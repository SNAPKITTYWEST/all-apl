# convergence.R — P/NP Convergence Analysis (R)
# Statistical analysis of proof search convergence rates.
# R excels at matrix operations, probability, and visualization.

cat("═══════════════════════════════════════════════════════════\n")
cat(" MATHLIB5 Convergence Analysis (R)\n")
cat("═══════════════════════════════════════════════════════════\n\n")

# ── Collatz trajectory statistics ──
cat(">> Collatz Trajectory Analysis\n")

collatz_step <- function(n) {
  if (n %% 2 == 0) return(n / 2)
  return(3 * n + 1)
}

collatz_trajectory <- function(start) {
  n <- start
  steps <- 0
  max_val <- start
  while (n != 1 && steps < 1e7) {
    n <- collatz_step(n)
    max_val <- max(max_val, n)
    steps <- steps + 1
  }
  return(list(length = steps + 1, max_value = max_val, start = start))
}

# Analyze trajectories for n = 1..1000
N <- 1000
trajectories <- sapply(1:N, function(i) collatz_trajectory(i))

lengths <- unlist(trajectories["length", ])
max_vals <- unlist(trajectories["max_value", ])

cat(sprintf("  Range: 1..%d\n", N))
cat(sprintf("  Mean length: %.1f\n", mean(lengths)))
cat(sprintf("  Max length: %d (start=%d)\n", max(lengths), which.max(lengths)))
cat(sprintf("  Mean max_value: %.0f\n", mean(max_vals)))
cat(sprintf("  Max value reached: %d (start=%d)\n", max(max_vals), which.max(max_vals)))
cat("\n")

# ── Convergence rate analysis ──
cat(">> Convergence Rate Analysis\n")

# Running average of trajectory lengths
cummean <- cumsum(lengths) / (1:N)
plot_data <- data.frame(n = 1:N, cummean = cummean)

# Fit power law: length ~ n^alpha
log_n <- log(1:N)
log_len <- log(lengths + 1)
fit <- lm(log_len ~ log_n)
alpha <- coef(fit)[2]
cat(sprintf("  Power law exponent: %.4f\n", alpha))
cat(sprintf("  R²: %.4f\n", summary(fit)$r.squared))
cat("\n")

# ── Ramsey number bounds ──
cat(">> Ramsey Number Analysis\n")

# R(3,3) = 6 (known)
# R(4,4) = 18 (known)
# R(5,5) is unknown: 43 <= R(5,5) <= 48

ramsey_bounds <- data.frame(
  k = c(3, 4, 5),
  lower = c(6, 18, 43),
  upper = c(6, 18, 48),
  known = c(TRUE, TRUE, FALSE)
)

for (i in 1:nrow(ramsey_bounds)) {
  if (ramsey_bounds$known[i]) {
    cat(sprintf("  R(%d,%d) = %d (known)\n",
        ramsey_bounds$k[i], ramsey_bounds$k[i], ramsey_bounds$lower[i]))
  } else {
    cat(sprintf("  R(%d,%d) ∈ [%d, %d] (unknown)\n",
        ramsey_bounds$k[i], ramsey_bounds$k[i],
        ramsey_bounds$lower[i], ramsey_bounds$upper[i]))
  }
}
cat("\n")

# ── Hadamard matrix properties ──
cat(">> Hadamard Matrix Analysis\n")

hadamard_order <- function(n) {
  # Sylvester construction: H(2n) = [[H(n), H(n)], [H(n), -H(n)]]
  if (n == 1) return(matrix(1, 1, 1))
  H <- hadamard_order(n / 2)
  return(rbind(cbind(H, H), cbind(H, -H)))
}

for (p in 1:4) {
  n <- 2^p
  H <- hadamard_order(n)
  # Verify: H * H' = nI
  product <- H %*% t(H)
  identity_check <- all(product == n * diag(n))
  cat(sprintf("  H(%d): verified = %s, det = %.0f\n",
      n, identity_check, det(H)))
}
cat("\n")

# ── Statistical summary ──
cat(">> Statistical Summary\n")
cat(sprintf("  Trajectories analyzed: %d\n", N))
cat(sprintf("  Mean trajectory length: %.2f ± %.2f\n",
    mean(lengths), sd(lengths)))
cat(sprintf("  Median trajectory length: %.0f\n", median(lengths)))
cat(sprintf("  Skewness: %.4f\n",
    mean((lengths - mean(lengths))^3) / sd(lengths)^3))
cat(sprintf("  Kurtosis: %.4f\n",
    mean((lengths - mean(lengths))^4) / sd(lengths)^4 - 3))
cat("\n")

cat("═══════════════════════════════════════════════════════════\n")
cat(" Analysis complete\n")
cat("═══════════════════════════════════════════════════════════\n")
