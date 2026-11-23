# nix/lib/update.nix
# nlp.update オプションを実行体へ渡す前の検証と正規化。
#
# ここで落とすのは「宣言したのに効かない」設定だけ。
# flags は pm 更新コマンドの末尾に 1 要素 = 1 引数で足す。
# 改行はレジストリの区切りと衝突するので、ここで拒否する。
{ lib, backends }:
{
  enable ? true,
  onActivation ? false,
  flags ? { },
}:
let
  pms = lib.attrNames backends;

  unknown = builtins.filter (pm: !builtins.elem pm pms) (lib.attrNames flags);

  checkFlags =
    pm: fs:
    let
      bad = builtins.filter (flag: flag == "" || builtins.match "[^\n]*" flag == null) fs;
    in
    if bad != [ ] then
      throw "nlp.update.flags.${pm} に空文字または改行を含むフラグがあります。1 フラグ = 1 文字列で書いてください: ${lib.concatStringsSep " " (map builtins.toJSON bad)}"
    else
      fs;

  checkedFlags = lib.mapAttrs checkFlags flags;
in
if onActivation then
  throw "nlp.update.onActivation = true はサポートしません。activation に sudo を挟むと非対話の switch と CI が詰まります。switch のあとに nlp update を手動で実行してください"
else if unknown != [ ] then
  throw "nlp.update.flags に未知のパッケージマネージャーがあります: ${lib.concatStringsSep " " unknown} (使える名前: ${lib.concatStringsSep " " pms})"
else
  # attrs の値は遅延するので、返す attrset 自体を deepSeq して
  # 「設定した瞬間」に落とす (tryEval でも検証できる)
  builtins.deepSeq checkedFlags {
    inherit enable;
    flags = checkedFlags;
  }
