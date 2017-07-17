extra:
{ config, lib, pkgs, ... }:
let util = extra.util;
    private = extra.private;
    extras = (rec { ztip = "10.243.14.20";
                    ztip-internal = "10.144.14.20";
                    nix-serve = {
                      port = 10845;
                      bindAddress = ztip;
                    };
                    import-scripts = (import <monstercatpkgs> { }).import-scripts;
                 }) // extra;
in {
  imports = [
    ./hardware
    ./fail-notifier
    (import ./backups extras)
    (import ./backups/git.nix extras)
    (import ./backups/wiki.nix extras)
    (import ./nginx extras)
    (import ./trendbot extras)
    (import ./transaction-bot extras)
    (import ./tunecore-sales-bot extras)
    (import ./bandcamp-sales-bot extras)
    (import ./youtube-sales-bot extras)
    (import <nixpkgs/nixos/modules/services/misc/gitit.nix>)
  ];

  # systemd.services.postgrest = {
  #   enable = false;
  #   description = "PostgREST";

  #   wantedBy = [ "multi-user.target" ];
  #   after =    [ "postgresql.service" ];

  #   serviceConfig.Type = "simple";
  #   serviceConfig.ExecStart = ''
  #     ${pkgs.haskellPackages.postgrest}/bin/postgrest \
  #       'postgres://pg-dev-zero.monstercat.com/Monstercat' \
  #       -a jb55 \
  #       +RTS -N -I2
  #   '';
  # };


  services.printing.drivers = [ pkgs.samsung-unified-linux-driver_4_01_17 ];
  services.mongodb.enable = true;
  services.redis = {
    enable = true;
    bind = extras.ztip;
  };
  services.gitlab.enable = false;
  services.gitlab.databasePassword = "gitlab";

  services.gitit = rec {
    enable = true;
    wikiTitle = "Monstercat Wiki";
    requireAuthentication = "none";
    sessionTimeout = 43800;
    math = "mathjax";
    plugins = [];
    mailCommand = "/run/current-system/sw/bin/sendmail %s";
    accessQuestion = "Enter 'monstercat' here";
    accessQuestionAnswers = "monstercat";
    staticDir = "/var/lib/gitit-static";
    useFeed = true;
    resetPasswordMessage = ''

      	> From: gitit@monstercat.com
      	> To: $useremail$
      	> Subject: ${wikiTitle} password reset
      	>
      	> Hello $username$,
      	>
      	> To reset your password, please follow the link below:
      	> http://wiki.monstercat.com$resetlink$
      	>
      	> Regards
    '';
  };

  users.extraGroups.gitit.members = [ "jb55" ];

  services.nginx.httpConfig = ''
    server {
      listen 80;
      server_name wiki.monstercat.com wiki.monster.cat;

      location / {
        proxy_pass  http://localhost:${toString config.services.gitit.port};
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;
        proxy_buffering off;
        proxy_set_header        Host            $host;
        proxy_set_header        X-Real-IP       $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
      }
    }
  '';

  services.nix-serve.enable = true;
  services.nix-serve.bindAddress = extras.nix-serve.bindAddress;
  services.nix-serve.port = extras.nix-serve.port;

  services.footswitch = {
    enable = true;
    enable-led = true;
    led = "input3::scrolllock";
  };

  networking.firewall.trustedInterfaces = ["zt0" "zt1"];
  networking.firewall.allowedTCPPorts = [ 22 143 80 ];

  networking.defaultMailServer = {
    directDelivery = private.gmail-user != null || private.gmail-pass != null;
    hostName = "smtp.gmail.com:587";
    root = "bill@monstercat.com";
    domain = "monstercat.com";
    useTLS = true;
    useSTARTTLS = true;
    authUser = private.gmail-user;
    authPass = private.gmail-pass;
  };

  services.fcgiwrap.enable = true;

  services.postfix = {
    enable = false;
    setSendmail = false;
  };

  systemd.user.services.mbsync = {
    description = "gmail sync";

    path = with pkgs; [ isync notmuch bash ];

    serviceConfig.ExecStart = util.writeBash "gmail-sync" ''
      mbsync gmail
      notmuch new
    '';

    startAt = "*:0/10";
  };

  systemd.services.postgresql.after = [ "zerotierone.service" ];

  services.postgresql = {
    dataDir = "/var/db/postgresql/9.5/";
    enable = true;
    # extraPlugins = with pkgs; [ pgmp ];
    authentication = pkgs.lib.mkForce ''
      # type db  user address        method
      local  all all                 trust
      host   all all  10.243.0.0/16  trust
      host   all all  192.168.1.0/16 trust

    '';
    extraConfig = ''
      listen_addresses = '10.243.14.20,192.168.1.49'
    '';
  };
}
