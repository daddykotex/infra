{
  config,
  lib,
  pkgs,
  ...
}:
let
  defaultVersion = "0.1.3";
  defaultHash = "sha256:7ad05e8ed014fa5bc553087d76911317d7cf969e3b5a2e6a1ba5155a3a451a80";

  mkLmahBinary = { version, hash }:
    pkgs.stdenv.mkDerivation {
      pname = "lmah-server";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/daddykotex/lmah-inventory-rs/releases/download/v${version}/server";
        inherit hash;
      };

      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      buildInputs = [ pkgs.stdenv.cc.cc.lib ];

      dontUnpack = true;
      dontBuild = true;

      installPhase = ''
        install -Dm755 $src $out/bin/lmah-server
      '';

      meta = {
        description = "lmah inventory server";
        platforms = [ "x86_64-linux" ];
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
