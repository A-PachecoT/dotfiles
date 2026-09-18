-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

local opt = vim.opt

-- Line numbers
opt.relativenumber = true  -- Relative line numbers (great for vim motions)
opt.number = true          -- Show current line number

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true       -- Case-sensitive if uppercase in search

-- UI
opt.termguicolors = true   -- True color support
opt.signcolumn = "yes"     -- Always show sign column
opt.cursorline = true      -- Highlight current line
opt.scrolloff = 8          -- Keep 8 lines above/below cursor
opt.sidescrolloff = 8

-- System clipboard integration
opt.clipboard = "unnamedplus"

-- Headless box (Arch via `ha` = herdr over ET): no native clipboard, and ET
-- doesn't set SSH_TTY, so nvim never falls back to OSC 52 on its own. Yanks go
-- out as OSC 52 (herdr → ET → Ghostty → Mac clipboard). Paste stays local: an
-- OSC 52 read makes Ghostty prompt or nvim hang. Mac clipboard in → Cmd+V.
if vim.fn.has("mac") == 0 and not vim.env.WAYLAND_DISPLAY and not vim.env.DISPLAY then
  local osc52 = require("vim.ui.clipboard.osc52")
  local last = {}
  local function copy(reg)
    local send = osc52.copy(reg)
    return function(lines, regtype)
      last[reg] = { lines, regtype }
      send(lines)
    end
  end
  local function paste(reg)
    return function() return last[reg] or { {}, "v" } end
  end
  vim.g.clipboard = {
    name = "osc52-copy",
    copy = { ["+"] = copy("+"), ["*"] = copy("*") },
    paste = { ["+"] = paste("+"), ["*"] = paste("*") },
  }
end

-- Faster completion
opt.updatetime = 250
opt.timeoutlen = 300       -- Faster which-key popup

-- Undo persistence
opt.undofile = true
opt.undolevels = 10000

-- Split behavior (more natural)
opt.splitright = true
opt.splitbelow = true

-- No swap files (we have undo persistence)
opt.swapfile = false

-- Wrap (useful for markdown)
opt.wrap = false           -- No wrap by default
opt.linebreak = true       -- Wrap at word boundaries when enabled
