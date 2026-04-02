#!/usr/bin/env bash

if [[ ! -f "kitty/kitty.conf" || ! -f "i3/i3_config" || ! -f "neovim/init.lua" ]]; then
    echo "Error: Run this script from the directory containing the config files."
    exit 1
fi
if [[ $(uname -m) != "x86_64" ]]; then
	echo "Error: This script can only be run on x86_64 architecture."
	exit 1
fi

set -e

# ---------- helpers ----------
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_with_pm() {
    PM="$1"
    shift
    PKGS=("$@")

    case "$PM" in
        pacman)
            sudo pacman -Suy --needed --noconfirm "${PKGS[@]}" base-devel
            ;;
        apt)
            sudo apt update
            sudo apt install -y "${PKGS[@]}" build-essential
            ;;
        dnf)
            sudo dnf group install "C Development Tools and Libraries" "Development Tools"
            sudo dnf install -y "${PKGS[@]}"
            ;;
    esac
}

# ---------- detect package manager ----------
if command_exists pacman; then
    PM="pacman"
elif command_exists apt; then
    PM="apt"
elif command_exists dnf; then
    PM="dnf"
else
    echo "Unsupported package manager"
    exit 1
fi

echo "Using package manager: $PM"

# ---------- package mapping ----------
CURL="curl"
I3="i3"
WGET="wget"
PYTHON="python3"
RIPGREP="ripgrep"
TMUX="tmux"
CMAKE="cmake"
CLANG="clang"

# ---------- install base tools ----------
TO_INSTALL=()

command_exists curl || TO_INSTALL+=("$CURL")
command_exists wget || TO_INSTALL+=("$WGET")
command_exists python3 || TO_INSTALL+=("$PYTHON")
command_exists rg || TO_INSTALL+=("$RIPGREP")
command_exists i3 || TO_INSTALL+=("$I3")
command_exists tmux || TO_INSTALL+=("$TMUX")
command_exists cmake || TO_INSTALL+=("$CMAKE")
command_exists clang || TO_INSTALL+=("$CLANG")

if [ ${#TO_INSTALL[@]} -ne 0 ]; then
    echo "Installing: ${TO_INSTALL[*]}"
    install_with_pm "$PM" "${TO_INSTALL[@]}"
else
    echo "Base tools already installed"
fi
# ---------- C toolchain -----------

case "$PM" in
    pacman)
        sudo pacman -S base-devel
        ;;
    apt)
        sudo apt install build-essential
        ;;
    dnf)
        sudo dnf group install "C Development Tools and Libraries" "Development Tools"
        ;;
esac


# ---------- install Rust ----------
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

if ! command_exists nvim; then
    echo "Installing neovim..."
    case "$PM" in
        pacman)
            sudo pacman -S --noconfirm neovim
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
            sudo dnf install neovim
            ;;
    esac
fi


# ---------- install LSD ----------
if ! command_exists lsd; then
    echo "Installing lsd..."

    case "$PM" in
        pacman)
            sudo pacman -Sy --needed --noconfirm lsd || true
            ;;
        apt)
            sudo apt install -y lsd || true
            ;;
        dnf)
            sudo dnf install -y lsd || true
            ;;
    esac

    # fallback to cargo if not installed
    if ! command_exists lsd; then
        echo "Installing lsd via cargo..."
        if ! command_exists cargo; then
            echo "Cargo not found, reloading Rust env..."
            source "$HOME/.cargo/env"
        fi
        cargo install lsd
    fi
else
    echo "lsd already installed"
fi

echo "Making config directories"

for dir in kitty i3 nvim/lua/custom/plugins nvim/lua/kickstart/plugins; do
    path="$HOME/.config/$dir"
    if mkdir -p "$path"; then
        echo "OK: $path"
    else
        echo "FAIL: $path"
    fi
done

echo "Creating symlinks..."
sourcedir="$(pwd)"
ln -sf $sourcedir/kitty/kitty.conf $HOME/.config/kitty/kitty.conf
ln -sf $sourcedir/i3/i3_config $HOME/.config/i3/config
ln -sf $sourcedir/neovim/init.lua $HOME/.config/nvim/init.lua
ln -sf $sourcedir/neovim/lua/custom/plugins/init.lua $HOME/.config/nvim/lua/custom/plugins/init.lua
ln -sf $sourcedir/neovim/lua/kickstart/plugins/debug.lua $HOME/.config/nvim/lua/kickstart/plugins/debug.lua
ln -sf $sourcedir/neovim/lua/kickstart/health.lua $HOME/.config/nvim/lua/kickstart/health.lua
ln -sf $sourcedir/neovim/lua/kickstart/plugins/debug.lua $HOME/.config/nvim/lua/kickstart/plugins/debug.lua
ln -sf $sourcedir/neovim/lua/kickstart/plugins/gitsigns.lua $HOME/.config/nvim/lua/kickstart/plugins/gitsigns.lua
ln -sf $sourcedir/neovim/lua/kickstart/plugins/indent_line.lua $HOME/.config/nvim/lua/kickstart/plugins/indent_line.lua
ln -sf $sourcedir/neovim/lua/kickstart/plugins/lint.lua $HOME/.config/nvim/lua/kickstart/plugins/lint.lua
ln -sf $sourcedir/neovim/lua/kickstart/plugins/neo-tree.lua $HOME/.config/nvim/lua/kickstart/plugins/neo-tree.lua
source ~/.bashrc
echo "All done!"
echo "If you get errors regarding treesitter, try running :Lazy sync, update etc..."
echo "source ~/.bashrc to update \$PATH"


