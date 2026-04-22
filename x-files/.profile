# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

amixer -D pulse set Master 50%

TOUCHPAD_ID=`xinput | grep "Touchpad" | awk '{ print $6 }' | cut -d'=' -f2`

NATURAL_SCROLLING_ENABLED=`xinput list-props $TOUCHPAD_ID | grep "libinput Natural Scrolling Enabled" | grep -v "Default" | awk '{ print $5 }' | cut -d'(' -f2 | cut -d')' -f1`
NATURAL_SCROLLING_ENABLED_DEFAULT=`xinput list-props $TOUCHPAD_ID | grep "libinput Natural Scrolling Enabled Default" | awk '{ print $6 }' | cut -d'(' -f2 | cut -d')' -f1`

sxhkd &

setxkbmap -option caps:escape

xinput set-prop $TOUCHPAD_ID $NATURAL_SCROLLING_ENABLED 1
xinput set-prop $TOUCHPAD_ID $NATURAL_SCROLLING_ENABLED_DEFAULT 1

xrandr --output eDP-1 --scale 0.5

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists2
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

./.fehbg

export SHELL=`which zsh`

export PATH="$PATH:/home/spectrum/devel/dotfiles/custom_scripts/"

export PATH="$PATH:~/.config/polybar/"

