import sys
import os
import pandas as pd


def map_numbers_to_labels(data, col_name, df_filtered_by_country_labels):
    if pd.isnull(data):
        return data
    if isinstance(data, float):
        data = str(int(data))
    if isinstance(data, int):
        data = str(data)

    filtered_by_colname = df_filtered_by_country_labels[df_filtered_by_country_labels["variable"] == col_name][[
        "value", "class"]]
    mapping = dict(
        zip(filtered_by_colname["value"], filtered_by_colname["class"]))

    # print(
    #    df_filtered_by_country_labels[df_filtered_by_country_labels["variable"] == col_name])

    transformed_val = []

    for val in data.split(","):
        try:
            if (val.isdigit()):
                if "Years Of Education" in mapping[int(val)]:
                    mapping_value = val + " " + mapping[int(val)]
                else:
                    mapping_value = mapping[int(val)]
            else:
                mapping_value = val

            if not isinstance(mapping_value, float):
                transformed_val.append(mapping_value)
        except KeyError:
            continue

    return ",".join(transformed_val)


def get_iso_code(country_code):
    df_index_filtered = df_index[df_index["c"] == country_code]
    return df_index_filtered["iso"].values[0]


# Path to the directory containing all CSV files
dir_path = sys.argv[1]
df_labels_path = sys.argv[2]
df_index_path = sys.argv[3]

# Read the labels DataFrame
df_labels = pd.read_excel(df_labels_path, dtype={
                          "class": str}, keep_default_na=False, na_values=['NaN'])
df_index = pd.read_excel(df_index_path)
df_index["c"] = df_index["c"].apply(lambda x: x.upper())

# Process each CSV file in the directory
for file_name in os.listdir(dir_path):

    print(file_name)

    if file_name.endswith(".csv"):
        df_path = os.path.join(dir_path, file_name)

        # Read the CSV file
        df = pd.read_csv(df_path)

        # Extract country code from the file name (assuming the same naming convention)
        country_code = file_name.split(".")[0].split("_")[0].upper()
        country_code = get_iso_code(country_code)

        # Filter the labels DataFrame by the country code
        df_filtered_by_country_labels = df_labels[df_labels["isocode"]
                                                  == country_code]

        # Get the unique target columns
        target_columns = list(
            df_filtered_by_country_labels["variable"].unique())

        # Apply the mapping function to each target column
        for column in target_columns:
            df[column] = df[column].apply(map_numbers_to_labels, args=(
                column, df_filtered_by_country_labels))

        # Save the transformed DataFrame back to CSV
        df.to_csv(df_path, index=False)
