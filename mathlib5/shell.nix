# shell.nix — MATHLIB5 development environment
# Usage: nix-shell (or nix-shell --argstr ghcVersion ghc96)
let
  env = import ./nix/default.nix;
  pkgs = env.pkgs;
in
pkgs.mkShell {
  name = "mathlib5-dev-env";

  buildInputs = [
    # GHC with all Haskell dependencies pre-loaded
    env.ghc

    # System build tools (Bazel, LLVM, SMT solvers, etc.)
  ] ++ env.buildTools;

  # Environment variables
  shellHook = ''
    echo "╔══════════════════════════════════════════╗"
    echo "║   MATHLIB5 Development Environment       ║"
    echo "╠══════════════════════════════════════════╣"
    echo "║  GHC:    $(ghc --version)                ║"
    echo "║  Bazel:  $(bazel --version | head -1)    ║"
    echo "║  LLVM:   $(llc --version | head -1)      ║"
    echo "║  Z3:     $(z3 --version)                 ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""
    echo "Build:  bazel build //..."
    echo "Test:   bazel test //..."
    echo "Enter:  nix-shell"
  '';

  # Propagate useful environment variables
  LANG = "en_US.UTF-8";
  LOCALE_ARCHIVE = pkgs.lib.optionalString pkgs.stdenv.isLinux
    "${pkgs.glibcLocales}/lib/locale/locale-archive";
}
