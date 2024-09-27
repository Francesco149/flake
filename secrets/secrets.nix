let

  keys = (import ../common/consts.nix).ssh.keys;

  headpatUsers = [ keys.tanuki keys.headpats ];
  desktopUsers = [ keys.tanuki ];
  streampcUsers = [ keys.tanuki keys.streampc ];
  dekaiUsers = [ keys.tanuki keys.dekai ];
in
{
  "gh2md/token.age".publicKeys = desktopUsers;
  "gist/token.age".publicKeys = desktopUsers;
  "chatterino/settings.json.age".publicKeys = desktopUsers;
  "protonvpn/creds.txt.age".publicKeys = desktopUsers;
  "protonvpn/config.ovpn.age".publicKeys = desktopUsers;
  "barrier/BarrierTanuki.pem.age".publicKeys = desktopUsers;

  "grafana/password.age".publicKeys = dekaiUsers;
  "grafana/secret-key.age".publicKeys = dekaiUsers;
  "cloudflare/password.age".publicKeys = dekaiUsers;
  "matterbridge/config.toml.age".publicKeys = dekaiUsers;
  "nextcloud/password.age".publicKeys = dekaiUsers;
  "nginx/nginx-selfsigned.crt.age".publicKeys = dekaiUsers;
  "nginx/nginx-selfsigned.key.age".publicKeys = dekaiUsers;

  "headpats/tanuki-hashed-password.age".publicKeys = headpatUsers;

  "barrier/Barrier.pem.age".publicKeys = streampcUsers;
  "chatterino/overlay.json.age".publicKeys = streampcUsers;
  "obs/profiles/stream1536x864/basic.ini.age".publicKeys = streampcUsers;
  "obs/profiles/stream1536x864/streamEncoder.json.age".publicKeys = streampcUsers;
  "obs/profiles/stream1536x864/service.json.age".publicKeys = streampcUsers;
  "obs/profiles/stream1536x864/obs-multi-rtmp.json.age".publicKeys = streampcUsers;
  "obs/scenes/streamscenes.json.age".publicKeys = streampcUsers;
  "obs/streampc-global.ini.age".publicKeys = streampcUsers;
}
