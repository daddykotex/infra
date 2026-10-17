{
  config,
  lib,
  pkgs,
  ...
}:
let
  release = lib.importJSON ./lmah.json;

  systemToTarget = {
    "x86_64-linux" = "linux-x86_64";
  };
  targetArch = systemToTarget.${pkgs.stdenv.hostPlatform.system};

  mkLmahBinary = { version, hash }:
    pkgs.stdenv.mkDerivation {
      pname = "lmah-server";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/daddykotex/lmah-inventory-rs/releases/download/v${version}/lmah-inventory-rs-${targetArch}.tar.gz";
        inherit hash;
      };

      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      buildInputs = [ pkgs.stdenv.cc.cc.lib ];

      dontBuild = true;

      installPhase = ''
        install -Dm755 server $out/bin/lmah-server
        cp -r static $out/static
      '';

      meta = {
        description = "lmah inventory server";
        platforms = builtins.attrNames systemToTarget;
      };
    };
in
{
  options.services.lmah = {
    version = lib.mkOption {
      type = lib.types.str;
      default = release.version;
      description = "Version of the lmah server binary to download. Defaults to the value in modules/apps/lmah.json.";
    };

    hash = lib.mkOption {
      type = lib.types.str;
      default = release.hash;
      description = "SHA256 hash of the lmah server binary. Defaults to the value in modules/apps/lmah.json.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      description = "Derived lmah server package. Set automatically from version and hash.";
    };
  };

  config.services.lmah.package = mkLmahBinary {
    inherit (config.services.lmah) version hash;
  };
}
