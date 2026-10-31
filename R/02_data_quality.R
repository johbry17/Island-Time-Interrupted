# =============================================================================
# 02_data_quality.R
# F1: Tourism Dependence and the COVID Cliff
# Purpose: Build country-level coverage matrix; produce feasibility audit stats.
# Depends on: 01_data_acquisition.R having been run first.
# Run from: F1-tourism-covid/ (project root)
# =============================================================================

library(here)
library(readr)
library(dplyr)
library(tidyr)

processed <- here("data", "processed")

# ---------------------------------------------------------------------------
# Load processed data
# ---------------------------------------------------------------------------

candidates  <- read_csv(file.path(processed, "candidates.csv"),           show_col_types = FALSE)
tgdp        <- read_csv(file.path(processed, "owid_tourism_gdp.csv"),     show_col_types = FALSE)
vspend      <- read_csv(file.path(processed, "owid_visitor_spending.csv"),show_col_types = FALSE)
arrivals    <- read_csv(file.path(processed, "owid_arrivals.csv"),        show_col_types = FALSE)
wb          <- read_csv(file.path(here("data","raw","worldbank"), "wdi_tourism_covid.csv"),
                        show_col_types = FALSE)

# ---------------------------------------------------------------------------
# Helper: count non-NA observations in a given year range
# ---------------------------------------------------------------------------

n_obs <- function(df, code_col, val_col, years) {
  df |>
    filter(.data[[code_col]] %in% years) |>
    group_by(iso3) |>
    summarise(n = sum(!is.na(.data[[val_col]])), .groups = "drop")
}

# ---------------------------------------------------------------------------
# Build indicator-level presence flags for each candidate
# ---------------------------------------------------------------------------

base <- candidates |> select(iso3, country_name, region, is_sids, is_territory)

# -- Tourism GDP (OWID) 2017-2019 --
tgdp_cover <- tgdp |>
  filter(year %in% 2017:2019, !is.na(tourism_gdp_pct)) |>
  group_by(iso3) |>
  summarise(owid_tgdp_n_1719 = n(), .groups = "drop")

# -- Visitor spending (OWID) 2017-2019 --
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

# -- WDI tourism receipts 2017-2019 --
wb_receipts_cover <- wb |>
  filter(year %in% 2017:2019, !is.na(tourism_receipts_pct_exports)) |>
  group_by(iso3) |>
  summarise(wb_receipts_n_1719 = n(), .groups = "drop")

# -- WDI GDP growth 2020 --
wb_gdpgrowth_2020 <- wb |>
  filter(year == 2020, !is.na(gdp_growth_pct)) |>
  group_by(iso3) |>
  summarise(wb_gdpgrowth_2020 = 1L, .groups = "drop")

# -- WDI GDP per capita 2019, 2020, 2022, 2023 --
wb_gdppc_cover <- wb |>
  filter(year %in% c(2019, 2020, 2022, 2023), !is.na(gdp_per_capita_usd)) |>
  group_by(iso3) |>
  summarise(wb_gdppc_n_req = n(), .groups = "drop")   # max = 4

# -- WDI unemployment 2019, 2020, 2022, 2023 --
wb_unem_cover <- wb |>
  filter(year %in% c(2019, 2020, 2022, 2023), !is.na(unemployment_pct)) |>
  group_by(iso3) |>
  summarise(wb_unem_n_req = n(), .groups = "drop")

# ---------------------------------------------------------------------------
# Assemble coverage matrix
# ---------------------------------------------------------------------------

coverage <- base |>
  left_join(tgdp_cover,         by = "iso3") |>
  left_join(vsp_cover,          by = "iso3") |>
  left_join(arr_1719_cover,     by = "iso3") |>
  left_join(arr_2020_cover,     by = "iso3") |>
  left_join(wb_receipts_cover,  by = "iso3") |>
  left_join(wb_gdpgrowth_2020,  by = "iso3") |>
  left_join(wb_gdppc_cover,     by = "iso3") |>
  left_join(wb_unem_cover,      by = "iso3") |>
  mutate(across(where(is.integer) | where(is.double),
                ~ replace_na(., 0L))) |>
  mutate(
    # Baseline tourism flags
    has_tgdp_baseline    = owid_tgdp_n_1719 > 0,
    has_vspend_baseline  = owid_vspend_n_1719 > 0,
    has_receipts_baseline = wb_receipts_n_1719 > 0,
    has_any_tourism      = has_tgdp_baseline | has_vspend_baseline | has_receipts_baseline,

    # Thin baseline flag (only 1 pre-pandemic observation)
    tgdp_thin_baseline   = owid_tgdp_n_1719 == 1,
    vspend_thin_baseline = owid_vspend_n_1719 == 1,
    receipts_thin_baseline = wb_receipts_n_1719 == 1,

    # Shock
    has_gdpgrowth_2020   = wb_gdpgrowth_2020 == 1,

    # Recovery
    has_gdppc_recovery   = wb_gdppc_n_req >= 2,   # 2019 + at least one of 2022/2023
    has_unem_recovery    = wb_unem_n_req >= 2,

    # Core analysis eligibility
    # Requires: at least one tourism baseline + 2020 GDP growth
    eligible_shock       = has_any_tourism & has_gdpgrowth_2020,

    # Full analysis eligibility: shock-eligible + some recovery data
    eligible_full        = eligible_shock & has_gdppc_recovery
  )

write_csv(coverage, file.path(processed, "country_coverage.csv"))
message("Coverage matrix saved: ", file.path(processed, "country_coverage.csv"))

# ---------------------------------------------------------------------------
# Aggregate feasibility statistics
# ---------------------------------------------------------------------------

cat("\n============================================================\n")
cat("FEASIBILITY AUDIT — AGGREGATE STATISTICS\n")
cat("============================================================\n\n")

cat("1. Total candidate economies:", nrow(candidates), "\n")

cat("2. Economies with at least one tourism-dependence indicator (2017-2019):\n")
cat("   Any indicator:           ", sum(coverage$has_any_tourism), "\n")
cat("   Tourism GDP (OWID):      ", sum(coverage$has_tgdp_baseline), "\n")
cat("   Visitor Spending (OWID): ", sum(coverage$has_vspend_baseline), "\n")
cat("   Receipts % Exports (WB): ", sum(coverage$has_receipts_baseline), "\n")

cat("\n3. Economies with tourism exposure AND 2020 GDP growth:\n")
cat("   Shock-eligible:          ", sum(coverage$eligible_shock), "\n")

cat("\n4. Economies sufficient for recovery analysis:\n")
cat("   Full-eligible:           ", sum(coverage$eligible_full), "\n")

cat("\n5. Coverage by region:\n")
coverage |>
  group_by(region) |>
  summarise(
    n_total     = n(),
    n_any_tour  = sum(has_any_tourism),
    n_shock     = sum(eligible_shock),
    n_full      = sum(eligible_full),
    .groups = "drop"
  ) |>
  print()

cat("\n6. Coverage by SIDS vs. territory:\n")
coverage |>
  mutate(status = case_when(
    is_sids      ~ "UN SIDS",
    is_territory ~ "Territory/Dependency",
    TRUE         ~ "Other"
  )) |>
  group_by(status) |>
  summarise(
    n_total     = n(),
    n_any_tour  = sum(has_any_tourism),
    n_shock     = sum(eligible_shock),
    n_full      = sum(eligible_full),
    .groups = "drop"
  ) |>
  print()

cat("\n7. Countries with thin baseline (single pre-pandemic obs):\n")
coverage |>
  filter(receipts_thin_baseline | vspend_thin_baseline | tgdp_thin_baseline) |>
  select(iso3, country_name, region,
         wb_receipts_n_1719, owid_vspend_n_1719, owid_tgdp_n_1719) |>
  print(n = 40)

cat("\n8. Shock-eligible countries:\n")
coverage |>
  filter(eligible_shock) |>
  select(iso3, country_name, region, is_sids, is_territory,
         wb_receipts_n_1719, owid_vspend_n_1719, wb_gdppc_n_req) |>
  arrange(region, country_name) |>
  print(n = 40)

cat("\n9. Countries with NO usable tourism indicator:\n")
coverage |>
  filter(!has_any_tourism) |>
  select(iso3, country_name, region, is_sids) |>
  print(n = 40)

# ---------------------------------------------------------------------------
# Build the analytical dataset
# ---------------------------------------------------------------------------
# Join all indicators into one country-year panel for candidates with any data.

wb_panel <- wb |>
  filter(iso3 %in% candidates$iso3) |>
  left_join(select(candidates, iso3, country_name, region, is_sids, is_territory),
            by = "iso3")

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

analytical <- wb_panel |>
  left_join(owid_panel, by = c("iso3", "year")) |>
  arrange(iso3, year)

write_csv(analytical, file.path(processed, "analytical_panel.csv"))
message("Analytical panel saved: ", nrow(analytical), " rows, ",
        length(unique(analytical$iso3)), " countries")

# ---------------------------------------------------------------------------
# Pre-pandemic tourism baseline (2017-2019 means)
# ---------------------------------------------------------------------------

baseline_tourism <- analytical |>
  filter(year %in% 2017:2019) |>
  group_by(iso3, country_name, region, is_sids, is_territory) |>
  summarise(
    receipts_mean_1719     = mean(tourism_receipts_pct_exports, na.rm = TRUE),
    receipts_n_1719        = sum(!is.na(tourism_receipts_pct_exports)),
    vspend_mean_1719       = mean(visitor_spend_gdp_pct, na.rm = TRUE),
    vspend_n_1719          = sum(!is.na(visitor_spend_gdp_pct)),
    tgdp_mean_1719         = mean(tourism_gdp_pct, na.rm = TRUE),
    tgdp_n_1719            = sum(!is.na(tourism_gdp_pct)),
    arrivals_mean_1719     = mean(arrivals, na.rm = TRUE),
    arrivals_n_1719        = sum(!is.na(arrivals)),
    .groups = "drop"
  ) |>
  mutate(
    # Replace NaN (all-NA mean) with NA
    across(where(is.double), ~ if_else(is.nan(.), NA_real_, .)),
    receipts_thin = receipts_n_1719 == 1,
    vspend_thin   = vspend_n_1719 == 1
  )

# Add 2020 GDP growth and GDP per capita
shock_recovery <- analytical |>
  filter(year %in% c(2019, 2020, 2021, 2022, 2023)) |>
  select(iso3, year, gdp_growth_pct, gdp_per_capita_usd, unemployment_pct) |>
  pivot_wider(
    names_from  = year,
    values_from = c(gdp_growth_pct, gdp_per_capita_usd, unemployment_pct),
    names_sep   = "_"
  )

baseline <- baseline_tourism |>
  left_join(shock_recovery, by = "iso3")

write_csv(baseline, file.path(processed, "baseline_shock_recovery.csv"))
message("Baseline + shock + recovery dataset saved: ", nrow(baseline), " rows")

message("Done: 02_data_quality.R")
