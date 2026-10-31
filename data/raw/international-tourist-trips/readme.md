# Arrivals of tourists from abroad - Data package

This data package contains the data that powers the chart ["Arrivals of tourists from abroad"](https://ourworldindata.org/grapher/international-tourist-trips?v=1&csvType=full&useColumnShortNames=false) on the Our World in Data website.

### Active Filters

A filtered subset of the full data was downloaded. The following filters were applied:

## CSV structure

Each row is an observation for an entity (usually a country or region) at a timepoint.

- "Entity" — the name of the entity, e.g. "United States".
- "Code" — our internal entity code. For most countries this is the [ISO alpha-3](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3) code, e.g. "USA"; historical and other non-standard entities get a custom code.
- "Year" or "Day" — the timepoint. Annual data has a "Year" column holding an integer year; otherwise a "Day" column holds a date string in the form "YYYY-MM-DD".
- Every remaining column is a data column, each one a time series. Downloaded with the "full data" option each corresponds to one time series below; with "only selected data visible in the chart" they are transformed depending on the chart type, so the correspondence may be less direct.


## Metadata.json structure

The .metadata.json file contains metadata about the data package. The "charts" key contains information to recreate the chart, like the title, subtitle etc. The "columns" key contains information about each of the columns in the csv, like the unit, timespan covered, citation for the data etc.

## How we process data at Our World in Data

Our World in Data is almost never the original producer of the data - almost all of the data we use has been compiled by others. If you want to re-use data, it is your responsibility to ensure that you adhere to the sources' license and to credit them correctly. Please note that a single time series may have more than one source - e.g. when we stitch together data from different time periods by different producers or when we calculate per capita metrics using population data from a second source.

Preparing this data involves several processing steps. Depending on the data, this can include standardizing country names and world region definitions, converting units, calculating derived indicators such as per capita measures, as well as adding or adapting metadata such as the name or the description given to an indicator.
[Read about our data pipeline](https://docs.owid.io/projects/etl/).

## Detailed information about each time series


### Arrivals of tourists from abroad
Number of trips by visitors who arrive from abroad and stay overnight.
Last updated: January 21, 2026  
Next expected update: January 2027  
Date range: 1995–2024  
Unit: arrivals  
Source: UN Tourism (2025) – processed by Our World in Data  

#### How to cite this data

UN Tourism (2025) – processed by Our World in Data

#### What you should know about this data
- Each trip by the same person is counted separately.
- When an individual visits a country multiple times within a year, each visit is counted as a separate arrival.
- Similarly, if a person travels to multiple countries during a single trip, their arrival in each country is recorded individually.
- As a result, the number of arrivals does not necessarily reflect the number of individuals traveling, as one person can generate multiple arrivals.
- Before 2006, the US counted same-day trips from Canada only. After 2006, day trips from Mexico were also included.


### World region according to OWID
Regions defined by Our World in Data, which are used in OWID charts and maps.
Last updated: January 1, 2023  
Date range: 2023–2023  
Source: Our World in Data  

#### How to cite this data

Our World in Data


## Sources

These are the sources behind the data in this package. Each time series above names the ones it draws on in its citation.

### UN Tourism – UN Tourism Statistics Database

UN World Tourism Organization collects data from countries through annual questionnaires that follow the International Recommendations for Tourism Statistics (IRTS 2008) standard, a framework approved by the United Nations. The data covers various aspects of tourism, such as inbound tourism (including arrivals by region, main purpose, and mode of transport, as well as accommodation and tourism expenditure in the country), domestic tourism (including trips and accommodation), outbound tourism (including departures and tourism expenditure in other countries), tourism industries (such as accommodation in hotels and similar establishments), and employment (including the number of employees in tourism industries).

Producer: UN Tourism  
Published: 2025-12-29  
Retrieved on: 2026-01-21  
Retrieved from: https://www.untourism.int/tourism-statistics/tourism-statistics-database  
Direct download: https://pre-webunwto.s3.amazonaws.com/s3fs-public/2025-12/UN_Tourism_bulk_data_download_12_2025.zip  
License: © UNWTO, 92844/14/23 (https://www.unwto.org/copyright)  

Citation: "World Tourism Organization (2025). UN Tourism Statistics Database, Madrid. Data updated on 23 December 2025. More information: https://www.untourism.int/tourism-statistics/tourism-statistics-database"

### Our World in Data – Regions

Producer: Our World in Data  

    