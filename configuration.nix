# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let caches = [ "https://cache.nixos.org/"
               "http://hydra.cryp.to"
             ];
    zsh = "/run/current-system/sw/bin/zsh";
    user = {
        name = "jb55";
        group = "users";
        uid = 1000;
        extraGroups = [ "wheel" ];
        createHome = true;
        home = "/home/jb55";
        shell = zsh;
      };
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };

  fileSystems = [
    { mountPoint = "/sand";
      device = "/dev/disk/by-label/sand";
      fsType = "ext4";
    }
    { mountPoint = "/home/jb55/.local/share/Steam/steamapps";
      device = "/sand/data/SteamAppsLinux";
      fsType = "none";
      options = "bind";
    }
  ];

  programs.ssh.startAgent = true;

  time.timeZone = "America/Vancouver";

  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    enableCoreFonts = true;
    fonts = with pkgs; [
      corefonts
      inconsolata
      ubuntu_font_family
      fira-code
      fira-mono
      source-code-pro
      ipafont
    ];
  };

  nix = {
    binaryCaches = caches;
    trustedBinaryCaches = caches;
    binaryCachePublicKeys = [
      "hydra.cryp.to-1:8g6Hxvnp/O//5Q1bjjMTd5RO8ztTsG8DKPOAg9ANr2g="
    ];
  };

  networking = {
    hostName = "monad";
    hostId = "900eef22";
    extraHosts = ''
      174.143.211.135 freenode.znc.jb55.com
      174.143.211.135 globalgamers.znc.jb55.com
    '';
  };

  hardware = {
    bluetooth.enable = true;
    pulseaudio.enable = true;
    sane = {
      enable = true;
      configDir = "/home/jb55/.sane";
    };
    opengl.driSupport32Bit = true;
  };

  environment.x11Packages = with pkgs; [
    gnome.gnomeicontheme
    gtk
    hicolor_icon_theme
    shared_mime_info
    xfce.thunar
    xfce.xfce4icontheme  # for thunar
  ];

  environment.systemPackages = with pkgs; [
    #unity3d
    autocutsel
    bc
    binutils
    chromium
    dmenu
    emacs
    file
    gitAndTools.git-extras
    gitFull
    haskellPackages.taffybar
    hsetroot
    htop
    lsof
    nix-repl
    parcellite
    patchelf
    redshift
    rsync
    rxvt_unicode
    scrot
    silver-searcher
    slock
    steam
    subversion
    unzip
    vim
    vlc
    wget
    xautolock
    xbindkeys
    xclip
    xdg_utils
    xlibs.xev
    xlibs.xmodmap
    xlibs.xset
    zathura
  ];

  nixpkgs.config = {
    allowUnfree = true;
    chromium.enablePepperFlash = true;
    chromium.enablePepperPDF = true;
  };

  services.redshift = {
    enable = true;
    temperature.day = 5700;
    temperature.night = 2800;
    # gamma=0.8

    latitude="49.270186";
    longitude="-123.109353";
  };

  services.mpd = {
    enable = true;
  };

  services.mongodb = {
    enable = true;
  };

  services.xserver = {
    enable = true;
    layout = "us";
    xkbOptions = "terminate:ctrl_alt_bksp, ctrl:nocaps";

    desktopManager = {
      default = "none";
      xterm.enable = false;
    };

    displayManager = {
      sessionCommands = ''
#       ${pkgs.xlibs.xsetroot}/bin/xsetroot -cursor_name left_ptr
        ${pkgs.xlibs.xset}/bin/xset r rate 200 50
        ${pkgs.xlibs.xmodmap}/bin/xmodmap $HOME/.Xmodmap
        ${pkgs.haskellPackages.taffybar}/bin/taffybar &
        ${pkgs.parcellite}/bin/parcellite &
        ${pkgs.xlibs.xinput}/bin/xinput set-prop 8 "Device Accel Constant Deceleration" 3
        ${pkgs.hsetroot}/bin/hsetroot -solid '#1a2028'
        ${pkgs.xbindkeys}/bin/xbindkeys
        ${pkgs.feh}/bin/feh --bg-fill $HOME/etc/img/polygon1.png
        ${pkgs.xautolock}/bin/xautolock -time 10 -locker slock &
      '';

      lightdm.enable = true;
    };

    videoDrivers = [ "nvidia" ];

    screenSection = ''
      Option "metamodes" "1920x1080_144 +0+0"
    '';

    # windowManager.spectrwm.enable = true;
    windowManager = {
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = hp: [
          hp.taffybar
        ];
      };
      default = "xmonad";
    };
  };

  virtualisation.virtualbox.host.enable = true;
  virtualisation.docker.enable = true;

  security.setuidPrograms = [ "slock" ];

  users.extraUsers.jb55 = user;
  users.extraGroups.vboxusers.members = [ "jb55" ];

  users.defaultUserShell = zsh;
  users.mutableUsers = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint ] ;
  };

  programs.zsh.enable = true;
}

