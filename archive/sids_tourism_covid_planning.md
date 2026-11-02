### Field Note F1: Tourism Dependence and the COVID Cliff

**Working Title:** *Tourism Dependence and the COVID Cliff: An EDA of Caribbean and Pacific Small Island Economies, 2008–2023*

**Research Question:**
- **Primary:** Which Caribbean and Pacific small island economies were most tourism-dependent in the years before COVID-19, and does pre-pandemic tourism dependence predict the size of the 2020 economic contraction?
- **Secondary:** Which tourism-dependent SIDS had recovered to near pre-pandemic economic output by 2022–2023?

---

**Significance**

Tourism is the economic backbone of many small island states — for places like Aruba, the British Virgin Islands, and Palau, tourism receipts account for 20–50% of total export earnings or more of measured GDP. The COVID-19 pandemic functioned as a sharp, involuntary stress test: international arrivals fell 74% globally in 2020, but the distributional consequences for heavily tourism-dependent economies were far more severe than for diversified ones. This question is analytically tractable, policy-relevant, and personally grounded: the USVI (where tourism accounts for roughly 20–30% of measured GDP per OWID data confirmed in this session) was among the most exposed small island economies globally, both to the 2020 pandemic shock and to the 2017 hurricane season.

Organizations that would value this research: small island development organizations, Caribbean regional bodies, IMF/World Bank small states desks, climate and development think tanks, international donors working on economic resilience.

---

**Geographic and Temporal Scope**

- **Unit of analysis:** Country-year (one row per country per year)
- **Countries:** ~30–40 SIDS with sufficient data coverage: Caribbean (USVI, BVI, Aruba, Barbados, Bahamas, Jamaica, St. Lucia, Grenada, Dominica, Antigua & Barbuda, Trinidad & Tobago, Cayman Islands, etc.) + Pacific (Fiji, Vanuatu, Samoa, Tonga, Palau, Maldives, Marshall Islands, Micronesia, Kiribati)
- **Years:** 2008–2023 (OWID tourism-GDP CSV range) with supplemental arrivals data back to 1995 from WDI
- **Temporal scope is manageable:** 15 years for the primary analysis, with a 2019-to-2020 shock window as the core analytical moment

---

**Verified Data Inventory**

| Dataset | Direct URL | Key Variables | Coverage | Access | Notes |
|---------|-----------|---------------|----------|--------|-------|
| OWID Tourism GDP % | `https://ourworldindata.org/grapher/tourism-gdp-proportion-of-total-gdp.csv` | Tourism % of GDP (SDG 8.9.1) | ~150 countries, 2008–2023 | Free, direct CSV | **Confirmed in session.** USVI, Fiji, Aruba, BVI visible. Maldives absent (no TSA). Many Pacific SIDS sparse. |
| OWID Tourist Arrivals | `https://ourworldindata.org/grapher/international-tourist-trips.csv` | Annual arrivals (count) | ~200 countries, 1995–2024 | Free, direct CSV | **Confirmed in session.** Source: UNWTO via OWID. |
| OWID Tourism Receipts | `https://ourworldindata.org/grapher/spending-by-international-visitors-while-visiting-a-country.csv` | Annual receipts (current USD) | ~200 countries, 1995–2024 | Free, direct CSV | **Confirmed in session.** |
| WDI Tourism Receipts % Exports | `https://api.worldbank.org/v2/en/indicator/ST.INT.RCPT.XP.ZS?downloadformat=csv` | Tourism receipts as % of total exports | 217 countries, ~1995–2022 | Free, direct ZIP | **Confirmed in session.** Better coverage for Maldives and Pacific micro-states than OWID tourism-GDP CSV. |
| WDI GDP per capita | Via `wbstats::wb_data("NY.GDP.PCAP.CD")` | GDP per capita, current USD | 217 countries, 1960– | R package or bulk ZIP | **Confirmed (wbstats CRAN page confirmed).** |

**Caveats:** OWID tourism-GDP CSV uses Tourism Satellite Account methodology; many SIDS lack TSA data and are absent. This is not fatal — the WDI `ST.INT.RCPT.XP.ZS` (tourism receipts as % of total exports) covers more SIDS and is a valid dependency proxy. Some 2020 GDP data may be preliminary or revised in later years.

---

**Proposed EDA**

**Language: R** (`wbstats`, `dplyr`, `ggplot2`, `tidyr`, `readr`, `countrycode`)

R is appropriate because the `wbstats` package enables direct programmatic access to WDI with no file management, and `ggplot2` is the clearest tool for the multi-panel small-multiple visualizations this project requires. The analysis is cross-sectional and longitudinal with a manageable number of countries.

**Steps:**
1. **Data acquisition (45 min):** Download OWID tourism-GDP CSV directly. Use `wbstats::wb_data()` to pull `ST.INT.RCPT.XP.ZS`, `NY.GDP.PCAP.CD`, `NY.GDP.MKTP.KD.ZG` (GDP growth), `SL.UEM.TOTL.ZS` (unemployment) for a custom SIDS country vector. Join on country code using `countrycode` package.
2. **Data quality check (30 min):** Count missing values per country per indicator. Identify which SIDS have sparse pre-2019 coverage. Define the analysis sample clearly — likely 25–35 countries with acceptable coverage.
3. **Dependency ranking (30 min):** Rank SIDS by 2019 (or 2017–2019 average) tourism receipts % of exports. Bar chart with country labels, highlighted by region (Caribbean vs. Pacific). A supplemental scatter of receipts-per-arrival vs. dependency explores the quality vs. quantity angle.
4. **COVID shock analysis (60 min):** Calculate the 2020 GDP growth rate for each SIDS. Scatter: 2019 tourism dependency vs. 2020 GDP growth. Fit a simple regression line with uncertainty band. Flag outliers (e.g., Maldives, which despite extreme tourism dependence has limited data). This is a descriptive correlation, not causal.
5. **Recovery tracking (45 min):** For the 15–20 SIDS with 2021–2023 data, compare GDP per capita or tourism receipts to 2019 baseline. Small-multiple line charts colored by recovery status (above/below pre-pandemic level by 2022).
6. **Interpretation (60 min):** Write narrative: which places recovered fastest and why (diversification, domestic tourism, geographic isolation), where data gaps prevent conclusions.

---

**Originality and Contribution**

Existing analyses found: The World Bank and IMF have published policy briefs on SIDS economic resilience and COVID (e.g., "COVID-19 and Small States," various 2021–2022 IMF Working Papers). The OWID "Tourism and Economic Development" page summarizes the macro picture. Several academic papers examine tourism-led growth in individual SIDS (Aruba: Croes & Vanegas 2003; Maldives: various).

**What this adds:** A focused cross-sectional EDA using freely reproducible code, visualizing the dependency-shock relationship across the SIDS universe simultaneously rather than in country case studies. The recovery angle (2021–2023) extends beyond most published analyses. The USVI inclusion as a non-sovereign U.S. territory adds an unusual comparative data point. The Field Note format — reproducible R Quarto document — is itself different from academic papers or institutional briefs.

**What it does not add:** Causal identification. This is an observational EDA. The correlation between tourism dependence and GDP shock may reflect other factors (domestic economic structure, policy response, fiscal buffers, hurricane exposure). These limitations must be explicit.

---

**Feasibility**

| Phase | Estimated Time |
|-------|---------------|
| Data download and initial inspection | 45 min |
| Cleaning and country-level joins | 60 min |
| Analysis and visualizations | 120 min |
| Interpretation and writing | 90 min |
| Quarto rendering and polish | 45 min |
| **Total** | **~6 hours** |

**Most likely obstacle:** SIDS data coverage gaps. The OWID tourism-GDP CSV has significant missingness for Pacific micro-states; the WDI receipts-as-%-exports series partially compensates. The fallback is to restrict the sample to countries with ≥10 years of data, accept a smaller N (20–25 countries), and be explicit about selection.

---

**Hiring Signal**

Demonstrates: R proficiency (`tidyverse`, `ggplot2`, `wbstats`); cross-sectional analysis with appropriate caveats; domain knowledge about small island economies, tourism dependence, and COVID-era development; data quality judgment; ability to communicate international economic data to non-specialist audiences.

Relevant roles: development data analyst (World Bank, IMF, UN agencies, Caribbean regional organizations, NGOs working on SIDS resilience), tourism analytics, economic consulting, policy research.

---

**Limitations**

- **Causation:** Cannot establish that tourism dependence *caused* deeper contractions. Confounders include fiscal space, healthcare capacity, and lockdown policies.
- **SIDS coverage:** Many Pacific micro-states have poor WDI/OWID coverage; sample is biased toward Caribbean islands and larger Pacific economies.
- **Tourism GDP methodology:** OWID uses Tourism Satellite Account data, which is absent for many SIDS. Substituting tourism receipts % of exports is a reasonable proxy but not identical.
- **Definitional changes:** WDI arrivals and receipts data sourced from UNWTO, which uses variable national definitions of "tourist" (some include same-day visitors).
- **USVI is a U.S. territory:** GDP data for USVI flows through BEA, not World Bank, and is only partially captured in WDI. It appears in OWID's tourism-GDP CSV but not all WDI series.

---


### F1: Tourism Dependence and the COVID Cliff

**1. First action:**
- Open `https://ourworldindata.org/grapher/tourism-gdp-proportion-of-total-gdp.csv` in a browser and download the CSV directly.
- Also download: `https://ourworldindata.org/grapher/international-tourist-trips.csv`
- Documentation: `https://ourworldindata.org/tourism` — review methodology notes, particularly the Tourism Satellite Account note explaining which countries are missing.

**2. First inspection:**
- Open the tourism-GDP CSV. Check: which SIDS are present? Look for USVI, Fiji, Aruba, BVI, Maldives, Palau, Tonga, Samoa.
- Count rows per country. Identify which SIDS have data for 2019 AND 2020 (the critical shock years). Any country missing either year is likely excluded from the main analysis.
- For countries absent from OWID tourism-GDP CSV, check if `ST.INT.RCPT.XP.ZS` from WDI covers them: `wbstats::wb_data("ST.INT.RCPT.XP.ZS", country="all", start_date=2019, end_date=2020)`.

**3. Initial EDA checks:**
1. `summary(df)` — distributions, range of tourism % values, number of NAs per year
2. Bar chart: top 20 countries by 2019 tourism % of GDP — does it look like the expected SIDS-dominated ranking?
3. Quick scatter: 2019 tourism % GDP vs. 2020 GDP growth rate (from WDI) for the available sample
4. Count: how many SIDS have ≥5 years of non-NA data in the 2015–2022 window?
5. Line chart: USVI, Fiji, Aruba, BVI trajectories over 2008–2023 — any interesting pre-COVID trends?

**4. Technical setup:**
```r
install.packages(c("wbstats", "tidyverse", "countrycode", "ggrepel"))
library(wbstats); library(tidyverse); library(countrycode); library(readr)

# Download OWID CSV
tourism_gdp <- read_csv("https://ourworldindata.org/grapher/tourism-gdp-proportion-of-total-gdp.csv")

# Define SIDS country codes (ISO2)
sids <- c("AW","BB","BS","DM","GD","HT","JM","KN","LC","TT","VC","VG","VI",
          "FJ","FM","KI","MH","MV","NR","PF","PG","PW","SB","TO","TV","VU","WS")

# Pull WDI supplement
wdi <- wb_data(c("ST.INT.RCPT.XP.ZS","NY.GDP.MKTP.KD.ZG","NY.GDP.PCAP.CD"),
               country=sids, start_date=2000, end_date=2023)
```

**5. Feasibility test (go/no-go):**
- **GO** if: ≥20 SIDS have both 2019 and 2020 data for at least one of (tourism % GDP, tourism receipts % exports, arrivals) AND at least one of (GDP growth, GDP per capita).
- **NO-GO** (narrow scope) if: Fewer than 15 usable country-year pairs. In that case, expand to all high-income small island economies (not just SIDS designation) or broaden to LMICs with >10% tourism-receipts-to-exports.

**6. Time budget:**
- Initial feasibility test: 30–45 minutes
- Complete Field Note: 5–7 hours

**7. Minimum viable deliverable:**
A Quarto HTML document containing: (a) a data table showing 2019 tourism dependency ranking for ≥20 SIDS; (b) a scatter plot of 2019 tourism dependency vs. 2020 GDP growth with labeled country points and a trend line; (c) a multi-line recovery chart for the 8–10 best-covered destinations, 2019–2023; (d) a 300–400 word interpretation section; (e) explicit data limitations and download links.

**8. Principal failure mode:**
Too few SIDS have both pre-pandemic tourism data AND reliable 2020 GDP data to make the scatter plot analytically meaningful. The simplest fallback: change the primary visualization to a "profiles gallery" (bar chart of 2019 dependency + change bar for 2020) rather than a scatter regression, which requires fewer matched observations.

---

### WHO GHO API (Supplemental)

Confirmed working, no registration, OData query syntax:
- Base: `https://ghoapi.azureedge.net/api/`
- No R package required — use `jsonlite::fromJSON()` directly
- Covers SIDS countries; relevant supplemental data for F1 or F4 if health/mortality context is needed

---
