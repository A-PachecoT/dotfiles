# Dotfiles Modernization Prompt

## Context

The dotfiles repository is currently incompatible with the existing system configuration. The repo assumes a different architecture (Zinit-based, cross-platform) while the actual system uses Oh My Zsh with a modern XDG-compliant structure.

### Current System Reality
- **Shell**: Oh My Zsh (not Zinit)
- **Config Location**: `~/.config/zsh/` (XDG compliant)
- **Customizations**: `~/.user.zsh` for plugins/aliases
- **Working Tools**: direnv, uv, ruff already configured

### Dotfiles Repository Issues
- Designed for Zinit (not Oh My Zsh)
- Cross-platform code (WSL, Ubuntu, Windows)
- Would override working configuration
- Conflicts with HyDE/Arch Linux setup
- Unsafe shell switching mechanisms

## Research Requirements

### 1. **Analyze Current Working System**
   - Map all configuration files and their purposes
   - Document what's working well (Oh My Zsh plugins, direnv, etc.)
   - Identify any missing features user might want
   - Check `~/.config/` for other application configs

### 2. **Evaluate Dotfiles Repository**
   - Identify valuable components (aliases, functions, shortcuts)
   - Extract Python setup best practices
   - Note useful Git configurations
   - Find reusable scripts

### 3. **User Clarification Needed**
   - Primary use cases for dotfiles sync?
   - Which machines need configuration sync?
   - Preference: adapt existing or start fresh?
   - Any specific features from old dotfiles to preserve?

## Proposed Solutions

### Option 1: Minimal Dotfiles Adapter
Create a lightweight dotfiles system that works WITH current setup:
- Sync only user customizations (`~/.user.zsh`, specific configs)
- Preserve existing Oh My Zsh structure
- Add only missing features as plugins/functions
- Use stow or simple symlinks

### Option 2: Modern Dotfiles Rewrite
Start fresh with current system as base:
- Document existing configuration
- Create new dotfiles repo matching current structure
- Use chezmoi or similar for templating
- Support only current environment (Arch/HyDE)

### Option 3: Cherry-Pick Integration
Extract valuable parts from old dotfiles:
- Port useful aliases/functions to `~/.user.zsh`
- Adapt Python setup for uv (already using it)
- Keep Git config if better
- Ignore all cross-platform/legacy code

## Implementation Blueprint

```bash
# Proposed structure for modern dotfiles
~/dotfiles-modern/
├── .config/
│   └── zsh/          # Only if overriding needed
├── home/
│   ├── .user.zsh     # Main customizations
│   ├── .gitconfig    # If different from current
│   └── .envrc.global # Global direnv configs
├── scripts/
│   ├── install.sh    # Simple, Arch-only
│   └── sync.sh       # Lightweight sync
└── README.md         # Clear documentation
```

## Validation Requirements

- [ ] Doesn't break existing Oh My Zsh setup
- [ ] Preserves working direnv configuration
- [ ] Compatible with HyDE desktop environment
- [ ] Simple enough to maintain
- [ ] Clear uninstall process

## Key Decisions Needed

1. **Sync Strategy**: What needs syncing vs local-only?
2. **Tool Choice**: stow, chezmoi, or custom scripts?
3. **Scope**: Full config management or just customizations?
4. **Backwards Compatibility**: Support old structure at all?

## Success Criteria

- Current working setup remains functional
- Easy to sync between machines
- Clear separation of concerns
- No conflicts with system packages
- Maintainable over time

## Anti-Patterns to Avoid

- ❌ Overriding system configurations unnecessarily
- ❌ Cross-platform complexity when not needed
- ❌ Unsafe shell switching
- ❌ Breaking HyDE integrations
- ❌ Monolithic setup scripts

## Recommendation

Given the current setup works well, recommend **Option 3: Cherry-Pick Integration** with these priorities:

1. Keep current Oh My Zsh setup untouched
2. Create minimal dotfiles for syncing customizations
3. Extract only proven-useful components from old repo
4. Use simple tooling (stow or symlinks)
5. Document clearly what each component does

This approach respects the working system while adding value where needed.