# Island Time, Interrupted

**Tourism Dependence and the COVID Cliff**

> Were Caribbean, Pacific, and AIMS small island developing states with greater
> pre-pandemic dependence on international tourism more vulnerable to the
> economic shock of COVID-19? Which economies had recovered to pre-pandemic
> levels of real output by 2022–2023?

---

## Repository structure

```
_quarto.yml              Quarto website configuration (renders to docs/)
index.qmd                Feasibility audit document
styles.css               Custom stylesheet
data/
├── raw/
│   ├── international-tourist-trips/
│   ├── spending-by-international-visitors-while-visiting-a-country-as-a-share-of-gdp/
│   ├── tourism-gdp-proportion-of-total-gdp/
│   └── worldbank/       WDI data retrieved via wbstats
└── processed/           Cleaned and joined datasets
R/
├── 01_data_acquisition.R   Load OWID + retrieve WB WDI data
├── 02_data_quality.R       Coverage matrix and feasibility audit
└── 03_preliminary_eda.R    EDA analysis and publication figures
output/
├── figures/             PNG (300 dpi) and SVG figures
└── tables/              CSV analysis tables
docs/                    Rendered website (GitHub Pages source)
README.md
LICENSE
```

---

## Scripts

| Script | Purpose |
|--------|---------|
| `R/01_data_acquisition.R` | Load OWID CSVs; retrieve WDI indicators (2008–2025) via wbstats |
| `R/02_data_quality.R` | Coverage matrix; 2015–2019 and 2017–2019 baselines; fixed sample flags |
| `R/03_preliminary_eda.R` | Tourism-dependence rankings and preliminary figures (figs 1–4) |
| `R/04_shock_models.R` | Eight-model shock analysis; influential observations; sensitivity (figs 5–6) |
| `R/05_recovery_analysis.R` | Real GDP recovery trajectories; 2019=100 index (figs 7–8) |

---

## Reproducing the analysis

### Prerequisites

- **R ≥ 4.4.0**
- **Quarto ≥ 1.4**
- R packages: `tidyverse`, `wbstats`, `scales`, `here`, `knitr`, `rmarkdown`, `svglite`

Install missing packages:

```r
install.packages(c("tidyverse", "wbstats", "scales", "here",
                   "knitr", "rmarkdown", "svglite"))
```

### Run the analysis

Open an R session with the working directory set to the repository root
(`here()` anchors at the `.git` directory).

```r
source("R/01_data_acquisition.R")   # ~2-3 min (World Bank API call, retrieves 2008-2025)
source("R/02_data_quality.R")       # builds coverage matrix and 2015-19/2017-19 baselines
source("R/03_preliminary_eda.R")    # preliminary figures (figs 1-4)
source("R/04_shock_models.R")       # 8-model shock comparison (figs 5-6)
source("R/05_recovery_analysis.R")  # recovery trajectories (figs 7-8)
```

### Render the Quarto document

```bash
quarto render index.qmd
```

The rendered HTML is written to `docs/index.html`.

> **Note:** R scripts must be run before rendering because the Quarto
> document reads pre-computed output files from `data/processed/` and
> `output/figures/`. The scripts do not re-execute inside the document.

---

## Data sources

| Dataset | Source | Notes |
|---------|--------|-------|
| International visitor spending (% GDP) | OWID / UN Tourism | Primary dependence measure. No single WDI code. |
| Tourism contribution to GDP | OWID / UN Tourism | TSA methodology; coverage gaps for many SIDS |
| International tourist arrivals | OWID / UN Tourism | Volume measure, not a dependence indicator |
| Tourism receipts (% exports) | WDI `ST.INT.RCPT.XP.ZS` | Complementary dependence measure |
| GDP growth | WDI `NY.GDP.MKTP.KD.ZG` | 2020 shock measure |
| GDP, constant 2015 USD | WDI `NY.GDP.MKTP.KD` | Primary real recovery measure |
| GDP/capita, constant 2015 USD | WDI `NY.GDP.PCAP.KD` | Per-capita real recovery measure |
| GDP/capita, current USD | WDI `NY.GDP.PCAP.CD` | Nominal reference only |
| Unemployment | WDI `SL.UEM.TOTL.ZS` | Sparse coverage for Pacific micro-states |

Raw OWID CSV files are stored in `data/raw/` and are not modified.
WDI data is retrieved programmatically and saved to `data/raw/worldbank/`.

### Important: OWID visitor spending attribution

The OWID indicator *Spending by international visitors while visiting a
country as a share of GDP* is **not** equivalent to WDI indicator
`ST.INT.XPND.GD.ZS`. The OWID numerator (inbound tourism receipts) comes
from UN Tourism statistics; the denominator (GDP) comes from World Bank
national accounts. Do not substitute or combine these series.

---

## Candidate universe

58 economies across three SIDS regions:

- **39 UN Member SIDS:** Sovereign states formally recognised as SIDS by the
  United Nations. Authority: UN-OHRLLS list of SIDS.
- **18 Associate Members:** Associate members of UN Regional Commissions
  included in the SIDS group (territories and dependencies).
- **1 other island economy:** BES (Bonaire, Sint Eustatius and Saba),
  retained from the original candidate list; not on the UN SIDS list.

| Region | UN SIDS | Associates | Other | Total |
|--------|---------|------------|-------|-------|
| Caribbean | 16 | 13 | 1 | 30 |
| Pacific | 15 | 5 | 0 | 20 |
| AIMS | 8 | 0 | 0 | 8 |
| **Total** | **39** | **18** | **1** | **58** |

7 economies are not in the World Bank WDI database:
AIA, GLP, MTQ, MSR, BES, COK, NIU.

---

## Key results

### Shock analysis

| Sample | N | Indicator | Window | Slope | R² | p (raw) | p (Holm) |
|--------|---|-----------|--------|-------|----|---------|----------|
| OWID | 29 | Visitor spending % GDP | 2015-19 | −0.308 | 0.414 | 0.0002 | 0.001 |
| WDI  | 35 | Tourism receipts % exports | 2015-19 | −0.120 | 0.100 | 0.065 | 0.129 |
| Common | 24 | Visitor spending % GDP | 2015-19 | −0.331 | 0.489 | 0.0001 | 0.001 |
| Common | 24 | Tourism receipts % exports | 2015-19 | −0.158 | 0.233 | 0.017 | 0.053 |

**Primary finding:** Consistent negative association between pre-pandemic visitor spending (% GDP) and 2020 GDP growth across all OWID sample specifications. WDI receipts show a weaker, inconsistent signal.

**Maldives (MDV) is influential** in all OWID models (Cook's D ≈ 0.36–0.39); exclusion weakens but does not reverse the result.

### Recovery

- 19 of 28 economies with 2023 data had recovered to 2019 real GDP levels by 2023.
- No significant association between pre-pandemic tourism dependence and 2023 recovery index (Pearson r=0.18, p=0.36): tourism-dependent economies had the worst shocks but also the strongest recoveries.
- Real GDP data: 2015–2022 complete (N=29); 2023–2024 (N=28); 2025 preliminary (N=22).

### Important data notes

- **WDI tourism receipts (`ST.INT.RCPT.XP.ZS`):** No data beyond 2020; significant publication lag.
- **OWID visitor spending:** Available through 2024; no single WDI indicator code.
- **Seven economies not in WDI:** AIA, GLP, MTQ, MSR, BES, COK, NIU.

---

## Publishing

The site is published from the `docs/` folder on the `main` branch via
GitHub Pages. To update the published site, re-run the analysis scripts
and re-render:

```bash
quarto render index.qmd
git add docs/
git commit -m "Update rendered site"
git push
```

---

## License

Data from Our World in Data and the World Bank are used under their
respective open-data licenses. See source URLs in the raw data files.
