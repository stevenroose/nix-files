userConfig:
{ config, lib, pkgs, ... }:
{
  # sync ical to org
  systemd.services.sync-ical2org.enable = true;

  services.redshift = {
    enable = true;
    temperature.day = 5700;
    temperature.night = 2800;
    # gamma=0.8

    latitude="49.270186";
    longitude="-123.109353";
  };

  services.zerotierone.enable = true;
  services.mpd = {
    enable = true;
    dataDir = "/home/jb55/mpd";
    user = "jb55";
    group = "users";
    extraConfig = ''
      audio_output {
        type     "pulse"
        name     "Local MPD"
        server   "127.0.0.1"
      }
    '';
  };

  services.mongodb.enable = true;
  services.redis.enable = true;

  services.postgresql = {
    enable = true;
    authentication = "local all all ident";
  };

  services.xserver = {
    enable = true;
    layout = "us";
    xkbOptions = "terminate:ctrl_alt_bksp, ctrl:nocaps";

    startGnuPGAgent = true;
    wacom.enable = true;

    desktopManager = {
      default = "none";
      xterm.enable = false;
    };

    displayManager = {
      sessionCommands = "${userConfig}/bin/xinitrc";
      lightdm.enable = true;
    };

    videoDrivers = [ "nvidia" ];

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

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  # Enable the OpenSSH daemon.
  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint ] ;
  };
}