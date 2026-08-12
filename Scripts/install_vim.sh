#!/usr/bin/env bash

set -euo pipefail

VIM_REPOSITORY="${VIM_REPOSITORY:-https://github.com/vim/vim.git}"
VIM_DEFAULT_SOURCE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/vim/source"
VIM_SOURCE_DIR="${VIM_SOURCE_DIR:-$VIM_DEFAULT_SOURCE_DIR}"
VIM_INSTALL_PREFIX="${VIM_INSTALL_PREFIX:-$HOME/.local/opt/vim-9.2}"
# Full upstream tests are intentionally opt-in: VIM_RUN_TESTS=1.
VIM_RUN_TESTS="${VIM_RUN_TESTS:-0}"
VIM_BUILD_JOBS="${VIM_BUILD_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "Cannot install Vim build dependencies: sudo is unavailable" >&2
        return 1
    fi
}

if [ "$(uname -s)" != "Linux" ]; then
    echo "This installer currently supports Linux only." >&2
    exit 1
fi

if command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get install -y \
        build-essential \
        git \
        libtool-bin \
        libncurses-dev \
        libwayland-dev \
        libgtk-4-dev \
        libpython3-dev
fi

if [ "$VIM_SOURCE_DIR" = "$VIM_DEFAULT_SOURCE_DIR" ] &&
        [ -d "$HOME/.cache/dotfiles-vim-src" ] &&
        [ ! -e "$VIM_SOURCE_DIR" ]; then
    mkdir -p "$(dirname "$VIM_SOURCE_DIR")"
    echo "Migrating Vim source cache to $VIM_SOURCE_DIR"
    mv "$HOME/.cache/dotfiles-vim-src" "$VIM_SOURCE_DIR"
fi

mkdir -p "$(dirname "$VIM_SOURCE_DIR")" "$(dirname "$VIM_INSTALL_PREFIX")"

if [ -d "$VIM_SOURCE_DIR/.git" ]; then
    echo "Updating Vim source in $VIM_SOURCE_DIR"
    git -C "$VIM_SOURCE_DIR" pull --ff-only
elif [ -e "$VIM_SOURCE_DIR" ]; then
    echo "Cannot clone Vim: $VIM_SOURCE_DIR exists and is not a Git checkout" >&2
    exit 1
else
    echo "Cloning Vim into $VIM_SOURCE_DIR"
    git clone "$VIM_REPOSITORY" "$VIM_SOURCE_DIR"
fi

cd "$VIM_SOURCE_DIR"

if [ -f src/auto/config.mk ]; then
    make distclean
fi

./configure \
    --prefix="$VIM_INSTALL_PREFIX" \
    --with-features=huge \
    --enable-gui=gtk4 \
    --with-wayland \
    --enable-python3interp=yes \
    --enable-terminal \
    --enable-multibyte \
    --enable-fail-if-missing

make -j"$VIM_BUILD_JOBS"

if [ "$VIM_RUN_TESTS" != "0" ]; then
    make test
fi

make install

"$VIM_INSTALL_PREFIX/bin/vim" --version | sed -n '1,6p'
echo "Installed Vim in $VIM_INSTALL_PREFIX"
