# Run Scripts

``` bash
chmod +x run_scripts.sh
./run_script-sh arg1 arg2 arg3 arg4 arg5
```

Provide the correct args with the following mapping:

-   **arg1:** absolute path to the directory of all RData tree objects
-   **arg2:** absolute path to the directory of all result data csv files
-   **arg3:** absolute path to the final target directory for the generated csv files
-   **arg4:** absolute path to the xlsx labels file
-   **arg5:** absolute path to the xlsx index file

## Output File

The output file has the following name convention:

``` bash
countrycode_year_type.csv
```

# CSV generator

## Run the script

``` bash
Rscript csv_generator.R arg1 arg2 arg3
```

Provide the correct args with the following mapping:

-   **arg1:** absolute path to the directory of all RData tree objects
-   **arg2:** absolute path to the directory of all result data csv files
-   **arg3:** absolute path to the final target directory for the generated csv files

# CSV labels transformation

## Run the script

``` bash
python csv_labels_transformation.py arg1 arg2 arg3
```

Provide the correct args with the following mapping:

-   **arg1:** absolute path to the directory of the R generated csv files
-   **arg2:** absolute path to the xlsx labels file
-   **arg3:** absolute path to the xlsx index file

# JSON labels transformation

## Run the script

``` bash
python json_labels_transformation.py arg1 arg2 arg3
```

Provide the correct args with the following mapping:

-   **arg1:** absolute path to the directory of the R generated json files
-   **arg2:** absolute path to the xlsx labels file
-   **arg3:** absolute path to the xlsx index file
