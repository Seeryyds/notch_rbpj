#!/bin/bash
#SBATCH -J CITE_all_HTO
#SBATCH -t 024:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=80G
#SBATCH -o /storage/working_data/xli7/notch_rbpj/logs/%x_%j.out
#SBATCH -e /storage/working_data/xli7/notch_rbpj/logs/%x_%j.err

set -euo pipefail
unset GROUPS  # 防止环境变量污染

# ---- 环境配置 ----
export MAMBA_ROOT_PREFIX=/home/xli7/software/mamba_root
MAMBA_BIN=/home/xli7/software/bin/micromamba
ENV_NAME=citeseq310

PROJECT=/storage/working_data/xli7/notch_rbpj
FASTQ_BASE="${PROJECT}/fastq"
TAGS="${PROJECT}/refs/hto_tags.citeseq.csv"
WHITELIST="${PROJECT}/refs/3M-february-2018.txt"
OUT_BASE="${PROJECT}/counts"
LOG_BASE="${PROJECT}/logs"

mkdir -p "$OUT_BASE" "$LOG_BASE"

# 只跑4组（不含Control）
GROUPS=( Control N1ICD N1N4 N1_block_Ab Rbpj)

test -x "$MAMBA_BIN"
"$MAMBA_BIN" run -n "$ENV_NAME" CITE-seq-Count --version || true

echo "PROJECT=$PROJECT"
echo "GROUPS=${GROUPS[*]}"
echo "TAGS=$TAGS"
echo "WHITELIST=$WHITELIST"

for g in "${GROUPS[@]}"; do
  # 按组设置 -cells（来自GEX filtered cells ×1.2）
  case "$g" in
    Control)      CELLS=21512 ;;
    N1ICD)        CELLS=23148 ;;
    N1N4)         CELLS=23253 ;;
    N1_block_Ab)  CELLS=26485 ;;
    Rbpj)         CELLS=18464 ;;
    *)            CELLS=25000 ;;  # 兜底
  esac
  echo ">>> $g  use -cells $CELLS"

  hto_root="${FASTQ_BASE}/${g}/HTO"
  if [ ! -d "$hto_root" ]; then
    echo "[SKIP] no HTO folder: $hto_root"
    continue
  fi

  # 每个样本一个子文件夹（例如 *_HTO）
  for sample_dir in "$hto_root"/*/; do
    [ -d "$sample_dir" ] || continue
    sample_name="$(basename "$sample_dir")"

    OUT="${OUT_BASE}/${g}_${sample_name}_citeseq"
    mkdir -p "$OUT"

    echo "======================================"
    echo "Group:  $g"
    echo "Sample: $sample_name"
    echo "FASTQ:  $sample_dir"
    echo "OUT:    $OUT"

    R1=$(find "$sample_dir" -maxdepth 1 -type f -name "*_R1_*.fastq.gz" | sort | paste -sd, -)
    R2=$(find "$sample_dir" -maxdepth 1 -type f -name "*_R2_*.fastq.gz" | sort | paste -sd, -)

    if [ -z "$R1" ] || [ -z "$R2" ]; then
      echo "[SKIP] missing R1 or R2 in $sample_dir"
      continue
    fi

    "$MAMBA_BIN" run -n "$ENV_NAME" \
      CITE-seq-Count \
      -R1 "$R1" \
      -R2 "$R2" \
      -t "$TAGS" \
      -cbf 1 -cbl 16 \
      -umif 17 -umil 12 \
      -cells "$CELLS" \
      -wl "$WHITELIST" \
      -T "${SLURM_CPUS_PER_TASK}" \
      -o "$OUT"
  done
done

echo "ALL DONE"
