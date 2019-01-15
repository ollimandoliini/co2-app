import pandas as pd
import matplotlib as mpl
import io
from flask import send_file, abort
mpl.use('TkAgg')
import matplotlib.pyplot as plt  # NOQA


co2_df = pd.read_csv('./data/emissions.csv', header=0,
                     error_bad_lines=False, sep=";")
population_df = pd.read_csv('./data/population.csv',
                            header=0, error_bad_lines=False, sep=";")

co2_df.fillna(value=0, inplace=True)
population_df.fillna(value=0, inplace=True)


def get_country_data(country):

    formatted_country = country.title()
    if (co2_df['Country Name'] == formatted_country).any():
        select_country = co2_df[co2_df['Country Name'] == formatted_country]
        year_columns = select_country.iloc[:, 4:]
        co2_dict = year_columns.apply(lambda x: float(x)).squeeze().to_dict()
    else:
        return abort(404)
    if (population_df['Country Name'] == formatted_country).any():
        select_country = population_df[population_df['Country Name']
                                       == formatted_country]
        year_columns = select_country.iloc[:, 4:]
        population_dict = year_columns.apply(
            lambda x: int(x)).squeeze().to_dict()

    combined_data = []
    for k, v in co2_dict.items():
        metric_tons_per_capita = v / population_dict[k] * 1000
        dict_item = {'year': int(k), 'co2_kilotons': v,
                     'population': population_dict[k],
                     'co2_per_capita': metric_tons_per_capita}
        combined_data.append(dict_item)
    return combined_data


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
