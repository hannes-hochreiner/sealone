export def deploy [] {
  let staging = $"/tmp/sealone-staging-(random uuid)"

  mkdir $staging

  # copy required files to staging
  mkdir $"($staging)/opt/sealone"
  
  cp ./flake.nix $"($staging)/opt/sealone/"
  cp ./sealone.tar.gz $"($staging)/opt/sealone/"

  # deploy the configuration and data
  ^tar $"--directory=($staging)" --create --owner=root --group=root . | ssh charon tar --directory=/ --extract
  rm -r $staging
}