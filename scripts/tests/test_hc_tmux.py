"""Tests del tmux falso (scripts/hc-tmux/tmux) contra un herdr-app y un hc falsos.

Correr: uv run --with pytest pytest scripts/tests/test_hc_tmux.py
La secuencia de `test_flujo_de_claude` es la que Claude Code mandó a tmux real al abrir dos teammates
(herdmates docs/research/spike-tmux-verbs-2026-07-16/REPORT.md).
"""
import json
import os
import subprocess
import textwrap
from pathlib import Path

import pytest

SHIM = Path(__file__).resolve().parents[1] / "hc-tmux" / "tmux"

FAKE = textwrap.dedent(r'''
    #!/usr/bin/env python3
    import json, os, sys
    from pathlib import Path
    home = Path(os.environ["FAKE_HOME"])
    world = json.loads((home / "world.json").read_text())
    with open(home / "calls.log", "a") as fh:
        fh.write(json.dumps([Path(sys.argv[0]).name] + sys.argv[1:]) + "\n")
    name, args = Path(sys.argv[0]).name, sys.argv[1:]
    def save(): (home / "world.json").write_text(json.dumps(world))
    if name == "herdr-app" and args[:1] == ["status"]:
        print(json.dumps({"focused_pane": world.get("focused")}))
    elif name == "herdr-app" and args[:2] == ["do", "pane.focus"]:
        world["focused"] = args[3]; save(); print("{}")
    elif name == "herdr-app" and args[:1] == ["ls"]:
        terms = [{"terminal": t, "pane": p} for p, t in world["panes"].items()]
        print(json.dumps({"spaces": [{"tabs": [{"terminals": terms}]}]}))
    elif name == "herdr-app" and args[:2] == ["do", "pane.split"]:
        opt = dict(zip(args[2::2], args[3::2]))
        if opt["--pane"] not in world["panes"]:
            print("no such pane", file=sys.stderr); sys.exit(1)
        world["n"] += 1
        pane, term = f"p{world['n']}", f"t{world['n']}"
        world["panes"][pane] = term
        if world.get("steal"): world["focused"] = pane
        world["splits"].append({"from": opt["--pane"], "dir": opt["--direction"],
                                "argv": json.loads(opt["--argv"]), "pane": pane})
        save(); print(json.dumps({"pane": pane, "terminal": term}))
    elif name == "herdr-app" and args[:2] == ["do", "pane.close"]:
        world["panes"].pop(args[3], None); save(); print("{}")
    elif name == "hc" and args[:1] == ["read"]:
        print("pantalla de", args[-1])
    elif name == "hc":
        print("{}")
    else:
        print("fake: no sé", args, file=sys.stderr); sys.exit(2)
''').lstrip()


@pytest.fixture
def env(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    for name in ("herdr-app", "hc"):
        f = bin_dir / name
        f.write_text(FAKE)
        f.chmod(0o755)
    (tmp_path / "world.json").write_text(json.dumps({"n": 0, "panes": {"pLEAD": "tLEAD"}, "splits": []}))
    e = dict(os.environ)
    for k in ("HERDR_PANE_ID", "TMUX"):
        e.pop(k, None)
    e.update(PATH=f"{bin_dir}:{e['PATH']}", FAKE_HOME=str(tmp_path), HC_TERMINAL_ID="tLEAD",
             HC_TMUX_STATE=str(tmp_path / "state" / "lead.json"), TMUX="hc-tmux,0,0", TMUX_PANE="%0")
    return e, tmp_path


def tmux(env, *args, ok=True):
    e, _ = env
    proc = subprocess.run([str(SHIM), *args], capture_output=True, text=True, env=e)
    if ok:
        assert proc.returncode == 0, proc.stderr
    return proc


def world(env):
    return json.loads((env[1] / "world.json").read_text())


def calls(env):
    path = env[1] / "calls.log"
    return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []


def test_sondeos_de_arranque(env):
    assert tmux(env, "-V").stdout == "tmux 3.5a\n"
    assert tmux(env, "show", "-Av", "mouse").stdout == "off\n"
    assert tmux(env, "show", "-gv", "focus-events").stdout == "off\n"
    assert tmux(env, "display-message", "-t", "%0", "-p", "#{window_id}").stdout == "@0\n"
    assert tmux(env, "display-message", "-p", "#{pane_id}").stdout == "%0\n"
    assert tmux(env, "list-panes", "-t", "@0", "-F", "#{pane_id}").stdout == "%0\n"


def test_sondeos_vistos_en_claude_2_1_325(env):
    """Lo que Claude 2.1.325 y el hook de tmux-assistant-resurrect mandaron en la corrida real del 2026-11-13."""
    assert tmux(env, "display-message", "-p", "-t", "%0",
                "#{session_name}:#{window_id}.#{pane_id}").stdout == "hc:@0.%0\n"
    out = tmux(env, "display-message", "-p", "-t", "%0", "#{client_termtype}\t#{allow-passthrough}\t#{pane_top}")
    assert "#{" not in out.stdout
    assert tmux(env, "display-message", "-p", "#S").stdout == "hc\n"
    assert tmux(env, "display-message", "-p", "#I").stdout == "0\n"
    assert tmux(env, "show-option", "-gqv", "@assistant-resurrect-capture-env").stdout == ""
    tmux(env, "set-option", "-t", "#S:#I", "-w", "@claude_active", "a")
    tmux(env, "refresh-client", "-S")


def test_flujo_de_claude(env):
    S = ["-S", "/tmp/tmux-1000/default"]
    p1 = tmux(env, *S, "split-window", "-d", "-t", "%0", "-h", "-l", "70%", "-P", "-F", "#{pane_id}",
              "--", "cat").stdout.strip()
    assert p1 == "%1"
    assert world(env)["splits"] == []  # placeholder: todavía no hay panel
    assert tmux(env, *S, "list-panes", "-t", "@0", "-F", "#{pane_id}").stdout == "%0\n%1\n"
    for args in (["set-option", "-p", "-t", p1, "window-style", "bg=default,fg=blue"],
                 ["select-pane", "-t", p1, "-T", "alpha"],
                 ["set-option", "-w", "-t", "@0", "pane-border-status", "top"],
                 ["set-option", "-p", "-t", p1, "remain-on-exit", "failed"]):
        tmux(env, *S, *args)
    tmux(env, *S, "respawn-pane", "-k", "-t", p1, "--",
         "cd /repo && env CLAUDECODE=1 claude --agent-id alpha@t")
    s1 = world(env)["splits"][0]
    assert (s1["from"], s1["dir"]) == ("pLEAD", "right")
    assert s1["argv"] == ["/bin/sh", "-c", "cd /repo && env CLAUDECODE=1 claude --agent-id alpha@t"]

    p2 = tmux(env, *S, "split-window", "-d", "-t", p1, "-v", "-P", "-F", "#{pane_id}", "--", "cat").stdout.strip()
    tmux(env, *S, "respawn-pane", "-k", "-t", p2, "--", "claude --agent-id beta@t")
    s2 = world(env)["splits"][1]
    assert (s2["from"], s2["dir"]) == (s1["pane"], "down")  # columna de teammates a la derecha

    tmux(env, *S, "select-layout", "-t", "@0", "main-vertical")
    tmux(env, *S, "resize-pane", "-t", "%0", "-x", "30%")
    assert tmux(env, "display-message", "-t", p1, "-p", "#{pane_title}").stdout == "alpha\n"

    tmux(env, *S, "kill-pane", "-t", p1)
    tmux(env, *S, "kill-pane", "-t", p2)
    assert world(env)["panes"] == {"pLEAD": "tLEAD"}
    assert tmux(env, "list-panes", "-F", "#{pane_id}").stdout == "%0\n"
    assert not any(c[:3] == ["herdr-app", "do", "pane.focus"] for c in calls(env))


def test_panel_cerrado_a_mano_desaparece(env):
    p1 = tmux(env, "split-window", "-h", "-P", "--", "claude").stdout.strip()
    pane = world(env)["splits"][0]["pane"]
    w = world(env)
    del w["panes"][pane]
    (env[1] / "world.json").write_text(json.dumps(w))
    assert tmux(env, "list-panes", "-F", "#{pane_id}").stdout == "%0\n"
    tmux(env, "kill-pane", "-t", p1)  # ya no existe: igual sale 0


def test_send_keys(env):
    p1 = tmux(env, "split-window", "-h", "-P", "-c", "/repo", "-e", "A=1").stdout.strip()
    term = world(env)["splits"][0]["pane"].replace("p", "t")
    assert world(env)["splits"][0]["argv"][0].endswith("zsh") or world(env)["splits"][0]["argv"][-1] == "-l"
    tmux(env, "send-keys", "-t", p1, "echo hola", "Enter")
    tmux(env, "send-keys", "-t", p1, "C-c")
    tmux(env, "send-keys", "-t", p1, "-l", "ab")
    tmux(env, "send-keys", "-t", p1, "Escape", "Enter")
    hc = [c for c in calls(env) if c[0] == "hc"]
    assert hc == [["hc", "send", term, "echo hola"], ["hc", "keys", term, "ctrl+c"],
                  ["hc", "keys", term, "a", "b"], ["hc", "keys", term, "esc", "enter"]]
    assert tmux(env, "capture-pane", "-p", "-t", p1, "-S", "-50").stdout == f"pantalla de {term}\n"
    assert ["hc", "read", "--lines", "50", term] in calls(env)


def test_cwd_y_env_del_split_viajan_al_respawn(env):
    p1 = tmux(env, "split-window", "-h", "-P", "-c", "/r p", "-e", "X=1", "--", "cat").stdout.strip()
    tmux(env, "respawn-pane", "-k", "-t", p1, "--", "claude")
    script = world(env)["splits"][0]["argv"][2]
    assert script == "cd '/r p' && env X=1 sh -c claude"


def test_teammate_de_una_despertada_hereda_la_marca(env):
    e, _ = env
    e.update(COFOUNDY_DESPERTADA="1", COFOUNDY_DESPERTADA_EXCEPCION="portafolios", COFOUNDY_DESPERTADA_CHAT="con_x")
    p1 = tmux(env, "split-window", "-h", "-P", "--", "cat").stdout.strip()
    tmux(env, "respawn-pane", "-k", "-t", p1, "--", "claude")
    script = world(env)["splits"][0]["argv"][2]
    assert script == "env COFOUNDY_DESPERTADA=1 sh -c claude"


def test_respawn_sobre_panel_vivo_lo_reemplaza(env):
    p1 = tmux(env, "split-window", "-h", "-P", "--", "sleep 99").stdout.strip()
    first = world(env)["splits"][0]["pane"]
    tmux(env, "respawn-pane", "-k", "-t", p1, "--", "claude")
    w = world(env)
    assert first not in w["panes"] and w["splits"][1]["from"] == first
    assert tmux(env, "list-panes", "-F", "#{pane_id}").stdout == "%0\n%1\n"


def test_verbo_desconocido_falla_y_queda_en_el_log(env):
    proc = tmux(env, "new-session", "-d", "-s", "x", ok=False)
    assert proc.returncode == 1 and "no soportado" in proc.stderr
    log = (env[1] / "state" / "lead.log").read_text()
    assert "new-session" in log


def test_lider_sin_panel(env):
    w = world(env)
    w["panes"] = {}
    (env[1] / "world.json").write_text(json.dumps(w))
    proc = tmux(env, "split-window", "-h", "--", "claude", ok=False)
    assert proc.returncode == 1 and "no tiene panel" in proc.stderr
    assert tmux(env, "list-panes", "-F", "#{pane_id}").stdout == "%0\n"  # el %1 fallido no quedó


def test_tercer_teammate_va_en_la_columna_y_el_foco_vuelve(env):
    """Corrida real: Claude pidió `split-window -t %3 -h` para el tercero; en tmux lo arregla main-vertical."""
    w = world(env)
    w.update(focused="pLEAD", steal=True)
    (env[1] / "world.json").write_text(json.dumps(w))
    p1 = tmux(env, "split-window", "-d", "-t", "%0", "-h", "-P", "--", "claude").stdout.strip()
    tmux(env, "split-window", "-d", "-t", p1, "-v", "--", "claude")
    tmux(env, "split-window", "-d", "-t", p1, "-h", "--", "claude")
    dirs = [s["dir"] for s in world(env)["splits"]]
    assert dirs == ["right", "down", "down"]
    assert world(env)["focused"] == "pLEAD"


def test_vecino_cerrado_va_al_final_de_la_columna(env):
    """Corrida real: un equipo nuevo partió de %4 mientras el equipo viejo se apagaba."""
    p1 = tmux(env, "split-window", "-d", "-t", "%0", "-h", "-P", "--", "claude").stdout.strip()
    p2 = tmux(env, "split-window", "-d", "-t", p1, "-v", "-P", "-F", "#{pane_id}", "--", "cat").stdout.strip()
    tmux(env, "kill-pane", "-t", p1)
    tmux(env, "split-window", "-d", "-t", "%0", "-h", "--", "claude")  # columna vacía: junto al líder
    first_live = world(env)["splits"][-1]["pane"]
    tmux(env, "respawn-pane", "-k", "-t", p2, "--", "claude")
    last = world(env)["splits"][-1]
    assert (last["from"], last["dir"]) == (first_live, "down")
