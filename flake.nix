{
  description = "lolisamurai's personal nixos flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # NOTE: remember to update home-manager versions

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05"; # for servers
    nixpkgs-wsl.url = "github:nixos/nixpkgs/nixos-22.11"; # nixos-wsl lags behind

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

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-22.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    home-manager-wsl = {
      url = "github:nix-community/home-manager/release-22.05";
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

    agenix-stable = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    declarative-cachix.url = "github:jonascarpay/declarative-cachix/master";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    nixpkgs-wsl,
    home-manager,
    home-manager-stable,
    home-manager-wsl,
    nixos-wsl,
    agenix,
    agenix-stable,
    emacs-overlay,
    declarative-cachix,
    ...
  }:
  let
    user = "loli";
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (import ./custom-packages.nix)
        emacs-overlay.overlay
      ];
    };

    pkgs-stable = import nixpkgs-stable {
      inherit system;
    };

    pkgs-wsl = import nixpkgs-wsl {
      inherit system;
    };

    # only used on machines that use home-manager to avoid some duplication

    mkSystem = conf: (
      conf.nixpkgs.lib.nixosSystem {
        inherit system;
        inherit (conf) pkgs;

        # pass user to modules (configuration.nix for example)
        specialArgs = { inherit user nixos-wsl meidoLocalIp; };

        modules = conf.modules ++ [
          conf.home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true; # instead of having its own private nixpkgs
            home-manager.useUserPackages = true; # install to /etc/profiles instead of ~/.nix-profile
            home-manager.extraSpecialArgs = {
              inherit user; # pass user to modules in conf (home.nix or whatever)
              configName = conf.configName;
            };
            home-manager.users.${user} = {
              imports = [
                declarative-cachix.homeManagerModules.declarative-cachix-experimental
              ] ++ conf.homeImports;
            };
          }
        ];
      }
    );

    # these are to be used with mkSystem

    stable = {
      nixpkgs = nixpkgs-stable;
      pkgs = pkgs-stable;
      home-manager = home-manager-stable;
    };

    wsl = {
      nixpkgs = nixpkgs-wsl;
      pkgs = pkgs-wsl;
      home-manager = home-manager-wsl;
    };

    unstable = {
      inherit nixpkgs pkgs home-manager;
    };

    meidoLocalIp = "192.168.1.11";

  in {
    nixosConfigurations = {

      # main desktop machine. low power draw
      tanuki = mkSystem (rec {
        configName = "tanuki"; # TODO: any way to avoid this duplication?
        modules = [
          ./${configName}/configuration.nix
          agenix.nixosModules.default
        ];
        homeImports = [ ./${configName}/home.nix ];
      } // unstable);

      # beefier desktop, mostly used to back up to my zfs array
      nixos-11400f = mkSystem (rec {
        configName = "nixos-11400f";
        modules = [
          ./${configName}/configuration.nix
          agenix.nixosModules.default
        ];
        homeImports = [ ./${configName}/home.nix ];
      } // unstable);

      # wsl on my windows machine
      nixos-wsl-5900x = mkSystem (rec {
        configName = "nixos-wsl-5900x";
        modules = [ ./${configName}/configuration.nix ];
        homeImports = [ ./${configName}/home.nix ];
      } // wsl);

      #
      # servers
      # NOTE: avoid having complex dependencies in these. a bit of code duplication is fine.
      #       we don't want to randomly break stuff changing some other machine's config.
      #

      # mail server
      headpats = nixpkgs-stable.lib.nixosSystem rec {
        inherit system;
        pkgs = pkgs-stable;
        modules = [
          ./headpats/configuration.nix
          agenix-stable.nixosModules.default
        ];
      };

      # home server (matrix and other stuff)
      # this is a low power x86_64 mini-pc (fujitsu esprimo). draws 7-10w idle
      meido = nixpkgs-stable.lib.nixosSystem rec {
        inherit system;
        specialArgs = { inherit user meidoLocalIp; };
        pkgs = pkgs-stable;
        modules = [
          ./meido/configuration.nix
          agenix-stable.nixosModules.default
        ];
      };

      # streaming beelink minipc
      # configured with jack for fancy audio routing
      # draws 7-10w idle
      # keep this isolated from all other configs, must be as stable as possible
      streampc = nixpkgs.lib.nixosSystem rec {
        inherit system pkgs;
        specialArgs = { inherit user; };
        modules = [
          ./streampc/configuration.nix
        ];
      };

    };

    # use nix-shell or nix develop to access this shell
    devShell.x86_64-linux = pkgs.mkShell {
      packages = [
        pkgs.nixpkgs-fmt
      ];
    };
  };
}
