# Data Quality Issues

Findings from profiling the `staging` tables with the queries in [`sql/02_profiling/`](../sql/02_profiling/). Fixes are applied in [`sql/03_clean/`](../sql/03_clean/) and checked in [`sql/04_validation/`](../sql/04_validation/).

## Summary

| Table | Rows | Status |
|---|---:|---|
| `staging.hdhi_admission_raw` | 15,757 | 5 issues, 4 observations |
| `staging.hdhi_mortality_raw` | 359 | 3 issues, 1 observation |
| `staging.hdhi_pollution_raw` | 737 | 2 issues |
| `staging.table_headings_raw` | 16,384 | 4 issues |

| # | Table | Issue | Rows affected | Priority | Action taken |
|---|---|---|---:|---|---|
| A1 | admissions | `doa` mixes two date formats | 15,757 (6,335 ambiguous) | High | Resolved using `month_year` to pick the format per row |
| M1 | mortality | `rural_urban` has trailing spaces and invalid values | 5 | Medium | `TRIM()`; `M` and `0` set to `NULL` |
| M2 | mortality | Repeated `mrd` | 6 values (12 rows) | Medium | 4 exact duplicates removed; 2 differing pairs kept |
| H4 | headings | `column_code` does not match the staging column names | 56 | Medium | New `column_name` in snake_case |
| A2 | admissions | `mrd_no` contains `NILL` | 1 | Low | Converted to `NULL` |
| A3 | admissions | Lab value columns contain the text `EMPTY` | See A3 | Low | Columns excluded from the clean table |
| A4 | admissions | `chest_infection` contains `\` | 1 | Low | Converted to `NULL` |
| A5 | admissions | `dod` has a malformed value and an unresolvable format | 15,757 | Low | Column excluded from the clean table |
| M3 | mortality | `mrd` contains `***` | 1 | Low | Converted to `NULL` |
| P1 | pollution | `aqi` exceeds the Indian scale | 2 | Low | Kept unchanged and flagged |
| P2 | pollution | `humidity` has empty values | 4 | Low | Converted to `NULL` |
| H1 | headings | Empty rows | 16,326 | Low | Removed |
| H2 | headings | `SMOKING ` has a trailing space | 1 | Low | `TRIM()` |
| H3 | headings | Rows that do not define a column | 2 | Low | Removed `Other Abbreveiations` and `DAMA` |

## Admissions: `hdhi_admission_raw`

Queries: [`01_profile_admissions.sql`](../sql/02_profiling/01_profile_admissions.sql)

### Issues

**A1. `doa` mixes two date formats.** `D/M/YYYY` and `M/D/YYYY` both appear:

| Case | Rows | Interpretation |
|---|---:|---|
| First part > 12 | 5,655 | Can only be `D/M/YYYY` |
| Second part > 12 | 3,767 | Can only be `M/D/YYYY` |
| Both parts <= 12 | 6,335 | Ambiguous |

**Resolution:** each row has a `month_year` value (for example `Apr-17`) that gives the real month. If the second part of `doa` equals that month, the row is read as `D/M/YYYY`; otherwise as `M/D/YYYY`. Validation found 0 rows where the month of the clean `doa` differs from `month_year`.

**A2. `mrd_no` contains `NILL`.** One row has this text instead of a number. Converted to `NULL`.

**A3. Lab value columns contain the text `EMPTY`.** These columns hold the text `EMPTY` instead of a blank. No current question uses them, so they are excluded from the clean table.

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

**A4. `chest_infection` contains `\`.** One row has a backslash instead of `0` or `1`. Converted to `NULL` with `CHR(92)`, since a literal `'\'` confuses the DBeaver editor.

**A5. `dod` excluded.** It has one malformed value (`2-1217`) and no column that resolves its format, as `month_year` does for `doa`. No current question uses it, since `duration_of_stay` already gives the length of stay.

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
| `M` | 1 | Set to `NULL` |
| `0` | 1 | Set to `NULL` |

**M2. Repeated `mrd`.** Six values appear twice. A person can only be brought in dead once, so each pair was compared:

| `mrd` | Finding | Action |
|---|---|---|
| `164763`, `632011`, `632061`, `633161` | Identical except `sno` | One copy removed (lowest `sno` kept) |
| `445843` | Different age and date | Both kept |
| `641113` | Same person details, dates in February and December | Both kept; possible month typo, cannot be confirmed |

The clean table has 355 rows (359 minus 4 duplicates).

**M3. `mrd` contains `***`.** One row has this placeholder instead of a number. Converted to `NULL`.

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

**P2. `humidity` has empty values.** Four rows have an empty text value, found when loading the clean table. Converted to `NULL`.

### No issues

- **`date` likely has a single format, `M/D/YYYY`.** No first part exceeds 12, and there are no duplicated dates. Confirm in validation that the 737 dates are consecutive with no gaps.
- **`prominent_pollutant` has clean categories:** `PM10` (374), `PM2.5` (319), `CO` (31), `NO2` (11), `SO2` (2).

## Headings: `table_headings_raw`

Queries: [`04_profile_headings.sql`](../sql/02_profiling/04_profile_headings.sql)

### Issues

**H1. Empty rows.** 16,326 of the 16,384 rows have an empty `column_code`. Only 58 have content. Removed.

**H2. Trailing space in `SMOKING `.** Fixed with `TRIM()`; otherwise any join on `column_code` would fail.

**H3. Rows that do not define a column.** Of the 58 rows with content, 56 are column definitions and 2 are not. Both were removed:

- `Other Abbreveiations` is a section label with no `explanatory_name`, which explains why there are 16,327 empty `explanatory_name` values versus 16,326 empty `column_code` values.
- `DAMA` is a value of `outcome` (*Discharged Against Medical Advice*), not a column.

**H4. `column_code` does not match the staging column names.** The 56 column definitions use the original CSV header style (`PRIOR CMP`, `D.O.A`), while the admission columns use snake_case (`prior_cmp`, `doa`). A new `column_name` column was built by removing dots, replacing spaces with `_` and lowercasing. `TYPE OF ADMISSION-EMERGENCY/OPD` was set to `type_of_admission` by hand.

The original spelling `cva_infract` (correct English: *infarct*) is kept in every table so joins keep working.

### No issues

- `column_code` and `explanatory_name` have no duplicates.
