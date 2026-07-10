# nix/lib.nix — Custom Haskell environment library for MATHLIB5
{ pkgs }:

{
  # Create a Haskell package set with MATHLIB5-specific overrides
  mkHaskellEnv = { ghcVersion ? "ghc982" }:
    let
      hsPkgs = pkgs.haskell.packages.${ghcVersion}.override {
        overrides = self: super: {
          # Pin specific versions if needed, otherwise use nixpkgs defaults
          megaparsec = super.megaparsec;
          parser-combinators = super.parser-combinators;
          scientific = super.scientific;

          # Local packages (if using cabal2nix for local libs)
          # mathlib5-ir = self.callCabal2nix "mathlib5-ir" ../layers/ir {};
          # mathlib5-parser = self.callCabal2nix "mathlib5-parser" ../layers/parser {};
        };
      };
    in
    hsPkgs;

  # Convenience: get a GHC with specific packages pre-loaded
  mkGhcWithPackages = { ghcVersion ? "ghc982", packages ? [] }:
    let
      hsPkgs = self.mkHaskellEnv { inherit ghcVersion; };
    in
    hsPkgs.ghcWithPackages (p: packages ++ (map (name: p.${name}) (builtins.filter (name: p ? ${name}) packages)));

  # System-level tools needed for the build pipeline
  mkBuildTools = {
    includeLean ? true,
    includeLLVM ? true,
    includeSMT ? true,
    includeBazel ? true,
  }:
    let
      baseTools = with pkgs; [
        # Core build
        bazel
        nix
        git
        curl
        jq

        # Haskell tooling
        haskellPackages.haskell-language-server
        haskellPackages.cabal-install
        hlint
        ormolu

        # Python for testing/comparison
        python3
        python3Packages.pytest
        python3Packages.hypothesis
        python3Packages.numpy
      ];

      leanTools = pkgs.lib.optionals includeLean [
        # Lean 4 (use nixpkgs lean4 or pin separately)
        # lean4.packages.${system}.lean  # If using flake-based lean
      ];

      llvmTools = pkgs.lib.optionals includeLLVM [
        pkgs.llvmPackages_18.llvm
        pkgs.llvmPackages_18.clang
        pkgs.llvmPackages_18.lld
      ];

      smtTools = pkgs.lib.optionals includeSMT [
        pkgs.z3
        pkgs.cvc5
      ];

    in
    baseTools ++ leanTools ++ llvmTools ++ smtTools;
}
