{ config, lib, pkgs, ... }:
let
  cfg = config.services.myLitestream;

  dbSubmodule = { name, config, ... }: {
    options = {
      dbName = lib.mkOption {
        type = lib.types.str;
        default = "${name}.db";
        description = "Filename of the SQLite database. Defaults to <name>.db.";
      };

      createGroup = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to create a litestream-<name> group for shared access to the database directory and file.";
      };

      settings = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Additional per-database litestream settings passed through verbatim (e.g. sync-interval).";
      };

      # Computed read-only outputs
      path = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Full filesystem path to the SQLite database file. Reference this in app configurations.";
      };

      dir = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Directory containing the database file.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "The shared group owning the database directory and file. Either litestream-<name> (if createGroup = true) or litestream.";
      };
    };

    config = {
      path = "${cfg.databaseDirectory}/${name}/${config.dbName}";
      dir = "${cfg.databaseDirectory}/${name}";
      group = if config.createGroup then "litestream-${name}" else "litestream";
    };
  };
in
{
  options.services.myLitestream = {
    enable = lib.mkEnableOption "myLitestream";

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional groups to add the litestream system user to (e.g. for GCP credential access).";
    };

    databaseDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/var/run/litestream";
      description = "Root directory under which per-database subdirectories are created.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to a systemd environment file passed to litestream (for secrets like GOOGLE_APPLICATION_CREDENTIALS).";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional litestream settings merged with the generated configuration. The generated dbs list is appended to any dbs defined here.";
    };

    databases = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule dbSubmodule);
      default = {};
      description = "Per-database litestream configuration, keyed by name.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create per-database groups
    users.groups = lib.mkMerge (lib.mapAttrsToList (name: db:
      lib.optionalAttrs db.createGroup { "litestream-${name}" = {}; }
    ) cfg.databases);

    # Add litestream user to extra groups and auto-created db groups
    users.users.litestream.extraGroups =
      cfg.extraGroups ++
      (lib.flatten (lib.mapAttrsToList (_name: db:
        lib.optional db.createGroup db.group
      ) cfg.databases));

    # Enable upstream litestream service and wire settings
    services.litestream = {
      enable = true;
      environmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
      settings = cfg.settings // {
        dbs = (cfg.settings.dbs or []) ++
          (lib.mapAttrsToList (_name: db:
            { path = db.path; } // db.settings
          ) cfg.databases);
      };
    };

    # Root-privileged pre-start: create directories, set permissions, restore databases
    systemd.services.litestream.serviceConfig.ExecStartPre =
      "+" + toString (pkgs.writeShellScript "myLitestream-start-pre" ''
        mkdir -p ${cfg.databaseDirectory}
        chown litestream:litestream ${cfg.databaseDirectory}

        ${lib.concatMapStrings (db: ''
          mkdir -p ${db.dir}
          chmod 2770 ${db.dir}
          chown litestream:${db.group} ${db.dir}

          ${pkgs.litestream}/bin/litestream restore -if-db-not-exists \
            -o ${db.path} \
            ${(builtins.head db.settings.replicas).url}
          chown litestream:${db.group} ${db.path}
          chmod 660 ${db.path}
        '') (lib.attrValues cfg.databases)}
      '');
  };
}
