{
  config,
  lib,
  ...
}:
let
  cfg = config.services.myNginx;
in
{
  options.services.myNginx = {
    enable = lib.mkEnableOption "nginx";

    user = lib.mkOption {
      type = lib.types.str;
      description = "User account under which nginx runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      description = "Group under which nginx runs.";
    };

    virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          useACMEHost = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Name of the myAcme-managed certificate to use for this virtual host. Usually the domain name.";
          };

          forceSSL = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Redirect all HTTP traffic to HTTPS.";
          };

          locations = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {
              options = {
                return = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                proxyPass = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                extraConfig = lib.mkOption {
                  type = lib.types.lines;
                  default = "";
                };
              };
            });
            default = {};
          };
        };
      });
      default = {};
      description = "Virtual host configurations passed through to services.nginx.virtualHosts.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };

    users.groups.${cfg.group} = {};

    services.nginx = {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      virtualHosts = lib.mapAttrs (_name: vhost: {
        inherit (vhost) forceSSL;
        useACMEHost = vhost.useACMEHost;
        locations = lib.mapAttrs (_loc: locCfg: {
          inherit (locCfg) extraConfig;
          return = locCfg.return;
          proxyPass = locCfg.proxyPass;
        }) vhost.locations // lib.optionalAttrs (vhost.useACMEHost != null) {
          "/.well-known/".root = "/var/lib/acme/acme-challenge";
        };
      }) cfg.virtualHosts;
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
