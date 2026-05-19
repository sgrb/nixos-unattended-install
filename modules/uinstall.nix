{
  self,
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (lib) types mkOption;
  cfg = config.uinstall;
  nixosSystem = inputs.nixpkgs.lib.nixosSystem;
in
{
  options.uinstall = {
    target = {
      configuration = mkOption {
        type = types.str;
        default = "target";
        description = "Target system configuration name";
      };
    };

    installer = {
      configuration = mkOption {
        type = types.anything;
        default = { };
        description = "Installer system configuration overrides";
      };

      buildOnRemote = mkOption {
        type = types.bool;
        default = false;
        description = "Don't pre-build target system";
      };

      wifiNetworks = mkOption {
        type = types.listOf types.anything;
        default = [ ];
        description = "WiFi networks for the installer";
      };
    };
  };

  config = let
    targetConf = self.outputs.nixosConfigurations.${cfg.target.configuration};
    installerConf = nixosSystem {
      inherit (targetConf.pkgs.stdenv.hostPlatform) system;
      modules = [
        ../installer.nix
        inputs.disko.nixosModules.default
        cfg.installer.configuration
      ];
      specialArgs = {
        installerCfg = cfg;
        nixosSystem = targetConf;
        flake = self;
      };
    };
  in {
    flake.nixosConfigurations.installer = installerConf;
    perSystem = { pkgs, system, ... }:
      let
        iso = installerConf.config.system.build.isoImage;
      in
        {
          packages = {
            inherit iso;
            default = iso;
          };
        };
  };
}
