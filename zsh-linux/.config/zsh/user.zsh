#  Startup 
# Commands to execute on startup (before the prompt is shown)
# Check if the interactive shell option is set
if [[ $- == *i* ]]; then
    # This is a good place to load graphic/ascii art, display system information, etc.
    if command -v pokego >/dev/null; then
        pokego --no-title -r 1,3,6
    elif command -v pokemon-colorscripts >/dev/null; then
        pokemon-colorscripts --no-title -r 1,3,6
    elif command -v fastfetch >/dev/null; then
        if do_render "image"; then
            fastfetch --logo-type kitty
        fi
    fi
fi

#   Overrides 
# HYDE_ZSH_NO_PLUGINS=1 # Set to 1 to disable loading of oh-my-zsh plugins, useful if you want to use your zsh plugins system 
# unset HYDE_ZSH_PROMPT # Uncomment to unset/disable loading of prompts from HyDE and let you load your own prompts
# HYDE_ZSH_COMPINIT_CHECK=1 # Set 24 (hours) per compinit security check // lessens startup time
# HYDE_ZSH_OMZ_DEFER=1 # Set to 1 to defer loading of oh-my-zsh plugins ONLY if prompt is already loaded

if [[ ${HYDE_ZSH_NO_PLUGINS} != "1" ]]; then
    #  OMZ Plugins 
    # manually add your oh-my-zsh plugins here
    plugins=(
        "sudo"
    )
fi

# Zoxide configuration moved to conf.d/98-zoxide.zsh

# Arduino CLI aliases
alias acc='arduino-cli compile --fqbn arduino:avr:uno'
alias acu='arduino-cli upload -p /dev/ttyACM0 --fqbn arduino:avr:uno'
alias accu='arduino-cli compile --fqbn arduino:avr:uno $1 && arduino-cli upload -p /dev/ttyACM0 --fqbn arduino:avr:uno $1'
alias acm='arduino-cli monitor -p /dev/ttyACM0'
alias acb='arduino-cli board list'
alias ach='echo "Arduino CLI Aliases:\n  acc  <sketch>  - Compilar\n  acu  <sketch>  - Subir (upload)\n  accu <sketch>  - Compilar + Subir\n  acm            - Monitor serial\n  acb            - Listar placas conectadas\n  ach            - Esta ayuda"'