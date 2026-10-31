# =============================================================================
# 01_data_acquisition.R
# F1: Tourism Dependence and the COVID Cliff
# Purpose: Load OWID raw data; retrieve World Bank WDI indicators via wbstats.
# Run from: F1-tourism-covid/ (project root)
# =============================================================================

library(here)
library(readr)
library(dplyr)
library(wbstats)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

# OWID CSVs live in the repository-level data/raw/ (one level above this project root)
raw_owid  <- here("data", "raw")
raw_wb    <- here("data", "raw", "worldbank")
processed <- here("data", "processed")

dir.create(raw_wb,    showWarnings = FALSE, recursive = TRUE)
dir.create(processed, showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------------------
# Candidate country vector
# ---------------------------------------------------------------------------
# ~37 Caribbean and Pacific small island economies and territories.
# ISO3 codes used throughout.  Not all are UN-designated SIDS; the flag
# `is_sids` documents UN SIDS status separately.

candidates <- tibble::tribble(
  ~iso3,  ~country_name,                    ~region,     ~is_sids, ~is_territory,
  "ABW",  "Aruba",                           "Caribbean", FALSE,    TRUE,
  "AIA",  "Anguilla",                        "Caribbean", FALSE,    TRUE,
  "ATG",  "Antigua and Barbuda",             "Caribbean", TRUE,     FALSE,
  "BHS",  "Bahamas",                         "Caribbean", TRUE,     FALSE,
  "BRB",  "Barbados",                        "Caribbean", TRUE,     FALSE,
  "BLZ",  "Belize",                          "Caribbean", TRUE,     FALSE,
  "BMU",  "Bermuda",                         "Caribbean", FALSE,    TRUE,
  "BES",  "Bonaire, Sint Eustatius & Saba",  "Caribbean", FALSE,    TRUE,
  "CUW",  "Curaçao",                         "Caribbean", FALSE,    TRUE,
  "CYM",  "Cayman Islands",                  "Caribbean", FALSE,    TRUE,
  "DMA",  "Dominica",                        "Caribbean", TRUE,     FALSE,
  "DOM",  "Dominican Republic",              "Caribbean", TRUE,     FALSE,
  "GRD",  "Grenada",                         "Caribbean", TRUE,     FALSE,
  "GUY",  "Guyana",                          "Caribbean", TRUE,     FALSE,
  "HTI",  "Haiti",                           "Caribbean", TRUE,     FALSE,
  "JAM",  "Jamaica",                         "Caribbean", TRUE,     FALSE,
  "KNA",  "Saint Kitts and Nevis",           "Caribbean", TRUE,     FALSE,
  "LCA",  "Saint Lucia",                     "Caribbean", TRUE,     FALSE,
  "MSR",  "Montserrat",                      "Caribbean", FALSE,    TRUE,
  "PRI",  "Puerto Rico",                     "Caribbean", FALSE,    TRUE,
  "TCA",  "Turks and Caicos Islands",        "Caribbean", FALSE,    TRUE,
  "TTO",  "Trinidad and Tobago",             "Caribbean", TRUE,     FALSE,
  "VCT",  "Saint Vincent and the Grenadines","Caribbean", TRUE,     FALSE,
  "VGB",  "British Virgin Islands",          "Caribbean", FALSE,    TRUE,
  "VIR",  "US Virgin Islands",               "Caribbean", FALSE,    TRUE,
  "FJI",  "Fiji",                            "Pacific",   TRUE,     FALSE,
  "FSM",  "Micronesia (Fed. Sts.)",          "Pacific",   TRUE,     FALSE,
  "KIR",  "Kiribati",                        "Pacific",   TRUE,     FALSE,
  "MHL",  "Marshall Islands",                "Pacific",   TRUE,     FALSE,
  "NRU",  "Nauru",                           "Pacific",   TRUE,     FALSE,
  "PLW",  "Palau",                           "Pacific",   TRUE,     FALSE,
  "PNG",  "Papua New Guinea",                "Pacific",   TRUE,     FALSE,
  "SLB",  "Solomon Islands",                 "Pacific",   TRUE,     FALSE,
  "TON",  "Tonga",                           "Pacific",   TRUE,     FALSE,
  "TUV",  "Tuvalu",                          "Pacific",   TRUE,     FALSE,
  "VUT",  "Vanuatu",                         "Pacific",   TRUE,     FALSE,
  "WSM",  "Samoa",                           "Pacific",   TRUE,     FALSE
)

write_csv(candidates, file.path(processed, "candidates.csv"))
message("Candidate list saved: ", nrow(candidates), " economies")

# ---------------------------------------------------------------------------
# Load OWID datasets
# ---------------------------------------------------------------------------

# 1. Tourism contribution to GDP (SDG 8.9.1, Tourism Satellite Account methodology)
#    Units: % of GDP  |  Source: UNWTO via OWID
owid_tgdp <- read_csv(
  file.path(raw_owid, "tourism-gdp-proportion-of-total-gdp",
            "tourism-gdp-proportion-of-total-gdp.csv"),
  col_types = cols(
    Entity = col_character(),
    Code   = col_character(),
    Year   = col_integer(),
    `Tourism contribution to GDP` = col_double(),
    `World region according to OWID` = col_character()
  )
) |>
  rename(
    entity = Entity,
    iso3   = Code,
    year   = Year,
    tourism_gdp_pct = `Tourism contribution to GDP`,
    owid_region = `World region according to OWID`
  )

# 2. Spending by international visitors as share of GDP
#    Units: % of GDP  |  Source: World Bank WDI (ST.INT.XPND.GD.ZS) via OWID
owid_vspend <- read_csv(
  file.path(raw_owid,
            "spending-by-international-visitors-while-visiting-a-country-as-a-share-of-gdp",
            "spending-by-international-visitors-while-visiting-a-country-as-a-share-of-gdp.csv"),
  col_types = cols(
    Entity = col_character(),
    Code   = col_character(),
    Year   = col_integer(),
    `Spending by international visitors while visiting a country as a share of GDP` = col_double(),
    `World region according to OWID` = col_character()
  )
) |>
  rename(
    entity = Entity,
    iso3   = Code,
    year   = Year,
    visitor_spend_gdp_pct = `Spending by international visitors while visiting a country as a share of GDP`,
    owid_region = `World region according to OWID`
  )

# 3. International tourist arrivals (volume, not economic dependence)
#    Units: number of arrivals  |  Source: UNWTO via OWID
owid_arrivals <- read_csv(
  file.path(raw_owid, "international-tourist-trips",
            "international-tourist-trips.csv"),
  col_types = cols(
    Entity = col_character(),
    Code   = col_character(),
    Year   = col_integer(),
    `Arrivals of tourists from abroad` = col_double(),
    `World region according to OWID` = col_character()
  )
) |>
  rename(
    entity   = Entity,
    iso3     = Code,
    year     = Year,
    arrivals = `Arrivals of tourists from abroad`,
    owid_region = `World region according to OWID`
  )

message("OWID data loaded:")
message("  Tourism GDP: ", nrow(owid_tgdp), " rows, ",
        length(unique(owid_tgdp$iso3)), " countries, ",
        min(owid_tgdp$year), "-", max(owid_tgdp$year))
message("  Visitor Spending: ", nrow(owid_vspend), " rows, ",
        length(unique(owid_vspend$iso3)), " countries, ",
        min(owid_vspend$year), "-", max(owid_vspend$year))
message("  Tourist Arrivals: ", nrow(owid_arrivals), " rows, ",
        length(unique(owid_arrivals$iso3)), " countries, ",
        min(owid_arrivals$year), "-", max(owid_arrivals$year))

# ---------------------------------------------------------------------------
# Retrieve World Bank WDI indicators via wbstats
# ---------------------------------------------------------------------------
# Indicators:
#   ST.INT.RCPT.XP.ZS  Tourism receipts (% of total exports)
#   NY.GDP.PCAP.CD      GDP per capita (current US$)
#   NY.GDP.MKTP.KD.ZG   GDP growth (annual %)
#   SL.UEM.TOTL.ZS      Unemployment, total (% of labor force)

wb_indicators <- c(
  "ST.INT.RCPT.XP.ZS",
  "NY.GDP.PCAP.CD",
  "NY.GDP.MKTP.KD.ZG",
  "SL.UEM.TOTL.ZS"
)

wb_indicator_labels <- c(
  ST.INT.RCPT.XP.ZS = "tourism_receipts_pct_exports",
  NY.GDP.PCAP.CD    = "gdp_per_capita_usd",
  NY.GDP.MKTP.KD.ZG = "gdp_growth_pct",
  SL.UEM.TOTL.ZS    = "unemployment_pct"
)

message("Fetching World Bank data via wbstats (2008-2023)...")
wb_raw <- tryCatch(
  wb_data(
    indicator = wb_indicators,
    country   = candidates$iso3,
    start_date = 2008,
    end_date   = 2023,
    return_wide = TRUE
  ),
  error = function(e) {
    warning("World Bank API call failed: ", conditionMessage(e))
    NULL
  }
)

if (is.null(wb_raw)) {
  stop("Could not retrieve World Bank data. Check internet connection and wbstats package.")
}

# Rename columns to clean names
wb_clean <- wb_raw |>
  rename(
    iso3                      = iso3c,
    year                      = date,
    country_name_wb           = country,
    tourism_receipts_pct_exports = ST.INT.RCPT.XP.ZS,
    gdp_per_capita_usd        = NY.GDP.PCAP.CD,
    gdp_growth_pct            = NY.GDP.MKTP.KD.ZG,
    unemployment_pct          = SL.UEM.TOTL.ZS
  ) |>
  select(iso3, year, country_name_wb,
         tourism_receipts_pct_exports, gdp_per_capita_usd,
         gdp_growth_pct, unemployment_pct) |>
  arrange(iso3, year)

# Flag codes that WB silently dropped (not in response)
wb_returned <- unique(wb_clean$iso3)
wb_missing  <- setdiff(candidates$iso3, wb_returned)
if (length(wb_missing) > 0) {
  message("Codes NOT returned by WB API (no WDI coverage): ",
          paste(wb_missing, collapse = ", "))
} else {
  message("All candidate codes returned by WB API.")
}

# Save WB data
retrieval_date <- format(Sys.Date(), "%Y-%m-%d")
write_csv(wb_clean, file.path(raw_wb, "wdi_tourism_covid.csv"))
writeLines(
  c(
    paste("Retrieved:", retrieval_date),
    paste("Indicators:", paste(wb_indicators, collapse = ", ")),
    paste("Countries requested:", paste(candidates$iso3, collapse = ", ")),
    paste("Countries returned:", paste(sort(wb_returned), collapse = ", ")),
    paste("Countries missing:", paste(wb_missing, collapse = ", "))
  ),
  file.path(raw_wb, "wdi_retrieval_metadata.txt")
)

message("WB data saved: ", nrow(wb_clean), " rows, ",
        length(wb_returned), " countries, ",
        min(wb_clean$year), "-", max(wb_clean$year))

# ---------------------------------------------------------------------------
# Save cleaned OWID subsets (candidates only) to processed/
# ---------------------------------------------------------------------------

owid_tgdp_cand <- owid_tgdp |>
  filter(iso3 %in% candidates$iso3) |>
  left_join(select(candidates, iso3, region, is_sids, is_territory), by = "iso3")

owid_vspend_cand <- owid_vspend |>
  filter(iso3 %in% candidates$iso3) |>
  left_join(select(candidates, iso3, region, is_sids, is_territory), by = "iso3")

owid_arrivals_cand <- owid_arrivals |>
  filter(iso3 %in% candidates$iso3) |>
  left_join(select(candidates, iso3, region, is_sids, is_territory), by = "iso3")

write_csv(owid_tgdp_cand,    file.path(processed, "owid_tourism_gdp.csv"))
write_csv(owid_vspend_cand,  file.path(processed, "owid_visitor_spending.csv"))
write_csv(owid_arrivals_cand, file.path(processed, "owid_arrivals.csv"))

message("Processed OWID subsets saved.")
message("Done: 01_data_acquisition.R")
