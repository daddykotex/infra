{ config, pkgs, ... }:
let
  domain = "box1.davidfrancoeur.com";
  group_gcp_lmah = "gcp-lmah";
  group_litestream_lmah = "litestream-lmah";

  litestream_db_lmah = "/var/run/litestream/lmah.db";
  litestream_replica_lmah = "gs://lmah-db-replica/lmah-qa";
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
  
  # Group that can be used for litestream and the app to share the database file
  users.groups.${group_litestream_lmah} = {};

  # Ensure litestream can read the GCP Service Account secret
  users.users.litestream.extraGroups = [ group_gcp_lmah group_litestream_lmah ];

  systemd.services.litestream.serviceConfig.ExecStartPre = "+" + toString (pkgs.writeShellScript "litestream-start-pre" ''
    mkdir -p /var/run/litestream
    chown litestream:litestream /var/run/litestream

    # init db for lmah
    ${pkgs.litestream}/bin/litestream restore -if-db-not-exists -o ${litestream_db_lmah} ${litestream_replica_lmah}
    chown litestream:${group_litestream_lmah} ${litestream_db_lmah}
    chmod 660 ${litestream_db_lmah}
  '');

  # SQLite database replication
  services.litestream = {
    enable = true;
    settings = {
      dbs = [
        {
          path = litestream_db_lmah;
          replicas = [
            {
              url = litestream_replica_lmah;
            }
          ];
        }
      ];
    };
    # Ideally, we'd have two service keys: 1 for the app, one for the litestream replication
    environmentFile = pkgs.writeText "litestream-env" ''
      GOOGLE_APPLICATION_CREDENTIALS=${config.age.secrets.lmah-calendar-gcp-sa-key-json.path}
    '';
  };

  # LMAH inventory app
  services.lmah = {
    version = "0.1.3";
    hash = "sha256:7ad05e8ed014fa5bc553087d76911317d7cf969e3b5a2e6a1ba5155a3a451a80";
  };
  services.myApp = {
    enable = true;
    name = "lmah";
    extraGroups = [
      group_gcp_lmah # ensure both can read the secret # TODO use different secret keys
      group_litestream_lmah # ensure both can access the db
    ];
    # binary = "${config.services.lmah.package}/bin/lmah-server";
    binary = "/run/current-system/sw/bin/sleep infinity";
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
