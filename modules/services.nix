{pkgs, config, lib, ...}:
let
  mkS6Run  = name: {
    name  = "/.data/services/${name}/run";
    value.executable = true;
    value.text       = ''
      #!/usr/bin/env sh
      exec 2>&1
      exec ${name}
    '';
  };
  mkS6Log  = name: {
    name  = "/.data/services/${name}/log/run";
    value.executable = true;
    value.text       = ''
      #!/usr/bin/env sh
      exec 2>&1
      exec s6-log -b n4 s100000 $PRJ_DATA_DIR/log/${name}/
    '';
  };
  mkS6Stop = name: {
    name  = "/.data/services/${name}/finish";
    value.executable = true;
    value.text       = ''
      #!/usr/bin/env sh
      exec 2>&1
      exec ${name}-finish || true
    '';
  };
  rmS6Srv  = name: {
    name  = "00-rm-service-${name}-file";
    value.text = "rm -rf $PRJ_DATA_DIR/services/${name}";
  };
  mkLogDir = name: {
    name  = "00-add-service-${name}-log-dir";
    value.text = "mkdir -p $PRJ_DATA_DIR/log/${name}";
  };
  mkS6Runs = names: builtins.listToAttrs (map mkS6Run  names);
  mkS6Logs = names: builtins.listToAttrs (map mkS6Log  names);
  mkS6Ends = names: builtins.listToAttrs (map mkS6Stop names);
  rmS6Srvs = names: builtins.listToAttrs (map rmS6Srv  names);
  mkS6Dirs = names: builtins.listToAttrs (map mkLogDir names);
  filtSrvs = boole: lib.filterAttrs (n: v: n != "s6" && v == boole);
  liveSrvs = builtins.attrNames (filtSrvs true  config.files.services);
  deadSrvs = builtins.attrNames (filtSrvs false config.files.services);
  initSrvs = ''
    s6-svscan       $PRJ_DATA_DIR/services &> \
      $PRJ_ROOT/.data/services/scan-errors.log &
  '';
  scanSrvs = ''
    s6-svscanctl -h $PRJ_DATA_DIR/services &> \
      $PRJ_ROOT/.data/services/sctl-errors.log
  '';
  stopSrvs = ''
    s6-svscanctl -t $PRJ_DATA_DIR/services
  '';
  stUpSrvs = lib.optionalAttrs haveSrvs { 
    "zzzzzz-ssssss-start".text = "scanSrvs" + lib.optionalString autoSrvs "|| initSrvs &";
  };
  haveSrvs = builtins.length liveSrvs > 0;
  autoSrvs = haveSrvs && config.files.services.s6 or false;
in
{
  options.files.services = lib.mkOption {
    default       = {};
    example.hello = true;
    type          = lib.types.attrsOf lib.types.bool;
    description   = ''
      Service name/command to enable

      {name} must be a executable command that runs forever.

      's6' is a special name to auto start [s6](http://skarnet.org/software/s6/)
      our process supervisor, it control all other services.

      If you don't set s6 service, we could start it running `initSrvs`

      Optionally could exist a {name}-finish command to stop it properly

      See [S6 documentation](http://skarnet.org/software/s6/s6-supervise.html)

      You can use config.files.alias to help you create your services scripts

      examples:

      Create your own service with bash

      ```nix
      {
        # Make S6 start when you enter in shell
        files.services.s6    = true;

        # Use hello configured below as service
        files.services.hello = true;

        # Creates an hello command in terminal
        files.alias.hello    = ${"''"}
          while :
          do
            echo "Hello World!"
          	sleep 60
          done
        ${"''"};
      }
       ```

      Use some program as service

      Configure httplz (http static server) as service

      ```nix
      ${builtins.readFile ../examples/services.nix}
      ```

      Know bugs:
      - S6 wont stop by itself, 
        - run `stopSrvs` when it's done
      - Turning off service by removing its entry may not work
        - please set it to false at least once
        - or remove all .data/services directory
    '';
  };
  config.files.alias.stopSrvs = lib.mkIf haveSrvs stopSrvs;
  config.files.alias.initSrvs = lib.mkIf haveSrvs initSrvs;
  config.files.alias.scanSrvs = lib.mkIf haveSrvs scanSrvs;
  config.devshell.packages    = lib.mkIf haveSrvs [ pkgs.s6 ];
  config.devshell.startup     = stUpSrvs // (rmS6Srvs deadSrvs) // (mkS6Dirs liveSrvs);
  config.file = (mkS6Runs liveSrvs) // (mkS6Logs liveSrvs) // (mkS6Ends liveSrvs);
}
