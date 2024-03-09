{
  description = "A flake for SealOne";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-23.11;
  };

  outputs = { self, nixpkgs, ... }: let 
    system = "x86_64-linux";
  in {
    # See flatpak for comparison
    # https://github.com/flathub/com.seal_one.SealOne/tree/master
    defaultPackage.x86_64-linux =
      with import nixpkgs {
        inherit system;
        # system = "x86_64-linux";
      };
      stdenv.mkDerivation {
        name = "sealone-1.0.0";
        src = fetchurl {
          url = "https://seal-one.com/downloads/SOInstLin.sh";
          hash = "sha256-QGRp4kv1I6r3sqHht9aBtU6BTdPjZcM/5bPiX8SR6Cs=";
        };

        # Unpack archive
        unpackPhase = ''
          tail -n +4 "$src" | tar --no-same-owner -xzf -
          sourceRoot="SealOne"
        '';

        # inherit src;

        # Required for compilation
        nativeBuildInputs = [
          autoPatchelfHook # Automatically setup the loader, and do the magic
        ];

        # Required at running time
        buildInputs = [
          gtk2-x11
        ];

        # Extract and copy executable in $out/bin
        installPhase = ''
          mkdir -p $out/bin
          cp -a x64/. $out/bin/
        '';
      };
    nixosModules.default = { config, lib, nixpkgs, ... } : 
      with lib;
      let
        cfg = config.hochreiner.services.sealone;
        pkgs = import nixpkgs {
          inherit system;
          # system = "x86_64-linux";
        };
      in {
        options.hochreiner.services.sealone = {
          enable = mkEnableOption "Enables the SealOne service";
          rotate = mkOption {
            type = types.bool;
            default = false;
            example = true;
            description = lib.mdDoc "Rotate the display";
          };
          zoom = mkOption {
            type = types.bool;
            default = false;
            example = true;
            description = lib.mdDoc "Zoom the display";
          };
        };
  
        config = mkIf cfg.enable {
          systemd.services."hochreiner.sealone" = {
            serviceConfig = let pkg = self.defaultPackage.x86_64-linux; in {
              ExecStart = "${pkg}/bin/SealOne --nogui ${if cfg.rotate then "--rotate-display" else ""} ${if cfg.zoom then "--toggle-display-zoom" else ""}";
              DynamicUser = true;
            };
          };
          boot.kernelModules = [ "sg" ];
          services.udev.extraRules = ''
            SUBSYSTEMS=="usb", ACTION=="add", ATTRS{idVendor}=="219c", ATTRS{idProduct}=="0010", MODE:="0666", RUN+="${pkgs.systemd}/bin/systemctl start hochreiner.sealone.service"
            SUBSYSTEMS=="usb", ACTION=="remove", ATTRS{idVendor}=="219c", ATTRS{idProduct}=="0010", MODE:="0666", RUN+="${pkgs.systemd}/bin/systemctl stop hochreiner.sealone.service"
          '';
        };      
      };
    devShells."${system}".default = let
      pkgs = import nixpkgs {
        inherit system;
      };
    in pkgs.mkShell {
      packages = with pkgs; [
        yazi
        nushell
        helix
        zellij
      ];
      shellHook = '' 
        zellij --layout zellij.kdl
      '';
    };
  };
}
