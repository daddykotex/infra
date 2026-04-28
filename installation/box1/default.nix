{ config, ... }:
let
  domain = "box1.davidfrancoeur.com";
in
{
  imports = [ ../modules/nginx.nix ../modules/acme.nix ../modules/app.nix ];

  services.myAcme = {
    enable = true;
    email = "info@davidfrancoeur.com";
    nginxGroup = "box1";
    domains = [ domain ];
  };

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

  age.secrets.lmah-env.file = ../secrets/lmah-env.age;
  services.myApp = {
    enable = true;
    name = "lmah";
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
