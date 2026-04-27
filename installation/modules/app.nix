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

    envFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the decrypted .env file (e.g. config.age.secrets.lmah-env.path).";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.name} = {
      isSystemUser = true;
      group = cfg.name;
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
      after = [ "network.target" ];

      serviceConfig = {
        User = cfg.name;
        Group = cfg.name;
        WorkingDirectory = "/opt/${cfg.name}";
        ExecStartPre = pkgs.writeShellScript "${cfg.name}-link-env" ''
          ln -sf ${cfg.envFile} /opt/${cfg.name}/.env
        '';
        ExecStart = cfg.binary;
        Restart = "on-failure";
      };
    };
  };
}
