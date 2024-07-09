{ user, ... }:
{
  services.getty.autologinUser = user;

  services.displayManager = {
    autoLogin.enable = true;
    autoLogin.user = user;
  };

  # workaround for race condition in autologin
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
}
