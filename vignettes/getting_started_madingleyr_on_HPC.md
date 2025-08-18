# MadingleyR on Alliance HPC – Quick Start Guide

## 1. Understand the HPC environment

Before diving in, read these to understand the system you’re on:

* [Alliance – Using Fir](https://docs.alliancecan.ca/wiki/Fir)
* [Alliance – Filesystem and storage (Home, Scratch, Project)](https://docs.alliancecan.ca/wiki/Storage_and_file_management)
* [Alliance – Using modules](https://docs.alliancecan.ca/wiki/Using_modules)
* [Alliance – Running jobs with Slurm](https://docs.alliancecan.ca/wiki/Running_jobs)
* [Alliance – Using R on Alliance HPC](https://docs.alliancecan.ca/wiki/R)

**Key points**:

* **Login nodes**: Where you connect, prepare work and launch jobs (don’t run heavy work here!).
* **Compute nodes**: Where your jobs actually run, through Slurm - `sbatch`.
* **Shared storage**: `Home`, `Project`, and `Scratch` are available on all nodes.
* **R dependencies**: Use modules to load R, install packages from the login node in your `home` or `project` directories, and make them available to your jobs by setting the R library path.


## 2. Clone the repository and set up directories

This guide assumes usage of `Home` for simplicity. However, consider using a `Project` folder for running simulations for better performance and sharing.

SSH into Cedar (or other hpc cluster) and run:

```bash
cd $HOME
git clone https://github.com/bios2/biodiversity_modelling_2025.git
cd biodiversity_modelling_2025

mkdir -p $SCRATCH/biodiversity_modelling_2025_out
```

* **\$HOME** → for personal scripts and R packages (persistent)
* **\$SCRATCH** → for simulation output (large files, temporary)
* **\project\...** → for shared R packages & code (shared, persistent, performant)


## 3. Load R and dependencies

Modules are how you load software on Alliance HPC clusters.

Check what’s available:

```bash
module spider r
module spider gdal proj geos
```

Then load them (adjust version if newer):

```bash
module load r/4.4.0
module load udunits/2.2.28
module load gdal/3.9.1
```

📖 [Alliance – Using modules](https://docs.alliancecan.ca/wiki/Using_modules)


## 4. Tell R where to install your packages

> **Important**: This step is not required when using the training cluster for the summer school, as it is already set up.

Set the R library path to your `$HOME` space so jobs can find them:

```bash
mkdir -p $HOME/biodiversity_modelling_2025/r-lib

echo 'R_LIBS_USER="'"$HOME/biodiversity_modelling_2025/r-lib"'"' >> ~/.Renviron
```


## 5. Install MadingleyR

> **Important**: This step is not required when using the training cluster for the summer school, as it is already set up.

Do this **on the login node** (internet is blocked on compute nodes):

```bash
R
```

In the R console:

```r
install.packages(c("remotes","data.table","terra","sf"))
library(remotes)
install_github("MadingleyR/MadingleyR", subdir="Package", build_vignettes=FALSE)
library(MadingleyR)
madingley_version()
q()
```


## 6. Create your first simulation script

Save this as:
`$HOME/biodiversity_modelling_2025/scripts/demo_madingley.R`

```r
library(MadingleyR)

# Region of interest : Single 1 degree grid cell over Vancouver
spatial_window <- c(-124, -123, 49, 50)

out_dir <- file.path(Sys.getenv("SCRATCH"), "biodiversity_modelling_2025_out")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

mdata <- madingley_init(spatial_window = spatial_window)
mdata2 <- madingley_run(out_dir = out_dir, madingley_data = mdata, years = 10)

saveRDS(mdata2, file.path(out_dir, "demo_results.rds"))
```


## 7. Create a Slurm batch script

📖 [Alliance – Running jobs with Slurm](https://docs.alliancecan.ca/wiki/Running_jobs)

Save this as:
`$HOME/biodiversity_modelling_2025/scripts/demo_madingley.sbatch`

```bash
#!/bin/bash
#SBATCH --job-name=demo_madingley
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --output=%x-%j.out
#SBATCH --account=def-sponsor00   # Replace with your allocation

# Load necessary modules
module load r/4.5.0 udunits/2.2.28 gdal/3.9.1

# Run the Madingley case study script
Rscript "$HOME/biodiversity_modelling_2025/scripts/demo_madingley.R"
```


## 8. Submit your job

From login node:

```bash
cd $HOME/biodiversity_modelling_2025/scripts
sbatch demo_madingley.sbatch
```

Check job status:

```bash
squeue -u $USER
```


## 9. Retrieve your results

When the job is finished:

```bash
# List past Slurm jobs
sacct -u $USER

# List output files
ls $SCRATCH/biodiversity_modelling_2025_out
```

You should see:

* `demo_results.rds` → the simulation output
* Any additional plots or data files


## 10. Troubleshooting

* If R can’t find `terra` or `sf`: make sure you loaded `gdal`, `proj`, `geos` **both when installing and in the job script**.
* If you see “no internet” errors: remember to install packages on the **login node**, not inside jobs.
