# Python Development Environment Setup

This document describes the comprehensive Python environment setup for reliable development across different contexts (system packages, development projects, and Jupyter notebooks).

## 🎯 Overview

This setup provides a hybrid Python environment that leverages:
- **System Python** (3.13+) for system tools and AUR package builds
- **UV** as primary Python version and package manager with automatic activation
- **Base environment** with common data science libraries (auto-activated on shell startup)
- **Miniconda** available when conda-specific packages are needed
- **Global tools** available everywhere
- **Jupyter** integration with proper kernels

## 📁 Architecture

```
Python Environment Architecture:
├── System Python (3.13+)           # For system tools, AUR builds
├── uv                               # Primary Python manager (fast, modern)
├── ~/.venvs/base/                   # Base env with common libraries
├── /opt/miniconda3/                 # Available when needed
├── ~/.local/bin/                    # Global tools (ruff, ipython, etc.)
└── ~/.config/zsh/conf.d/            # ZSH configuration
```

## 🚀 Installation

### 1. Install System Dependencies

```bash
# Install system Python build tools
sudo pacman -S python-pip python-build python-wheel python-setuptools python-virtualenv

# Install uv (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 2. Create Base Environment

```bash
# Create comprehensive base environment
uv venv ~/.venvs/base --python 3.13

# Install common data science and development packages
source ~/.venvs/base/bin/activate
uv pip install numpy pandas matplotlib seaborn scikit-learn requests jupyter ipython black ruff pytest mypy build wheel setuptools
```

### 3. Install Global Tools

```bash
# Install tools available system-wide
uv tool install black
uv tool install ruff  
uv tool install ipython
```

### 4. Setup Jupyter Kernel

```bash
# Create Jupyter kernel for base environment
source ~/.venvs/base/bin/activate
python -m ipykernel install --user --name=base --display-name="Python (Base Environment)"
```

### 5. Configure IDE (Cursor/VS Code)

Add to `~/.config/Cursor/User/settings.json`:
```json
{
    "python.defaultInterpreterPath": "/home/andre/.venvs/base/bin/python",
    "python.terminal.activateEnvironment": true,
    "jupyter.kernels.filter": [
        {
            "path": "/home/andre/.venvs/base/bin/python",
            "type": "pythonEnvironment"
        }
    ]
}
```

## 🔧 Shell Integration

The shell configuration is automatically loaded via XDG-compliant structure:
- Main config: `~/.config/zsh/conf.d/99-custom-python.zsh`
- Follows HyDE dotfiles system conventions
- Loaded automatically in new terminal sessions

### Available Aliases

```bash
# Python Environment Management
pybase      # Activate base environment with all common packages (auto-activated on startup)
pysys       # Use system Python (deactivate virtual environments)
pyconda     # Activate miniconda when conda-specific packages needed

# UV Package Manager Shortcuts
uvx         # Run tools without installing (uv tool run)
uvi         # Install packages in current env (uv pip install)
uvs         # Sync packages from requirements (uv pip sync)
uvr         # Run commands in UV environment (uv run)
pip         # Redirects to 'uv pip' when in virtual environment

# Jupyter Shortcuts
jlab        # Launch JupyterLab with base environment
jnb         # Launch Jupyter Notebook with base environment

# Development Tools (available globally)
ruff        # Python linter/formatter
black       # Code formatter
ipython     # Enhanced Python REPL
code2prompt # Code documentation tool (installed via cargo)
```

## 💡 Usage Patterns

### Default Behavior
```bash
# Open new terminal - base environment is auto-activated
# You can immediately run Python scripts with common libraries
python my_script.py  # Works with numpy, pandas, etc. already available
```

### For New Projects
```bash
# Create new project with uv
uv init myproject
cd myproject
uv add requests pandas matplotlib  # Add project-specific deps
```

### For Quick Analysis/Scripts
```bash
# Base environment is already active, just run your script
python my_analysis.py

# Or explicitly use base environment if you switched away
pybase
python my_analysis.py
```

### Installing Packages
```bash
# In any virtual environment (including auto-activated base)
pip install package_name  # Automatically uses UV under the hood
# or
uvi package_name  # Direct UV alias
```

### For Jupyter Notebooks
```bash
# Launch with all packages available
jlab
# or
jnb
```

### For System Package Building (AUR)
- Uses system Python automatically
- All build tools (build, wheel, setuptools) available
- No environment conflicts

## 🔍 Troubleshooting

### AUR Package Build Issues
If AUR packages fail to build due to missing Python modules:
```bash
# Install the missing module in miniconda (where AUR often looks)
/opt/miniconda3/bin/python -m pip install build wheel setuptools
```

### Environment Not Loading
```bash
# Check if configuration is loaded
zsh -c "pybase && echo 'Config working'"

# Manual reload
source ~/.config/zsh/conf.d/99-custom-python.zsh
```

### Jupyter Kernel Issues
```bash
# List available kernels
jupyter kernelspec list

# Reinstall base kernel
source ~/.venvs/base/bin/activate
python -m ipykernel install --user --name=base --display-name="Python (Base Environment)" --force
```

## 🔄 Maintenance

### Keep Base Environment Updated
```bash
pybase
uv pip install --upgrade numpy pandas matplotlib jupyter
```

### Update Global Tools
```bash
uv tool upgrade black
uv tool upgrade ruff
```

### System Python Updates
When system Python updates, recreate base environment:
```bash
uv venv ~/.venvs/base --python 3.13 --force
# Then reinstall packages following step 2 above
```

## 🎛️ Configuration Files

### Key Files Created/Modified:
- `~/.config/zsh/conf.d/99-custom-python.zsh` - Main Python configuration
- `~/.config/Cursor/User/settings.json` - IDE Python interpreter settings
- `~/.venvs/base/` - Base Python environment
- `~/.local/share/jupyter/kernels/base/` - Jupyter kernel

### Integration Points:
- **HyDE dotfiles**: Uses `conf.d/` structure for compatibility
- **XDG Base Directory**: Follows modern Linux standards
- **System Package Manager**: Doesn't interfere with system Python
- **IDE Integration**: Automatic detection and activation

## 📊 Benefits

✅ **Reliable**: Works across AUR builds, development, and data science  
✅ **Fast**: uv provides extremely fast package management  
✅ **Modern**: Follows XDG Base Directory and modern Python practices  
✅ **Compatible**: Works with HyDE, system updates, and IDE integration  
✅ **Comprehensive**: Includes all common data science libraries by default  
✅ **Maintainable**: Clear separation of concerns and documented patterns  

This setup eliminates the common Python environment issues while providing a robust foundation for all development needs.
