#!/usr/bin/env python3
"""PreToolUse(Bash): una corrida de tests/build de UN agente no puede colgar la caja compartida.

2026-11-14: en Arch (16 cores, 31G, ~13 agentes) un agente corrió `pytest -n 8` y luego
`-n 10` sobre la suite entera de Tracta (~5-8G); con el swap ya lleno, el kernel se fue a
98% sys reclamando memoria, load 157, y la caja se congeló dos veces en 10 min. oomd no
mató nada porque la RAM no pasó su umbral del 90% (el page cache cuenta como libre).

Qué hace (solo Linux con systemd de usuario; en macOS es no-op):
  1. Capea `pytest -n N` / `--numprocesses N|auto|logical` a max(2, nproc//4).
  2. Envuelve el comando en un scope de systemd con techo propio
     (MemoryHigh/MemoryMax/MemorySwapMax) y CPUWeight/IOWeight bajos: si se pasa,
     el OOM killer mata SOLO esa corrida, y herdr/los demás agentes siguen fluidos.
  3. (2026-11-26) El scope vive en agent-heavy.slice (techo de la caja para TODAS las corridas
     juntas) y, si está `agent-heavy` (linux/agent-heavy), espera turno: máx. 2 a la vez.
No bloquea nunca: reescribe el comando vía `updatedInput` y deja una nota en stderr.
Escape: TEST_LOAD_GUARD=off en el entorno del agente.
→ bitacora/2026-11-14-pytest-colgo-arch.md
"""
import json
import os
import re
import shlex
import shutil
import sys

MARK = "claude-guard-test-load"
MEM_HIGH, MEM_MAX, SWAP_MAX = "6G", "8G", "1G"

WRAPPERS = {"env", "time", "command", "exec", "npx", "bunx", "nice", "("}
TWO_WORD = {("uv", "run"), ("poetry", "run"), ("pnpm", "exec"), ("pnpm", "dlx"), ("python", "-m"),
            ("python3", "-m"), ("yarn", "dlx")}


def code_only(s):
    """Quita cuerpos de heredoc y el contenido de strings entre comillas: son datos."""
    out, lines, i = [], s.split("\n"), 0
    while i < len(lines):
        out.append(lines[i])
        m = re.search(r"<<-?\s*['\"]?(\w+)['\"]?", lines[i])
        i += 1
        if m:
            while i < len(lines) and lines[i].strip() != m.group(1):
                i += 1
            i += 1
    s = "\n".join(out)
    s = re.sub(r"'[^']*'", "''", s)
    return re.sub(r'"(?:\\.|[^"\\])*"', '""', s)


def head(stage):
    t = stage.replace("(", " ").split()
    while t:
        if re.match(r"^\w+=", t[0]) or t[0] in WRAPPERS:
            t = t[1:]
        elif t[0] == "timeout" and len(t) > 1:
            t = t[2:]
        elif len(t) > 1 and (t[0], t[1]) in TWO_WORD:
            t = t[2:]
        else:
            break
    return t


def is_heavy(t):
    if not t:
        return False
    w = t[0].rsplit("/", 1)[-1]
    nxt = t[1] if len(t) > 1 else ""
    nxt2 = t[2] if len(t) > 2 else ""
    if w in ("pytest", "py.test", "vitest", "jest", "mypy", "pyright", "tsc"):
        return True
    if w == "make" and nxt in ("check", "test", "ci"):
        return True
    if w in ("npm", "pnpm", "yarn", "bun"):
        task = nxt2 if nxt == "run" else nxt
        return task in ("build", "test", "typecheck", "check")
    if w in ("playwright", "next") and nxt in ("test", "build"):
        return True
    if w in ("cargo", "go") and nxt in ("test", "build"):
        return True
    return False


def segments(cmd):
    return re.split(r"&&|\|\||;|\||\n|\bthen\b|\bdo\b|\belse\b", code_only(cmd))


def worker_cap():
    env = os.environ.get("TEST_LOAD_MAX_WORKERS", "")
    if env.isdigit() and int(env) > 0:
        return int(env)
    return max(2, (os.cpu_count() or 4) // 4)


N_RE = re.compile(r"(?P<flag>(?<![\w-])-n|--numprocesses)(?P<sep>[ =]?)(?P<val>\d+|auto|logical)\b")


def cap_workers(cmd, cap):
    """Baja -n N a `cap` solo dentro de segmentos que corren pytest."""
    notes = []

    def fix_segment(seg):
        if not re.search(r"(?<![\w-])(pytest|py\.test)\b", seg):
            return seg

        def repl(m):
            v = m.group("val")
            if v.isdigit() and int(v) <= cap:
                return m.group(0)
            notes.append(f"-n {v} → -n {cap}")
            return f"{m.group('flag')}{m.group('sep')}{cap}"

        return N_RE.sub(repl, seg)

    parts = re.split(r"(&&|\|\||;|\n)", cmd)
    return "".join(fix_segment(p) for p in parts), notes


def systemd_ok():
    if not sys.platform.startswith("linux") or not shutil.which("systemd-run"):
        return False
    return os.path.exists(f"/run/user/{os.getuid()}/bus")


def heavy_runner():
    """`agent-heavy` (linux/agent-heavy): turnos + slice con techo para toda la caja."""
    p = os.path.expanduser("~/.local/bin/agent-heavy")
    return p if os.access(p, os.X_OK) else None


def wrap(cmd, runner=None):
    shell = os.environ.get("SHELL") or "/bin/sh"
    uid = os.getuid()
    inner = shlex.quote(cmd)
    env = f"XDG_RUNTIME_DIR=${{XDG_RUNTIME_DIR:-/run/user/{uid}}} "
    if runner:
        # Espera turno (máx. 2 corridas pesadas en la caja) y corre en un scope de agent-heavy.slice.
        return f"{env}{shlex.quote(runner)} run -- {shlex.quote(shell)} -c {inner}"
    return (
        f"{env}systemd-run --user --scope --quiet --collect --unit={MARK}-$$-$RANDOM "
        f"--slice=agent-heavy.slice "
        f"-p MemoryHigh={MEM_HIGH} -p MemoryMax={MEM_MAX} -p MemorySwapMax={SWAP_MAX} "
        f"-p CPUWeight=20 -p IOWeight=20 -- {shlex.quote(shell)} -c {inner}; "
        f"__rc=$?; [ $__rc -eq 137 ] && echo '⚠ {MARK}: la corrida pasó {MEM_MAX} y la mató su techo "
        f"(caja compartida con otros agentes). Corre solo tus tests (pytest tests/<tu área>) o con menos workers.' >&2; "
        f"( exit $__rc )"  # propaga el código sin cerrar el shell del harness
    )


def rewrite(cmd, use_scope, runner=None):
    """Devuelve (nuevo_cmd, notas) o (None, []) si no hay nada que hacer."""
    if not cmd or MARK in cmd or "systemd-run" in cmd or "agent-heavy" in cmd:
        return None, []
    if not any(is_heavy(head(s)) for s in segments(cmd)):
        return None, []
    new, notes = cap_workers(cmd, worker_cap())
    if use_scope:
        new = wrap(new, runner)
        notes.append(f"corre en un scope con techo {MEM_MAX} dentro del presupuesto de la caja"
                     + (" (espera turno si ya hay 2 corridas pesadas)" if runner else ""))
    if new == cmd:
        return None, []
    return new, notes


def main():
    if os.environ.get("TEST_LOAD_GUARD") == "off":
        return 0
    try:
        d = json.load(sys.stdin)
    except Exception:
        return 0
    if d.get("tool_name", "Bash") != "Bash":
        return 0
    ti = d.get("tool_input") or {}
    use_scope = systemd_ok()
    if not sys.platform.startswith("linux"):
        return 0
    new, notes = rewrite(ti.get("command") or "", use_scope, heavy_runner() if use_scope else None)
    if not new:
        return 0
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": f"{MARK}: " + "; ".join(notes),
            "updatedInput": {**ti, "command": new},
        },
        "systemMessage": f"{MARK}: " + "; ".join(notes),
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
