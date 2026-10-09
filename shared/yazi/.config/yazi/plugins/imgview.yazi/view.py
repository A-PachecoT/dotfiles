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
import fcntl
import os
import shutil
import struct
import sys
import termios
import tty

ESC = "\x1b"


def wrap_tmux(seq: str) -> str:
    """Wrap a sequence so tmux forwards it verbatim to the outer terminal."""
    if os.environ.get("TMUX"):
        return f"{ESC}Ptmux;" + seq.replace(ESC, ESC + ESC) + f"{ESC}\\"
    return seq


def term_size() -> tuple[int, int, float]:
    """(cols, rows, cell h:w) from the real tty: under yazi's `shell --block`
    stdout/env can report the 80x24 fallback, which shrank the image."""
    for fd_src in ("/dev/tty", None):
        try:
            fd = os.open(fd_src, os.O_RDONLY) if fd_src else sys.stdout.fileno()
            rows, cols, xp, yp = struct.unpack(
                "HHHH", fcntl.ioctl(fd, termios.TIOCGWINSZ, b"\0" * 8)
            )
            if fd_src:
                os.close(fd)
            if cols and rows:
                cell = (yp / rows) / (xp / cols) if xp and yp else 1.9
                return cols, rows, cell
        except OSError:
            pass
    cols, rows, cell = term_size()
    return cols, rows, 1.9


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

    cols, rows, cell = term_size()
    view_rows = max(1, rows - 1)  # reserve the last line for the hint

    # Columns to span, preserving aspect. Kitty infers the row count from the
    # column count; the cell h:w ratio (from the tty's pixel size) sizes the
    # vertical fit.
    if iw > 0 and ih > 0:
        c = int(view_rows * cell * iw / ih)
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
