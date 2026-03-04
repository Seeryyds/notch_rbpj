/bin/bash
#SBATCH -J solo_all_GEX
#SBATCH -t 48:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=80G
#SBATCH -o /storage/working_data/xli7/notch_rbpj/logs/%x_%j.out
#SBATCH -e /storage/working_data/xli7/notch_rbpj/logs/%x_%j.err

set -euo pipefail
unset GROUPS  

STAR_BIN="/software/lmod/modules/quay.io/biocontainers/star/2.7.11b--h5ca1c30_6/bin/STAR"
GENOME_DIR="/storage/working_data/xli7/notch_rbpj/refs/star_index_GRCm39_109_plusTG"
WHITELIST="/storage/working_data/xli7/notch_rbpj/refs/3M-february-2018.txt"

FASTQ_BASE="/storage/working_data/xli7/notch_rbpj/fastq"
OUT_BASE="/storage/working_data/xli7/notch_rbpj/counts"
LOG_BASE="/storage/working_data/xli7/notch_rbpj/logs"

mkdir -p "$OUT_BASE" "$LOG_BASE"
test -x "$STAR_BIN"
"$STAR_BIN" --version
ls -lh "$GENOME_DIR" | head

# 你要跑的组（不含Control）
GROUPS=(N1ICD N1N4 N1_block_Ab Rbpj)

echo "SCRIPT: $0"
echo "FASTQ_BASE=$FASTQ_BASE"
echo "GROUPS=${GROUPS[*]}"

for g in "${GROUPS[@]}"; do
  gex_root="${FASTQ_BASE}/${g}/GEX"
  echo "==== $gex_root ===="
  if [ ! -d "$gex_root" ]; then
    echo "[SKIP] no GEX folder: $gex_root"
    continue
  fi

  for sample_dir in "$gex_root"/*/; do
    [ -d "$sample_dir" ] || continue
    sample_name="$(basename "$sample_dir")"
    OUT_DIR="${OUT_BASE}/${g}_${sample_name}_plusTG"

    echo "--------------------------------------"
    echo "Group:  $g"
    echo "Sample: $sample_name"
    echo "FASTQ:  $sample_dir"
    echo "OUT:    $OUT_DIR"

    mkdir -p "$OUT_DIR"
    cd "$OUT_DIR"

    mapfile -t R1 < <(find "$sample_dir" -maxdepth 1 -type f -name "*_R1_*.fastq.gz" | sort)
    mapfile -t R2 < <(find "$sample_dir" -maxdepth 1 -type f -name "*_R2_*.fastq.gz" | sort)

    echo "R1 count: ${#R1[@]}"
    echo "R2 count: ${#R2[@]}"
    if [ "${#R1[@]}" -ne "${#R2[@]}" ]; then
      echo "ERROR: R1 and R2 file counts differ for $g/$sample_name" >&2
      exit 1
    fi
    if [ "${#R1[@]}" -eq 0 ]; then
      echo "[SKIP] no FASTQ found in $sample_dir"
      continue
    fi

    R1_LIST=$(printf "%s," "${R1[@]}"); R1_LIST="${R1_LIST%,}"
    R2_LIST=$(printf "%s," "${R2[@]}"); R2_LIST="${R2_LIST%,}"

    "$STAR_BIN" \
      --genomeDir "$GENOME_DIR" \
      --soloType CB_UMI_Simple \
      --readFilesCommand zcat \
      --readFilesIn "$R2_LIST" "$R1_LIST" \
      --runThreadN "${SLURM_CPUS_PER_TASK}" \
      --soloCBwhitelist "$WHITELIST" \
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
      --outTmpDir "${OUT_DIR}/_STARtmp" \
      --outFileNamePrefix "${OUT_DIR}/"
  done
done

echo "ALL DONE"
