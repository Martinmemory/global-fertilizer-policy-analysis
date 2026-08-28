# Data

## Dataset

**Nitrogen fertilizer use per hectare of cropland**, 1961–2023.

The indicator is kilograms of nutrient nitrogen from inorganic fertilizer per hectare of cropland (arable land plus permanent crops). It measures application intensity, not nitrogen surplus, water quality, or manure.

## Official sources

- **FAOSTAT**, domain *Fertilizers by Nutrient* (RFN). Method note: [FAOSTAT RFN README (July 2025)](https://files-faostat.fao.org/production/RFN/RFN_EN_README.pdf)
- **Our World in Data** chart: [Nitrogen fertilizer application per hectare of cropland](https://ourworldindata.org/grapher/nitrogen-fertilizer-application-per-hectare-of-cropland)

OWID citation recorded in `source/nitrogen_fertilizer_use_per_hectare_metadata.json` (downloaded 2026-08-08):

> Food and Agriculture Organization of the United Nations (2025) — with major processing by Our World in Data.

## Files in this repository

| File | Role |
|------|------|
| `source/nitrogen_fertilizer_use_per_hectare_1961_2023.csv` | Full OWID download used for the World series and regional aggregates (12,568 rows; 242 entities including aggregates) |
| `source/ten_country_displayed_1961_2023.csv` | OWID “Download displayed data” extract for ten countries |
| `source/nitrogen_fertilizer_use_per_hectare_metadata.json` | OWID metadata for the indicator |
| `source/FAOSTAT_Fertilizers_by_Nutrient_README.pdf` | FAO method note |
| `processed/world_series_1961_2023.csv` | World series, 63 annual observations, 1961–2023 |
| `processed/ten_country_series_1961_2023.csv` | 10 countries × 63 years = 630 observations |
| `processed/nitrogen_panel_clean.csv` | Cleaned full panel |
| `processed/regional_series_1961_2023.csv` | Six FAO regional aggregates |

The source CSVs are small (well under 25 MB) and are included so the analysis can be rerun without a new download.

## Years and variables

- **Years:** 1961–2023
- **World sample:** 63 observations
- **Ten-country sample:** Australia, Brazil, China, France, India, Japan, Nigeria, Pakistan, South Korea, United States
- **Variables:** entity/country, optional ISO-like code, year, nitrogen use in kg N/ha

## Cleaning steps

Implemented in `R/01_data_cleaning.R`:

1. Read the OWID full CSV and rename columns.
2. Check row count (12,568), entity count (242), year range, non-missing values, and non-negative rates.
3. Extract the World series and set `t = year - 1961`.
4. Extract six FAO regional aggregates.
5. Validate the ten-country displayed-data file (630 complete country-years).

## Where to put a new download

Replace the files in `data/source/` with a fresh OWID full download and, if needed, a new ten-country displayed-data CSV using the same column names. Then rerun `R/01_data_cleaning.R`.

## License and citation

FAOSTAT data are subject to [FAO terms of use](https://www.fao.org/contact-us/terms/en/). Our World in Data content is typically offered under [CC BY](https://ourworldindata.org/faqs#how-is-our-work-copyrighted). Cite both FAO and OWID as in the paper’s reference list.
