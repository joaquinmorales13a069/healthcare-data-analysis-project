# Data Quality Issues

Findings from profiling the `staging` tables with the queries in [`sql/02_profiling/`](../sql/02_profiling/). Fixes are applied in Phase 3.

## Summary

| Table | Rows | Status |
|---|---:|---|
| `staging.hdhi_admission_raw` | 15,757 | 3 issues, 4 observations |
| `staging.hdhi_mortality_raw` | 359 | 3 issues, 1 observation |
| `staging.hdhi_pollution_raw` | 737 | 1 issue |
| `staging.table_headings_raw` | 16,384 | 4 issues |

| # | Table | Issue | Rows affected | Priority | Proposed action |
|---|---|---|---:|---|---|
| A1 | admissions | `doa` mixes two date formats | 15,757 (6,335 ambiguous) | High | Resolve in Phase 3 before any monthly analysis |
| M1 | mortality | `rural_urban` has trailing spaces and invalid values | 5 | Medium | `TRIM()` and treat `M` and `0` as unknown |
| M2 | mortality | Repeated `mrd` | 6 values (12 rows) | Medium | Check whether they are true duplicates before removing any |
| H4 | headings | `column_code` does not match the staging column names | 56 | Medium | Decide a mapping in Phase 3 |
| A2 | admissions | `mrd_no` contains `NILL` | 1 | Low | Convert to `NULL` |
| A3 | admissions | Lab value columns contain the text `EMPTY` | 664 | Low | Convert to `NULL`; out of scope for the current questions |
| M3 | mortality | `mrd` contains `***` | 1 | Low | Convert to `NULL` |
| P1 | pollution | `aqi` exceeds the Indian scale | 2 | Low | Keep both values unchanged and flag them |
| H1 | headings | Empty rows | 16,326 | Low | Remove |
| H2 | headings | `SMOKING ` has a trailing space | 1 | Low | `TRIM()` |
| H3 | headings | Rows that do not define a column | 2 | Low | Remove `Other Abbreveiations`; keep `DAMA` as a note |

## Admissions: `hdhi_admission_raw`

Queries: [`01_profile_admissions.sql`](../sql/02_profiling/01_profile_admissions.sql)

### Issues

**A1. `doa` mixes two date formats.** `D/M/YYYY` and `M/D/YYYY` both appear:

| Case | Rows | Interpretation |
|---|---:|---|
| First part > 12 | 5,655 | Can only be `D/M/YYYY` |
| Second part > 12 | 3,767 | Can only be `M/D/YYYY` |
| Both parts <= 12 | 6,335 | Ambiguous |

This test alone cannot resolve 40% of the rows. It directly affects question 1 (admissions by month), so it must be resolved in Phase 3.

**A2. `mrd_no` contains `NILL`.** One row has this text instead of a number.

**A3. Lab value columns contain the text `EMPTY`.** These columns hold the text `EMPTY` instead of a blank. Convert it to `NULL`; out of scope for the current questions.

| Column | Rows |
|---|---:|
| `bnp` | 640 |
| `ef` | 94 |
| `glucose` | 82 |
| `platelets` | 9 |
| `hb` | 4 |
| `tlc` | 4 |
| `creatinine` | 4 |
| `urea` | 3 |

### Observations

- **`mrd_no` repeats.** The headings table defines it as *Admission Number*, but the repeats show it identifies a patient, with readmissions. `sno` is the unique key instead.
- **`mrd_no` has variable length.** It ranges from 3 to 7 characters, and 6 is the norm (15,113 rows). Unusual lengths may be data entry errors, so they are flagged only.

| Length | Rows |
|---:|---:|
| 3 | 7 |
| 4 | 32 |
| 5 | 599 |
| 6 | 15,113 |
| 7 | 6 |

The `NILL` value is included in the 32 rows of length 4.

- **`age` reaches 110 years.** The range is 4 to 110. Only two rows are above 100, both with the same `mrd_no` (`542943`), which points to one patient admitted twice. They are kept.
- **`duration_of_stay` reaches 98 days.** The range of 1 to 98 is reasonable.

### No issues

| Column | Values |
|---|---|
| `sno` | No duplicates; usable as a row identifier |
| `gender` | `M` (9,990), `F` (5,767) |
| `rural` | `U` (12,077), `R` (3,680) |
| `type_of_admission` | `E` (10,924), `O` (4,833) |
| `outcome` | `DISCHARGE` (13,756), `EXPIRY` (1,105), `DAMA` (896) |

## Mortality: `hdhi_mortality_raw`

Queries: [`02_profile_mortality.sql`](../sql/02_profiling/02_profile_mortality.sql)

### Issues

**M1. `rural_urban` has dirty values.** `R` and `U` each appear twice in the `GROUP BY` because some rows have a trailing space. There are also two values that are not valid categories:

| Value | Rows | Treatment |
|---|---:|---|
| `U` | 294 | Correct |
| `R` | 60 | Correct |
| `R ` (trailing space) | 2 | `TRIM()` |
| `U ` (trailing space) | 1 | `TRIM()` |
| `M` | 1 | Invalid; `TRIM()` does not fix it |
| `0` | 1 | Invalid; `TRIM()` does not fix it |

**M2. Repeated `mrd`.** Six values appear twice: `164763`, `445843`, `632011`, `632061`, `633161`, and `641113`. A person can only be brought in dead once, so compare the rows in each pair before removing any.

**M3. `mrd` contains `***`.** One row has this placeholder instead of a number.

### Observations

- **`mrd` has variable length.** It ranges from 3 to 7 characters, with the same pattern as admissions. Length 3: 2 rows (including `***`); length 5: 15; length 6: 341; length 7: 1.

### No issues

| Column | Values |
|---|---|
| `gender` | `M` (236), `F` (123) |

## Pollution: `hdhi_pollution_raw`

Queries: [`03_profiling_pollution.sql`](../sql/02_profiling/03_profiling_pollution.sql)

### Issues

**P1. `aqi` exceeds the Indian scale.** The range is 28 to 797, while India's index runs from 1 to 500. Two rows fall outside it (`769` and `797`). Decision: keep both values unchanged and flag them, since they are only 2 of 737 days.

### No issues

- **`date` likely has a single format, `M/D/YYYY`.** No first part exceeds 12, and there are no duplicated dates. Confirm in validation that the 737 dates are consecutive with no gaps.
- **`prominent_pollutant` has clean categories:** `PM10` (374), `PM2.5` (319), `CO` (31), `NO2` (11), `SO2` (2).

## Headings: `table_headings_raw`

Queries: [`04_profile_headings.sql`](../sql/02_profiling/04_profile_headings.sql)

### Issues

**H1. Empty rows.** 16,326 of the 16,384 rows have an empty `column_code`. Only 58 have content.

**H2. Trailing space in `SMOKING `.** Fix it with `TRIM()`; otherwise any join on `column_code` would fail.

**H3. Rows that do not define a column.** Of the 58 rows with content, 56 are column definitions and 2 are not:

- `Other Abbreveiations` is a section label with no `explanatory_name`, which explains why there are 16,327 empty `explanatory_name` values versus 16,326 empty `column_code` values. Remove it.
- `DAMA` is a value of `outcome` (*Discharged Against Medical Advice*). Keep it as a note for question 2.

**H4. `column_code` does not match the staging column names.** The 56 column definitions use the original CSV header style (`PRIOR CMP`, `HEART FAILURE`), while the staging admission columns use snake_case (`prior_cmp`, `heart_failure`). They will not join directly, which affects question 4. Decide a mapping in Phase 3.

### No issues

- `column_code` and `explanatory_name` have no duplicates.
