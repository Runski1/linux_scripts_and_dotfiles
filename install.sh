#!/usr/bin/env bash
set -e
LOG="$(pwd)/install.log"
exec > >(tee -a "$LOG") 2>&1

info() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

# Check if script is run in correct directory - relative paths are used
if [[ ! -f "install.sh" ]]; then
    error "Error: Run this script from the directory containing the config files."
    exit 1
fi
# neovim on apt based distos is installed from prebuilt binary (thanks, apt)
if [[ $(uname -m) != "x86_64" ]]; then
	error "Error: This script can only be run on x86_64 architecture."
	exit 1
fi

set -e

# ---------- helpers ----------
# is packet installed
command_exists_any() {
    for cmd in $1; do
        if command -v "$cmd" >/dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

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
declare -A PKG_COMMANDS=(
    [curl]="curl"
    [wget]="wget"
    [git]="git"
    [ninja-build]="ninja"
    [build-essential]="gcc make"
    [cmake]="cmake"
    [ripgrep]="rg"
    [bat]="bat batcat"
    [tmux]="tmux"
    [btop]="btop"
    [kitty]="kitty"
    [python3]="python python3"
    [lsd]="lsd"
)

# general packets
PKGS=(btop kitty curl wget python3 ripgrep tmux cmake clang git lsd bat)
if [[ $XDG_SESSION_TYPE == "x11" ]]; then
    PKG_COMMANDS[i3]="i3"
else
    warn "Warning: XDG_SESSION_TYPE = {$XDG_SESSION_TYPE}, skipping i3 install"
fi


# packet manager specific stuff
if command -v pacman >/dev/null 2>&1; then
    PM="pacman"
    PKGS+=("base-devel" "ninja" "neovim")
elif command -v apt >/dev/null 2>&1; then
    PM="apt"
    PKGS+=("build-essential" "ninja-build" "gettext")
elif command -v dnf >/dev/null 2>&1; then
    PM="dnf"
    sudo dnf group install "c-development" "development-tools"
    PKGS+=("ninja-build" "gcc" "make" "gettext" "glibc-gconv-extra" "neovim" "python3-neovim")
else
    error "Unsupported package manager"
    exit 1
fi
info "Packet manager detected: $PM"

# ---------- install tools ----------
TO_INSTALL=()
for pkg in "${PKGS[@]}"; do
    cmds="${PKG_COMMANDS[$pkg]:-$pkg}"  # fallback to package name
    if ! command_exists_any "$cmds"; then
        TO_INSTALL+=("$pkg")
    else
        info "Package already exists: $pkg"
    fi
done

if [ ${#TO_INSTALL[@]} -ne 0 ]; then
    info "Installing: ${TO_INSTALL[*]}"
    install_with_pm "$PM" "${TO_INSTALL[@]}"
else
    info "Basic tools already installed"
fi

# ---------- Rust, cargo packages ----------
if ! command_exists rustc; then
    info "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    export PATH="$HOME/.cargo/bin:$PATH"
    echo "export PATH=\"\$HOME/.cargo/bin:\$PATH\"" >> ~/.bashrc
else
    info "Rust already installed"
fi

# We need tree-sitter-cli for treesitter plugin
if ! command_exists tree-sitter; then
    info "Installing tree-sitter-cli"
    cargo install --locked tree-sitter-cli
else
    info "tree-sitter-cli already installed"
fi

# apt neovim is outdated, we install the binary from github
if ! command_exists nvim; then
    info "Installing neovim..."
    case "$PM" in
        pacman)
            error "Neovim should already be installed!"
            exit 1
            ;;
        apt)
	    nvim="nvim-linux-x86_64"
        curl -LO "https://github.com/neovim/neovim/releases/download/stable/$nvim.tar.gz"
	    sudo rm -rf "/opt/$nvim"
	    sudo tar -C /opt -xvf "$nvim.tar.gz"
        rm -rf "$nvim.tar.gz"
        sudo ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/bin/nvim
            ;;
        dnf)
            error "Neovim should already be installed!"
            exit 1
            ;;
    esac
fi


    # LSD install: fallback to cargo if not installed yet
    if ! command_exists lsd; then
        info "Installing lsd via cargo..."
        if ! command_exists cargo; then
            warn "Cargo not found, reloading Rust env..."
            source "$HOME/.cargo/env"
        fi
        cargo install lsd
    else
        info "lsd already installed"
    fi

# config directories
info "Making config directories"
for dir in kitty i3 tmux nvim/lua/custom/plugins nvim/lua/kickstart/plugins; do
    path="$HOME/.config/$dir"
    if mkdir -p "$path"; then
        info "Created: $path"
    else
        error "Path creation failed: $path"
        exit 1
    fi
done


info "Creating config file symlinks..."

sourcedir="$(pwd)"
# Define symlinks: key=source relative to $sourcedir, value=destination
declare -A SYMLINKS=(
    ["kitty/kitty.conf"]="$HOME/.config/kitty/kitty.conf"
    ["kitty/catppuccin-mocha.conf"]="$HOME/.config/kitty/catppuccin-mocha.conf"
    ["tmux/tmux.conf"]="$HOME/.config/tmux/tmux.conf"
    ["neovim/init.lua"]="$HOME/.config/nvim/init.lua"
    ["neovim/lua/custom/plugins/init.lua"]="$HOME/.config/nvim/lua/custom/plugins/init.lua"
    ["neovim/lua/kickstart/health.lua"]="$HOME/.config/nvim/lua/kickstart/health.lua"
    ["neovim/lua/kickstart/plugins/debug.lua"]="$HOME/.config/nvim/lua/kickstart/plugins/debug.lua"
    ["neovim/lua/kickstart/plugins/gitsigns.lua"]="$HOME/.config/nvim/lua/kickstart/plugins/gitsigns.lua"
    ["neovim/lua/kickstart/plugins/indent_line.lua"]="$HOME/.config/nvim/lua/kickstart/plugins/indent_line.lua"
    ["neovim/lua/kickstart/plugins/lint.lua"]="$HOME/.config/nvim/lua/kickstart/plugins/lint.lua"
    ["neovim/lua/kickstart/plugins/neo-tree.lua"]="$HOME/.config/nvim/lua/kickstart/plugins/neo-tree.lua"
    ["bashrc"]="$HOME/.bashrc"
)

if [ "$XDG_SESSION_TYPE" = "x11" ]; then
    SYMLINKS["i3/i3_config"]="$HOME/.config/i3/config"
fi

# Loop through and create symlinks
for src in "${!SYMLINKS[@]}"; do
    dest="${SYMLINKS[$src]}"
    mkdir -p "$(dirname "$dest")"  # ensure parent directory exists
    ln -sf "$sourcedir/$src" "$dest"
    info "$sourcedir/$src → $dest"
done

# Nerd font
FONT_DIR="$HOME/.local/share/fonts"
if ! find "$FONT_DIR" -type f -iname "*nerd*font*" | grep -q .; then
    info "Installing 0xProto Nerd font to $FONT_DIR"
    mkdir -p "$FONT_DIR"
    curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/0xProto.tar.xz
    tar -xvf 0xProto.tar.xz -C "$FONT_DIR"
    rm -rf 0xProto.tar.xz
fi

# aliases to .bash_aliases
TARGET="$HOME/.bash_aliases"
SOURCE="./aliases.sh"

info "Adding aliases to $TARGET"

# Make sure the target file exists
touch "$TARGET"

while IFS= read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue
    # Skip lines that already exist
    if ! grep -Fxq "$line" "$TARGET"; then
        echo "$line" >> "$TARGET"
    fi
done < "$SOURCE"

if command_exists "batcat" && ! command_exists "bat"; then
    info "Symlinking batcat to /usr/local/bin/bat"
    sudo ln -s "$(command -v batcat)" /usr/local/bin/bat
fi

# update path
source ~/.bashrc

# for future idiot me
info "\nInstallation done.\n
If you get errors regarding treesitter, try running :Lazy sync and update.
Old kitty versions don't support in and out cursor, fix line 2627 if needed.
remember to source bashrc!"
