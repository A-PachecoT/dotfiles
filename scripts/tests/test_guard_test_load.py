import importlib.util
from pathlib import Path

import pytest

_spec = importlib.util.spec_from_file_location(
    "guard", Path(__file__).resolve().parent.parent / "claude-guard-test-load.py"
)
g = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(g)


@pytest.fixture(autouse=True)
def cap4(monkeypatch):
    monkeypatch.setenv("TEST_LOAD_MAX_WORKERS", "4")
    monkeypatch.setenv("SHELL", "/usr/bin/zsh")


@pytest.mark.parametrize("cmd,expected", [
    ("uv run pytest -n 10 -q -p no:cacheprovider", "uv run pytest -n 4 -q -p no:cacheprovider"),
    ("cd backend && uv run pytest tests/ -n 8 --dist loadfile", "cd backend && uv run pytest tests/ -n 4 --dist loadfile"),
    ("pytest -n auto", "pytest -n 4"),
    ("pytest --numprocesses=12 tests", "pytest --numprocesses=4 tests"),
    ("pytest -n8", "pytest -n4"),
])
def test_caps_workers(cmd, expected):
    new, notes = g.rewrite(cmd, use_scope=False)
    assert new == expected and notes


@pytest.mark.parametrize("cmd", [
    "pytest -n 2 tests/test_x.py",      # ya bajo el techo, sin scope → nada que hacer
    "git log -n 8",                     # -n de otro comando
    "head -n 20 file && pytest -q",     # -n de head no se toca; pytest sin -n
    "echo 'pytest -n 8'",               # string = dato
    "ls -la",
])
def test_leaves_alone_without_scope(cmd):
    assert g.rewrite(cmd, use_scope=False) == (None, [])


def test_wraps_heavy_in_scope():
    new, _ = g.rewrite("uv run pytest -n 10", use_scope=True)
    assert "systemd-run --user --scope" in new
    assert "MemoryMax=8G" in new and "CPUWeight=20" in new
    assert "'uv run pytest -n 4'" in new
    assert new.rstrip().endswith("( exit $__rc )")


def test_does_not_wrap_light_or_already_wrapped():
    assert g.rewrite("git status", use_scope=True) == (None, [])
    assert g.rewrite("systemd-run --user --scope pytest", use_scope=True) == (None, [])
    wrapped, _ = g.rewrite("pnpm build", use_scope=True)
    assert g.rewrite(wrapped, use_scope=True) == (None, [])


def test_heavy_detection():
    for c in ("pnpm build", "npm run test", "npx vitest run", "make check", "uv run mypy src", "next build"):
        assert g.rewrite(c, use_scope=True)[0], c
    for c in ("pnpm install", "npm ci", "make deploy", "git push"):
        assert g.rewrite(c, use_scope=True) == (None, []), c
