# home-manager module usage example.
# Pass `inputs` via home-manager's specialArgs when importing this file.
{ inputs, ... }:
{
  # flakeModules.home-manager avoids the unknown flake output warning
  # that homeManagerModules produces under `nix flake check`.
  imports = [ inputs.linux-pkgmanager.flakeModules.home-manager ];
  programs.nlp = {
    enable = true;
    autoDetect = true;
    commonPackages = [
      "curl"
      "git"
      "jq"
    ];
    packages = {
      apt = [
        "bat"
        "eza"
      ];
      pacman = [
        "bat"
        "eza"
      ];
      dnf = [
        "bat"
        "eza"
      ];
    };
  };
}
