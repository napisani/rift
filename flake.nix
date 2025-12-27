{
  description = "rift - a tiling window manager for macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };

  outputs = { self, nixpkgs, fenix, crane }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;

          # Use stable Rust toolchain from fenix
          toolchain = fenix.packages.${system}.stable.toolchain;
          craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

          root = ./.;

          commonArgs = {
            src = lib.fileset.toSource {
              inherit root;
              fileset = lib.fileset.unions [
                (craneLib.fileset.commonCargoSources root)
                (lib.fileset.fileFilter (file: file.hasExt "plist") root)
              ];
            };
            strictDeps = true;
            doCheck = false;
          };

          cargoArtifacts = craneLib.buildDepsOnly commonArgs;

          rift = craneLib.buildPackage (commonArgs // {
            inherit cargoArtifacts;

            meta = {
              description = "A tiling window manager for macOS";
              homepage = "https://github.com/napisani/rift";
              license = lib.licenses.mit;
              platforms = lib.platforms.darwin;
            };
          });
        in {
          default = rift;
          rift = rift;
        });
    };
}

