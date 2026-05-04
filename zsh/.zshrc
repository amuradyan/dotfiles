USER=$(whoami)

bindkey "^[[5~" history-incremental-search-backward  # Page Up
bindkey "^[[6~" history-incremental-search-forward   # Page Down

# Prefix history search: type a prefix, then Up/Down walks matching history.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Bind both raw escape sequences AND application-mode sequences so it works
# in URxvt regardless of cursor-key mode (tmux/some apps flip between them).
bindkey "^[[A" up-line-or-beginning-search       # Up   (normal mode)
bindkey "^[[B" down-line-or-beginning-search     # Down (normal mode)
bindkey "^[OA" up-line-or-beginning-search       # Up   (application mode)
bindkey "^[OB" down-line-or-beginning-search     # Down (application mode)
# The following lines were added by compinstall
zstyle ':completion:*' completer _complete _ignored _approximate
zstyle :compinstall filename "/home/$USER/.zshrc"
autoload -Uz compinit
compinit
# End of lines added by compinstall
# Coloring and transparency setings

# Base16 Shell
BASE16_SHELL="$HOME/.config/base16-shell/"
[ -n "$PS1" ] && [ -s "$BASE16_SHELL/profile_helper.sh" ] && source "$BASE16_SHELL/profile_helper.sh"

# misc
alias ll='ls -al'
alias llh='ll -h'
alias lS='ls -1FSsh'
alias ...='../..'
alias mkdirp='mkdir -p'

# Pyhton
alias py='python'

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
alias muxv='mux start v ~'
alias muxvh='mux start vh ~'
alias muxhv='mux start hv ~'
alias muxhvh='mux start hvh ~'
alias txks='tmux kill-server'
alias txls='tmux ls'
alias rgr='ranger'

# scala3
alias scala3='~/devel/scala3/bin/scala'
alias scalac3='~/devel/scala3/bin/scalac'
alias scaladoc3='~/devel/scala3/bin/scaladoc'


# mc
alias mcn='mc --nocolor'
export MC_XDG_OPEN=feh

start_tmux() {
  local DEFAULT_LAYOUT="v"
  local DEFAULT_PATH=$(pwd)
  local DEFAULT_NAME="Default"
}


# [ -n "$XTERM_VERSION" ] && transset-df -a >/dev/null

autoload -U colors && colors

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=50000
SAVEHIST=50000

setopt HIST_IGNORE_DUPS         # don't store consecutive duplicates
setopt HIST_IGNORE_SPACE        # commands starting with a space are not saved
setopt HIST_REDUCE_BLANKS       # tidy whitespace before saving
setopt SHARE_HISTORY            # share history live across open shells
setopt EXTENDED_HISTORY         # record timestamp + duration per entry
# End of lines configured by zsh-newuser-install

setopt autocd extendedglob
unsetopt beep

source ~/.git-prompt.sh
RPROMPT="[%{$fg_no_bold[yellow]%}%?%{$reset_color%}]"
setopt PROMPT_SUBST
export GIT_PS1_SHOWSTASHSTATE="yes"
export GIT_PS1_DESCRIBE_STYLE="contains"
PS1='%{$fg_no_bold[green]%}%6~%{$fg_bold[yellow]%} $(__git_ps1 "(%s) ")%{$reset_color%}
ƒ ' >>~/.zshrc
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# enables cowsay and fortune.
# if [ -x /usr/games/cowsay -a -x /usr/games/fortune ]; then
fortune | cowsay -r | lolcat
# fi

export EDITOR=hx
# export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}'):0.0

export RANGER_LOAD_DEFAULT_RC=FALSE

plugins=(git colored-man-pages colorize)

export PATH="/home/spectrum/.config/custom_scripts/:$PATH"
