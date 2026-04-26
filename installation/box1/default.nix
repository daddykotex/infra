let
  domain = "box1.davidfrancoeur.com";
in
{
  imports = [ ../modules/nginx.nix ../modules/acme.nix ];

  services.myAcme = {
    enable = true;
    email = "info@davidfrancoeur.com";
    nginxGroup = "box1";
    domains = [ domain ];
  };

  services.myNginx = {
    enable = true;
    user = "box1";
    group = "box1";
    virtualHosts = {
      ${domain} = {
        useACMEHost = domain;
        forceSSL = true;
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
