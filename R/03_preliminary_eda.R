# =============================================================================
# 03_preliminary_eda.R
# Island Time, Interrupted: Tourism Dependence and the COVID Cliff
# Purpose: Preliminary EDA and publication-quality figures.
# Depends on: 01_data_acquisition.R and 02_data_quality.R having been run.
#             R/theme_utils.R must exist (provides palettes and save_fig_dual).
# Run from: repository root (here() anchors at .git)
# =============================================================================

library(here)
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)

source(here("R", "theme_utils.R")) # palettes, make_fn_theme, save_fig_dual

processed <- here("data", "processed")
fig_dir <- here("output", "figures")
tbl_dir <- here("output", "tables")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tbl_dir, showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------------

candidates <- read_csv(
  file.path(processed, "candidates.csv"),
  show_col_types = FALSE
)
baseline <- read_csv(
  file.path(processed, "baseline_shock_recovery.csv"),
  show_col_types = FALSE
)
coverage <- read_csv(
  file.path(processed, "country_coverage.csv"),
  show_col_types = FALSE
)

# ---------------------------------------------------------------------------
# Short labels for figure annotations
# ---------------------------------------------------------------------------

short_labels <- c(
  # Caribbean UN SIDS
  ATG = "Antigua & Barbuda",
  BHS = "Bahamas",
  BRB = "Barbados",
  BLZ = "Belize",
  CUB = "Cuba",
  DMA = "Dominica",
  DOM = "Dom. Rep.",
  GRD = "Grenada",
  GUY = "Guyana",
  HTI = "Haiti",
  JAM = "Jamaica",
  KNA = "St. Kitts",
  LCA = "St. Lucia",
  SUR = "Suriname",
  TTO = "Trinidad & Tobago",
  VCT = "St. Vincent",
  # Caribbean Associates / Other
  AIA = "Anguilla",
  ABW = "Aruba",
  BMU = "Bermuda",
  VGB = "British VI",
  CYM = "Cayman Is.",
  CUW = "Curaçao",
  GLP = "Guadeloupe",
  MTQ = "Martinique",
  MSR = "Montserrat",
  PRI = "Puerto Rico",
  SXM = "Sint Maarten",
  TCA = "Turks & Caicos",
  VIR = "US Virgin Is.",
  BES = "Bonaire etc.",
  # Pacific UN SIDS
  COK = "Cook Is.",
  FJI = "Fiji",
  KIR = "Kiribati",
  MHL = "Marshall Is.",
  FSM = "Micronesia",
  NRU = "Nauru",
  NIU = "Niue",
  PLW = "Palau",
  PNG = "Papua New Guinea",
  WSM = "Samoa",
  SLB = "Solomon Is.",
  TLS = "Timor-Leste",
  TON = "Tonga",
  TUV = "Tuvalu",
  VUT = "Vanuatu",
  # Pacific Associates
  ASM = "American Samoa",
  MNP = "N. Mariana Is.",
  PYF = "French Polynesia",
  GUM = "Guam",
  NCL = "New Caledonia",
  # AIMS UN SIDS
  CPV = "Cabo Verde",
  COM = "Comoros",
  GNB = "Guinea-Bissau",
  MDV = "Maldives",
  MUS = "Mauritius",
  STP = "São Tomé & Príncipe",
  SYC = "Seychelles",
  SGP = "Singapore"
)

baseline <- baseline |>
  mutate(label = coalesce(short_labels[iso3], iso3))

# ============================================================
# A. Tourism-dependence rankings
# ============================================================

# Figure 1: OWID visitor spending (% GDP) ranking — PRIMARY measure

fig1_data <- baseline |>
  filter(!is.na(vspend_mean_1519)) |>
  mutate(
    thin_flag = if_else(vspend_thin_1519, "Thin (1 obs)", "Full (2-5 obs)"),
    thin_flag = factor(thin_flag, levels = c("Full (2-5 obs)", "Thin (1 obs)"))
  ) |>
  arrange(vspend_mean_1519) |>
  mutate(label = factor(label, levels = label))

caption_fig1 <- paste0(
  "Source: OWID / UN Tourism. International visitor spending as % of GDP; ",
  "2015\u20132019 mean (primary baseline).\nOpen circles: thin baseline (1 obs only)."
)

build_fig1 <- function(pal) {
  pal_reg <- c(
    Caribbean = pal$series1,
    Pacific = pal$series2,
    AIMS = pal$series3
  )

  ggplot(
    fig1_data,
    aes(x = vspend_mean_1519, y = label, color = sids_region, alpha = thin_flag)
  ) +
    geom_vline(xintercept = 0, color = pal$grid, linewidth = 0.4) +
    geom_segment(
      aes(x = 0, xend = vspend_mean_1519, yend = label),
      linewidth = 0.5
    ) +
    geom_point(size = 2.8) +
    scale_color_manual(values = pal_reg, name = "Region") +
    scale_alpha_manual(
      values = c("Full (2-5 obs)" = 1, "Thin (1 obs)" = 0.45),
      name = "Baseline"
    ) +
    scale_x_continuous(
      labels = label_number(suffix = "%"),
      expand = expansion(mult = c(0, 0.04))
    ) +
    labs(
      title = "International Visitor Spending as a Share of GDP, 2015\u20132019",
      x = "International visitor spending (% of GDP)",
      y = NULL,
      caption = caption_fig1
    ) +
    make_fn_theme(pal) +
    theme(
      axis.text.y = element_text(size = 7.5),
      panel.grid.major.y = element_blank()
    )
}

save_fig_dual(
  build_fig1(pal_archipelago_light),
  build_fig1(pal_archipelago_dark),
  "fig1_vspend_ranking",
  fig_dir,
  w = 8.5,
  h = max(5.5, nrow(fig1_data) * 0.28 + 1.2)
)

# ============================================================
# B. Measure comparison
# ============================================================

# Figure 2: OWID visitor spending vs WDI tourism receipts
# Note: these measure related but distinct concepts and use different denominators

fig2_data <- baseline |>
  filter(
    in_primary_shock_sample,
    in_receipts_shock_sample,
    !is.na(vspend_mean_1519),
    !is.na(receipts_mean_1519)
  )

fig2_caption <- paste0(
  "Sources: OWID/UN Tourism (visitor spending % GDP); WDI ST.INT.RCPT.XP.ZS (receipts % exports). \n",
  "Both: 2015\u20132019 mean. N = ",
  nrow(fig2_data),
  " economies with data in both series."
)

if (nrow(fig2_data) >= 4) {
  cor_pearson <- cor(
    fig2_data$vspend_mean_1519,
    fig2_data$receipts_mean_1519,
    use = "complete.obs"
  )
  cor_spearman <- cor(
    fig2_data$vspend_mean_1519,
    fig2_data$receipts_mean_1519,
    method = "spearman",
    use = "complete.obs"
  )

  cat("\n--- Measure comparison (N =", nrow(fig2_data), ") ---\n")
  cat("Pearson r (vspend vs receipts):", round(cor_pearson, 3), "\n")
  cat("Spearman rho:                  ", round(cor_spearman, 3), "\n")

  build_fig2 <- function(pal) {
    pal_reg <- c(
      Caribbean = pal$series1,
      Pacific = pal$series2,
      AIMS = pal$series3
    )
    ann_lab <- paste0(
      "Pearson r = ",
      round(cor_pearson, 2),
      "; Spearman \u03c1 = ",
      round(cor_spearman, 2)
    )
    ggplot(
      fig2_data,
      aes(x = vspend_mean_1519, y = receipts_mean_1519, color = sids_region)
    ) +
      geom_smooth(
        method = "lm",
        formula = y ~ x,
        se = FALSE,
        color = pal$muted,
        linewidth = 0.5,
        linetype = "dashed"
      ) +
      geom_point(size = 2.5, alpha = 0.85) +
      geom_text(
        aes(label = label),
        size = 2.5,
        vjust = -0.75,
        check_overlap = TRUE
      ) +
      scale_color_manual(values = pal_reg, name = "Region") +
      scale_x_continuous(
        labels = label_number(suffix = "%"),
        expand = expansion(mult = c(0.03, 0.06))
      ) +
      scale_y_continuous(
        labels = label_number(suffix = "%"),
        expand = expansion(mult = c(0.03, 0.06))
      ) +
      annotate(
        "text",
        x = Inf,
        y = Inf,
        label = ann_lab,
        hjust = 1.1,
        vjust = 1.3,
        size = 2.9,
        color = pal$muted
      ) +
      labs(
        title = "Two Tourism-Dependence Measures Compared",
        subtitle = "Visitor spending (% GDP) vs. tourism receipts (% exports); 2015\u20132019 averages",
        x = "OWID: International visitor spending (% of GDP)",
        y = "WDI: Tourism receipts (% of total exports)",
        caption = fig2_caption
      ) +
      make_fn_theme(pal)
  }

  save_fig_dual(
    build_fig2(pal_archipelago_light),
    build_fig2(pal_archipelago_dark),
    "fig2_measure_comparison",
    fig_dir,
    w = 7.5,
    h = 6
  )
}

# ============================================================
# C. Primary shock analysis: vspend vs 2020 GDP growth
# ============================================================

# Primary shock sample: OWID vspend + 2020 GDP growth
shock_primary <- baseline |>
  filter(
    in_primary_shock_sample,
    !is.na(vspend_mean_1519),
    !is.na(gdp_growth_pct_2020)
  ) |>
  mutate(
    thin_flag = if_else(vspend_thin_1519, "Thin (1 obs)", "Full (2-5 obs)")
  )

cat("\n================================================================\n")
cat("PRIMARY SHOCK ANALYSIS (vspend baseline)\n")
cat("================================================================\n\n")
cat("Primary shock sample N:", nrow(shock_primary), "\n")
cat(
  "Visitor spending range:",
  round(range(shock_primary$vspend_mean_1519, na.rm = TRUE), 1),
  "\n"
)
cat(
  "GDP growth 2020 range: ",
  round(range(shock_primary$gdp_growth_pct_2020, na.rm = TRUE), 1),
  "\n"
)

if (nrow(shock_primary) >= 6) {
  fit_p <- lm(gdp_growth_pct_2020 ~ vspend_mean_1519, data = shock_primary)
  fit_sum <- summary(fit_p)
  r2_p <- round(fit_sum$r.squared, 3)
  pval_p <- round(coef(fit_sum)[2, 4], 4)
  slope_p <- round(coef(fit_p)[2], 3)
  cor_p <- round(
    cor(shock_primary$vspend_mean_1519, shock_primary$gdp_growth_pct_2020),
    3
  )
  cor_sp_p <- round(
    cor(
      shock_primary$vspend_mean_1519,
      shock_primary$gdp_growth_pct_2020,
      method = "spearman"
    ),
    3
  )

  cat("OLS slope:     ", slope_p, "\n")
  cat("R\u00b2:            ", r2_p, "\n")
  cat("p-value:       ", pval_p, "\n")
  cat("Pearson r:     ", cor_p, "\n")
  cat("Spearman \u03c1:   ", cor_sp_p, "\n")
  cat("Note: exploratory association only. NOT causal.\n")

  p_label <- if (pval_p < 0.001) {
    "<0.001"
  } else {
    formatC(pval_p, format = "f", digits = 3)
  }

  reg_ann_p <- paste0(
    "OLS slope: ",
    slope_p,
    " | R\u00b2 = ",
    r2_p,
    " | p = ",
    p_label,
    "\nPearson r = ",
    cor_p,
    " | Spearman \u03c1 = ",
    cor_sp_p
  )

  # --- Sensitivity: exclude thin baselines ---
  shock_full <- shock_primary |> filter(!vspend_thin_1519)
  if (nrow(shock_full) >= 6) {
    fit_f <- lm(gdp_growth_pct_2020 ~ vspend_mean_1519, data = shock_full)
    fit_fs <- summary(fit_f)
    cat("\nSENSITIVITY (full baselines only, n =", nrow(shock_full), "):\n")
    cat("  OLS slope: ", round(coef(fit_f)[2], 3), "\n")
    cat("  R\u00b2:       ", round(fit_fs$r.squared, 3), "\n")
    cat("  p-value:   ", round(coef(fit_fs)[2, 4], 4), "\n")
  }

  fig3_caption <- paste0(
    "Sources: OWID/UN Tourism (visitor spending % GDP, 2015–2019 mean); WDI (NY.GDP.MKTP.KD.ZG). \n",
    "OLS line is exploratory only \u2014 does not imply causation. N = ",
    nrow(shock_primary),
    "."
  )

  build_fig3 <- function(pal) {
    pal_reg <- c(
      Caribbean = pal$series1,
      Pacific = pal$series2,
      AIMS = pal$series3
    )
    ci_fill <- paste0(pal$muted, "50") # ~31% opacity CI band

    ggplot(
      shock_primary,
      aes(x = vspend_mean_1519, y = gdp_growth_pct_2020, color = sids_region)
    ) +
      geom_hline(yintercept = 0, color = pal$reference, linewidth = 0.5) +
      geom_smooth(
        method = "lm",
        formula = y ~ x,
        se = TRUE,
        color = pal$muted,
        fill = ci_fill,
        linewidth = 0.7,
        alpha = 0.35,
        show.legend = FALSE
      ) +
      geom_point(aes(shape = thin_flag), size = 2.8, alpha = 0.9) +
      geom_text(
        aes(label = label),
        size = 2.5,
        vjust = -0.85,
        check_overlap = TRUE
      ) +
      scale_color_manual(values = pal_reg, name = "Region") +
      scale_shape_manual(
        values = c("Full (2-5 obs)" = 16, "Thin (1 obs)" = 1),
        name = "Baseline"
      ) +
      scale_x_continuous(
        labels = label_number(suffix = "%"),
        expand = expansion(mult = c(0.03, 0.08))
      ) +
      scale_y_continuous(
        labels = label_number(suffix = "%"),
        expand = expansion(mult = c(0.05, 0.05))
      ) +
      annotate(
        "text",
        x = max(shock_primary$vspend_mean_1519, na.rm = TRUE) * 0.98,
        y = max(shock_primary$gdp_growth_pct_2020, na.rm = TRUE),
        label = reg_ann_p,
        hjust = 1,
        vjust = 1.2,
        size = 2.6,
        color = pal$muted,
        lineheight = 1.3
      ) +
      labs(
        title = "Tourism Dependence and the 2020 Economic Shock",
        subtitle = "International visitor spending (2015\u20132019 avg.) vs. 2020 GDP growth",
        x = "International visitor spending (% of GDP, 2015\u20132019 avg.)",
        y = "GDP growth (annual %, 2020)",
        caption = fig3_caption
      ) +
      make_fn_theme(pal)
  }

  save_fig_dual(
    build_fig3(pal_archipelago_light),
    build_fig3(pal_archipelago_dark),
    "fig3_shock_scatter",
    fig_dir,
    w = 8.5,
    h = 6.5
  )
}

# --- Complementary: receipts-based shock (for comparison) ---
shock_receipts <- baseline |>
  filter(!is.na(receipts_mean_1519), !is.na(gdp_growth_pct_2020))

if (nrow(shock_receipts) >= 6) {
  fit_r <- lm(gdp_growth_pct_2020 ~ receipts_mean_1519, data = shock_receipts)
  fit_rs <- summary(fit_r)
  cat("\nCOMPLEMENTARY (WDI receipts, n =", nrow(shock_receipts), "):\n")
  cat("  OLS slope: ", round(coef(fit_r)[2], 3), "\n")
  cat("  R\u00b2:       ", round(fit_rs$r.squared, 3), "\n")
  cat("  p-value:   ", round(coef(fit_rs)[2, 4], 4), "\n")
  cat(
    "  Spearman \u03c1:",
    round(
      cor(
        shock_receipts$receipts_mean_1519,
        shock_receipts$gdp_growth_pct_2020,
        method = "spearman"
      ),
      3
    ),
    "\n"
  )
}

# ============================================================
# D. Data coverage tile chart
# ============================================================

cov_plot_data <- coverage |>
  filter(in_tourism_data_sample | has_gdpgrowth_2020) |>
  transmute(
    iso3,
    country = coalesce(short_labels[iso3], iso3),
    sids_region,
    `Visitor Spending\n(OWID, 2017-19)` = owid_vspend_n_1719,
    `Tourism Receipts\n(WDI, 2017-19)` = wb_receipts_n_1719,
    `Tourism GDP\n(OWID, 2017-19)` = owid_tgdp_n_1719,
    `Arrivals\n(OWID, 2017-19)` = owid_arrivals_n_1719,
    `Arrivals 2020\n(OWID)` = as.integer(owid_arrivals_2020),
    `GDP Growth 2020\n(WDI)` = as.integer(wb_gdpgrowth_2020),
    `Real GDP\n(WDI, key yrs)` = wb_gdpreal_n_req,
    `Unemployment\n(WDI, key yrs)` = wb_unem_n_req
  ) |>
  pivot_longer(
    cols = -c(iso3, country, sids_region),
    names_to = "indicator",
    values_to = "n_obs"
  ) |>
  mutate(
    avail = case_when(
      n_obs == 0 ~ "None",
      n_obs == 1 ~ "Partial",
      n_obs >= 2 ~ "Available",
      TRUE ~ "None"
    ),
    avail = factor(avail, levels = c("Available", "Partial", "None"))
  )

country_order <- cov_plot_data |>
  group_by(iso3, country, sids_region) |>
  summarise(total_obs = sum(n_obs), .groups = "drop") |>
  arrange(sids_region, desc(total_obs)) |>
  pull(country)

indicator_order <- c(
  "Visitor Spending\n(OWID, 2017-19)",
  "Tourism Receipts\n(WDI, 2017-19)",
  "Tourism GDP\n(OWID, 2017-19)",
  "Arrivals\n(OWID, 2017-19)",
  "Arrivals 2020\n(OWID)",
  "GDP Growth 2020\n(WDI)",
  "Real GDP\n(WDI, key yrs)",
  "Unemployment\n(WDI, key yrs)"
)

cov_plot_data <- cov_plot_data |>
  mutate(
    country = factor(country, levels = rev(country_order)),
    indicator = factor(indicator, levels = indicator_order)
  )

n_cov <- length(unique(cov_plot_data$country))

build_fig4 <- function(pal, cov_pal) {
  ggplot(cov_plot_data, aes(x = indicator, y = country, fill = avail)) +
    geom_tile(color = pal$bg, linewidth = 0.4) +
    scale_fill_manual(values = cov_pal, name = "Coverage", drop = FALSE) +
    facet_grid(sids_region ~ ., scales = "free_y", space = "free_y") +
    labs(
      title = "Data Coverage Matrix: Tourism and Economic Indicators",
      subtitle = paste0("SIDS candidate universe (n = ", n_cov, " shown)"),
      x = NULL,
      y = NULL,
      caption = paste0(
        "Sources: OWID (UN Tourism); World Bank WDI via wbstats. ",
        "\u2018Partial\u2019 = 1 of requested years available. \n",
        "Key years: 2017\u20132019 baseline; 2020 shock; 2022\u20132023 recovery."
      )
    ) +
    make_fn_theme(pal) +
    theme(
      axis.text.x = element_text(size = 7.5, angle = 25, hjust = 1),
      axis.text.y = element_text(size = 7.5),
      strip.text.y = element_text(angle = 0, face = "bold", size = 8.5),
      panel.spacing = unit(0.3, "lines"),
      legend.position = "bottom"
    )
}

save_fig_dual(
  build_fig4(pal_archipelago_light, pal_coverage_light),
  build_fig4(pal_archipelago_dark, pal_coverage_dark),
  "fig4_coverage_matrix",
  fig_dir,
  w = 9.5,
  h = max(6, n_cov * 0.26 + 2.5)
)

# ============================================================
# E. Measure-comparison rankings (text output)
# ============================================================

cat("\n================================================================\n")
cat("INDICATOR RANKINGS (2017-2019 averages)\n")
cat("================================================================\n\n")

measures <- list(
  "OWID visitor spending % GDP (PRIMARY)" = "vspend_mean_1719",
  "WDI receipts % exports (complementary)" = "receipts_mean_1719",
  "OWID tourism direct GDP % GDP" = "tgdp_mean_1719"
)

for (nm in names(measures)) {
  col <- measures[[nm]]
  cat("\n--- Ranking:", nm, "---\n")
  baseline |>
    filter(!is.na(.data[[col]])) |>
    arrange(desc(.data[[col]])) |>
    select(iso3, country, sids_region, !!col) |>
    print(n = 60)
  cat("N:", sum(!is.na(baseline[[col]])), "\n")
}

# ============================================================
# F. Real GDP coverage report
# ============================================================

cat("\n================================================================\n")
cat("REAL GDP COVERAGE (constant 2015 USD)\n")
cat("================================================================\n\n")

cat(
  "Economies with real GDP data in all four key years (2019, 2020, 2022, 2023):\n"
)
baseline |>
  filter(
    !is.na(gdp_real_const2015usd_2019),
    !is.na(gdp_real_const2015usd_2020),
    !is.na(gdp_real_const2015usd_2022),
    !is.na(gdp_real_const2015usd_2023)
  ) |>
  select(
    iso3,
    country,
    sids_region,
    gdp_real_const2015usd_2019,
    gdp_real_const2015usd_2020,
    gdp_real_const2015usd_2022,
    gdp_real_const2015usd_2023
  ) |>
  arrange(sids_region, country) |>
  print(n = 60)

# Save EDA table
write_csv(
  baseline |>
    filter(!is.na(vspend_mean_1719) | !is.na(receipts_mean_1719)) |>
    select(
      iso3,
      country,
      sids_region,
      sids_status,
      political_status,
      vspend_mean_1519,
      vspend_mean_1719,
      vspend_n_1719,
      vspend_thin_1719,
      receipts_mean_1519,
      receipts_mean_1719,
      receipts_n_1719,
      tgdp_mean_1719,
      tgdp_n_1719,
      gdp_growth_pct_2020,
      gdp_real_const2015usd_2019,
      gdp_real_const2015usd_2022,
      gdp_real_const2015usd_2023
    ) |>
    arrange(
      sids_region,
      desc(coalesce(vspend_mean_1519, vspend_mean_1719, receipts_mean_1519))
    ),
  file.path(tbl_dir, "eda_tourism_shock_table.csv")
)

message("Done: 03_preliminary_eda.R")
