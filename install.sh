#!/usr/bin/env bash

# Check if script is run in correct directory - relative paths are used
if [[ ! -f "kitty/kitty.conf" || ! -f "i3/i3_config" || ! -f "neovim/init.lua" ]]; then
    echo "Error: Run this script from the directory containing the config files."
    exit 1
fi
# neovim on apt based distos is installed from prebuilt binary (thanks, apt)
if [[ $(uname -m) != "x86_64" ]]; then
	echo "Error: This script can only be run on x86_64 architecture."
	exit 1
fi

set -e

# ---------- helpers ----------
# is packet installed
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_with_pm() {
    PM="$1"
    shift
    PKGS=("$@")

    case "$PM" in
        pacman)
            sudo pacman -Suy --needed --noconfirm "${PKGS[@]}"
            ;;
        apt)
            sudo apt update
            sudo apt install -y "${PKGS[@]}"
            ;;
        dnf)
            sudo dnf group install "C Development Tools and Libraries" "Development Tools"
            sudo dnf install -y "${PKGS[@]}"
            ;;
    esac
}


# general packets
PKGS=(curl i3 wget python3 ripgrep tmux cmake clang git lsd bat kitty)


# packet manager specific stuff
if command -v pacman >/dev/null 2>&1; then
    PM="pacman"
    PKGS+=("base-devel" "ninja" "neovim")
elif command -v apt >/dev/null 2>&1; then
    PM="apt"
    PKGS+=("build-essential" "ninja-build" "gettext")
elif command -v dnf >/dev/null 2>&1; then
    PM="dnf"
    sudo dnf group install "C Development Tools and Libraries" "Development Tools"
    PKGS+=("ninja-build" "gcc" "make" "gettext" "glibc-gconv-extra" "neovim" "python3-neovim")
else
    echo "Unsupported package manager"
    exit 1
fi
echo "Packet manager detected: $PM"

# ---------- install tools ----------
TO_INSTALL=()

for pkg in "${PKGS[@]}"; do
    if ! command_exists "$pkg"; then
        TO_INSTALL+=("$pkg")
    else
        echo "Package already exist: $pkg"
    fi
done

if [ ${#TO_INSTALL[@]} -ne 0 ]; then
    echo "Installing: ${TO_INSTALL[*]}"
    install_with_pm "$PM" "${TO_INSTALL[@]}"
else
    echo "Base tools already installed"
fi

# ---------- Rust, cargo packages ----------
if ! command_exists rustc; then
    echo "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source "$HOME/.cargo/env"
else
    echo "Rust already installed"
fi

# We need tree-sitter-cli for treesitter plugin
if ! command_exists tree-sitter; then
    echo "Installing tree-sitter-cli"
    cargo install --locked tree-sitter-cli
else
    echo "tree-sitter-cli already installed"
fi

# apt neovim is outdated, we install the binary from github
if ! command_exists nvim; then
    echo "Installing neovim..."
    case "$PM" in
        pacman)
            echo "Neovim should already be installed!"
            exit 1
            ;;
        apt)
	    nvim="nvim-linux-x86_64"
        curl -LO "https://github.com/neovim/neovim/releases/download/stable/$nvim.tar.gz"
	    sudo rm -rf "/opt/$nvim"
	    sudo tar -C /opt -xvf "$nvim.tar.gz"
        rm -rf "$nvim.tar.gz"
	    echo "export PATH=\"$PATH:/opt/$nvim/bin\"" >> $HOME/.bashrc
            ;;
        dnf)
            echo "Neovim should already be installed!"
            exit 1
            ;;
    esac
fi


    # LSD install: fallback to cargo if not installed yet
    if ! command_exists lsd; then
        echo "Installing lsd via cargo..."
        if ! command_exists cargo; then
            echo "Cargo not found, reloading Rust env..."
            source "$HOME/.cargo/env"
        fi
        cargo install lsd
    else
        echo "lsd already installed"
    fi

# config directories
echo "Making config directories"
for dir in kitty i3 tmux nvim/lua/custom/plugins nvim/lua/kickstart/plugins; do
    path="$HOME/.config/$dir"
    if mkdir -p "$path"; then
        echo "OK: $path"
    else
        echo "FAIL: $path"
    fi
done

# symlinking config files to ~/.config/ 
echo "Creating symlinks..."
sourcedir="$(pwd)"
ln -sf $sourcedir/kitty/kitty.conf $HOME/.config/kitty/kitty.conf
ln -sf $sourcedir/i3/i3_config $HOME/.config/i3/config
ln -sf $sourcedir/tmux/tmux.conf $HOME/.config/tmux/tmux.conf
ln -sf $sourcedir/neovim/init.lua $HOME/.config/nvim/init.lua
ln -sf $sourcedir/neovim/lua/custom/plugins/init.lua $HOME/.config/nvim/lua/custom/plugins/init.lua
ln -sf $sourcedir/neovim/lua/kickstart/health.lua $HOME/.config/nvim/lua/kickstart/health.lua
ln -sf $sourcedir/neovim/lua/kickstart/plugins/debug.lua $HOME/.config/nvim/lua/kickstart/plugins/debug.lua
ln -sf $sourcedir/neovim/lua/kickstart/plugins/gitsigns.lua $HOME/.config/nvim/lua/kickstart/plugins/gitsigns.lua
ln -sf $sourcedir/neovim/lua/kickstart/plugins/indent_line.lua $HOME/.config/nvim/lua/kickstart/plugins/indent_line.lua
ln -sf $sourcedir/neovim/lua/kickstart/plugins/lint.lua $HOME/.config/nvim/lua/kickstart/plugins/lint.lua
ln -sf $sourcedir/neovim/lua/kickstart/plugins/neo-tree.lua $HOME/.config/nvim/lua/kickstart/plugins/neo-tree.lua
ln -sf $sourcedir/bashrc $HOME/.bashrc


# Nerd font
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/0xProto.tar.xz
tar -xvf 0xProto.tar.xz -C "$FONT_DIR"
rm -rf 0xProto.tar.xz


# aliases to .bash_aliases
cat ./aliases.sh > $HOME/.bash_aliases
#
# update path
source ~/.bashrc

# for future idiot me
echo "Installation done."
echo "If you get errors regarding treesitter, try running :Lazy sync, update etc..."
echo "source ~/.bashrc to update \$PATH"


