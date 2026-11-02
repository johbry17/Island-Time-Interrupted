# Island Time, Interrupted

**Tourism Dependence and the COVID Cliff in Small Island Developing States**

When COVID-19 shut down international travel, small island economies that depended most on tourism contracted the most. This project documents that association across 29 Caribbean, Pacific, and AIMS economies using pre-pandemic visitor spending data and 2020 GDP growth, then traces the recovery through 2023–2025.

**The central finding:** Each additional percentage point of international visitor spending relative to GDP was associated with approximately 0.31 percentage points of additional GDP contraction in 2020 (OLS, N=29, R² ≈ 0.41–0.49, p < 0.001). The result is stable across two baseline windows, two samples, and after excluding the most influential observation (Maldives).

By 2023, 19 of 28 economies with data had returned to their 2019 aggregate real GDP level; 17 had returned to their 2019 real GDP per capita.

---

## Published site

> **[https://johbry17.github.io/Island-Time-Interrupted/](https://johbry17.github.io/Island-Time-Interrupted/)**

| Page | Description |
|------|-------------|
| [Field Note](https://johbry17.github.io/Island-Time-Interrupted/index.html) | Public-facing research communication: question, findings, figures, limitations |
| [Analysis](https://johbry17.github.io/Island-Time-Interrupted/analysis.html) | Full technical results: all 8 models, diagnostics, recovery tables and figures |
| [Data Dictionary](https://johbry17.github.io/Island-Time-Interrupted/data-dictionary.html) | Indicator definitions, sources, units, coverage, and limitations |
| [Methodology](https://johbry17.github.io/Island-Time-Interrupted/methodology.html) | Research design, sample construction, baseline windows, model specification, reproduction |

---

## Data sources and coverage

| Dataset | Source | Years | Geography |
|---------|--------|-------|-----------|
| Visitor spending (% GDP) | OWID / UN Tourism | 1995–2024 | ~200 countries |
| Tourism direct GDP (% GDP) | OWID / UN Tourism (TSA) | 2008–2023 | ~125 countries |
| Tourist arrivals | OWID / UN Tourism | 1995–2024 | ~207 countries |
| Tourism receipts (% exports) | WDI `ST.INT.RCPT.XP.ZS` | ~1995–2020* | ~180 countries |
| Real GDP (const. 2015 USD) | WDI `NY.GDP.MKTP.KD` | 2008–2025 | 51 candidates |
| Real GDP per capita | WDI `NY.GDP.PCAP.KD` | 2008–2025 | 51 candidates |
| GDP growth (annual %) | WDI `NY.GDP.MKTP.KD.ZG` | 2008–2025 | 51 candidates |

\* WDI tourism receipts has a significant publication lag. No observations beyond 2020 were available in the November 2026 retrieval.

**Candidate universe:** 58 economies — 39 UN Member SIDS + 18 Associate Member SIDS + 1 other island economy (BES), across Caribbean (30), Pacific (20), and AIMS (8) regions. Authority: UN-OHRLLS, retrieved November 2026.

**7 candidate economies not in WDI:** AIA, GLP, MTQ, MSR, BES, COK, NIU.

---

## Repository structure

```
_quarto.yml              Quarto site configuration (renders to docs/)
index.qmd                Field Note (public-facing)
analysis.qmd             Full technical analysis
data-dictionary.qmd      Data sources, definitions, and limitations
methodology.qmd          Research design and reproduction instructions
styles.css               Site stylesheet
images/                  Favicon and site images
data/
├── raw/
│   ├── international-tourist-trips/            OWID arrivals CSV
│   ├── spending-by-international-visitors-.../ OWID visitor spending CSV
│   ├── tourism-gdp-proportion-of-total-gdp/    OWID tourism GDP CSV
│   └── worldbank/                              WDI data (retrieved via wbstats)
└── processed/                                  Cleaned datasets and outputs
R/
├── 01_data_acquisition.R     Load OWID CSVs; retrieve WDI via wbstats (2008-2025)
├── 02_data_quality.R         Coverage matrix; 2015-19 and 2017-19 baselines
├── 03_preliminary_eda.R      Tourism-dependence rankings and preliminary figures
├── 04_shock_models.R         Eight-model shock analysis; diagnostics; sensitivity
└── 05_recovery_analysis.R    Real GDP recovery trajectories and tables
output/
├── figures/                  PNG (300 dpi) and SVG figures (figs 1-8)
└── tables/                   CSV output tables (models, sensitivity, recovery)
docs/                         Rendered website (GitHub Pages source — do not edit directly)
archive/                      Superseded planning documents
LICENSE
README.md
```

---

## Prerequisites

- **R ≥ 4.4.0**
- **Quarto ≥ 1.4**
- R packages: `tidyverse`, `wbstats`, `here`, `scales`, `knitr`, `rmarkdown`, `patchwork`, `svglite`

Install missing packages:
```r
install.packages(c("tidyverse","wbstats","here","scales",
                   "knitr","rmarkdown","patchwork","svglite"))
```

---

## Reproducing the analysis

Run from the **repository root** (where `.git` is located). The `here` package anchors paths there automatically.

```r
source("R/01_data_acquisition.R")   # ~2-3 min; calls World Bank API
source("R/02_data_quality.R")
source("R/03_preliminary_eda.R")
source("R/04_shock_models.R")
source("R/05_recovery_analysis.R")
```

### Render the full site

```bash
quarto render
```

This renders all four pages to `docs/`. Open `docs/index.html` locally to preview.

> **Note:** R scripts must be run before rendering. The Quarto pages read from pre-computed files in `data/processed/` and `output/`. They do not re-execute the R scripts at render time.

---

## Publishing to GitHub Pages

The site is published from `docs/` on the `main` branch.

GitHub repository → Settings → Pages → Deploy from a branch → `main` → `/docs`.

`docs/` is committed to the repository and should not be in `.gitignore`.

---

## Data provenance

**OWID data** are downloaded CSV files from Our World in Data (January–July 2026). They will not update automatically. To refresh, download new CSVs from the OWID grapher and replace files in `data/raw/`.

**WDI data** are retrieved programmatically via `wbstats::wb_data()`. Retrieval date and returned country codes are logged in `data/raw/worldbank/wdi_retrieval_metadata.txt`. Re-running `01_data_acquisition.R` will pull the latest available WDI data, which may differ from results reported here.

**OWID visitor spending** is sourced from UN Tourism statistics and World Bank national accounts. It does not correspond to a single WDI indicator code; do not attribute it to `ST.INT.XPND.GD.ZS`.

---

## License

OWID data are used under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). World Bank WDI data are used under [CC BY 4.0](https://datacatalog.worldbank.org/public-licenses#cc-by). Analysis code and narrative are the work of Bryan C. Johns. See LICENSE file.
