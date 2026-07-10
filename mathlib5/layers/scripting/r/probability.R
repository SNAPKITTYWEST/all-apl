# probability.R — Probabilistic Method Analysis (R)
# Lovász Local Lemma, random graph analysis, existence proofs.
# R excels at probability distributions and Monte Carlo simulation.

cat("═══════════════════════════════════════════════════════════\n")
cat(" MATHLIB5 Probabilistic Method (R)\n")
cat("═══════════════════════════════════════════════════════════\n\n")

set.seed(42)

# ── Random graph analysis ──
cat(">> Random Graph G(n,p)\n")

count_edges <- function(adj) {
  sum(adj) / 2
}

count_triangles <- function(adj) {
  n <- nrow(adj)
  count <- 0
  for (i in 1:(n-2)) {
    for (j in (i+1):(n-1)) {
      if (adj[i,j]) {
        for (k in (j+1):n) {
          if (adj[i,k] && adj[j,k]) count <- count + 1
        }
      }
    }
  }
  return(count)
}

# Analyze G(n, p) for various p
n <- 100
p_values <- c(0.01, 0.05, 0.1, 0.2, 0.5)
for (p in p_values) {
  adj <- matrix(rbinom(n*n, 1, p), n, n)
  adj <- pmax(adj, t(adj))  # Symmetric
  diag(adj) <- 0
  edges <- count_edges(adj)
  triangles <- count_triangles(adj[1:30, 1:30])  # Subsample for speed
  cat(sprintf("  G(%d, %.2f): edges=%d, triangles(sub)=%d\n",
      n, p, edges, triangles))
}
cat("\n")

# ── Lovász Local Lemma ──
cat(">> Lovász Local Lemma\n")
cat("  If P(A_i) <= p and each A_i depends on <= d others,\n")
cat("  and ep(d+1) <= 1, then Pr(∧¬A_i) > 0\n\n")

for (d in c(2, 5, 10, 20, 50)) {
  p_max <- 1 / (exp(1) * (d + 1))
  cat(sprintf("  d=%d: p_max = %.6f\n", d, p_max))
}
cat("\n")

# ── Ramsey number lower bounds (probabilistic) ──
cat(">> Ramsey Lower Bounds (Probabilistic Method)\n")

# Erdős bound: R(k,k) > 2^(k/2)
for (k in 3:10) {
  bound <- 2^(k/2)
  cat(sprintf("  R(%d,%d) > %.1f (Erdos bound)\n", k, k, bound))
}
cat("\n")

# ── Monte Carlo estimation ──
cat(">> Monte Carlo Integration\n")

# Estimate pi via random points in unit square
for (N in c(1000, 10000, 100000, 1000000)) {
  x <- runif(N)
  y <- runif(N)
  inside <- sum(x^2 + y^2 <= 1)
  pi_est <- 4 * inside / N
  error <- abs(pi_est - pi)
  cat(sprintf("  N=%d: pi = %.6f (error = %.2e)\n", N, pi_est, error))
}
cat("\n")

# ── Birthday paradox ──
cat(">> Birthday Paradox\n")
for (n in c(10, 20, 23, 30, 50)) {
  p_no_collision <- 1
  for (i in 1:(n-1)) {
    p_no_collision <- p_no_collision * (365 - i) / 365
  }
  p_collision <- 1 - p_no_collision
  cat(sprintf("  %d people: P(collision) = %.4f\n", n, p_collision))
}
cat("\n")

# ── Random walk analysis ──
cat(">> Random Walk on Z\n")
for (steps in c(100, 1000, 10000)) {
  walk <- cumsum(sample(c(-1, 1), steps, replace = TRUE))
  cat(sprintf("  %d steps: final=%d, max=%d, min=%d, range=%d\n",
      steps, walk[steps], max(walk), min(walk), max(walk) - min(walk)))
}
cat("\n")

cat("═══════════════════════════════════════════════════════════\n")
cat(" Analysis complete\n")
cat("═══════════════════════════════════════════════════════════\n")
