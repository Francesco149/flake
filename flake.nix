{
  description = "lolisamurai's personal nixos flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";

      # home-manager pins nixpkgs to a specific version in its flake.
      # we want to make sure everything pins to the same version of nixpkgs to be more efficient
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO: separate each config into its own flake to avoid pulling unnecessary deps? or is nix smart enough
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # agenix allows me to store encrypted secrets in the repo just like git-crypt, except
    # it integrates with nix so I don't need to have world-readable secrets in the nix store.
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      #inputs.flake-utils.follows = "utils";
    };

    declarative-cachix.url = "github:jonascarpay/declarative-cachix/master";
  };

  # TODO: I could do inherit inputs and just have { ... } here, but I don't want to inherit nixpkgs
  outputs = { self, nixpkgs, home-manager, nixos-wsl, agenix, emacs-overlay, declarative-cachix }:
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
      ];
    };

    mkSystem = conf: (
      nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        specialArgs = { inherit user; inherit nixos-wsl; }; # pass user to modules (configuration.nix for example)
        modules = conf.modules ++ [
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true; # instead of having its own private nixpkgs
            home-manager.useUserPackages = true; # install to /etc/profiles instead of ~/.nix-profile
            home-manager.extraSpecialArgs = {
              inherit user; # pass user to modules in conf (home.nix or whatever)
              configName = conf.configName;
            };
            home-manager.users.${user} = {
              imports = [
                declarative-cachix.homeManagerModules.declarative-cachix
              ] ++ conf.homeImports;
            };
          }
        ];
      }
    );

  in {
    nixosConfigurations = {

      nixos-11400f = mkSystem rec {
        configName = "nixos-11400f"; # TODO: any way to avoid this duplication?
        modules = [
          ./${configName}/configuration.nix
          agenix.nixosModule
        ];
        homeImports = [ ./${configName}/home.nix ];
      };

      nixos-wsl-5900x = mkSystem rec {
        configName = "nixos-wsl-5900x";
        modules = [ ./${configName}/configuration.nix ];
        homeImports = [ ./${configName}/home.nix ];
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
