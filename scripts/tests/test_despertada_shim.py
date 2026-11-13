"""El shim de hc/herdr-app/herdr en una sesión despertada (H1 D6, André 2026-11-13: «Cambiar el método
(Recomendado)»). Cada escape que encontró el crítico (ronda 4) termina igual: el hijo lleva la marca."""
import json
import os
import subprocess
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[2]
SHIM = REPO / "scripts/despertada/bin"
ZSHRC = REPO / "macos/zsh/.zshrc"

FAKE = r'''#!/usr/bin/env python3
import json, os, sys
log = os.path.join(os.environ["FAKE_LOG"])
with open(log, "a") as f:
    f.write(json.dumps([os.path.basename(sys.argv[0])] + sys.argv[1:]) + "\n")
a = sys.argv[1:]
G = {"t50": {"address": "t50", "argv": ["/bin/zsh", "-lic", "x", "/bin/zsh", "env", "COFOUNDY_DESPERTADA=1",
             "COFOUNDY_DESPERTADA_NIVEL=1", "COFOUNDY_DESPERTADA_PADRE=t9", "claude"]},
     "t60": {"address": "t60", "argv": ["env", "COFOUNDY_DESPERTADA=1", "claude", "--resume", "s"]},
     "t1g": {"address": "t1g", "argv": ["/bin/zsh", "-l"]},
     "t9": {"address": "t9", "argv": ["env", "COFOUNDY_DESPERTADA=1", "claude"]},
     "pm": {"address": "t9", "argv": []}}
if a[:1] == ["get"]:
    g = G.get(a[1])
    print(json.dumps(g)) if g else sys.exit(1)
elif a[:1] == ["templates"]:
    print(json.dumps({"templates": [{"name": "reviewer"}]}))
'''


@pytest.fixture
def w(tmp_path):
    real = tmp_path / "real"
    real.mkdir()
    for n in ("hc", "herdr-app", "herdr"):
        f = real / n
        f.write_text(FAKE)
        f.chmod(0o755)
    # macOS no trae timeout(1): uno equivalente que, como el de coreutils, busca el programa en el PATH
    t = real / "timeout"
    t.write_text('#!/bin/sh\nshift\nexec "$@"\n')
    t.chmod(0o755)
    log = tmp_path / "log"
    env = {k: v for k, v in os.environ.items() if not k.startswith(("COFOUNDY_DESPERTADA", "HC_"))}
    env.update(PATH=f"{SHIM}:{real}:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin", FAKE_LOG=str(log), COFOUNDY_DESPERTADA="1",
               HC_TERMINAL_ID="t9")
    return env, log


def sh(w, script, **extra):
    env, log = w
    p = subprocess.run(["bash", "-c", script], env={**env, **extra}, capture_output=True, text=True)
    calls = [json.loads(x) for x in log.read_text().splitlines()] if log.exists() else []
    log.unlink(missing_ok=True)
    return p, [norm(c) for c in calls if c[1:2] not in (["get"], ["templates"])]


def norm(call):
    """CLAUDE_ENV_FILE=<archivo propio> → CLAUDE_ENV_FILE=*, tras comprobar que el archivo pone el shim primero."""
    import re
    out = []
    for x in call:
        for f in re.findall(r'CLAUDE_ENV_FILE=([^"\s]+)', x):
            assert os.stat(f).st_mode & 0o777 == 0o600
            assert f'export PATH="{SHIM}:$PATH"' in Path(f).read_text()
        x = re.sub(r'CLAUDE_ENV_FILE=[^"\s]+', "CLAUDE_ENV_FILE=*", x)
        if re.match(r'"?PATH=', x) or '"PATH=' in x:
            assert re.search(r'PATH=' + re.escape(str(SHIM)) + ':', x)  # el shim primero en el PATH del hijo
            x = re.sub(r'PATH=[^"]+', "PATH=*", x)
        out.append(x)
    return out


MARCA = ["env", "COFOUNDY_DESPERTADA=1", "COFOUNDY_DESPERTADA_NIVEL=1", "COFOUNDY_DESPERTADA_PADRE=t9",
         "CLAUDE_ENV_FILE=*", "PATH=*"]


@pytest.mark.parametrize("script", [
    'hc run --bg claude "haz X"',
    'if [ -d / ]; then hc run --bg claude "haz X"; fi',
    'cd /   # al repo\nhc run --bg claude "haz X"',
    'curl -s http://x/a#b >/dev/null 2>&1 || true\nhc run --bg claude "haz X"',
    'timeout 30 hc run --bg claude "haz X"',
    'bash -c \'hc run --bg claude "haz X"\'',
    'env FOO=1 hc run --bg claude "haz X"',
    'for i in 1; do hc run --bg claude "haz X"; done',
    '{ hc run --bg claude "haz X"; }',
    'echo x | xargs -I{} hc run --bg claude "haz X"',
    'T=`hc run --bg claude "haz X"`',
    "python3 -c 'import subprocess; subprocess.run([\"hc\", \"run\", \"--bg\", \"claude\", \"haz X\"])'",
])
def test_cualquier_forma_de_lanzar_lleva_la_marca(w, script):
    p, calls = sh(w, script)
    assert calls == [["hc", "run", "--bg", "--", *MARCA, "claude", "haz X"]], p.stderr


def test_la_receta_de_handoff_lleva_la_marca_y_no_la_excepcion(w):
    p, calls = sh(w, 'T=$(hc run --bg --json --name h --cwd /r --no-parent --label "herdr.tab=tb1" \\\n'
                     '   env COFOUNDY_PARENT_SESSION=s1 claude --model opus "brief")',
                  COFOUNDY_DESPERTADA_EXCEPCION="portafolios", COFOUNDY_DESPERTADA_CHAT="con_x")
    assert calls == [["hc", "run", "--bg", "--json", "--name", "h", "--cwd", "/r", "--no-parent", "--label",
                      "herdr.tab=tb1", "--", *MARCA, "env", "COFOUNDY_PARENT_SESSION=s1", "claude", "--model",
                      "opus", "brief"]], p.stderr
    assert not any("EXCEPCION" in x or "CHAT" in x for x in calls[0])


def test_una_cadena_va_por_sh(w):
    _, calls = sh(w, 'hc run --bg "cd /r && npm test"')
    assert calls == [["hc", "run", "--bg", "--", *MARCA, "sh", "-c", "cd /r && npm test"]]


def test_un_hijo_no_lanza_otro_nivel(w):
    for script in ('hc run --bg claude x', 'if true; then hc run --bg claude x; fi', 'hc exec -- claude -p x',
                   "herdr-app do tab.new --argv '[\"claude\"]'"):
        p, calls = sh(w, script, COFOUNDY_DESPERTADA_NIVEL="1", COFOUNDY_DESPERTADA_PADRE="t1", HC_TERMINAL_ID="t50")
        assert p.returncode == 3 and calls == [] and "un solo nivel" in p.stderr, script


def test_plantilla_bloqueada(w):
    p, calls = sh(w, 'hc run reviewer "revisa"')
    assert p.returncode == 3 and calls == []


def test_exec_lleva_la_marca_por_env(w):
    _, calls = sh(w, 'hc exec --on hq uptime')
    assert calls == [["hc", "exec", "--env", "COFOUNDY_DESPERTADA=1", "--env", "COFOUNDY_DESPERTADA_NIVEL=1",
                      "--env", "COFOUNDY_DESPERTADA_PADRE=t9", "--env", "CLAUDE_ENV_FILE=*", "--env", "PATH=*", "--on", "hq", "--",
                      "uptime"]]


@pytest.mark.parametrize("script,ok", [
    ('hc send --if idle t50 "sigue"', True),          # su hijo
    ('hc send --wait t50 "x" && hc keys --json t50 enter', True),
    ('hc kill t50; hc rm t50', True),
    ('hc send t9 "/goal x"', True),                    # a sí misma
    ('hc kill "$HC_TERMINAL_ID"', True),
    ('hc send t1g "pásale esto al cliente"', False),  # otra sesión de André
    ('hc send t60 "sigue"', False),                    # otra despertada (hermana)
    ('if hc get t1g >/dev/null; then hc send t1g hola; fi', False),
    ('hc ls   # miro\nhc send t1g "x"', False),
    ('timeout 5 hc send t1g x', False),
    ('hc label t50 x=y', False),
    ('echo {} | hc connect', False),
    ('hc server stop', False),
    ('hc', False),
])
def test_escribir_solo_a_lo_propio(w, script, ok):
    p, calls = sh(w, script)
    assert (p.returncode == 0) == ok, p.stderr
    if not ok:
        assert "BLOQUEADO" in p.stderr, p.stderr
        assert all(c[1] in ("ls",) for c in calls)


def test_un_hijo_le_devuelve_el_trabajo_a_su_padre(w):
    child = dict(COFOUNDY_DESPERTADA_NIVEL="1", COFOUNDY_DESPERTADA_PADRE="t9", HC_TERMINAL_ID="t50")
    p, calls = sh(w, 'hc send t9 "listo: PR #3"', **child)
    assert p.returncode == 0 and calls == [["hc", "send", "t9", "listo: PR #3"]]
    p, _ = sh(w, 'hc send pm "listo"', **child)  # por nombre también
    assert p.returncode == 0
    p, _ = sh(w, 'hc send t1g "x"', **child)
    assert p.returncode == 3


def test_leer_libre(w):
    p, calls = sh(w, 'hc ls --json && hc read t3 --lines 20 && hc wait t3 && hc machine ls && herdr-app ls')
    assert p.returncode == 0 and len(calls) == 5


def test_herdr_app_lanza_con_la_marca(w):
    _, calls = sh(w, "herdr-app do pane.split --direction right --pane p1 --argv '[\"claude\",\"x\"]'")
    assert calls == [["herdr-app", "do", "pane.split", "--direction", "right", "--pane", "p1", "--argv",
                      json.dumps([*MARCA, "claude", "x"])]]
    _, calls = sh(w, "herdr-app do space.new '{\"name\":\"Ana\",\"argv\":[\"claude\"],\"task\":\"t\"}'")
    assert json.loads(calls[0][3])["argv"] == [*MARCA, "claude"]


@pytest.mark.parametrize("script", ["herdr-app do terminal.paste", "herdr-app do agent.focus --terminal t1g",
                                    "herdr-app do tab.new", "herdr-app feedback hola",
                                    "herdr pane run wX:p1 claude", "herdr agent prompt wX:p1 hola"])  # legacy-herdr
def test_lo_demas_de_la_app_y_el_tui_bloqueado(w, script):
    p, calls = sh(w, script)
    assert p.returncode == 3 and calls == []


def test_sin_despertar_es_transparente(w):
    env, _ = w
    p, calls = sh(w, 'hc run reviewer x; hc send t1g y; herdr-app do agent.focus', COFOUNDY_DESPERTADA="")
    assert calls == [["hc", "run", "reviewer", "x"], ["hc", "send", "t1g", "y"],
                     ["herdr-app", "do", "agent.focus"]]


def test_zshrc_pone_el_shim_al_final():
    lineas = [x for x in ZSHRC.read_text().splitlines() if x.strip() and not x.lstrip().startswith("#")]
    assert lineas[-1] == ('if [[ "${COFOUNDY_DESPERTADA:-}" == 1 ]]; then export PATH='
                          '"$HOME/dotfiles/scripts/despertada/bin:$PATH"; fi')
