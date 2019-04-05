{ pkgs ? import ./nix {} }:
rec
{ niv = pkgs.snack-lib.executable ./package.yaml;
  readme = pkgs.writeText "README.md"
    (with
      { template = builtins.readFile ./README.tpl.md;
        niv_help = builtins.readFile
          (pkgs.runCommand "niv_help" { buildInputs = [ niv ]; }
            "niv --help > $out"
          );
        niv_cmd_help = cmd: builtins.readFile
          (pkgs.runCommand "niv_${cmd}_help" { buildInputs = [ niv ]; }
            "niv ${cmd} --help > $out"
          );
        cmds = [ "add" "update" "drop" "init" "show" ];
      };
    pkgs.lib.replaceStrings
      ([ "replace_niv_help" ] ++ (map (cmd: "replace_niv_${cmd}_help") cmds))
      ([ niv_help ] ++ (map niv_cmd_help cmds))
      template
    );
  readme-test = pkgs.runCommand "README-test" {}
    ''
      err() {
        echo
        echo -e "\e[31mERR\e[0m: README.md out of date"
        echo -e "please run \e[1m./script/gen\e[0m"
        echo
        exit 1
      }

      diff ${./README.md} ${readme} && echo dummy > $out || err ;
    '';
}
