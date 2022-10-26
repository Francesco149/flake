let
  loli = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpNgs8JFiW2okM8bWoQXkXD6y3x1LONA3hNQbUmvJhMK8BP7Ajkd5avC0dhyOnHee1WCoiQfCfqN/2SVgHMDmRv2QNluciZ4scFr1IwXRxrUqRPpDid6bBIc/e7PYcFBfA2r1nfOdZTePiQcQAcb0yhblqtsg9aOgl+JwqK4GvoQgwriB3Hp6PrezRYBcQjjLbcrU8U1vqKCljhL/cYy5qj5ybJ4hRYcsuZoiQxjtomlrsmibVcTJZVnwPL3DVhCcNrPYABstVgLZfLSttCQCdB2VvGJOx5r6gaB8bkgHsqgERyZza4hBYsMPLSuzxrxgEH+AZzTBGIZiWD0WgY+81";
  headpats = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4j6+dF+4xogE9C7/1Cm67AGslsOPEzCZm8j6WfbEoe7FK1tD3bV9ACjr7mgeCHurKv3IRLZuoQjkyp17c2LwW8hnz0evBnemgrQ3GrTEbYsPl4yJoAuBUdL7HU1DLoq6SlgNxy1lxn5FM5s5t8FH37yFqkvmt6zRoIqsQQ67lBduiNe9wlqskND8t5pckBsNkhot4Otv+Hetpm2lbB+hCo4FLrINZg/dBY5fsngOl5pFw8/Nu+/BdTLluyRgqQEbjFk7mf8AUU530GozTdszGR3gSHOd9vDKOLPWC+HodnV34glUIuTzPCsP7km/oXEDcyWpz2+dJYwsXNLIlRav1qPQ2W2PIduhCeN8NtV3lu2B6h/td+zgkfLkSCxpRokaSsnJCtYhX1GQTEFhWB35QiCwcHzjLf1367ufIrmbdjG1qalqsC0berLG885+Up2L0fFvOp2tH70zR9trTXVi3nnmvKpqamV7yFPClkEGa96hboH4NzIXZit/00LrsDjU= root@headpats";
  users = [ loli ];
  headpatUsers = [ headpats ];
in {
  "gh2md/token.age".publicKeys = users;
  "gist/token.age".publicKeys = users;
  "dendrite-keys/matrix_key.pem.age".publicKeys = users;
  "synapse/homeserver.signing.key.age".publicKeys = users;
  "synapse/secrets.yaml.age".publicKeys = users;
  "grafana/password.age".publicKeys = users;
  "grafana/secret-key.age".publicKeys = users;
  "cloudflare/password.age".publicKeys = users;
  "matterbridge/config.toml.age".publicKeys = users;
  "headpats/loli-hashed-password.age".publicKeys = headpatUsers;
}
