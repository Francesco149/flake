# https://github.com/NixOS/nixpkgs/pull/264621/
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libdrm, libva }:

stdenv.mkDerivation rec {
  pname = "onevpl-intel-gpu";
  version = "23.4.3";

  outputs = [ "out" "dev" ];

  src = fetchFromGitHub {
    owner = "oneapi-src";
    repo = "oneVPL-intel-gpu";
    rev = "intel-onevpl-${version}";
    sha256 = "sha256-oDwDMUq6JpRJH5nbANb7TJLW7HRYA9y0xZxEsoepx/U=";
  };

  nativeBuildInputs = [ cmake pkg-config ];

  buildInputs = [ libdrm libva ];

  meta = {
    description = "oneAPI Video Processing Library Intel GPU implementation";
    homepage = "https://github.com/oneapi-src/oneVPL-intel-gpu";
    changelog = "";
    license = [ lib.licenses.mit ];
    platforms = lib.platforms.linux;
    # CMake adds x86 specific compiler flags in <source>/builder/FindGlobals.cmake
    # NOTE: https://github.com/oneapi-src/oneVPL-intel-gpu/issues/303
    broken = !stdenv.hostPlatform.isx86;
    maintainers = [ lib.maintainers.evanrichter ];
  };
}
