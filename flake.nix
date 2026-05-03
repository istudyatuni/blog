{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = (import nixpkgs) {
          inherit system;
        };
        lib = pkgs.lib;
      in {
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            typst
            static-web-server
          ];
          shellHook = ''
            # typst respects this
            unset SOURCE_DATE_EPOCH
          '';
        };
        formatter = pkgs.writeShellScriptBin "alejandra" "exec ${lib.getExe pkgs.alejandra} .";
      }
    );
}
