# =============================================================================
# 02_data_quality.R
# Island Time, Interrupted: Tourism Dependence and the COVID Cliff
# Purpose: Coverage matrix, feasibility audit, baseline datasets.
# Depends on: 01_data_acquisition.R having been run first.
# Run from: repository root (here() anchors at .git)
# =============================================================================

library(here)
library(readr)
library(dplyr)
library(tidyr)

processed <- here("data", "processed")

# ---------------------------------------------------------------------------
# Load processed data
# ---------------------------------------------------------------------------

candidates <- read_csv(
  file.path(processed, "candidates.csv"),
  show_col_types = FALSE
)
tgdp <- read_csv(
  file.path(processed, "owid_tourism_gdp.csv"),
  show_col_types = FALSE
)
vspend <- read_csv(
  file.path(processed, "owid_visitor_spending.csv"),
  show_col_types = FALSE
)
arrivals <- read_csv(
  file.path(processed, "owid_arrivals.csv"),
  show_col_types = FALSE
)
wb <- read_csv(
  file.path(here("data", "raw", "worldbank"), "wdi_tourism_covid.csv"),
  show_col_types = FALSE
)

# ---------------------------------------------------------------------------
# Build indicator-level coverage counts (used for coverage matrix)
# Baseline eligibility is assessed on 2017-2019 throughout the coverage matrix.
# 2015-2019 baselines are calculated separately below for the analytical dataset.
# ---------------------------------------------------------------------------

base <- candidates |>
  select(iso3, country, sids_region, sids_status, political_status)

# -- Tourism GDP (OWID) 2017-2019 --
tgdp_cover <- tgdp |>
  filter(year %in% 2017:2019, !is.na(tourism_gdp_pct)) |>
  group_by(iso3) |>
  summarise(owid_tgdp_n_1719 = n(), .groups = "drop")

# -- Visitor spending (OWID) 2017-2019 -- PRIMARY indicator
vsp_cover <- vspend |>
  filter(year %in% 2017:2019, !is.na(visitor_spend_gdp_pct)) |>
  group_by(iso3) |>
  summarise(owid_vspend_n_1719 = n(), .groups = "drop")

# -- Arrivals (OWID) 2017-2019 --
arr_1719_cover <- arrivals |>
  filter(year %in% 2017:2019, !is.na(arrivals)) |>
  group_by(iso3) |>
  summarise(owid_arrivals_n_1719 = n(), .groups = "drop")

# -- Arrivals (OWID) 2020 --
arr_2020_cover <- arrivals |>
  filter(year == 2020, !is.na(arrivals)) |>
  group_by(iso3) |>
  summarise(owid_arrivals_2020 = 1L, .groups = "drop")

# -- WDI tourism receipts 2017-2019 -- complementary measure
# NOTE: WDI ST.INT.RCPT.XP.ZS contains no observations beyond 2020 in this
# retrieval. This may reflect a change in UN Tourism's data dissemination
# approach following the pandemic, rather than a simple publication lag.
# Many economies lack 2019 data; their 2017-2019 baseline uses 2017 and 2018 only.
# See the Data Dictionary for documentation of this limitation.
wb_receipts_cover <- wb |>
  filter(year %in% 2017:2019, !is.na(tourism_receipts_pct_exports)) |>
  group_by(iso3) |>
  summarise(wb_receipts_n_1719 = n(), .groups = "drop")

# -- WDI GDP growth 2020 --
wb_gdpgrowth_2020 <- wb |>
  filter(year == 2020, !is.na(gdp_growth_pct)) |>
  group_by(iso3) |>
  summarise(wb_gdpgrowth_2020 = 1L, .groups = "drop")

# -- WDI GDP per capita (current USD) key years --
wb_gdppc_cover <- wb |>
  filter(year %in% c(2019, 2020, 2022, 2023), !is.na(gdp_per_capita_usd)) |>
  group_by(iso3) |>
  summarise(wb_gdppc_n_req = n(), .groups = "drop")

# -- WDI real GDP (constant 2015 USD) key years 2019-2023 --
wb_gdpreal_cover <- wb |>
  filter(year %in% c(2019, 2020, 2022, 2023), !is.na(gdp_real_const2015usd)) |>
  group_by(iso3) |>
  summarise(wb_gdpreal_n_req = n(), .groups = "drop")

# -- WDI real GDP per capita (constant 2015 USD) key years --
wb_gdppcreal_cover <- wb |>
  filter(
    year %in% c(2019, 2020, 2022, 2023),
    !is.na(gdppc_real_const2015usd)
  ) |>
  group_by(iso3) |>
  summarise(wb_gdppcreal_n_req = n(), .groups = "drop")

# -- WDI unemployment key years --
wb_unem_cover <- wb |>
  filter(year %in% c(2019, 2020, 2022, 2023), !is.na(unemployment_pct)) |>
  group_by(iso3) |>
  summarise(wb_unem_n_req = n(), .groups = "drop")

# ---------------------------------------------------------------------------
# Assemble coverage matrix
# ---------------------------------------------------------------------------

coverage <- base |>
  left_join(tgdp_cover, by = "iso3") |>
  left_join(vsp_cover, by = "iso3") |>
  left_join(arr_1719_cover, by = "iso3") |>
  left_join(arr_2020_cover, by = "iso3") |>
  left_join(wb_receipts_cover, by = "iso3") |>
  left_join(wb_gdpgrowth_2020, by = "iso3") |>
  left_join(wb_gdppc_cover, by = "iso3") |>
  left_join(wb_gdpreal_cover, by = "iso3") |>
  left_join(wb_gdppcreal_cover, by = "iso3") |>
  left_join(wb_unem_cover, by = "iso3") |>
  mutate(across(where(is.integer) | where(is.double), ~ replace_na(., 0L))) |>
  mutate(
    has_tgdp_baseline = owid_tgdp_n_1719 > 0,
    has_vspend_baseline = owid_vspend_n_1719 > 0,
    has_receipts_baseline = wb_receipts_n_1719 > 0,
    has_any_tourism = has_tgdp_baseline |
      has_vspend_baseline |
      has_receipts_baseline,

    tgdp_thin_baseline = owid_tgdp_n_1719 == 1,
    vspend_thin_baseline = owid_vspend_n_1719 == 1,
    receipts_thin_baseline = wb_receipts_n_1719 == 1,

    has_gdpgrowth_2020 = wb_gdpgrowth_2020 == 1,

    # Recovery sample: primary shock-eligible + 2019 real GDP baseline +
    # at least one later comparison year (2020, 2022, or 2023) in real GDP.
    # Explicitly requiring 2019 ensures the index can be computed.
    has_real_gdp_recovery = {
      has_2019 <- wb |>
        filter(year == 2019, !is.na(gdp_real_const2015usd)) |>
        pull(iso3)
      iso3 %in% has_2019 & wb_gdpreal_n_req >= 2
    },
    has_real_gdppc_recovery = {
      has_2019_pc <- wb |>
        filter(year == 2019, !is.na(gdppc_real_const2015usd)) |>
        pull(iso3)
      iso3 %in% has_2019_pc & wb_gdppcreal_n_req >= 2
    },

    # Sample definitions (based on 2017-2019 availability + 2020 GDP growth)
    in_tourism_data_sample = has_any_tourism,
    in_primary_shock_sample = has_vspend_baseline & has_gdpgrowth_2020,
    in_receipts_shock_sample = has_receipts_baseline & has_gdpgrowth_2020,
    in_common_sample = has_vspend_baseline &
      has_receipts_baseline &
      has_gdpgrowth_2020,
    in_recovery_sample = in_primary_shock_sample & has_real_gdp_recovery
  )

write_csv(coverage, file.path(processed, "country_coverage.csv"))
message("Coverage matrix saved: ", file.path(processed, "country_coverage.csv"))

# ---------------------------------------------------------------------------
# Sample membership report
# ---------------------------------------------------------------------------

owid_sample_iso <- coverage |> filter(in_primary_shock_sample) |> pull(iso3)
wdi_sample_iso <- coverage |> filter(in_receipts_shock_sample) |> pull(iso3)
common_sample_iso <- coverage |> filter(in_common_sample) |> pull(iso3)

cat("\n================================================================\n")
cat("SAMPLE DEFINITIONS (based on 2017-2019 availability)\n")
cat("================================================================\n\n")
cat(
  "OWID sample  (vspend 2017-19 + GDP growth 2020) N =",
  length(owid_sample_iso),
  ":",
  paste(sort(owid_sample_iso), collapse = ", "),
  "\n\n"
)
cat(
  "WDI sample   (receipts 2017-19 + GDP growth 2020) N =",
  length(wdi_sample_iso),
  ":",
  paste(sort(wdi_sample_iso), collapse = ", "),
  "\n\n"
)
cat(
  "Common sample(both indicators + GDP growth 2020) N =",
  length(common_sample_iso),
  ":",
  paste(sort(common_sample_iso), collapse = ", "),
  "\n\n"
)
cat(
  "OWID-only:",
  paste(sort(setdiff(owid_sample_iso, common_sample_iso)), collapse = ", "),
  "\n"
)
cat(
  "WDI-only: ",
  paste(sort(setdiff(wdi_sample_iso, common_sample_iso)), collapse = ", "),
  "\n"
)

# ---------------------------------------------------------------------------
# Build analytical dataset (country-year panel)
# ---------------------------------------------------------------------------

wb_panel <- wb |>
  filter(iso3 %in% candidates$iso3) |>
  left_join(
    select(
      candidates,
      iso3,
      country,
      sids_region,
      sids_status,
      political_status
    ),
    by = "iso3"
  )

owid_panel <- tgdp |>
  select(iso3, year, tourism_gdp_pct) |>
  full_join(
    vspend |> select(iso3, year, visitor_spend_gdp_pct),
    by = c("iso3", "year")
  ) |>
  full_join(
    arrivals |> select(iso3, year, arrivals),
    by = c("iso3", "year")
  ) |>
  filter(iso3 %in% candidates$iso3)

# Full join: preserves all economy-year records from both WDI and OWID sources.
# Seven candidate economies (AIA, GLP, MTQ, MSR, BES, COK, NIU) are not in the
# World Bank API and therefore have no WDI rows; a left_join from wb_panel would
# silently drop their OWID observations. Using full_join followed by a coalesce
# of metadata ensures all 58 candidate economies appear, with NA for any WDI
# variables that are unavailable. Note: these 7 economies lack 2020 GDP growth
# data and therefore cannot qualify for any analytical (shock) sample —
# the join correction does not change any model results.
analytical_raw <- wb_panel |>
  full_join(owid_panel, by = c("iso3", "year"))

# Coalesce metadata for economies present only in OWID (not in wb_panel)
cand_meta <- select(
  candidates,
  iso3,
  country,
  sids_region,
  sids_status,
  political_status
)

analytical <- analytical_raw |>
  left_join(cand_meta, by = "iso3", suffix = c("", "_cand")) |>
  mutate(
    country = coalesce(country, country_cand),
    sids_region = coalesce(sids_region, sids_region_cand),
    sids_status = coalesce(sids_status, sids_status_cand),
    political_status = coalesce(political_status, political_status_cand)
  ) |>
  select(-ends_with("_cand")) |>
  arrange(iso3, year)

# Verify: check for duplicate economy-year keys
dup_check <- analytical |> group_by(iso3, year) |> filter(n() > 1)
if (nrow(dup_check) > 0) {
  stop(
    "Duplicate iso3-year keys found in analytical panel: ",
    paste(unique(dup_check$iso3), collapse = ", ")
  )
}

write_csv(analytical, file.path(processed, "analytical_panel.csv"))
message(
  "Analytical panel saved: ",
  nrow(analytical),
  " rows, ",
  length(unique(analytical$iso3)),
  " countries, ",
  min(analytical$year),
  "-",
  max(analytical$year)
)

# ---------------------------------------------------------------------------
# Baseline calculations — BOTH 2015-2019 and 2017-2019 windows
#
# Sample membership is fixed based on 2017-2019 availability (above).
# Baselines are calculated for all candidates; sample flags added below.
# ---------------------------------------------------------------------------

compute_baselines <- function(data_wide, years) {
  data_wide |>
    filter(year %in% years) |>
    group_by(iso3, country, sids_region, sids_status, political_status) |>
    summarise(
      vspend_mean = mean(visitor_spend_gdp_pct, na.rm = TRUE),
      vspend_n = sum(!is.na(visitor_spend_gdp_pct)),
      receipts_mean = mean(tourism_receipts_pct_exports, na.rm = TRUE),
      receipts_n = sum(!is.na(tourism_receipts_pct_exports)),
      tgdp_mean = mean(tourism_gdp_pct, na.rm = TRUE),
      tgdp_n = sum(!is.na(tourism_gdp_pct)),
      arrivals_mean = mean(arrivals, na.rm = TRUE),
      arrivals_n = sum(!is.na(arrivals)),
      .groups = "drop"
    ) |>
    mutate(
      across(
        c(vspend_mean, receipts_mean, tgdp_mean, arrivals_mean),
        ~ if_else(is.nan(.), NA_real_, .)
      ),
      vspend_thin = vspend_n == 1,
      receipts_thin = receipts_n == 1
    )
}

bl_1519 <- compute_baselines(analytical, 2015:2019) |>
  rename_with(
    ~ paste0(., "_1519"),
    starts_with(c("vspend", "receipts", "tgdp", "arrivals"))
  )

bl_1719 <- compute_baselines(analytical, 2017:2019) |>
  rename_with(
    ~ paste0(., "_1719"),
    starts_with(c("vspend", "receipts", "tgdp", "arrivals"))
  )

# ---------------------------------------------------------------------------
# Shock and recovery data (wide format, years 2015-2025)
# ---------------------------------------------------------------------------

shock_recovery <- analytical |>
  filter(year %in% c(2015:2025)) |>
  select(
    iso3,
    year,
    gdp_growth_pct,
    gdp_per_capita_usd,
    gdp_real_const2015usd,
    gdppc_real_const2015usd,
    unemployment_pct
  ) |>
  pivot_wider(
    names_from = year,
    values_from = c(
      gdp_growth_pct,
      gdp_per_capita_usd,
      gdp_real_const2015usd,
      gdppc_real_const2015usd,
      unemployment_pct
    ),
    names_sep = "_"
  )

# ---------------------------------------------------------------------------
# Assemble combined baseline + shock + recovery dataset
# ---------------------------------------------------------------------------

baseline <- bl_1519 |>
  left_join(
    bl_1719 |>
      select(iso3, starts_with(c("vspend", "receipts", "tgdp", "arrivals"))),
    by = "iso3"
  ) |>
  left_join(shock_recovery, by = "iso3") |>
  left_join(
    coverage |>
      select(
        iso3,
        in_primary_shock_sample,
        in_receipts_shock_sample,
        in_common_sample,
        in_recovery_sample,
        in_tourism_data_sample
      ),
    by = "iso3"
  )

write_csv(baseline, file.path(processed, "baseline_shock_recovery.csv"))
message("Baseline dataset saved: ", nrow(baseline), " rows")

# ---------------------------------------------------------------------------
# Coverage distribution report for 2015-2019 baseline
# ---------------------------------------------------------------------------

cat("\n================================================================\n")
cat("BASELINE COVERAGE DISTRIBUTION\n")
cat("================================================================\n\n")

for (spec_name in c("2015-2019", "2017-2019")) {
  sfx <- if (spec_name == "2015-2019") "_1519" else "_1719"

  cat("=== Baseline window:", spec_name, "===\n")
  for (ind_name in c("OWID vspend", "WDI receipts")) {
    col_n <- if (ind_name == "OWID vspend") {
      paste0("vspend_n", sfx)
    } else {
      paste0("receipts_n", sfx)
    }
    vals <- baseline[[col_n]]
    cat("  ", ind_name, "| obs per country distribution:\n")
    tbl <- table(vals[vals > 0], useNA = "no")
    print(tbl)
    cat("    Total with >=1 obs:", sum(vals >= 1, na.rm = TRUE), "\n")
    cat("    Total with >=3 obs:", sum(vals >= 3, na.rm = TRUE), "\n")
    cat("    Total with  5 obs:", sum(vals == 5, na.rm = TRUE), "\n")
  }
  cat("\n")
}

# Coverage restricted to fixed sample members
for (samp_name in c("OWID", "WDI", "Common")) {
  samp_col <- switch(
    samp_name,
    "OWID" = "in_primary_shock_sample",
    "WDI" = "in_receipts_shock_sample",
    "Common" = "in_common_sample"
  )
  ind_col_1519 <- switch(
    samp_name,
    "OWID" = "vspend_n_1519",
    "WDI" = "receipts_n_1519",
    "Common" = "vspend_n_1519"
  )
  ind_col_1719 <- sub("1519", "1719", ind_col_1519)

  samp <- baseline |> filter(.data[[samp_col]])
  cat("--- Fixed", samp_name, "sample (N =", nrow(samp), ") ---\n")
  cat("  2015-2019 obs counts:\n  ")
  print(table(samp[[ind_col_1519]]))
  cat(
    "  Countries with 0 obs in 2015-2019 baseline:",
    sum(samp[[ind_col_1519]] == 0),
    "\n"
  )
  cat("  Countries with 1 obs (thin):", sum(samp[[ind_col_1519]] == 1), "\n")
  cat("  2017-2019 obs counts:\n  ")
  print(table(samp[[ind_col_1719]]))
  cat(
    "  Countries with 0 obs in 2017-2019 baseline:",
    sum(samp[[ind_col_1719]] == 0),
    "\n"
  )
  cat("  Countries with 1 obs (thin):", sum(samp[[ind_col_1719]] == 1), "\n\n")
}

cat("Done: 02_data_quality.R\n")
