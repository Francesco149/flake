{ ... }:
let
  consts = import ../consts.nix;
in
{
    networking.hosts = {
      "${consts.machines.dekai.ip}" = ["office.local" "cloud.local"];
    };
}
