import sys
import os
import json

import pandas as pd


def get_iso_code(country_code):
    df_index_filtered = df_index[df_index["c"] == country_code]
    return df_index_filtered["iso"].values[0]


def get_code(country_name):
    df_index_filtered = df_index[df_index["name"] == country_name]
    return df_index_filtered["c"].values[0]


dir_path = sys.argv[1]
des_dir_path = sys.argv[2]
df_index_path = sys.argv[3]

df_index = pd.read_excel(df_index_path)
df_index["name"] = df_index["name"].apply(lambda x: x.strip())
df_index["c"] = df_index["c"].apply(lambda x: x.upper())
data = {}

for file_name in os.listdir(dir_path):

    if "-" in file_name:
        file_name = file_name.replace("-", "_")
    if "Descriptives" in file_name:
        file_name = file_name.replace("Descriptives_", "")
    if "Template" in file_name:
        file_name = file_name.replace("Template_", "")

    print(file_name)

    if len(file_name.split("_")) == 3:
        country_name = file_name.split("_")[0] + " " + file_name.split("_")[1]
        year = int(file_name.split("_")[2].replace(".pdf", ""))
    else:
        country_name = file_name.split("_")[0]
        year = int(file_name.split("_")[1].replace(".pdf", ""))

    country_name = "Czech Rep." if country_name == "Czech Republic" else "United States of America" if country_name == "United States" else country_name

    country_code = get_code(country_name)

    if country_code not in data:
        data[country_code] = {}
        data[country_code]["name"] = country_name
        data[country_code]["iso"] = get_iso_code(country_code)
        data[country_code]["years"] = [year]
    else:
        data[country_code]["years"].append(year)
        data[country_code]["years"] = sorted(data[country_code]["years"])


data = dict(sorted(data.items()))
with open(os.path.join(des_dir_path, f"descriptives.json"), "w") as f:
    json.dump(data, f, indent=4)
