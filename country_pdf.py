import sys
import os
import json
import pandas as pd


def get_iso_code(country_code):
    df_index_filtered = df_index[df_index["c"] == country_code]
    return df_index_filtered["iso"].values[0]


def get_name(country_code):
    df_index_filtered = df_index[df_index["c"] == country_code]
    return df_index_filtered["name"].values[0]


dir_path = sys.argv[1]
des_dir_path = sys.argv[2]
df_index_path = sys.argv[3]
type = sys.argv[4]

df_index = pd.read_excel(df_index_path)
df_index["c"] = df_index["c"].apply(lambda x: x.upper())
data = {}

for file_name in os.listdir(dir_path):
    country_code, year, _ = file_name.split("_")
    country_code = country_code.upper()
    year = int(year)
    print(country_code, year)

    if country_code not in data:
        data[country_code] = {}
        data[country_code]["name"] = get_name(country_code)
        data[country_code]["iso"] = get_iso_code(country_code)
        data[country_code]["years"] = [year]
    else:
        data[country_code]["years"].append(year)
        data[country_code]["years"] = sorted(data[country_code]["years"])

data = dict(sorted(data.items()))
with open(os.path.join(des_dir_path, f"country_pdf_{type}.json"), "w") as f:
    json.dump(data, f, indent=4)
