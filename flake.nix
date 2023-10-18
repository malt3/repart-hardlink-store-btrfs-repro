{
  description = "Build fedora image with mkosi";

  inputs = {
    nixpkgsUnstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs =
    { self
    , nixpkgsUnstable
    , flake-utils
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgsUnstable = import nixpkgsUnstable { inherit system; };
      in
      {
        devShells = {
          default = import ./shells/default.nix { pkgs = pkgsUnstable; };
          patched-repart = import ./shells/patched-repart.nix { pkgs = pkgsUnstable; };
        };

        formatter = nixpkgsUnstable.legacyPackages.${system}.nixpkgs-fmt;
      });
}
