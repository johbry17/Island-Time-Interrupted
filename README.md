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
source("R/01_data_acquisition.R")   # ~1-2 min (World Bank API call)
source("R/02_data_quality.R")
source("R/03_preliminary_eda.R")
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

## Key results (feasibility audit)

| Sample | N |
|--------|---|
| Candidate universe | 58 |
| Tourism-data sample (any indicator) | 48 |
| Primary shock sample (vspend + 2020 GDP growth) | 29 |
| Recovery sample (primary shock + real GDP data) | 29 |

**Primary measure:** OWID visitor spending (% GDP).

**Shock analysis:** Slope = −0.32, R² = 0.428, p < 0.001 (N=29). Stable under sensitivity analysis excluding thin baselines (N=28, R² = 0.412).

See `docs/index.html` for the full feasibility report with figures and tables.

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
