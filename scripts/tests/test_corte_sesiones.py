"""El corte de myturn al toolkit (cofoundy-toolkit#188): copia las esperas una sola vez y no pierde ninguna."""

import importlib.machinery
import importlib.util
import json
from pathlib import Path

P = Path(__file__).resolve().parents[1] / "myturn-corte-sesiones"
SPEC = importlib.util.spec_from_loader("corte", importlib.machinery.SourceFileLoader("corte", str(P)))
corte = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(corte)


def ev(op, id, **kw):
    return {"ts": f"2026-11-16T10:00:0{len(kw)}-05:00", "host": "mac", "op": op, "id": id, **kw}


def test_copia_solo_esperas_y_es_idempotente(tmp_path):
    src, dst = tmp_path / "events.jsonl", tmp_path / "esperas.jsonl"
    src.write_text("\n".join(json.dumps(e) for e in [
        ev("add", "e1", source="espera", title="espera: X"), ev("add", "c1", source="capture", title="pan"),
        ev("done", "c1"), ev("update", "e1", set={"title": "espera: Y"})]) + "\n")
    assert corte.copiar_esperas(src, dst) == 2
    assert corte.copiar_esperas(src, dst) == 0
    assert {e["id"] for e in corte.lineas(dst)} == {"e1"}


def test_comparar_detecta_espera_perdida():
    f = corte.comparar({"a", "b"}, {"esperas": [{"id": "a"}], "vivo": True, "pos": {"inode": 1, "offset": 9}},
                       {"inode": 1, "offset": 10})
    assert len(f) == 1 and "b" in f[0]
    assert corte.comparar({"a"}, {"esperas": [{"id": "a"}, {"id": "c"}], "vivo": True}, None) == []


def test_espera_nacida_en_el_hueco_rebobina_wacli(tmp_path, monkeypatch):
    """Crítica H7 ronda 2: un `dormir` del módulo antes de prender el nuevo; el viejo ya pasó por esos mensajes."""
    wacli = tmp_path / "wacli.jsonl"
    lineas = [{"Timestamp": f"2026-11-16T20:0{m}:00Z", "Text": str(m)} for m in range(6)]
    wacli.write_text("".join(json.dumps(x) + "\n" for x in lineas))
    monkeypatch.setattr(corte, "WACLI", wacli)
    viejo = tmp_path / "viejo"
    viejo.mkdir()
    (viejo / "despertador.json").write_text(json.dumps({"pos": {"inode": 7, "offset": wacli.stat().st_size}}))
    monkeypatch.setattr(corte, "CACHE_VIEJO", viejo)
    st = corte.estado_para_el_modulo(tmp_path / "nuevo/despertador.json", ["2026-11-16T15:04:00-05:00"])
    esperado = sum(len(json.dumps(x)) + 1 for x in lineas[:1])  # 20:04Z − 3 min = 20:01Z: desde la 2.ª línea
    assert st["pos"]["offset"] == esperado


def test_si_el_modulo_ya_corrio_gana_el_pos_menor(tmp_path, monkeypatch):
    viejo = tmp_path / "viejo"
    viejo.mkdir()
    (viejo / "despertador.json").write_text(json.dumps({"pos": {"inode": 7, "offset": 500}}))
    monkeypatch.setattr(corte, "CACHE_VIEJO", viejo)
    dst = tmp_path / "nuevo/despertador.json"
    dst.parent.mkdir()
    dst.write_text(json.dumps({"pos": {"inode": 7, "offset": 900}}))
    assert corte.estado_para_el_modulo(dst, [])["pos"]["offset"] == 500
