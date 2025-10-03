#==============================================================================
# CUSTOM FUNCTIONS
#==============================================================================
# Example function - you can add your custom functions here
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Conda initialization function (moved from main config for cleaner startup)
function init_conda() {
    __conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
            . "/opt/miniconda3/etc/profile.d/conda.sh"
        else
            export PATH="/opt/miniconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
}

# Initialize conda if it exists
[ -f "/opt/miniconda3/bin/conda" ] && init_conda 