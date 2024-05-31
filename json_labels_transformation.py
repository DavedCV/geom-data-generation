import os
import sys
import json
import pandas as pd


def get_iso_code(country_code):
    df_index_filtered = df_index[df_index["c"] == country_code]
    if not df_index_filtered.empty:
        return df_index_filtered["iso"].values[0]
    return None


def map_numbers_to_labels(numbers, country_code, label):

    df_filtered_by_country_labels = df_labels[df_labels["isocode"]
                                              == country_code]
    filtered_by_colname = df_filtered_by_country_labels[df_filtered_by_country_labels["variable"] == label][[
        "value", "class"]]
    mapping = dict(
        zip(filtered_by_colname["value"], filtered_by_colname["class"]))

    transformed_val = []
    for val in numbers.split(","):
        try:
            if (val.isdigit()):
                if "Years Of Education" in mapping[int(val)]:
                    mapping_value = val + " " + mapping[int(val)]
                else:
                    mapping_value = mapping[int(val)]
            else:
                mapping_value = val

            if not isinstance(mapping_value, float):
                # transformed_val.append(mapping_value)
                transformed_val.append(mapping_value.replace("'", "\'"))
        except KeyError:
            continue

    return ",".join(transformed_val)


def traverse_tree(json_data, country_code):
    if isinstance(json_data, dict):
        for key, value in json_data.items():
            if key == "split_condition":
                try:
                    label, numbers = value.split(" -> ")
                    labels_values = map_numbers_to_labels(
                        numbers, country_code, label)
                    json_data[key] = f"{label} -> {labels_values}"
                except ValueError:
                    pass  # handle cases where split_condition is not in expected format
            traverse_tree(value, country_code)
    elif isinstance(json_data, list):
        for item in json_data:
            traverse_tree(item, country_code)


dir_path = sys.argv[1]
df_labels_path = sys.argv[2]
df_index_path = sys.argv[3]

df_labels = pd.read_excel(df_labels_path, dtype={
                          "class": str}, keep_default_na=False, na_values=['NaN'])
df_index = pd.read_excel(df_index_path)
df_index["c"] = df_index["c"].apply(lambda x: x.upper())

for file_name in os.listdir(dir_path):
    if file_name.endswith('.json'):
        country_code, _, _ = file_name.split("_")
        country_code = get_iso_code(country_code.upper())
        if country_code:
            file_path = os.path.join(dir_path, file_name)
            with open(file_path, 'r+') as f:
                try:
                    data = json.load(f)
                    traverse_tree(data, country_code)
                    f.seek(0)  # reset file pointer to the beginning of the file
                    f.truncate()  # clear the file content
                    json.dump(data, f, indent=4)
                except json.JSONDecodeError:
                    print(f"Error decoding JSON in file: {file_path}")
                except Exception as e:
                    print(f"Error processing file {file_path}: {e}")
