# Housing price dataset

`Housing-Training-Dataset-Kaggle.csv` holds the price and twelve features for 545
houses. It is read by the
[L8c ridge regression housing example](../CHEME-5800-L8c-Example-RLS-SVD-HousingPriceModel-Fall-2026.ipynb).

Source: the [Housing Prices Dataset on Kaggle](https://www.kaggle.com/datasets/yasserh/housing-prices-dataset?select=Housing.csv).
This copy is the file distributed with the Fall 2025
[VLDataScienceMachineLearningPackage.jl](https://github.com/varnerlab/VLDataScienceMachineLearningPackage.jl)
package (`src/data/Housing-Training-Dataset-Kaggle.csv`), copied unchanged on
October 6, 2026. The original download date is not recorded.

SHA-256: `fe173cc470ed37c796f83f5f737ac47fa4a97869e97574db38a05eed8df1997a`

Columns: `price`, `area`, `bedrooms`, `bathrooms`, `stories`, `mainroad`,
`guestroom`, `basement`, `hotwaterheating`, `airconditioning`, `parking`,
`prefarea`, and `furnishingstatus`. The example notebook encodes the categorical
columns as numbers and rescales the price and the area.
