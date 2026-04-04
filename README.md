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

Some dependencies and C toolchain packages are also installed.
My setup also uses nerdfont - a set of those are installed to `$HOME/.local/share/fonts`

## dotfiles
Dotfiles are symlinked to `$USER/.config`. Neovim config used kickstart.nvim as 
a base, and has some additions made to it. i3 and kitty configurations are light, 
only some keybind stuff.

`.bashrc` and `.bash_aliases` are symlinked to `$HOME`

In case of treesitter errors when opening neovim, try running :Lazy sync, update etc.

## TODO
The script has been tested only on an apt based system thus far.
Need to test on pacman and dnf too.
add all packages to readme

# Notice
THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
