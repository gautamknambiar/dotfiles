#!/usr/bin/env bash

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/gautamknambiar/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DOTFILES_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles"
BACKUP_DIR="${DOTFILES_BACKUP_DIR:-$DOTFILES_DATA_HOME/backups}"
APPLESCRIPT_PATH="$DOTFILES_DIR/Scripts/terminal.applescript"

is_macos() {
    [ "$(uname -s)" = "Darwin" ]
}

is_linux() {
    [ "$(uname -s)" = "Linux" ]
}

is_wsl() {
    is_linux || return 1
    if [ -r /proc/sys/kernel/osrelease ] && grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease; then
        return 0
    fi
    [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ]
}

platform_name() {
    if is_macos; then
        echo "macOS"
    elif is_wsl; then
        echo "WSL Linux"
    elif is_linux; then
        echo "Linux"
    else
        uname -s
    fi
}

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "Skipping root command because sudo is not available: $*" >&2
        return 1
    fi
}

prompt_yes_no() {
    local prompt="$1"
    local default_answer="${2:-Y}"
    local reply

    if [ ! -t 0 ]; then
        echo "$prompt (non-interactive: defaulting to $default_answer)"
        case "$default_answer" in
            Y|y) return 0 ;;
            *) return 1 ;;
        esac
    fi

    while true; do
        if [ "$default_answer" = "Y" ]; then
            read -r -p "$prompt [Y/n] " reply
            reply="${reply:-Y}"
        else
            read -r -p "$prompt [y/N] " reply
            reply="${reply:-N}"
        fi

        case "$reply" in
            Y|y|yes|YES) return 0 ;;
            N|n|no|NO) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

prompt_conflict_action() {
    local path="$1"
    local reply

    if [ ! -t 0 ]; then
        echo "Conflict for $path [k/a/R] (non-interactive: defaulting to keep)" >&2
        echo "keep"
        return
    fi

    while true; do
        echo "Conflict for $path:" >&2
        echo "  [k] keep existing" >&2
        echo "  [a] append or merge dotfiles content into existing target" >&2
        echo "  [r] replace existing target with a symlink" >&2
        read -r -p "Choose [k/a/R] " reply
        reply="${reply:-r}"

        case "$reply" in
            k|K|keep|KEEP)
                echo "keep"
                return
                ;;
            a|A|append|APPEND)
                echo "append"
                return
                ;;
            r|R|replace|REPLACE)
                echo "replace"
                return
                ;;
            *)
                echo "Please choose k, a, or r." >&2
                ;;
        esac
    done
}

backup_target() {
    local source_path="$1"
    local name
    local backup_path

    name="$(basename "$source_path")"
    backup_path="$BACKUP_DIR/${name}.backup.$(date +"%Y%m%d_%H%M%S")"

    echo "Backing up $source_path to $backup_path"
    mv "$source_path" "$backup_path"
}

migrate_directory() {
    local old_path="$1"
    local new_path="$2"

    [ -d "$old_path" ] || return 0

    if [ -e "$new_path" ] || [ -L "$new_path" ]; then
        echo "Keeping legacy directory at $old_path because $new_path already exists" >&2
        return
    fi

    mkdir -p "$(dirname "$new_path")"
    echo "Migrating $old_path to $new_path"
    mv "$old_path" "$new_path"
}

migrate_file() {
    local old_path="$1"
    local new_path="$2"

    [ -f "$old_path" ] || return 0

    if [ -e "$new_path" ] || [ -L "$new_path" ]; then
        echo "Keeping legacy file at $old_path because $new_path already exists" >&2
        return
    fi

    mkdir -p "$(dirname "$new_path")"
    echo "Migrating $old_path to $new_path"
    mv "$old_path" "$new_path"
}

migrate_managed_layout() {
    local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
    local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"

    if [ -z "${DOTFILES_BACKUP_DIR:-}" ]; then
        migrate_directory "$HOME/dotfiles_backup" "$data_home/dotfiles/backups"
    fi

    migrate_directory "$state_home/shell-motd" "$state_home/dotfiles/shell-motd"
}

migrate_vim_layout() {
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
    local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"

    [ -f "$config_home/vim/vimrc" ] || return 0

    migrate_directory "$state_home/vim/undo" "$data_home/vim/undo"
    migrate_file "$HOME/.viminfo" "$state_home/vim/viminfo"
}

remove_managed_legacy_vim_links() {
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local name
    local legacy_path
    local managed_target

    [ -f "$config_home/vim/vimrc" ] || return 0

    for name in .vimrc .ezvimrc; do
        legacy_path="$HOME/$name"
        managed_target="$DOTFILES_DIR/$name"

        if [ -L "$legacy_path" ] && [ "$(readlink "$legacy_path")" = "$managed_target" ]; then
            echo "Removing managed legacy link $legacy_path"
            rm "$legacy_path"
        elif [ "$name" = ".vimrc" ] && [ -e "$legacy_path" ]; then
            echo "Warning: $legacy_path takes precedence over the XDG Vim config; keeping it unchanged" >&2
        fi
    done
}

append_source_into_existing() {
    local source_path="$1"
    local destination_path="$2"

    if [ -d "$source_path" ] && [ -d "$destination_path" ]; then
        echo "Merging $source_path into $destination_path"
        cp -a "$source_path"/. "$destination_path"/
        return 0
    fi

    if [ -f "$source_path" ] && [ -f "$destination_path" ]; then
        echo "Appending $source_path into $destination_path"
        if [ -s "$destination_path" ] && [ -s "$source_path" ]; then
            printf '\n' >> "$destination_path"
        fi
        cat "$source_path" >> "$destination_path"
        return 0
    fi

    echo "Cannot append $source_path into $destination_path because the types do not match"
    return 1
}

replace_with_symlink() {
    local source_path="$1"
    local destination_path="$2"
    local parent_dir

    backup_target "$destination_path"
    parent_dir="$(dirname "$destination_path")"
    mkdir -p "$parent_dir"
    echo "Creating symlink for $(basename "$destination_path")"
    ln -s "$source_path" "$destination_path"
}

ensure_repo() {
    mkdir -p "$BACKUP_DIR"

    if [ "$REPO_ROOT" = "$DOTFILES_DIR" ]; then
        echo "Using existing repository checkout at $DOTFILES_DIR"
        return
    fi

    if ! prompt_yes_no "Sync dotfiles repository into $DOTFILES_DIR?" "Y"; then
        echo "Skipping repository sync"
        return
    fi

    if [ -e "$DOTFILES_DIR" ]; then
        backup_target "$DOTFILES_DIR"
    fi

    echo "Cloning new dotfiles repository..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
}

ensure_symlink() {
    local file="$1"
    local target="$DOTFILES_DIR/$file"
    local home_path
    local parent_dir
    local action

    case "$file" in
        .config/*)
            home_path="${XDG_CONFIG_HOME:-$HOME/.config}/${file#.config/}"
            ;;
        *)
            home_path="$HOME/$file"
            ;;
    esac

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        echo "Skipping $file because $target does not exist in the dotfiles repo"
        return
    fi

    parent_dir="$(dirname "$home_path")"
    mkdir -p "$parent_dir"

    if [ -L "$home_path" ]; then
        if [ "$(readlink "$home_path")" = "$target" ]; then
            echo "Symlink already correct for $file"
            return
        fi
    elif [ -e "$home_path" ]; then
        :
    else
        echo "Creating symlink for $file"
        ln -s "$target" "$home_path"
        return
    fi

    while true; do
        action="$(prompt_conflict_action "$home_path")"

        case "$action" in
            keep)
                echo "Keeping existing target at $home_path"
                return
                ;;
            append)
                if append_source_into_existing "$target" "$home_path"; then
                    return
                fi
                ;;
            replace)
                replace_with_symlink "$target" "$home_path"
                return
                ;;
        esac
    done
}

maybe_link_group() {
    local prompt="$1"
    shift

    if prompt_yes_no "$prompt" "Y"; then
        local file
        for file in "$@"; do
            ensure_symlink "$file"
        done
    else
        echo "Skipping: $prompt"
    fi
}

install_neovim_packer() {
    local packer_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/packer/start/packer.nvim"

    if [ -d "$packer_dir" ]; then
        echo "packer.nvim is already installed"
        return
    fi

    echo "Installing packer.nvim..."
    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$packer_dir"
}

apt_package_available() {
    local package_name="$1"
    local candidate

    candidate="$(apt-cache policy "$package_name" 2>/dev/null | awk '/Candidate:/ { print $2; exit }')"
    [ -n "$candidate" ] && [ "$candidate" != "(none)" ]
}

install_apt_packages() {
    local package_name
    local available_packages=()
    local unavailable_packages=()

    for package_name in "$@"; do
        if apt_package_available "$package_name"; then
            available_packages+=("$package_name")
        else
            unavailable_packages+=("$package_name")
        fi
    done

    if [ "${#unavailable_packages[@]}" -gt 0 ]; then
        echo "Skipping unavailable apt packages: ${unavailable_packages[*]}"
    fi

    if [ "${#available_packages[@]}" -eq 0 ]; then
        echo "No requested apt packages are available from the configured apt repositories"
        return 0
    fi

    run_as_root apt-get install -y "${available_packages[@]}"
}

echo "Detected platform: $(platform_name)"
migrate_managed_layout
ensure_repo

maybe_link_group "Install bash symlinks (.bashrc, .bash.d)?" .bashrc .bash.d
maybe_link_group "Install zsh symlinks (.zshrc, .zsh.d)?" .zshrc .zsh.d
maybe_link_group "Install Vim config symlink (.config/vim)?" .config/vim
migrate_vim_layout
remove_managed_legacy_vim_links
maybe_link_group "Install shared config symlinks (.config/nvim, .config/fastfetch)?" .config/nvim .config/fastfetch
maybe_link_group "Install dotfiles profile symlink (.config/dotfiles/profile.sh)?" .config/dotfiles/profile.sh

if is_macos; then
    maybe_link_group "Install macOS Terminal profile config (.config/terminal)?" .config/terminal
else
    echo "Skipping macOS Terminal profile config on $(platform_name)"
fi

if is_macos; then
    # Apple Silicon macOS
    if ! command -v brew >/dev/null 2>&1; then
        if prompt_yes_no "Install Homebrew?" "N"; then
            echo "Homebrew not found, installing..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            echo "Skipping Homebrew installation"
        fi
    else
        echo "Homebrew is already installed"
    fi

    if command -v brew >/dev/null 2>&1; then
        if prompt_yes_no "Install/update Homebrew packages?" "N"; then
            brew install bash git fastfetch jq lua oniguruma z.lua zsh-autosuggestions zsh-syntax-highlighting tree tmux python3 coreutils fzf neovim
        else
            echo "Skipping Homebrew packages"
        fi
    fi

    if prompt_yes_no "Install Neovim packer.nvim plugin manager?" "N"; then
        install_neovim_packer
    else
        echo "Skipping packer.nvim installation"
    fi
    
    # Update PATH for Apple Silicon macOS
    export PATH="/opt/homebrew/bin:$PATH"

    if [ -f "$APPLESCRIPT_PATH" ]; then
        if prompt_yes_no "Import Terminal profiles with AppleScript?" "N"; then
            echo "Executing AppleScript to import Terminal profiles..."
            osascript "$APPLESCRIPT_PATH"
        else
            echo "Skipping Terminal profile import"
        fi
    else
        echo "AppleScript file not found: $APPLESCRIPT_PATH"
    fi
    
elif is_linux; then
    # Linux setup
    if ! command -v apt-get >/dev/null 2>&1; then
        echo "apt-get not found; skipping Linux package installation"
    elif prompt_yes_no "Run apt update?" "N"; then
        run_as_root apt-get update
    else
        echo "Skipping apt update"
    fi

    if command -v apt-get >/dev/null 2>&1 && prompt_yes_no "Install apt packages?" "N"; then
        install_apt_packages \
            bash \
            bash-completion \
            ca-certificates \
            curl \
            git \
            iproute2 \
            jq \
            lua5.4 \
            libonig5 \
            procps \
            zoxide \
            zsh-autosuggestions \
            zsh-syntax-highlighting \
            tree \
            tmux \
            python3 \
            fzf \
            neovim \
            vim
    else
        echo "Skipping apt package installation"
    fi

    if prompt_yes_no "Build/update Vim 9.2 with GTK4 and Wayland support?" "N"; then
        "$DOTFILES_DIR/Scripts/install_vim.sh"
    else
        echo "Skipping Vim 9.2 source build"
    fi
else
    echo "No installation available for system"
fi

echo "Dotfiles installation complete!"
