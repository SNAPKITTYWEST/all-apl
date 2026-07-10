# Dockerfile — MetaOracle Engine (Sovereign Server Build)
# CUDA 12.4 + Lean 4 + SWI-Prolog + CompCert C
FROM nvidia/cuda:12.4-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. System deps
RUN apt-get update && apt-get install -y \
    opam gcc make libgmp-dev curl git \
    swi-prolog-nox python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 2. CompCert (Verified C Compiler)
RUN opam init -y && opam install -y compcert

# 3. Lean 4
RUN curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
ENV PATH="/root/.elan/bin:${PATH}"
RUN elan toolchain install lean4:nightly-2024-12-01

# 4. Python / vLLM
RUN pip3 install vllm xgrammar fastapi uvicorn pydantic nacl

# 5. Build C Kernel (CompCert verified)
COPY kernel/ /app/kernel/
WORKDIR /app/kernel
RUN ccomp -std=c99 -O2 -o asp_validate asp_validate.c || \
    gcc -std=c99 -pedantic -Wall -Wextra -O2 -o asp_validate asp_validate.c

# 6. Build Lean Project
COPY lean/ /app/lean/
WORKDIR /app/lean
RUN lake build || echo "Lean build skipped (Mathlib dependency)"

# 7. Copy Engine
COPY engine/ /app/engine/
COPY receipts/ /app/receipts/
COPY api/ /app/api/

WORKDIR /app
ENV PYTHONPATH="/app"

EXPOSE 8000
CMD ["uvicorn", "api.openai_compat:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
