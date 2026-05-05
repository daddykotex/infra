{
  config,
  lib,
  ...
}:
let
  cfg = config.services.myAcme;
in
{
  options.services.myAcme = {
    enable = lib.mkEnableOption "ACME certificate renewal";

    email = lib.mkOption {
      type = lib.types.str;
      description = "Email address for Let's Encrypt account registration and expiry notices.";
    };

    nginxGroup = lib.mkOption {
      type = lib.types.str;
      description = "Group that nginx runs under, so it can read certificate files.";
    };

    testing = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use the Let's Encrypt staging server (for testing without hitting rate limits).";
    };

    domains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of domains to issue certificates for.";
    };
  };

  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = cfg.email;
        webroot = "/var/lib/acme/acme-challenge";
      } // lib.optionalAttrs cfg.testing {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      };
    };

    security.acme.certs = lib.listToAttrs (map (domain: {
      name = domain;
      value = {
        group = cfg.nginxGroup;
      };
    }) cfg.domains);
  };
}
