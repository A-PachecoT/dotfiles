"""Smoke tests de myturn: store, estados, enlace, hook y poda. Correr: uv run --with pytest pytest scripts/tests/"""
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
    monkeypatch.delenv("HERDR_PANE_ID", raising=False)
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
    info = mt.observe(lists, front, mt.now())
    return mt.classify(mt.fold(), info, lists)


def link(mt, s):
    return {"host": mt.LOCAL, "session": s, "pane": "w:p1"}


def ids(rows):
    return [r["id"] for r in rows]


def test_clean_title_strips_claude_status_glyph(mt):
    assert mt.clean_title("◐ Task manager AI first plugin") == "Task manager AI first plugin"
    assert mt.clean_title("✳ ¿Qué hora es?") == "¿Qué hora es?"
    assert mt.clean_title("✳ Claude Code") == ""


def test_my_tasks_show_hook_sessions_dont(mt):
    mt.emit("add", "mine", title="Cotización Ecoverde")
    mt.emit("add", "hook", title="x", source="agent", link=link(mt, "s1"))
    st = state(mt, [agent("s1", "idle")])
    assert ids(st["rows"]) == ["mine"] and st["background"] == 1
    assert st["rows"][0]["state"] == "none" and "cópiala" in st["rows"][0]["say"]


def test_linked_task_waits_then_seen_then_waits_again(mt):
    mt.emit("add", "a", title="Fix webhook Fovente", link=link(mt, "s1"))
    st = state(mt, [agent("s1", "idle", title="✳ otra cosa")])
    assert ids(st["waiting"]) == ["a"]
    assert st["rows"][0]["title"] == "Fix webhook Fovente"  # el título que escribiste no lo pisa Claude
    st = state(mt, [agent("s1", "idle", focused=True)], front=mt.LOCAL)
    assert st["waiting"] == [] and st["rows"][0]["say"] == "ya lo viste"
    assert state(mt, [agent("s1", "working")])["rows"][0]["say"] == "trabajando…"
    assert ids(state(mt, [agent("s1", "blocked")])["waiting"]) == ["a"]


def test_focused_without_herdr_frontmost_is_not_seen(mt):
    mt.emit("add", "a", title="x", link=link(mt, "s1"))
    assert ids(state(mt, [agent("s1", "idle", focused=True)], front=None)["waiting"]) == ["a"]


def test_order_waiting_first_then_prio(mt):
    mt.emit("add", "low", title="baja")
    mt.emit("add", "p1", title="urgente", prio=1)
    mt.emit("add", "w", title="espera", prio=2, link=link(mt, "s1"))
    assert ids(state(mt, [agent("s1", "idle")])["rows"]) == ["w", "p1", "low"]


def test_closed_agent_offers_resume(mt):
    mt.emit("add", "a", title="x", link=link(mt, "gone"))
    row = state(mt, [agent("other", "idle")])["rows"][0]
    assert row["state"] == "closed" and row["can_resume"] and not row["can_go"]


def test_bar_label(mt):
    assert mt.bar_label(state(mt, []))[2].startswith("sin tareas")
    mt.emit("add", "a", title="Cotización", prio=1)
    assert mt.bar_label(state(mt, [])) == ("○", "white", "Cotización")
    mt.emit("add", "w", title="Fix webhook", link=link(mt, "s1"))
    assert mt.bar_label(state(mt, [agent("s1", "idle")])) == ("●", "green", "Fix webhook · te espera")


def test_link_here_binds_session_and_merges_hook_task(mt, monkeypatch):
    mt.emit("add", "task", title="Cotización Ecoverde")
    mt.emit("add", "hook", title="sesión", source="agent", link=link(mt, "s9"))
    monkeypatch.setenv("HERDR_PANE_ID", "w:p9")
    monkeypatch.setattr(mt, "herdr_json", lambda *a, **k: {"pane": {"agent_session": {"value": "s9"},
                                                                       "pane_id": "w:p9"}})
    monkeypatch.setattr(mt, "refresh", lambda: {})
    assert "Cotización Ecoverde" in mt.link_here("#task")
    tasks = mt.fold()
    assert tasks["task"]["link"]["session"] == "s9" and tasks["hook"]["status"] == "archived"
    assert mt.by_session(tasks)["s9"]["id"] == "task"


def test_claude_prompt_tells_the_agent_how_to_link(mt):
    assert "myturn link tabc123" in mt.claude_prompt({"id": "tabc123", "title": "Fix"})


def test_track_hook_registers_once_and_skips_foreign_sessions(mt, monkeypatch):
    monkeypatch.setenv("HERDR_PANE_ID", "w:p9")
    pane = {"pane": {"agent_session": {"value": "s9"}, "terminal_title": "◐ Arma la cotización"}}
    monkeypatch.setattr(mt, "herdr_json", lambda *a, **k: pane)
    mt.track({"session_id": "s9", "prompt": "arma la cotización de ecoverde", "cwd": "/tmp"})
    mt.track({"session_id": "s9", "prompt": "otra cosa"})
    mt.track({"session_id": "claude-p-run", "prompt": "x"})  # el pane es de otra sesión
    tasks = list(mt.fold().values())
    assert len(tasks) == 1 and tasks[0]["title"] == "Arma la cotización" and tasks[0]["source"] == "agent"


def test_track_outside_herdr_is_noop_and_never_raises(mt, monkeypatch):
    mt.track({"session_id": "s1", "prompt": "x"})
    assert mt.fold() == {}
    monkeypatch.setattr("sys.stdin", io.StringIO("no es json"))
    mt.main(["track"])


def test_garden_prunes_hook_sessions_and_stale_tasks_not_yours(mt, monkeypatch):
    for tid, s in (("closed", "gone"), ("alive", "s1")):
        mt.emit("add", tid, title=tid, source="agent", link=link(mt, s))
    mt.emit("add", "linked_mine", title="mía", link=link(mt, "gone2"))
    old = mt.iso(mt.now() - timedelta(days=30))
    with open(mt.EVENTS, "a") as f:
        f.write(json.dumps({"ts": old, "host": mt.LOCAL, "op": "add", "id": "stale", "title": "vieja"}) + "\n")
    mt.emit("add", "due", title="con fecha", due=date.today().isoformat())
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


# ── Obsidian ──────────────────────────────────────────────────────────────────────────────────────
@pytest.fixture
def vault(mt, tmp_path, monkeypatch):
    v = tmp_path / "vault"
    v.mkdir()
    monkeypatch.setattr(mt, "VAULT", v)
    monkeypatch.setattr(mt, "TAREAS", v / "05. System" / "myturn" / "Tareas.md")
    monkeypatch.setattr(mt, "GATE", tmp_path / "no-gate")
    monkeypatch.setattr(mt, "herdr_agents", lambda host: [])
    monkeypatch.setattr(mt, "herdr_frontmost", lambda: None)
    return v


DAILY = """# Tuesday
## Plan
### To-do
- [ ] ***GOAL FOR TODAY:*** [due:: 2026-10-06]
```tasks
not done
```
- [ ] 📅 10:00 — 📩 Indusegur — toque
- [ ] Callejon terminar
\t- [ ] Q pase menu
- [x] ya hecha
- Reu Founders. Accionables:
\t- [ ] enviar coti a Marx
\t- [ ] —

## Journaling
- [ ] esto no es del To-do
"""


def test_import_daily_moves_my_tasks_and_leaves_forward_marks(mt, vault):
    note = mt.daily_path(date.today())
    note.parent.mkdir(parents=True)
    note.write_text(DAILY)
    titles = mt.import_daily(note)
    assert titles == ["Callejon terminar", "Callejon terminar: Q pase menu", "Reu Founders: enviar coti a Marx"]
    text = note.read_text()
    assert "- [>] Callejon terminar → myturn" in text and "\t- [>] enviar coti a Marx → myturn" in text
    assert "- [ ] 📅 10:00" in text and "\t- [ ] —" in text and "- [ ] esto no es del To-do" in text
    assert mt.import_daily(note) == []  # idempotente: no reimporta
    assert {t["title"] for t in mt.fold().values()} == set(titles)
    # la nota del día siguiente trae las mismas líneas (daily_prep): se marcan, no se duplican
    tomorrow = mt.daily_path(date.today() + timedelta(days=1))
    tomorrow.parent.mkdir(parents=True, exist_ok=True)
    tomorrow.write_text(DAILY)
    assert mt.import_daily(tomorrow) == []
    assert "- [>] Callejon terminar → myturn" in tomorrow.read_text()
    assert len(mt.fold()) == 3


def test_tareas_roundtrip_edit_done_and_new_line(mt, vault):
    mt.emit("add", "t000001", title="Cotización Ecoverde", prio=1)
    mt.emit("add", "t000002", title="Llamar contador")
    out = mt.obsidian_sync()
    assert out["wrote"]
    text = mt.TAREAS.read_text()
    assert "- [ ] Cotización Ecoverde ⏫ ^t000001" in text and "- [ ] Llamar contador ^t000002" in text
    # André edita en Obsidian: marca una, renombra y baja la prioridad de otra, y agrega una nueva
    text = text.replace("- [ ] Llamar contador ^t000002", "- [x] Llamar contador ^t000002")
    text = text.replace("Cotización Ecoverde ⏫ ^t000001", "Cotización Ecoverde v2 🔼 📅 2026-10-09 ^t000001")
    mt.TAREAS.write_text(text + "- [ ] Nueva desde Obsidian ⏫\n")
    out = mt.obsidian_sync()
    tasks = mt.fold()
    assert out["edits"] == 3
    assert tasks["t000002"]["status"] == "done"
    assert (tasks["t000001"]["title"], tasks["t000001"]["prio"], tasks["t000001"]["due"]) == \
        ("Cotización Ecoverde v2", 2, "2026-10-09")
    new = [t for t in tasks.values() if t["title"] == "Nueva desde Obsidian"]
    assert len(new) == 1 and new[0]["prio"] == 1
    text = mt.TAREAS.read_text()
    assert "Llamar contador" not in text and f"^{new[0]['id']}" in text
    assert mt.obsidian_sync() == {"imported": [], "edits": 0, "wrote": False}  # estable


def test_widget_edit_wins_over_unchanged_obsidian_line(mt, vault):
    mt.emit("add", "t000001", title="viejo")
    mt.obsidian_sync()
    mt.emit("update", "t000001", set={"title": "nuevo desde el widget"})
    mt.obsidian_sync()
    assert mt.fold()["t000001"]["title"] == "nuevo desde el widget"
    assert "nuevo desde el widget ^t000001" in mt.TAREAS.read_text()


def test_busy_gate_skips_the_file(mt, vault, tmp_path, monkeypatch):
    gate = tmp_path / "gate.py"
    gate.write_text("import sys; sys.exit(2)")
    monkeypatch.setattr(mt, "GATE", gate)
    mt.emit("add", "t000001", title="x")
    assert mt.obsidian_sync()["wrote"] is False and not mt.TAREAS.exists()
