{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.myApp;
in
{
  options.services.myApp = {
    enable = lib.mkEnableOption "myApp";

    name = lib.mkOption {
      type = lib.types.str;
      description = "Application name, used as user/group and working directory name.";
    };

    binary = lib.mkOption {
      type = lib.types.str;
      description = "Path to the application binary (or command) to run.";
    };

    secrets = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          description = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Human-readable description of the secret.";
          };
          source = lib.mkOption {
            type = lib.types.path;
            description = "Path to the decrypted secret (e.g. config.age.secrets.my-secret.path).";
          };
          target = lib.mkOption {
            type = lib.types.str;
            description = "Relative path inside the working directory where the secret is symlinked (e.g. \".env\").";
          };
        };
      });
      default = [];
      description = "Secrets to symlink into the working directory at service start.";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional groups to add the service user to.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages to add to the service's PATH.";
    };

    extraPreStart = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Shell script to append to ExecStartPre before the service starts.";
    };

    litestream = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether is app depends on litestream, or not.";
    };

    direnv = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable direnv integration.";
      };

      envrcContent = lib.mkOption {
        type = lib.types.str;
        default = "dotenv";
        description = "Content to write to the .envrc file.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.name} = {
      isSystemUser = true;
      group = cfg.name;
      extraGroups = cfg.extraGroups;
      home = "/opt/${cfg.name}";
      createHome = false;
    };

    users.groups.${cfg.name} = {};

    systemd.tmpfiles.rules = [
      "d /opt/${cfg.name} 0750 ${cfg.name} ${cfg.name} -"
    ];

    systemd.services.${cfg.name} = {
      description = "${cfg.name} application service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ lib.optional cfg.litestream "litestream.service";
      requires = lib.optional cfg.litestream "litestream.service";

      path = (lib.optional cfg.direnv.enable pkgs.direnv) ++ cfg.extraPackages;

      serviceConfig = {
        User = cfg.name;
        Group = cfg.name;
        WorkingDirectory = "/opt/${cfg.name}";
        ExecStartPre = pkgs.writeShellScript "${cfg.name}-start-pre" ''
          ${lib.concatMapStrings (secret: ''
          ln -sf ${secret.source} /opt/${cfg.name}/${secret.target}
          '') cfg.secrets}

          ${lib.optionalString cfg.direnv.enable ''
          # enable direnv
          echo "${cfg.direnv.envrcContent}" > /opt/${cfg.name}/.envrc

          # allow the .envrc through direnv
          ${pkgs.direnv}/bin/direnv allow /opt/${cfg.name}
          ''}

          ${cfg.extraPreStart}
        '';
        ExecStart = cfg.binary;
        Restart = "on-failure";
      };
    };
  };
}
