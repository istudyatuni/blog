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
            (let
              rev = "86e38439b61cd31c002a7ae5951c947e8630eeae";
            in
              typst.overrideAttrs rec {
                version = "0.14.2-dev";
                # do not forget to update workflows/pages.yaml
                src = pkgs.fetchFromGitHub {
                  owner = "typst";
                  repo = "typst";
                  inherit rev;
                  hash = "sha256-QqIr1HykzRx0UDUg+PWehQNDE/XSZyE6TRfl/Kn0JZc=";
                };
                cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
                  inherit version src;
                  pname = "typst";
                  hash = "sha256-JNBYgk6B31TM0EUw6/6WBmMaYws9YYt3Hwvq8kds8Ak=";
                };
                postPatch = '''';
                preBuild = ''
                  export TYPST_COMMIT_SHA="${rev}"
                '';
                doCheck = false;
                doInstallCheck = false;
              })
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
