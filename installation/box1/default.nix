{ config, pkgs, ... }:
let
  domain = "box1.davidfrancoeur.com";
  
  lmahDomain = "lmah-qa.lamarieealhonneur.com";
  lmahPort = 3000;
  group_gcp_lmah = "gcp-lmah";
in
{
  imports = [
    ../modules/nginx.nix
    ../modules/acme.nix
    ../modules/app.nix
    ../modules/apps/lmah.nix
    ../modules/litestream.nix
  ];

  # SSL renewal service
  services.myAcme = {
    enable = true;
    email = "info@davidfrancoeur.com";
    nginxGroup = "box1";
    domains = [ domain lmahDomain ];
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
      ${lmahDomain} = {
        useACMEHost = lmahDomain;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString lmahPort}";
        };
      };
    };
  };

  # Secrets decryption through agenix
  age.secrets.lmah-env = {
    file = ../secrets/lmah-env.age;
    mode = "400";
    # Only LMAH can read
    owner = "lmah";
  };
  age.secrets.lmah-calendar-gcp-sa-key-json = {
    file = ../secrets/lmah-calendar-gcp-sa-key-json.age;
    mode = "440";
    # both litestream and LMAH can read
    group = group_gcp_lmah;
  };

  # Group that can be used for litestream and the app to have access to the GCP
  # service account credentials
  users.groups.${group_gcp_lmah} = {};

  # SQLite database replication
  # Ideally, we'd have two service keys: 1 for the app, one for the litestream replication
  services.myLitestream = {
    enable = true;
    extraGroups = [ group_gcp_lmah ];
    environmentFile = pkgs.writeText "litestream-env" ''
      GOOGLE_APPLICATION_CREDENTIALS=${config.age.secrets.lmah-calendar-gcp-sa-key-json.path}
    '';
    databases.lmah = {
      createGroup = true;
      settings = { replicas = [{ url = "gs://lmah-db-replica/lmah-qa"; }]; };
    };
  };

  # LMAH inventory app
  services.lmah = {
    version = "0.1.4";
    hash = "sha256:c7ae1e85120d4cf1f9ba32976a482e15355c9560b455beb09d0aa59afaf5e198";
  };
  services.myApp = {
    enable = true;
    name = "lmah";
    litestream = true;
    extraGroups = [
      group_gcp_lmah # ensure both can read the secret # TODO use different secret keys
      config.services.myLitestream.databases.lmah.group # ensure both can access the db
    ];
    binary = "${pkgs.direnv}/bin/direnv exec . ${config.services.lmah.package}/bin/lmah-server --db-url sqlite://${config.services.myLitestream.databases.lmah.path} --port ${toString lmahPort}";
    secrets = [
      {
        description = "Application environment variables";
        source = config.age.secrets.lmah-env.path;
        target = ".env";
      }

      {
        description = "Google Service Account keys";
        source = config.age.secrets.lmah-calendar-gcp-sa-key-json.path;
        target = ".gcp_lmah-calendar_sa_key.json";
      }
    ];
  };
}
