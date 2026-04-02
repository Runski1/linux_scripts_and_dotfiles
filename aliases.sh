# echo "hello" | clip for CTRL+V pasting
alias clip='xclip -selection clipboard'

# LSD
alias lsd='\lsd --directory-only --oneline */' # Directories
alias ls='\lsd --oneline'                       # ls in column
alias lla='\lsd -la'                            # ls -la
alias la='\lsd -a'                              # ls -a
alias ll='\lsd -l'                              # ls -l

# make with all cores
alias make='make -j$(nproc)'

## IP addr
alias 'ip'='ip addr show | grep "scope global" | grep inet'

alias cp="cp -i"                          # confirm before overwriting something
alias df='df -h'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB

# Git
alias gitlog="git log --oneline --graph --decorate --all"

# I cant type
alias cd..='cd ..'

# Disk Usage
alias du='du -h --max-depth=1'

# Paste image from clipboard. Usage: imgpaste > my_image.png
alias imgpaste='xclip -selection clipboard -t image/png -o'
