{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.rasp1-nixpkgs.url = "github:NixOS/nixpkgs/0c88e1f2bdb93d5999019e99cb0e61e1fe2af4c5"; # pinned from: https://hydra.nixos.org/build/328082553
  # secrets
  inputs.agenix.url = "github:ryantm/agenix";
  inputs.agenix.inputs.nixpkgs.follows = "nixpkgs";
  # disk creation when using nixos-anywhere
  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      nixpkgs,
      rasp1-nixpkgs,
      disko,
      agenix,
      ...
    }:
    {
      nixosConfigurations.box1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          agenix.nixosModules.default
          ./configuration.nix
          ./box1/default.nix
        ];
      };
      nixosConfigurations.rasp1 = rasp1-nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          agenix.nixosModules.default
          ./rasp1/default.nix
        ];
      };
    };
}
