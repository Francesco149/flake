let
  inherit ((import ../common/consts.nix).ssh.keys) loli headpats meido streampc;
  meidoUsers = [ loli meido ];
  headpatUsers = [ loli headpats ];
  desktopUsers = [ loli ];
  streampcUsers = [ loli streampc ];
in
{
  "gh2md/token.age".publicKeys = desktopUsers;
  "gist/token.age".publicKeys = desktopUsers;
  "chatterino/settings.json.age".publicKeys = desktopUsers;
  "protonvpn/creds.txt.age".publicKeys = desktopUsers;
  "protonvpn/config.ovpn.age".publicKeys = desktopUsers;
  "barrier/BarrierTanuki.pem.age".publicKeys = desktopUsers;

  "dendrite-keys/matrix_key.pem.age".publicKeys = meidoUsers;
  "synapse/homeserver.signing.key.age".publicKeys = meidoUsers;
  "synapse/secrets.yaml.age".publicKeys = meidoUsers;
  "grafana/password.age".publicKeys = meidoUsers;
  "grafana/secret-key.age".publicKeys = meidoUsers;
  "cloudflare/password.age".publicKeys = meidoUsers;
  "matterbridge/config.toml.age".publicKeys = meidoUsers;

  "headpats/loli-hashed-password.age".publicKeys = headpatUsers;

  "barrier/Barrier.pem.age".publicKeys = streampcUsers;
  "chatterino/overlay.json.age".publicKeys = streampcUsers;
}
