import pandas as pd
import io
import matplotlib as mpl
mpl.use('TkAgg')
import matplotlib.pyplot as plt  # NOQA

co2_df = pd.read_csv("./data/emissions.csv", header=0,
                     error_bad_lines=False, sep=";")

population_df = pd.read_csv('./data/population.csv',
                            header=0, error_bad_lines=False, sep=";")

# co2_df.fillna(value=0, inplace=True)
# population_df.fillna(value=0, inplace=True)


def country_data(country):
    formatted_country = country.title()
    co2_dict = {}
    population_dict = {}

    if (co2_df['Country Name'] == formatted_country).any():
        select_country = co2_df[co2_df['Country Name'] == formatted_country]
        year_columns = select_country.iloc[:, 4:]
        co2_dict = year_columns.apply(lambda x: float(x)).squeeze().to_dict()
    if (population_df['Country Name'] == formatted_country).any():
        select_country = population_df[population_df['Country Name']
                                       == formatted_country]
        year_columns = select_country.iloc[:, 4:]
        population_dict = year_columns.apply(
            lambda x: int(x)).squeeze().to_dict()

    if len(co2_dict) == 0:
        return
    combined_data = []
    for k, v in co2_dict.items():
        metric_tons_per_capita = v / population_dict[k] * 1000
        dict_item = {'year': k, 'co2_kilotons': v,
                     'population': population_dict[k],
                     'metric_tons_per_capita': metric_tons_per_capita}
        combined_data.append(dict_item)
    return combined_data


def country_plot(country, percapita=True):
    data = country_data(country)
    years = [i['year'] for i in data]
    if percapita:
        percapita_list = [i['metric_tons_per_capita'] for i in data]
        print(percapita_list)
        plt.barh(range(len(percapita_list)), percapita_list, align='center')
        plt.yticks(range(len(years)), years)
        plt.show()
    else:
        percapita_list = [i['co2_kilotons'] for i in data]
        plt.figure(figsize=(8, 14))
        plt.barh(range(len(percapita_list)),
                 percapita_list, align='center', color='black')
        plt.yticks(range(len(years)), years)
        buf = io.BytesIO()
        plt.savefig(buf, format='png')
        return buf


def get_country_names():
    names = co2_df['Country Name'].squeeze().tolist()
    return names


# country_data_dict = country_data('sweden')

# print(country_data_dict)

# country_dict = all_years_dict('United')
# plt.barh(range(len(country_dict)), list(country_dict.values()), align='center') asdasdadsd
# plt.yticks(range(len(country_dict)), list(country_dict.keys()))

# plt.show()
