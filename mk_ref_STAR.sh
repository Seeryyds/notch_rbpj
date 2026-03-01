#!/bin/bash
#SBATCH -J mkSTAR_GRCm39_109
#SBATCH -t 08:00:00
#SBATCH --cpus-per-task=18
#SBATCH --mem=80G
#SBATCH -o ~/data_storage/working_data/notch_rbpj/logs/%x_%j.out
#SBATCH -e ~/data_storage/working_data/notch_rbpj/logs/%x_%j.err

set -euo pipefail

# If STAR is provided via modules on your cluster, load it here:
# module load star

STAR --version

VERSION=109
BASE="$HOME/data_storage/working_data/notch_rbpj/refs"

gtf_file="${BASE}/Mus_musculus.GRCm39.${VERSION}.gtf"
fasta_file="${BASE}/Mus_musculus.GRCm39.dna.toplevel.fa"
ref_name="${BASE}/star_index_GRCm39_${VERSION}"

mkdir -p "$ref_name"
ls -lh "$gtf_file" "$fasta_file"

STAR --runMode genomeGenerate \
  --runThreadN "${SLURM_CPUS_PER_TASK}" \
  --genomeDir "$ref_name" \
  --genomeFastaFiles "$fasta_file" \
  --sjdbGTFfile "$gtf_file" \
  --sjdbOverhang 99
