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

    confirm = mkOption {
      type = types.bool;
      default = true;
      description = "Ask confirmation for destroying disk";
    };

    diskName = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Disk name im disko configuration";
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
              cfg.configuration
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
