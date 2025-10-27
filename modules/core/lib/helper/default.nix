{lib, ...}:{
  # mkDotfiles "tanmay" ".config/nvim" ./dotfiles
  # → ensures /home/tanmay/.config and /home/tanmay/.config/nvim exist
  # → creates symlinks /home/tanmay/.config/nvim/<each entry in ./dotfiles> -> <src>/<entry>
  mkDotfiles = user: target: targetFolderName: srcFolder:
    let 
      home = "/home/${user}";
      dotfilesPath = builtins.path {
        path = srcFolder;
        name = "${targetFolderName}-dotfiles";
      };
      parts =
        builtins.filter (p: p != "" && p != ".")
          (builtins.split "/" target);

      # Build cumulative parent paths: [ ".config", ".config/nvim", ... ]
      parents =
        if builtins.length parts == 0 then []
        else builtins.genList
          (n: builtins.concatStringsSep "/" (builtins.take (n + 1) parts))
          (builtins.length parts - 1);
      dirRules =
        map (p: "d ${home}/${p} 0755 ${user} users - -") parents;
    in dirRules ++ [
      # Force-create/replace ~/.config/nvim -> store path of your Lua config
      "L+ ${home}/${target}/${targetFolderName} - ${user} - - ${dotfilesPath}"
    ];


 # Individually link files in srcPath to target so that target doesn't become a read-only link
  mkTmpFileRules = user: target: srcPath:
    let
      home = "/home/${user}";
      src = builtins.path {
        path = srcPath;
        name = "${target}-dotfiles";
      };

      parts =
        builtins.filter (p: p != "" && p != ".")
          (builtins.split "/" target);

      parents =
        if builtins.length parts == 0 then []
        else builtins.genList
          (n: builtins.concatStringsSep "/" (lib.lists.take (n + 1) parts))
          (builtins.length parts);  # fixed off-by-one

      dirRules =
        map (p: "d ${home}/${p} 0755 ${user} users - -") parents;

      entries = builtins.attrNames (builtins.readDir srcPath);

      linkRules =
        map (name:
          "L+ ${home}/${target}/${name} - ${user} users - ${srcPath}/${name}"
        ) entries;
    in
      dirRules ++ linkRules;
}

