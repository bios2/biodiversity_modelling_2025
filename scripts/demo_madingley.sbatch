#!/bin/bash
#SBATCH --job-name=madingley_case1
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --output=%x-%j.out
#SBATCH --account=def-your_account   # Replace with your allocation

# Load necessary modules
module load StdEnv/2023
module load r/4.4.0 gdal

# Run the Madingley case study script
Rscript "$HOME/biodiversity_modelling_2025/scripts/demo_madingley.R"