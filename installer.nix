{
  config,
  lib,
  pkgs,
  modulesPath,
  installerCfg,
  nixosSystem,
  flake,
  cfgName,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  config = let
    cfg = installerCfg;
    flakeConf = "${flake}#${cfgName}";
    recFlattenInputs = inputs:
      builtins.foldl' (acc: input:
        let
          # Рекурсивно собираем инпуты текущего инпута
          nested = recFlattenInputs (input.inputs or {});
        in acc ++ [ input ] ++ [ nested ]
      ) [] (builtins.attrValues inputs);

    deps = (with nixosSystem.config.system.build; [ toplevel diskoScript]) ++
           (with nixosSystem.pkgs; [ stdenv
                                     perlPackages.ConfigIniFiles
                                     perlPackages.FileSlurp
                                   ]) ++
           (recFlattenInputs flake.inputs);
    cinfo = pkgs.closureInfo { rootPaths = deps; };
  in {
    systemd.services = (lib.genAttrs ["getty@tty1" "autovt@tty1"] (_: {
      enable = false;
      wantedBy = [ ];
    })) // {
      unattended-installer = {
        wantedBy = [ "multi-user.target" ];
        after = ["getty.target"];
        serviceConfig = {
          Type = "idle";
          Restart = "no";
          StandardInput = "tty-force";
          StandardOutput = "tty";
          StandardError = "tty";

          TTYPath = "/dev/tty1";

          TTYReset = "yes";
          TTYVHangup = "yes";
        };
        path = [
          pkgs.nix # Dependency of nixos-install
          # Dependencies of disko/disk-deactivate
          pkgs.gawk
          pkgs.zfs
        ];
        script = ''
          ${pkgs.ncurses}/bin/clear
          set -eufo pipefail
          echo Looking for largest disk
          disk=`${pkgs.util-linux}/bin/lsblk -d -b -o NAME,TYPE,RO,RM,SIZE,MODEL --json | ${pkgs.jq}/bin/jq -r '[.blockdevices[] | select(.ro == false and .rm == false)] | max_by(.size) | .name'`
          echo "Found $disk"
          echo THIS WILL DESTROY YOUR DISK!!! Press enter to continue, C-c to abort
          read
          echo Wiping and installing
          ${pkgs.disko}/bin/disko-install --mode format --disk main /dev/$disk --flake ${flakeConf} --write-efi-boot-entries

          echo Installation seems successful. Precautionary unmount
          ${pkgs.util-linux}/bin/umount -lfR /mnt || true
        '';
      };
    };

    environment.etc."install-closure".source = lib.mkIf (! cfg.installer.buildOnRemote) "${cinfo}/store-paths";
  };
}
