#!/bin/bash
#SBATCH -J solo_one
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=80G
#SBATCH -o /storage/working_data/xli7/notch_rbpj/logs/%x_%j.out
#SBATCH -e /storage/working_data/xli7/notch_rbpj/logs/%x_%j.err

set -euo pipefail

STAR_BIN="/software/lmod/modules/quay.io/biocontainers/star/2.7.11b--h5ca1c30_6/bin/STAR"
GENOME_DIR="/storage/working_data/xli7/notch_rbpj/refs/star_index_GRCm39_109"

# >>> 改这两个变量即可复用到别的样本 <<<
FASTQ_DIR="/storage/raw_data/groups/benedito/new/xli7_first_notch_vs_rbpj/First_Notch_vs_Rbpj_MPI_analysis/Control/GEX/Control_3sep24_GeX"
OUT_DIR="/storage/working_data/xli7/notch_rbpj/counts/Control_GEX"

mkdir -p "$OUT_DIR"
cd "$OUT_DIR"

# Collect + validate pairing
mapfile -t R1 < <(ls -1 ${FASTQ_DIR}/*_R1_*.fastq.gz | sort)
mapfile -t R2 < <(ls -1 ${FASTQ_DIR}/*_R2_*.fastq.gz | sort)

echo "R1 count: ${#R1[@]}"
echo "R2 count: ${#R2[@]}"
if [ "${#R1[@]}" -ne "${#R2[@]}" ]; then
  echo "ERROR: R1 and R2 file counts differ!" >&2
  exit 1
fi

for i in "${!R1[@]}"; do
  echo "PAIR $i"
  echo "  R2: ${R2[$i]}"
  echo "  R1: ${R1[$i]}"
done

R1_LIST=$(printf "%s," "${R1[@]}"); R1_LIST="${R1_LIST%,}"
R2_LIST=$(printf "%s," "${R2[@]}"); R2_LIST="${R2_LIST%,}"

test -x "$STAR_BIN"
"$STAR_BIN" --version

"$STAR_BIN" \
  --genomeDir "$GENOME_DIR" \
  --soloType CB_UMI_Simple \
  --readFilesCommand zcat \
  --readFilesIn "$R2_LIST" "$R1_LIST" \
  --runThreadN "${SLURM_CPUS_PER_TASK}" \
  --soloCBstart 1 --soloCBlen 16 \
  --soloUMIstart 17 --soloUMIlen 12 \
  --soloBarcodeReadLength 0 \
  --soloCellFilter EmptyDrops_CR \
  --soloUMIfiltering MultiGeneUMI_CR \
  --soloUMIdedup 1MM_CR \
  --soloCBmatchWLtype 1MM_multi_Nbase_pseudocounts \
  --outFilterMismatchNoverLmax 0.05 \
  --outFilterMatchNmin 15 \
  --soloFeatures Gene \
  --soloMultiMappers EM \
  --outSAMtype BAM SortedByCoordinate \
  --outSAMattributes NH HI AS nM GX GN CB UB \
  --outFileNamePrefix "${OUT_DIR}/"
