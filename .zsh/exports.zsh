#==============================================================================
# ENVIRONMENT VARIABLES
#==============================================================================
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1 

# Path configurations
export PATH="$HOME/bin:$PATH"
export PATH=$PATH:$HOME/go/bin

# Source additional environment variables
. "$HOME/.local/bin/env" 