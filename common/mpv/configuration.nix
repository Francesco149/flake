{ config, pkgs, lib, user, ... }:
let
  mpv-unwrapped-custom = (pkgs.mpv-unwrapped.override {
    jackaudioSupport = true;
  });

  mpv-custom = (mpv-unwrapped-custom.wrapper {
    mpv = mpv-unwrapped-custom;

    scripts = [

      (pkgs.mpvScripts.sponsorblock-minimal.overrideAttrs (old: rec {
        preInstall =
          let

            # customize categories to be skipped here

            categoriesStr = (lib.strings.concatMapStringsSep "," (x: ''\"${x}\"'') [
              "sponsors"
              #"intro"
              #"outro"
              "interaction"
              #"selfpromo"
              #"filler"
              "music_offtopic"
            ]);

          in
          ''
            ${old.preInstall}

            substituteInPlace sponsorblock_minimal.lua \
              --replace-fail "categories = '\"sponsor\"'," "categories = '${categoriesStr}',"
          '';
      }))

    ];
  });

in
{

  users.users."${user}".packages = with pkgs; [
    yt-dlp
    mpv-custom
  ];

}
