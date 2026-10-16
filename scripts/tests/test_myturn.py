"""Smoke tests de myturn: store, estados, enlace, hook y poda. Correr: uv run --with pytest pytest scripts/tests/"""
import importlib.machinery
import importlib.util
import io
import json
import os
from datetime import date, datetime, timedelta
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


def test_remote_agents_never_wait_for_ssh(mt, monkeypatch):
    calls, spawned = [], []
    monkeypatch.setattr(mt, "herdr_json", lambda *a, **k: calls.append(a) or {"agents": [agent("s1", "idle")]})
    monkeypatch.setattr(mt, "spawn", lambda *a: spawned.append(a))
    remote = "arch" if mt.LOCAL == "mac" else "mac"
    assert mt.herdr_agents(remote)[0]["agent_status"] == "idle" and len(calls) == 1  # sin caché: lee
    cache = mt.CACHE / f"agents-{remote}.json"
    old = cache.stat().st_mtime - 120
    os.utime(cache, (old, old))
    assert mt.herdr_agents(remote) and len(calls) == 1 and spawned == [("_agents", remote)]  # viejo: sirve y renueva
    old -= 600
    os.utime(cache, (old, old))
    assert mt.herdr_agents(remote) is None  # muy viejo: la otra caja no responde
    assert mt.herdr_agents(remote, fresh=True) and len(calls) == 2  # go lee en el acto


# ── tiempo: programadas, HOY, avisos ──────────────────────────────────────────────────────────────
@pytest.fixture
def clock(mt, monkeypatch):
    """Reloj fijo (viernes 16-oct-2026, 10:00) que el test adelanta con clock(hours=…)."""
    t = {"now": datetime(2026, 10, 16, 10, 0).astimezone()}
    monkeypatch.setattr(mt, "now", lambda: t["now"])

    def advance(**delta):
        t["now"] += timedelta(**delta)
    return advance


@pytest.fixture
def quiet(mt, monkeypatch):
    """Sin herdr, sin barra y sin notificaciones de verdad; devuelve los avisos que habrían sonado."""
    rings = []
    monkeypatch.setattr(mt, "notify", lambda msg, sound=False: rings.append(msg))
    monkeypatch.setattr(mt, "herdr_agents", lambda host, fresh=False: [])
    monkeypatch.setattr(mt, "herdr_frontmost", lambda: None)
    monkeypatch.setattr(mt, "sketchybar", lambda st: None)
    return rings


@pytest.mark.parametrize("text,expected", [
    ("Revisar TikTok el 30", ("Revisar TikTok", "2026-10-30", None)),
    ("llamar a Juan mañana a las 9", ("llamar a Juan", "2026-10-17T09:00", None)),
    ("llamar a Juan a las 3", ("llamar a Juan", "2026-10-17T15:00", None)),  # «a las 3» = 15:00, hoy ya pasó
    ("pagar luz antes del vie", ("pagar luz", None, "2026-10-23")),
    ("pagar luz hoy", ("pagar luz", None, "2026-10-16")),
    ("follow-up en 2 h", ("follow-up", "2026-10-16T20:40", None)),
    ("contrato desde el lunes antes del 30", ("contrato", "2026-10-19", "2026-10-30")),
    ("mockup de Sonda, para el 16-oct", ("mockup de Sonda", None, "2026-10-16")),
    ("Pago 5 de enero", ("Pago", "2027-01-05", None)),
    ("lun 9:00 standup", ("standup", "2026-10-19T09:00", None)),
    ("deck la próxima semana", ("deck", "2026-10-19", None)),
    # no son fechas: se quedan en el título
    ("prepararse reu macro mar presencial", None),
    ("revisar el 30% de margen", None),
    ("Lescano: invitación demo mié 14-oct 11:00", None),  # ya pasó: es una referencia, no un plazo
    ("reunión del lunes: deck", None),
    ("planificar la mañana", None),
    ("ver el 1 de los PRs", None),
    ("Reu 1:1 con Juan", None),
])
def test_parse_when_spanish_phrases(mt, text, expected):
    ref = datetime(2026, 10, 16, 18, 40).astimezone()  # viernes
    assert mt.parse_when(text, ref) == (expected or (text, None, None))


def test_when_value_for_the_row_editor(mt, clock):
    assert mt.when_value("vie")["set"] == {"start": "2026-10-23"}  # sola, una abreviatura sí es fecha
    assert mt.when_value("30")["label"] == "aparece el vie 30/10"
    assert mt.when_value("ya")["set"] == {"start": None}
    assert mt.when_value("sin fecha")["set"] == {"start": None, "due": None}
    assert mt.when_value("mañana 9")["error"] == "no entiendo «9»"


def test_scheduled_task_hides_until_its_time_then_tops_the_list_and_rings_once(mt, clock, quiet, capsys):
    mt.emit("add", "p1", title="urgente", prio=1)
    mt.main(["add", "--parse", "--", "Revisar TikTok a las 15:00"])
    assert "aparece hoy 15:00" in capsys.readouterr().out
    st = mt.compute(notify_new=True)
    assert ids(st["rows"]) == ["p1"] and [r["title"] for r in st["later"]] == ["Revisar TikTok"]
    assert mt.panel()["later"][0]["say"] == "aparece hoy 15:00" and quiet == []
    clock(hours=5, minutes=1)
    st = mt.compute(notify_new=True)
    assert [r["title"] for r in st["rows"]] == ["Revisar TikTok", "urgente"]  # HOY va sobre la prioridad
    assert mt.bar_label(st) == ("●", "yellow", "Revisar TikTok · toca hoy 15:00")
    assert quiet == ["Toca ahora: Revisar TikTok"]
    mt.compute(notify_new=True)
    assert len(quiet) == 1  # una sola vez
    clock(days=1)  # al día siguiente es una tarea más
    assert mt.compute(notify_new=True)["rows"][0]["title"] == "urgente" and len(quiet) == 1


def test_ls_hides_scheduled_tasks_until_todas(mt, clock, quiet, capsys):
    mt.main(["add", "prueba diferida", "--desde", "mañana"])
    capsys.readouterr()
    mt.main(["ls"])
    out = capsys.readouterr().out
    assert "prueba diferida" not in out and "(1 programada: myturn ls --todas)" in out
    mt.main(["ls", "--todas"])
    assert "prueba diferida  — aparece mañana" in capsys.readouterr().out


def test_due_today_rings_once_unless_you_set_it_today(mt, clock, quiet):
    mt.emit("add", "a", title="pagar luz", due="2026-10-17")
    mt.emit("add", "b", title="otra")
    clock(days=1)
    mt.emit("update", "b", set={"due": "2026-10-17"})  # se la pusiste hoy: ya lo sabes
    st = mt.compute(notify_new=True)
    assert [r["id"] for r in st["rows"] if r["urgency"] == "today"] == ["a", "b"]
    assert st["rows"][0]["say"] == "vence hoy · sin agente · cópiala a un Claude"
    assert quiet == ["Vence hoy: pagar luz"]
    clock(days=1)
    st = mt.compute(notify_new=True)
    assert st["rows"][0]["urgency"] == "overdue" and mt.bar_label(st)[1:] == ("red", "pagar luz · vencida hace 1 d")


def test_when_snoozes_sets_due_and_brings_back(mt, clock, quiet, capsys):
    mt.emit("add", "a", title="Esperar a Meta")
    mt.main(["when", "a", "--", "el 30"])
    assert mt.fold()["a"]["start"] == "2026-10-30" and ids(mt.compute()["later"]) == ["a"]
    mt.main(["when", "a", "antes del vie"])  # un plazo antes de que aparezca la trae de vuelta
    assert (mt.fold()["a"]["start"], mt.fold()["a"]["due"]) == (None, "2026-10-23")
    mt.main(["when", "a", "lun"])
    mt.main(["when", "a", "ya"])
    assert (mt.fold()["a"]["start"], mt.fold()["a"]["due"]) == (None, "2026-10-23")
    mt.main(["when", "a", "sin fecha"])
    assert (mt.fold()["a"]["start"], mt.fold()["a"]["due"]) == (None, None)
    with pytest.raises(SystemExit):
        mt.main(["when", "a", "xyz"])


def test_garden_never_archives_a_scheduled_task_before_it_appears(mt, clock, monkeypatch):
    monkeypatch.setattr(mt, "herdr_agents", lambda host: [])
    mt.emit("add", "far", title="revisar aprobación TikTok", start="2026-11-20")
    clock(days=20)
    assert mt.garden(use_ai=False) == []  # 20 d sin tocar, pero todavía no aparece
    clock(days=15)
    assert mt.garden(use_ai=False) == []  # apareció ayer: la inactividad cuenta desde ahí


def test_obsidian_start_date_roundtrip_keeps_the_hour(mt, vault, clock):
    mt.emit("add", "t000001", title="Revisar TikTok", start="2026-10-30T09:00")
    mt.emit("add", "t000002", title="Hoy")
    mt.obsidian_sync()
    text = mt.TAREAS.read_text()
    assert "- [ ] Hoy ^t000002\n\n## Programadas\n\n- [ ] Revisar TikTok 🛫 2026-10-30 ^t000001\n" in text
    text = text.replace("- [ ] Hoy ^t000002", "- [ ] Hoy 🛫 2026-10-20 ^t000002")
    mt.TAREAS.write_text(text + "- [ ] llamar a Juan mañana a las 9\n")
    mt.obsidian_sync()
    tasks = mt.fold()
    assert tasks["t000001"]["start"] == "2026-10-30T09:00"  # misma fecha: Obsidian no ve la hora, no la pisa
    assert tasks["t000002"]["start"] == "2026-10-20"
    assert [t["start"] for t in tasks.values() if t["title"] == "llamar a Juan"] == ["2026-10-17T09:00"]
    mt.TAREAS.write_text(mt.TAREAS.read_text().replace("TikTok 🛫 2026-10-30", "TikTok ⏳ 2026-10-31"))
    mt.obsidian_sync()
    assert mt.fold()["t000001"]["start"] == "2026-10-31"  # ⏳ (scheduled de Tasks) también vale


def test_daily_line_with_a_date_is_scheduled(mt, vault, clock):
    note = mt.daily_path(date(2026, 10, 16))
    note.parent.mkdir(parents=True)
    note.write_text("### To-do\n- [ ] revisar aprobación TikTok el 30\n- [ ] Indusegur 🛫 2026-10-20\n")
    assert mt.import_daily(note) == ["revisar aprobación TikTok", "Indusegur"]
    assert {t["title"]: t["start"] for t in mt.fold().values()} == \
        {"revisar aprobación TikTok": "2026-10-30", "Indusegur": "2026-10-20"}
    assert "- [>] revisar aprobación TikTok el 30 → myturn" in note.read_text()
