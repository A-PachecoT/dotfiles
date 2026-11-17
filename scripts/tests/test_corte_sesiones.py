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


def test_comparar_detecta_espera_perdida_y_pos_que_retrocede():
    antes = {"esperas": [{"id": "a"}, {"id": "b"}], "pos": {"inode": 1, "offset": 10}}
    assert corte.comparar(antes, {"esperas": [{"id": "a"}, {"id": "b"}, {"id": "c"}], "pos": {"inode": 1, "offset": 12}}) == []
    f = corte.comparar(antes, {"esperas": [{"id": "a"}], "pos": {"inode": 1, "offset": 9}})
    assert len(f) == 2 and "b" in f[0]
