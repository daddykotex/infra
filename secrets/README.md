# agenix guide

## configure

1. grab encryptor public key `cat ~/.ssh/id_rsa.pub` (or something like that)
2. grab target system public key `ssh-keyscan $host`
3. add the two keys above to the `./secrets.nix` file

The files would look like:

```nix
let
  # keys to encrypts
  dfrancoeur = "ssh-rsa my pub key";

  # target systems
  box1 = "ssh-ed25519 pub key on the box1 server";
in
{
  "lmah-env.age".publicKeys = [ dfrancoeur box1 ];
  "armored-secret.age" = {
    publicKeys = [ dfrancoeur ];
    armor = true;
  };
}
```


## encrypt a secret

Use the nix-flake to run the agenix, eg: `nix run github:ryantm/agenix -- agenix --help`.

For example to create the env file defined above, `lmah-env`, you'd do:

```bash
nix run github:ryantm/agenix -- -e lmah-env.agenix

# or redirect an existing .env file into agenix
nix run github:ryantm/agenix -- -e lmah-env.age < /path/to/.env

# specify the identify
nix run github:ryantm/agenix -- -i ~/.ssh/id_rsa -e lmah-env.age < /path/to/.env
```

## Decrypt a file

```
nix-shell -p age --run "age -d -i ~/.ssh/id_rsa_dfrancoeur rasp1-ssh-private-key.age" > ./.local/ssh_host_ed25519_key
```