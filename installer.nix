{
  config,
  lib,
  pkgs,
  modulesPath,
  installerCfg,
  nixosSystem,
  flake,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  config = let
    cfg = installerCfg;
    flakeConf = "${flake}#${cfg.target.configuration}";
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
          echo ${flakeConf}
          set -eufo pipefail
          echo Looking for largest disk
          disk=`${pkgs.util-linux}/bin/lsblk -d -b -o NAME,TYPE,RO,RM,SIZE,MODEL --json | ${pkgs.jq}/bin/jq -r '[.blockdevices[] | select(.ro == false and .rm == false)] | max_by(.size) | .name'`
          echo "Found $disk"
          echo Wiping and installing
          ${pkgs.disko}/bin/disko-install --disk main /dev/$disk --flake ${flakeConf} --write-efi-boot-entries

          echo Installation seems successful. Precautionary unmount
          ${pkgs.util-linux}/bin/umount -lfR /mnt || true
        '';
      };
    };

    environment.etc."install-targets".text = lib.mkIf (! cfg.installer.buildOnRemote) (lib.concatStringsSep "\n" (
      (lib.map lib.toString ((lib.attrValues flake.inputs) ++ [
        nixosSystem.config.system.build.toplevel
      ]))));
  };
}
