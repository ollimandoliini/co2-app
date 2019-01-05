import pandas as pd

df_emissions = pd.read_csv('./data/emissions.csv',
                           header=0, error_bad_lines=False, sep=";")
df_population = pd.read_csv('./data/population.csv',
                            header=0, error_bad_lines=False, sep=";")
# df_emissions.columns = df_emissions.columns.str.lower()
# df_population.columns = df_population.columns.str.lower()


def population(country, year):
    row = df_population[df_population['Country Name'] == country]
    return float(row[str(year)].values[0])


def emissions(country, year):
    row = df_emissions[df_emissions['Country Name'] == country]
    return float(row[str(year)].values[0])


def emissions_per_capita(country, year):
    per_capita = emissions(country, year) / population(country, year)
    return per_capita
