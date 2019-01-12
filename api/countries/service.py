import pandas as pd

co2_df = pd.read_csv('./data/emissions.csv',
                     header=0, error_bad_lines=False, sep=";")
population_df = pd.read_csv('./data/population.csv',
                            header=0, error_bad_lines=False, sep=";")


# df_emissions.columns = df_emissions.columns.str.lower()
# population_df.columns = population_df.columns.str.lower()


def population(country, year):
    row = population_df[population_df['Country Name'] == country]
    return float(row[str(year)].values[0])


# def emissions(country, year=''):
#     if year:
#         row = df_emissions[df_emissions['Country Name'] == country]
#         return float(row[str(year)].values[0])


# def emissions_per_capita(country, year):
#     per_capita = emissions(country, year) / population(country, year)
#     return per_capita


def co2_dict(country):
    formatted_country = country.title()
    if (co2_df['Country Name'] == formatted_country).any():
        select_country = co2_df[co2_df['Country Name'] == formatted_country]
        year_rows = select_country.iloc[:, 4:]
        year_dict = year_rows.apply(lambda x: float(x)).squeeze().to_dict()
        co2_list = [{'year': int(k), 'amount': v}
                    for k, v in year_dict.items()]
        return co2_list
    elif (co2_df['Country Code'] == country.upper()).any():
        select_country = co2_df[co2_df['Country Code'] == country.upper()]
        year_rows = select_country.iloc[:, 4:]
        year_dict = year_rows.apply(lambda x: float(x)).squeeze().to_dict()
        co2_list = [{'year': int(k), 'amount': v}
                    for k, v in year_dict.items()]
        return co2_list
    else:
        return


def population_dict(country):
    formatted_country = country.title()
    if (population_df['Country Name'] == formatted_country).any():
        select_country = population_df[population_df['Country Name']
                                       == formatted_country]
        year_rows = select_country.iloc[:, 4:]
        year_dict = year_rows.apply(lambda x: int(x)).squeeze().to_dict()
        population_list = [{'year': int(k), 'amount': v}
                           for k, v in year_dict.items()]
        return population_list
    elif (population_df['Country Code'] == country.upper()).any():
        select_country = population_df[population_df['Country Code']
                                       == country.upper()]
        year_rows = select_country.iloc[:, 4:]
        year_dict = year_rows.apply(lambda x: int(x)).squeeze().to_dict()
        population_list = [{'year': int(k), 'amount': v}
                           for k, v in year_dict.items()]
        return population_list
    else:
        return
