# The following lines were added by compinstall

zstyle ':completion:*' completer _complete _ignored _approximate
zstyle :compinstall filename '/home/spectrum/.zshrc'

# misc
alias ll='ls -al'
alias lS='ls -1FSsh'
alias ...='../..'

# Pyhton
alias ipy='/usr/bin/ipython3'
alias py='/usr/bin/python3.7'

# git
alias gs='git status'
alias gss='git status -s'
alias gc='git commit'
alias gl='git log'
alias glo='git log --pretty=oneline'
alias gmt='git mergetool'
alias gp='git push'
alias mux="tmuxinator"
alias rmorig='find . -name '"'"'*.orig'"'"' -delete'

# mux/tmux
alias tmux='stty stop "" -ixoff; tmux'
alias muxv='mux start v'
alias muxvh='mux start vh'
alias muxhv='mux start hv'
alias muxhvh='mux start hvh'

start_tmux() {
  local DEFAULT_LAYOUT="v"
  local DEFAULT_PATH=$(pwd)
  local DEFAULT_NAME="Default"
}

# ranger
alias rgr='~/devel/ranger/ranger.py'

autoload -Uz compinit
compinit
# End of lines added by compinstall
# Coloring and transparency setings

[ -n "$XTERM_VERSION" ] && transset-df -a >/dev/null

autoload -U colors && colors

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# End of lines configured by zsh-newuser-install

setopt autocd extendedglob
unsetopt beep

source ~/.git-prompt.sh
RPROMPT="[%{$fg_no_bold[yellow]%}%?%{$reset_color%}]"
setopt PROMPT_SUBST
export GIT_PS1_SHOWSTASHSTATE="yes"
PS1='%{$fg_no_bold[green]%}%6~%{$fg_bold[yellow]%} $(__git_ps1 "(%s) ")%{$reset_color%}
> ' >>~/.zshrc
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# enables cowsay and fortune.
if [ -x /usr/games/cowsay -a -x /usr/games/fortune ]; then
  fortune | cowsay -f $(ls /usr/share/cowsay/cows/ | shuf -n1)
fi

export EDITOR=vim
export DISPLAY=localhost:0.0

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/spectrum/.sdkman"
[[ -s "/home/spectrum/.sdkman/bin/sdkman-init.sh" ]] && source "/home/spectrum/.sdkman/bin/sdkman-init.sh"

SPARK_HOME="/home/spectrum/devel/spark-2.3.3-bin-hadoop2.7/"
export PATH=$SPARK_HOME/bin:$PATH


clear

