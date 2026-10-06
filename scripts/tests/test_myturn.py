"""Smoke tests de myturn: store, visto, cola, hook y poda. Correr: uv run --with pytest pytest scripts/tests/"""
import importlib.machinery
import importlib.util
import io
import json
from datetime import date, timedelta
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "myturn"


@pytest.fixture
def mt(tmp_path, monkeypatch):
    monkeypatch.setenv("MYTURN_HOME", str(tmp_path / "tasks"))
    monkeypatch.setenv("MYTURN_CACHE", str(tmp_path / "cache"))
    monkeypatch.setenv("MYTURN_NO_SYNC", "1")
    loader = importlib.machinery.SourceFileLoader("myturn", str(SCRIPT))
    spec = importlib.util.spec_from_loader("myturn", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


def agent(session, status, pane="w:p1", focused=False, title="✳ Fix webhook"):
    return {"agent": "claude", "agent_session": {"value": session}, "agent_status": status, "pane_id": pane,
            "focused": focused, "terminal_title": title, "cwd": "/tmp"}


def state(mt, agents, front=None):
    lists = {mt.LOCAL: agents}
    tasks = mt.fold()
    info = mt.observe(tasks, lists, front, mt.now())
    return mt.classify(tasks, info, lists)


def link(mt, s):
    return {"host": mt.LOCAL, "session": s, "pane": "w:p1"}


def test_clean_title_strips_claude_status_glyph(mt):
    assert mt.clean_title("◐ Task manager AI first plugin") == "Task manager AI first plugin"
    assert mt.clean_title("✳ ¿Qué hora es?") == "¿Qué hora es?"
    assert mt.clean_title("✳ Claude Code") == ""


def test_prio_agent_idle_unseen_waits_then_seen_pauses(mt):
    mt.emit("add", "a", title="x", source="agent", prio=1, link=link(mt, "s1"))
    st = state(mt, [agent("s1", "idle")])
    assert [t["id"] for t in st["waiting"]] == ["a"]
    assert st["waiting"][0]["title"] == "Fix webhook"  # título vivo de Claude Code
    # enfocado + ventana de herdr al frente → visto → en pausa
    st = state(mt, [agent("s1", "idle", focused=True)], front=mt.LOCAL)
    assert st["waiting"] == [] and [t["id"] for t in st["paused"]] == ["a"]
    # nueva transición (trabajó y terminó otra vez) → vuelve a esperar
    state(mt, [agent("s1", "working")])
    st = state(mt, [agent("s1", "idle")])
    assert [t["id"] for t in st["waiting"]] == ["a"]


def test_focused_without_herdr_frontmost_is_not_seen(mt):
    mt.emit("add", "a", title="x", source="agent", prio=1, link=link(mt, "s1"))
    st = state(mt, [agent("s1", "idle", focused=True)], front=None)
    assert [t["id"] for t in st["waiting"]] == ["a"]


def test_unprioritized_agents_never_interrupt(mt):
    mt.emit("add", "a", title="x", source="agent", link=link(mt, "s1"))
    st = state(mt, [agent("s1", "idle")])
    assert st["waiting"] == [] and st["background"] == 1


def test_queue_order_prio_then_wait_time(mt):
    for tid, s, p in (("p2", "s2", 2), ("p1", "s1", 1), ("p1b", "s3", 1)):
        mt.emit("add", tid, title=tid, source="agent", prio=p, link=link(mt, s))
    early = mt.iso(mt.now() - timedelta(minutes=30))  # s3 espera desde antes
    mt.save_seen({"s3": {"status": "idle", "since": early, "seen_at": None, "notified": False}})
    st = state(mt, [agent(s, "idle", pane=f"w:{s}") for s in ("s1", "s2", "s3")])
    assert [t["id"] for t in st["waiting"]] == ["p1b", "p1", "p2"]


def test_closed_prio_agent_goes_to_pending_and_untracked_counted(mt):
    mt.emit("add", "a", title="x", source="agent", prio=1, link=link(mt, "gone"))
    st = state(mt, [agent("other", "idle")])
    assert st["pending"][0]["id"] == "a" and "agente cerrado" in st["pending"][0]["why"]
    assert st["untracked"] == 1


def test_loose_pending_order(mt):
    mt.emit("add", "low", title="baja")
    mt.emit("add", "due", title="vence", due=date.today().isoformat())
    mt.emit("add", "p1", title="urgente", prio=1)
    assert [t["id"] for t in state(mt, [])["pending"]] == ["due", "p1", "low"]


def test_track_hook_registers_once_and_skips_foreign_sessions(mt, monkeypatch):
    monkeypatch.setenv("HERDR_PANE_ID", "w:p9")
    pane = {"pane": {"agent_session": {"value": "s9"}, "terminal_title": "◐ Arma la cotización"}}
    monkeypatch.setattr(mt, "herdr_json", lambda *a, **k: pane)
    mt.track({"session_id": "s9", "prompt": "arma la cotización de ecoverde", "cwd": "/tmp"})
    mt.track({"session_id": "s9", "prompt": "otra cosa"})
    mt.track({"session_id": "claude-p-run", "prompt": "x"})  # el pane es de otra sesión
    tasks = list(mt.fold().values())
    assert len(tasks) == 1 and tasks[0]["title"] == "Arma la cotización"
    assert tasks[0]["link"] == {"host": mt.LOCAL, "session": "s9", "pane": "w:p9"}


def test_track_outside_herdr_is_noop(mt, monkeypatch):
    monkeypatch.delenv("HERDR_PANE_ID", raising=False)
    mt.track({"session_id": "s1", "prompt": "x"})
    assert mt.fold() == {}


def test_main_track_never_raises(mt, monkeypatch):
    monkeypatch.setattr("sys.stdin", io.StringIO("no es json"))
    mt.main(["track"])


def test_garden_archives_dead_unprioritized_sessions_only(mt, monkeypatch):
    for tid, s, p in (("closed", "gone", None), ("prio", "gone2", 1), ("alive", "s1", None)):
        mt.emit("add", tid, title=tid, source="agent", prio=p, link=link(mt, s))
    old = mt.iso(mt.now() - timedelta(days=30))
    with open(mt.EVENTS, "a") as f:
        f.write(json.dumps({"ts": old, "host": mt.LOCAL, "op": "add", "id": "stale", "title": "vieja"}) + "\n")
    monkeypatch.setattr(mt, "herdr_agents", lambda host: [agent("s1", "working")])
    acts = {a["id"]: a["archive"] for a in mt.garden(use_ai=False)}
    assert acts == {"closed": "sesión cerrada", "stale": "sin tocar hace 30 d"}
    mt.emit("restore", "closed")
    assert mt.fold()["closed"]["status"] == "open"


def test_fold_tolerates_interleaved_union_merge(mt):
    mt.EVENTS.parent.mkdir(parents=True, exist_ok=True)
    lines = [{"ts": "2026-10-05T10:00:02-05:00", "host": "arch", "op": "done", "id": "x"},
             {"ts": "2026-10-05T10:00:01-05:00", "host": "mac", "op": "add", "id": "x", "title": "x"}]
    mt.EVENTS.write_text("".join(json.dumps(ln) + "\n" for ln in lines))
    assert mt.fold()["x"]["status"] == "done"
