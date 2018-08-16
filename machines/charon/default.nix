extra:
{ config, lib, pkgs, ... }:
let adblock-hosts = pkgs.fetchurl {
      url    = "https://jb55.com/s/ad-sources.txt";
      sha256 = "d9e6ae17ecc41eb7021c0552548a1c8da97efbb61e3a750fb023674d01d81134";
    };
    dnsmasq-adblock = pkgs.fetchurl {
      url = "https://jb55.com/s/dnsmasq-ad-sources.txt";
      sha256 = "3b34e565fb240c4ac1d261cb223bdc2d992fa755b5f6e981144e5b18f96f260d";
    };
    gitExtra = {
      git = {projectroot = "/var/git";};
      host = "git.zero.jb55.com";
    };
    npmrepo = (import (pkgs.fetchFromGitHub {
      owner  = "jb55";
      repo   = "npm-repo-proxy";
      rev    = "017cd7c7d98a9cf927d73c4f5c99636e21803935";
      sha256 = "1knrzadnlcvd779da269njhs3psf5mjbbpf95axcc02rya01fqzc";
    }) {}).package;
    gitCfg = extra.git-server { inherit config pkgs; extra = extra // gitExtra; };
    hearpress = (import <jb55pkgs> { nixpkgs = pkgs; }).hearpress;
    myemail = "jb55@jb55.com";
    radicale-rights = pkgs.writeText "radicale-rights" ''
      [vanessa-famcal-access]
      user = vanessa
      collection = jb55/4bcae62e-9c8b-0d94-d8ef-977a29a24a84
      permission = rw

      # Give owners read-write access to everything else:
      [owner-write]
      user = .+
      collection = %(login)s(/.*)?
      permission = rw

      # Everyone can read the root collection
      [read]
      user = .*
      collection =
      permission = r
    '';
in
{
  imports = [
    ./networking
    ./hardware
    (import ./nginx extra)
    (import ./sheetzen extra)
    #(import ./vidstats extra)
  ];

  users.extraGroups.jb55cert.members = [ "prosody" "nginx" ];

  services.gitDaemon.basePath = "/var/git-public/repos";
  services.gitDaemon.enable = true;

  services.radicale.enable = true;
  services.radicale.config = ''
    [auth]
    type = htpasswd
    htpasswd_filename = /home/jb55/.config/radicale/users
    htpasswd_encryption = plain
    delay = 1

    [storage]
    filesystem_folder = /home/jb55/.config/radicale/data

    [server]
    hosts = 127.0.0.1:5232
    ssl = False
    max_connections = 20

    # 1 Megabyte
    max_content_length = 10000000

    timeout = 10

    [rights]
    type = from_file
    file = ${radicale-rights}
  '';

  security.acme.certs."jb55.com" = {
    webroot = "/var/www/challenges";
    group = "jb55cert";
    allowKeysForGroup = true;
    postRun = "systemctl restart prosody";
    email = myemail;
  };

  security.acme.certs."coretto.io" = {
    webroot = "/var/www/challenges";
    email = myemail;
  };

  security.acme.certs."git.jb55.com" = {
    webroot = "/var/www/challenges";
    group = "jb55cert";
    allowKeysForGroup = true;
    email = myemail;
  };

  security.acme.certs."sheetzen.com" = {
    webroot = "/var/www/challenges";
    email = myemail;
  };

  security.acme.certs."hearpress.com" = {
    webroot = "/var/www/challenges";
    email = myemail;
  };

  services.mailz = {
    enable = true;
    domain = "jb55.com";

    users = {
      jb55 = {
        password = "$6$KHmFLeDBaXBE1Jkg$eEN8HM3LpZ4muDK/JWC25qW9xSZq0AqsF4tlzEan7yctROJ9A/lSqz6gN1b1GtwE7efroXGHtDi2FEJ2ujDAl0";
        aliases = [ "postmaster" "bill" "will" "william" "me" "jb" ];
      };
    };

    sieves = builtins.readFile ./dovecot/filters.sieve;
  };

  users.extraUsers.prosody.extraGroups = [ "jb55cert" ];
  services.prosody.enable = true;
  services.prosody.admins = [ "jb55@jb55.com" ];
  services.prosody.allowRegistration = false;
  services.prosody.extraModules = [
    # "cloud_notify"
    # "smacks"
    # "carbons"
    # "http_upload"
  ];
  services.prosody.extraConfig = ''
    c2s_require_encryption = true
  '';
  services.prosody.ssl = {
    cert = "${config.security.acme.directory}/jb55.com/fullchain.pem";
    key = "${config.security.acme.directory}/jb55.com/key.pem";
  };
  services.prosody.virtualHosts.jb55 = {
    enabled = true;
    domain = "jb55.com";
    ssl = {
      cert = "${config.security.acme.directory}/jb55.com/fullchain.pem";
      key = "${config.security.acme.directory}/jb55.com/key.pem";
    };
  };

  services.postgresql = {
    dataDir = "/var/db/postgresql/9.5";
    package = pkgs.postgresql95;
    enable = true;
    enableTCPIP = true;
    authentication = ''
      # type db  user address        method
      local  all all                 trust
      host   all all  172.24.0.0/16  trust
      host   all all  127.0.0.1/16  trust
    '';
    #extraConfig = ''
    #  listen_addresses = '${extra.ztip}'
    #'';
  };

  systemd.services.npmrepo = {
    description = "npmrepo.com";

    wantedBy = [ "multi-user.target" ];

    serviceConfig.Type = "simple";
    serviceConfig.ExecStart = "${npmrepo}/bin/npm-repo-proxy";
  };


  services.dnsmasq.enable = false;
  services.dnsmasq.servers = ["8.8.8.8" "8.8.4.4"];
  services.dnsmasq.extraConfig = ''
    addn-hosts=${adblock-hosts}
    conf-file=${dnsmasq-adblock}
  '';

  security.setuidPrograms = [ "sendmail" ];

  services.fcgiwrap.enable = true;

  services.nginx.httpConfig = ''
    ${gitCfg}

    server {
      listen 443 ssl;
      server_name coretto.io;
      root /home/jb55/www/coretto.io;
      index index.html;

      ssl_certificate /var/lib/acme/coretto.io/fullchain.pem;
      ssl_certificate_key /var/lib/acme/coretto.io/key.pem;

      location / {
        try_files $uri $uri/ =404;
      }

      location /email {
        gzip off;
        # fcgiwrap is set up to listen on this host:port
        fastcgi_pass                  unix:${config.services.fcgiwrap.socketAddress};
        include                       ${pkgs.nginx}/conf/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /home/jb55/www/coretto.io/email.py;

        client_max_body_size 512;

        # export all repositories under GIT_PROJECT_ROOT

        fastcgi_param PATH_INFO           $uri;
      }


    }

    server {
      listen 80;
      server_name coretto.io www.coretto.io;

      location /.well-known/acme-challenge {
        root /var/www/challenges;
      }

      location / {
        return 301 https://coretto.io$uri;
      }
    }

    server {
      listen 443 ssl;
      server_name www.coretto.io;
      return 301 https://coretto.io$request_uri;
    }

    server {
      listen 80;
      server_name git.jb55.com;

      location /.well-known/acme-challenge {
        root /var/www/challenges;
      }

      location / {
        return 301 https://git.jb55.com$request_uri;
      }
    }

    server {
      listen       443 ssl;
      server_name  git.jb55.com;

      root /var/git-public/stagit;
      index index.html index.htm;

      ssl_certificate /var/lib/acme/git.jb55.com/fullchain.pem;
      ssl_certificate_key /var/lib/acme/git.jb55.com/key.pem;
    }

    server {
      listen 443 ssl;
      server_name jb55.com;
      root /www/jb55/public;
      index index.html index.htm;

      ssl_certificate /var/lib/acme/jb55.com/fullchain.pem;
      ssl_certificate_key /var/lib/acme/jb55.com/key.pem;

      rewrite ^/pkgs.tar.gz$ https://github.com/jb55/jb55pkgs/archive/master.tar.gz permanent;
      rewrite ^/pkgs/?$ https://github.com/jb55/jb55pkgs/archive/master.tar.gz permanent;

      location / {
        try_files $uri $uri/ =404;
      }

      location /cal/ {
        proxy_pass        http://127.0.0.1:5232/;
        proxy_set_header  X-Script-Name /cal;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
      }

      location ^~ /files/calls {
        error_page 405 =200 $uri;
      }
    }

    server {
      listen 80;
      server_name jb55.com www.jb55.com;

      location /.well-known/acme-challenge {
        root /var/www/challenges;
      }

      location / {
        return 301 https://jb55.com$request_uri;
      }
    }

    server {
      listen 443 ssl;
      server_name www.jb55.com;
      return 301 https://jb55.com$request_uri;
    }

  '';

}

