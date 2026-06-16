#!/usr/bin/env python3
"""Full-resolution image viewer via the Kitty graphics protocol.

Uses DIRECT placement (transmit + display at cursor) wrapped in tmux
passthrough — the method empirically proven to survive a
tmux -> Eternal Terminal -> Ghostty chain, where yazi's native
unicode-placeholder path is corrupted in transit. Invoked by imgview.yazi
after yazi yields the terminal with ui.hide().

Only the Kitty APC graphics sequences are wrapped in tmux passthrough; plain
CSI moves/clears are emitted normally so tmux keeps its screen model in sync.
"""

import base64
import os
import shutil
import sys
import termios
import tty

ESC = "\x1b"


def wrap_tmux(seq: str) -> str:
    """Wrap a sequence so tmux forwards it verbatim to the outer terminal."""
    if os.environ.get("TMUX"):
        return f"{ESC}Ptmux;" + seq.replace(ESC, ESC + ESC) + f"{ESC}\\"
    return seq


def main() -> None:
    if len(sys.argv) < 2:
        return
    path = sys.argv[1]

    iw = ih = 0
    try:
        from PIL import Image

        with Image.open(path) as im:
            iw, ih = im.size
    except Exception:
        pass

    cols, rows = shutil.get_terminal_size((80, 24))
    view_rows = max(1, rows - 1)  # reserve the last line for the hint

    # Columns to span, preserving aspect. Kitty infers the row count from the
    # column count; CELL (~cell height:width) only sizes the vertical fit, so a
    # slight under-estimate just leaves a small margin rather than overflowing.
    CELL = 1.9
    if iw > 0 and ih > 0:
        c = int(view_rows * CELL * iw / ih)
        c = max(1, min(cols, c))
    else:
        c = cols
    x = max(0, (cols - c) // 2)

    b64 = base64.standard_b64encode(open(path, "rb").read()).decode()
    chunks = [b64[i : i + 4096] for i in range(0, len(b64), 4096)] or [""]

    kitty = []
    for idx, ch in enumerate(chunks):
        more = 1 if idx < len(chunks) - 1 else 0
        ctrl = f"a=T,f=100,c={c},q=2,m={more}" if idx == 0 else f"m={more}"
        kitty.append(f"{ESC}_G{ctrl};{ch}{ESC}\\")

    # clear + position (normal CSI), then the image (passthrough-wrapped).
    sys.stdout.write(f"{ESC}[2J{ESC}[H{ESC}[1;{x + 1}H")
    sys.stdout.write(wrap_tmux("".join(kitty)))

    name = os.path.basename(path)
    dims = f"{iw}x{ih}" if iw else "?"
    sys.stdout.write(
        f"{ESC}[{rows};1H{ESC}[2m  {name}  ·  {dims}  ·  cualquier tecla para volver{ESC}[0m"
    )
    sys.stdout.flush()

    # Wait for a single keypress from the controlling terminal.
    fd = sys.stdin.fileno()
    old = None
    try:
        old = termios.tcgetattr(fd)
        tty.setraw(fd)
        os.read(fd, 1)
    except Exception:
        pass
    finally:
        if old is not None:
            try:
                termios.tcsetattr(fd, termios.TCSADRAIN, old)
            except Exception:
                pass

    # Delete all Kitty images (wrapped), then clear the screen (normal).
    sys.stdout.write(wrap_tmux(f"{ESC}_Ga=d{ESC}\\") + f"{ESC}[2J{ESC}[H")
    sys.stdout.flush()


if __name__ == "__main__":
    main()
