# =============================================================================
# 03_preliminary_eda.R
# F1: Tourism Dependence and the COVID Cliff
# Purpose: Preliminary EDA and publication-quality figures.
# Depends on: 01_data_acquisition.R and 02_data_quality.R having been run.
# Run from: F1-tourism-covid/ (project root)
# =============================================================================

library(here)
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)

processed <- here("data", "processed")
fig_dir   <- here("output", "figures")
tbl_dir   <- here("output", "tables")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tbl_dir, showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------------

candidates <- read_csv(file.path(processed, "candidates.csv"),               show_col_types = FALSE)
baseline   <- read_csv(file.path(processed, "baseline_shock_recovery.csv"), show_col_types = FALSE)
coverage   <- read_csv(file.path(processed, "country_coverage.csv"),        show_col_types = FALSE)

# ---------------------------------------------------------------------------
# Design system
# ---------------------------------------------------------------------------

pal_region <- c(
  "Caribbean" = "#0072B2",   # accessible blue
  "Pacific"   = "#D55E00"    # accessible vermillion
)

pal_thin <- c(
  "Full (2-3 obs)"   = "grey20",
  "Thin (1 obs)"     = "grey55"
)

base_theme <- theme_minimal(base_size = 11) +
  theme(
    text              = element_text(family = "sans", color = "grey15"),
    plot.title        = element_text(face = "bold", size = 13, margin = margin(b = 4)),
    plot.subtitle     = element_text(size = 10, color = "grey35", margin = margin(b = 8)),
    plot.caption      = element_text(size = 7.5, color = "grey50", hjust = 0,
                                     margin = margin(t = 8)),
    axis.title        = element_text(size = 9, color = "grey25"),
    axis.text         = element_text(size = 8.5, color = "grey30"),
    axis.ticks        = element_line(color = "grey80"),
    panel.grid.major  = element_line(color = "grey92"),
    panel.grid.minor  = element_blank(),
    legend.title      = element_text(size = 9, face = "bold"),
    legend.text       = element_text(size = 8.5),
    legend.key.size   = unit(0.9, "lines"),
    plot.margin       = margin(12, 14, 8, 12),
    strip.text        = element_text(face = "bold", size = 9)
  )

theme_set(base_theme)

# Helper: save figure at publication quality
save_fig <- function(filename, width = 8, height = 5.5) {
  # PNG at 300 dpi — suitable for Quarto HTML and print
  ggsave(
    filename = file.path(fig_dir, paste0(filename, ".png")),
    width = width, height = height, dpi = 300, bg = "white"
  )
  # SVG for Quarto inline embed
  ggsave(
    filename = file.path(fig_dir, paste0(filename, ".svg")),
    width = width, height = height, bg = "white"
  )
  message("Saved: ", filename)
}

# Short country labels for figures
short_labels <- c(
  ABW = "Aruba", AIA = "Anguilla", ATG = "Antigua & Barbuda",
  BHS = "Bahamas", BRB = "Barbados", BLZ = "Belize",
  BMU = "Bermuda", BES = "Bonaire etc.", CUW = "Curaçao",
  CYM = "Cayman Is.", DMA = "Dominica", DOM = "Dom. Rep.",
  GRD = "Grenada", GUY = "Guyana", HTI = "Haiti",
  JAM = "Jamaica", KNA = "St. Kitts", LCA = "St. Lucia",
  MSR = "Montserrat", PRI = "Puerto Rico", TCA = "Turks & Caicos",
  TTO = "Trinidad & Tobago", VCT = "St. Vincent", VGB = "British VI",
  VIR = "US Virgin Is.", FJI = "Fiji", FSM = "Micronesia",
  KIR = "Kiribati", MHL = "Marshall Is.", NRU = "Nauru",
  PLW = "Palau", PNG = "Papua New Guinea", SLB = "Solomon Is.",
  TON = "Tonga", TUV = "Tuvalu", VUT = "Vanuatu", WSM = "Samoa"
)

baseline <- baseline |>
  mutate(label = coalesce(short_labels[iso3], iso3))

# ============================================================
# A. Compare tourism-dependence measures
# ============================================================

# --- Figure 1: Tourism receipts (% exports) ranking, 2017-2019 mean ---
# Primary measure chosen: WDI tourism receipts % exports
# Rationale: best-covered indicator across candidates (see audit);
# directly measures economic dependence (tourism earnings / total export earnings).

fig1_data <- baseline |>
  filter(!is.na(receipts_mean_1719)) |>
  mutate(
    thin_flag = if_else(receipts_thin, "Thin (1 obs)", "Full (2-3 obs)"),
    thin_flag = factor(thin_flag, levels = c("Full (2-3 obs)", "Thin (1 obs)"))
  ) |>
  arrange(receipts_mean_1719) |>
  mutate(label = factor(label, levels = label))

caption_fig1 <- paste0(
  "Source: World Bank WDI (ST.INT.RCPT.XP.ZS) via wbstats. ",
  "Mean of available years 2017\u20132019. \u2020Thin baseline: only one pre-pandemic ",
  "observation available (treat with caution)."
)

p1 <- ggplot(fig1_data,
             aes(x = receipts_mean_1719, y = label,
                 color = region, alpha = thin_flag)) +
  geom_vline(xintercept = 0, color = "grey80", linewidth = 0.4) +
  geom_segment(aes(x = 0, xend = receipts_mean_1719, yend = label),
               linewidth = 0.5) +
  geom_point(size = 2.8) +
  scale_color_manual(values = pal_region, name = "Region") +
  scale_alpha_manual(values = c("Full (2-3 obs)" = 1, "Thin (1 obs)" = 0.45),
                     name = "Baseline") +
  scale_x_continuous(labels = label_number(suffix = "%"),
                     expand = expansion(mult = c(0, 0.04))) +
  labs(
    title    = "Tourism Receipts as a Share of Total Exports, 2017\u20132019 Average",
    subtitle = "Candidate Caribbean and Pacific island economies \u2014 primary dependence measure",
    x        = "International tourism receipts (% of total exports)",
    y        = NULL,
    caption  = caption_fig1
  ) +
  theme(
    axis.text.y = element_text(size = 8),
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(color = "grey92")
  )

save_fig("fig1_receipts_ranking", width = 8, height = max(5, nrow(fig1_data) * 0.32 + 1))

# --- Figure 2: Three-way measure comparison (scatter) ---
# Compare WDI receipts vs OWID visitor spending; annotate with Tourism GDP overlay

fig2_data <- baseline |>
  filter(!is.na(receipts_mean_1719) | !is.na(vspend_mean_1719)) |>
  filter(!is.na(receipts_mean_1719) & !is.na(vspend_mean_1719))

fig2_caption <- paste0(
  "Sources: WDI (ST.INT.RCPT.XP.ZS); OWID/WB (ST.INT.XPND.GD.ZS). ",
  "Both indicators 2017\u20132019 mean. Countries with data in both series only shown."
)

if (nrow(fig2_data) >= 4) {
  cor_val <- cor(fig2_data$receipts_mean_1719, fig2_data$vspend_mean_1719,
                 use = "complete.obs")
  p2 <- ggplot(fig2_data, aes(x = vspend_mean_1719, y = receipts_mean_1719,
                               color = region)) +
    geom_abline(slope = 1, intercept = 0, color = "grey75",
                linetype = "dashed", linewidth = 0.5) +
    geom_point(size = 2.5, alpha = 0.85) +
    geom_text(aes(label = label), size = 2.6, vjust = -0.7,
              check_overlap = TRUE) +
    scale_color_manual(values = pal_region, name = "Region") +
    scale_x_continuous(labels = label_number(suffix = "%"),
                       expand = expansion(mult = c(0.03, 0.06))) +
    scale_y_continuous(labels = label_number(suffix = "%"),
                       expand = expansion(mult = c(0.03, 0.06))) +
    annotate("text", x = Inf, y = -Inf,
             label = paste0("r = ", round(cor_val, 2)),
             hjust = 1.1, vjust = -0.5, size = 3, color = "grey35") +
    labs(
      title    = "Two Tourism-Dependence Measures Compared",
      subtitle = paste0("Visitor spending vs. tourism receipts (% of exports) \u2014 ",
                        nrow(fig2_data), " economies with data in both series"),
      x        = "International visitor spending (% of GDP)",
      y        = "Tourism receipts (% of total exports)",
      caption  = fig2_caption
    )
  save_fig("fig2_measure_comparison", width = 7.5, height = 6)
} else {
  message("Fig 2: insufficient overlap for scatter plot (n = ", nrow(fig2_data), ")")
}

# ============================================================
# B. Tourism dependence vs. 2020 GDP growth
# ============================================================

fig3_data <- baseline |>
  filter(!is.na(receipts_mean_1719), !is.na(gdp_growth_pct_2020)) |>
  mutate(thin_flag = if_else(receipts_thin, "Thin (1 obs)", "Full (2-3 obs)"))

cat("\n--- Figure 3 sample summary ---\n")
cat("N:", nrow(fig3_data), "\n")
cat("Tourism receipts range:", round(range(fig3_data$receipts_mean_1719, na.rm=TRUE), 1), "\n")
cat("GDP growth 2020 range:", round(range(fig3_data$gdp_growth_pct_2020, na.rm=TRUE), 1), "\n")

if (nrow(fig3_data) >= 6) {
  # Simple OLS: GDP growth ~ tourism receipts (exploratory, not causal)
  fit <- lm(gdp_growth_pct_2020 ~ receipts_mean_1719, data = fig3_data)
  fit_sum <- summary(fit)
  r2   <- round(fit_sum$r.squared, 3)
  pval <- round(coef(fit_sum)[2, 4], 3)
  slope <- round(coef(fit)[2], 3)

  cat("OLS: slope =", slope, "| R² =", r2, "| p =", pval, "\n")
  cat("Note: exploratory association only, NOT causal.\n")

  # Regression annotation
  reg_ann <- paste0("OLS slope: ", slope, " (R\u00b2 = ", r2, ", p = ", pval, ")")

  fig3_caption <- paste0(
    "Sources: WDI (ST.INT.RCPT.XP.ZS, NY.GDP.MKTP.KD.ZG). ",
    "OLS line is exploratory; does not imply causation. N = ", nrow(fig3_data), "."
  )

  p3 <- ggplot(fig3_data,
               aes(x = receipts_mean_1719, y = gdp_growth_pct_2020,
                   color = region)) +
    geom_hline(yintercept = 0, color = "grey70", linewidth = 0.5) +
    geom_smooth(method = "lm", formula = y ~ x, se = TRUE,
                color = "grey40", fill = "grey85",
                linewidth = 0.7, alpha = 0.35, show.legend = FALSE) +
    geom_point(aes(shape = thin_flag), size = 2.8, alpha = 0.9) +
    geom_text(aes(label = label), size = 2.6, vjust = -0.8,
              check_overlap = TRUE) +
    scale_color_manual(values = pal_region, name = "Region") +
    scale_shape_manual(values = c("Full (2-3 obs)" = 16, "Thin (1 obs)" = 1),
                       name = "Baseline") +
    scale_x_continuous(labels = label_number(suffix = "%"),
                       expand = expansion(mult = c(0.03, 0.06))) +
    scale_y_continuous(labels = label_number(suffix = "%"),
                       expand = expansion(mult = c(0.05, 0.05))) +
    annotate("text", x = max(fig3_data$receipts_mean_1719, na.rm = TRUE),
             y = max(fig3_data$gdp_growth_pct_2020, na.rm = TRUE),
             label = reg_ann, hjust = 1, vjust = 1.3,
             size = 2.7, color = "grey35") +
    labs(
      title    = "Tourism Dependence and the 2020 Economic Shock",
      subtitle = "Pre-pandemic tourism receipts (2017\u20132019 avg.) vs. 2020 GDP growth",
      x        = "International tourism receipts (% of total exports, 2017\u20132019 avg.)",
      y        = "GDP growth (annual %, 2020)",
      caption  = fig3_caption
    )
  save_fig("fig3_shock_scatter", width = 8, height = 6)
} else {
  message("Fig 3: insufficient matched data (n = ", nrow(fig3_data), ")")
}

# ============================================================
# C. Data coverage tile chart (Fig 4)
# ============================================================

# Indicators to show
cov_plot_data <- coverage |>
  filter(has_any_tourism | wb_gdpgrowth_2020 == 1) |>
  transmute(
    iso3,
    country = coalesce(short_labels[iso3], iso3),
    region,
    `Tourism GDP\n(OWID, 2017-19)` = owid_tgdp_n_1719,
    `Visitor Spending\n(OWID, 2017-19)` = owid_vspend_n_1719,
    `Tourism Receipts\n(WDI, 2017-19)` = wb_receipts_n_1719,
    `Tourist Arrivals\n(OWID, 2017-19)` = owid_arrivals_n_1719,
    `Arrivals 2020\n(OWID)` = as.integer(owid_arrivals_2020),
    `GDP Growth 2020\n(WDI)` = as.integer(wb_gdpgrowth_2020),
    `GDP/capita\n(WDI, key yrs)` = wb_gdppc_n_req,
    `Unemployment\n(WDI, key yrs)` = wb_unem_n_req
  ) |>
  pivot_longer(cols = -c(iso3, country, region),
               names_to = "indicator", values_to = "n_obs") |>
  mutate(
    avail = case_when(
      n_obs == 0 ~ "None",
      n_obs == 1 ~ "Partial",
      n_obs >= 2 ~ "Available",
      TRUE       ~ "None"
    ),
    avail = factor(avail, levels = c("Available", "Partial", "None"))
  )

# Order countries by region then total availability
country_order <- cov_plot_data |>
  group_by(iso3, country, region) |>
  summarise(total_obs = sum(n_obs), .groups = "drop") |>
  arrange(region, desc(total_obs)) |>
  pull(country)

indicator_order <- c(
  "Tourism Receipts\n(WDI, 2017-19)",
  "Visitor Spending\n(OWID, 2017-19)",
  "Tourism GDP\n(OWID, 2017-19)",
  "Tourist Arrivals\n(OWID, 2017-19)",
  "Arrivals 2020\n(OWID)",
  "GDP Growth 2020\n(WDI)",
  "GDP/capita\n(WDI, key yrs)",
  "Unemployment\n(WDI, key yrs)"
)

cov_plot_data <- cov_plot_data |>
  mutate(
    country   = factor(country, levels = rev(country_order)),
    indicator = factor(indicator, levels = indicator_order)
  )

pal_avail <- c(
  "Available" = "#2a9d8f",
  "Partial"   = "#e9c46a",
  "None"      = "#e8e8e8"
)

n_countries <- length(unique(cov_plot_data$country))

p4 <- ggplot(cov_plot_data, aes(x = indicator, y = country, fill = avail)) +
  geom_tile(color = "white", linewidth = 0.4) +
  scale_fill_manual(values = pal_avail, name = "Coverage",
                    drop = FALSE) +
  facet_grid(region ~ ., scales = "free_y", space = "free_y") +
  labs(
    title   = "Data Coverage Matrix: Tourism & Economic Indicators",
    subtitle = paste0("Candidate Caribbean and Pacific island economies (n = ",
                      n_countries, ")"),
    x = NULL, y = NULL,
    caption = paste0("Sources: OWID (UNWTO); World Bank WDI via wbstats. ",
                     "\u2018Partial\u2019 = 1 of requested years available. ",
                     "Key years: 2017\u20132019 baseline; 2020 shock; 2022\u20132023 recovery.")
  ) +
  theme(
    axis.text.x    = element_text(size = 7.5, angle = 25, hjust = 1),
    axis.text.y    = element_text(size = 7.8),
    strip.text.y   = element_text(angle = 0, face = "bold", size = 8.5),
    panel.spacing  = unit(0.3, "lines"),
    legend.position = "bottom"
  )

save_fig("fig4_coverage_matrix",
         width = 9.5,
         height = max(5.5, n_countries * 0.28 + 2.5))

# ============================================================
# D. EDA text output: measure comparison and coverage summary
# ============================================================

cat("\n============================================================\n")
cat("EDA: TOURISM-DEPENDENCE MEASURE COMPARISON\n")
cat("============================================================\n\n")

# Rankings by each measure
measures <- list(
  "WDI receipts % exports (primary)" = "receipts_mean_1719",
  "OWID visitor spending % GDP"      = "vspend_mean_1719",
  "OWID tourism GDP % GDP"           = "tgdp_mean_1719"
)

for (nm in names(measures)) {
  col <- measures[[nm]]
  cat("\n--- Ranking:", nm, "---\n")
  baseline |>
    filter(!is.na(.data[[col]])) |>
    arrange(desc(.data[[col]])) |>
    select(iso3, country_name, region, !!col) |>
    print(n = 40)
  cat("N:", sum(!is.na(baseline[[col]])), "\n")
}

cat("\n============================================================\n")
cat("EDA: RECOVERY DATA AVAILABILITY\n")
cat("============================================================\n\n")

# Check constant-price GDP availability
cat("GDP per capita (current USD) is available as requested.\n")
cat("For real (inflation-adjusted) recovery analysis, recommend:\n")
cat("  NY.GDP.PCAP.KD (GDP per capita, constant 2015 USD)\n")
cat("  NY.GDP.MKTP.KD (GDP, constant 2015 USD)\n")
cat("These should be retrieved in Phase 2 for recovery analysis.\n\n")

cat("Countries with GDP per capita data in 2022 or 2023:\n")
baseline |>
  filter(!is.na(gdp_per_capita_usd_2022) | !is.na(gdp_per_capita_usd_2023)) |>
  filter(!is.na(receipts_mean_1719) | !is.na(vspend_mean_1719)) |>
  select(iso3, country_name, region,
         gdp_per_capita_usd_2019, gdp_per_capita_usd_2022, gdp_per_capita_usd_2023) |>
  arrange(region, country_name) |>
  print(n = 40)

# Save EDA table
write_csv(
  baseline |>
    filter(!is.na(receipts_mean_1719) | !is.na(vspend_mean_1719)) |>
    select(iso3, country_name, region, is_sids, is_territory,
           receipts_mean_1719, receipts_n_1719, receipts_thin,
           vspend_mean_1719, vspend_n_1719,
           tgdp_mean_1719, tgdp_n_1719,
           gdp_growth_pct_2020,
           gdp_per_capita_usd_2019, gdp_per_capita_usd_2022, gdp_per_capita_usd_2023) |>
    arrange(region, desc(coalesce(receipts_mean_1719, vspend_mean_1719))),
  file.path(tbl_dir, "eda_tourism_shock_table.csv")
)

message("Done: 03_preliminary_eda.R")
