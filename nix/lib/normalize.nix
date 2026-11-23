{ lib, backends }:
let
  pms = lib.attrNames backends;
in
rec {
  # Normalize high-level options into declared attrset
  # declared is attrset pm -> list or path (we output lists for merged case)
  normalizeDeclared =
    {
      enable ? true,
      autoDetect ? false,
      commonPackages ? [ ],
      packages ? { },
      managers ? { },
    }:
    if !enable then
      { }
    else
      let
        # ホストにどの pm があるかは pure 評価では分からない。
        # autoDetect は「全 pm 分の宣言を作る」だけにして、
        # 実際に使う pm は実行時の PATH 検出 (40-detect.sh) に委ねる
        detectEnabled = if autoDetect then pms else [ ];

        explicitEnabled = builtins.filter (pm: managers.${pm}.enable or false) pms;

        # Merge enabled set
        enabledSet = lib.foldl' (acc: pm: acc // { ${pm} = true; }) { } (
          detectEnabled
          ++ explicitEnabled
          ++
            # If packages specified for a pm, include it unless explicitly disabled?
            (builtins.filter (pm: packages.${pm} or null != null) pms)
        );

        # If nothing enabled but packages declared or commonPackages exist, include those PMs
        enabledSet' =
          if enabledSet == { } && ((packages != { }) || (commonPackages != [ ])) then
            lib.foldl' (acc: pm: acc // { ${pm} = true; }) { } (
              builtins.filter (pm: packages.${pm} or null != null) pms
            )
          else
            enabledSet;

        # Build declared lists
        mkList =
          pm:
          let
            base = packages.${pm} or [ ];
            baseList =
              if builtins.isPath base then
                [ ] # path case handled separately? but we merge; better to keep as-is if path
              else
                base;
            merged = baseList ++ commonPackages;
          in
          if builtins.isPath (packages.${pm} or null) then
            # If user provided path, prefer path as-is? But commonPackages can't merge into path.
            # For high-level API we expect lists; if path given, use path (no common merge)
            packages.${pm}
          else
            lib.unique merged;
      in
      lib.foldl' (
        acc: pm: if enabledSet' ? ${pm} && enabledSet'.${pm} then acc // { ${pm} = mkList pm; } else acc
      ) { } pms;
}
