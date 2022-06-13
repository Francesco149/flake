# nixpkgs overlay that adds my custom packages

self: super: with super; {

  self.maintainers = super.maintainers.override {
    lolisamurai = {
      email = "lolisamurai@animegirls.xyz";
      github = "Francesco149";
      githubId = 973793;
      name = "Francesco Noferi";
    };
  };

  chatterino7 = chatterino2.overrideAttrs (old: rec {
    pname = "chatterino7";
    version = "7.3.5";
    src = fetchFromGitHub {
      owner = "SevenTV";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-lFzwKaq44vvkbVNHIe0Tu9ZFXUUDlWVlNXI40kb1GEM=";
      fetchSubmodules = true;
    };
    # required for 7tv emotes to be visible
    # TODO: is this robust? in an actual package definition we wouldn't have qt5,
    #       but just self.qtimageformats doesn't work. what if qt version changes
    buildInputs = old.buildInputs ++ [ self.qt5.qtimageformats ];
    meta.description = old.meta.description + ", with 7tv emotes";
    meta.homepage = "https://github.com/SevenTV/chatterino7";
    meta.changelog = "https://github.com/SevenTV/chatterino7/releases";
  });

  pxplus-ibm-vga8-bin = let
    pname = "pxplus-ibm-vga8-bin";
    bname = "PxPlus_IBM_VGA8";
    ttfname = "${bname}.ttf";
    fname = "${bname}.otf";
  in stdenv.mkDerivation {
    pname = pname;
    version = "2022-06-02-r8";
    src = fetchFromGitHub {
      owner = "pocketfood";
      repo = "Fontpkg-PxPlus_IBM_VGA8";
      rev = "bf08976574bbaf4c9efb208025c71109a07e259f";
      sha256 = "sha256-WMNqehxLBeo4YC8QrH/UFSh3scvs7oAAPenPhyJ+UVA=";
    };
    nativeBuildInputs = [ pkgs.fontforge ];
    buildPhase = ''
      runHook preBuild
      fontforge -lang=py -c "import fontforge; from sys import argv; \
        f = fontforge.open(argv[1]); f.generate(argv[2]);" "${ttfname}" "${fname}"
      runHook postBuild
    '';
    installPhase = ''
      install -Dm 444 "${fname}" "$out/share/fonts/truetype/${pname}.otf"
    '';

    meta = with lib; {
      description = "monospace pixel font";
      homepage = "https://int10h.org/oldschool-pc-fonts/fontlist/font?ibm_vga_8x16";
      license = with licenses; [ cc-by-sa-40 ];
      platforms = platforms.all;
      maintainers = with maintainers; [ lolisamurai ];
    };
  };

}
