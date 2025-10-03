# System Migration Notes - HyDE/Arch Linux Dotfiles

**Created:** 2025-07-24  
**Context:** Current dotfiles system has legacy cross-platform code that conflicts with HyDE (Hyperland Desktop Environment) and Arch Linux best practices.

## Current System Analysis

### Architecture Issues

1. **Cross-Platform Legacy Code**
   - System has Ubuntu/WSL specific configurations mixed with Arch Linux code
   - Package manager detection uses both `pacman` and `apt-get`
   - Windows-specific files (`.zshrc.windows`, `win11_config/`) not needed for HyDE setup
   - WSL detection logic conflicts with native Arch Linux environment

2. **Shell Management Problems**
   - `setup.sh` uses unsafe shell switching that modifies `.bashrc`
   - Adds `exec zsh` to `.bashrc` which can cause login loops
   - Safety fallback mechanisms designed for remote/VM environments not needed locally
   - HyDE already manages shell preferences through its own configuration

3. **Package Management Conflicts**
   - Uses both `pacman` and `yay` without proper detection of AUR helper preference
   - Installs system packages that might conflict with HyDE's curated package set
   - Font installation bypasses HyDE's font management system
   - Python environment setup conflicts with HyDE's development tools

### HyDE Integration Issues

1. **Configuration Conflicts**
   - `.zshrc` disables HyDE's Oh My Zsh loading (`unset DEFER_OMZ_LOAD`)
   - Powerlevel10k installation might conflict with HyDE's theme system
   - Custom aliases/functions may override HyDE's optimized shortcuts
   - XDG Base Directory compliance partial - some configs still use legacy paths

2. **Plugin Management**
   - Uses Zinit instead of HyDE's preferred plugin manager
   - Plugin selection not optimized for Hyperland workflow
   - Fast-syntax-highlighting may conflict with HyDE's syntax highlighting
   - History management separate from HyDE's unified history system

## Required Fixes

### High Priority (Critical)

1. **Remove Cross-Platform Code**
   - [ ] Remove all WSL detection and Windows-specific configurations
   - [ ] Remove Ubuntu/Debian package installation logic
   - [ ] Simplify to Arch Linux only with proper AUR helper support
   - [ ] Remove remote/VM safety mechanisms for local installation

2. **Fix Shell Management**
   - [ ] Remove `.bashrc` modification logic
   - [ ] Use proper `chsh` command for shell changing
   - [ ] Remove backup shell switching mechanisms
   - [ ] Integrate with HyDE's shell preferences

3. **Package Management Overhaul**
   - [ ] Use only `pacman` and detect preferred AUR helper (`yay`, `paru`)
   - [ ] Respect HyDE's package management preferences
   - [ ] Remove system font installation (use HyDE's font system)
   - [ ] Coordinate with HyDE's Python development setup

### Medium Priority (Important)

4. **HyDE Integration**
   - [ ] Respect HyDE's Oh My Zsh configuration instead of disabling it
   - [ ] Coordinate with HyDE's theme system for Powerlevel10k
   - [ ] Merge custom functions with HyDE's function library
   - [ ] Use HyDE's XDG Base Directory structure consistently

5. **Plugin System Modernization**
   - [ ] Evaluate Zinit vs HyDE's preferred plugin manager
   - [ ] Review plugin selection for Hyperland compatibility
   - [ ] Integrate with HyDE's completion system
   - [ ] Coordinate syntax highlighting with HyDE's preferences

### Low Priority (Enhancement)

6. **Code Quality**
   - [ ] Remove unused configuration files
   - [ ] Simplify backup system (remove VM-specific features)
   - [ ] Update documentation to reflect Arch Linux/HyDE only
   - [ ] Clean up GitHub Actions workflow for local-only setup

## Migration Strategy

### Phase 1: Assessment
- [ ] Backup current working HyDE configuration
- [ ] Document current HyDE customizations that should be preserved
- [ ] Test dotfiles in isolated environment to identify all conflicts

### Phase 2: Cleanup
- [ ] Remove all non-Arch Linux code paths
- [ ] Simplify setup scripts for local Arch installation only
- [ ] Remove Windows/WSL specific files and configurations

### Phase 3: Integration
- [ ] Modify configurations to work WITH HyDE instead of replacing it
- [ ] Use HyDE's package management and font systems
- [ ] Coordinate theme and plugin management

### Phase 4: Testing
- [ ] Test installation on fresh HyDE system
- [ ] Verify no conflicts with HyDE's existing configurations
- [ ] Test all custom functions and aliases

## Files Requiring Major Changes

### Remove Completely
- `win11_config/` directory
- `.zshrc.windows`
- WSL-specific logic in all scripts
- Ubuntu/Debian package installation code

### Significant Refactoring
- `setup.sh` - Remove cross-platform logic, simplify for Arch only
- `sync.sh` - Remove VM/remote session handling
- `.zshrc` - Integrate with HyDE instead of overriding
- `.zsh/plugins.zsh` - Coordinate with HyDE's plugin system

### Minor Updates
- `README.md` - Update for HyDE/Arch Linux only
- `.gitconfig` - Ensure XDG compliance
- Python setup scripts - Coordinate with HyDE's development tools

## Notes for Implementation

- **Test thoroughly** - HyDE has a complex configuration system
- **Preserve HyDE features** - Don't break existing HyDE functionality
- **Use HyDE patterns** - Follow HyDE's configuration conventions
- **Consider AUR packages** - Many tools may be available via AUR instead of manual installation
- **Document changes** - Keep track of what works well with HyDE

## Related Files
- Main configuration: `.zshrc`, `.zsh/`
- Setup scripts: `setup.sh`, `sync.sh`  
- Documentation: `README.md`, `PYTHON_SETUP.md`
- Package management: All installation logic in scripts
