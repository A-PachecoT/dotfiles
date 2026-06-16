-- chafa.yazi — image previewer that renders via chafa (Unicode symbols).
--
-- Why: over a tmux + Eternal Terminal + Ghostty chain, yazi's native image
-- adapter for Ghostty is "Kitty unicode placeholders" (Kgp). Those placeholder
-- cells (U+10EEEE + combining diacritics encoding the image id) get mangled in
-- transit by tmux/ET, so Ghostty can't reassemble the image and the panel stays
-- blank (with the placeholder glyphs leaking as `+++++`). chafa's
-- `--format=symbols` output is plain colored text and always survives the chain.
--
-- We only take over in REMOTE sessions (SSH/ET). When yazi runs locally (e.g.
-- natively on macOS), we defer to the built-in `image` previewer so real
-- graphics protocols still apply.

local M = {}

local function is_remote()
	if os.getenv("SSH_CONNECTION") or os.getenv("SSH_CLIENT") or os.getenv("SSH_TTY") then
		return true
	end
	local sock = os.getenv("SSH_AUTH_SOCK") or ""
	return sock:find("et_forward", 1, true) ~= nil
end

local function show(job, widget)
	local fn = ya.preview_widget or ya.preview_widgets
	fn(job, widget)
end

function M:peek(job)
	-- Local session: let yazi's native graphics adapter handle it.
	if not is_remote() then
		local ok, image = pcall(require, "image")
		if ok and image then
			return image.peek(image, job)
		end
	end

	local area = job.area
	local output, err = Command("chafa")
		:arg({
			"--format=symbols",
			-- Sextants (2x3 sub-cells) + blocks give ~3x the resolution of half
			-- blocks while staying as plain colored glyphs Ghostty draws natively
			-- (so they survive tmux + Eternal Terminal, unlike Kitty graphics).
			"--symbols=sextant+block+quad+half+space",
			"--dither=ordered",
			"--size=" .. area.w .. "x" .. area.h,
			"--animate=off",
			-- Don't let chafa query the terminal (fg/bg color, size, DA1): its
			-- stdin races with yazi for the tty, and the bg-color response
			-- `ESC]11;rgb:1a1a/1b1b/2626` leaks its `/` separators into yazi as
			-- keystrokes -> spuriously opens the "Find next:" prompt.
			"--probe=off",
			"--passthrough=none",
			tostring(job.file.url),
		})
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	if not output then
		return show(job, ui.Text("chafa failed to run: " .. tostring(err)):area(area))
	end
	if output.stdout == nil or output.stdout == "" then
		local msg = (output.stderr ~= nil and output.stderr ~= "") and output.stderr or "chafa: empty output"
		return show(job, ui.Text(msg):area(area))
	end

	show(job, ui.Text.parse(output.stdout):area(area))
end

function M:seek() end

return M
