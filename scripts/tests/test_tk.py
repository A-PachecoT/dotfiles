"""Smoke tests de tk: store, fold y ranking. Correr: uv run --with pytest pytest scripts/tests/test_tk.py"""
import importlib.machinery
import importlib.util
import json
from datetime import date, timedelta
from pathlib import Path

import pytest

TK = Path(__file__).resolve().parents[1] / "tk"


@pytest.fixture
def tk(tmp_path, monkeypatch):
    monkeypatch.setenv("TK_HOME", str(tmp_path / "tasks"))
    monkeypatch.setenv("TK_CACHE", str(tmp_path / "cache"))
    monkeypatch.setenv("TK_NO_SYNC", "1")
    loader = importlib.machinery.SourceFileLoader("tk", str(TK))
    spec = importlib.util.spec_from_loader("tk", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


def test_add_fold_done(tk):
    tk.emit("add", "t1", title="a")
    tk.emit("add", "t2", title="b")
    tk.emit("done", "t1")
    tasks = tk.fold()
    assert tasks["t1"]["status"] == "done" and tasks["t2"]["status"] == "open"


def test_rank_order_and_why(tk):
    today = date.today().isoformat()
    tk.emit("add", "low", title="baja", prio=3)
    tk.emit("add", "due", title="vence", due=today)
    tk.emit("add", "p1", title="urgente", prio=1)
    order = [t["id"] for t in tk.rank(tk.fold(), {})["order"]]
    assert order == ["due", "p1", "low"]
    due = tk.rank(tk.fold(), {})["order"][0]
    assert "vence hoy" in due["why"]


def test_snooze_hides_and_bump_wins(tk):
    tk.emit("add", "a", title="a", prio=1)
    tk.emit("add", "b", title="b", prio=3)
    tk.emit("snooze", "a", until=tk.iso(tk.now() + timedelta(hours=1)))
    r = tk.rank(tk.fold(), {})
    assert [t["id"] for t in r["order"]] == ["b"] and r["sleeping"] == 1
    tk.emit("add", "c", title="c", prio=1)
    tk.emit("bump", "b")
    assert tk.rank(tk.fold(), {})["order"][0]["id"] == "b"


def test_agent_done_is_your_turn_and_working_is_apart(tk):
    tk.emit("add", "p1", title="urgente", prio=1, due=date.today().isoformat())
    tk.emit("add", "ag", title="con agente", prio=3, link={"host": tk.LOCAL, "session": "s-idle"})
    tk.emit("add", "wk", title="trabajando", prio=1, link={"host": tk.LOCAL, "session": "s-work"})
    since = tk.iso(tk.now() - timedelta(minutes=12))
    agents = {"s-idle": {"status": "idle", "since": since, "pane": "w:p1", "host": tk.LOCAL},
              "s-work": {"status": "working", "since": since, "pane": "w:p2", "host": tk.LOCAL}}
    r = tk.rank(tk.fold(), agents)
    assert r["order"][0]["id"] == "ag"
    assert r["order"][0]["why"][0] == "tu agente terminó hace 12 min"
    assert [t["id"] for t in r["working"]] == ["wk"]


def test_garden_archives_stale_unlinked_only(tk):
    old = tk.iso(tk.now() - timedelta(days=30))
    for tid, extra in (("stale", {}), ("urgent", {"prio": 1}), ("linked", {"link": {"host": "mac", "session": "x"}})):
        ev = {"ts": old, "host": "mac", "op": "add", "id": tid, "title": tid, **extra}
        tk.EVENTS.parent.mkdir(parents=True, exist_ok=True)
        with open(tk.EVENTS, "a") as f:
            f.write(json.dumps(ev) + "\n")
    tk.emit("add", "fresh", title="fresh")
    acts = tk.garden(use_ai=False)
    assert [a["id"] for a in acts] == ["stale"]
    tk.emit("restore", "stale")
    assert tk.fold()["stale"]["status"] == "open"


def test_fold_tolerates_interleaved_union_merge(tk):
    tk.EVENTS.parent.mkdir(parents=True, exist_ok=True)
    lines = [{"ts": "2026-10-05T10:00:02-05:00", "host": "arch", "op": "done", "id": "x"},
             {"ts": "2026-10-05T10:00:01-05:00", "host": "mac", "op": "add", "id": "x", "title": "x"}]
    tk.EVENTS.write_text("".join(json.dumps(ln) + "\n" for ln in lines))
    assert tk.fold()["x"]["status"] == "done"
