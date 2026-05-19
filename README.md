# SUS-NASA-Toolkit
Open-source toolkit for collecting, scoring, and visualizing System Usability Scale (SUS) and NASA-TLX results.

## Online questionnaire
Use the web app to perform the SUS and NASA-TLX questionnaires:

- Website: https://lelox93.github.io/NASA_TLX_TaInCo/

After finishing a questionnaire the site exports CSV files which can be analyzed with the scripts included in this repository.

## Repository structure

- `Executables/` — compiled Python executables that let you select an input folder containing SUS or NASA CSV files and an output folder; they run the analysis and save plots plus computed CSV result files.

An example is shown here with the SUS executable:

<p align="center"><img src="Executables/sus_gui.png" alt="SUS executable" width="600" /></p>


- `NASA/`
	- `nasa_analysis.m` — MATLAB script to analyze NASA-TLX CSV files.
	- `data_csv/` — CSV exports (examples: `bernardo_task_PW.csv`, `bernardo_task_RS.csv`).
	- `function/` — helper import functions (`importfilePW.m`, `importfileRS.m`).
- `SUS/`
	- `sus_analysis.m` — MATLAB script to analyze SUS CSV files.
	- `data_csv/` — CSV exports (example: `bernardo_KNSC_sus.csv`).

## MatLab Usage

1. Open MATLAB and add the repository to the path or change the working directory to the project root.
2. Place the exported CSV files from the questionnaire in the appropriate `data_csv/` folder.
3. Run the analysis script in MATLAB, for example:

```matlab
run('NASA/nasa_analysis.m')
% or
run('SUS/sus_analysis.m')
```

Check the top of each script for configurable options (file names, plotting flags, output locations).