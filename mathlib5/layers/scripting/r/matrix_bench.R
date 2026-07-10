# matrix_bench.R — Matrix Algebra Benchmarks (R)
# BLAS-level operations, eigenvalue iteration, SVD.
# R's matrix operations are backed by optimized BLAS/LAPACK.

cat("═══════════════════════════════════════════════════════════\n")
cat(" MATHLIB5 Matrix Algebra Benchmarks (R)\n")
cat("═══════════════════════════════════════════════════════════\n\n")

# ── Benchmark 1: Matrix multiply ──
cat(">> Matrix Multiply\n")
for (n in c(64, 128, 256, 512)) {
  A <- matrix(runif(n * n), n, n)
  B <- matrix(runif(n * n), n, n)
  t0 <- proc.time()
  C <- A %*% B
  elapsed <- (proc.time() - t0)["elapsed"] * 1000
  flops <- 2 * n^3
  gflops <- flops / (elapsed / 1000) / 1e9
  cat(sprintf("  %dx%d: %.2f ms, %.2f GFLOPS\n", n, n, elapsed, gflops))
}
cat("\n")

# ── Benchmark 2: Eigenvalue decomposition ──
cat(">> Eigenvalue Decomposition\n")
for (n in c(64, 128, 256)) {
  A <- matrix(runif(n * n), n, n)
  A <- A + t(A)  # Symmetric
  t0 <- proc.time()
  e <- eigen(A)
  elapsed <- (proc.time() - t0)["elapsed"] * 1000
  cat(sprintf("  %dx%d: %.2f ms, max eigenvalue: %.4f\n",
      n, n, elapsed, max(e$values)))
}
cat("\n")

# ── Benchmark 3: SVD ──
cat(">> Singular Value Decomposition\n")
for (n in c(64, 128, 256)) {
  A <- matrix(runif(n * n), n, n)
  t0 <- proc.time()
  s <- svd(A)
  elapsed <- (proc.time() - t0)["elapsed"] * 1000
  cat(sprintf("  %dx%d: %.2f ms, condition number: %.2f\n",
      n, n, elapsed, max(s$d) / min(s$d)))
}
cat("\n")

# ── Benchmark 4: Linear solve ──
cat(">> Linear Solve (Ax = b)\n")
for (n in c(64, 128, 256, 512)) {
  A <- matrix(runif(n * n), n, n)
  b <- runif(n)
  t0 <- proc.time()
  x <- solve(A, b)
  elapsed <- (proc.time() - t0)["elapsed"] * 1000
  residual <- max(abs(A %*% x - b))
  cat(sprintf("  %dx%d: %.2f ms, residual: %.2e\n", n, n, elapsed, residual))
}
cat("\n")

# ── Benchmark 5: Determinant ──
cat(">> Determinant\n")
for (n in c(64, 128, 256)) {
  A <- matrix(runif(n * n), n, n)
  t0 <- proc.time()
  d <- det(A)
  elapsed <- (proc.time() - t0)["elapsed"] * 1000
  cat(sprintf("  %dx%d: %.2f ms, det = %.4e\n", n, n, elapsed, d))
}
cat("\n")

# ── Benchmark 6: QR decomposition ──
cat(">> QR Decomposition\n")
for (n in c(128, 256, 512)) {
  A <- matrix(runif(n * n), n, n)
  t0 <- proc.time()
  q <- qr(A)
  elapsed <- (proc.time() - t0)["elapsed"] * 1000
  cat(sprintf("  %dx%d: %.2f ms\n", n, n, elapsed))
}
cat("\n")

# ── Benchmark 7: Parallel reduce ──
cat(">> Parallel Reduction\n")
N <- 1e7
x <- runif(N)
t0 <- proc.time()
s <- sum(x)
elapsed_sum <- (proc.time() - t0)["elapsed"] * 1000
t0 <- proc.time()
m <- max(x)
elapsed_max <- (proc.time() - t0)["elapsed"] * 1000
cat(sprintf("  sum(%d elements): %.2f ms\n", N, elapsed_sum))
cat(sprintf("  max(%d elements): %.2f ms\n", N, elapsed_max))
cat("\n")

cat("═══════════════════════════════════════════════════════════\n")
cat(" Benchmarks complete\n")
cat("═══════════════════════════════════════════════════════════\n")
