{
  description = "lolisamurai's personal nixos flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-staging.url = "github:nixos/nixpkgs/staging-next";

    # NOTE: remember to update home-manager versions

    nixpkgs-wsl.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-mailserver.url = "github:nixos/nixpkgs/nixos-24.05";

    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager";

      # home-manager pins nixpkgs to a specific version in its flake.
      # we want to make sure everything pins to the same version of nixpkgs to be more efficient
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-wsl = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs-wsl";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs-wsl";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };

    # agenix allows me to store encrypted secrets in the repo just like git-crypt, except
    # it integrates with nix so I don't need to have world-readable secrets in the nix store.
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # this allows querying packages by filename as well as enabling comma, a command line tool
    # that lets me run any package binary with , command even if it's not installed
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-staging
    , nixpkgs-wsl
    , nixpkgs-mailserver
    , home-manager
    , home-manager-wsl
    , nixos-wsl
    , agenix
    , nix-index-database
    , ...
    }:
    let
      inherit (import ./common/consts.nix) user system;

      pkgs = import nixpkgs {
        inherit system;

        # ideally never enable this
        # find open alternatives to any proprietary software
        #config.allowUnfree = true;

        # selectively enable unfree pkgs when absolutely needed
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
          "nvidia-x11"
          "nvidia-settings"
        ];

        overlays = [
          (import ./custom-packages.nix)
        ];

        # NOTE: these are NOT and should NOT be exposed to the internet
        config.permittedInsecurePackages = [
          "python3.12-django-3.1.14" # archivebox
          "olm-3.2.16" # nextcloud
        ];
      };

      pkgs-mailserver = import nixpkgs-mailserver {
        inherit system;
      };

      pkgs-wsl = import nixpkgs-wsl {
        inherit system;
      };

      pkgs-staging = import nixpkgs-staging {
        inherit system;
      };

      optAttrList = with builtins; s: set: if hasAttr s set then getAttr s set else [ ];

      # only used on machines that use home-manager to avoid some duplication

      mkSystem =
        let
          nixIndex = { programs.nix-index-database.comma.enable = true; };
        in
        conf: {
          "${conf.configName}" = conf.nixpkgs.lib.nixosSystem {
            inherit system;
            inherit (conf) pkgs;

            # pass user to modules (configuration.nix for example)
            specialArgs = {
              inherit user nixos-wsl pkgs-staging;
              inherit (conf) configName;
            };

            modules = with builtins; [
              ./machines/${conf.configName}/configuration.nix
              agenix.nixosModules.default
            ] ++
            (optAttrList "modules" conf) ++
            (if hasAttr "hm" conf then [
              conf.home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true; # instead of having its own private nixpkgs
                home-manager.useUserPackages = true; # install to /etc/profiles instead of ~/.nix-profile
                home-manager.backupFileExtension = "backup"; # rename files to .backup if it would overwrite
                home-manager.extraSpecialArgs = {
                  inherit user; # pass user to modules in conf (home.nix or whatever)
                  configName = conf.configName;
                };
                home-manager.users.${user} = {
                  imports = [
                    ./machines/${conf.configName}/home.nix
                    nix-index-database.hmModules.nix-index
                    nixIndex
                  ] ++ optAttrList "homeImports" conf;
                };
              }
            ] else [
              nix-index-database.nixosModules.nix-index
              nixIndex
            ]);
          };
        };

      # these are to be used with mkSystem

      wsl = {
        nixpkgs = nixpkgs-wsl;
        pkgs = pkgs-wsl;
        home-manager = home-manager-wsl;
      };

      unstable = {
        inherit nixpkgs pkgs home-manager;
      };

      mailserver = {
        nixpkgs = nixpkgs-mailserver;
        pkgs = pkgs-mailserver;
      };

      sys = name: conf: mkSystem ({ configName = name; } // conf);
      hmsys = name: conf: mkSystem ({ configName = name; hm = true; } // conf);

    in
    {
      nixosConfigurations =
        hmsys "tanuki" unstable //
        hmsys "streampc-beelink-eq20-pro" unstable //
        hmsys "streampc-7800x3d" unstable //
        hmsys "nixos-wsl-5900x" wsl //

        sys "headpats" mailserver //
        sys "dekai" unstable //

        # dummy config to init a machine for remote rebuilds. also template for new configs
        sys "dummy" unstable //

        { };

      # use nix-shell or nix develop to access this shell
      devShell.x86_64-linux = pkgs.mkShell {
        packages = [
          pkgs.nixpkgs-fmt
          agenix.packages.x86_64-linux.default
        ];
      };
    };
}
