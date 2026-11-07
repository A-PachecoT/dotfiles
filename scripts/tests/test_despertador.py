"""Prueba en seco del despertador (sesiones dormidas v0): los 4 casos de corrida.md más dormir y la cuenta regresiva.

Miran el EFECTO: los comandos herdr que el despertador emite y el estado que deja, con herdr, pgrep, closeout y
`wsp equipo` falsos. Correr: uv run --with pytest pytest scripts/tests/
Diseño: ~/cofoundy/core/docs/research/2026-11-06_sesiones-dormidas/ (opciones v4, corrida.md)."""
import importlib.machinery
import importlib.util
import json
import os
import subprocess
from datetime import datetime, timedelta
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
    monkeypatch.delenv("HERDR_PANE_ID", raising=False)
    loader = importlib.machinery.SourceFileLoader("myturn_desp", str(SCRIPT))
    spec = importlib.util.spec_from_loader("myturn_desp", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    (tmp_path / "wacli").mkdir()
    mod.WACLI_EVENTS.write_text("")
    return mod


class World:
    """herdr + pgrep + closeout + wsp falsos. `herdr` guarda cada comando que muta; `agents` es lo que herdr ve."""

    def __init__(self):
        self.agents: list[dict] = []
        self.herdr: list[list[str]] = []
        self.resuming = False
        self.closeout_ok = True
        self.panes = 0

    def run(self, cmd, host=None, timeout=4):
        def ok(out=""):
            return subprocess.CompletedProcess(cmd, 0, out, "")
        if cmd[0] == "herdr":
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
    prompt = next(c for c in world.herdr if c[:2] == ["agent", "prompt"])
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
    prompts = [c for c in world.herdr if c[:2] == ["agent", "prompt"]]
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
    assert "$ herdr tab create --workspace wT" in out and "COFOUNDY_DESPERTADA=1 --no-focus" in out
    assert "$ herdr pane run dry:p1 'claude --resume s-tsc'" in out
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
    """El comando entero, como lo correría André: un herdr falso en el PATH que solo responde `agent list`."""
    bindir = tmp_path / "bin"
    bindir.mkdir()
    (bindir / "herdr").write_text("#!/bin/sh\necho '{\"result\":{\"agents\":[]}}'\n")
    (bindir / "herdr").chmod(0o755)
    env = {**os.environ, "MYTURN_HOME": str(tmp_path / "t"), "MYTURN_CACHE": str(tmp_path / "c"),
           "MYTURN_NO_SYNC": "1", "MYTURN_WACLI_EVENTS": str(tmp_path / "ev.jsonl"),
           "PATH": f"{bindir}:{os.environ['PATH']}"}
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
    prompts = [c for c in world.herdr if c[:2] == ["agent", "prompt"]]
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
    tick(mt)
    clock(minutes=11)
    tick(mt)
    assert ["pane", "close", "wT:p3"] not in world.herdr
    assert world.herdr[-1][-1] == "💤 se duerme cuando salgas"
    monkeypatch.setattr(mt, "herdr_frontmost", lambda: None)
    clock(seconds=15)
    tick(mt)
    assert world.herdr[-1] == ["pane", "close", "wT:p3"]
