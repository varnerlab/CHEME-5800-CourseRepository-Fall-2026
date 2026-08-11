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
