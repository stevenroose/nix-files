{ util, composeKey, userConfig, theme, icon-theme }:
{ config, lib, pkgs, ... }:
let
  clippings-pl-file = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/jb55/kindle-clippings/master/clippings.pl";
    sha256 = "13bn5lvm4p85369yj88jr62h3zalmmyrzmjc332qwlqgqhyf3dls";
  };
  clippings-pl = util.writeBash "clippings.pl" ''
    ${lib.getBin pkgs.perl}/bin/perl ${clippings-pl-file}
  '';
  clipmenu = pkgs.callPackage ../../nixpkgs/clipmenu {};
in
{
  services.gnome3.gnome-keyring.enable = true;

  services.redshift = {
    enable = true;
    temperature.day = 5700;
    temperature.night = 4700;
    # gamma=0.8

    brightness = {
      day = "1.0";
      night = "0.5";
    };

    latitude="49.270186";
    longitude="-123.109353";
  };


  services.udev.extraRules = ''
    # yubikey neo
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0116", MODE="0666"

    # yubikey4
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", MODE="0666"

    # kindle
    ATTRS{idVendor}=="1949", ATTRS{idProduct}=="0004", SYMLINK+="kindle"
  '';

  services.xserver = {
    enable = true;
    layout = "us";

    xkbOptions = "terminate:ctrl_alt_bksp, ctrl:nocaps, keypad:hex, altwin:swap_alt_win, lv3:ralt_switch, compose:${composeKey}";

    wacom.enable = true;

    desktopManager = {
      default = "none";
      xterm.enable = false;
    };

    displayManager = {
      sessionCommands = "${userConfig}/bin/xinitrc";
      lightdm = {
        enable = true;
        background = "${pkgs.fetchurl {
          url = "https://jb55.com/img/haskell-space.jpg";
          sha256 = "e08d82e184f34e6a6596faa2932ea9699da9b9a4fbbd7356c344e9fb90473482";
        }}";
        greeters.gtk = {
          theme = theme;
          # iconTheme = icon-theme;
        };
      };
    };

    screenSection = ''
      Option "metamodes" "1920x1080 +0+0"
      Option "dpi" "96 x 96"
    '';

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

  # Enable the OpenSSH daemon.
  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint ] ;
  };

  systemd.user.services.urxvtd = {
    enable = true;
    description = "RXVT-Unicode Daemon";
    wantedBy = [ "default.target" ];
    after    = [ "default.target" ];
    path = [ pkgs.rxvt_unicode-with-plugins ];
    serviceConfig = {
      Restart = "always";
      ExecStart = "${pkgs.rxvt_unicode-with-plugins}/bin/urxvtd -q -o";
    };
  };

  systemd.user.services.xautolock = {
    enable      = true;
    description = "X auto screen locker";
    wantedBy    = [ "graphical-session.target" ];
    after       = [ "graphical-session.target" ];
    serviceConfig.ExecStart = "${pkgs.xautolock}/bin/xautolock -time 10 -locker slock";
  };

  systemd.user.services.clipmenu = {
    enable      = true;
    description = "clipmenu";
    wantedBy = [ "graphical-session.target" ];
    after    = [ "graphical-session.target" ];
    serviceConfig.ExecStart = "${clipmenu}/bin/clipmenud";
  };

  systemd.user.services.xbindkeys = {
    enable      = true;
    description = "X key bind helper";
    wantedBy    = [ "graphical-session.target" ];
    after       = [ "graphical-session.target" ];
    serviceConfig.ExecStart = "${pkgs.xbindkeys}/bin/xbindkeys -n -f ${pkgs.jb55-dotfiles}/.xbindkeysrc";
  };

  systemd.user.services.xinitrc = {
    enable      = true;
    description = "X session init commands";
    wantedBy    = [ "graphical-session.target" ];
    after       = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${userConfig}/bin/xinitrc";
    };
  };

}
