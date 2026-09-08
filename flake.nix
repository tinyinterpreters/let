{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ti.url = "github:tinyinterpreters/nix";
  };

  outputs = { self, nixpkgs, flake-utils, ti }:
    flake-utils.lib.eachDefaultSystem(system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        mkElmShell = ti.lib.mkElmShell pkgs;
      in
      {
        devShells.default = mkElmShell {
          name = "let";
        };
      }
    );
}
