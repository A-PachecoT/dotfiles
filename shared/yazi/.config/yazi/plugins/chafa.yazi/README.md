# chafa.yazi

Image previewer that renders via **chafa** (Unicode block symbols) instead of a
graphics protocol, so previews work over a `tmux → Eternal Terminal → Ghostty`
chain where yazi's native Kitty *unicode-placeholder* adapter is corrupted in
transit (blank panel + leaked `+++++` glyphs).

Only takes over in **remote** sessions (`SSH_CONNECTION` / ET's
`et_forward_sock`); locally it defers to yazi's built-in `image` previewer so
native graphics still apply.

Wired in `yazi.toml`:

```toml
[plugin]
prepend_previewers = [
  { mime = "image/*", run = "chafa" },
]
```

For pixel-perfect viewing on demand, see the sibling `imgview.yazi` (`i` key).

## Runtime dependencies (not stow-managed)

```bash
sudo pacman -S --needed chafa ffmpegthumbnailer
```

- **chafa** (>= 1.16) — required. Renders the image as colored sextant/block
  glyphs.
- **ffmpegthumbnailer** — optional, enables video/cover thumbnails elsewhere.

## Notes

- `--probe=off --passthrough=none` is mandatory: otherwise chafa queries the
  terminal (fg/bg color, size) and the bg-color reply `ESC]11;rgb:1a1a/1b1b/2626`
  leaks its `/` separators into yazi's stdin, spuriously opening the
  "Find next:" prompt.
- Symbol set is `sextant+block+quad+half+space` for ~3× the resolution of half
  blocks while staying as plain glyphs Ghostty draws natively (survives ET).
