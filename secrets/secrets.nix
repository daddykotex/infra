let
  # keys to encrypts
  dfrancoeur = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxDLOoi5qM5kz3g9HMTsNE5WPWxNo8LUpvO1QBEBKDe43gjHUcjpMMgedPWT2ShPeOiB4B7CXpiq+MoQrdM/LzR1FQstaGfIo0pwhFYLXTnPHtZg3yxVV9AjgHMyyXIwkfubtjCj9DY0y2n3IFZTxXgM+67MSGptAJHVRqNDCia//hIF8PB6/7QnGPycMSQ3DViVCE33DBNHvj2j2ywHmma5vsK15NLynXP3dBNOdv4a/dsAg+MjOvdq5Tv/EDV3V3hrDrjxFGpXUI3OAovmxeiWH7WDB2NdJj2BEfRF+hKgMAoAiLb6pNXC8rvwZ5V3m9oP7JKcfgnvEljI/KA7kDq5o5n0fEMtoARQvPP6mnicnoGyJhP8us69WI5Z8HgYbR5g325ZfWWixveiqn2ZZPKvY9+Uk6tkjIOkJWFStEHmc5uh0EbLSqmGXlVw2QyEmUDcZ4H/4JqIpm7i5VedZpUN6gG5RaGvDuV9rslfxcAgmsQ0W93un9X1YYohomcAzhQNYeVutYpHiokOXuMtsSz9OgDcxTK3vYIHscNl6QcV8PqmdlP11e4VCXItOjLddAc1gsFFQ5IfTHkZ4aqqgY1Tdl6vxFI8dPt0dyA3LCLu9mgWr7J4Ev4IdQP00AKAPf/uTCX2Bk0eR50StEQWxez7m16zCll/gDOECCjVU2yw==";

  # target systems
  box1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpBdCFDihFhTDcAOt99DzSvt2tekKiXKh79v/9J/BJL";
  rasp1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZVzcXNTvrkP+ouwgZu57xw6xqWaWoX4KvrNpVcukxx";
in
{
  "lmah-env.age".publicKeys = [ dfrancoeur box1 ];
  "lmah-calendar-gcp-sa-key-json.age".publicKeys = [ dfrancoeur box1 ];
  "rasp1-wifi-password.age".publicKeys = [ dfrancoeur rasp1 ];
  # "rasp1-ssh-private-key.age" is meant to be loaded manually on the raspberry pi

  "armored-secret.age" = {
    publicKeys = [ dfrancoeur ];
    armor = true;
  };
}