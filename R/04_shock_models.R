# =============================================================================
# 04_shock_models.R
# Island Time, Interrupted: Tourism Dependence and the COVID Cliff
# Purpose: Complete 8-model shock-analysis comparison.
#          Two indicators x two baseline windows x OWID/WDI/Common samples.
#          Influential-observation diagnostics and coverage-restricted sensitivity.
# Depends on: 02_data_quality.R having been run first.
# Run from: repository root (here() anchors at .git)
# =============================================================================
# METHODOLOGICAL NOTE:
# This analysis examines whether greater pre-pandemic tourism dependence was
# associated with worse 2020 GDP growth. The primary baseline window (2015-2019)
# was chosen after observing that the sensitivity baseline (2017-2019) produces
# a statistically significant result. This ordering is documented transparently;
# no window was designated a priori. All eight estimates are reported regardless
# of their outcome.
# =============================================================================

library(here)
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)

processed <- here("data", "processed")
fig_dir <- here("output", "figures")
tbl_dir <- here("output", "tables")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tbl_dir, showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------------

bl <- read_csv(
  file.path(processed, "baseline_shock_recovery.csv"),
  show_col_types = FALSE
)
cands <- read_csv(
  file.path(processed, "candidates.csv"),
  show_col_types = FALSE
)

# Short labels for figure annotations
short_labels <- c(
  ATG = "Antigua",
  ABW = "Aruba",
  BHS = "Bahamas",
  BMU = "Bermuda",
  BRB = "Barbados",
  COM = "Comoros",
  CPV = "CapeVerde",
  CUB = "Cuba",
  CUW = "Curacao",
  CYM = "Cayman Is.",
  DMA = "Dominica",
  DOM = "Dom.Rep.",
  FJI = "Fiji",
  GNB = "Guinea-B.",
  GRD = "Grenada",
  HTI = "Haiti",
  KIR = "Kiribati",
  KNA = "St.Kitts",
  LCA = "St.Lucia",
  MDV = "Maldives",
  MHL = "Marshall Is.",
  MUS = "Mauritius",
  NRU = "Nauru",
  PLW = "Palau",
  PNG = "Papua NG",
  PRI = "Puerto Rico",
  SLB = "Solomon Is.",
  SGP = "Singapore",
  STP = "São Tomé",
  SUR = "Suriname",
  SXM = "Sint Maarten",
  SYC = "Seychelles",
  TLS = "Timor-Leste",
  TON = "Tonga",
  TTO = "Trinidad",
  TUV = "Tuvalu",
  VCT = "St.Vincent",
  VIR = "US VI",
  VUT = "Vanuatu",
  WSM = "Samoa"
)

bl <- bl |>
  mutate(label = coalesce(short_labels[iso3], iso3))

# ---------------------------------------------------------------------------
# Design system
# ---------------------------------------------------------------------------

pal_region <- c(
  "Caribbean" = "#0072B2",
  "Pacific" = "#D55E00",
  "AIMS" = "#009E73"
)

base_theme <- theme_minimal(base_size = 11) +
  theme(
    text = element_text(family = "sans", color = "grey15"),
    plot.title = element_text(face = "bold", size = 12, margin = margin(b = 4)),
    plot.subtitle = element_text(
      size = 9.5,
      color = "grey35",
      margin = margin(b = 8)
    ),
    plot.caption = element_text(size = 7.5, color = "grey50", hjust = 0),
    axis.title = element_text(size = 9, color = "grey25"),
    axis.text = element_text(size = 8.5, color = "grey30"),
    panel.grid.major = element_line(color = "grey92"),
    panel.grid.minor = element_blank(),
    legend.title = element_text(size = 9, face = "bold"),
    legend.text = element_text(size = 8.5),
    plot.margin = margin(12, 14, 8, 12)
  )
theme_set(base_theme)

save_fig <- function(plt, nm, w = 8.5, h = 6) {
  ggsave(
    file.path(fig_dir, paste0(nm, ".png")),
    plot = plt,
    width = w,
    height = h,
    dpi = 300,
    bg = "white"
  )
  ggsave(
    file.path(fig_dir, paste0(nm, ".svg")),
    plot = plt,
    width = w,
    height = h,
    bg = "white"
  )
  message("Saved: ", nm)
}

# ---------------------------------------------------------------------------
# Helper: fit one model and extract all statistics
# ---------------------------------------------------------------------------

fit_model <- function(data, x_col, y_col = "gdp_growth_pct_2020", label = "") {
  df <- data |>
    filter(!is.na(.data[[x_col]]), !is.na(.data[[y_col]])) |>
    rename(x = all_of(x_col), y = all_of(y_col))

  n <- nrow(df)
  if (n < 4) {
    message("  [SKIP] n=", n, " too small for: ", label)
    return(NULL)
  }

  fit <- lm(y ~ x, data = df)
  fit_s <- summary(fit)
  ci <- confint(fit)["x", ]
  slope <- coef(fit)[["x"]]
  se_sl <- coef(fit_s)[2, 2]
  r2 <- fit_s$r.squared
  pval <- coef(fit_s)[2, 4]
  pearson <- cor(df$x, df$y, use = "complete.obs")
  spearman <- cor(df$x, df$y, method = "spearman", use = "complete.obs")

  # Cook's distance diagnostics
  cooks <- cooks.distance(fit)
  thresh_cook <- 4 / n
  infl <- df |>
    mutate(
      cooksd = cooks,
      leverage = hatvalues(fit),
      residual = residuals(fit),
      influential = cooksd > thresh_cook
    ) |>
    arrange(desc(cooksd))

  list(
    label = label,
    n = n,
    slope = slope,
    ci_lo = ci[1],
    ci_hi = ci[2],
    r2 = r2,
    pearson = pearson,
    spearman = spearman,
    pval = pval,
    fit = fit,
    df = df,
    infl = infl,
    x_col = x_col
  )
}

# ---------------------------------------------------------------------------
# Define the eight principal models
# ---------------------------------------------------------------------------
# Fixed sample definitions (based on 2017-2019 availability):
#   OWID sample (N=29): in_primary_shock_sample
#   WDI sample  (N=35): in_receipts_shock_sample
#   Common      (N=24): in_common_sample

owid_data <- bl |> filter(in_primary_shock_sample)
wdi_data <- bl |> filter(in_receipts_shock_sample)
common_data <- bl |> filter(in_common_sample)

# Outcome variable: GDP growth 2020
y_col <- "gdp_growth_pct_2020"

models_spec <- list(
  # 2015-2019 baseline
  list(
    id = 1,
    label = "M1: OWID vspend [2015-19], OWID sample",
    data = owid_data,
    x = "vspend_mean_1519",
    window = "2015-19",
    indicator = "OWID vspend",
    sample = "OWID (N=29)"
  ),
  list(
    id = 2,
    label = "M2: WDI receipts [2015-19], WDI sample",
    data = wdi_data,
    x = "receipts_mean_1519",
    window = "2015-19",
    indicator = "WDI receipts",
    sample = "WDI (N=35)"
  ),
  list(
    id = 3,
    label = "M3: OWID vspend [2015-19], Common sample",
    data = common_data,
    x = "vspend_mean_1519",
    window = "2015-19",
    indicator = "OWID vspend",
    sample = "Common (N=24)"
  ),
  list(
    id = 4,
    label = "M4: WDI receipts [2015-19], Common sample",
    data = common_data,
    x = "receipts_mean_1519",
    window = "2015-19",
    indicator = "WDI receipts",
    sample = "Common (N=24)"
  ),
  # 2017-2019 baseline
  list(
    id = 5,
    label = "M5: OWID vspend [2017-19], OWID sample",
    data = owid_data,
    x = "vspend_mean_1719",
    window = "2017-19",
    indicator = "OWID vspend",
    sample = "OWID (N=29)"
  ),
  list(
    id = 6,
    label = "M6: WDI receipts [2017-19], WDI sample",
    data = wdi_data,
    x = "receipts_mean_1719",
    window = "2017-19",
    indicator = "WDI receipts",
    sample = "WDI (N=35)"
  ),
  list(
    id = 7,
    label = "M7: OWID vspend [2017-19], Common sample",
    data = common_data,
    x = "vspend_mean_1719",
    window = "2017-19",
    indicator = "OWID vspend",
    sample = "Common (N=24)"
  ),
  list(
    id = 8,
    label = "M8: WDI receipts [2017-19], Common sample",
    data = common_data,
    x = "receipts_mean_1719",
    window = "2017-19",
    indicator = "WDI receipts",
    sample = "Common (N=24)"
  )
)

# Fit all 8 models
results <- lapply(models_spec, function(ms) {
  message("Fitting: ", ms$label)
  res <- fit_model(ms$data, ms$x, y_col, ms$label)
  if (!is.null(res)) {
    res$model_id <- ms$id
    res$window <- ms$window
    res$indicator <- ms$indicator
    res$sample <- ms$sample
  }
  res
})
names(results) <- paste0("M", 1:8)

# ---------------------------------------------------------------------------
# Apply Holm correction across 8 principal p-values
# ---------------------------------------------------------------------------

principal_pvals <- sapply(results, function(r) {
  if (!is.null(r)) r$pval else NA_real_
})
holm_pvals <- p.adjust(principal_pvals, method = "holm")

# Add Holm-adjusted p to each result
for (i in seq_along(results)) {
  if (!is.null(results[[i]])) results[[i]]$pval_holm <- holm_pvals[i]
}

# ---------------------------------------------------------------------------
# Print complete results table
# ---------------------------------------------------------------------------

cat("\n================================================================\n")
cat("EIGHT-MODEL SHOCK-ANALYSIS RESULTS\n")
cat("Outcome: 2020 GDP growth (annual %, WDI NY.GDP.MKTP.KD.ZG)\n")
cat("Holm correction applied across 8 principal p-values\n")
cat("================================================================\n\n")

summary_rows <- lapply(results, function(r) {
  if (is.null(r)) {
    return(NULL)
  }
  tibble(
    Model = r$model_id,
    Indicator = r$indicator,
    Window = r$window,
    Sample = r$sample,
    N = r$n,
    Slope = round(r$slope, 3),
    CI_lo = round(r$ci_lo, 3),
    CI_hi = round(r$ci_hi, 3),
    R2 = round(r$r2, 3),
    Pearson_r = round(r$pearson, 3),
    Spearman_rho = round(r$spearman, 3),
    p_raw = round(r$pval, 4),
    p_holm = round(r$pval_holm, 4)
  )
})

results_tbl <- bind_rows(summary_rows)
print(results_tbl, n = 8, width = 120)

write_csv(results_tbl, file.path(tbl_dir, "shock_model_results.csv"))
message("Results table saved")

# ---------------------------------------------------------------------------
# Influential observations summary
# ---------------------------------------------------------------------------

cat("\n================================================================\n")
cat("INFLUENTIAL OBSERVATIONS (Cook's D > 4/n)\n")
cat("================================================================\n\n")

for (r in results) {
  if (is.null(r)) {
    next
  }
  thresh <- 4 / r$n
  infl_countries <- r$infl |>
    filter(influential) |>
    left_join(select(bl, iso3, label, sids_region), by = "iso3")
  cat(
    "Model",
    r$model_id,
    "(",
    r$label,
    ")  threshold =",
    round(thresh, 3),
    "\n"
  )
  if (nrow(infl_countries) == 0) {
    cat("  No observations exceed Cook's D threshold.\n")
  } else {
    cat(
      "  Influential:",
      paste(infl_countries$iso3, collapse = ", "),
      "  (top Cook's D:",
      paste(
        round(infl_countries$cooksd[1:min(3, nrow(infl_countries))], 3),
        collapse = ", "
      ),
      ")\n"
    )
  }
}

# ---------------------------------------------------------------------------
# Diagnostic sensitivity: exclude top influential observation
# ---------------------------------------------------------------------------

cat("\n================================================================\n")
cat("SENSITIVITY: EXCLUDING MOST INFLUENTIAL OBSERVATION\n")
cat("================================================================\n\n")

for (r in results) {
  if (is.null(r)) {
    next
  }
  top_infl <- r$infl |> slice(1)
  infl_iso <- top_infl$iso3

  df_excl <- r$df |> filter(iso3 != infl_iso)
  fit_excl <- lm(y ~ x, data = df_excl)
  fit_excl_s <- summary(fit_excl)

  cat(
    "M",
    r$model_id,
    ": exclude ",
    infl_iso,
    " (Cook's D=",
    round(top_infl$cooksd, 3),
    ")\n",
    "  Original: slope=",
    round(r$slope, 3),
    " R2=",
    round(r$r2, 3),
    " p=",
    round(r$pval, 4),
    "\n",
    "  Excl.top: slope=",
    round(coef(fit_excl)[2], 3),
    " R2=",
    round(fit_excl_s$r.squared, 3),
    " p=",
    round(coef(fit_excl_s)[2, 4], 4),
    "\n",
    sep = ""
  )
}

# ---------------------------------------------------------------------------
# Coverage-restricted sensitivity (>= 3 baseline observations)
# ---------------------------------------------------------------------------

cat("\n================================================================\n")
cat("COVERAGE-RESTRICTED SENSITIVITY (>=3 obs in baseline window)\n")
cat("================================================================\n\n")

sens_specs <- list(
  list(
    id = "S1",
    window = "2015-19",
    indicator = "OWID vspend",
    sample = "OWID",
    data = owid_data,
    x = "vspend_mean_1519",
    n_col = "vspend_n_1519"
  ),
  list(
    id = "S2",
    window = "2015-19",
    indicator = "WDI receipts",
    sample = "WDI",
    data = wdi_data,
    x = "receipts_mean_1519",
    n_col = "receipts_n_1519"
  ),
  list(
    id = "S3",
    window = "2015-19",
    indicator = "OWID vspend",
    sample = "Common",
    data = common_data,
    x = "vspend_mean_1519",
    n_col = "vspend_n_1519"
  ),
  list(
    id = "S4",
    window = "2017-19",
    indicator = "OWID vspend",
    sample = "OWID",
    data = owid_data,
    x = "vspend_mean_1719",
    n_col = "vspend_n_1719"
  ),
  list(
    id = "S5",
    window = "2017-19",
    indicator = "WDI receipts",
    sample = "WDI",
    data = wdi_data,
    x = "receipts_mean_1719",
    n_col = "receipts_n_1719"
  ),
  list(
    id = "S6",
    window = "2017-19",
    indicator = "OWID vspend",
    sample = "Common",
    data = common_data,
    x = "vspend_mean_1719",
    n_col = "vspend_n_1719"
  )
)

sens_rows <- lapply(sens_specs, function(ss) {
  data_full <- ss$data
  data_restr <- data_full |> filter(.data[[ss$n_col]] >= 3)
  excluded <- setdiff(data_full$iso3, data_restr$iso3)
  fit_r <- fit_model(
    data_restr,
    ss$x,
    y_col,
    paste0(
      ss$id,
      ": ",
      ss$indicator,
      " [",
      ss$window,
      "] ",
      ss$sample,
      " >=3 obs"
    )
  )
  cat(ss$id, ":", ss$indicator, "[", ss$window, "]", ss$sample, ">=3 obs\n")
  cat("  Excluded:", paste(excluded, collapse = ", "), "\n")
  if (is.null(fit_r)) {
    return(NULL)
  }
  cat(
    "  N=",
    fit_r$n,
    " slope=",
    round(fit_r$slope, 3),
    " R2=",
    round(fit_r$r2, 3),
    " p=",
    round(fit_r$pval, 4),
    "\n\n"
  )
  tibble(
    Sensitivity = ss$id,
    Window = ss$window,
    Indicator = ss$indicator,
    Sample = ss$sample,
    N = fit_r$n,
    Excluded = paste(excluded, collapse = ","),
    Slope = round(fit_r$slope, 3),
    R2 = round(fit_r$r2, 3),
    Pearson = round(fit_r$pearson, 3),
    Spearman = round(fit_r$spearman, 3),
    p_raw = round(fit_r$pval, 4)
  )
})

sens_tbl <- bind_rows(sens_rows)
write_csv(sens_tbl, file.path(tbl_dir, "shock_sensitivity_restricted.csv"))

# ---------------------------------------------------------------------------
# Figure 5: 4-panel comparison (2015-2019 baseline)
# ---------------------------------------------------------------------------

pal_region <- c(
  "Caribbean" = "#0072B2",
  "Pacific" = "#D55E00",
  "AIMS" = "#009E73"
)

make_scatter <- function(r) {
  # r$df has the renamed x/y cols plus all original columns including iso3, sids_region
  # Add label and thin_baseline flag
  n_col <- if (grepl("vspend", r$x_col)) {
    if (grepl("1519", r$x_col)) "vspend_n_1519" else "vspend_n_1719"
  } else {
    if (grepl("1519", r$x_col)) "receipts_n_1519" else "receipts_n_1719"
  }

  df <- r$df |>
    mutate(
      label_disp = coalesce(short_labels[iso3], iso3),
      thin = .data[[n_col]] == 1
    )

  fit_ann <- paste0(
    "slope=",
    round(r$slope, 3),
    " | R\u00b2=",
    round(r$r2, 3),
    " | p=",
    round(r$pval, 4)
  )

  ggplot(df, aes(x = x, y = y, color = sids_region)) +
    geom_hline(yintercept = 0, color = "grey70", linewidth = 0.4) +
    geom_smooth(
      method = "lm",
      formula = y ~ x,
      se = TRUE,
      color = "grey40",
      fill = "grey88",
      linewidth = 0.6,
      alpha = 0.35,
      show.legend = FALSE
    ) +
    geom_point(aes(shape = thin), size = 2.8, alpha = 0.9) +
    geom_text(
      aes(label = label_disp),
      size = 2.3,
      vjust = -0.85,
      check_overlap = TRUE
    ) +
    scale_color_manual(values = pal_region, name = "Region") +
    scale_shape_manual(
      values = c("FALSE" = 16, "TRUE" = 1),
      name = "Baseline",
      labels = c("FALSE" = "Full", "TRUE" = "Thin (1 obs)")
    ) +
    scale_x_continuous(
      labels = label_number(suffix = "%"),
      expand = expansion(mult = c(0.04, 0.08))
    ) +
    scale_y_continuous(
      labels = label_number(suffix = "%"),
      expand = expansion(mult = c(0.05, 0.05))
    ) +
    annotate(
      "text",
      x = Inf,
      y = Inf,
      label = fit_ann,
      hjust = 1.05,
      vjust = 1.5,
      size = 2.6,
      color = "grey35"
    ) +
    labs(
      title = r$label,
      x = if (grepl("vspend", r$x_col)) {
        "Visitor spending (% GDP)"
      } else {
        "Tourism receipts (% exports)"
      },
      y = "GDP growth 2020 (%)"
    ) +
    theme(
      plot.title = element_text(size = 9, face = "bold"),
      legend.position = "none"
    )
}

plots_1519 <- lapply(results[1:4], make_scatter)

p5 <- ggpubr_or_patchwork <- tryCatch(
  {
    library(patchwork)
    (plots_1519[[1]] | plots_1519[[2]]) /
      (plots_1519[[3]] | plots_1519[[4]]) +
      plot_annotation(
        title = "Tourism Dependence and 2020 GDP Growth: 2015\u20132019 Baseline",
        subtitle = "Four model specifications; OLS regression line with 95% CI band shown",
        caption = "Sources: OWID/UN Tourism; WDI ST.INT.RCPT.XP.ZS; WDI NY.GDP.MKTP.KD.ZG.\nExploratory OLS; does not imply causation. Open circles = thin baseline (1 obs).",
        theme = theme(
          plot.title = element_text(face = "bold", size = 13),
          plot.subtitle = element_text(size = 10, color = "grey35"),
          plot.caption = element_text(size = 7.5, color = "grey50", hjust = 0)
        )
      )
  },
  error = function(e) NULL
)

if (!is.null(p5)) {
  save_fig(p5, "fig5_shock_4panel_1519", w = 13, h = 10)
  message("Saved: fig5_shock_4panel_1519")
}

# ---------------------------------------------------------------------------
# Figure 6: Common-sample comparison (isolates indicator differences)
# ---------------------------------------------------------------------------

r3 <- results[["M3"]] # vspend 2015-19, common
r4 <- results[["M4"]] # receipts 2015-19, common

if (!is.null(r3) && !is.null(r4)) {
  common_comp <- r3$df |>
    rename(vspend = x, gdp_growth = y) |>
    left_join(
      r4$df |> select(iso3, receipts = x),
      by = "iso3"
    ) |>
    mutate(label_disp = coalesce(short_labels[iso3], iso3)) |>
    pivot_longer(
      c(vspend, receipts),
      names_to = "indicator",
      values_to = "tourism_dep"
    ) |>
    mutate(
      indicator = factor(
        indicator,
        levels = c("vspend", "receipts"),
        labels = c(
          "OWID visitor spending (% GDP)",
          "WDI tourism receipts (% exports)"
        )
      )
    )

  p6 <- ggplot(
    common_comp,
    aes(x = tourism_dep, y = gdp_growth, color = sids_region)
  ) +
    geom_hline(yintercept = 0, color = "grey70", linewidth = 0.4) +
    geom_smooth(
      method = "lm",
      formula = y ~ x,
      se = TRUE,
      color = "grey40",
      fill = "grey88",
      linewidth = 0.7,
      alpha = 0.35,
      show.legend = FALSE
    ) +
    geom_point(size = 2.8, alpha = 0.9) +
    geom_text(
      aes(label = label_disp),
      size = 2.4,
      vjust = -0.8,
      check_overlap = TRUE
    ) +
    facet_wrap(~indicator, scales = "free_x") +
    scale_color_manual(values = pal_region, name = "Region") +
    scale_y_continuous(
      labels = label_number(suffix = "%"),
      expand = expansion(mult = c(0.05, 0.05))
    ) +
    scale_x_continuous(
      labels = label_number(suffix = "%"),
      expand = expansion(mult = c(0.04, 0.08))
    ) +
    labs(
      title = "Common Sample (N=24): Both Indicators, 2015\u20132019 Baseline",
      subtitle = "Same 24 economies; indicator difference isolates measurement choice from sample composition",
      x = "Tourism dependence measure",
      y = "GDP growth 2020 (%)",
      caption = "Sources: OWID/UN Tourism; WDI ST.INT.RCPT.XP.ZS; WDI NY.GDP.MKTP.KD.ZG."
    )
  save_fig(p6, "fig6_common_sample_comparison", w = 11, h = 5.5)
}

message("Done: 04_shock_models.R")
