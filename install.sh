#!/usr/bin/env bash

if [[ ! -f "./kitty.conf" || ! -f "./i3_config" || ! -f "./init.lua" ]]; then
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
            sudo pacman -Suy --needed --noconfirm "${PKGS[@]}"
            ;;
        apt)
            sudo apt update
            sudo apt install -y "${PKGS[@]}"
            ;;
        dnf)
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

# ---------- install base tools ----------
TO_INSTALL=()

command_exists curl || TO_INSTALL+=("$CURL")
command_exists wget || TO_INSTALL+=("$WGET")
command_exists python3 || TO_INSTALL+=("$PYTHON")
command_exists rg || TO_INSTALL+=("$RIPGREP")
command_exists i3 || TO_INSTALL+=("$I3")

if [ ${#TO_INSTALL[@]} -ne 0 ]; then
    echo "Installing: ${TO_INSTALL[*]}"
    install_with_pm "$PM" "${TO_INSTALL[@]}"
else
    echo "Base tools already installed"
fi

# ---------- install Rust ----------
if ! command_exists rustc; then
    echo "Installing Rust via rustup..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust already installed"
fi

if ! command_exists nvim; then
    echo "Installing neovim..."
    command_exists nvim || TO_INSTALL+=("$NEOVIM")
    case "$PM" in
        pacman)
            sudo pacman -S --noconfirm neovim
            ;;
        apt)
	    image="nvim-linux-x86_64.appimage"
            curl -LO "https://github.com/neovim/neovim/releases/download/stable/$image"
            chmod u+x "$image"
            sudo mv "$image" /usr/local/bin/nvim
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

for dir in kitty i3 nvim; do
    path="$HOME/.config/$dir"
    if mkdir -p "$path"; then
        echo "OK: $path"
    else
        echo "FAIL: $path"
    fi
done

echo "Creating symlinks..."
sourcedir="$(pwd)"
ln -sf $sourcedir/kitty.conf $HOME/.config/kitty/kitty.conf
ln -sf $sourcedir/i3_config $HOME/.config/i3/config
ln -sf $sourcedir/init.lua $HOME/.config/nvim/init.lua
echo "All done!"

