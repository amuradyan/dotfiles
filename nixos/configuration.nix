# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> {config.allowUnfree = true; };
in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
      };
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = [ 
      "xhci_pci" 
      "nvme" 
      "thunderbolt" 
      "usb_storage" 
      "sd_mod" 
      "rtsx_pci_sdmmc" 
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };
  
  networking = {
    hostName = "clarissa";
    wireless.iwd.enable = true;
  };

  services = {
    pulseaudio.enable = false;
    clipmenu.enable = true;
    printing.enable = true;
    udisks2.enable = true;
    acpid.enable = true;
    libinput.enable = true;
    logind = {
     settings.Login = {
        IdleAction = "suspend";
        IdleActionSec = 600;
      };
    };

    xserver = {
      enable = true;
      videoDrivers = ["nvidia"];
      windowManager.bspwm.enable = true;
      xkb = {
        layout = "us,ru,am";
        variant = "";
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
      enableTCPIP = true;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
      '';
      initialScript = pkgs.writeText "backend-initScript"
        (builtins.readFile ./db-init.sql);
    };
    
  };
  
  time.timeZone = "Asia/Yerevan";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {                                             
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";                                                      
  };
  
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "hy_AM";
      LC_IDENTIFICATION = "hy_AM";
      LC_MEASUREMENT = "hy_AM";
      LC_MONETARY = "hy_AM";
      LC_NAME = "hy_AM";
      LC_NUMERIC = "hy_AM";
      LC_PAPER = "hy_AM";
      LC_TELEPHONE = "hy_AM";
      LC_TIME = "hy_AM";
    };
  };

  security.rtkit.enable = true;

  virtualisation.docker.enable = true;

  users.users.spectrum = {
    isNormalUser = true;
    description = "spectrum";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "docker" "wheel" "input" ];
  };

  environment.variables.EDITOR = "hx";
 
  programs = {
    zsh.enable = true;
    direnv.enable = true;
    firefox.enable = true;
  };
  
  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [
    noto-fonts-color-emoji
  ];
  
  environment.systemPackages = with pkgs; [
    wget
    telegram-desktop
    helix
    git
    tmux
    zsh
    mc
    elixir
    elixir-ls
    tig
    chicken
    nodejs_22
    clojure
    unstable.vscode
    cypress
    clojure-lsp
    clj-kondo
    leiningen
    jdk
    scala_3
    sbt
    babashka
    gcc
    xclip
    python312
    python312Packages.pip
    inotify-tools
    bspwm
    rofi
    xsecurelock
    polybarFull
    dunst
    sxhkd
    scrot
    audacity
    rxvt-unicode
    bc
    alsa-utils
    feh
    xorg.xev
    xorg.xkill
    xorg.xinit
    lolcat
    fortune
    cowsay
    unstable.claude-code
    telegram-desktop
    pavucontrol
    llpp
    zip
    unzip
    deno
    racket
    xidlehook
    yarn
    postgresql_17
    dbeaver-bin
    btop
    slack
    element-desktop
    neofetch
    entr
    google-chrome
    scala-cli
    killall
    emacs
    udisks2
    libinput
    xdotool
    sox
    gimp-with-plugins
    arandr
    lsof
    docker
    ranger
    fzf
    jq
    ffmpeg
    bun
    gh
    anydesk

    # ranger preview backends + mc Type= matching
    w3m            # w3mimgdisplay for ranger image previews on urxvt
    bat            # syntax-highlighted text previews
    poppler-utils  # pdftotext for PDF previews
    mediainfo      # audio/video metadata
    exiftool       # image metadata
    atool          # archive content listing
    p7zip          # 7z archive support
    file           # libmagic; mc Type= rules shell out to this
    libheif        # heif-convert for HEIC -> JPEG thumbnails (w3m can't render HEIC directly)
 ];

 systemd.user.services.three-finger-swipe = {
    enable = true;
    wantedBy = [ "default.target" ];
    path = with pkgs; [ python3 libinput bspwm rofi ];
    serviceConfig.ExecStart = "/home/spectrum/.config/custom_scripts/three-finger-swipe.py";
    serviceConfig.Restart   = "always";
  };

  system = {
    stateVersion = "24.11";
    autoUpgrade.enable = true;
  };
}
