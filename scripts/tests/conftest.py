import pytest


@pytest.fixture(autouse=True)
def _despertada_state(tmp_path, monkeypatch):
    """El CLAUDE_ENV_FILE de cada despertar va a tmp, nunca a ~/.local/state (también en los CLI de subprocess)."""
    monkeypatch.setenv("MYTURN_DESPERTADA_STATE", str(tmp_path / "despertada-state"))
