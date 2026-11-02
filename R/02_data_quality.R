# =============================================================================
# 02_data_quality.R
# Island Time, Interrupted: Tourism Dependence and the COVID Cliff
# Purpose: Build country-level coverage matrix; produce feasibility audit stats.
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

candidates <- read_csv(file.path(processed, "candidates.csv"),            show_col_types = FALSE)
tgdp       <- read_csv(file.path(processed, "owid_tourism_gdp.csv"),      show_col_types = FALSE)
vspend     <- read_csv(file.path(processed, "owid_visitor_spending.csv"), show_col_types = FALSE)
arrivals   <- read_csv(file.path(processed, "owid_arrivals.csv"),         show_col_types = FALSE)
wb         <- read_csv(file.path(here("data","raw","worldbank"), "wdi_tourism_covid.csv"),
                       show_col_types = FALSE)

# ---------------------------------------------------------------------------
# Build indicator-level coverage counts for each candidate
# ---------------------------------------------------------------------------

base <- candidates |>
  select(iso3, country, sids_region, sids_status, political_status)

# -- Tourism GDP (OWID) 2017-2019 --
tgdp_cover <- tgdp |>
  filter(year %in% 2017:2019, !is.na(tourism_gdp_pct)) |>
  group_by(iso3) |>
  summarise(owid_tgdp_n_1719 = n(), .groups = "drop")

# -- Visitor spending (OWID) 2017-2019 --  PRIMARY tourism indicator
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

# -- WDI tourism receipts 2017-2019 --  COMPLEMENTARY measure
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

# -- WDI real GDP (constant 2015 USD) key years --
wb_gdpreal_cover <- wb |>
  filter(year %in% c(2019, 2020, 2022, 2023), !is.na(gdp_real_const2015usd)) |>
  group_by(iso3) |>
  summarise(wb_gdpreal_n_req = n(), .groups = "drop")

# -- WDI real GDP per capita (constant 2015 USD) key years --
wb_gdppcreal_cover <- wb |>
  filter(year %in% c(2019, 2020, 2022, 2023), !is.na(gdppc_real_const2015usd)) |>
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
  left_join(tgdp_cover,         by = "iso3") |>
  left_join(vsp_cover,          by = "iso3") |>
  left_join(arr_1719_cover,     by = "iso3") |>
  left_join(arr_2020_cover,     by = "iso3") |>
  left_join(wb_receipts_cover,  by = "iso3") |>
  left_join(wb_gdpgrowth_2020,  by = "iso3") |>
  left_join(wb_gdppc_cover,     by = "iso3") |>
  left_join(wb_gdpreal_cover,   by = "iso3") |>
  left_join(wb_gdppcreal_cover, by = "iso3") |>
  left_join(wb_unem_cover,      by = "iso3") |>
  mutate(across(where(is.integer) | where(is.double),
                ~ replace_na(., 0L))) |>
  mutate(
    # Tourism baseline flags
    has_tgdp_baseline     = owid_tgdp_n_1719 > 0,
    has_vspend_baseline   = owid_vspend_n_1719 > 0,
    has_receipts_baseline = wb_receipts_n_1719 > 0,
    has_any_tourism       = has_tgdp_baseline | has_vspend_baseline | has_receipts_baseline,

    # Thin baseline (single observation) flags
    tgdp_thin_baseline    = owid_tgdp_n_1719 == 1,
    vspend_thin_baseline  = owid_vspend_n_1719 == 1,
    receipts_thin_baseline = wb_receipts_n_1719 == 1,

    # 2020 shock availability
    has_gdpgrowth_2020    = wb_gdpgrowth_2020 == 1,

    # Real GDP recovery data (constant 2015 USD)
    has_real_gdp_recovery = wb_gdpreal_n_req >= 2,   # need 2019 + at least one of 2022/2023
    has_real_gdppc_recovery = wb_gdppcreal_n_req >= 2,

    # ── Four-tier sample definitions ─────────────────────────────────────
    # 1. Tourism-data sample: any usable tourism baseline indicator
    in_tourism_data_sample  = has_any_tourism,

    # 2. Primary shock sample: PRIMARY indicator (OWID vspend) + 2020 GDP growth
    #    Use vspend as primary; fall back to receipts only for complementary analysis
    in_primary_shock_sample = has_vspend_baseline & has_gdpgrowth_2020,

    # 2b. Receipts shock sample (complementary/sensitivity)
    in_receipts_shock_sample = has_receipts_baseline & has_gdpgrowth_2020,

    # 3. Recovery sample: primary shock-eligible + real GDP recovery data
    in_recovery_sample      = in_primary_shock_sample & has_real_gdp_recovery
  )

write_csv(coverage, file.path(processed, "country_coverage.csv"))
message("Coverage matrix saved: ", file.path(processed, "country_coverage.csv"))

# ---------------------------------------------------------------------------
# Feasibility audit statistics
# ---------------------------------------------------------------------------

cat("\n================================================================\n")
cat("FEASIBILITY AUDIT — AGGREGATE STATISTICS\n")
cat("================================================================\n\n")

cat("── CANDIDATE UNIVERSE ──────────────────────────────────────────\n")
cat("Total candidate economies:", nrow(candidates), "\n")
cat("  UN Member SIDS:        ", sum(candidates$sids_status == "UN Member SIDS"), "\n")
cat("  Associate Member SIDS: ", sum(candidates$sids_status == "Associate Member SIDS"), "\n")
cat("  Other island economy:  ", sum(candidates$sids_status == "Other island economy"), "\n")
cat("  Caribbean:             ", sum(candidates$sids_region == "Caribbean"), "\n")
cat("  Pacific:               ", sum(candidates$sids_region == "Pacific"), "\n")
cat("  AIMS:                  ", sum(candidates$sids_region == "AIMS"), "\n")

cat("\n── TOURISM-DATA SAMPLE ─────────────────────────────────────────\n")
cat("Economies with at least one tourism indicator (2017-2019):\n")
cat("  Any indicator (tourism-data sample):", sum(coverage$in_tourism_data_sample), "\n")
cat("  OWID visitor spending (% GDP):      ", sum(coverage$has_vspend_baseline), "\n")
cat("  WDI tourism receipts (% exports):   ", sum(coverage$has_receipts_baseline), "\n")
cat("  OWID tourism GDP (% GDP):           ", sum(coverage$has_tgdp_baseline), "\n")

cat("\n── PRIMARY SHOCK SAMPLE ────────────────────────────────────────\n")
cat("Economies with OWID vspend baseline AND 2020 GDP growth:\n")
cat("  Primary shock sample:  ", sum(coverage$in_primary_shock_sample), "\n")
cat("  (WDI receipts-based):  ", sum(coverage$in_receipts_shock_sample), "\n")

cat("\n── RECOVERY SAMPLE ─────────────────────────────────────────────\n")
cat("Economies in primary shock sample WITH real GDP recovery data:\n")
cat("  Recovery sample:       ", sum(coverage$in_recovery_sample), "\n")
cat("  (real GDP, const USD): ", sum(coverage$has_real_gdp_recovery), "\n")
cat("  (real GDP/cap):        ", sum(coverage$has_real_gdppc_recovery), "\n")

cat("\n── COVERAGE BY SIDS REGION ─────────────────────────────────────\n")
coverage |>
  group_by(sids_region) |>
  summarise(
    n_candidate    = n(),
    n_any_tourism  = sum(in_tourism_data_sample),
    n_primary_shock = sum(in_primary_shock_sample),
    n_recovery     = sum(in_recovery_sample),
    .groups = "drop"
  ) |>
  print()

cat("\n── COVERAGE BY SIDS STATUS ─────────────────────────────────────\n")
coverage |>
  group_by(sids_status) |>
  summarise(
    n_candidate     = n(),
    n_any_tourism   = sum(in_tourism_data_sample),
    n_primary_shock = sum(in_primary_shock_sample),
    n_recovery      = sum(in_recovery_sample),
    .groups = "drop"
  ) |>
  print()

cat("\n── THIN BASELINES (single pre-pandemic observation) ────────────\n")
coverage |>
  filter(vspend_thin_baseline | receipts_thin_baseline | tgdp_thin_baseline) |>
  select(iso3, country, sids_region,
         owid_vspend_n_1719, wb_receipts_n_1719, owid_tgdp_n_1719) |>
  arrange(sids_region, country) |>
  print(n = 40)

cat("\n── PRIMARY SHOCK SAMPLE: country list ──────────────────────────\n")
coverage |>
  filter(in_primary_shock_sample) |>
  select(iso3, country, sids_region, sids_status,
         owid_vspend_n_1719, wb_receipts_n_1719, wb_gdpreal_n_req) |>
  arrange(sids_region, country) |>
  print(n = 60)

cat("\n── NO USABLE TOURISM INDICATOR ──────────────────────────────────\n")
coverage |>
  filter(!in_tourism_data_sample) |>
  select(iso3, country, sids_region, sids_status) |>
  arrange(sids_region, country) |>
  print(n = 40)

# ---------------------------------------------------------------------------
# Build the analytical dataset (country-year panel)
# ---------------------------------------------------------------------------

wb_panel <- wb |>
  filter(iso3 %in% candidates$iso3) |>
  left_join(select(candidates, iso3, country, sids_region, sids_status, political_status),
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
# Pre-pandemic baseline (2017-2019 means) + shock + recovery
# ---------------------------------------------------------------------------

baseline_tourism <- analytical |>
  filter(year %in% 2017:2019) |>
  group_by(iso3, country, sids_region, sids_status, political_status) |>
  summarise(
    vspend_mean_1719   = mean(visitor_spend_gdp_pct,      na.rm = TRUE),
    vspend_n_1719      = sum(!is.na(visitor_spend_gdp_pct)),
    receipts_mean_1719 = mean(tourism_receipts_pct_exports, na.rm = TRUE),
    receipts_n_1719    = sum(!is.na(tourism_receipts_pct_exports)),
    tgdp_mean_1719     = mean(tourism_gdp_pct,             na.rm = TRUE),
    tgdp_n_1719        = sum(!is.na(tourism_gdp_pct)),
    arrivals_mean_1719 = mean(arrivals,                    na.rm = TRUE),
    arrivals_n_1719    = sum(!is.na(arrivals)),
    .groups = "drop"
  ) |>
  mutate(
    across(where(is.double), ~ if_else(is.nan(.), NA_real_, .)),
    vspend_thin   = vspend_n_1719 == 1,
    receipts_thin = receipts_n_1719 == 1
  )

shock_recovery <- analytical |>
  filter(year %in% c(2019, 2020, 2021, 2022, 2023)) |>
  select(iso3, year, gdp_growth_pct, gdp_per_capita_usd,
         gdp_real_const2015usd, gdppc_real_const2015usd, unemployment_pct) |>
  pivot_wider(
    names_from  = year,
    values_from = c(gdp_growth_pct, gdp_per_capita_usd,
                    gdp_real_const2015usd, gdppc_real_const2015usd,
                    unemployment_pct),
    names_sep   = "_"
  )

baseline <- baseline_tourism |>
  left_join(shock_recovery, by = "iso3")

write_csv(baseline, file.path(processed, "baseline_shock_recovery.csv"))
message("Baseline + shock + recovery dataset saved: ", nrow(baseline), " rows")

message("Done: 02_data_quality.R")
