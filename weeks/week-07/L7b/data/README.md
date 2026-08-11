# Reduced S&P 500 return matrix

`SP500-Reduced-LogReturns-2024.csv` contains 181 daily close-to-close log returns
for AAPL, AMD, JPM, LLY, MSFT, and XOM from 2024-01-04 through 2024-09-24.
It was deterministically derived from the historical course file
`SP500-Daily-OHLC-1-3-2024-to-09-24-2024.jld2` in the CHEME 5660 Fall 2024
repository. No hidden package or live download is required.

- Original file SHA-256: `0e37521ea5572121fa2e43aa586b4651d4fa6e7ea7d51e05a95e9f979229d6e4`
- Reduced CSV SHA-256: `77b184906dac44b44b1ccf02d9be9f0548a622203851d5c078792392d00fd6b6`
- Transformation: for each ticker, `log(close[t] / close[t-1])`

The upstream market-data provider is not recorded in the historical artifact; this
is an explicit provenance-cleanup item before a public final release.
