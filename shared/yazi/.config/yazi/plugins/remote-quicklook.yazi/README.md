# remote-quicklook.yazi

Quick Look and Finder on your Mac for files on a remote machine.

You run [yazi](https://github.com/sxyazi/yazi) on a Linux box over ssh, Eternal Terminal,
mosh or a multiplexer, but you look at it from a Mac. Local previewers can't help you:
`xdg-open` opens on a screen nobody watches, and image protocols don't cover PDFs, videos
or Office files. This plugin copies the hovered file to a cache on your Mac over ssh and
opens it there.

- `preview`: Quick Look (`qlmanage -p`), brought to the front
- `reveal`: shown in Finder (`open -R`)

## Requirements

- From the remote box, `ssh you@mac` works without a password (key auth). Tailscale
  makes this easy.
- yazi 25.5.31 or newer.

## Install

```sh
ya pkg add A-PachecoT/remote-quicklook
```

## Setup

`~/.config/yazi/init.lua`:

```lua
require("remote-quicklook"):setup {
	host = "you@your-mac",                     -- required: anything `ssh` accepts
	-- cache = "Library/Caches/remote-quicklook", -- on the Mac, relative to $HOME
	-- max_mb = 500,                              -- refuse bigger files
}
```

`~/.config/yazi/keymap.toml`:

```toml
[[mgr.prepend_keymap]]
on   = "<Space>"
run  = "plugin remote-quicklook preview"
desc = "Quick Look on the Mac"

[[mgr.prepend_keymap]]
on   = "<C-r>"
run  = "plugin remote-quicklook reveal"
desc = "Reveal in the Mac's Finder"
```

On the Mac itself the plugin opens the file in place (no ssh, no copy), so a keymap
shared between the Mac and the remote box works on both. `host` is only needed on the
remote side.

## Notes

- The Mac gets a **copy**: edits there don't go back to the remote file.
- Copies live in one folder per source directory and are never deleted by the plugin;
  macOS may purge `~/Library/Caches`, or clear it yourself.
- Directories are skipped.

## License

MIT
