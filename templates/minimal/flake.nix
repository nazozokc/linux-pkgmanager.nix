{
  description = "Minimal linux-pkgmanager.nix setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    linux-pkgmanager.url = "github:nazozokc/linux-pkgmanager.nix";
  };

  outputs =
    inputs@{ flake-parts, linux-pkgmanager, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [ linux-pkgmanager.flakeModules.default ];

      # dotfiles らしく 1 つのリストだけ書けば全 pm で動く
      nlp = {
        enable = true;
        packages = [
          "curl"
          "git"
          "jq"
        ];
      };
    };
}
