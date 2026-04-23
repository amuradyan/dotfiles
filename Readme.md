# Settings

This repo contains settings for different tools (a la dotfiles)

## Tools
* [VS Code](https://code.visualstudio.com/)
* [zsh](http://zsh.sourceforge.net/)
* [git](https://www.git-scm.com/)
* [tmux](https://github.com/tmux/tmux/wiki)

## Stuff I install

> sudo apt install mc tmux tmuxinator tig zsh iwd xsecurelock rofi polybar dunst scrot



## Awesome oldschool fonts everybody needs

https://int10h.org/oldschool-pc-fonts/


URxvt [font resize](https://github.com/simmel/urxvt-resize-font) should be installed

## Redacted files

Some files carry a placeholder instead of real content. Do **not** overwrite the live system copy with them naively.

- `.ssh/config` — `IdentityFile ~/.ssh/<private_key>` is a placeholder; live machine uses a real key filename.
- `nixos/db-init.sql` — holds the real PostgreSQL bootstrap password and is gitignored. `nixos/db-init.sql.example` ships the placeholder template; copy it to `/etc/nixos/db-init.sql` (root 0600) and edit the real password into place.
