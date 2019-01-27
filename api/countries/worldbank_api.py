import wbdata
import datetime
import pandas as pd


def reformat_dataframe(df):
    df = df['value'].to_frame().reset_index()
    df.rename(columns={'country': 'Country Name'}, inplace=True)
    df = df.pivot(index='Country Name',
                  columns='date', values='value')
    df = df.apply(pd.to_numeric).fillna(value=0).reset_index()
    return df


def update_co2_data(co2_df):
    years = (datetime.datetime(2015, 1, 1), (datetime.datetime.now()))

    new_co2 = wbdata.get_data(indicator='EN.ATM.CO2E.KT',
                              data_date=years, pandas=True).to_frame()

    formatted_co2 = reformat_dataframe(new_co2)

    added_years = list(formatted_co2)

    co2_df = co2_df.sort_values(by=['Country Name'])
    formatted_co2 = formatted_co2.sort_values(by=['Country Name'])
    co2_df.update(formatted_co2)

    for year in added_years:
        if year not in co2_df.columns:
            co2_df = pd.concat(
                [co2_df, formatted_co2[year]], axis=1, sort=True)

    return co2_df


def update_population_data(population_df):
    years = (datetime.datetime(2015, 1, 1), (datetime.datetime.now()))
    new_pop = wbdata.get_data(indicator='SP.POP.TOTL',
                              data_date=years, pandas=True).to_frame()

    formatted_population = reformat_dataframe(new_pop)

    added_years = list(formatted_population)
    population_df = population_df.sort_values(by=['Country Name'])
    formatted_population = formatted_population.sort_values(
        by=['Country Name'])
    population_df.update(formatted_population)

    for year in added_years:
        if year not in population_df.columns:
            population_df = pd.concat(
                [population_df, formatted_population[year]], axis=1, sort=True)

    return population_df
