Yet another NixOS unattended installer generator.

TL;DR:
- Wrap your NixOS configuration with flake-parts (put it into `flake.nixosConfigurations.${name}`)
- Add `flakeModules.default` to its imports
- You'll have `installer-${name}` package in your flake now, which builds installer iso
- Build it, write to the usb flash (or burn cd/dvd)

It requires that your configuration has disko configuration with exactly one disk (or you will have to specify which disk to use explicitly). The system will be installed onto the largest non-removable disk.
