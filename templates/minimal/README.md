# linux-pkgmanager.nix minimal template

```bash
nix flake init -t github:nazozokc/linux-pkgmanager.nix#minimal
nix run .#nlp-diff
nix run .#nlp-apply
nix run .#nlp-update
```

`nlp.packages` is a flat list. `autoDetect` defaults to `true`, so the same list is declared for every backend and the backend actually used is picked from `PATH` at runtime. Use `nlp.packagesByPm.<pm>` only for pm-specific packages.

For home-manager, pass `inputs` through `specialArgs` and import `home-manager-example.nix`, which uses `flakeModules.home-manager`.
