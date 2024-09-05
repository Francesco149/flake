{ ... }:
let
  consts = import ../consts.nix;
in
  {
    networking.hosts = with builtins; (listToAttrs
      (map
        (x: {
          name = x.ip;
          value = attrValues x.domains;
        })
        (filter (x: x ? "ip" && x ? "domains")
         (attrValues consts.machines))
      )
    );
}
