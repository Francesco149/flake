{
  description = "lolisamurai's personal nixos flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-22.05"; # for my mail server
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
      inputs.utils.follows = "flake-utils";
    };

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-22.05";

      # home-manager pins nixpkgs to a specific version in its flake.
      # we want to make sure everything pins to the same version of nixpkgs to be more efficient
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    # TODO: separate each config into its own flake to avoid pulling unnecessary deps? or is nix smart enough
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs-stable";
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

    cubecalc-ui = {
      url = "github:Francesco149/cubecalc-ui";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };

    declarative-cachix.url = "github:jonascarpay/declarative-cachix/master";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    home-manager-stable,
    nixos-wsl,
    agenix,
    agenix-stable,
    emacs-overlay,
    declarative-cachix,
    cubecalc-ui,
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
        (final: prev: { agenix = agenix.defaultPackage.x86_64-linux; })
        emacs-overlay.overlay
        cubecalc-ui.overlay
      ];
    };

    pkgs-stable = import nixpkgs-stable {
      inherit system;
      overlays = [
        emacs-overlay.overlay
      ];
    };

    mkSystem = conf: (
      conf.nixpkgs.lib.nixosSystem {
        inherit system;
        inherit (conf) pkgs;
        specialArgs = { inherit user; inherit nixos-wsl; }; # pass user to modules (configuration.nix for example)
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

      stable = {
        nixpkgs = nixpkgs-stable;
        pkgs = pkgs-stable;
        home-manager = home-manager-stable;
      };

      unstable = {
        inherit nixpkgs pkgs home-manager;
      };

  in {
    nixosConfigurations = {

      nixos-11400f = mkSystem (rec {
        configName = "nixos-11400f"; # TODO: any way to avoid this duplication?
        modules = [
          ./${configName}/configuration.nix
          agenix.nixosModule
        ];
        homeImports = [ ./${configName}/home.nix ];
      } // unstable);

      nixos-wsl-5900x = mkSystem (rec {
        configName = "nixos-wsl-5900x";
        modules = [ ./${configName}/configuration.nix ];
        homeImports = [ ./${configName}/home.nix ];
      } // stable);

      headpats = nixpkgs-stable.lib.nixosSystem rec {
        inherit system;
        specialArgs = { inherit user; };
        pkgs = pkgs-stable;
        modules = [
          ./headpats/configuration.nix
          agenix-stable.nixosModule
        ];
      };

    };

    # use nix-shell or nix develop to access this shell
    devShell.x86_64-linux = pkgs.mkShell {
      packages = [
        pkgs.nixpkgs-fmt
        pkgs.agenix
      ];
    };
  };
}
