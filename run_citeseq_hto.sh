#!/bin/bash
#SBATCH -J CITE_Control_HTO
#SBATCH -t 024:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=80G
#SBATCH -o /storage/working_data/xli7/notch_rbpj/logs/%x_%j.out
#SBATCH -e /storage/working_data/xli7/notch_rbpj/logs/%x_%j.err

set -euo pipefail

# ---- USER CONFIG ----
export MAMBA_ROOT_PREFIX=/home/xli7/software/mamba_root
MAMBA_BIN=/home/xli7/software/bin/micromamba
ENV_NAME=citeseq310

PROJECT=/storage/working_data/xli7/notch_rbpj
FASTQ_DIR="${PROJECT}/fastq/Control/HTO/Control_3sep24_HTO"
TAGS="/storage/working_data/xli7/notch_rbpj/refs/hto_tags.citeseq.csv"
WHITELIST="${PROJECT}/refs/3M-february-2018.txt"
OUT="${PROJECT}/counts/Control_HTO_citeseq"
EXPECTED_CELLS=25000
# ---------------------

mkdir -p "$OUT"

R1=$(ls -1 ${FASTQ_DIR}/*_R1_*.fastq.gz | sort | paste -sd, -)
R2=$(ls -1 ${FASTQ_DIR}/*_R2_*.fastq.gz | sort | paste -sd, -)

"$MAMBA_BIN" run -n "$ENV_NAME" \
  CITE-seq-Count \
  -R1 "$R1" \
  -R2 "$R2" \
  -t "$TAGS" \
  -cbf 1 -cbl 16 \
  -umif 17 -umil 28 \
  -cells "$EXPECTED_CELLS" \
  -wl "$WHITELIST" \
  -T "${SLURM_CPUS_PER_TASK}" \
  -o "$OUT"
