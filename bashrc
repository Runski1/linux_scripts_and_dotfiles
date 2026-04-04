# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# source the aliases
if [ -f $HOME/.bash_aliases ]; then
	. $HOME/.bash_aliases
fi

# Source the bash completion
[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion


export PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\007"'

use_color=true

#PS1 colors
if [ use_color ] ; then
	if [[ ${EUID} == 0 ]] ; then
		PS1='\[\033[01;31m\][\h\[\033[01;36m\] \W\[\033[01;31m\]]\$\[\033[00m\] '
	else
		PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '
	fi
fi

# Chesterton's fence here >>>>>
unset use_color safe_term match_lhs sh


# allow root to connect to xserver
xhost +local:root > /dev/null 2>&1

# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.  #65623
# http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)
shopt -s checkwinsize

shopt -s expand_aliases
# <<<<<< Chesterton's fence


# Enable history appending instead of overwriting.  #139609
shopt -s histappend
export EDITOR=nvim
export VISUAL=nvim
export TERMINAL=kitty
export PATH="$HOME/.cargo/bin:$PATH"
