#==============================================================================
# WSL-SPECIFIC CONFIGURATION
#==============================================================================
# Windows path-related aliases
alias cdco='cd /mnt/d/code'
alias cddo='cd /mnt/c/Users/Andre/Downloads'
alias cduni='cd /mnt/c/Users/AndreP/OneDrive\ -\ UNIVERSIDAD\ NACIONAL\ DE\ INGENIERIA/UNI-HUB/UNI\ 2024-2/'
alias cdbr='cd /mnt/c/Brainflow'
alias cdcp='cd /mnt/c/projects'

# Windows integration aliases
alias ex='explorer.exe .'

# YaVendio utils
alias yavgatestg='cd ~/yav/message-gateway && git checkout main && git pull --rebase && conda activate yav-gateway && vim config/stg.yaml'
alias yavgateprd='cd ~/yav/message-gateway && git checkout main && git pull --rebase && conda activate yav-gateway && vim config/prd.yaml'
alias cdya='cd /mnt/d/yavendio/clients_backends' 

# Setup Vagrant variables
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="/mnt/c/Users/Andre/"
export PATH="$PATH:/mnt/c/Program Files/Oracle/VirtualBox"

# Mobile Development (Android)
export ANDROID_HOME=/mnt/c/Users/Andre/AppData/Local/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
