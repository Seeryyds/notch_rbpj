#!/bin/bash
#SBATCH -J mkSTAR_GRCm39_109_plusTG
#SBATCH -t 10:00:00
#SBATCH --cpus-per-task=18
#SBATCH --mem=80G
#SBATCH -o /storage/working_data/xli7/notch_rbpj/logs/%x_%j.out
#SBATCH -e /storage/working_data/xli7/notch_rbpj/logs/%x_%j.err

set -euo pipefail

STAR_BIN="/software/lmod/modules/quay.io/biocontainers/star/2.7.11b--h5ca1c30_6/bin/STAR"
test -x "$STAR_BIN"
"$STAR_BIN" --version

VERSION=109
BASE="/storage/working_data/xli7/notch_rbpj/refs"

gtf_file="${BASE}/Mus_musculus.GRCm39.${VERSION}.plusTG.gtf"
fasta_file="${BASE}/Mus_musculus.GRCm39.${VERSION}.plusTG.fa"
ref_name="${BASE}/star_index_GRCm39_${VERSION}_plusTG"

mkdir -p "$ref_name"
ls -lh "$gtf_file" "$fasta_file"

"$STAR_BIN" --runMode genomeGenerate \
  --runThreadN "${SLURM_CPUS_PER_TASK}" \
  --genomeDir "$ref_name" \
  --genomeFastaFiles "$fasta_file" \
  --sjdbGTFfile "$gtf_file" \
  --sjdbOverhang 89

