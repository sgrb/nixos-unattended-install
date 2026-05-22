{
  description = "Unattended NixOS install";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./modules/uinstall.nix ];
      systems = [ "x86_64-linux" ];
      flake = {
        flakeModules.default = ./modules/uinstall.nix;
        nixosModules.simpleDisko = ./modules/simpleDisko.nix;
        nixosConfigurations.target = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.disko.nixosModules.default
            ./modules/simpleDisko.nix
            {
              users.users.root.password = "test";
            }
          ];
        };
      };
    };
}
