import pandas as pd
import matplotlib as mpl
mpl.use('TkAgg')
import matplotlib.pyplot as plt

df_co2 = pd.read_csv("./data/emissions.csv", header=0,
                     error_bad_lines=False, sep=";")

df_population = pd.read_csv('./data/population.csv',
                            header=0, error_bad_lines=False, sep=";")


def co2_dict(country):
    formatted_country = country.title()
    if (df_co2['Country Name'] == formatted_country).any():
        select_country = df_co2[df_co2['Country Name'] == formatted_country]
        int_rows = select_country.iloc[:, 4:]
        year_dict = int_rows.apply(lambda x: float(x)).squeeze().to_dict()
        return year_dict
    elif (df_co2['Country Code'] == country.upper()).any():
        select_country = df_co2[df_co2['Country Code'] == country.upper()]
        int_rows = select_country.iloc[:, 4:]
        year_dict = int_rows.apply(lambda x: float(x)).squeeze().to_dict()
        return year_dict
    else:
        return


def population_dict(country):
    formatted_country = country.title()
    if (df_population['Country Name'] == formatted_country).any():
        select_country = df_population[df_population['Country Name']
                                       == formatted_country]
        int_rows = select_country.iloc[:, 4:]
        year_dict = int_rows.apply(lambda x: int(x)).squeeze().to_dict()
        return year_dict
    elif (df_population['Country Code'] == country.upper()).any():
        select_country = df_population[df_population['Country Code']
                                       == country.upper()]
        int_rows = select_country.iloc[:, 4:]
        year_dict = int_rows.apply(lambda x: int(x)).squeeze().to_dict()
        return year_dict
    else:
        return


def co2_per_capita(country):
    co2 = co2_dict(country)
    population = population_dict(country)
    per_capita = {}
    for i in co2.values():
        print(i)


co2_per_capita('sweden')


# print(co2_dict('fin'))

# country_dict = all_years_dict('United')
# plt.barh(range(len(country_dict)), list(country_dict.values()), align='center')
# plt.yticks(range(len(country_dict)), list(country_dict.keys()))

# plt.show()
