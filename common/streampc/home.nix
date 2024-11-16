{ config, pkgs, user, configName, lib, ... }:
with config; {
  imports = [
    ../gnome/home.nix
    ../xterm/home.nix
    ../vim/home.nix
  ];

  home.username = "${user}";
  home.homeDirectory = "/home/${user}";

  xdg.dataFile."chatterino/Settings/window-layout.json".source = ./chatterino/overlay-window-layout.json;
  home.file."stream-linux.carxp".source = ./carla/stream-linux.carxp;
  home.file."cam.gpfl".source = ./guvcviewer/cam.gpfl;

  xdg.configFile."falkTX/Carla2.conf".text = ''
    [General]
    DiskFolders=@Variant(\0\0\0\t\0\0\0\x1\0\0\0\n\0\0\0\x14\0/\0h\0o\0m\0\x65\0/\0l\0o\0l\0i)
    Geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\0\0\0\0 \0\0\x5U\0\0\x2\xff\0\0\0\xac\0\0\0\xc2\0\0\x4\xab\0\0\x3\x10\0\0\0\0\x2\0\0\0\x5V\0\0\0\0\0\0\0\x45\0\0\x5U\0\0\x2\xff)
    HorizontalScrollBarValue=67
    LastBPM=0
    ShowKeyboard=true
    ShowMeters=true
    ShowSidePanel=true
    ShowToolbar=true
    VerticalScrollBarValue=38

    [Canvas]
    Antialiasing=0
    AutoHideGroups=true
    AutoSelectItems=false
    EyeCandy2=false
    FancyEyeCandy=false
    FullRepaints=false
    HQAntialiasing=false
    InlineDisplays=false
    Size=6200x4800
    Theme=Modern Dark
    UseBezierLines=true
    UseOpenGL=false

    [Engine]
    AudioDriver=JACK
    Driver-JACK\BufferSize=0
    Driver-JACK\Device=Auto-Connect ON
    Driver-JACK\SampleRate=0
    Driver-JACK\TripleBuffer=false
    Driver-PulseAudio\BufferSize=512
    Driver-PulseAudio\Device=PulseAudio
    Driver-PulseAudio\SampleRate=44100
    Driver-PulseAudio\TripleBuffer=false
    ForceStereo=false
    ManageUIs=true
    MaxParameters=200
    PreferPluginBridges=false
    PreferUiBridges=true
    ProcessMode=3
    ResetXruns=false
    TransportExtra=
    TransportMode=1
    UIsAlwaysOnTop=false
    UiBridgesTimeout=4000

    [Experimental]
    ExportLV2=false
    JackApplications=false
    LoadLibGlobal=false
    PluginBridges=false
    PreventBadBehaviour=false
    WineBridges=false

    [Main]
    ClassicSkin=false
    ConfirmExit=true
    Experimental=false
    ProThemeColor=Black
    ProjectFolder=/home/${user}
    RefreshInterval=20
    ShowLogs=true
    SystemIcons=false
    UseProTheme=true

    [OSC]
    Enabled=true
    TCPEnabled=true
    TCPNumber=22752
    TCPRandom=false
    UDPEnabled=true
    UDPNumber=22752
    UDPRandom=false

    [Paths]
    Audio=@Invalid()
    DSSI=/home/${user}/.dssi, /usr/lib/dssi, /usr/local/lib/dssi
    JSFX=@Variant(\0\0\0\t\0\0\0\x1\0\0\0\n\0\0\0\x42\0/\0h\0o\0m\0\x65\0/\0l\0o\0l\0i\0/\0.\0\x63\0o\0n\0\x66\0i\0g\0/\0R\0\x45\0\x41\0P\0\x45\0R\0/\0\x45\0\x66\0\x66\0\x65\0\x63\0t\0s)
    LADSPA=/home/${user}/.ladspa, /usr/lib/ladspa, /usr/local/lib/ladspa
    LV2=/home/${user}/.lv2, ${pkgs.bolliedelayxt-lv2}/lib/lv2, /usr/lib/lv2, /usr/local/lib/lv2
    MIDI=@Invalid()
    SF2=/home/${user}/.sounds/sf2, /home/${user}/.sounds/sf3, /usr/share/soundfonts, /usr/share/sounds/sf2, /usr/share/sounds/sf3
    SFZ=/home/${user}/.sounds/sfz, /usr/share/sounds/sfz
    VST2=/home/${user}/.vst, /usr/lib/lxvst, /usr/lib/vst, /usr/local/lib/lxvst, /usr/local/lib/vst/home/${user}/.lxvst
    VST3=/home/${user}/.vst3, /usr/lib/vst3, /usr/local/lib/vst3

    [Wine]
    AutoPrefix=true
    BaseRtPrio=15
    Executable=wine
    FallbackPrefix=/home/${user}/.wine
    RtPrioEnabled=true
    ServerRtPrio=10
  '';
}
