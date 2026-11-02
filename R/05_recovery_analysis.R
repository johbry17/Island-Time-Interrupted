# =============================================================================
# 05_recovery_analysis.R
# Island Time, Interrupted: Tourism Dependence and the COVID Cliff
# Purpose: Real GDP recovery trajectories for SIDS shock sample, 2015-2025.
# Depends on: 02_data_quality.R having been run first.
# Run from: repository root (here() anchors at .git)
# =============================================================================
# NOTE ON RECOVERY MEASUREMENT:
# Aggregate real GDP (NY.GDP.MKTP.KD, constant 2015 USD) and real GDP per
# capita (NY.GDP.PCAP.KD) are the primary measures. Nominal GDP per capita
# is not used for recovery comparisons because it conflates real output with
# price and exchange-rate changes.
#
# Annual sample sizes vary; see coverage tables. Do not compare 2025 data
# (N=37) directly with 2020 data (N=49/50) as if they are the same sample.
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

analytical <- read_csv(file.path(processed, "analytical_panel.csv"), show_col_types = FALSE)
bl         <- read_csv(file.path(processed, "baseline_shock_recovery.csv"), show_col_types = FALSE)
cands      <- read_csv(file.path(processed, "candidates.csv"), show_col_types = FALSE)

# ---------------------------------------------------------------------------
# Design system
# ---------------------------------------------------------------------------

pal_region <- c("Caribbean"="#0072B2", "Pacific"="#D55E00", "AIMS"="#009E73")

base_theme <- theme_minimal(base_size = 11) +
  theme(
    text              = element_text(family="sans", color="grey15"),
    plot.title        = element_text(face="bold", size=12, margin=margin(b=4)),
    plot.subtitle     = element_text(size=9.5, color="grey35", margin=margin(b=8)),
    plot.caption      = element_text(size=7.5, color="grey50", hjust=0),
    axis.title        = element_text(size=9, color="grey25"),
    axis.text         = element_text(size=8.5, color="grey30"),
    panel.grid.major  = element_line(color="grey92"),
    panel.grid.minor  = element_blank(),
    legend.title      = element_text(size=9, face="bold"),
    legend.text       = element_text(size=8.5),
    plot.margin       = margin(12, 14, 8, 12)
  )
theme_set(base_theme)

save_fig <- function(nm, w=10, h=6.5) {
  ggsave(file.path(fig_dir, paste0(nm, ".png")), width=w, height=h, dpi=300, bg="white")
  ggsave(file.path(fig_dir, paste0(nm, ".svg")), width=w, height=h, bg="white")
  message("Saved: ", nm)
}

short_labels <- c(
  ATG="Antigua",ABW="Aruba",    BHS="Bahamas",  BMU="Bermuda",  BRB="Barbados",
  COM="Comoros", CPV="CapeVerde",CUB="Cuba",    CUW="Curacao",  CYM="Cayman Is.",
  DMA="Dominica",DOM="Dom.Rep.", FJI="Fiji",    GNB="Guinea-B.",GRD="Grenada",
  HTI="Haiti",   KIR="Kiribati",KNA="St.Kitts", LCA="St.Lucia", MDV="Maldives",
  MHL="Marshall Is.",MUS="Mauritius",NRU="Nauru",PLW="Palau",  PNG="Papua NG",
  PRI="Puerto Rico",SLB="Solomon Is.",SGP="Singapore",STP="São Tomé",
  SUR="Suriname",SXM="Sint Maarten",SYC="Seychelles",TLS="Timor-Leste",
  TON="Tonga",   TTO="Trinidad",TUV="Tuvalu",  VCT="St.Vincent",VIR="US VI",
  VUT="Vanuatu", WSM="Samoa"
)

# ---------------------------------------------------------------------------
# Restrict to primary shock sample (N=29) for recovery analysis
# ---------------------------------------------------------------------------
# These 29 economies have both the vspend baseline and 2020 GDP growth data.
# Not all will have complete recovery trajectories.

shock_isos <- bl |> filter(in_primary_shock_sample) |> pull(iso3)

recovery_panel <- analytical |>
  filter(iso3 %in% shock_isos, year %in% 2015:2025) |>
  mutate(label = coalesce(short_labels[iso3], iso3))

# ---------------------------------------------------------------------------
# Coverage audit: real GDP by year
# ---------------------------------------------------------------------------

cat("\n================================================================\n")
cat("REAL GDP COVERAGE AUDIT (Primary Shock Sample, N=29)\n")
cat("================================================================\n\n")

cat("=== GDP constant 2015 USD by year ===\n")
recovery_panel |>
  group_by(year) |>
  summarise(
    n_avail = sum(!is.na(gdp_real_const2015usd)),
    pct     = round(100 * n_avail / 29, 0)
  ) |>
  print(n=20)

cat("\n=== GDP per capita constant 2015 USD by year ===\n")
recovery_panel |>
  group_by(year) |>
  summarise(
    n_avail = sum(!is.na(gdppc_real_const2015usd)),
    pct     = round(100 * n_avail / 29, 0)
  ) |>
  print(n=20)

# Economies with 2019 AND all subsequent years
cat("\n=== Economies with real GDP in 2019 AND all years through: ===\n")
for (end_yr in c(2021, 2022, 2023, 2024, 2025)) {
  complete <- recovery_panel |>
    filter(year %in% c(2019, end_yr)) |>
    group_by(iso3) |>
    summarise(has_both = all(!is.na(gdp_real_const2015usd))) |>
    filter(has_both)
  cat(" ...through", end_yr, ": N =", nrow(complete),
      "(", paste(sort(complete$iso3), collapse=", "), ")\n")
}

# ---------------------------------------------------------------------------
# Compute recovery index (2019 = 100)
# ---------------------------------------------------------------------------

# Get 2019 baseline values
base_2019 <- recovery_panel |>
  filter(year == 2019) |>
  select(iso3, gdp_2019 = gdp_real_const2015usd,
         gdppc_2019 = gdppc_real_const2015usd)

recovery_idx <- recovery_panel |>
  left_join(base_2019, by = "iso3") |>
  mutate(
    gdp_index    = 100 * gdp_real_const2015usd    / gdp_2019,
    gdppc_index  = 100 * gdppc_real_const2015usd  / gdppc_2019
  ) |>
  filter(!is.na(gdp_2019))   # only economies with 2019 data

cat("\n=== Economies with 2019 real GDP baseline: ===\n")
cat(length(unique(recovery_idx$iso3)), "economies\n")

# Pre-pandemic tourism dependence for colouring trajectories
vspend_2019 <- bl |>
  filter(iso3 %in% unique(recovery_idx$iso3)) |>
  select(iso3, vspend_mean_1519, vspend_n_1519,
         vspend_mean_1719, sids_region)

recovery_idx <- recovery_idx |>
  left_join(vspend_2019, by = "iso3", suffix = c("", "_drop")) |>
  select(-ends_with("_drop"))

# Write recovery index dataset
write_csv(recovery_idx, file.path(processed, "recovery_index.csv"))
message("Recovery index saved: ", nrow(recovery_idx), " rows")

# ---------------------------------------------------------------------------
# Recovery summary table
# ---------------------------------------------------------------------------

# For each economy: was real GDP above 100 (i.e., above 2019) in 2022, 2023, 2024?
recovery_summary <- recovery_idx |>
  filter(year %in% c(2020, 2021, 2022, 2023, 2024, 2025)) |>
  select(iso3, label, sids_region, year, gdp_index) |>
  pivot_wider(names_from = year, values_from = gdp_index,
              names_prefix = "gdp_idx_") |>
  mutate(
    shock_2020   = round(gdp_idx_2020, 1),
    recovered_by_2022 = !is.na(gdp_idx_2022) & gdp_idx_2022 >= 100,
    recovered_by_2023 = !is.na(gdp_idx_2023) & gdp_idx_2023 >= 100,
    recovered_by_2024 = !is.na(gdp_idx_2024) & gdp_idx_2024 >= 100
  ) |>
  left_join(
    bl |> select(iso3, vspend_mean_1519, vspend_mean_1719),
    by = "iso3"
  ) |>
  arrange(sids_region, iso3)

cat("\n================================================================\n")
cat("RECOVERY SUMMARY (2019 = 100)\n")
cat("================================================================\n\n")
recovery_summary |>
  select(iso3, label, sids_region, shock_2020,
         gdp_idx_2022, gdp_idx_2023, gdp_idx_2024,
         recovered_by_2022, recovered_by_2023) |>
  mutate(across(starts_with("gdp_idx"), ~round(., 1))) |>
  print(n=40)

write_csv(recovery_summary, file.path(tbl_dir, "recovery_summary.csv"))

cat("\n=== Recovered to 2019 level by 2023: ===\n")
rec_2023 <- recovery_summary |> filter(recovered_by_2023, !is.na(gdp_idx_2023))
cat("N =", nrow(rec_2023), ":", paste(sort(rec_2023$iso3), collapse=", "), "\n")
cat("Not recovered / missing by 2023: ",
    sum(recovery_summary$gdp_idx_2023 < 100, na.rm=TRUE), "economies\n")
cat("Missing 2023 data:", sum(is.na(recovery_summary$gdp_idx_2023)), "economies\n")

# ---------------------------------------------------------------------------
# Figure 7: GDP recovery trajectories (2015-2025), faceted by region
# ---------------------------------------------------------------------------

# Use economies with 2019 AND 2023 data for the main panel
has_2023 <- recovery_idx |>
  filter(year %in% c(2019,2023)) |>
  group_by(iso3) |>
  summarise(complete = all(!is.na(gdp_index))) |>
  filter(complete) |>
  pull(iso3)

# Annual sample sizes for annotation
annual_n <- recovery_idx |>
  filter(!is.na(gdp_index)) |>
  group_by(year) |>
  summarise(n = n())

p7 <- ggplot(
  recovery_idx |> filter(!is.na(gdp_index)),
  aes(x = year, y = gdp_index, group = iso3)
) +
  geom_hline(yintercept=100, color="grey40", linewidth=0.7, linetype="solid") +
  geom_line(aes(color = sids_region), alpha = 0.65, linewidth = 0.65) +
  geom_point(data = recovery_idx |> filter(year == 2020, !is.na(gdp_index)),
             aes(color = sids_region), size = 1.8, alpha = 0.9) +
  facet_wrap(~sids_region, ncol = 1, scales = "fixed") +
  geom_text(
    data = annual_n, inherit.aes = FALSE,
    aes(x = year, y = 55, label = paste0("n=", n)),
    size = 2.2, color = "grey55", hjust = 0.5
  ) +
  scale_color_manual(values = pal_region, name = "Region") +
  scale_x_continuous(breaks = c(2015, 2017, 2019, 2021, 2023, 2025)) +
  scale_y_continuous(labels = label_number(suffix = ""),
                     limits = c(50, 165),
                     breaks = seq(60, 160, by = 20)) +
  labs(
    title    = "Real GDP Recovery Trajectories: 2015\u20132025",
    subtitle = "Primary shock sample (N \u226429); index 2019 = 100. Bottom row: annual sample sizes.",
    x        = NULL,
    y        = "Real GDP Index (2019 = 100)",
    caption  = paste0(
      "Source: WDI NY.GDP.MKTP.KD (constant 2015 USD). ",
      "Lines show individual economies by SIDS region. ",
      "Horizontal line = 2019 level. 2025 preliminary for some economies."
    )
  ) +
  theme(
    legend.position = "none",
    strip.text      = element_text(face = "bold", size = 9.5)
  )

save_fig("fig7_recovery_trajectories", w = 9, h = 10)

# ---------------------------------------------------------------------------
# Figure 8: Recovery index in 2023 vs pre-pandemic tourism dependence
# ---------------------------------------------------------------------------

# Use latest common year with good coverage (2023)
rec_vs_tourism <- recovery_idx |>
  filter(year == 2023, !is.na(gdp_index)) |>
  mutate(label_disp = coalesce(short_labels[iso3], iso3))

if (nrow(rec_vs_tourism) >= 6) {
  cor_p <- cor(rec_vs_tourism$vspend_mean_1519, rec_vs_tourism$gdp_index,
               use = "complete.obs")
  cor_s <- cor(rec_vs_tourism$vspend_mean_1519, rec_vs_tourism$gdp_index,
               method = "spearman", use = "complete.obs")
  fit_r <- lm(gdp_index ~ vspend_mean_1519, data = rec_vs_tourism)
  cat("\n=== Recovery vs. Tourism Dependence (2023) ===\n")
  cat("N:", nrow(rec_vs_tourism), "\n")
  cat("Pearson r:", round(cor_p, 3), "\n")
  cat("Spearman ρ:", round(cor_s, 3), "\n")
  cat("OLS slope:", round(coef(fit_r)[2], 3), " p =", round(summary(fit_r)$coef[2,4], 4), "\n")
  cat("(Exploratory only; does not imply causation)\n")

  p8 <- ggplot(rec_vs_tourism,
               aes(x = vspend_mean_1519, y = gdp_index, color = sids_region)) +
    geom_hline(yintercept=100, color="grey60", linewidth=0.5, linetype="dashed") +
    geom_smooth(method="lm", formula=y~x, se=TRUE,
                color="grey40", fill="grey88", linewidth=0.6, alpha=0.3,
                show.legend=FALSE) +
    geom_point(size=3, alpha=0.9) +
    geom_text(aes(label=label_disp), size=2.4, vjust=-0.8, check_overlap=TRUE) +
    scale_color_manual(values=pal_region, name="Region") +
    scale_x_continuous(labels=label_number(suffix="%"),
                       expand=expansion(mult=c(0.04,0.08))) +
    scale_y_continuous(labels=label_number(suffix=""),
                       expand=expansion(mult=c(0.04,0.04))) +
    annotate("text", x=Inf, y=Inf,
             label=paste0("Pearson r = ", round(cor_p,2), " | Spearman \u03c1 = ", round(cor_s,2)),
             hjust=1.1, vjust=1.5, size=2.8, color="grey35") +
    labs(
      title    = "Tourism Dependence and Recovery by 2023",
      subtitle = paste0("Pre-pandemic visitor spending vs. 2023 real GDP index (2019=100). N=",
                        nrow(rec_vs_tourism), "."),
      x        = "Visitor spending (% GDP, 2015-2019 avg.)",
      y        = "Real GDP index, 2023 (2019 = 100)",
      caption  = "Sources: OWID/UN Tourism; WDI NY.GDP.MKTP.KD. OLS line is exploratory."
    )
  save_fig("fig8_recovery_vs_tourism", w=8.5, h=6)
}

cat("Done: 05_recovery_analysis.R\n")
