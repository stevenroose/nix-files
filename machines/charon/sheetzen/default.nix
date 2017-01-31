extra:
{ config, lib, pkgs, ... }:
let port = "1080";
    sname = "sheetzen.com";
    sheetzen = (import (pkgs.fetchgit {
      url    = "http://git.zero.jb55.com/socialtracker";
      rev    = "7bd919245c3c44a1ec9556d1982513ae6f2bf670";
      sha256 = "0i1990p9r35sf6x0jm1dpp0nbbmzq50v9h5r5qrryglrdllmp8n6";
    }) {});
in
{
  services.nginx.httpConfig = lib.mkIf config.services.nginx.enable ''
    server {
      listen 80;
      server_name ${sname} www.${sname};

      location /.well-known/acme-challenge {
        root /var/www/challenges;
      }

      location / {
        return 301 https://${sname}$request_uri;
      }
    }

    server {
      listen 443 ssl;
      server_name ${sname};
      root ${sheetzen}/share/sheetzen/frontend;
      index index.html;

      ssl_certificate /var/lib/acme/${sname}/fullchain.pem;
      ssl_certificate_key /var/lib/acme/${sname}/key.pem;

      location = / {
        try_files index.html /index.html;
      }

      location / {
        try_files $uri $uri/ @proxy;
      }

      location @proxy {
        proxy_pass  http://localhost:${port};
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;
        proxy_buffering off;
        proxy_intercept_errors on;
        proxy_set_header        Host            $host;
        proxy_set_header        X-Real-IP       $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
      }

    }
  '';

  systemd.services.sheetzen = {
    enable = true;

    description = "sheetzen";

    wantedBy = [ "multi-user.target" ];
    after    = [ "postgresql.target" ];

    environment = {
      PGHOST = extra.ztip;
      PGPORT = "5432";
      PGUSER = "jb55";
      PGPASS = "";
      PGDATABASE = "sheetzen";
      ENV = "Production";
      JWT_KEYFILE = "${sheetzen}/share/sheetzen/credentials/token-key.json";
      PORT = "${port}";
    };

    serviceConfig.ExecStart = "${sheetzen}/bin/sheetzend";
    unitConfig.OnFailure = "systemd-failure-emailer@%n.service";
  };
}