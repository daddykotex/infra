# Infrastructure

This repository will host everything related to infrastructure for my needs.
For now, this is:

## rasp1

A raspberry pi 3+ that's plugged in my home. I use it as a control center for all the operations of my other boxes.

### how to

On CI, a NixOS img is generated, eg: https://github.com/daddykotex/infra/releases/tag/v0.1.5.

1. Download the compressed image
2. Decompress it: `nix-shell -p zstd --run "unzstd /path/to/image"`
3. Using Raspberry Imager, burn this image to the SD card you'll install on the Raspberry Pi
4. Plug in the Raspberry Pi
5. SSH into it to validate that it works `ssh root@xx.xx.xx.xx` (it should work because the base image knows my SSH key)
6. Export the `/etc/nixos/configuration.nix` and `/etc/nixox/hardware-configuration.nix`
6. Include them (with some modifications) in your `rasp1` flake
7. `ssh-keyscan xx.xx.xx.xx` to grab the SSH key and add it to the secrets.nix for this machine (`rasp1`)
7. Re-key the secrets for the SSH key `nix run github:ryantm/agenix -- -r -i /Users/davidfrancoeur/.ssh/id_rsa_dfrancoeur`
8. Build on the Raspberry pi: `nix run nixpkgs#nixos-rebuild -- build --fast --flake .#rasp1 --target-host root@xx.xx.xx.xx --build-host root@xx.xx.xx.xx`
9. Install and switch: `nix run nixpkgs#nixos-rebuild -- switch --fast --flake .#rasp1 --target-host root@192.168.18.28 --build-host root@192.168.18.28`

## box1

A NixOS box where we deploy
- cert renewal
- (internet facing) nginx to redirect for SSL termination and redirect to the right app - port 80 / port 443
- (through nginx) rust webapp for lamarieealhonneur - port 3000

### how to

1. Purchase the VPS (from serverbear)
2. Validate we can login using root password
3. Copy ssh pub key over: `ssh-copy-id -i ~/.ssh/id_rsa_dfrancoeur root@xx.xx.xx.xx`
4. (unrelated) Update home manager config to add server alias:

```nix
"box1.davidfrancoeur.com" = {
    hostname = "xx.xx.xx.xx";
    user = "root";
    identityFile = "~/.ssh/id_rsa_dfrancoeur";
    identitiesOnly = true;
    extraOptions = extraOptions;
};
```
5. Run nixos-anywhere to install nixos on the target machine (you'll be prompted for the root password):

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#box1 \
  --target-host root@xx.xx.xx.xx
```

6. Possibly optional: if you have connected to the machine previously and the identity was added to your known hosts file, you'll get the following message:

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
SHA256:xxxxxxxx.
Please contact your system administrator.
Add correct host key in /home/user/.ssh/known_hosts to get rid of this message.
Offending RSA key in /home/user/.ssh/known_hosts:8
  remove with:
  ssh-keygen -f '/home/user/.ssh/known_hosts' -R 'xx.xx.xx.xx'
Host key for xx.xx.xx.xx has changed and you have requested strict checking.
Host key verification failed.
```

If you do, just run the suggested command.

7. SSH into the box, you'll see `root@nixos` as the prompt.

### Notes

**nixos-anywhere-examples**

Checkout the [flake.nix](flake.nix) for examples tested on different hosters.
