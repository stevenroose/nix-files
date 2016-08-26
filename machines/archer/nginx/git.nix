
{ extra, config, pkgs }:
let gitwebConf = pkgs.writeText "gitweb.conf" ''
      # path to git projects (<project>.git)
      $projectroot = "${extra.git.projectroot}";
    '';
    gitweb-wrapper = pkgs.writeScript "gitweb.cgi" ''
      #!${pkgs.bash}/bin/bash
      export PERL5LIB=$PERL5LIB:${with pkgs.perlPackages; pkgs.lib.makePerlPath [ CGI HTMLParser ]}
      ${pkgs.perl}/bin/perl ${pkgs.git}/share/gitweb/gitweb.cgi
    '';
in
if config.services.fcgiwrap.enable then ''
  server {
      listen       ${extra.ztip}:80;
      server_name  git.zero.monster.cat;

      location = / {
        return 301 http://git.zero.monster.cat/repos/;
      }

      location = /repos {
        return 301 http://git.zero.monster.cat/repos/;
      }

      location / {
        # fcgiwrap is set up to listen on this host:port
        fastcgi_pass                  unix:${config.services.fcgiwrap.socketAddress};
        include                       ${pkgs.nginx}/conf/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME ${pkgs.git}/bin/git-http-backend;

        # export all repositories under GIT_PROJECT_ROOT

        fastcgi_param GIT_HTTP_EXPORT_ALL "";
        fastcgi_param GIT_PROJECT_ROOT    ${extra.git.projectroot};
        fastcgi_param PATH_INFO           $uri;
      }

      location /repos/static {
        alias ${pkgs.git}/share/gitweb/static;
      }

      location /repos {
        include ${pkgs.nginx}/conf/fastcgi_params;
        gzip off;

        fastcgi_param GITWEB_CONFIG   ${gitwebConf};
        fastcgi_param SCRIPT_FILENAME ${gitweb-wrapper};
        fastcgi_pass  unix:${config.services.fcgiwrap.socketAddress};
      }

  }
'' else ""
