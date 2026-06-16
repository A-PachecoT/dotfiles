-- imgview.yazi — full-resolution image viewer.
--
-- Bind a key to `plugin imgview`. On the hovered image it hides yazi
-- (ui.hide), hands the terminal to view.py which paints the image at real
-- resolution using the Kitty graphics protocol with DIRECT placement (wrapped
-- in tmux passthrough) — the method proven to survive tmux + Eternal Terminal
-- + Ghostty, unlike yazi's native unicode-placeholder path. Press any key to
-- return to yazi.

local IMAGE_EXT = {
	png = true, jpg = true, jpeg = true, gif = true, webp = true, bmp = true,
	tif = true, tiff = true, avif = true, jxl = true, ico = true, heic = true,
	heif = true, jpe = true, jfif = true,
}

local hovered = ya.sync(function()
	local h = cx.active.current.hovered
	return h and tostring(h.url) or nil
end)

return {
	entry = function()
		local url = hovered()
		if not url then
			return
		end
		local ext = url:match("%.([%a%d]+)$")
		if not ext or not IMAGE_EXT[ext:lower()] then
			ya.notify { title = "imgview", content = "Not an image file", timeout = 2, level = "warn" }
			return
		end

		local permit = ui.hide()
		Command("bash")
			:arg({
				"-c",
				'exec python3 "$HOME/dotfiles/shared/yazi/.config/yazi/plugins/imgview.yazi/view.py" "$1"',
				"bash",
				url,
			})
			:stdin(Command.INHERIT)
			:stdout(Command.INHERIT)
			:stderr(Command.INHERIT)
			:status()
		permit:drop()
	end,
}
