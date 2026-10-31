# Island Time, Interrupted
Tourism Dependence, Economic Vulnerability, and the COVID Shock in Small Island Economies

[Our World in Data - Tourism contribution to GDP](https://ourworldindata.org/grapher/tourism-gdp-proportion-of-total-gdp)

[Our World in Data - Arrival of tourists from abroad](https://ourworldindata.org/grapher/international-tourist-trips)

[Our World in Data - Spending by international visitors](https://ourworldindata.org/grapher/spending-by-international-visitors-while-visiting-a-country-as-a-share-of-gdp)

# **Data Feasibility Audit and Preliminary EDA**

> Were Caribbean and Pacific island economies with greater pre-pandemic
> dependence on international tourism more vulnerable to the economic
> shock of COVID-19? Which economies had recovered to pre-pandemic levels
> of economic output by 2022–2023?

---

## Repository structure

```
_quarto.yml              Quarto website configuration
index.qmd                Feasibility audit document (renders to HTML)
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
└── tables/              CSV tables for Quarto inline use
README.md
LICENSE
```

---

## Reproducing the analysis

### Prerequisites

- **R ≥ 4.4.0**
- **Quarto ≥ 1.4**
- R packages: `tidyverse`, `wbstats`, `countrycode`, `janitor`, `scales`,
  `ggrepel`, `here`, `knitr`, `rmarkdown`, `svglite`

Install missing packages:

```r
install.packages(c(
  "tidyverse", "wbstats", "countrycode", "janitor", "scales",
  "ggrepel", "here", "knitr", "rmarkdown", "svglite"
))
```

### Run the analysis

Open an R session with the working directory set to `F1-tourism-covid/`
(or use RStudio with this folder as the project root — `here()` will
resolve paths automatically).

```r
source("R/01_data_acquisition.R")   # ~1-2 min (World Bank API call)
source("R/02_data_quality.R")
source("R/03_preliminary_eda.R")
```

### Render the Quarto document

```bash
quarto render index.qmd
```

Or from R:

```r
quarto::quarto_render("index.qmd")
```

The rendered HTML appears in `_site/index.html`.

> **Note:** Scripts must be run before rendering because the Quarto
> document reads pre-computed output files (`data/processed/`,
> `output/figures/`). The scripts do not re-run inside the document.

---

## Data sources

| Dataset | Source | Indicator |
|---------|--------|-----------|
| Tourism contribution to GDP | UNWTO / Our World in Data | SDG 8.9.1 (TSA methodology) |
| International visitor spending | World Bank WDI via OWID | ST.INT.XPND.GD.ZS |
| International tourist arrivals | UNWTO via OWID | Annual arrivals count |
| Tourism receipts (% exports) | World Bank WDI | ST.INT.RCPT.XP.ZS |
| GDP per capita | World Bank WDI | NY.GDP.PCAP.CD |
| GDP growth | World Bank WDI | NY.GDP.MKTP.KD.ZG |
| Unemployment | World Bank WDI | SL.UEM.TOTL.ZS |

Raw OWID CSV files are stored in `data/raw/` and are not modified.
WDI data is retrieved programmatically and saved to `data/raw/worldbank/`
with a retrieval-date metadata file.

---

## Key findings (Phase 1)

- **37 candidate economies** across the Caribbean and Pacific.
- **~25–30 economies** have at least one usable tourism-dependence indicator
  for 2017–2019.
- **~15–20 economies** are shock-eligible (tourism baseline + 2020 GDP growth).
- **Primary measure:** WDI tourism receipts (% of total exports) — best
  coverage, consistent methodology, directly measures economic exposure.
- **Major gap:** Pacific micro-states have sparser WDI coverage than
  Caribbean economies.
- **Recovery analysis** requires constant-price GDP; nominal GDP per capita
  is available but limited for real recovery comparison.

See `index.qmd` (rendered) for the full feasibility report and figures.

---

## License

Data from Our World in Data and the World Bank are used under their
respective open-data licenses. See source URLs in the data files.
