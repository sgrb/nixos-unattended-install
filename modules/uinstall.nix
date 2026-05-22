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
    namePrefix = mkOption {
      type = types.str;
      default = "installer-";
      description = "Installer iso package prefix name";
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

  config = {
    perSystem = {
        packages = lib.mapAttrs' (name: targetConf: let
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
              cfgName = name;
            };
          };
        in lib.nameValuePair
          "${cfg.namePrefix}${name}"
          installerConf.config.system.build.isoImage
        ) self.outputs.nixosConfigurations;
    };
  };
}
