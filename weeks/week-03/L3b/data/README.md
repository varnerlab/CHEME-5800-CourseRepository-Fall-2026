# L3b data record

`fulfillment-shifts.csv` contains eight instructor-generated synthetic picking shifts
from a regional fulfillment center: four in the `East` zone and four in the `West`
zone. The columns are the same ones built by hand in the Week 2 collections lecture,
now arriving as an external file. `fulfillment-metadata.json` records their origin,
intended use, units, schema, allowed zones, and constraints. The values are plausible
only for classroom exercises and must not be represented as operational results.

`fulfillment-shifts-invalid-example.csv` intentionally violates six parts of the
contract at once: a duplicated `shift_id`, a blank zone, an unsupported zone, a
negative order count, a zero `labor_hours`, and a `picking_error_fraction` above one.
Its filename and location identify it as a known-bad data example used to demonstrate
validation failures.

## Authored-file checksums

```text
8674d24b30b5a3bf9dca5be28fcb8242fe8591ccb3118b9f048a51c1c85005ae  fulfillment-shifts.csv
a7c5d2658e3022998aaa26d35dc53c5cfdaceef8c3e7dd04f7ecf67f53d598d9  fulfillment-metadata.json
62cae00c8122d03421105aa6103b48358ffafa1740c6fd18b7fa950db9aafda9  fulfillment-shifts-invalid-example.csv
```

From this directory, verify the files with:

```bash
shasum -a 256 fulfillment-shifts.csv fulfillment-metadata.json fulfillment-shifts-invalid-example.csv
```
