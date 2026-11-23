# linux-pkgmanager.nix minimal template

```bash
nix flake init -t github:nazozokc/linux-pkgmanager.nix#minimal
nix run .#nlp-diff
nix run .#nlp-apply
nix run .#nlp-update
```

`autoDetect = true` declares the packages for every backend. Which backend is used is decided at runtime from `PATH`, so the same flake works on apt/pacman/dnf hosts.

For home-manager, pass `inputs` through `specialArgs` and import `home-manager-example.nix`, which uses `flakeModules.home-manager` (no unknown-output warning).
