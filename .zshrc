if [[ "$(uname)" == "Darwin" && -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

ZSH_D="$HOME/.zsh.d"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config_src.jsonc"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DOTFILES_SHELL_LOADER="${DOTFILES_SHELL_LOADER:-$DOTFILES_DIR/Scripts/shell_loader.sh}"

if [[ -r "$DOTFILES_SHELL_LOADER" ]]; then
    source "$DOTFILES_SHELL_LOADER"
    dotfiles_init_shell zsh "$ZSH_D"
fi

if command -v cleanpath >/dev/null 2>&1; then
    cleanpath -q
fi

if [[ -r "$HOME/.local/bin/env" ]]; then
    . "$HOME/.local/bin/env"
fi
