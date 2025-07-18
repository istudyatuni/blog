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
            (typst.overrideAttrs rec {
              version = "0.13.1-dev";
              src = pkgs.fetchFromGitHub {
                owner = "typst";
                repo = "typst";
                rev = "b790c6d59ceaf7a809cc24b60c1f1509807470e2";
                hash = "sha256-+0Gye1zwBQ0rGgX/3tM7hrOaH66peo2ssjc6xNTO84M=";
              };
              cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
                inherit version src;
                pname = "typst";
                hash = "sha256-fWi7rPh3BYrqRHoWhCE3SgR+bETfFZlJYCGRbASJhzk=";
              };
              doCheck = false;
            })
            static-web-server
          ];
        };
        formatter = pkgs.writeShellScriptBin "alejandra" "exec ${lib.getExe pkgs.alejandra} .";
      }
    );
}
