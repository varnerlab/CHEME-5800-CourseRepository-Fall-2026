# S&P 500 daily volume-weighted average prices

`SP500-Daily-VWAP-1-3-2014-to-12-31-2024.csv` holds the market data used by the
[L10b weighted majority lab](../CHEME-5800-L10b-Lab-WeightedMajorityAlgorithm-Fall-2026.ipynb).
Each row is one trading day, from January 3, 2014, to December 31, 2024 (2,767 days).
The first column, `date`, holds the trading day; each of the other 424 columns holds the
daily volume-weighted average price (units: USD/share) of one ticker, sorted
alphabetically by ticker symbol.

Source: the course package's `MyTrainingMarketDataSet()` file,
`SP500-Daily-OHLC-1-3-2014-to-12-31-2024.jld2` (SHA-256
`36b7ebe2c13be3ecebe829b159b6f3b2abbab0fd35b92fbb4eb11e1ea08d681d`), which holds daily
open-high-low-close records from [Polygon.io](https://polygon.io/) for the firms in the
S&P 500 and a few exchange-traded funds. That file is 88 MB and is not part of this
repository, so this cache keeps only what the lab uses:

- the 424 tickers with a record for every one of the 2,767 trading days (the Fall 2025
  lab dropped the others in the notebook; tickers acquired or delisted during the period
  have fewer records);
- the `volume_weighted_average_price` column, which the course package's
  `log_growth_matrix(...)` function reads;
- the date of each record, taken from its `timestamp` (all 424 tickers share the same
  2,767 dates).

The prices have at most four decimal places and are written in full, so reading the CSV
returns exactly the values in the source file. The cache was made on October 10, 2026.

SHA-256: `6fc16374b3fc06dc1b9318a9fcb1056944fbe939f7a4674f1ed70e05a10c25ae`
