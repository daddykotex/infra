{ config, ... }:
let
  domain = "box1.davidfrancoeur.com";
in
{
  imports = [
    ../modules/nginx.nix
    ../modules/acme.nix
    ../modules/app.nix
    ../modules/apps/lmah.nix
  ];

  # SSL renewal service
  services.myAcme = {
    enable = true;
    email = "info@davidfrancoeur.com";
    nginxGroup = "box1";
    domains = [ domain ];
  };

  # Nginx for SSL termination (and ACME challenges)
  services.myNginx = {
    enable = true;
    user = "box1";
    group = "box1";
    virtualHosts = {
      ${domain} = {
        useACMEHost = domain;
        forceSSL = true;
        locations."/" = {
          extraConfig = ''
            return 200 "<p>it works</p>";
            add_header Content-Type text/html;
          '';
        };
      };
    };
  };

  # SQLite database replication
  services.litestream = {
    enable = true;
    settings = {};
  };

  # LMAH inventory app
  age.secrets.lmah-env.file = ../secrets/lmah-env.age;
  services.lmah = {
    version = "0.1.3";
    hash = "sha256:7ad05e8ed014fa5bc553087d76911317d7cf969e3b5a2e6a1ba5155a3a451a80";
  };
  services.myApp = {
    enable = true;
    name = "lmah";
    # binary = "${config.services.lmah.package}/bin/lmah-server";
    binary = "/run/current-system/sw/bin/sleep infinity";
    secrets = [
      {
        description = "Application environment variables";
        source = config.age.secrets.lmah-env.path;
        target = ".env";
      }
    ];
  };
}
