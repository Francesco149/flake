{ ... }:
{
  # only use on machines where security is not important and performance is critical.
  # this makes the cpu vulnerable to many exploits.

  boot.kernelParams = [
    "usbhid.kbpoll=1"
    "usbhid.mousepoll=1"
    "usbhid.jspoll=1"
    "noibrs"
    "noibpb"
    "nopti"
    "nospectre_v2"
    "nospectre_v1"
    "l1tf=off"
    "nospec_store_bypass_disable"
    "no_stf_barrier"
    "mds=off"
    "mitigations=off"
    "tpm.disable_pcr_integrity=on"
  ];

}
