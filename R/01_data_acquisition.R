# =============================================================================
# 01_data_acquisition.R
# Island Time, Interrupted: Tourism Dependence and the COVID Cliff
# Purpose: Load OWID raw data; retrieve World Bank WDI indicators via wbstats.
# Run from: repository root (here() anchors at .git)
# =============================================================================

library(here)
library(readr)
library(dplyr)
library(wbstats)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

raw_owid <- here("data", "raw")
raw_wb <- here("data", "raw", "worldbank")
processed <- here("data", "processed")

dir.create(raw_wb, showWarnings = FALSE, recursive = TRUE)
dir.create(processed, showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------------------
# Candidate universe
# ---------------------------------------------------------------------------
# 58 economies: all OHRLLS-listed SIDS (39) + Associate Members of UN Regional
# Commissions included in the SIDS group (18) + one non-listed island economy (BES).
# Authority: UN-OHRLLS list of SIDS, retrieved November 2026.
# https://www.un.org/ohrlls/content/list-sids
#
# sids_status:
#   "OHRLLS-listed SIDS"   — 39 economies formally listed as SIDS by UN-OHRLLS.
#                            Includes Cook Islands and Niue, which are sovereign
#                            states in free association with New Zealand and are
#                            NOT UN General Assembly member states, but appear on
#                            the OHRLLS list.
#   "Associate Member SIDS"— associate members of UN Regional Commissions
#                            included in the SIDS group (non-sovereign territories)
#   "Other island economy" — island economies not listed by UN-OHRLLS (BES)
#
# sids_region:
#   "Caribbean" | "Pacific" | "AIMS" (Atlantic, Indian Ocean, Med., S. China Sea)
#
# political_status:
#   "Sovereign state"      — independent state with full international personality
#   "Territory/Dependency" — non-sovereign; includes British Overseas Territories,
#                            US territories, Dutch special municipalities/countries,
#                            French collectivités and départements

candidates <- tibble::tribble(
  ~iso3 , ~country                           , ~sids_region , ~sids_status            , ~political_status      , ~source         , ~notes                                                                   ,
  # ── CARIBBEAN: OHRLLS-listed SIDS ─────────────────────────────────────────
  "ATG" , "Antigua and Barbuda"              , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "BHS" , "Bahamas"                          , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "BRB" , "Barbados"                         , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "BLZ" , "Belize"                           , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "CUB" , "Cuba"                             , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "DMA" , "Dominica"                         , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "DOM" , "Dominican Republic"               , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "GRD" , "Grenada"                          , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "GUY" , "Guyana"                           , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "HTI" , "Haiti"                            , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "LDC"                                                                    ,
  "JAM" , "Jamaica"                          , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "KNA" , "Saint Kitts and Nevis"            , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "LCA" , "Saint Lucia"                      , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "SUR" , "Suriname"                         , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "TTO" , "Trinidad and Tobago"              , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "VCT" , "Saint Vincent and the Grenadines" , "Caribbean"  , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  # ── CARIBBEAN: Associate Member SIDS ─────────────────────────────────────
  "AIA" , "Anguilla"                         , "Caribbean"  , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "British Overseas Territory"                                             ,
  "ABW" , "Aruba"                            , "Caribbean"  , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "Constituent country, Kingdom of the Netherlands"                        ,
  "BMU" , "Bermuda"                          , "Caribbean"  , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "British Overseas Territory"                                             ,
  "VGB" , "British Virgin Islands"           , "Caribbean"  , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "British Overseas Territory"                                             ,
  "CYM" , "Cayman Islands"                   , "Caribbean"  , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "British Overseas Territory"                                             ,
  "CUW" , "Curaçao"                          , "Caribbean"  , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "Constituent country, Kingdom of the Netherlands"                        ,
  "GLP" , "Guadeloupe"                       , "Caribbean"  , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "French overseas department"                                             ,
  "MTQ" , "Martinique"                       , "Caribbean"  , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "French overseas department"                                             ,
  "MSR" , "Montserrat"                       , "Caribbean"  , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "British Overseas Territory"                                             ,
  "PRI" , "Puerto Rico"                      , "Caribbean"  , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "US Commonwealth territory"                                              ,
  "SXM" , "Sint Maarten"                     , "Caribbean"  , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "Constituent country, Kingdom of the Netherlands"                        ,
  "TCA" , "Turks and Caicos Islands"         , "Caribbean"  , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "British Overseas Territory"                                             ,
  "VIR" , "US Virgin Islands"                , "Caribbean"  , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "US unincorporated territory"                                            ,
  # ── CARIBBEAN: Other island economy ──────────────────────────────────────
  "BES" , "Bonaire, Sint Eustatius and Saba" , "Caribbean"  , "Other island economy"  , "Territory/Dependency" , "Not UN-listed" , "Dutch special municipalities; not on UN SIDS list"                      ,
  # ── PACIFIC: UN Member SIDS ───────────────────────────────────────────────
  "COK" , "Cook Islands"                     , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "Free association with New Zealand"                                      ,
  "FJI" , "Fiji"                             , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "KIR" , "Kiribati"                         , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "LDC"                                                                    ,
  "MHL" , "Marshall Islands"                 , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "FSM" , "Micronesia (Fed. Sts.)"           , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "NRU" , "Nauru"                            , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "NIU" , "Niue"                             , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "Free association with New Zealand"                                      ,
  "PLW" , "Palau"                            , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "PNG" , "Papua New Guinea"                 , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "WSM" , "Samoa"                            , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "SLB" , "Solomon Islands"                  , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "LDC"                                                                    ,
  "TLS" , "Timor-Leste"                      , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "LDC; classified with Pacific SIDS by UN"                                ,
  "TON" , "Tonga"                            , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  "TUV" , "Tuvalu"                           , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "LDC"                                                                    ,
  "VUT" , "Vanuatu"                          , "Pacific"    , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , ""                                                                       ,
  # ── PACIFIC: Associate Member SIDS ───────────────────────────────────────
  "ASM" , "American Samoa"                   , "Pacific"    , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "US unincorporated territory"                                            ,
  "MNP" , "Northern Mariana Islands"         , "Pacific"    , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "US Commonwealth territory; listed as Commonwealth of Northern Marianas" ,
  "PYF" , "French Polynesia"                 , "Pacific"    , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "French overseas collectivity"                                           ,
  "GUM" , "Guam"                             , "Pacific"    , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "US unincorporated territory"                                            ,
  "NCL" , "New Caledonia"                    , "Pacific"    , "Associate Member SIDS" , "Territory/Dependency" , "UN-OHRLLS"     , "French special collectivity"                                            ,
  # ── AIMS: UN Member SIDS ─────────────────────────────────────────────────
  # Atlantic, Indian Ocean, Mediterranean, and South China Sea
  "CPV" , "Cabo Verde"                       , "AIMS"       , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "Atlantic"                                                               ,
  "COM" , "Comoros"                          , "AIMS"       , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "Indian Ocean; LDC"                                                      ,
  "GNB" , "Guinea-Bissau"                    , "AIMS"       , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "Atlantic; LDC"                                                          ,
  "MDV" , "Maldives"                         , "AIMS"       , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "Indian Ocean"                                                           ,
  "MUS" , "Mauritius"                        , "AIMS"       , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "Indian Ocean"                                                           ,
  "STP" , "São Tomé and Príncipe"            , "AIMS"       , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "Atlantic"                                                               ,
  "SYC" , "Seychelles"                       , "AIMS"       , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "Indian Ocean"                                                           ,
  "SGP" , "Singapore"                        , "AIMS"       , "OHRLLS-listed SIDS"    , "Sovereign state"      , "UN-OHRLLS"     , "South China Sea"
)

write_csv(candidates, file.path(processed, "candidates.csv"))
message("Candidate list saved: ", nrow(candidates), " economies")
message(
  "  OHRLLS-listed SIDS:       ",
  sum(candidates$sids_status == "OHRLLS-listed SIDS")
)
message(
  "  Associate Member SIDS:",
  sum(candidates$sids_status == "Associate Member SIDS")
)
message(
  "  Other island economy: ",
  sum(candidates$sids_status == "Other island economy")
)
message("  Caribbean: ", sum(candidates$sids_region == "Caribbean"))
message("  Pacific:   ", sum(candidates$sids_region == "Pacific"))
message("  AIMS:      ", sum(candidates$sids_region == "AIMS"))

# ---------------------------------------------------------------------------
# Load OWID datasets
# ---------------------------------------------------------------------------

# 1. Tourism contribution to GDP (SDG 8.9.1, Tourism Satellite Account methodology)
#    Units: % of GDP  |  Source: UNWTO via OWID
owid_tgdp <- read_csv(
  file.path(
    raw_owid,
    "tourism-gdp-proportion-of-total-gdp",
    "tourism-gdp-proportion-of-total-gdp.csv"
  ),
  col_types = cols(
    Entity = col_character(),
    Code = col_character(),
    Year = col_integer(),
    `Tourism contribution to GDP` = col_double(),
    `World region according to OWID` = col_character()
  )
) |>
  rename(
    entity = Entity,
    iso3 = Code,
    year = Year,
    tourism_gdp_pct = `Tourism contribution to GDP`,
    owid_region = `World region according to OWID`
  )

# 2. Spending by international visitors as share of GDP
#    Units: % of GDP
#    Source: UN Tourism (2025); National statistical organizations and central
#    banks, OECD national accounts, and World Bank staff estimates — processed
#    by Our World in Data. OWID variable ID: 1146095.
#    Note: This is NOT sourced from a single World Bank indicator code.
#    The denominator (GDP) is from WB; the numerator (inbound receipts) is from
#    UN Tourism statistics. Do not attribute to ST.INT.XPND.GD.ZS (unverified).
owid_vspend <- read_csv(
  file.path(
    raw_owid,
    "spending-by-international-visitors-while-visiting-a-country-as-a-share-of-gdp",
    "spending-by-international-visitors-while-visiting-a-country-as-a-share-of-gdp.csv"
  ),
  col_types = cols(
    Entity = col_character(),
    Code = col_character(),
    Year = col_integer(),
    `Spending by international visitors while visiting a country as a share of GDP` = col_double(),
    `World region according to OWID` = col_character()
  )
) |>
  rename(
    entity = Entity,
    iso3 = Code,
    year = Year,
    visitor_spend_gdp_pct = `Spending by international visitors while visiting a country as a share of GDP`,
    owid_region = `World region according to OWID`
  )

# 3. International tourist arrivals (volume, not economic dependence)
#    Units: number of arrivals  |  Source: UNWTO via OWID
owid_arrivals <- read_csv(
  file.path(
    raw_owid,
    "international-tourist-trips",
    "international-tourist-trips.csv"
  ),
  col_types = cols(
    Entity = col_character(),
    Code = col_character(),
    Year = col_integer(),
    `Arrivals of tourists from abroad` = col_double(),
    `World region according to OWID` = col_character()
  )
) |>
  rename(
    entity = Entity,
    iso3 = Code,
    year = Year,
    arrivals = `Arrivals of tourists from abroad`,
    owid_region = `World region according to OWID`
  )

message("OWID data loaded:")
message(
  "  Tourism GDP: ",
  nrow(owid_tgdp),
  " rows, ",
  length(unique(owid_tgdp$iso3)),
  " countries, ",
  min(owid_tgdp$year),
  "-",
  max(owid_tgdp$year)
)
message(
  "  Visitor Spending: ",
  nrow(owid_vspend),
  " rows, ",
  length(unique(owid_vspend$iso3)),
  " countries, ",
  min(owid_vspend$year),
  "-",
  max(owid_vspend$year)
)
message(
  "  Tourist Arrivals: ",
  nrow(owid_arrivals),
  " rows, ",
  length(unique(owid_arrivals$iso3)),
  " countries, ",
  min(owid_arrivals$year),
  "-",
  max(owid_arrivals$year)
)

# ---------------------------------------------------------------------------
# Retrieve World Bank WDI indicators via wbstats
# ---------------------------------------------------------------------------
# Indicators:
#   ST.INT.RCPT.XP.ZS  Tourism receipts (% of total exports)
#   NY.GDP.PCAP.CD      GDP per capita (current US$) — for comparison only
#   NY.GDP.MKTP.KD.ZG   GDP growth (annual %)
#   NY.GDP.MKTP.KD      GDP, constant 2015 US$ — primary real recovery measure
#   NY.GDP.PCAP.KD      GDP per capita, constant 2015 US$
#   SL.UEM.TOTL.ZS      Unemployment, total (% of labor force)

wb_indicators <- c(
  "ST.INT.RCPT.XP.ZS",
  "NY.GDP.PCAP.CD",
  "NY.GDP.MKTP.KD.ZG",
  "NY.GDP.MKTP.KD",
  "NY.GDP.PCAP.KD",
  "SL.UEM.TOTL.ZS"
)

wb_indicator_labels <- c(
  ST.INT.RCPT.XP.ZS = "tourism_receipts_pct_exports",
  NY.GDP.PCAP.CD = "gdp_per_capita_usd",
  NY.GDP.MKTP.KD.ZG = "gdp_growth_pct",
  NY.GDP.MKTP.KD = "gdp_real_const2015usd",
  NY.GDP.PCAP.KD = "gdppc_real_const2015usd",
  SL.UEM.TOTL.ZS = "unemployment_pct"
)

message("Fetching World Bank data via wbstats (2008-2025)...")
# Note: ST.INT.RCPT.XP.ZS (tourism receipts) contains no observations beyond 2020
# in this retrieval. This likely reflects a change in UN Tourism's data dissemination
# approach following the pandemic rather than a simple publication lag; the WDI series
# may no longer be actively updated. Real GDP indicators extend through 2024/2025
# but preliminary estimates may not be available for all economies.
wb_raw <- tryCatch(
  wb_data(
    indicator = wb_indicators,
    country = candidates$iso3,
    start_date = 2008,
    end_date = 2025,
    return_wide = TRUE
  ),
  error = function(e) {
    warning("World Bank API call failed: ", conditionMessage(e))
    NULL
  }
)

if (is.null(wb_raw)) {
  stop(
    "Could not retrieve World Bank data. Check internet connection and wbstats package."
  )
}

# Rename columns to clean names
wb_clean <- wb_raw |>
  rename(
    iso3 = iso3c,
    year = date,
    country_wb = country,
    tourism_receipts_pct_exports = ST.INT.RCPT.XP.ZS,
    gdp_per_capita_usd = NY.GDP.PCAP.CD,
    gdp_growth_pct = NY.GDP.MKTP.KD.ZG,
    gdp_real_const2015usd = NY.GDP.MKTP.KD,
    gdppc_real_const2015usd = NY.GDP.PCAP.KD,
    unemployment_pct = SL.UEM.TOTL.ZS
  ) |>
  select(
    iso3,
    year,
    country_wb,
    tourism_receipts_pct_exports,
    gdp_per_capita_usd,
    gdp_growth_pct,
    gdp_real_const2015usd,
    gdppc_real_const2015usd,
    unemployment_pct
  ) |>
  arrange(iso3, year)

# Flag codes that WB silently dropped (not in response)
wb_returned <- unique(wb_clean$iso3)
wb_missing <- setdiff(candidates$iso3, wb_returned)
if (length(wb_missing) > 0) {
  message(
    "Codes NOT returned by WB API (no WDI coverage): ",
    paste(wb_missing, collapse = ", ")
  )
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

message(
  "WB data saved: ",
  nrow(wb_clean),
  " rows, ",
  length(wb_returned),
  " countries, ",
  min(wb_clean$year),
  "-",
  max(wb_clean$year)
)
message(
  "Note: ST.INT.RCPT.XP.ZS contains no observations beyond 2020 in this retrieval.",
  " This likely reflects a change in UN Tourism data dissemination, not a simple lag.",
  " NY.GDP.MKTP.KD and NY.GDP.PCAP.KD extend to 2024/2025."
)

# ---------------------------------------------------------------------------
# Save cleaned OWID subsets (candidates only) to processed/
# ---------------------------------------------------------------------------

owid_tgdp_cand <- owid_tgdp |>
  filter(iso3 %in% candidates$iso3) |>
  left_join(
    select(candidates, iso3, sids_region, sids_status, political_status),
    by = "iso3"
  )

owid_vspend_cand <- owid_vspend |>
  filter(iso3 %in% candidates$iso3) |>
  left_join(
    select(candidates, iso3, sids_region, sids_status, political_status),
    by = "iso3"
  )

owid_arrivals_cand <- owid_arrivals |>
  filter(iso3 %in% candidates$iso3) |>
  left_join(
    select(candidates, iso3, sids_region, sids_status, political_status),
    by = "iso3"
  )

write_csv(owid_tgdp_cand, file.path(processed, "owid_tourism_gdp.csv"))
write_csv(owid_vspend_cand, file.path(processed, "owid_visitor_spending.csv"))
write_csv(owid_arrivals_cand, file.path(processed, "owid_arrivals.csv"))

message("Processed OWID subsets saved.")
message("Done: 01_data_acquisition.R")
