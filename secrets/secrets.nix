let

  keys = (import ../common/consts.nix).ssh.keys;

  meidoUsers = [ keys.tanuki keys.meido ];
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

  "dendrite-keys/matrix_key.pem.age".publicKeys = dekaiUsers;
  "synapse/homeserver.signing.key.age".publicKeys = dekaiUsers;
  "synapse/secrets.yaml.age".publicKeys = dekaiUsers;
  "grafana/password.age".publicKeys = dekaiUsers;
  "grafana/secret-key.age".publicKeys = dekaiUsers;
  "cloudflare/password.age".publicKeys = dekaiUsers;
  "matterbridge/config.toml.age".publicKeys = dekaiUsers;

  "headpats/tanuki-hashed-password.age".publicKeys = headpatUsers;

  "barrier/Barrier.pem.age".publicKeys = streampcUsers;
  "chatterino/overlay.json.age".publicKeys = streampcUsers;
}
