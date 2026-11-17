-- ~/.config/yazi/init.lua (shared: macOS + Arch)
require("zoxide"):setup {
    update_db = true,  -- Add directories to zoxide database when navigating
}

-- Space / Ctrl+R: Quick Look / Finder. On the Mac it opens in place; on Arch (seen from
-- the Mac through Herdr or ssh) it copies the file to the Mac first. Plugin vendored
-- from github.com/A-PachecoT/remote-quicklook.yazi; update with `cp` from ~/oss.
require("remote-quicklook"):setup {
    host = "styreep@100.73.150.52",  -- same Mac as scripts/mac-clipboard
}
