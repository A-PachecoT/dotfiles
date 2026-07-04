#!/usr/bin/env zsh

[[ $- == *i* ]] || return 0
#  Vi mode for the zsh command line
#
#  Shared across macOS + Linux. Sourced from macos/.zshrc and
#  linux conf.d/97-vi-mode.zsh. Esc -> NORMAL mode (h/j/k/l, dd, ciw, etc).
#
#  Prompt indicator: starship (macOS) and p10k vi_mode (Linux) both show the
#  current mode automatically once `bindkey -v` is active.

# Enable vi keymap for line editing
bindkey -v

# Make <Esc> switch to NORMAL mode almost instantly (10ms instead of 0.4s).
# Low value = snappy mode switch; too low can clip multi-key sequences, 10ms is safe.
export KEYTIMEOUT=1

# --- Keep the useful emacs bindings in INSERT mode ---------------------------
# Pure vi mode drops these and it hurts daily use. Restore the muscle-memory ones.
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^Y' yank
bindkey -M viins '^?' backward-delete-char      # Backspace past insert point
bindkey -M viins '^H' backward-delete-char

# Incremental history search (fzf usually owns ^R; this is the fallback)
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M vicmd '^R' history-incremental-search-backward

# --- NORMAL mode niceties ----------------------------------------------------
# Edit the current command in $EDITOR (nvim) with `v` (very-magic vim editing)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Up/Down search history by what's already typed
bindkey -M vicmd 'k' up-line-or-history
bindkey -M vicmd 'j' down-line-or-history

# --- Cursor shape: block in NORMAL, beam in INSERT ---------------------------
# Works in Ghostty, kitty, and most modern terminals via DECSCUSR escapes.
_vi_cursor_block() { print -n '\e[1 q'; }   # steady block
_vi_cursor_beam()  { print -n '\e[5 q'; }   # steady beam

function zle-keymap-select {
  case $KEYMAP in
    vicmd)      _vi_cursor_block ;;   # NORMAL
    main|viins) _vi_cursor_beam  ;;   # INSERT
  esac
}
zle -N zle-keymap-select

function zle-line-init {
  _vi_cursor_beam   # always start a fresh prompt in INSERT
}
zle -N zle-line-init

# Reset to beam after a command finishes running
_vi_cursor_beam
