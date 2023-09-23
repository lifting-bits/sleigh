{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    treefmt-nix,
  }:
    {
      overlays.default = final: prev: {
        ghidra = with final;
          applyPatches {
            src = fetchFromGitHub {
              owner = "NationalSecurityAgency";
              repo = "ghidra";
              rev = "refs/tags/Ghidra_10.3.3_build";
              sha256 = "sha256-KDSiZ/JwAqX6Obg9UD8ZQut01l/eMXbioJy//GluXn0=";
            };
            patches = [
              ./src/patches/stable/0001-Fix-UBSAN-errors-in-decompiler.patch
              ./src/patches/stable/0002-Use-stroull-instead-of-stroul-to-parse-address-offse.patch
            ];
          };

        sleigh = with final;
          stdenv.mkDerivation {
            name = "sleigh";
            src = ./.;
            nativeBuildInputs = [
              cmake
              ninja
              git
            ];
            buildInputs = [
              ghidra
            ];
            cmakeFlags = [
              "-DFETCHCONTENT_SOURCE_DIR_GHIDRASOURCE=${ghidra}"
            ];
          };
        sleigh-debug = with final;
          final.sleigh.overrideAttrs (o: {
            dontStrip = true;
            enableDebugging = true;
            separateDebugInfo = true;
          });
        sleigh-asan = with final;
          final.sleigh-debug.overrideAttrs (o: {
            cmakeFlags = o.cmakeFlags ++ ["-DCMAKE_C_FLAGS=-fsanitize=address" "-DCMAKE_CXX_FLAGS=-fsanitize=address"];
          });
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        };
      in {
        packages.default = pkgs.sleigh;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            sleigh-asan
            clang-tools
          ];
        };
        formatter = treefmt-nix.lib.mkWrapper pkgs {
          projectRootFile = ".git/config";
          programs = {
            alejandra.enable = true;
            clang-format.enable = true;
          };
        };
      }
    );
}
