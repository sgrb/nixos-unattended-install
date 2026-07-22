{
  description = "Unattended NixOS install";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ { flake-parts, disko, ... }:
  let
    uinstall = import ./modules/uinstall.nix {inherit disko;};
  in flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ uinstall ];
      systems = [ "x86_64-linux" ];
      flake = {
        flakeModules.default = uinstall;
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
