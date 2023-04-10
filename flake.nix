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
      overlay = final: prev: {
        ghidra = with final;
          applyPatches {
            src = fetchFromGitHub {
              owner = "NationalSecurityAgency";
              repo = "ghidra";
              rev = "refs/tags/Ghidra_10.2.3_build";
              sha256 = "sha256-YhjKRlFlF89H05NsTS69SB108rNiiWijvZZY9fR+Ebc=";
            };
            patches = [
              ./src/patches/stable/0001-Small-improvements-to-C-decompiler-testing-from-CLI.patch
              ./src/patches/stable/0002-Add-include-guards-to-decompiler-C-headers.patch
              ./src/patches/stable/0003-Fix-UBSAN-errors-in-decompiler.patch
              ./src/patches/stable/0004-Use-stroull-instead-of-stroul-to-parse-address-offse.patch
              ./src/patches/stable/0005-1-4-decompiler-Add-using-namespace-std-to-all-.cc.patch
              ./src/patches/stable/0006-2-4-decompiler-Remusing-automated-std-namespace-fix.patch
              ./src/patches/stable/0007-3-4-decompiler-Manually-fix-std-namespace-in-generat.patch
              ./src/patches/stable/0008-4-4-decompiler-Manually-fix-missed-std-variable-usag.patch
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
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [self.overlay];
        };
      in {
        defaultPackage = pkgs.sleigh;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            sleigh
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
