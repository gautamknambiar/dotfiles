#!/usr/bin/env bash

set -e  # Exit on any error

# Define variables
DOTFILES_REPO="https://github.com/gautamknambiar/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/dotfiles_backup"
APPLESCRIPT_PATH="$DOTFILES_DIR/Scripts/terminal.applescript"

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Clone the dotfiles repository
if [ -d "$DOTFILES_DIR" ]; then
    # Move the existing directory to the backup location
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_PATH="$BACKUP_DIR/dotfiles_$TIMESTAMP"
    
    echo "Backing up existing dotfiles directory to $BACKUP_PATH"
    mv "$DOTFILES_DIR" "$BACKUP_PATH"
fi

# Clone the new dotfiles repository
echo "Cloning new dotfiles repository..."
git clone "$DOTFILES_REPO" "$DOTFILES_DIR"

# Define list of dotfiles to symlink
DOTFILES=(.zshrc .bashrc .bash.d .zsh.d .config)

# Loop through the array and create or replace symlinks
for file in "${DOTFILES[@]}"; do
    # Check if the file is a symlink and points to a different target
    if [ -L "$HOME/$file" ]; then
        if [ "$(readlink "$HOME/$file")" != "$DOTFILES_DIR/$file" ]; then
            echo "Removing incorrect symlink $file"
            rm "$HOME/$file"
        fi
    elif [ -e "$HOME/$file" ]; then
        # File exists but is not a symlink, so back it up
        echo "Backing up existing file or directory $file to $BACKUP_DIR/${file}.backup"
        mv "$HOME/$file" "$BACKUP_DIR/${file}.backup"
    fi

    # Create the symlink
    echo "Creating symlink for $file"
    ln -s "$DOTFILES_DIR/$file" "$HOME/$file"
done

echo "Dotfiles installation complete!"


if [ "$(uname)" == "Darwin" ]; then
    # Apple Silicon macOS
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found, installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Homebrew is already installed"
    fi
    brew install bash git fastfetch jq lua oniguruma z.lua zsh-autosuggestions zsh-syntax-highlighting tree tmux python3 coreutils fzf neovim

    git clone --depth 1 https://github.com/wbthomason/packer.nvim\
    ~/.local/share/nvim/site/pack/packer/start/packer.nvim
    
    # Update PATH for Apple Silicon macOS
    export PATH="/opt/homebrew/bin:$PATH"

    if [ -f "$APPLESCRIPT_PATH" ]; then
        echo "Executing AppleScript to import Terminal profiles..."
        osascript "$APPLESCRIPT_PATH"
    else
        echo "AppleScript file not found: $APPLESCRIPT_PATH"
    fi
    
elif [ "$(uname)" == "Linux" ]; then
    # Linux setup
    sudo apt-get update
    sudo apt-get install -y bash git fastfetch jq lua oniguruma z.lua zsh-autosuggestions zsh-syntax-highlighting tree tmux python3 fzf neovim
else
    echo "No installation available for system"
fi

echo "Dotfiles installation complete!"
