{
  imports = [ ../modules/nginx.nix ];

  services.myNginx = {
    enable = true;
    user = "box1";
    group = "box1";
    virtualHosts = {
      "_" = {
        locations."/" = {
          extraConfig = ''
            return 200 "<p>it works</p>";
            add_header Content-Type text/html;
          '';
        };
      };
    };
  };
}
