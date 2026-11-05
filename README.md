# Healthcare Data Analysis Project

An end-to-end SQL project built on real hospital data. Raw CSV files are loaded into PostgreSQL, profiled for data quality issues, cleaned into typed tables, and analysed to answer five questions about cardiac admissions, patient outcomes and air pollution.

## Dataset

The data comes from the [Hospital Admissions Data](https://www.kaggle.com/datasets/ashishsahani/hospital-admissions-data/data) dataset on Kaggle. It covers patients admitted to the Hero DMC Heart Institute in Ludhiana, India, between April 2017 and March 2019.

| File | Rows | Description |
|---|---:|---|
| `HDHI Admission data.csv` | 15,757 | One row per hospital admission: demographics, length of stay, outcome and 35 condition flags |
| `HDHI Mortality Data.csv` | 359 | Patients brought in dead (never admitted) |
| `HDHI Pollution Data.csv` | 737 | One row per day: air quality index, pollutants, temperature and humidity |
| `table_headings.csv` | 56 | Dictionary of the abbreviations used in the admission columns |

## Questions

1. **Seasonality:** how do admissions change month by month? Is there a seasonal pattern?
2. **Risk of death:** who is most at risk of dying in hospital? Death rate (`outcome = 'EXPIRY'`) by age group and gender.
3. **Admission type:** do emergency admissions stay longer or die more often than outpatient admissions?
4. **Conditions:** which conditions are most common, and which are most deadly?
5. **Air pollution:** on high AQI days, are there more admissions or more people brought in dead?

## Pipeline

The project follows a staging, clean and analysis pattern. Each stage has one job, so problems are easy to trace.

| Stage | Schema | Purpose |
|---|---|---|
| 1. Staging | `staging` | Load each CSV exactly as it arrives, with every column as `TEXT`, so the load never fails |
| 2. Profiling | `staging` | Find data quality issues (missing, invalid, inconsistent, duplicated or unrealistic values) without changing any data |
| 3. Cleaning | `clean` | Rebuild each table with real data types, apply the fixes found in profiling, and validate the result |
| 4. Analysis | `clean` | Answer the five questions using only the clean tables |

All issues found and the decision taken for each one are documented in [`docs/data_issues.md`](docs/data_issues.md).

## Repository structure

```
healthcare-data-analysis-project/
├── data/
│   └── raw/                  # Original CSV files (not committed, download from Kaggle)
├── docs/
│   └── data_issues.md        # Data quality findings and decisions
├── sql/
│   ├── 01_staging/           # Create the staging schema and raw tables
│   ├── 02_profiling/         # Data quality checks on staging
│   ├── 03_cleaning/          # Create, load and validate the clean tables
│   └── 04_analysis/          # One script per question
├── .env.example              # Database settings template
├── compose.yaml              # PostgreSQL container
└── README.md
```

## Setup

### Requirements

- [Docker](https://www.docker.com/products/docker-desktop/)
- [DBeaver](https://dbeaver.io/download/) (Community Edition is enough) or any PostgreSQL client
- A free [Kaggle](https://www.kaggle.com/) account to download the data

### 1. Clone the repository

```bash
git clone https://github.com/joaquinmorales13a069/healthcare-data-analysis-project.git
cd healthcare-data-analysis-project
```

### 2. Download the data

Download the dataset from [Kaggle](https://www.kaggle.com/datasets/ashishsahani/hospital-admissions-data/data), unzip it, and place the four CSV files in `data/raw/` (create the folder if it does not exist). The data files are excluded from the repository by `.gitignore`.

### 3. Configure the database settings

Copy the template and fill in your own values:

```bash
cp .env.example .env
```

```
POSTGRES_USER=
POSTGRES_PASSWORD=
POSTGRES_DB=
```

The `.env` file is excluded from the repository, so your password is never committed.

### 4. Start PostgreSQL in Docker

```bash
docker compose up -d
```

This starts the `kaggle_healthcare_db` container on port `5432`. Data is kept in the `postgres_data` volume, so it survives container restarts.

### 5. Connect DBeaver

Create a new PostgreSQL connection with host `localhost`, port `5432`, and the database, user and password from your `.env` file.

## Running the project

Run the scripts in folder and file number order.

**Step 1: Staging.** Run `sql/01_staging/01_staging.sql` to create the `staging` schema and the four raw tables.

**Step 2: Import the CSV files.** In DBeaver, right click each staging table, choose **Import Data**, and select the matching CSV from `data/raw/`. Keep the default importer settings. On the **Tables mapping** screen, check that every column is mapped to an existing column, since some CSV headers (such as `D.O.A` or `GENDER ` with a trailing space) do not match automatically. Expected row counts:

| Table | Rows |
|---|---:|
| `staging.hdhi_admission_raw` | 15,757 |
| `staging.hdhi_mortality_raw` | 359 |
| `staging.hdhi_pollution_raw` | 737 |
| `staging.table_headings_raw` | 16,384 |

The headings file contains thousands of empty rows; they are removed in the cleaning stage.

**Step 3: Profiling (optional).** The scripts in `sql/02_profiling/` only read data. Run them to reproduce the findings in `docs/data_issues.md`.

**Step 4: Cleaning.** Run the scripts in `sql/03_cleaning/`, starting with `00_create_schema.sql`. Each script creates its clean table, empties it, loads it from staging, and ends with validation queries. Compare their results with the expected values noted in the comments. Each script can be rerun safely.

**Step 5: Analysis.** Run the scripts in `sql/04_analysis/`, one per question.

## Key data quality findings

The most important issue was the admission date. `doa` mixes two date formats (`D/M/YYYY` and `M/D/YYYY`), and 6,335 rows were ambiguous, such as `4/1/2017`. Each row also has a `month_year` value (for example `Apr-17`), which was used to decide the correct format for every row. Validation confirmed that all 15,757 clean dates match their `month_year`.

Other fixes include placeholder IDs (`NILL`, `***`) converted to `NULL`, trailing spaces and invalid categories, four exact duplicate rows in the mortality data, and a data dictionary with 16,326 empty rows. See [`docs/data_issues.md`](docs/data_issues.md) for the full list.

## Findings

To be added after the analysis stage.

## Tools

PostgreSQL, Docker Compose, DBeaver, Git and GitHub.
