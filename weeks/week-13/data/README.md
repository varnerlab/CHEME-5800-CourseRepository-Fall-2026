# Week 13 data and provenance

## National Weather Service fixtures

The two `nws-*.fixture.json` files are compact teaching fixtures authored for
deterministic tests. They preserve only the response fields used by the client;
they are not archived observations and must not be interpreted as historical
weather records.

Their shape follows the National Weather Service API points-to-forecast workflow:

1. request `/points/{latitude},{longitude}`;
2. read `properties.forecastHourly`; and
3. request the linked hourly forecast document.

The optional live client must send an identifiable `User-Agent`. No secret or API
key is used.

## FRED fixtures

The three `fred-series*.fixture.json` files are compact teaching fixtures authored for
deterministic tests of the L13b lab code. They are not recorded responses. Their keys
follow the JSON examples in the FRED API documentation for the `fred/series/search`,
`fred/series`, and `fred/series/observations` endpoints.

The six observations are the Henry Hub natural gas spot price (series `DHHNGSP`) for
January 1 to January 8, 2025, taken from the public FRED graph download
(`https://fred.stlouisfed.org/graph/fredgraph.csv?id=DHHNGSP`) on November 12, 2026.
January 1 has no value, which FRED sends as a period.

`fred-error.fixture.json` is the body of a real FRED response, recorded on November 12,
2026. FRED returned it with the status code `400` for a request that used the example key
of the FRED documentation, which is not a registered key.

The fixtures hold no API key. The lab reads each student's key from
`L13b/conf/Configuration.toml`, which git does not track.

## Urea-cycle network

`urea-cycle-network.json` was derived from:

```text
CHEME-5800-Fall-2025/
  CHEME-5800-Labs-Fall-2025/labs/week-6/L6b/data/Network.net
```

The JSON preserves the 18-species, 19-reaction stoichiometric model and adds two
small cross-language test vectors. The `balanced` vector satisfies `S*v = 0`; the
`imbalanced` vector omits urea export and leaves a residual of `1.0` for
`M_Urea_c`.

The committed fixture is the canonical Week 13 resource. The original VFF file
remains the historical source.
