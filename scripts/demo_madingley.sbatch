#!/bin/bash
#SBATCH --job-name=demo_madingley
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4 # Adjust number of CPUs as needed
#SBATCH --mem=4G  # Adjust memory as needed
#SBATCH --output=%x-%j.out
#SBATCH --account=def-sponsor00   # Replace with your allocation

# Load necessary modules
module load r/4.5.0 udunits/2.2.28 gdal/3.9.1

# Run the Madingley case study script
Rscript "$HOME/biodiversity_modelling_2025/scripts/demo_madingley.R"