{ config, lib, pkgs, ... }: {
    imports = [
      ./hardware-configuration.nix
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

    # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
    boot.loader.grub.enable = false;
    # Enables the generation of /boot/extlinux/extlinux.conf
    boot.loader.generic-extlinux-compatible.enable = true;

    # networking.hostName = "nixos"; # Define your hostname.

    # Configure network connections interactively with nmcli or nmtui.
    # networking.networkmanager.enable = true;
    networking = {
      useDHCP = false;
      usePredictableInterfaceNames = false;
      interfaces.wlan0.useDHCP = true;
      wireless = {
        enable = true;
        # see: https://search.nixos.org/options?channel=25.11&query=wireless.secretsFile#show=option%253Anetworking.wireless.secretsFile
        secretsFile = config.age.secrets.rasp1-wifi-password.path;
        networks."davidetkateryne" = {
          pskRaw = "ext:PASS_DAVIDETKATERYNE";
        };
      };
    };

    # Set your time zone.
    # time.timeZone = "Europe/Amsterdam";

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Select internationalisation properties.
    # i18n.defaultLocale = "en_US.UTF-8";
    # console = {
    #   font = "Lat2-Terminus16";
    #   keyMap = "us";
    #   useXkbConfig = true; # use xkb.options in tty.
    # };

    # Enable the X11 windowing system.
    # services.xserver.enable = true;


    

    # Configure keymap in X11
    # services.xserver.xkb.layout = "us";
    # services.xserver.xkb.options = "eurosign:e,caps:escape";

    # Enable CUPS to print documents.
    # services.printing.enable = true;

    # Enable sound.
    # services.pulseaudio.enable = true;
    # OR
    # services.pipewire = {
    #   enable = true;
    #   pulse.enable = true;
    # };

    # Enable touchpad support (enabled default in most desktopManager).
    # services.libinput.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.rasp1 = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];

      # password can be hashed with: nix run nixpkgs#mkpasswd -- -m SHA-512 -s
      hashedPassword = "$6$/UkVdJiyFhjmvdbN$K7uLtBEJ9qHgYmUu5qG07XW3473caYKD6R9vBr4..gAdKRiNPWQ3B.ldjipB.U52Xtkj5rAvIdSyBfIjhNnUF0";
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxDLOoi5qM5kz3g9HMTsNE5WPWxNo8LUpvO1QBEBKDe43gjHUcjpMMgedPWT2ShPeOiB4B7CXpiq+MoQrdM/LzR1FQstaGfIo0pwhFYLXTnPHtZg3yxVV9AjgHMyyXIwkfubtjCj9DY0y2n3IFZTxXgM+67MSGptAJHVRqNDCia//hIF8PB6/7QnGPycMSQ3DViVCE33DBNHvj2j2ywHmma5vsK15NLynXP3dBNOdv4a/dsAg+MjOvdq5Tv/EDV3V3hrDrjxFGpXUI3OAovmxeiWH7WDB2NdJj2BEfRF+hKgMAoAiLb6pNXC8rvwZ5V3m9oP7JKcfgnvEljI/KA7kDq5o5n0fEMtoARQvPP6mnicnoGyJhP8us69WI5Z8HgYbR5g325ZfWWixveiqn2ZZPKvY9+Uk6tkjIOkJWFStEHmc5uh0EbLSqmGXlVw2QyEmUDcZ4H/4JqIpm7i5VedZpUN6gG5RaGvDuV9rslfxcAgmsQ0W93un9X1YYohomcAzhQNYeVutYpHiokOXuMtsSz9OgDcxTK3vYIHscNl6QcV8PqmdlP11e4VCXItOjLddAc1gsFFQ5IfTHkZ4aqqgY1Tdl6vxFI8dPt0dyA3LCLu9mgWr7J4Ev4IdQP00AKAPf/uTCX2Bk0eR50StEQWxez7m16zCll/gDOECCjVU2yw=="
      ];
    };

    # programs.firefox.enable = true;

    # List packages installed in system profile.
    # You can use https://search.nixos.org/ to find more packages (and options).
    # environment.systemPackages = with pkgs; [
    #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #   wget
    # ];

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    # programs.mtr.enable = true;
    # programs.gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };

    # List services that you want to enable:

    # Enable the OpenSSH daemon.
    # services.openssh.enable = true;

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

    # Copy the NixOS configuration file and link it from the resulting system
    # (/run/current-system/configuration.nix). This is useful in case you
    # accidentally delete configuration.nix.
    # system.copySystemConfiguration = true;

    # This option defines the first version of NixOS you have installed on this particular machine,
    # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
    #
    # Most users should NEVER change this value after the initial install, for any reason,
    # even if you've upgraded your system to a new NixOS release.
    #
    # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
    # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
    # to actually do that.
    #
    # This value being lower than the current NixOS release does NOT mean your system is
    # out of date, out of support, or vulnerable.
    #
    # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
    # and migrated your data accordingly.
    #
    # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    system.stateVersion = "25.11"; # Did you read the comment?
}