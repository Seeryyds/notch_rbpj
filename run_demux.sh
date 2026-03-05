#!/bin/bash
#SBATCH --job-name=demux_HTO
#SBATCH --output=/storage/working_data/xli7/notch_rbpj/logs/demux_HTO_%j.out
#SBATCH --error=/storage/working_data/xli7/notch_rbpj/logs/demux_HTO_%j.err
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=40G

set -euo pipefail

/home/xli7/software/bin/micromamba run -n demuxR Rscript /home/xli7/data_storage/scripts/demux_all.R
