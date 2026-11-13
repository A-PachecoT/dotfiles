"""Fuente «reuniones» de myturn: cuándo caen los 2 recordatorios y a qué brief se cruza una reunión.

Correr: uv run --with pytest --with pyyaml --with google-api-python-client --with google-auth-oauthlib pytest scripts/tests/test_reuniones.py
Diseño: ~/cofoundy/core/docs/research/2026-11-12_calendarios/diseno.md §6.3."""
import importlib.machinery
import importlib.util
from pathlib import Path

loader = importlib.machinery.SourceFileLoader("reuniones", str(Path(__file__).resolve().parents[1] / "myturn-reuniones"))
spec = importlib.util.spec_from_loader("reuniones", loader)
r = importlib.util.module_from_spec(spec)
loader.exec_module(r)

VERONICA = {"cliente": "VeronicaHinojosa", "tz": "America/Los_Angeles", "horario": "L-V 09:00-20:00 America/Lima",
            "jid": "x@g.us", "consentimiento": None}


def ev(start, summary="📩 Verónica · revisión 3", attendees=None):
    return {"id": "e1", "iCalUID": "u1@google.com", "summary": summary, "start": {"dateTime": start},
            "hangoutLink": "https://meet.google.com/abc", "attendees": attendees or []}


def test_cliente_en_los_angeles_dia_anterior_a_las_10_de_su_hora():
    # mar 17-nov 10:00 LA = 13:00 Lima → lun 16 10:00 LA = 13:00 Lima (dentro de su horario 09-20 Lima).
    t = r.recordatorios(ev("2026-11-17T10:00:00-08:00"), VERONICA)
    assert t[0]["due"] == "2026-11-16T13:00" and t[1]["due"] == "2026-11-17T11:00"
    assert "mar 17-nov 10:00 su hora" in t[0]["title"]


def test_reunion_del_lunes_recuerda_el_viernes():
    t = r.recordatorios(ev("2026-11-16T09:00:00-05:00"), {**VERONICA, "tz": "America/Lima"})
    assert t[0]["due"] == "2026-11-13T10:00"


def test_10_de_madrid_cae_fuera_del_horario_de_lima_y_se_lleva_a_la_apertura():
    t = r.recordatorios(ev("2026-11-18T18:00:00+01:00"), {**VERONICA, "tz": "Europe/Madrid",
                                                           "horario": "L-V 09:00-18:00 America/Lima"})
    assert t[0]["due"] == "2026-11-17T09:00"  # 10:00 Madrid = 04:00 Lima → abre 09:00 Lima


def test_ids_idempotentes_por_reunion_y_tipo():
    t = r.recordatorios(ev("2026-11-17T10:00:00-08:00"), VERONICA)
    assert [x["id"] for x in t] == ["u1@google.com#dia-anterior", "u1@google.com#2h-antes"]


TODOS = [
    {"cliente": "JUMP_Arquitectura", "nombres": {"jump_arquitectura"}, "correos": {"x@jump.pe": None},
     "dominios": {"jump.pe"}},
    {"cliente": "Macondo-LaParlante", "nombres": {"macondo-laparlante", "la parlante"},
     "correos": {"josemi@laparlante.pe": "no"}, "dominios": {"laparlante.pe"}},
]


def test_sin_cruce_por_apellido():
    # Corrida 2026-11-12: «Josemi Ucendo» con su Gmail no debe caer en otro cliente por un apellido.
    b, por = r.cliente_de(ev("2026-11-13T09:00:00-05:00", "Client Meet entre Andre y Josemi Ucendo García"),
                          ["jmucendo@gmail.com"], TODOS)
    assert b is None and por == "sin brief"


def test_correo_exacto_cruza_y_trae_el_consentimiento():
    b, por = r.cliente_de(ev("2026-11-13T09:00:00-05:00", "Reunión"), ["josemi@laparlante.pe"], TODOS)
    assert b["cliente"] == "Macondo-LaParlante" and b["correos"]["josemi@laparlante.pe"] == "no"


def test_nombre_del_cliente_en_el_titulo_sin_tildes():
    b, _ = r.cliente_de(ev("2026-11-13T09:00:00-05:00", "La Parlante × Cofoundy"), [], TODOS)
    assert b["cliente"] == "Macondo-LaParlante"
