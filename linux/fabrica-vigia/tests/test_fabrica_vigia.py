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
r = ronda(run)
check("V-12", "blocked sin diálogo ni avance → «sin-avance», nunca relanza",
      r.get("accion") == "sin-avance" and not any(c[:2] in (["tab", "create"], ["agent", "start"]) for c in calls()), r)

run, calls, _ = world({"down": True})
check("V-13", "herdr caído → no hace nada destructivo", ronda(run).get("accion") == "sin-herdr")

run, calls, _ = world({"panes": [], "workspaces": [{"label": "Macondo", "workspace_id": "w1"}]})
r = ronda(run, "--dry-run")
check("V-14", "--dry-run: dice qué haría y no llama a tab create",
      r.get("accion") == "relanzaria" and not any(c[:2] == ["tab", "create"] for c in calls()), r)

# --- La noche del 2026-11-12 (reporte de pm, journalctl de fabrica-vigia.service): el vigía marcó el-deily
# «bloqueada» de 02:31 a 07:03 mientras el repo recibía commits a las 02:45, 04:38 y 06:43-07:07, y el aviso
# fue solo a Vikunja (André dormía). A las 07:05 el panel esperaba Enter en este diálogo:
DIALOGO = """ Bash command

   rm -rf /home/andre/.herdr/worktrees/el-deily/bloque-f-panel
   Borra el worktree del sitio ya mergeado

 Dangerous rm operation not ruled out

 Do you want to proceed?
 ❯ 1. Yes
   2. No, and tell Claude what to do differently (esc)
"""
NOCHE = ["2026-11-12T02:45:29", "2026-11-12T04:38:51", "2026-11-12T06:43:49"]
PM = {"label": "pm", "pane_id": "w1:p3", "agent": "claude", "agent_status": "done", "workspace_id": "w1"}


def repo_con_commits(d, fechas):
    r = d / "repo"
    subprocess.run(["git", "init", "-q", str(r)], check=True)
    for i, f in enumerate(fechas):
        env = dict(os.environ, GIT_AUTHOR_DATE=f + "-05:00", GIT_COMMITTER_DATE=f + "-05:00")
        subprocess.run(["git", "-C", str(r), "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q",
                        "--allow-empty", "-m", f"c{i}"], check=True, env=env)
    return r


def world_noche(screen, fechas, now):
    sc = {"panes": [dict(PANE, agent_status="blocked", workspace_id="w1"), PM], "screen": screen,
          "workspaces": [{"label": "Macondo", "workspace_id": "w1"}]}
    run, calls, d = world(sc, now=now)
    r = repo_con_commits(d, fechas)
    cfg = json.loads((d / ".config/cofoundy/fabrica-vigia/deily.json").read_text())
    cfg["cwd"] = str(r)
    (d / ".config/cofoundy/fabrica-vigia/deily.json").write_text(json.dumps(cfg))
    return run, calls, d


print("vigía — la noche del 2026-11-12")
run, calls, _ = world_noche(DIALOGO, NOCHE[:2], "2026-11-12T04:50")
r = ronda(run)
check("N-01", "diálogo de permiso con commit hace 12 min → «permiso», con avance, no «bloqueada» a secas",
      r.get("accion") == "permiso" and r.get("avance") is True, r)
check("N-02", "trae el texto del comando del diálogo", "rm -rf /home/andre/.herdr/worktrees/el-deily/bloque-f-panel"
      in (r.get("comando") or ""), r)
pm = [c for c in calls() if c[:3] == ["pane", "run", "w1:p3"]]
check("N-03", "despierta al pm del workspace (herdr pane run a su panel) con el comando",
      len(pm) == 1 and "rm -rf" in pm[0][3] and "`" not in pm[0][3], calls())
ronda(run, now_="2026-11-12T04:55")
pm = [c for c in calls() if c[:3] == ["pane", "run", "w1:p3"]]
check("N-04", "el mismo diálogo en la ronda siguiente no vuelve a despertar al pm", len(pm) == 1, pm)

run, calls, _ = world_noche("Esperando… algo raro sin diálogo", NOCHE[:1], "2026-11-12T04:30")
r = ronda(run)
check("N-05", "blocked sin diálogo y sin commits ni actividad en 1 h → «sin-avance» y despierta al pm",
      r.get("accion") == "sin-avance" and r.get("avance") is False
      and any(c[:3] == ["pane", "run", "w1:p3"] for c in calls()), (r, calls()))

run, calls, d = world_noche("Esperando… algo raro sin diálogo", NOCHE[:1], "2026-11-12T04:30")
t = d / ".claude/projects/-home-x-el-deily/s1/subagents/a1.jsonl"; t.parent.mkdir(parents=True); t.write_text("{}")
ts = __import__("datetime").datetime.fromisoformat("2026-11-12T04:25:00-05:00").timestamp(); os.utime(t, (ts, ts))
r = ronda(run)
check("N-06", "sin commits pero con un subagente escribiendo hace 5 min → hay avance",
      r.get("avance") is True and r.get("accion") != "sin-avance", r)

print(f"\n{OK} pass · {BAD} fail"); sys.exit(1 if BAD else 0)
