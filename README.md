# Linux Scripts and Dotfiles
Dotfiles, installation scripts and QoL scripts for new linux setup.
I'm expanding this as I see need for more stuff.

## install.sh
Installation script installs software packages and symlinks the included 
dotfiles to `$USER/.config`. *The script should be run in the same directory.*

### Installed packages
* i3
* kitty
* tmux
* Neovim
* python
* rust
* Curl
* wget
* ripgrep
* lsd

## dotfiles
Dotfiles are symlinked to `$USER/.config`. Neovim config used kickstart.nvim as 
a base, and has some additions made to it. i3 and kitty configurations are light, 
only some keybind stuff

# Todo:
aliases
Fix treesitter problems - include the plugin configurations to repo?
