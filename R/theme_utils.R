# =============================================================================
# theme_utils.R
# Island Time, Interrupted: Tourism Dependence and the COVID Cliff
#
# Shared plotting utilities for all R analysis scripts.
# Source: reports/themes/plot-styling-guide.md
#
# Provides:
#   - pal_archipelago_light / pal_archipelago_dark  : palette lists
#   - make_fn_theme(pal)                             : builds a ggplot2 theme
#   - theme_archipelago_light() / theme_archipelago_dark()
#   - pal_coverage_light / pal_coverage_dark         : coverage-matrix palettes
#   - save_fig_dual(p_light, p_dark, name, fig_dir, w, h)
# =============================================================================

library(ggplot2)

# ---------------------------------------------------------------------------
# Palettes
# ---------------------------------------------------------------------------

pal_archipelago_light <- list(
  series1   = "#1a3a52",   # deep navy
  series2   = "#2d7d8e",   # sea-glass teal
  series3   = "#c0634a",   # muted coral
  accent    = "#c0634a",   # same coral for highlight
  muted     = "#a0968a",   # warm grey
  reference = "#7a7368",   # muted warm
  bg        = "#f4f1eb",   # limestone
  panel     = "#f4f1eb",
  grid      = "#ddd8d0",
  text      = "#252320"
)

pal_archipelago_dark <- list(
  series1   = "#5bbcc9",   # sea-glass teal
  series2   = "#d4845e",   # warm coral
  series3   = "#7ab8c8",   # lighter teal
  accent    = "#d4845e",   # coral
  muted     = "#7a7068",
  reference = "#5a5248",
  bg        = "#0d1e2b",   # deep ocean night
  panel     = "#132535",
  grid      = "#1f3348",
  text      = "#ddd8d0"
)

# Coverage matrix: Available / Partial / None (data completeness, not regions)
pal_coverage_light <- c(
  "Available" = "#2a9d8f",   # teal
  "Partial"   = "#e9c46a",   # amber
  "None"      = "#e8e8e8"    # light grey
)

pal_coverage_dark <- c(
  "Available" = "#3dbcae",   # lighter teal (more visible on dark background)
  "Partial"   = "#d4a830",   # darker amber
  "None"      = "#2a3340"    # dark navy-grey (distinct from panel background)
)

# ---------------------------------------------------------------------------
# ggplot2 theme functions
# ---------------------------------------------------------------------------

make_fn_theme <- function(pal, base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      text              = element_text(color = pal$text),
      plot.background   = element_rect(fill = pal$panel, color = NA),
      panel.background  = element_rect(fill = pal$panel, color = NA),
      panel.grid.major  = element_line(color = pal$grid, linewidth = 0.5),
      panel.grid.minor  = element_blank(),
      axis.text         = element_text(color = pal$text, size = rel(0.85)),
      axis.title        = element_text(color = pal$text, size = rel(0.9)),
      plot.title        = element_text(color = pal$text, face = "bold",
                                       size = rel(1.2), margin = margin(b = 4)),
      plot.subtitle     = element_text(color = pal$muted, size = rel(1.0),
                                       margin = margin(b = 8)),
      plot.caption      = element_text(color = pal$muted, size = rel(0.72),
                                       hjust = 0, margin = margin(t = 8)),
      legend.background = element_rect(fill = pal$panel, color = NA),
      legend.key        = element_rect(fill = pal$panel, color = NA),
      legend.text       = element_text(color = pal$text, size = rel(0.85)),
      legend.title      = element_text(color = pal$text, size = rel(0.85),
                                       face = "bold"),
      strip.text        = element_text(color = pal$text, face = "bold",
                                       size = rel(0.9)),
      strip.background  = element_rect(fill = pal$grid, color = NA),
      plot.margin       = margin(14, 16, 10, 14)
    )
}

theme_archipelago_light <- function(base_size = 11)
  make_fn_theme(pal_archipelago_light, base_size)

theme_archipelago_dark <- function(base_size = 11)
  make_fn_theme(pal_archipelago_dark, base_size)

# ---------------------------------------------------------------------------
# Dual save function
# ---------------------------------------------------------------------------
# Accepts two pre-styled ggplot objects (one per theme) and saves all four
# output files: _light.png, _light.svg, _dark.png, _dark.svg.
# Plots must be fully styled before passing — no theme is applied here.

save_fig_dual <- function(p_light, p_dark, name, fig_dir, w = 8.5, h = 6) {
  for (suffix in c("_light", "_dark")) {
    p   <- if (suffix == "_light") p_light else p_dark
    pal <- if (suffix == "_light") pal_archipelago_light else pal_archipelago_dark

    ggsave(
      filename = file.path(fig_dir, paste0(name, suffix, ".png")),
      plot     = p,
      width    = w, height = h, dpi = 300,
      bg       = pal$bg
    )
    ggsave(
      filename = file.path(fig_dir, paste0(name, suffix, ".svg")),
      plot     = p,
      width    = w, height = h,
      bg       = pal$bg
    )
  }
  message("Saved: ", name, " (_light + _dark, .png + .svg)")
}
