# home-manager module usage example.
# Pass `inputs` via home-manager's specialArgs when importing this file.
{ inputs, ... }:
{
  imports = [ inputs.linux-pkgmanager.flakeModules.home-manager ];

  # flat な packages だけで distro 横断の dotfiles が書ける。
  # autoDetect は既定 true なので指定不要。
  programs.nlp = {
    enable = true;
    packages = [
      "curl"
      "git"
      "jq"
    ];

    # pm 固有のものだけ分けて書く
    packagesByPm.pacman = [
      "bat"
      "eza"
    ];
  };
}
