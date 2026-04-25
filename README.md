# Infrastructure

This repository will host everything related to infrastructure for my needs.
For now, this is:

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