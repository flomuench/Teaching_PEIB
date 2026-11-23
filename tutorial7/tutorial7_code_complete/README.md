# PEIB Tutorial 7: Does cleantech FDI drive the diffusion of solar energy?

A small, fully reproducible project (SEES0082, UCL SSEES).

Authors: [your name]

## How to run
1. Code: put this folder at `Documents/GitHub/tutorial7_code` on your computer (the local
   Documents folder, not the one inside OneDrive) and add it to GitHub Desktop.
2. Data: create `tutorial7_project` on your OneDrive, unzip `tutorial7_data.zip` into it and
   create the empty folders shown below.
3. R: open `tutorial7_code.Rproj`, open `main.R`, run it (button Source).
   Stata: open `main.do`, run it (button Execute (do)).
   Both read your user name; if your OneDrive folder has another name, change it in Part 1.

## Folder structure
Code (this repository, on GitHub):
```
Documents/GitHub/tutorial7_code/
  main.R  main.do  README.md  .gitignore  tutorial7_code.Rproj
  code/   fdi_import  fdi_clean  fdi_correct  fdi_generate  fdi_aggregate
          sol_import  sol_clean  sol_correct  sol_generate
          an_merge  an_visualise  an_regress        (.R and .do)
```
Data and output (on OneDrive, never on GitHub):
```
OneDrive/tutorial7_project/
  data/fdi/raw  data/fdi/inter  data/fdi/final
  data/sol/raw  data/sol/inter  data/sol/final
  data/an/final
  output/figures  output/tables
```

## Data
- Bandara, P. and the Net Zero Industrial Policy Lab. Cleantech Manufacturing FDI Dataset, edition
  2026.10.05. Johns Hopkins University. https://cmfdi.netzeropolicylab.com (CC BY 4.0).
  File: https://cmfdi.netzeropolicylab.com/data/cm-fdi-projects.csv -> `data/fdi/raw/`
- IRENA (2026) - processed by Our World in Data. Installed solar PV capacity.
  File: https://ourworldindata.org/grapher/installed-solar-pv-capacity.csv?v=1&csvType=full&useColumnShortNames=true
  -> `data/sol/raw/installed-solar-pv-capacity.csv`

## Software
R 4.5 or newer with data.table, ggplot2, fixest, modelsummary, flextable (installed by `main.R`);
or Stata 17 or newer with the package estout (installed by `main.do`).
