#==============================================================================
# ENVIRONMENT VARIABLES
#==============================================================================
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1 

# Path configurations
export PATH="$HOME/bin:$PATH"
export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:$HOME/.cargo/bin

# Source additional environment variables (commented out - file doesn't exist)
# . "$HOME/.local/bin/env" 