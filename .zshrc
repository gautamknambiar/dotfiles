if [[ "$(uname)" == "Darwin" && -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

ZSH_D="$HOME/.zsh.d"
CONFIG_FILE="$HOME/.config/fastfetch/config_src.jsonc"

if [[ -r "$ZSH_D/zsh_colors" ]]; then
    source "$ZSH_D/zsh_colors"
fi

if [[ -r "$ZSH_D/zsh_functions" ]]; then
    source "$ZSH_D/zsh_functions"
fi

zsh_daily_motd

cleanpath -q

if [[ -r "$HOME/.local/bin/env" ]]; then
    . "$HOME/.local/bin/env"
fi
