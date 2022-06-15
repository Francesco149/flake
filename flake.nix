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
  };

  outputs = { self, nixpkgs, home-manager, nixos-wsl }:
  let
    user = "loli";
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (import ./custom-packages.nix)
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
            home-manager.users.${user} = { imports = conf.homeImports; };
          }
        ];
      }
    );

  in {
    nixosConfigurations = {

      nixos-11400f = mkSystem {
        configName = "nixos-11400f"; # TODO: any way to avoid this duplication?
        modules = [./config-11400f.nix ];
        homeImports = [ ./home.nix ];
      };

      nixos-wsl-5900x = mkSystem {
        configName = "nixos-wsl-5900x";
        modules = [ ./config-wsl-5900x.nix ];
        homeImports = [ ./home.nix ];
      };

    };

    # use nix-shell or nix develop to access this shell
    devShell.x86_64-linux = pkgs.mkShell {
      packages = [
        pkgs.nixpkgs-fmt
        pkgs.git-crypt
      ];
    };
  };
}
