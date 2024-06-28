{ pkgs, user, ... }:
{
  nix = {
    package = pkgs.nixVersions.git;
    # keep-* is for direnv
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    settings.trusted-users = [ "root" user ];
  };

  # automatically garbage collect nix store to save disk space
  nix.gc = {
    automatic = true;
    dates = "13:00";
    options = "--delete-older-than 7d";
  };
}
