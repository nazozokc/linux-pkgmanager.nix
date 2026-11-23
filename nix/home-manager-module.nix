# nix/home-manager-module.nix
# 消費側の home-manager 設定に import する。
#
#   imports = [ inputs.linux-pkgmanager.nix.flakeModules.home-manager ];
#   programs.nlp = {
#     enable = true;
#     packages = [ "bat" "eza" ];              # 全 pm に共通 (autoDetect 既定 true)
#     packagesByPm.pacman = [ "man-db" ];      # pm 固有
#   };
#
# やるのは「宣言を焼き込んだ nlp を home.packages に載せる」だけ。
#
# apply / update は sudo が要るので activation では走らせない。
# パスワード入力を activation の中に挟むと、非対話の switch や CI で必ず詰まる。
# 運用は「switch のあとに `nlp apply` を手で打つ」で固定する。
# いつ走らせるかは消費側の都合なので、ここでは決めない
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.nlp;

  backends = import ./lib/backends.nix;

  # 検査は flake-parts 版と同じものを通す
  declaredCheck = import ./lib/declared.nix { inherit lib backends; };
  inherit (declaredCheck) validate;

  mkNlp = import ./lib/mk-nlp.nix { inherit lib backends validate; };
  normalize = import ./lib/normalize.nix { inherit lib backends; };
  normalizeUpdate = import ./lib/update.nix { inherit lib backends; };

  # 正規化された宣言（High-level + Low-level をマージ）
  declaredNormalized =
    if cfg.declared != { } then
      cfg.declared
    else
      normalize.normalizeDeclared {
        enable = true;
        inherit (cfg)
          autoDetect
          commonPackages
          packages
          packagesByPm
          managers
          ;
      };

  # 更新設定の検証。onActivation = true はここで評価時に落とす
  updateCfg = normalizeUpdate cfg.update;

  # 宣言を焼き込んだ実行体。enable = false のときはこの thunk は触られない
  # (config 側が mkIf で包んでいるため)
  package = mkNlp {
    inherit pkgs;
    declared = declaredNormalized;
    update = updateCfg;
  };
in
{
  options.programs.nlp = {
    enable = lib.mkEnableOption "linux-pkgmanager (nlp) を home.packages に載せる";

    # High-level convenience options
    autoDetect = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        全 pm 分の宣言を作る (既定 true)。
        評価時にホストの pm は分からない (pure 評価を壊さないため) ので、
        実際にどの pm を使うかは実行時の PATH 検出が決める。
        特定の pm だけを対象にしたいときは false にして packagesByPm を書く。
      '';
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "全 pm に共通して入れたいパッケージ名のリスト (dotfiles の主入力)";
    };

    packagesByPm = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either (lib.types.listOf lib.types.str) lib.types.path);
      default = { };
      description = "pm 固有のパッケージ一覧。値はリストでもファイルでも書ける";
    };

    commonPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "packages の互換用別名。新しい設定では packages を使う";
    };

    managers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.enable = lib.mkEnableOption "このマネージャーを有効化する";
        }
      );
      default = { };
      description = "有効マネージャーを明示的に指定する (Low-level)";
    };

    update = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              false にすると実行体の update が拒否される。
              home-manager は apps を出さないので、ここでは nlp 本体に焼き込む。
            '';
          };
          onActivation = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              非対応。true にすると評価時に落ちる。
              activation に sudo を挟むと非対話の switch と CI が詰まるため、
              switch のあとに nlp update を手動で実行する。
            '';
          };
          flags = lib.mkOption {
            type = lib.types.attrsOf (lib.types.listOf lib.types.str);
            default = { };
            description = ''
              pm ごとの更新コマンドへ末尾に足す引数。1 要素 = 1 引数。
            '';
          };
        };
      };
      default = { };
      description = "更新コマンドの設定 (nlp update)";
    };

    # Low-level: explicit declared
    declared = lib.mkOption {
      # リストでもファイルでも書ける。nix/lib/declared.nix が import する
      type = lib.types.attrsOf (lib.types.either (lib.types.listOf lib.types.str) lib.types.path);
      default = { };
      example = {
        pacman = ./packages/pacman.nix;
        apt = [
          "man-db"
          "bash-completion"
        ];
      };
      description = ''
        パッケージマネージャー名からパッケージ名リストへの宣言（Low-level）。
        リストでもファイルでも書ける。ファイルは評価時に import され、
        中身がリストでなければ評価時に落ちる。
        書いた pm だけを使う。書かなかった pm は空リストとして扱う。
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      defaultText = lib.literalExpression "nlp (nlp.declared を焼き込んだ実行体)";
      description = ''
        home.packages に載せる実行体。
        宣言はそのままに、本体だけ差し替えたいときに指定する。
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # pacman / apt / dnf / zypper / yum は Linux のツール。
    # darwin の home-manager には載せない (evaluation にも意味がない)
    home.packages = lib.mkIf pkgs.stdenv.hostPlatform.isLinux [ cfg.package ];
  };
}
