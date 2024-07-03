{
  description = "lolisamurai's personal nixos flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-wsl
    , nixpkgs-mailserver
    , home-manager
    , home-manager-wsl
    , nixos-wsl
    , agenix
    , ...
    }:
    let
      inherit (import ./common/consts.nix) user system;

      pkgs = import nixpkgs {
        inherit system;

        # ideally never enable this
        # find open alternatives to any proprietary software
        #config.allowUnfree = true;

        overlays = [
          (import ./custom-packages.nix)
        ];

        # only used by archivebox, not actually exposed to the internet
        config.permittedInsecurePackages = [
          "python3.11-django-3.1.14"
        ];
      };

      pkgs-mailserver = import nixpkgs-mailserver {
        inherit system;
      };

      pkgs-wsl = import nixpkgs-wsl {
        inherit system;
      };

      optAttrList = with builtins; s: set: if hasAttr s set then getAttr s set else [ ];

      # only used on machines that use home-manager to avoid some duplication

      mkSystem = conf: {
        "${conf.configName}" = conf.nixpkgs.lib.nixosSystem {
          inherit system;
          inherit (conf) pkgs;

          # pass user to modules (configuration.nix for example)
          specialArgs = {
            inherit user nixos-wsl;
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
              home-manager.extraSpecialArgs = {
                inherit user; # pass user to modules in conf (home.nix or whatever)
                configName = conf.configName;
              };
              home-manager.users.${user} = {
                imports = [
                  ./machines/${conf.configName}/home.nix
                ] ++ optAttrList "homeImports" conf;
              };
            }
          ] else [ ]);
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
        hmsys "streampc" unstable //
        hmsys "nixos-wsl-5900x" wsl //

        sys "headpats" mailserver //
        sys "dekai" unstable //

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
