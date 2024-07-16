# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

amixer -D pulse set Master 50%

TOUCHPAD_ID=`xinput | grep "Touchpad" | awk '{ print $5 }' | cut -d'=' -f2`

xinput set-prop $TOUCHPAD_ID 325 1
xinput set-prop $TOUCHPAD_ID 333 1

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

export SHELL=/bin/zsh


# >>> JVM installed by coursier >>>
export JAVA_HOME="/home/universe.dart.spb/amuradyan/.cache/coursier/arc/https/github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u292-b10/OpenJDK8U-jdk_x64_linux_hotspot_8u292b10.tar.gz/jdk8u292-b10"
export PATH="$PATH:/home/universe.dart.spb/amuradyan/.cache/coursier/arc/https/github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u292-b10/OpenJDK8U-jdk_x64_linux_hotspot_8u292b10.tar.gz/jdk8u292-b10/bin"
# <<< JVM installed by coursier <<<

# >>> coursier install directory >>>
export PATH="$PATH:/home/universe.dart.spb/amuradyan/.local/share/coursier/bin"
# <<< coursier install directory <<<

export PATH="$PATH:/home/universe.dart.spb/amuradyan/devel/rofi-bluetooth"
