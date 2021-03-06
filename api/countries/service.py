import pandas as pd
import matplotlib as mpl
import io
from countries.worldbank_api import update_co2_data, update_population_data
from flask import send_file, abort
mpl.use('TkAgg')
import matplotlib.pyplot as plt  # NOQA

co2_df = pd.read_csv("data/emissions.csv", header=0,
                     error_bad_lines=False, sep=";")

population_df = pd.read_csv('data/population.csv',
                            header=0, error_bad_lines=False, sep=";")


co2_countrynames_lowercase = co2_df['Country Name'].apply(
    lambda x: x.lower())
co2_df.insert(loc=0, column='Country Name Lowercase',
              value=co2_countrynames_lowercase)

population_countrynames_lowercase = population_df['Country Name'].apply(
    lambda x: x.lower())
population_df.insert(loc=0, column='Country Name Lowercase',
                     value=population_countrynames_lowercase)


co2_df = update_co2_data(co2_df).fillna(value=0)
population_df = update_population_data(population_df).fillna(value=0)


def get_country_names():
    names = co2_df['Country Name'].squeeze().tolist()
    return names


def get_country_data(country):
    formatted_country = country.lower()
    if (co2_df['Country Name Lowercase'] == formatted_country).any():
        select_country = co2_df[co2_df['Country Name Lowercase']
                                == formatted_country]
        year_columns = select_country.iloc[:, 5:]
        co2_dict = year_columns.apply(lambda x: float(x)).squeeze().to_dict()
    else:
        return abort(404)
    if (population_df['Country Name Lowercase'] == formatted_country).any():
        select_country = population_df[population_df['Country Name Lowercase']
                                       == formatted_country]
        year_columns = select_country.iloc[:, 5:]
        population_dict = year_columns.apply(
            lambda x: int(x)).squeeze().to_dict()

    combined_data = []
    for k, v in co2_dict.items():
        per_capita = metric_tons_per_capita(v, population_dict[k])

        dict_item = {'year': int(k), 'co2_kilotons': v,
                     'population': population_dict[k],
                     'co2_per_capita': per_capita}
        combined_data.append(dict_item)
    return combined_data


def metric_tons_per_capita(co2, population):
    if population == 0:
        return 0
    else:
        return co2 / population * 1000


def get_country_plot(country, percapita=False):
    data = get_country_data(country)
    years = [i['year'] for i in data]
    if percapita:
        dataset = [i['metric_tons_per_capita'] for i in data]
    else:
        dataset = [i['co2_kilotons'] for i in data]
    plt.figure(figsize=(6, 12))
    plt.barh(range(len(dataset)), dataset, align='center', color='black')
    plt.yticks(range(len(years)), years)
    buf = io.BytesIO()
    plt.savefig(buf, format='png', bbox_inches='tight')
    buf.seek(0)
    file = send_file(buf, mimetype='image/png')
    return file
