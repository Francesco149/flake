{ lib, stdenv, fetchFromGitHub, obs-studio, cmake, qtbase }:

stdenv.mkDerivation rec {
  pname = "obs-multi-rtmp";
  version = "0.6.0.1";

  src = fetchFromGitHub {
    owner = "sorayuki";
    repo = "obs-multi-rtmp";
    rev = version;
    sha256 = "sha256-MRBQY9m6rj8HVdn58mK/Vh07FSm0EglRUaP20P3FFO4="; # 0.6.0.1
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ obs-studio qtbase ];

  cmakeFlags = [
    (lib.cmakeBool "ENABLE_QT" true)
    (lib.cmakeBool "ENABLE_FRONTEND_API" true)
    (lib.cmakeBool "CMAKE_COMPILE_WARNING_AS_ERROR" false)

    (lib.cmakeFeature "CMAKE_CXX_STANDARD" "20")
    (lib.cmakeBool "CMAKE_CXX_STANDARD_REQUIRED" true)
    (lib.cmakeFeature "QT_VERSION" "6")
    (lib.cmakeFeature "CMAKE_BUILD_TYPE" "RelWithDebInfo")
  ];

  patches = [
    # after 0.5.0.3-OBS30, the linux build doesn't install files in the correct location unless
    # we patch them back
    ./fix-build.patch
  ];

  dontWrapQtApps = true;

  meta = with lib; {
    homepage = "https://github.com/sorayuki/obs-multi-rtmp/";
    changelog = "https://github.com/sorayuki/obs-multi-rtmp/releases/tag/${version}";
    description = "Multi-site simultaneous broadcast plugin for OBS Studio";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ jk ];
    platforms = [ "x86_64-linux" "i686-linux" ];
  };
}
