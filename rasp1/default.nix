{ config, pkgs, modulesPath, ... }: {
    imports = [
      "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ];

    age.secrets.rasp1-wifi-password = {
      file = ../secrets/rasp1-wifi-password.age;
    };

    age.secrets.rasp1-ssh-private-key = {
      file = ../secrets/rasp1-ssh-private-key.age;
    };

    # Pre-provisioned SSH host key so agenix can decrypt secrets at first boot
    services.openssh = {
      enable = true;
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";  # path to the private key file
          type = "ed25519";
        }
      ];
    };
    # Embed the private key into the image
    environment.etc."ssh/ssh_host_ed25519_key" = {
      source = config.age.secrets.rasp1-ssh-private-key.path;  # path to the private key file
      mode = "0600";
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