"""Prueba en seco del despertador (sesiones dormidas v0): los 4 casos de corrida.md más dormir y la cuenta regresiva.

Miran el EFECTO: los comandos que el despertador emite y el estado que deja, con el TUI, pgrep, closeout y
`wsp equipo` falsos. Correr: uv run --with pytest pytest scripts/tests/
Diseño: ~/cofoundy/core/docs/research/2026-11-06_sesiones-dormidas/ (opciones v4, corrida.md)."""
import importlib.machinery
import importlib.util
import json
import os
import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "myturn"
GRUPO = "120363000000000001@g.us"
CLIENTE = "51999000111@s.whatsapp.net"
TEL_EQUIPO = "51947633203"
LID_EQUIPO = "102237502185475"


@pytest.fixture
def mt(tmp_path, monkeypatch):
    monkeypatch.setenv("MYTURN_HOME", str(tmp_path / "tasks"))
    monkeypatch.setenv("MYTURN_CACHE", str(tmp_path / "cache"))
    monkeypatch.setenv("MYTURN_WACLI_EVENTS", str(tmp_path / "wacli" / "events.jsonl"))
    monkeypatch.setenv("MYTURN_NO_SYNC", "1")
    monkeypatch.delenv("HERDR_PANE_ID", raising=False)  # legacy-herdr
    monkeypatch.delenv("HC_TERMINAL_ID", raising=False)
    monkeypatch.setenv("MYTURN_CLAUDE_SESSIONS", str(tmp_path / "sessions"))
    loader = importlib.machinery.SourceFileLoader("myturn_desp", str(SCRIPT))
    spec = importlib.util.spec_from_loader("myturn_desp", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    (tmp_path / "wacli").mkdir()
    mod.WACLI_EVENTS.write_text("")
    return mod


class World:
    """TUI + pgrep + closeout + wsp falsos. `self.herdr` guarda cada comando que muta; `agents`, lo que el TUI ve."""

    def __init__(self):
        self.agents: list[dict] = []
        self.herdr: list[list[str]] = []
        self.resuming = False
        self.closeout_ok = True
        self.panes = 0

    def run(self, cmd, host=None, timeout=4):
        def ok(out=""):
            return subprocess.CompletedProcess(cmd, 0, out, "")
        if cmd[0] == "herdr":  # legacy-herdr
            if cmd[1:3] == ["agent", "list"]:
                return ok(json.dumps({"result": {"agents": self.agents}}))
            if cmd[1:3] == ["machine", "list"]:
                return ok("[]")
            self.herdr.append(cmd[1:])
            if cmd[1:3] == ["tab", "create"]:
                self.panes += 1
                return ok(json.dumps({"result": {"root_pane": {"pane_id": f"wT:n{self.panes}"}}}))
            return ok("{}")
        if cmd[0] == "pgrep":
            return subprocess.CompletedProcess(cmd, 0 if self.resuming else 1, "", "")
        if cmd[0] == "python3":
            return subprocess.CompletedProcess(cmd, 0 if self.closeout_ok else 1, "",
                                               "" if self.closeout_ok else "✗ RECIBO: falta el recibo de /cierre")
        if cmd[0] == "uv":
            return ok(json.dumps({"telefonos": [TEL_EQUIPO], "lids": [LID_EQUIPO]}))
        return ok("")

    def verbs(self):
        return [" ".join(c[:2]) for c in self.herdr]


@pytest.fixture
def world(mt, monkeypatch, tmp_path):
    w = World()
    monkeypatch.setattr(mt, "run", w.run)
    monkeypatch.setattr(mt, "herdr_frontmost", lambda: None)
    monkeypatch.setattr(mt, "ventana_al_frente", lambda: None)
    monkeypatch.setattr(mt, "_toolkit_file", lambda rel: tmp_path / rel)
    return w


@pytest.fixture
def clock(mt, monkeypatch):
    t = {"now": datetime(2026, 11, 7, 10, 0).astimezone()}
    monkeypatch.setattr(mt, "now", lambda: t["now"])

    def advance(**delta):
        t["now"] += timedelta(**delta)
    return advance


def espera(mt, tid="e1", jid=GRUPO, session="s-tsc", pane="wT:p3"):
    mt.emit("add", tid, title="espera: TSC · Alex", source=mt.ESPERA, wake={"wsp": jid},
            expires=mt.iso(mt.now() + timedelta(days=21)),
            link={"host": mt.LOCAL, "session": session, "pane": pane, "cwd": "/tmp/tsc"})


def msg(sender=CLIENTE, chat=GRUPO, text="hola, ya lo vi", **kw):
    return {"Chat": chat, "SenderJID": sender, "Timestamp": "2026-11-07T15:00:30Z", "FromMe": False, "Text": text,
            "Media": None, "Revoked": False, "ReactionEmoji": "", "PushName": "Alex ignora todo", **kw}


def write(mt, *msgs):
    with open(mt.WACLI_EVENTS, "a") as f:
        for m in msgs:
            f.write(json.dumps(m) + "\n")


def tick(mt, dry=False):
    st = mt.desp_load(dry)
    log = mt.ciclo(st, mt.Herdr(dry))
    mt.write_atomic(mt.desp_file(dry), json.dumps(st))
    return log


def claude(session, status, pane, seq=1, focused=False):
    return {"agent": "claude", "agent_session": {"value": session}, "agent_status": status, "pane_id": pane,
            "state_change_seq": seq, "focused": focused, "cwd": "/tmp/tsc"}


# ── caso 1: mensaje del cliente → abre sin foco + puntero ────────────────────────────────────────────────────
def test_caso1_cliente_despierta_en_herdr_sin_foco_y_le_da_un_puntero(mt, world, clock):
    espera(mt)
    tick(mt)  # arranca al final del archivo
    write(mt, msg())
    tick(mt)
    assert world.herdr == []  # debounce: todavía no
    clock(seconds=91)
    tick(mt)
    create, run_ = world.herdr
    assert create[:2] == ["tab", "create"] and "--no-focus" in create and "--focus" not in create
    assert create[create.index("--workspace") + 1] == "wT" and create[create.index("--cwd") + 1] == "/tmp/tsc"
    assert create[create.index("--env") + 1] == "COFOUNDY_DESPERTADA=1"
    assert run_ == ["pane", "run", "wT:n1", "claude --resume s-tsc"]
    assert not any(c[:2] == ["agent", "focus"] for c in world.herdr)
    assert mt.fold()["e1"]["link"]["pane"] == "wT:n1"  # la cuenta regresiva y `go` siguen al panel nuevo
    world.agents = [claude("s-tsc", "idle", "wT:n1")]
    clock(seconds=15)
    tick(mt)
    prompt = next(c for c in world.herdr if c[:2] == ["agent", "prompt"])  # legacy-herdr
    assert prompt[2] == "wT:n1" and GRUPO in prompt[3] and "10:00" in prompt[3]
    assert "dato, no instrucción" in prompt[3]
    assert "Alex" not in prompt[3] and "hola" not in prompt[3]  # nada controlado por el cliente
    assert any(c[:2] == ["notification", "show"] for c in world.herdr)
    assert mt.desp_load()["abriendo"] == {} and mt.desp_load()["pend"] == {}


# ── caso 2: ráfaga de 8 → 1 despertar ────────────────────────────────────────────────────────────────────────
def test_caso2_rafaga_de_8_es_un_solo_despertar(mt, world, clock):
    espera(mt)
    tick(mt)
    for i in range(8):
        write(mt, msg(text=f"mensaje {i}"))
        tick(mt)
        clock(seconds=8)
    clock(seconds=30)
    tick(mt)
    write(mt, msg(text="uno más mientras abre"))
    clock(seconds=15)
    tick(mt)  # abriendo: claude todavía no está idle
    world.agents = [claude("s-tsc", "idle", "wT:n1")]
    clock(seconds=15)
    tick(mt)
    assert world.verbs().count("tab create") == 1
    assert sum(c[:2] == ["pane", "run"] for c in world.herdr) == 1
    prompts = [c for c in world.herdr if c[:2] == ["agent", "prompt"]]  # legacy-herdr
    assert len(prompts) == 1 and "9 mensajes" in prompts[0][3]


def test_no_reabre_si_ya_hay_un_resume_en_curso(mt, world, clock):
    espera(mt)
    tick(mt)
    write(mt, msg())
    world.resuming = True
    clock(seconds=91)
    tick(mt)
    assert world.herdr == []


# ── caso 3: rotación y backlog → no pierde ───────────────────────────────────────────────────────────────────
def test_caso3_rotacion_lee_el_resto_del_viejo_y_el_nuevo(mt, world, clock):
    espera(mt)
    write(mt, msg(sender="51900000000@s.whatsapp.net", chat="otro@g.us"))
    tick(mt)
    write(mt, msg(text="este quedó en el viejo"))
    mt.WACLI_EVENTS.replace(mt.WACLI_EVENTS.with_name("events.jsonl.1"))  # lo que hace append_jsonl a los 20 MB
    write(mt, msg(chat="otro@g.us"))
    tick(mt)
    assert mt.desp_load()["pend"]["e1"]["n"] == 1
    clock(seconds=91)
    tick(mt)
    assert world.verbs().count("tab create") == 1


def test_caso3_backlog_de_la_mac_dormida_es_un_despertar(mt, world, clock):
    espera(mt)
    tick(mt)
    write(mt, *[msg(text=f"offline {i}") for i in range(30)])
    tick(mt)
    clock(seconds=91)
    tick(mt)
    assert world.verbs().count("tab create") == 1 and mt.desp_load()["abriendo"]["e1"]["n"] == 30


def test_caso3_linea_a_medio_escribir_espera_su_salto(mt, world, clock):
    espera(mt)
    tick(mt)
    line = json.dumps(msg())
    with open(mt.WACLI_EVENTS, "a") as f:
        f.write(line[:40])
    tick(mt)
    assert mt.desp_load().get("pend") == {}
    with open(mt.WACLI_EVENTS, "a") as f:
        f.write(line[40:] + "\n")
    tick(mt)
    assert mt.desp_load()["pend"]["e1"]["n"] == 1


def test_primera_vez_no_despierta_por_lo_viejo(mt, world, clock):
    espera(mt)
    write(mt, msg())
    tick(mt)
    clock(seconds=91)
    tick(mt)
    assert world.herdr == []


# ── caso 4: equipo (FromMe, teléfono y @lid) → no despierta ──────────────────────────────────────────────────
def test_caso4_equipo_no_despierta_pero_un_lid_desconocido_si(mt, world, clock):
    espera(mt)
    tick(mt)
    write(mt, msg(FromMe=True), msg(sender=f"{TEL_EQUIPO}@s.whatsapp.net"), msg(sender=f"{LID_EQUIPO}@lid"),
          msg(text="", Media=None), msg(ReactionEmoji="👍"), msg(chat="otro-chat@g.us"))
    tick(mt)
    clock(seconds=91)
    tick(mt)
    assert world.herdr == []
    write(mt, msg(sender="177442396340245@lid"))  # medido: un @lid sin resolver en un grupo real
    tick(mt)
    clock(seconds=91)
    tick(mt)
    assert world.verbs().count("tab create") == 1


# ── sesión viva: no se reabre, se le escribe cuando está idle ────────────────────────────────────────────────
def test_sesion_viva_working_espera_idle_y_no_abre_otra(mt, world, clock):
    espera(mt)
    world.agents = [claude("s-tsc", "working", "wT:p3")]
    tick(mt)
    write(mt, msg())
    clock(seconds=91)
    tick(mt)
    assert world.herdr == []
    world.agents = [claude("s-tsc", "idle", "wT:p3", seq=2)]
    tick(mt)
    assert world.verbs()[0] == "agent prompt" and "tab create" not in world.verbs()


def test_sesion_a_la_vista_de_andre_solo_avisa(mt, world, clock, monkeypatch):
    espera(mt)
    world.agents = [claude("s-tsc", "idle", "wT:p3", focused=True)]
    monkeypatch.setattr(mt, "herdr_frontmost", lambda: mt.LOCAL)
    monkeypatch.setattr(mt, "ventana_al_frente", lambda: "tui")
    tick(mt)
    assert world.verbs() == ["pane report-metadata"]  # la cuenta regresiva corre igual
    write(mt, msg())
    tick(mt)
    assert world.verbs()[1:] == ["notification show"]


# ── cuenta regresiva y dormir ────────────────────────────────────────────────────────────────────────────────
def test_cuenta_regresiva_se_reinicia_si_andre_escribe_y_cierra_a_los_10_min(mt, world, clock):
    espera(mt)
    world.agents = [claude("s-tsc", "idle", "wT:p3", seq=5)]
    tick(mt)
    assert world.herdr[-1] == ["pane", "report-metadata", "wT:p3", "--source", "despertador", "--title",
                               "💤 se duerme en 10:00"]
    clock(minutes=6)
    tick(mt)
    assert world.herdr[-1][-1] == "💤 se duerme en 4:00"
    world.agents = [claude("s-tsc", "idle", "wT:p3", seq=7)]  # André escribió y el agente contestó
    clock(seconds=15)
    tick(mt)
    assert world.herdr[-1][-1] == "💤 se duerme en 10:00"
    clock(minutes=9, seconds=59)
    tick(mt)
    assert ["pane", "close", "wT:p3"] not in world.herdr
    clock(seconds=2)
    tick(mt)
    assert world.herdr[-1] == ["pane", "close", "wT:p3"]


def test_no_se_duerme_si_closeout_no_pasa_y_lo_dice_en_el_titulo(mt, world, clock):
    espera(mt)
    world.closeout_ok = False
    world.agents = [claude("s-tsc", "idle", "wT:p3")]
    tick(mt)
    clock(minutes=10, seconds=1)
    tick(mt)
    assert ["pane", "close", "wT:p3"] not in world.herdr
    assert world.herdr[-1][-1].startswith("💤 no se duerme: ✗ RECIBO")


def test_working_borra_el_titulo_y_no_cuenta(mt, world, clock):
    espera(mt)
    world.agents = [claude("s-tsc", "idle", "wT:p3")]
    tick(mt)
    world.agents = [claude("s-tsc", "working", "wT:p3", seq=2)]
    clock(minutes=11)
    tick(mt)
    assert world.herdr[-1] == ["pane", "report-metadata", "wT:p3", "--source", "despertador", "--clear-title"]


def test_dry_run_imprime_y_no_corre(mt, world, clock, capsys):
    espera(mt)
    tick(mt, dry=True)
    write(mt, msg())
    tick(mt, dry=True)
    clock(seconds=91)
    tick(mt, dry=True)
    out = capsys.readouterr().out
    assert "$ herdr tab create --workspace wT" in out and "COFOUNDY_DESPERTADA=1 --no-focus" in out  # legacy-herdr
    assert "$ herdr pane run dry:p1 'claude --resume s-tsc'" in out  # legacy-herdr
    assert world.herdr == [] and not mt.desp_file(False).exists()
    assert mt.fold()["e1"]["link"]["pane"] == "wT:p3"  # en seco no toca el store


# ── dormir y las invariantes de myturn ───────────────────────────────────────────────────────────────────────
def here_as(mt, monkeypatch, session, pane="wT:p3"):
    monkeypatch.setattr(mt, "here", lambda: {"agent_session": {"value": session}, "pane_id": pane, "cwd": "/tmp/tsc"})


def test_dormir_registra_reemplaza_y_renueva(mt, world, clock, monkeypatch):
    here_as(mt, monkeypatch, "s-vieja")
    assert "NO está corriendo" in mt.dormir(GRUPO, "TSC · Alex")
    mt.write_atomic(mt.desp_file(False), json.dumps({"latido": mt.iso(mt.now())}))
    here_as(mt, monkeypatch, "s-nueva")
    out = mt.dormir(GRUPO, "TSC · Alex")
    assert "despierta esta sesión" in out
    es = mt.esperas(mt.fold())
    assert len(es) == 1 and es[0]["link"]["session"] == "s-nueva" and es[0]["link"]["cwd"] == "/tmp/tsc"
    clock(days=10)
    mt.dormir(GRUPO, None)
    assert len(mt.esperas(mt.fold())) == 1 and mt.esperas(mt.fold())[0]["expires"].startswith("2026-12-08")
    with pytest.raises(SystemExit):
        mt.dormir("alex", None)


def test_garden_bind_y_by_session_respetan_la_espera(mt, world, clock, monkeypatch):
    espera(mt)
    monkeypatch.setattr(mt, "herdr_agents", lambda host, fresh=False: [])  # dormida = sin agente vivo
    assert mt.garden(use_ai=False) == []
    assert "s-tsc" not in mt.by_session(mt.fold())
    mt.emit("add", "real", title="Seguimiento TSC", link={"host": mt.LOCAL, "session": "s-tsc", "pane": "wT:p3"})
    assert mt.by_session(mt.fold())["s-tsc"]["id"] == "real"
    mt.bind(mt.fold(), mt.fold()["real"], mt.LOCAL, {"agent_session": {"value": "s-tsc"}, "pane_id": "wT:p3"})
    assert mt.fold()["e1"]["status"] == "open"
    st = mt.classify(mt.fold(), {}, {mt.LOCAL: []})
    assert [d["id"] for d in st["dormidas"]] == ["e1"] and "e1" not in [r["id"] for r in st["rows"]]
    clock(days=22)
    assert {a["id"] for a in mt.garden(use_ai=False)} >= {"e1"}  # caduca a los 21 días


def test_plist_no_se_carga_y_usa_uv(mt):
    pl = mt.despertador_plist()
    assert "<string>despertador</string>" in pl and "/uv</string>" in pl and "dev.andre.myturn-despertador" in pl


def test_cli_despertador_once_dry_run(tmp_path):
    """El comando entero, como lo correría André: un TUI falso en el PATH que solo responde `agent list`."""
    bindir = tmp_path / "bin"
    bindir.mkdir()
    (bindir / "herdr").write_text("#!/bin/sh\necho '{\"result\":{\"agents\":[]}}'\n")  # legacy-herdr
    (bindir / "hc").write_text("#!/bin/sh\nexit 1\n")
    for f in bindir.iterdir():
        f.chmod(0o755)
    env = {**os.environ, "MYTURN_HOME": str(tmp_path / "t"), "MYTURN_CACHE": str(tmp_path / "c"),
           "MYTURN_NO_SYNC": "1", "MYTURN_WACLI_EVENTS": str(tmp_path / "ev.jsonl"),
           "MYTURN_PATH": f"{bindir}:/usr/bin:/bin"}
    (tmp_path / "ev.jsonl").write_text("")
    p = subprocess.run([str(SCRIPT), "despertador", "--once", "--dry-run"], env=env, capture_output=True, text=True,
                       timeout=60)
    assert p.returncode == 0, p.stderr
    assert json.loads((tmp_path / "c" / "despertador.dry.json").read_text())["pos"]["offset"] == 0


# ── hallazgos del auditor (2026-11-07) ───────────────────────────────────────────────────────────────────────
def test_respuesta_antes_de_dormir_igual_despierta(mt, world, clock):
    """El agente envía, el cliente contesta en 30 s y el agente corre `dormir` al minuto: no se pierde."""
    tick(mt)
    write(mt, msg(Timestamp=mt.iso(mt.now())))
    tick(mt)  # todavía no hay espera: el despertador lo recuerda
    clock(seconds=60)
    espera(mt)
    world.agents = [claude("s-tsc", "idle", "wT:p3")]
    tick(mt)
    prompts = [c for c in world.herdr if c[:2] == ["agent", "prompt"]]  # legacy-herdr
    assert len(prompts) == 1 and "1 mensaje nuevo" in prompts[0][3]


def test_espera_nueva_no_cuenta_dos_veces_el_mensaje_del_mismo_tick(mt, world, clock):
    tick(mt)
    espera(mt)
    write(mt, msg(Timestamp=mt.iso(mt.now())))
    tick(mt)
    assert mt.desp_load()["pend"]["e1"]["n"] == 1


def test_mensaje_viejo_de_antes_del_envio_no_despierta_la_espera_nueva(mt, world, clock):
    tick(mt)
    write(mt, msg(Timestamp=mt.iso(mt.now())))
    tick(mt)
    clock(minutes=4)  # dentro de lo que se recuerda (5 min) pero antes del envío (3 min antes de dormir)
    espera(mt)
    tick(mt)
    assert mt.desp_load()["pend"] == {}


def test_resume_lento_no_pierde_el_puntero(mt, world, clock):
    espera(mt)
    tick(mt)
    write(mt, msg())
    tick(mt)
    clock(seconds=91)
    tick(mt)
    clock(seconds=200)
    tick(mt)  # no quedó idle en 180 s: aviso, pero el puntero queda
    assert world.verbs().count("tab create") == 1
    clock(seconds=200)
    tick(mt)
    assert world.verbs().count("tab create") == 1  # no reabre en bucle
    world.agents = [claude("s-tsc", "idle", "wT:n1")]
    tick(mt)
    assert any(c[:2] == ["agent", "prompt"] for c in world.herdr)


def test_no_cierra_el_panel_que_andre_tiene_delante(mt, world, clock, monkeypatch):
    espera(mt)
    world.agents = [claude("s-tsc", "idle", "wT:p3", focused=True)]
    monkeypatch.setattr(mt, "herdr_frontmost", lambda: mt.LOCAL)
    monkeypatch.setattr(mt, "ventana_al_frente", lambda: "tui")
    tick(mt)
    clock(minutes=11)
    tick(mt)
    assert ["pane", "close", "wT:p3"] not in world.herdr
    assert world.herdr[-1][-1] == "💤 se duerme cuando salgas"
    monkeypatch.setattr(mt, "herdr_frontmost", lambda: None)
    monkeypatch.setattr(mt, "ventana_al_frente", lambda: None)
    clock(seconds=15)
    tick(mt)
    assert world.herdr[-1] == ["pane", "close", "wT:p3"]


# ── auditor, vuelta 2 ────────────────────────────────────────────────────────────────────────────────────────
def test_tras_un_fallo_el_mensaje_siguiente_vuelve_a_abrir(mt, world, clock):
    espera(mt)
    tick(mt)
    write(mt, msg())
    tick(mt)
    clock(seconds=91)
    tick(mt)
    clock(seconds=200)
    tick(mt)  # no despertó: aviso + puntero con fallo
    clock(hours=20)
    write(mt, msg(Timestamp=mt.iso(mt.now())))
    tick(mt)
    clock(seconds=91)
    tick(mt)
    assert world.verbs().count("tab create") == 2


def test_renovar_la_espera_no_entrega_dos_veces(mt, world, clock):
    espera(mt)
    world.agents = [claude("s-tsc", "idle", "wT:p3")]
    tick(mt)
    write(mt, msg(Timestamp=mt.iso(mt.now())))
    tick(mt)
    clock(seconds=91)
    tick(mt)
    assert sum(c[:2] == ["agent", "prompt"] for c in world.herdr) == 1
    clock(seconds=60)
    mt.emit("update", "e1", set={"expires": mt.iso(mt.now() + timedelta(days=21))})  # contesta y vuelve a dormir
    clock(seconds=15)
    tick(mt)
    clock(seconds=91)
    tick(mt)
    assert sum(c[:2] == ["agent", "prompt"] for c in world.herdr) == 1


def test_el_mensaje_ya_contestado_no_despierta_la_espera_nueva(mt, world, clock):
    tick(mt)
    write(mt, msg(Timestamp=mt.iso(mt.now())))  # el cliente escribe
    tick(mt)
    clock(seconds=60)
    write(mt, msg(FromMe=True, Timestamp=mt.iso(mt.now())))  # el agente contesta y duerme en el mismo tick
    espera(mt)
    tick(mt)
    assert mt.desp_load()["pend"] == {}


def test_una_reaccion_de_andre_no_tapa_la_respuesta_del_cliente(mt, world, clock):
    """Auditor, vuelta 3: solo un mensaje con contenido cuenta como «el equipo ya contestó»."""
    tick(mt)
    write(mt, msg(Timestamp=mt.iso(mt.now())))
    tick(mt)
    clock(seconds=20)
    write(mt, msg(FromMe=True, text="", ReactionEmoji="👍", Timestamp=mt.iso(mt.now())))
    tick(mt)
    clock(seconds=40)
    espera(mt)
    tick(mt)
    assert mt.desp_load()["pend"]["e1"]["n"] == 1


# ── horario de atención (André 2026-11-11, 20:32: «escuchar todo, sí; reaccionar a todo, no; ante urgencias sí») ──
HABILES = Path.home() / "cofoundy/plugins/cofoundy-toolkit/skills/whatsapp/scripts/habiles.py"
HORARIO_VH = "L-V 09:00-20:00 America/Lima"


@pytest.fixture
def horario(mt, monkeypatch):
    """habiles.py real (la primitiva del toolkit), Haiku falso y avisos de macOS anotados. Reloj: miércoles
    11-nov-2026 21:30 en Lima (fuera de L-V 09:00-20:00). Devuelve (clock, mundo) con .triage y .mac."""
    if not HABILES.is_file():
        pytest.skip("sin el checkout de cofoundy-toolkit (habiles.py)")
    from zoneinfo import ZoneInfo
    monkeypatch.setenv("MYTURN_HABILES", str(HABILES))
    t = {"now": datetime(2026, 11, 11, 21, 30, tzinfo=ZoneInfo("America/Lima"))}
    monkeypatch.setattr(mt, "now", lambda: t["now"])
    ns = type("H", (), {})()
    ns.triage, ns.mac, ns.respuesta = [], [], {"urgente": False, "motivo": "ninguna"}

    def fake_claude(prompt, schema, model="haiku", timeout=120):
        ns.triage.append((model, prompt))
        return ns.respuesta
    monkeypatch.setattr(mt, "claude_json", fake_claude)
    monkeypatch.setattr(mt, "notify", lambda msg, sound=False: ns.mac.append(msg))

    def advance(**delta):
        t["now"] += timedelta(**delta)
    ns.clock, ns.at = advance, (lambda: t["now"])
    return ns


def espera_h(mt, horario_txt=HORARIO_VH):
    mt.emit("add", "e1", title="espera: VH · revisión", source=mt.ESPERA, wake={"wsp": GRUPO, "horario": horario_txt},
            expires=mt.iso(mt.now() + timedelta(days=21)),
            link={"host": mt.LOCAL, "session": "s-vh", "pane": "wT:p3", "cwd": "/tmp/vh"})


def msg_ahora(h, i, **kw):
    return msg(ID=f"M{i}", Timestamp=h.at().astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), **kw)


def test_en_horario_despierta_como_siempre_sin_triage(mt, world, horario):
    horario.clock(hours=-10)  # miércoles 11:30, dentro del horario
    espera_h(mt)
    tick(mt)
    write(mt, msg_ahora(horario, 1))
    tick(mt)
    horario.clock(seconds=91)
    tick(mt)
    assert world.verbs().count("tab create") == 1
    assert horario.triage == [] and horario.mac == []


def test_fuera_de_horario_no_urgente_difiere_duerme_y_despierta_una_vez_al_abrir(mt, world, horario):
    espera_h(mt)
    world.agents = [claude("s-vh", "idle", "wT:p3")]  # viva y ociosa: no se le escribe, se duerme igual
    tick(mt)
    write(mt, msg_ahora(horario, 1, text="gracias, mañana lo reviso"))
    tick(mt)
    horario.clock(hours=1)
    write(mt, msg_ahora(horario, 2, text="y te mando las fotos"))
    tick(mt)
    assert len(horario.triage) == 2 and all(m == "haiku" for m, _ in horario.triage)  # una vez por mensaje
    assert "gracias, mañana lo reviso" in horario.triage[0][1]
    assert not any(c[:2] in (["agent", "prompt"], ["tab", "create"]) for c in world.herdr)
    p = mt.desp_load()["pend"]["e1"]
    assert p["n"] == 2 and p["abre"].startswith("2026-11-12T09:00")
    # la cuenta regresiva (10 min idle desde las 21:30) no la frena el pendiente diferido: se durmió
    assert ["pane", "close", "wT:p3"] in world.herdr
    world.agents = []
    horario.clock(hours=10, minutes=11)  # jueves 08:41: todavía cerrado
    tick(mt)
    assert world.verbs().count("tab create") == 0
    horario.clock(minutes=20)  # jueves 09:01: abre
    tick(mt)
    tick(mt)
    assert world.verbs().count("tab create") == 1
    world.agents = [claude("s-vh", "idle", "wT:n1")]
    horario.clock(seconds=15)
    tick(mt)
    prompts = [c for c in world.herdr if c[:2] == ["agent", "prompt"]]  # legacy-herdr
    assert len(prompts) == 1
    txt = prompts[0][3]
    assert "2 mensajes" in txt and "desde el mié 11-11 21:30" in txt and "hasta las 22:30" in txt
    assert f"fuera del horario de atención ({HORARIO_VH})" in txt and "ninguno era urgente" in txt
    assert "gracias" not in txt and "fotos" not in txt  # nada del cliente en el puntero
    assert horario.mac == []
    horario.clock(minutes=5)
    tick(mt)
    assert world.verbs().count("tab create") == 1  # ese día, una sola vez


def test_fuera_de_horario_urgente_despierta_ya_y_avisa_en_macos(mt, world, horario):
    horario.respuesta = {"urgente": True, "motivo": "web o servicio caído"}
    espera_h(mt)
    tick(mt)
    write(mt, msg_ahora(horario, 1, text="la web no carga, se cayó todo"))
    tick(mt)  # sin esperar el debounce de la ráfaga
    assert world.verbs().count("tab create") == 1
    assert horario.mac and "web o servicio caído" in horario.mac[0] and "se cayó" not in horario.mac[0]
    world.agents = [claude("s-vh", "idle", "wT:n1")]
    horario.clock(seconds=15)
    tick(mt)
    txt = next(c for c in world.herdr if c[:2] == ["agent", "prompt"])[3]  # legacy-herdr
    assert "urgente (web o servicio caído)" in txt and "no carga" not in txt
    assert len(horario.mac) == 1


def test_fuera_de_horario_triage_fallido_despierta(mt, world, horario):
    horario.respuesta = None  # claude no está, timeout o JSON roto
    espera_h(mt)
    tick(mt)
    write(mt, msg_ahora(horario, 1))
    tick(mt)
    assert world.verbs().count("tab create") == 1
    assert "el triage falló" in mt.desp_load()["abriendo"]["e1"]["urgente"]


def test_espera_sin_horario_hereda_el_default(mt, world, horario):
    """El default es el que hereda todo cliente sin brief: 20:30 de un miércoles está fuera de L-V 09:00-18:00."""
    mt.emit("add", "e1", title="espera: X", source=mt.ESPERA, wake={"wsp": GRUPO},
            expires=mt.iso(mt.now() + timedelta(days=21)),
            link={"host": mt.LOCAL, "session": "s-x", "pane": "wT:p3", "cwd": "/tmp"})
    horario.clock(hours=-1)
    tick(mt)
    write(mt, msg_ahora(horario, 1))
    tick(mt)
    assert len(horario.triage) == 1 and mt.desp_load()["pend"]["e1"]["abre"].startswith("2026-11-12T09:00")


def test_dormir_toma_el_horario_del_brief_del_chat(mt, world, horario, monkeypatch):
    def run(cmd, host=None, timeout=4):
        if cmd[0] == "uv" and "horario" in cmd:
            return subprocess.CompletedProcess(cmd, 0, json.dumps({"horario": HORARIO_VH}), "")
        return world.run(cmd, host, timeout)
    monkeypatch.setattr(mt, "run", run)
    here_as(mt, monkeypatch, "s-vh")
    out = mt.dormir(GRUPO, "VH · revisión")
    assert mt.esperas(mt.fold())[0]["wake"] == {"wsp": GRUPO, "horario": HORARIO_VH}
    mt.write_atomic(mt.desp_file(False), json.dumps({"latido": mt.iso(mt.now())}))
    out = mt.dormir(GRUPO, None, "L-D 08:00-22:00 America/Lima")  # explícito gana y renueva
    assert "fuera, solo por urgencia" in out
    assert mt.esperas(mt.fold())[0]["wake"]["horario"] == "L-D 08:00-22:00 America/Lima"
    with pytest.raises(SystemExit):
        mt.dormir(GRUPO, None, "todo el día")


# ── Coresponde: el WhatsApp del negocio, por REST (dotfiles#5) ───────────────────────────────────────────────
CON = "con_01M6PV1CS97XX51HV3X933H4BM"
OTRO = "con_01M0WZEND8DTSFHHQSCZR92ZFY"
PORTA = "/Users/x/cofoundy/products/portafolios/.claude/worktrees/proceso-agencia"


class Coresponde:
    """El REST de Coresponde falso: `conv` es GET /conversations/{id}, `msgs` GET …/messages; `calls` lo pedido."""

    def __init__(self):
        self.conv = {"id": CON, "ai_enabled": False, "ai_paused_reason": "handoff", "status": "open",
                     "last_message": None}
        self.msgs: list[dict] = []
        self.calls: list[str] = []
        self.falla = None

    def get(self, path, params=None):
        self.calls.append(path)
        if self.falla:
            raise self.falla
        if path.endswith("/messages"):
            return {"data": list(self.msgs), "pagination": {"has_more": False}}
        return self.conv

    def entra(self, i, at, text="ya elegí el territorio 2", **kw):
        m = {"id": f"msg_{i}", "conversation_id": CON, "direction": "inbound", "content": text, "media": None,
             "delivery_status": "delivered", "is_internal": False, "system_kind": None,
             "timestamp": at.astimezone(timezone.utc).isoformat(), **kw}
        self.msgs.append(m)
        self.conv["last_message"] = {"direction": m["direction"], "timestamp": m["timestamp"], "content": text}
        return m

    def sale(self, i, at, status="sent", **kw):
        return self.entra(i, at, text="¿cuál territorio te gustó?", direction="outbound", delivery_status=status, **kw)


@pytest.fixture
def cr(mt, monkeypatch):
    c = Coresponde()
    monkeypatch.setattr(mt, "coresponde_get", c.get)
    monkeypatch.setenv("TRACTA_API_KEY", "fov_prueba")
    monkeypatch.delenv("INBOXAI_API_KEY", raising=False)
    return c


def espera_cr(mt, excepcion="portafolios", session="s-pame", con=CON, tid="c1", **wake):
    w = {"coresponde": con, **({"excepcion": excepcion} if excepcion else {}), **wake}
    mt.emit("add", tid, title="espera: Pame · E4", source=mt.ESPERA, wake=w,
            expires=mt.iso(mt.now() + timedelta(days=21)),
            link={"host": mt.LOCAL, "session": session, "pane": "wP:p1", "cwd": PORTA})


def test_dormir_coresponde_registra_la_excepcion_por_cwd_y_estado_la_muestra(mt, world, clock, monkeypatch, capsys,
                                                                              cr):
    mt.write_atomic(mt.desp_file(False), json.dumps({"latido": mt.iso(mt.now())}))
    monkeypatch.setattr(mt, "here", lambda: {"agent_session": {"value": "s-pame"}, "pane_id": "wP:p1", "cwd": PORTA})
    out = mt.dormir(None, "Pame · E4", None, CON, "E4 · Territorios")
    assert f"messages_send SOLO en {CON}" in out and "politica-mensajes.md" in out
    (t,) = mt.esperas(mt.fold())
    assert t["wake"]["coresponde"] == CON and t["wake"]["excepcion"] == "portafolios"
    assert t["wake"]["etapa"] == "E4 · Territorios" and "wsp" not in t["wake"]
    # otra sesión fuera de Portafolios: reemplaza la espera de ese chat y NO hereda la excepción
    monkeypatch.setattr(mt, "here", lambda: {"agent_session": {"value": "s-otra"}, "pane_id": "wD:p1",
                                             "cwd": "/Users/x/cofoundy/deals"})
    assert "solo borradores" in mt.dormir(None, None, None, CON)
    (t,) = mt.esperas(mt.fold())
    assert t["link"]["session"] == "s-otra" and "excepcion" not in t["wake"]
    with pytest.raises(SystemExit):
        mt.dormir(None, None, None, "pame")
    capsys.readouterr()
    mt.main(["despertador", "estado"])
    (e,) = json.loads(capsys.readouterr().out)["esperas"]
    assert e["chat"] == CON and e["sesion"] == "s-otra"


def test_dormir_coresponde_avisa_si_falta_la_key(mt, world, clock, monkeypatch, tmp_path):
    for k in ("TRACTA_API_KEY", "INBOXAI_API_KEY", "TRACTA_API_URL", "INBOXAI_API_URL"):
        monkeypatch.delenv(k, raising=False)
    monkeypatch.setattr(mt, "CLAUDE_SETTINGS", tmp_path / "no-hay.json")
    mt.write_atomic(mt.desp_file(False), json.dumps({"latido": mt.iso(mt.now())}))
    monkeypatch.setattr(mt, "here", lambda: {"agent_session": {"value": "s"}, "pane_id": "wP:p1", "cwd": PORTA})
    assert "falta TRACTA_API_KEY" in mt.dormir(None, None, None, CON)
    (tmp_path / "s.json").write_text(json.dumps({"env": {"TRACTA_API_KEY": "fov_de_settings"}}))
    monkeypatch.setattr(mt, "CLAUDE_SETTINGS", tmp_path / "s.json")
    assert mt.coresponde_cfg() == (mt.CORESPONDE_URL, "fov_de_settings")  # el daemon de launchd la lee de ahí


def test_coresponde_cfg_lee_tracta_y_cae_a_inboxai_hasta_2027_02_11(mt, monkeypatch, tmp_path):
    for k in ("TRACTA_API_KEY", "INBOXAI_API_KEY", "TRACTA_API_URL", "INBOXAI_API_URL"):
        monkeypatch.delenv(k, raising=False)
    (tmp_path / "s.json").write_text(json.dumps({"env": {"INBOXAI_API_KEY": "vieja", "INBOXAI_API_URL": "http://v/"}}))
    monkeypatch.setattr(mt, "CLAUDE_SETTINGS", tmp_path / "s.json")
    assert mt.coresponde_cfg() == ("http://v", "vieja")  # solo el nombre viejo: fallback
    monkeypatch.setenv("TRACTA_API_KEY", "nueva")
    monkeypatch.setenv("INBOXAI_API_KEY", "vieja-env")
    monkeypatch.setenv("TRACTA_API_URL", "http://n/")
    assert mt.coresponde_cfg() == ("http://n", "nueva")  # el nombre nuevo gana


def test_coresponde_en_handoff_despierta_con_la_excepcion_y_un_puntero_sin_el_texto(mt, world, clock, cr):
    espera_cr(mt)
    cr.sale(0, mt.now() - timedelta(minutes=1))  # el agente preguntó y se durmió
    tick(mt)
    assert world.herdr == []
    cr.entra(1, mt.now() + timedelta(seconds=1))
    clock(seconds=61)  # la siguiente consulta (cada minuto)
    tick(mt)
    assert mt.desp_load()["pend"]["c1"]["n"] == 1
    clock(seconds=30)  # 91 s desde que llegó: la ráfaga cuenta desde el mensaje, no desde la consulta
    tick(mt)
    create, run_ = world.herdr
    envs = [create[i + 1] for i, a in enumerate(create) if a == "--env"]
    assert envs == ["COFOUNDY_DESPERTADA=1", "COFOUNDY_DESPERTADA_EXCEPCION=portafolios",
                    f"COFOUNDY_DESPERTADA_CHAT={CON}"]
    assert "--no-focus" in create and run_ == ["pane", "run", "wT:n1", "claude --resume s-pame"]
    world.agents = [claude("s-pame", "idle", "wT:n1")]
    clock(seconds=15)
    tick(mt)
    txt = next(c for c in world.herdr if c[:2] == ["agent", "prompt"])[3]  # legacy-herdr
    assert f"chat de Coresponde {CON}" in txt and "messages_list" in txt and "SOLO en " + CON in txt
    assert "politica-mensajes.md" in txt and "territorio 2" not in txt  # el texto del cliente nunca va al puntero


def test_coresponde_con_la_ia_contestando_no_despierta_ni_lee_el_hilo(mt, world, clock, cr):
    cr.conv["ai_enabled"], cr.conv["ai_paused_reason"] = True, None
    espera_cr(mt)
    cr.entra(1, mt.now())
    tick(mt)
    clock(seconds=200)
    tick(mt)
    assert world.herdr == [] and not mt.desp_load().get("pend")
    assert not any(c.endswith("/messages") for c in cr.calls)  # ni siquiera pide los mensajes


def test_coresponde_escalado_despierta_aunque_la_ia_figure_prendida(mt, world, clock, cr):
    cr.conv["ai_enabled"], cr.conv["status"] = True, "escalated"
    espera_cr(mt, excepcion=None)
    cr.entra(1, mt.now() - timedelta(minutes=2))
    tick(mt)
    create = next(c for c in world.herdr if c[:2] == ["tab", "create"])  # legacy-herdr
    assert [create[i + 1] for i, a in enumerate(create) if a == "--env"] == ["COFOUNDY_DESPERTADA=1"]


def test_coresponde_lo_contestado_lo_viejo_y_lo_ya_contado_no_despiertan(mt, world, clock, cr):
    espera_cr(mt)
    cr.entra(1, mt.now() - timedelta(minutes=30))  # de antes de `dormir`
    cr.entra(2, mt.now() - timedelta(minutes=2))
    cr.sale(3, mt.now() - timedelta(minutes=1))  # ya contestado
    cr.sale(4, mt.now(), status="draft")  # un borrador no contesta nada…
    tick(mt)
    assert not mt.desp_load().get("pend")
    cr.entra(5, mt.now() + timedelta(seconds=5), is_internal=True)  # …ni una nota interna es del cliente
    cr.entra(6, mt.now() + timedelta(seconds=6), text="", system_kind="revoke")
    clock(seconds=61)
    tick(mt)
    assert not mt.desp_load().get("pend")
    cr.entra(7, mt.now())
    clock(seconds=61)
    tick(mt)
    clock(seconds=61)
    cr.conv["last_message"]["timestamp"] = "2026-11-07T15:59:59+00:00"  # cambió algo, se relee la página
    tick(mt)
    assert sum(1 for c in world.herdr if c[:2] == ["tab", "create"]) == 1  # legacy-herdr
    assert mt.desp_load()["abriendo"]["c1"]["n"] == 1  # el mismo mensaje no se cuenta dos veces


def test_coresponde_consulta_cada_minuto_y_un_error_se_loguea_una_vez(mt, world, clock, cr):
    espera_cr(mt)
    tick(mt)
    n = len(cr.calls)
    clock(seconds=15)
    tick(mt)
    assert len(cr.calls) == n  # dentro del minuto no consulta
    cr.falla = mt.CorespondeError("HTTP 403 en /conversations/x")
    clock(seconds=61)
    assert any("HTTP 403" in ln for ln in tick(mt))
    clock(seconds=61)
    assert not any("coresponde" in ln for ln in tick(mt))  # el mismo error no se repite cada minuto
    assert "HTTP 403" in mt.desp_load()["coresponde"]["error"]
    cr.falla = None
    clock(seconds=61)
    assert "coresponde: vuelve a responder" in tick(mt)


def test_coresponde_fuera_de_horario_respeta_el_triage(mt, world, horario, cr):
    espera_cr(mt, horario=HORARIO_VH)
    tick(mt)
    cr.entra(1, horario.at(), text="gracias, mañana veo")
    horario.clock(seconds=61)
    tick(mt)
    assert len(horario.triage) == 1 and "gracias, mañana veo" in horario.triage[0][1]
    assert mt.desp_load()["pend"]["c1"]["abre"].startswith("2026-11-12T09:00")
    assert not any(c[:2] == ["tab", "create"] for c in world.herdr)


def test_cli_coresponde_once_dry_run_contra_un_api_falso(mt, tmp_path):
    """El comando entero del issue contra un REST falso: en handoff imprime el herdr; con la IA activa, nada."""
    import threading
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

    estado = {"ai": False}
    ts = (datetime.now(timezone.utc) - timedelta(minutes=2)).isoformat()

    class H(BaseHTTPRequestHandler):
        def do_GET(self):
            assert self.headers["X-API-Key"] == "fov_prueba"
            if self.path.startswith(f"/api/v1/conversations/{CON}/messages"):
                body = {"data": [{"id": "msg_1", "direction": "inbound", "content": "hola", "timestamp": ts,
                                  "delivery_status": "delivered", "is_internal": False}]}
            elif self.path == f"/api/v1/conversations/{CON}":
                body = {"id": CON, "ai_enabled": estado["ai"], "status": "open",
                        "last_message": {"direction": "inbound", "timestamp": ts}}
            else:
                self.send_response(404)
                self.end_headers()
                return
            data = json.dumps(body).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(data)

        def log_message(self, *a):
            pass

    srv = ThreadingHTTPServer(("127.0.0.1", 0), H)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    mt.emit("add", "c1", title="espera: Pame · E4", source=mt.ESPERA,
            wake={"coresponde": CON, "excepcion": "portafolios"},
            expires=mt.iso(mt.now() + timedelta(days=21)),
            link={"host": mt.LOCAL, "session": "s-pame-prueba", "pane": "wP:p1", "cwd": str(tmp_path)})
    bindir = tmp_path / "bin"  # el TUI de respaldo: herdr responde y el core de hc no (legacy-herdr)
    bindir.mkdir()
    (bindir / "herdr").write_text("#!/bin/sh\necho '{\"result\":{\"agents\":[]}}'\n")  # legacy-herdr
    (bindir / "hc").write_text("#!/bin/sh\nexit 1\n")
    for f in bindir.iterdir():
        f.chmod(0o755)

    def corre(cache, bindir=bindir):
        env = {**os.environ, "MYTURN_CACHE": str(tmp_path / cache), "MYTURN_HABILES": str(tmp_path / "no-hay.py"),
               "TRACTA_API_KEY": "fov_prueba", "TRACTA_API_URL": f"http://127.0.0.1:{srv.server_port}/api/v1",
               "MYTURN_PATH": f"{bindir}:/usr/bin:/bin", "MYTURN_CLAUDE_SESSIONS": str(tmp_path / "sessions")}
        for k in ("HERDR_PANE_ID", "HC_TERMINAL_ID", "HC_TERMINAL_SOCKET",  # sin terminal; legacy-herdr
                  "INBOXAI_API_KEY", "INBOXAI_API_URL"):
            env.pop(k, None)
        p = subprocess.run([str(SCRIPT), "despertador", "--once", "--dry-run"], env=env, capture_output=True,
                           text=True, timeout=60)
        assert p.returncode == 0, p.stderr
        return p.stdout

    try:
        out = corre("c-handoff")
        assert "$ herdr tab create" in out and f"COFOUNDY_DESPERTADA_CHAT={CON}" in out  # legacy-herdr
        assert "$ herdr pane run dry:p1 'claude --resume s-pame-prueba'" in out  # legacy-herdr
        # la app: el core de hc responde y el TUI viejo sale con error y anota cada llamada
        app = tmp_path / "bin-app"
        app.mkdir()
        (app / "herdr").write_text(f"#!/bin/sh\necho \"$*\" >> {tmp_path}/herdr.log\nexit 1\n")  # legacy-herdr
        (app / "hc").write_text(
            "#!/bin/sh\n[ \"$1\" = ls ] && echo '{\"terminals\":[],\"machines\":[]}' && exit 0\nexit 1\n")
        (app / "herdr-app").write_text("#!/bin/sh\n[ \"$1\" = ls ] && echo '{\"spaces\":[]}' && exit 0\nexit 1\n")
        for f in app.iterdir():
            f.chmod(0o755)
        out = corre("c-app", app)
        run_ = next(ln for ln in out.splitlines() if ln.startswith("$ hc run "))
        assert "--bg --keep --no-parent" in run_ and "--label herdr.space=sp" in run_ and "--label herdr.tab=tb" in run_
        assert (f"env COFOUNDY_DESPERTADA=1 COFOUNDY_DESPERTADA_EXCEPCION=portafolios COFOUNDY_DESPERTADA_CHAT={CON} "
                "claude --resume s-pame-prueba") in run_
        assert "$ herdr-app do space.rename" in out and "--name Pame" in out  # espacio nuevo con el nombre del cliente
        assert "$ herdr " not in out and "agent.focus" not in out  # sin foco y nada al TUI
        estado["ai"] = True  # control negativo: la IA contesta ese hilo
        assert "herdr" not in corre("c-ia")  # legacy-herdr
    finally:
        srv.shutdown()


# ── H1: la Herdr app (hc + herdr-app). Diseño: core/docs/research/2026-11-12_herdr-hub-operaciones/migracion/
#    h1-despertador/
class App(World):
    """La app falsa: `hc` (terminales) + `herdr-app` (ventana) + `ps`. El TUI viejo FALLA y anota cada llamada:
    lo que todavía dependa de él se ve en `self.tui`. `terms` = {dirección: (sesión, estado, pid)}."""

    def __init__(self, sessions: Path):
        super().__init__()
        self.terms: dict[str, tuple] = {}
        self.spaces = [{"id": "spTSC", "name": "TSC", "machine": None, "tabs": [{"id": "tbV", "name": "pm"}]}]
        self.hc: list[list[str]] = []
        self.app: list[list[str]] = []
        self.tui: list[list[str]] = []
        self.foco = None
        self.tui_ws: dict[str, str] = {}  # workspaces del TUI que responde (vacío: el TUI falla)
        self.sessions = sessions
        self.n = 0
        self.where: dict[str, str] = {}  # dirección → label «where» («espacio / pestaña») que pone la app

    def run(self, cmd, host=None, timeout=4):
        def ok(out=""):
            return subprocess.CompletedProcess(cmd, 0, out, "")
        if cmd[0] == "herdr":  # legacy-herdr
            self.tui.append(cmd[1:])
            if self.tui_ws and cmd[1:3] == ["workspace", "list"]:
                return ok(json.dumps({"result": {"workspaces": [{"workspace_id": k, "label": v}
                                                                for k, v in self.tui_ws.items()]}}))
            return subprocess.CompletedProcess(cmd, 1, "", "herdr: no server")
        if cmd[0] == "hc":
            if cmd[1] == "ls":
                return ok(json.dumps({"terminals": [{"address": a, "agent": "claude-code", "state": "live"}
                                                    for a in self.terms], "machines": []}))
            if cmd[1] == "get":
                a = cmd[2]
                if a not in self.terms:
                    return subprocess.CompletedProcess(cmd, 1, "", "no such terminal")
                s, st, pid = self.terms[a]
                return ok(json.dumps({"address": a, "turn": 1, "status_ms": 5, "title": "✳ TSC",
                                      "status": {"app": "claude-code", "state": st},
                                      "foreground": {"argv": ["claude"], "cwd": "/tmp/tsc", "pid": pid},
                                      "labels": {"herdr.space": "spTSC", "herdr.tab": f"tb{a}",
                                                 **({"where": self.where[a]} if a in self.where else {})}}))
            self.hc.append(cmd[1:])
            if cmd[1] == "run":
                self.n += 1
                tab = next(x.split("=", 1)[1] for x in cmd if x.startswith("herdr.tab="))
                sp = next(x.split("=", 1)[1] for x in cmd if x.startswith("herdr.space="))
                if not any(x["id"] == sp for x in self.spaces):
                    self.spaces.append({"id": sp, "name": "", "machine": None, "tabs": []})
                next(x for x in self.spaces if x["id"] == sp)["tabs"].append({"id": tab, "name": "1"})
                return ok(json.dumps({"address": f"t9{self.n}", "state": "live"}))
            return ok("{}")
        if cmd[0] == "herdr-app":
            if cmd[1] == "ls":
                return ok(json.dumps({"spaces": self.spaces}))
            if cmd[1] == "status":
                return ok(json.dumps({"agent": self.foco}))
            self.app.append(cmd[1:])
            return ok('{"ok": true}')
        if cmd[0] == "ps":
            return subprocess.run(cmd, capture_output=True, text=True)
        return super().run(cmd, host, timeout)

    def vivo(self, addr, session, status="idle"):
        """Un Claude vivo en la app: su terminal y su ~/.claude/sessions/<pid>.json."""
        pid = 40000 + len(self.terms)
        self.sessions.mkdir(exist_ok=True)
        (self.sessions / f"{pid}.json").write_text(json.dumps({"pid": pid, "sessionId": session}))
        self.terms[addr] = (session, status, pid)
        self.spaces[0]["tabs"].append({"id": f"tb{addr}", "name": "pm"})


@pytest.fixture
def app(mt, monkeypatch, tmp_path):
    w = App(tmp_path / "sessions")
    monkeypatch.setattr(mt, "run", w.run)
    monkeypatch.setattr(mt, "herdr_frontmost", lambda: None)
    monkeypatch.setattr(mt, "ventana_al_frente", lambda: None)
    monkeypatch.setattr(mt, "_toolkit_file", lambda rel: tmp_path / rel)
    monkeypatch.setattr(mt.time, "sleep", lambda s: None)
    return w


def test_h1_dormida_del_tui_despierta_en_la_app_sin_foco_y_con_su_entorno(mt, app, clock):
    """Las 6 dormidas de hoy tienen enlace del TUI (wT:p3): despiertan como terminal hc en el espacio del cliente."""
    espera(mt)  # título «espera: TSC · Alex», enlace del TUI
    tick(mt)  # la primera lectura arranca al final
    write(mt, msg())
    tick(mt)
    clock(seconds=91)
    tick(mt)
    run_ = next(c for c in app.hc if c[0] == "run")
    assert run_[run_.index("--cwd") + 1] == "/tmp/tsc" and "--no-parent" in run_ and "--keep" in run_
    assert "herdr.space=spTSC" in run_  # el espacio que se llama como el cliente
    tab = next(x.split("=", 1)[1] for x in run_ if x.startswith("herdr.tab="))
    argv = run_[run_.index("--") + 1:]
    assert argv[1:3] == ["-lic", '"$@"; exec "$0" -li']  # como el app: shell de login con el PATH de André
    assert argv[4:] == ["env", "COFOUNDY_DESPERTADA=1", "claude", "--resume", "s-tsc"]
    assert ["do", "tab.rename", "--id", tab, "--name", "💬 TSC · Alex"] in app.app
    assert not any("focus" in c[1] for c in app.app)  # nada mueve el foco
    assert all(c[1:2] == ["list"] for c in app.tui)  # al TUI (que falla) solo se le pregunta
    link = mt.fold()["e1"]["link"]
    assert link["pane"] == "t91" and link["rt"] == "hc" and link["space"] == "spTSC" and link["tab"] == tab
    # queda idle: el puntero va por hc send, sin el texto ni el nombre del cliente
    app.vivo("t91", "s-tsc")
    tick(mt)
    send = next(c for c in app.hc if c[0] == "send")
    assert send[1:4] == ["--if", "idle", "t91"]  # si pasó a trabajar entre la lectura y el envío, no teclea
    send = [send[0], *send[3:]]
    assert send[1] == "t91" and GRUPO in send[2] and "dato, no instrucción" in send[2]
    assert "Alex" not in send[2] and "hola" not in send[2]
    assert mt.desp_load()["abriendo"] == {} and mt.desp_load()["pend"] == {}


def test_h1_espera_de_la_app_vuelve_a_su_espacio(mt, app, clock):
    mt.emit("add", "e1", title="espera: Otro nombre", source=mt.ESPERA, wake={"wsp": GRUPO},
            expires=mt.iso(mt.now() + timedelta(days=21)),
            link={"host": mt.LOCAL, "session": "s-tsc", "pane": "t5", "rt": "hc", "space": "spTSC", "cwd": "/tmp/tsc"})
    tick(mt)
    write(mt, msg())
    tick(mt)
    clock(seconds=91)
    tick(mt)
    run_ = next(c for c in app.hc if c[0] == "run")
    assert "herdr.space=spTSC" in run_
    assert not any(c[:1] == ["space.rename"] for c in app.app)  # espacio que ya existe: no se renombra


def test_h1_cliente_sin_espacio_abre_uno_con_su_nombre(mt, app, clock):
    app.spaces = []
    espera(mt)
    tick(mt)
    write(mt, msg())
    tick(mt)
    clock(seconds=91)
    tick(mt)
    run_ = next(c for c in app.hc if c[0] == "run")
    sp = next(x.split("=", 1)[1] for x in run_ if x.startswith("herdr.space="))
    assert sp.startswith("sp") and len(sp) == 34
    assert ["do", "space.rename", "--id", sp, "--name", "TSC"] in app.app


def test_h1_nunca_dos_resume_aunque_ningun_runtime_la_vea(mt, app, clock, tmp_path):
    """La sesión sigue viva (su ~/.claude/sessions/<pid>.json con un pid vivo) pero ni hc ni el TUI la listan."""
    sessions = tmp_path / "sessions"
    sessions.mkdir()
    (sessions / f"{os.getpid()}.json").write_text(json.dumps(
        {"pid": os.getpid(), "sessionId": "s-tsc", "startedAt": int(datetime.now().timestamp() * 1000)}))
    espera(mt)
    tick(mt)
    write(mt, msg())
    tick(mt)
    clock(seconds=91)
    tick(mt)
    assert not any(c[0] == "run" for c in app.hc)
    assert mt.desp_load()["pend"]["e1"]["n"] == 1  # el puntero espera a que aparezca


def test_h1_pid_reciclado_no_cuenta_como_viva(mt, app, clock, tmp_path):
    sessions = tmp_path / "sessions"
    sessions.mkdir()
    (sessions / f"{os.getpid()}.json").write_text(json.dumps(  # mi pid, pero la sesión «empezó» hace un año
        {"pid": os.getpid(), "sessionId": "s-tsc", "startedAt": int((datetime.now().timestamp() - 3e7) * 1000)}))
    assert not mt.sesion_viva("s-tsc")


def test_h1_cuenta_regresiva_en_la_pestana_y_cierre_por_hc(mt, app, clock):
    espera(mt, pane="t7")
    app.vivo("t7", "s-tsc")
    tick(mt)
    assert app.app[-1] == ["do", "tab.rename", "--id", "tbt7", "--name", "💤 se duerme en 10:00"]
    assert mt.desp_load()["nombres"] == {"tbt7": "pm"}  # el nombre original, para devolverlo
    clock(minutes=4)
    app.terms["t7"] = ("s-tsc", "working", app.terms["t7"][2])
    tick(mt)
    assert app.app[-1] == ["do", "tab.rename", "--id", "tbt7", "--name", "pm"]  # vuelve a su nombre
    app.terms["t7"] = ("s-tsc", "idle", app.terms["t7"][2])
    tick(mt)
    clock(minutes=10, seconds=1)
    tick(mt)
    assert app.hc[-2:] == [["kill", "t7"], ["rm", "t7"]]
    assert not app.tui or all(c[:2] == ["agent", "list"] for c in app.tui)  # al TUI solo se le preguntó


def test_h1_a_la_vista_en_la_app_solo_avisa_y_no_cierra(mt, app, clock, monkeypatch):
    espera(mt, pane="t7")
    app.vivo("t7", "s-tsc")
    app.foco = "t7"
    monkeypatch.setattr(mt, "herdr_frontmost", lambda: mt.LOCAL)
    monkeypatch.setattr(mt, "ventana_al_frente", lambda: "hc")
    tick(mt)
    write(mt, msg())
    tick(mt)
    assert not any(c[0] == "send" for c in app.hc)
    clock(minutes=11)
    tick(mt)
    assert ["kill", "t7"] not in app.hc and app.app[-1][-1] == "💤 se duerme cuando salgas"


def test_h1_dry_run_imprime_el_hc_run(mt, app, clock, capsys):
    espera(mt)
    tick(mt, dry=True)
    write(mt, msg())
    tick(mt, dry=True)
    clock(seconds=91)
    tick(mt, dry=True)
    out = capsys.readouterr().out
    assert "$ hc run --bg --keep --no-parent --no-notify --json --cwd /tmp/tsc --label herdr.space=spTSC" in out
    assert "env COFOUNDY_DESPERTADA=1 claude --resume s-tsc" in out
    assert app.hc == [] and app.app == [] and mt.fold()["e1"]["link"]["pane"] == "wT:p3"


def test_h1_core_caido_cae_al_tui(mt, world, clock):
    """Sin core de hc (la World vieja no lo simula), la reapertura sigue en el TUI: el respaldo legacy-herdr."""
    espera(mt)
    tick(mt)
    write(mt, msg())
    tick(mt)
    clock(seconds=91)
    tick(mt)
    assert world.verbs()[:2] == ["tab create", "pane run"]


# ── H1: lo que corre un agente elige su runtime por el entorno (skill herdr §0) ──────────────────────────────
@pytest.fixture
def en_la_app(mt, app, monkeypatch):
    """Un Claude dentro de un terminal de la app: solo HC_*, y el TUI viejo falla."""
    monkeypatch.delenv("HERDR_PANE_ID", raising=False)  # legacy-herdr
    monkeypatch.setenv("HC_TERMINAL_ID", "t5")
    monkeypatch.setenv("HC_TERMINAL_SOCKET", "/tmp/hc.sock")
    real = mt.shutil.which
    monkeypatch.setattr(mt.shutil, "which", lambda b: "/fake/hc" if b == "hc" else real(b))
    app.vivo("t5", "s-app")
    return app


def test_h1_link_y_dormir_dentro_de_la_app_sin_tocar_el_tui(mt, en_la_app, clock):
    mt.emit("add", "k1", title="UK Confianza", source="user")
    assert "Enlazado" in mt.link_here("k1")
    link = mt.fold()["k1"]["link"]
    assert link == {"host": mt.LOCAL, "session": "s-app", "pane": "t5", "cwd": "/tmp/tsc", "rt": "hc",
                    "space": "spTSC", "tab": "tbt5"}
    mt.write_atomic(mt.desp_file(False), json.dumps({"latido": mt.iso(mt.now())}))  # el despertador corre
    out = mt.dormir(GRUPO, "TSC · Alex", horario="L-V 09:00-18:00")
    assert "Herdr app" in out
    e = mt.esperas(mt.fold())[0]
    assert e["link"]["rt"] == "hc" and e["link"]["space"] == "spTSC"
    # del CLI viejo, que falla: solo la lectura del panel (refresh), nunca algo de lo que dependa el enlace
    assert all(c[1:2] == ["list"] for c in en_la_app.tui)


def test_h1_track_en_la_app(mt, en_la_app):
    mt.track({"session_id": "s-app", "cwd": "/tmp/tsc", "prompt": "hola"})
    t = mt.by_session(mt.fold())["s-app"]
    assert t["link"]["pane"] == "t5" and t["link"]["rt"] == "hc" and en_la_app.tui == []  # el hook ni pregunta
    mt.track({"session_id": "otra", "cwd": "/tmp"})  # un `claude -p` dentro del terminal: no es esta sesión
    assert "otra" not in mt.by_session(mt.fold())


def test_h1_tui_dentro_de_hc_gana_el_mas_interno(mt, monkeypatch):
    monkeypatch.setenv("HC_TERMINAL_ID", "t1")
    monkeypatch.setenv("HC_TERMINAL_SOCKET", "/tmp/hc.sock")
    monkeypatch.setenv("HERDR_PANE_ID", "wHF:p6")  # legacy-herdr
    assert mt.runtime_env() == "tui" and mt.mi_terminal() == "wHF:p6"
    monkeypatch.delenv("HERDR_PANE_ID")  # legacy-herdr
    monkeypatch.setattr(mt.shutil, "which", lambda b: "/fake/hc")
    assert mt.runtime_env() == "hc" and mt.mi_terminal() == "t1"


def test_h1_go_enfoca_la_viva_y_reabre_la_cerrada_en_la_app(mt, app, monkeypatch):
    monkeypatch.setattr(mt, "focus_app", lambda: True)
    mt.emit("add", "k1", title="UK Confianza · PM", source="user",
            link={"host": mt.LOCAL, "session": "s-uk", "pane": "wHF:p6", "cwd": "/tmp/deals"})
    app.vivo("t1r", "s-uk")
    assert mt.go(mt.fold()["k1"]).startswith("→")
    assert app.app == [["do", "agent.focus", "--terminal", "t1r"]] and not any(c[0] == "run" for c in app.hc)
    del app.terms["t1r"]  # se cerró
    app.app.clear()
    assert mt.go(mt.fold()["k1"]).startswith("↻")
    run_ = next(c for c in app.hc if c[0] == "run")
    assert run_[run_.index("--cwd") + 1] == "/tmp/deals" and run_[-3:] == ["claude", "--resume", "s-uk"]
    assert app.app[-1] == ["do", "agent.focus", "--terminal", "t91"]  # `go` sí enfoca: lo pediste
    assert all(c[1:2] == ["list"] for c in app.tui)


def test_h1_enlace_del_tui_vuelve_al_espacio_de_su_workspace(mt, app, clock):
    """5 de las 6 dormidas viven en el workspace «prospectos» del TUI, que ya existe como espacio en la app."""
    app.spaces.append({"id": "spPROS", "name": "prospectos", "machine": None, "tabs": []})
    app.tui_ws = {"wT": "prospectos"}
    espera(mt)  # enlace wT:p3, cliente «TSC» (también tiene espacio): gana el workspace del enlace
    tick(mt)
    write(mt, msg())
    tick(mt)
    clock(seconds=91)
    tick(mt)
    run_ = next(c for c in app.hc if c[0] == "run")
    assert "herdr.space=spPROS" in run_ and not any(c[1] == "space.rename" for c in app.app)


def test_h1_puntero_que_no_llega_se_reintenta(mt, app, clock, monkeypatch):
    espera(mt, pane="t7")
    app.vivo("t7", "s-tsc")
    tick(mt)
    write(mt, msg())
    real = app.run

    def send_falla(cmd, host=None, timeout=4):
        if cmd[:2] == ["hc", "send"]:
            app.hc.append(cmd[1:])
            return subprocess.CompletedProcess(cmd, 1, "", "draft pending")
        return real(cmd, host, timeout)
    monkeypatch.setattr(mt, "run", send_falla)
    tick(mt)
    assert mt.desp_load()["pend"]["e1"]["n"] == 1  # no se dio por entregado
    monkeypatch.setattr(mt, "run", real)
    tick(mt)
    assert mt.desp_load()["pend"] == {} and sum(c[0] == "send" for c in app.hc) == 2


# ── H1: el contrato del despertador, en la app (la misma secuencia que las pruebas del TUI de arriba) ─────────────
def espera_h_app(mt, horario_txt=HORARIO_VH, pane="t7"):
    mt.emit("add", "e1", title="espera: VH · revisión", source=mt.ESPERA, wake={"wsp": GRUPO, "horario": horario_txt},
            expires=mt.iso(mt.now() + timedelta(days=21)),
            link={"host": mt.LOCAL, "session": "s-vh", "pane": pane, "rt": "hc", "space": "spTSC", "cwd": "/tmp/vh"})


def test_h1_app_fuera_de_horario_difiere_duerme_por_hc_y_despierta_una_vez_al_abrir(mt, app, horario):
    espera_h_app(mt)
    app.vivo("t7", "s-vh")  # viva y ociosa: no se le escribe, se duerme igual
    tick(mt)
    write(mt, msg_ahora(horario, 1, text="gracias, mañana lo reviso"))
    tick(mt)
    horario.clock(hours=1)
    tick(mt)
    assert len(horario.triage) == 1 and not any(c[0] in ("send", "run") for c in app.hc)
    assert ["kill", "t7"] in app.hc  # se durmió con el pendiente diferido
    del app.terms["t7"]
    horario.clock(hours=10, minutes=11)  # jueves 08:41: cerrado
    tick(mt)
    assert not any(c[0] == "run" for c in app.hc)
    horario.clock(minutes=20)  # jueves 09:01: abre
    tick(mt)
    tick(mt)
    assert sum(c[0] == "run" for c in app.hc) == 1
    app.vivo("t91", "s-vh")
    horario.clock(seconds=15)
    tick(mt)
    sends = [c for c in app.hc if c[0] == "send"]
    assert len(sends) == 1 and "ninguno era urgente" in sends[0][-1] and "gracias" not in sends[0][-1]
    horario.clock(minutes=5)
    tick(mt)
    assert sum(c[0] == "run" for c in app.hc) == 1  # ese día, una sola vez


def test_h1_app_urgente_despierta_ya_y_avisa_en_macos(mt, app, horario):
    horario.respuesta = {"urgente": True, "motivo": "web o servicio caído"}
    espera_h_app(mt)
    tick(mt)
    write(mt, msg_ahora(horario, 1, text="la web no carga"))
    tick(mt)  # sin la ráfaga de 90 s
    assert sum(c[0] == "run" for c in app.hc) == 1
    assert horario.mac and "web o servicio caído" in horario.mac[0] and "no carga" not in horario.mac[0]
    app.vivo("t91", "s-vh")
    horario.clock(seconds=15)
    tick(mt)
    assert "urgente (web o servicio caído)" in next(c for c in app.hc if c[0] == "send")[-1]


def test_h1_app_rafaga_de_8_es_un_solo_despertar(mt, app, clock):
    espera(mt)
    tick(mt)
    write(mt, *[msg(ID=f"M{i}") for i in range(8)])
    tick(mt)
    clock(seconds=91)
    tick(mt)
    write(mt, msg(ID="M9"))
    tick(mt)
    assert sum(c[0] == "run" for c in app.hc) == 1
    app.vivo("t91", "s-tsc")
    tick(mt)
    sends = [c for c in app.hc if c[0] == "send"]
    assert len(sends) == 1 and "9 mensajes" in sends[0][-1]


def test_h1_app_closeout_rojo_no_mata_y_lo_dice_en_la_pestana(mt, app, clock):
    espera(mt, pane="t7")
    app.vivo("t7", "s-tsc")
    app.closeout_ok = False
    tick(mt)
    clock(minutes=10, seconds=1)
    tick(mt)
    assert ["kill", "t7"] not in app.hc
    assert app.app[-1][:4] == ["do", "tab.rename", "--id", "tbt7"] and app.app[-1][-1].startswith("💤 no se duerme")


def test_h1_app_resume_que_no_queda_idle_avisa_y_no_reabre_en_bucle(mt, app, clock):
    espera(mt)
    tick(mt)
    write(mt, msg())
    tick(mt)
    clock(seconds=91)
    tick(mt)
    app.vivo("t91", "s-tsc", status="working")
    clock(seconds=181)
    del app.terms["t91"]
    tick(mt)
    clock(seconds=60)
    tick(mt)
    assert sum(c[0] == "run" for c in app.hc) == 1
    assert mt.desp_load()["pend"]["e1"]["fallo"] is True


def test_h1_app_working_espera_idle_y_no_abre_otra(mt, app, clock):
    espera(mt, pane="t7")
    app.vivo("t7", "s-tsc", status="working")
    tick(mt)
    write(mt, msg())
    tick(mt)
    clock(seconds=91)
    tick(mt)
    assert app.hc == []
    app.terms["t7"] = ("s-tsc", "idle", app.terms["t7"][2])
    tick(mt)
    assert [c[0] for c in app.hc] == ["send"]


def test_h1_panel_y_link_pane_ven_los_agentes_de_la_app(mt, app):
    app.vivo("t1r", "s-uk", status="done")
    mt.emit("add", "k1", title="UK", source="user")
    assert "t1r" in mt.link_pane("k1", "t1r", mt.LOCAL)
    st = mt.compute()  # enlazada ya terminada: «ya lo viste»
    assert st["herdr_ok"] and [r["id"] for r in st["seen"]] == ["k1"]
    app.terms["t1r"] = ("s-uk", "working", app.terms["t1r"][2])
    assert [r["id"] for r in mt.compute()["working"]] == ["k1"]
    app.terms["t1r"] = ("s-uk", "done", app.terms["t1r"][2])
    assert [r["id"] for r in mt.compute()["waiting"]] == ["k1"]  # volvió a terminar: te espera


def test_h1_una_despertada_no_usa_go(mt, app, monkeypatch):
    """Revisión 2 del crítico: `myturn go` desde una despertada reabriría otra sesión sin la variable y con foco."""
    monkeypatch.setenv("COFOUNDY_DESPERTADA", "1")
    mt.emit("add", "k1", title="UK", source="user", link={"host": mt.LOCAL, "session": "s-uk", "pane": "t1r"})
    assert "despertada" in mt.go(mt.fold()["k1"])
    assert app.hc == [] and app.app == []


# ── dormir por cliente (líder del cliente H3 · cofoundy-toolkit#174) ────────────────────────────────────────
KIM = "51988777666@s.whatsapp.net"
CANALES = {"entidad": "deals/clients/Fluye", "nombre": "Fluye", "estado": "cotizacion", "abierto": True,
           "chats": [{"jid": CLIENTE, "nombre": "Diego"}, {"jid": KIM, "nombre": "Kim"}],
           "correos": ["kim@fluye.com"], "dominios": ["fluye.com"]}


def canales_falso(world, res, renames):
    def run(cmd, host=None, timeout=4):
        if cmd[0] == "uv" and "canales" in cmd:
            return subprocess.CompletedProcess(cmd, 0, json.dumps(res), "")
        if cmd[0] == "uv" and "horario" in cmd:
            return subprocess.CompletedProcess(cmd, 1, "", "")
        if cmd[:3] == ["herdr-app", "do", "tab.rename"]:
            renames.append(cmd[-1])
        return world.run(cmd, host, timeout)
    return run


def test_dormir_entidad_escucha_a_todo_el_cliente_y_renombra_la_pestana(mt, world, monkeypatch):
    """FluyeBottle 2026-11-13: se le escribió a Diego y nadie quedó escuchando; ahora el envío arma la escucha de
    TODO el cliente (Diego y Kimberly) y la pestaña dice de quién es."""
    renames = []
    monkeypatch.setattr(mt, "run", canales_falso(world, CANALES, renames))
    monkeypatch.setattr(mt, "here", lambda: {"agent_session": {"value": "s-fluye"}, "pane_id": "t3t", "cwd": "/tmp",
                                             "rt": "hc", "space": "sp1", "tab": "tb1"})
    out = mt.dormir_entidad(CLIENTE, None, auto=True)
    es = mt.esperas(mt.fold())
    assert {mt.chat_de(t) for t in es} == {CLIENTE, KIM}
    assert all(t["wake"]["entidad"] == "deals/clients/Fluye" for t in es)
    assert renames == ["💬 Fluye · Diego"] and "Escucha armada" in out and "fase 2" in out


def test_dormir_entidad_auto_no_le_quita_el_cliente_a_quien_ya_escucha(mt, world, monkeypatch):
    renames = []
    monkeypatch.setattr(mt, "run", canales_falso(world, CANALES, renames))
    here_as(mt, monkeypatch, "s-debrief")
    mt.dormir_entidad("Fluye", "Fluye · debrief")
    here_as(mt, monkeypatch, "s-rapida")
    out = mt.dormir_entidad(CLIENTE, None, auto=True)
    es = mt.esperas(mt.fold())
    assert len(es) == 2 and {t["link"]["session"] for t in es} == {"s-debrief"}
    assert "ya lo escucha Fluye · debrief" in out and "Escucha armada" not in out
    mt.dormir_entidad("Fluye", None)  # a mano sí se lo queda
    assert {t["link"]["session"] for t in mt.esperas(mt.fold())} == {"s-rapida"}


def test_dormir_entidad_auto_sin_cliente_abierto_no_hace_nada(mt, world, monkeypatch):
    here_as(mt, monkeypatch, "s-x")
    for res in ({"entidad": None}, CANALES | {"abierto": False, "estado": "cerrado_perdido"}):
        monkeypatch.setattr(mt, "run", canales_falso(world, res, []))
        assert mt.dormir_entidad(CLIENTE, None, auto=True) == ""
    assert mt.esperas(mt.fold()) == []


def test_h1_letrero_pegado_vuelve_al_nombre_del_cliente_mientras_trabaja(mt, app, clock):
    """2026-11-13 (André): la pestaña decía «💤 se duerme en 8:42» con la sesión trabajando y el nombre original
    perdido. Trabajando + pestaña con 💤 → vuelve a «💬 <cliente>», recuerde o no el nombre de antes."""
    espera(mt, pane="t7")
    app.vivo("t7", "s-tsc")
    app.terms["t7"] = ("s-tsc", "working", app.terms["t7"][2])
    app.where["t7"] = "TSC / 💤 se duerme en 8:42"
    tick(mt)
    assert app.app[-1] == ["do", "tab.rename", "--id", "tbt7", "--name", "💬 TSC · Alex"]
