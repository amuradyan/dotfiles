# Dotfiles

Personal dotfiles for a bspwm + URxvt + zsh Linux setup. Generic enough to live under Debian or Arch; the `nixos/` directory additionally carries system config for NixOS hosts (currently `clarissa`).

## Layout

| Repo path | Target on system | What it configures |
|---|---|---|
| `.config/bspwm/` | `~/.config/bspwm/` | tiling WM, monitor scripts, `telman` sessions |
| `.config/polybar/` | `~/.config/polybar/` | status bar and pulseaudio volume helper |
| `.config/ranger/` | `~/.config/ranger/` | file manager |
| `.config/rofi/` | `~/.config/rofi/` | launcher and nord theme |
| `.config/sxhkd/` | `~/.config/sxhkd/` | global hotkeys |
| `custom_scripts/` | `~/.config/custom_scripts/` | personal scripts, prepended to `PATH` by `.zshrc` |
| `fonts/` | `~/.local/share/fonts/` | Px437 IBM DOS fonts and Material Design Icons |
| `git/.git-prompt.sh` | `~/.git-prompt.sh` | git segment for the shell prompt |
| `nixos/configuration.nix` | `/etc/nixos/configuration.nix` | NixOS system packages and services |
| `tig/.tigrc` | `~/.tigrc` | tig UI |
| `tmux/.tmux.conf` | `~/.tmux.conf` | tmux bindings |
| `vscode/{settings,keybindings}.json` | `~/.config/Code/User/` | VS Code |
| `x-files/.profile`, `.xinwer` | `~/.profile`, `~/.xinwer` | X session bootstrap |
| `zsh/.zshrc` | `~/.zshrc` | shell config |
| `.Xresources`, `.fehbg`, `.ssh/config` | `~/...` | terminal, wallpaper, SSH |

The authoritative list is `shove.manifest`; the table above is a human-readable mirror — keep them in sync.

## `shove` — the sync tool

`bin/shove` is a small bash driver that reads `shove.manifest` and walks each entry. It is copy-based, not symlink-based: the live tree gets its own byte copy. Defaults to `--dry-run`; pass `--write` to actually touch files.

```sh
./bin/shove status            # report drift per entry
./bin/shove push --write      # repo -> live
./bin/shove pull zsh          # live -> repo, filtered to entries containing "zsh"
./bin/shove bootstrap --write # fresh-machine install, seeds templates, runs hooks
```

Hosts are auto-detected: `nixos` if `/etc/NIXOS` exists, else `any`. Manifest entries tagged `host = nixos` are silently skipped on non-NixOS machines, so the same repo drives a Debian laptop and a NixOS laptop. Override with `--host any|nixos` if you need to.

`shove` also runs registered hooks (`fc-cache`, `nixos-rebuild`, `ssh-edit`) once per invocation after copies land.

## Bootstrapping a fresh machine

### Any Linux

1. Install the packages listed in [Required tools](#required-tools) via your distro's package manager.
2. Clone this repo to `~/devel/dotfiles`.
3. `./bin/shove bootstrap --write`.
4. Replace `<private_key>` in `~/.ssh/config` with the real key filename.
5. Log in to bspwm.

### NixOS (additionally)

1. Install NixOS; the standard installer generates `/etc/nixos/hardware-configuration.nix`.
2. Run `./bin/shove bootstrap --write`. This:
   - copies `nixos/configuration.nix` to `/etc/nixos/`;
   - seeds `/etc/nixos/db-init.sql` from the `.example` and opens `$EDITOR` for you to fill in the real password;
   - runs `sudo nixos-rebuild switch`, which installs every package listed in `environment.systemPackages` — bspwm, polybar, URxvt, etc.
3. Adjust `networking.hostName` in `/etc/nixos/configuration.nix` if not reusing `clarissa`, then rebuild again.

## Required tools

These are the generic packages the configs assume exist on `PATH`. On NixOS they come in via `nixos/configuration.nix`; elsewhere, install with your distro's package manager.

- Window management: `bspwm`, `sxhkd`, `polybar`, `dunst`
- Terminal + launcher: `rxvt-unicode` (URxvt), `rofi`, `xsecurelock`
- Shell + utilities: `zsh`, `tmux`, `tig`, `ranger`, `mc`
- X helpers: `scrot`, `xclip`, `feh`, `xdotool`, `xrandr`, `xidlehook`
- Sound: `pipewire` or `pulseaudio`, `alsa-utils`, `pavucontrol`
- Networking: `iwd` or equivalent

## Custom scripts

| Script | Purpose |
|---|---|
| `telman` | bspwm desktop layout save/restore; sessions live in `.config/bspwm/sessions/` |
| `chxk` | screenshot to `/tmp/screenshot.png` and clipboard |
| `brightness.sh` | backlight up/down |
| `bluetooth` | polybar bluetooth indicator and toggler |
| `keyboard_switcher.sh` | cycle xkb layouts (`us` / `ru` / `am`) |
| `lock_screen.sh`, `logout.sh` | session helpers |
| `wifi-picker.sh` | rofi-driven SSID picker |
| `suspender.sh` | idle-suspend helper |
| `paplay` | pulseaudio play wrapper |

## Redacted files

Two files ship as placeholders, not real content. `shove push` understands both and will not clobber a real secret.

- `.ssh/config` — `IdentityFile ~/.ssh/<private_key>` is a placeholder; the live machine uses a real key filename. After bootstrap, edit the live `~/.ssh/config` to replace the placeholder.
- `nixos/db-init.sql` — gitignored; holds the real PostgreSQL bootstrap password. `nixos/db-init.sql.example` ships the template. `shove bootstrap` seeds `/etc/nixos/db-init.sql` from the example (root-owned, `0600`) and opens `$EDITOR` on it.

## External bits worth knowing

- [Oldschool PC fonts](https://int10h.org/oldschool-pc-fonts/) — source of the Px437 IBM DOS fonts in `fonts/`.
- [urxvt-resize-font](https://github.com/simmel/urxvt-resize-font) — referenced by the URxvt keybindings in `.Xresources`.
