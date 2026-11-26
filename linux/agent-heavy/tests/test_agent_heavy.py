import importlib.machinery
import importlib.util
import os
from pathlib import Path

import pytest

_p = Path(__file__).resolve().parent.parent / ".local/bin/agent-heavy"
_loader = importlib.machinery.SourceFileLoader("agent_heavy", str(_p))
_spec = importlib.util.spec_from_loader("agent_heavy", _loader)
ah = importlib.util.module_from_spec(_spec)
_loader.exec_module(ah)

UID = 1000
MGR = f"/user.slice/user-{UID}.slice/user@{UID}.service"
PANE = f"{MGR}/app.slice/hc-hold-abc.service"


@pytest.mark.parametrize("argv", [
    ["uv", "run", "pytest", "-n", "4", "tests/"],
    ["/repo/backend/.venv/bin/python", "/repo/backend/.venv/bin/pytest", "-q"],
    ["python3", "-m", "pytest"],
    ["node (vitest)"],
    ["node (vitest 3)"],
    ["node", "/repo/node_modules/vitest/vitest.mjs", "run"],
    ["npx", "vitest", "run"],
    ["node", "/repo/node_modules/.bin/next", "build"],
    ["npx", "playwright", "test"],
    ["node", "/repo/node_modules/typescript/bin/tsc", "--noEmit"],
])
def test_heavy(argv):
    assert ah.is_heavy(argv)


@pytest.mark.parametrize("argv", [
    ["claude", "--model", "opus", "corre pytest -n 8 y vitest"],  # el prompt es dato
    ["/usr/bin/zsh", "-c", "cd x && uv run pytest"],               # la shell no; su hijo sí
    ["node", "/repo/node_modules/.bin/next", "dev"],
    ["next-server (v15.1.0)"],
    ["python", "-u", "-c", "import sys;exec(eval(sys.stdin.readline()))"],  # worker xdist: va con su raíz
    ["uv", "sync"],
    [],
])
def test_not_heavy(argv):
    assert not ah.is_heavy(argv)


def P(argv, ppid, cg=PANE, uid=UID):
    return {"argv": argv, "ppid": ppid, "cg": cg, "uid": uid}


def test_plan_moves_whole_tree_once_and_skips_what_is_inside():
    procs = {
        10: P(["claude"], 1),
        11: P(["/usr/bin/zsh", "-c", "uv run pytest -n 4"], 10),
        12: P(["uv", "run", "pytest", "-n", "4"], 11),
        13: P([".venv/bin/python", ".venv/bin/pytest", "-n", "4"], 12),
        14: P(["python", "-u", "-c", "import sys;exec(eval(sys.stdin.readline()))"], 13),
        15: P(["python", "-u", "-c", "import sys;exec(eval(sys.stdin.readline()))"], 13),
        20: P(["node (vitest)"], 1, cg=f"{MGR}/agent-heavy.slice/agent-heavy-run-1.scope"),
        30: P(["pytest"], 1, cg="/system.slice/actions.runner.x.service"),  # CI: no es nuestro
        40: P(["pytest"], 1, uid=0, cg=PANE),
    }
    assert ah.plan(procs, UID) == [(12, [12, 13, 14, 15])]


def test_slots_queue_and_report_holders(tmp_path, monkeypatch):
    monkeypatch.setenv("AGENT_HEAVY_LOCKDIR", str(tmp_path))
    d = ah.lockdir()
    a = ah.try_slot(d, 2, "A vitest")
    b = ah.try_slot(d, 2, "B pytest")
    assert a is not None and b is not None
    assert ah.try_slot(d, 2, "C") is None
    assert sorted(ah.holders(d, 2)) == ["A vitest", "B pytest"]
    os.close(a)
    c = ah.try_slot(d, 2, "C")
    assert c is not None and sorted(ah.holders(d, 2)) == ["B pytest", "C"]
    os.close(b), os.close(c)


def test_scope_cmd_lands_in_slice_with_ceilings():
    argv, env = ah.scope_cmd(["zsh", "-c", "pytest"])
    assert "--slice=agent-heavy.slice" in argv and "MemoryMax=8G" in argv
    assert argv[-3:] == ["zsh", "-c", "pytest"] and env["XDG_RUNTIME_DIR"]
