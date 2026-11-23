# nix/lib/normalize.nix
# 高位オプションを declared (pm -> リスト or パス) へ落とす。
#
# dotfiles では「どの distro でも同じ CLI を入れたい」が普通なので、
# autoDetect は既定 true (全 pm 分の宣言を作る)。実際に使う pm は
# 実行時の PATH 検出 (40-detect.sh) が決める。
{ lib, backends }:
let
  pms = lib.attrNames backends;
in
{
  normalizeDeclared =
    {
      enable ? true,
      autoDetect ? true,
      packages ? [ ],
      packagesByPm ? { },
      commonPackages ? [ ],
      managers ? { },
    }:
    if !enable then
      { }
    else
      let
        explicitEnabled = builtins.filter (pm: managers.${pm}.enable or false) pms;
        byPmEnabled = builtins.filter (pm: packagesByPm.${pm} or null != null) pms;

        # flat な packages は有効な pm に足す。commonPackages は互換用の別名。
        flat = packages ++ commonPackages;

        # autoDetect = false のときは packages だけでは pm を有効にしない。
        # 明示した managers / packagesByPm だけを対象にする
        enabled = if autoDetect then pms else lib.unique (explicitEnabled ++ byPmEnabled);

        mkList =
          pm:
          let
            base = packagesByPm.${pm} or [ ];
          in
          if builtins.isPath base then
            # パスは commonPackages / flat と連結しない (そのまま宣言として使う)
            base
          else
            lib.unique (base ++ flat);
      in
      lib.foldl' (acc: pm: acc // { ${pm} = mkList pm; }) { } enabled;
}
