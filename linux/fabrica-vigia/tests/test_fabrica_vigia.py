#!/usr/bin/env python3
"""Batería del vigía (orch#202). Sin red, sin herdr real: un herdr falso responde según un
JSON de escenario y registra cada llamada. Cada caso prueba UNA rama de la ronda."""
import json, os, subprocess, sys, tempfile
from pathlib import Path

VIGIA = Path(__file__).resolve().parents[1] / ".local/bin/fabrica-vigia"
OK = BAD = 0
FAKE = r'''#!/usr/bin/env python3
import json, os, sys
sc = json.load(open(os.environ["SC"]))
a = sys.argv[1:]
open(os.environ["LOG"], "a").write(json.dumps(a) + "\n")
k = " ".join(a[:2])
if sc.get("down"): sys.exit(1)
if k == "pane list": print(json.dumps({"result": {"panes": sc.get("panes", [])}}))
elif k == "pane read": print(sc.get("screen", ""))
elif k == "workspace list": print(json.dumps({"result": {"workspaces": sc.get("workspaces", [])}}))
elif k == "tab create": print(json.dumps({"result": {"root_pane": {"pane_id": "wX:p9"}}}))
sys.exit(0)
'''
MEM_OK = "MemAvailable: 9000000 kB\nSwapTotal: 16000000 kB\nSwapFree: 8000000 kB\n"
MEM_RED = "MemAvailable: 800000 kB\nSwapTotal: 16000000 kB\nSwapFree: 500000 kB\n"


def check(cid, desc, ok, det=""):
    global OK, BAD
    OK, BAD = (OK + 1, BAD) if ok else (OK, BAD + 1)
    print(f"  {'✓' if ok else '✗'} {cid} {desc}" + ("" if ok else f"  — {det}"))


def world(sc, mem=MEM_OK, now="2026-11-12T02:00"):
    d = Path(tempfile.mkdtemp())
    (d / "herdr").write_text(FAKE); (d / "herdr").chmod(0o755)
    (d / "sc.json").write_text(json.dumps(sc)); (d / "mem").write_text(mem)
    env = {**os.environ, "VIGIA_HOME": str(d), "VIGIA_HERDR": str(d / "herdr"), "VIGIA_MEMINFO": str(d / "mem"),
           "VIGIA_NOW": now, "VIGIA_BRAIN": "", "SC": str(d / "sc.json"), "LOG": str(d / "log")}
    def run(*a, now_=None):
        e = dict(env, **({"VIGIA_NOW": now_} if now_ else {}))
        p = subprocess.run([sys.executable, str(VIGIA), *a], capture_output=True, text=True, env=e)
        return p.returncode, p.stdout, p.stderr
    run("vigilar", "--nombre", "deily", "--workspace-label", "Macondo", "--cwd", str(d), "--repo", "el-deily")
    calls = lambda: [json.loads(l) for l in (d / "log").read_text().splitlines()] if (d / "log").exists() else []
    return run, calls, d


def ronda(run, *extra, now_=None):
    rc, out, err = run("ronda", "--json", *extra, now_=now_)
    return (json.loads(out) or [{}])[0] if rc == 0 and out.strip() else {"rc": rc, "err": err}


PANE = {"label": "factory-deily", "pane_id": "w1:p1", "agent": "claude"}
print("vigía")
run, calls, _ = world({"panes": [dict(PANE, agent_status="working")]})
check("V-01", "fábrica trabajando → nada", ronda(run).get("accion") == "nada")

run, calls, _ = world({"panes": [], "workspaces": [{"label": "Macondo", "workspace_id": "w1"}]})
r = ronda(run)
seq = [c[:2] for c in calls()]
check("V-02", "panel muerto → relanza: tab en el space del proyecto, claude, kickoff, espera working",
      r.get("accion") == "relanzada" and ["tab", "create"] in seq and ["agent", "start"] in seq
      and ["pane", "run"] in seq and ["agent", "wait"] in seq and ["pane", "rename"] in seq, (r, seq))
kick = next((c for c in calls() if c[:2] == ["pane", "run"]), [])
check("V-03", "el kickoff nombra el repo y no lleva backticks (herdr#83 los vacía)",
      "el-deily" in " ".join(kick) and "`" not in " ".join(kick), kick)
check("V-04", "segunda ronda inmediata con el panel aún ausente: relanza otra vez pero cuenta",
      ronda(run).get("accion") == "relanzada")
ronda(run)
check("V-05", "tope: el cuarto relance en 6 h no se hace", ronda(run).get("accion") == "tope")

run, calls, _ = world({"panes": [], "workspaces": [{"label": "Macondo", "workspace_id": "w1"}]}, mem=MEM_RED)
r = ronda(run)
check("V-06", "memoria en rojo → no lanza nada", r.get("accion") == "freno-memoria"
      and not any(c[:2] == ["tab", "create"] for c in calls()), (r, calls()))

run, calls, _ = world({"panes": [dict(PANE, agent_status="idle")],
                       "screen": "Claude usage limit reached · resets 3am (America/Lima)"})
r = ronda(run)
check("V-07", "límite de uso → espera hasta la hora de reinicio (+2 min), no relanza",
      r.get("accion") == "espera-limite" and r.get("hasta", "").startswith("2026-11-12T03:02"), r)
r = ronda(run, now_="2026-11-12T03:05")
check("V-08", "pasada la hora → la reanuda con un prompt", r.get("accion") == "reanudada"
      and any(c[:2] == ["agent", "prompt"] for c in calls()), r)

run, calls, _ = world({"panes": [dict(PANE, agent_status="idle")], "screen": "❯"})
check("V-09", "quieta poco → nada", ronda(run).get("accion") == "nada")
r = ronda(run, now_="2026-11-12T03:20")
check("V-10", "quieta 80 min → la empuja", r.get("accion") == "empujada", r)

run, calls, _ = world({"panes": [dict(PANE, agent="")]})
r = ronda(run)
check("V-11", "panel vivo pero claude salió → relanza en ese mismo panel (sin tab nueva), tras cd a su carpeta",
      r.get("accion") == "relanzada" and not any(c[:2] == ["tab", "create"] for c in calls())
      and any(c[:2] == ["pane", "run"] and c[3].startswith("cd ") for c in calls()), (r, calls()))

run, calls, _ = world({"panes": [dict(PANE, agent_status="blocked")]})
check("V-12", "bloqueada → aviso, nunca relanza", ronda(run).get("accion") == "bloqueada")

run, calls, _ = world({"down": True})
check("V-13", "herdr caído → no hace nada destructivo", ronda(run).get("accion") == "sin-herdr")

run, calls, _ = world({"panes": [], "workspaces": [{"label": "Macondo", "workspace_id": "w1"}]})
r = ronda(run, "--dry-run")
check("V-14", "--dry-run: dice qué haría y no llama a tab create",
      r.get("accion") == "relanzaria" and not any(c[:2] == ["tab", "create"] for c in calls()), r)

print(f"\n{OK} pass · {BAD} fail"); sys.exit(1 if BAD else 0)
