{
  config,
  lib,
  pkgs,
  ...
}:
let
  defaultVersion = "0.1.5";
  defaultHash = "sha256:245b4cadfb8b6c419ee48c1ef7f07aa2553508804c1a3dadb5cd4880001213d5";

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
      default = defaultVersion;
      description = "Version of the lmah server binary to download.";
    };

    hash = lib.mkOption {
      type = lib.types.str;
      default = defaultHash;
      description = "SHA256 hash of the lmah server binary.";
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
