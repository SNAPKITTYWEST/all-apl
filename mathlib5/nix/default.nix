# nix/default.nix — Pinned nixpkgs + custom library instantiation
let
  # Pin nixpkgs for reproducibility (equivalent to flake.lock)
  nixpkgsCommit = "8a3249547d1a58066c4e0cb9df7c2ab4b5840679"; # nixos-24.05 as of 2024-08
  pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${nixpkgsCommit}.tar.gz";
    sha256 = "sha256:1lr1h35prqkd1mkmzriwlpvxcb34kmhc9dnr48gkm8hh089hifm";
  }) {};

  # Load custom library
  customLib = import ./lib.nix { inherit pkgs; };

in
{
  inherit pkgs;
  inherit customLib;

  # The Haskell package set with MATHLIB5 overrides
  haskellEnv = customLib.mkHaskellEnv { ghcVersion = "ghc982"; };

  # GHC pre-loaded with project dependencies
  ghc = customLib.mkGhcWithPackages {
    ghcVersion = "ghc982";
    packages = [
      "megaparsec"
      "parser-combinators"
      "scientific"
      "text"
      "vector"
      "containers"
      "aeson"
      "hashable"
      "deepseq"
      "tasty"
      "tasty-hunit"
      "tasty-quickcheck"
    ];
  };

  # System build tools
  buildTools = customLib.mkBuildTools {
    includeLean = false;  # Lean managed separately via Bazel or overlay
    includeLLVM = true;
    includeSMT = true;
    includeBazel = true;
  };
}
