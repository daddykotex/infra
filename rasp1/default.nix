{ config, pkgs, modulesPath, ... }: {
    imports = [
      "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ];

    age.secrets.rasp1-wifi-password = {
      file = ../secrets/rasp1-wifi-password.age;
    };

    # Pre-provisioned SSH host key so agenix can decrypt secrets at first boot
    services.openssh = {
      enable = true;
      hostKeys = [
        {
          # path to the private key file
          # key needs to be loaded on the device manually
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };

    networking = {
      useDHCP = false;
      usePredictableInterfaceNames = false;
      interfaces.wlan0.useDHCP = true;
      wireless = {
        enable = true;
        secretsFile = config.age.secrets.rasp1-wifi-password.path;
        networks."davidetkateryne" = {
          pskRaw = "ext:psk_home";
        };
      };
    };

    boot.kernelPackages = pkgs.linuxPackages_6_1;
    hardware.enableRedistributableFirmware = true;
}