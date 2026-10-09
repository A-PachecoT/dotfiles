# imgview.yazi

Full-resolution, pixel-perfect image viewer. Complements `chafa.yazi`: chafa
gives the always-on (approximate) preview while browsing; `imgview` opens the
hovered image at real resolution on demand.

Bound to **`i`** in `keymap.toml`:

```toml
[[mgr.prepend_keymap]]
on   = "i"
run  = "plugin imgview"
desc = "View image full-res (Kitty)"
```

Flow: hides yazi (`ui.hide`), hands the terminal to `view.py`, which paints the
image with the Kitty graphics protocol using **direct placement** (transmit +
display at cursor) wrapped in tmux passthrough — the method proven to survive
`tmux → Eternal Terminal → Ghostty`, unlike yazi's native unicode-placeholder
path. Any key returns to yazi.

## Runtime dependencies (not stow-managed)

- **python3** with **Pillow** (`PIL`) — Pillow is used only to read the image
  dimensions for aspect-correct fitting; it degrades gracefully if missing.
- A terminal that speaks the Kitty graphics protocol (Ghostty, kitty, …) with
  tmux `allow-passthrough on`.

## Notes

- The image is transmitted with `q=2` (responses suppressed) so nothing leaks
  back into the terminal input.
- Size comes from `TIOCGWINSZ` on `/dev/tty` (cols, rows and pixels → cell size);
  images bigger than the pane are downscaled before sending (~5x fewer bytes over ET).
  A 10x19 px cell is only the fallback when the terminal reports no pixels, used to cap
  the vertical fit. Tune it if tall images leave too much margin.
