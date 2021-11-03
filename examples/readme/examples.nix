''
  ## Examples

  Creating JSON, TEXT, TOML or YAML files

  ```nix
  ${builtins.readFile ../hello.nix}
  ```

  Your file can be complemented with another file

  ```nix
  ${builtins.readFile ../world.nix}
  ```

  Content generated by those examples are in [generated](./generated/)

  ```YAML
  # ie ./generated/hello.yaml
  ${builtins.readFile ../../generated/hello.yaml}
  ```

  ### Dogfooding

  This project is configured by module [project.nix](./project.nix)

  ```nix
  # ./project.nix
  ${builtins.readFile ../../project.nix}
  ``

  This README.md is also a module defined as above

  ```nix
  ${builtins.readFile ../readme.nix}
  ```

  Fun fact: it import [examples.nix](./examples/readme/examples.nix)
  that also include [readme.nix](./examples/readme.nix), as we can see above


  ### Configuration Example

  To integrate it with existing project

  Copy files of [template](./template/) to your project

  ```nix
  # flake.nix
  ${builtins.readFile ../../template/flake.nix}
  ```

  ```nix
  # my-project-module.nix
  ${builtins.readFile ../../template/my-project-module.nix}
  ```
''
