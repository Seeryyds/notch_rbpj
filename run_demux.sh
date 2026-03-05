#!/bin/bash
#SBATCH -J demux_HTO
#SBATCH -t 024:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=40G
#SBATCH -o /storage/working_data/xli7/notch_rbpj/logs/%x_%j.out
#SBATCH -e /storage/working_data/xli7/notch_rbpj/logs/%x_%j.err

module load R 2>/dev/null || true
Rscript /storage/working_data/xli7/notch_rbpj/repo/01_demux_all.R
