{
  description = "devShell file generator helper";

  inputs.devshell.url = "github:numtide/devshell";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, flake-utils, devshell, nixpkgs }:
  let 
    systemic = system: {
      devShellModules = {
        imports = [
          ./modules/files.nix
          ./modules/json.nix
          ./modules/text.nix
          ./modules/toml.nix
          ./modules/yaml.nix
          ./modules/git.nix
          ./modules/gitignore.nix
        ];
      };
      devShell =
        let pkgs = import nixpkgs {
          inherit system;
          overlays = [ devshell.overlay ];
        };
        in
        pkgs.devshell.mkShell {
          imports = [
            self.devShellModules.${system}
            ./project.nix
          ];
        };

    };
  in
  {
    defaultTemplate.path = ./template;
    defaultTemplate.description = "nix flake new -t github:cruel-intentions/devshell-files project";
  } // (flake-utils.lib.eachDefaultSystem systemic);
}
