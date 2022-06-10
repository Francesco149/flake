{
  description = "lolisamurai's personal nixos flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # updated more frequently than home-manager's fork
    };
    nurpkgs = {
      url = github:nix-community/NUR;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    loli.url = "git+ssh://git@github.com/Francesco149/nur-packages.git";
  };

  outputs = { self, nixpkgs, home-manager, nurpkgs, loli }:
  let
    user = "loli";
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ nurpkgs.overlay ];
    };
    nur = import nurpkgs {
      inherit pkgs;
      nurpkgs = pkgs;
      repoOverrides = { loli = import loli { inherit pkgs; }; };
    };
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit user; inherit nur; };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit user; inherit nur; };
            home-manager.users.${user} = {
              imports = [ ./home.nix ];
            };
          }
        ];
      };
    };
  };
}
