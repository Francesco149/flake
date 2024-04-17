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

  oneVPL-intel-gpu = callPackage ./pkgs/onevpl-intel-gpu.nix { };
}
