# 🏠 Dotfiles

Personal macOS configuration files managed with [GNU Stow](https://www.gnu.org/software/stow/). Features a HyDE-inspired aesthetic with AeroSpace tiling window manager and SketchyBar status bar.

## 🚀 Quick Start

```bash
# Clone the repository
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles

# Install GNU Stow (if not already installed)
brew install stow

# Install all configurations
./install.sh
```

## 📦 Included Configurations

### 🪟 Window Management
- **AeroSpace**: i3-like tiling window manager for macOS
  - Hyprland-inspired keybindings (`Alt+hjkl` navigation)
  - Workspace switching (`Alt+1-9`)
  - Dynamic gaps and layouts

### 🎨 Status Bar
- **SketchyBar**: Customizable menu bar replacement
  - HyDE-inspired dark theme
  - Workspace indicators (occupied workspaces only)
  - AeroSpace integration
  - MonoLisa font styling

### 🔧 Development Tools
- **Git**: Version control configuration
- **Zsh**: Shell configuration
- **Python/Jupyter**: Global environment with `uv` for notebooks

## 🏗️ Structure

```
~/dotfiles/
├── aerospace/           # AeroSpace window manager
│   └── .aerospace.toml
├── sketchybar/          # SketchyBar status bar
│   └── .config/
│       └── sketchybar/
│           ├── sketchybarrc
│           ├── plugins/
│           └── themes/
├── git/                 # Git configuration
│   └── .gitconfig
├── zsh/                 # Zsh shell
│   └── .zshrc
├── scripts/             # Utility scripts
├── docs/                # Documentation
├── backup/              # Automatic backups
├── install.sh           # Installation script
└── .stow-local-ignore   # Files to ignore during stowing
```

## 🛠️ Management Commands

```bash
# Install all configurations
./install.sh install

# Remove all symlinks
./install.sh unstow

# Reinstall (useful after updates)
./install.sh restow

# Backup existing configs only
./install.sh backup

# Setup global Jupyter environment
./install.sh jupyter
```

## 🔗 How It Works

This setup uses **GNU Stow** to create symlinks from your home directory to the dotfiles repository:

```
~/.aerospace.toml → ~/dotfiles/aerospace/.aerospace.toml
~/.config/sketchybar → ~/dotfiles/sketchybar/.config/sketchybar
~/.gitconfig → ~/dotfiles/git/.gitconfig
```

### Benefits:
- ✅ **Single Source of Truth**: All configs in one repo
- ✅ **Version Control**: Full Git history of changes
- ✅ **Cross-Machine Sync**: Same setup everywhere
- ✅ **Modular**: Enable/disable specific packages
- ✅ **Safe**: Easy to unstow and revert

## ⚙️ Manual Package Management

Install specific packages:
```bash
# Individual packages
stow aerospace
stow sketchybar
stow git
stow zsh

# Remove specific package
stow -D aerospace
```

## 🎯 Key Features

### AeroSpace Configuration
- **Keybindings**: Hyprland-style (`Alt` modifier)
- **Workspaces**: 1-10 with dynamic switching
- **Layouts**: Tiling with customizable gaps
- **Integration**: Auto-starts SketchyBar

### SketchyBar Features
- **Theme**: HyDE-inspired dark aesthetic
- **Workspaces**: Shows only occupied workspaces
- **Font**: MonoLisa for clean typography
- **Indicators**: Real-time workspace highlighting

## 🔄 Updating Configurations

1. Edit files in the dotfiles repository
2. Changes are immediately reflected (symlinks!)
3. Commit and push to sync across machines
4. Run `./install.sh restow` if you add new files

## 🆘 Troubleshooting

### Conflicts During Installation
The install script automatically handles common conflicts by backing up existing files.

### Restore Original Configs
```bash
# Unstow everything
./install.sh unstow

# Restore from backup
cp backup/.aerospace.toml ~/.aerospace.toml
cp -r backup/sketchybar ~/.config/
```

### Check Symlinks
```bash
# Verify symlinks are correct
ls -la ~/.aerospace.toml ~/.config/sketchybar ~/.gitconfig
```

## 📚 Dependencies

- **macOS**: Sonoma or later
- **Homebrew**: Package manager
- **GNU Stow**: Symlink management
- **AeroSpace**: Window manager
- **SketchyBar**: Status bar
- **MonoLisa**: Font (optional but recommended)
- **uv**: Python package manager (for Jupyter setup)

## 🐍 Python & Jupyter Setup

This dotfiles includes automatic setup for a global Jupyter environment using `uv`.

### Quick Start
```bash
# Setup global environment (automatically includes common data science packages)
./install.sh jupyter

# Use in VS Code
# 1. Open any .ipynb file
# 2. Select kernel: "Python (Global Jupyter)"
# 3. Start coding!

# Install additional packages
uv pip install --python ~/.jupyter-env/bin/python <package-name>
```

### What's Included
- **Location**: `~/.jupyter-env/`
- **Kernel**: `jupyter-global` (available in VS Code and Jupyter)
- **Pre-installed packages**:
  - `ipykernel`, `jupyter`, `jupyterlab`
  - `pandas`, `numpy`, `matplotlib`, `seaborn`
  - `scikit-learn`

### When to Use
- ✅ **Use global env** for general data analysis and learning
- ⚠️ **Use project env** when:
  - Project has specific version requirements
  - Need isolated dependencies for deployment
  - Working with conflicting package versions

```bash
# Create project-specific environment
cd /path/to/project
uv venv
source .venv/bin/activate
uv pip install ipykernel <other-packages>
python -m ipykernel install --user --name=project-name
```

See [CLAUDE.md](CLAUDE.md#python--jupyter-management) for detailed documentation.

## 🎨 Customization

### Colors and Themes
Edit `sketchybar/.config/sketchybar/themes/tokyo-night` for color customization.

### Keybindings
Modify `aerospace/.aerospace.toml` for different keyboard shortcuts.

### Workspace Behavior
Adjust workspace logic in `sketchybar/.config/sketchybar/sketchybarrc`.

## 📝 License

Personal dotfiles - feel free to use as inspiration for your own setup!

---

*✨ Crafted with attention to detail for a productive and beautiful macOS environment*