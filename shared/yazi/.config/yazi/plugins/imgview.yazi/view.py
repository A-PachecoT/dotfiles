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


def term_size() -> tuple[int, int, float, float]:
    """(cols, rows, cell_w_px, cell_h_px) from the real tty: under yazi's
    `shell --block` stdout/env can report the 80x24 fallback, which shrank the
    image. Pixel sizes fall back to a 10x19 cell when the terminal reports none."""
    for fd_src in ("/dev/tty", None):
        try:
            fd = os.open(fd_src, os.O_RDONLY) if fd_src else sys.stdout.fileno()
            rows, cols, xp, yp = struct.unpack(
                "HHHH", fcntl.ioctl(fd, termios.TIOCGWINSZ, b"\0" * 8)
            )
            if fd_src:
                os.close(fd)
            if cols and rows:
                if xp and yp:
                    return cols, rows, xp / cols, yp / rows
                return cols, rows, 10.0, 19.0
        except OSError:
            pass
    cols, rows = shutil.get_terminal_size((80, 24))
    return cols, rows, 10.0, 19.0


def encode(path: str, max_w: int, max_h: int) -> bytes:
    """PNG bytes no larger than the pane in pixels. Sending a 4K screenshot
    whole costs ~1.5 MB of base64 through herdr + ET; downscaled it is ~5x less."""
    raw = open(path, "rb").read()
    try:
        import io

        from PIL import Image

        with Image.open(path) as im:
            if im.format == "PNG" and im.width <= max_w * 1.2 and im.height <= max_h * 1.2:
                return raw
            im.thumbnail((max_w, max_h), Image.BILINEAR, reducing_gap=2.0)
            buf = io.BytesIO()
            im.save(buf, "PNG", compress_level=1)
            return buf.getvalue()
    except Exception:
        return raw


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

    cols, rows, cw, ch_px = term_size()
    cell = ch_px / cw
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

    data = encode(path, int(c * cw), int(view_rows * ch_px))
    b64 = base64.standard_b64encode(data).decode()
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
