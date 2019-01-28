import wbdata
import datetime
import pandas as pd


co2_df = pd.read_csv("data/emissions.csv", header=0,
                     error_bad_lines=False, sep=";")

population_df = pd.read_csv('data/population.csv',
                            header=0, error_bad_lines=False, sep=";")


def update_co2_data(co2_df):
    years = (datetime.datetime(2015, 1, 1), (datetime.datetime.now()))

    new_co2 = wbdata.get_data(indicator='EN.ATM.CO2E.KT',
                              data_date=years, pandas=True).to_frame()
    new_co2 = new_co2['value'].to_frame().reset_index()
    new_co2.rename(columns={'country': 'Country Name'}, inplace=True)
    new_co2 = new_co2.pivot(index='Country Name',
                            columns='date', values='value')
    new_co2 = new_co2.apply(pd.to_numeric).fillna(value=0).reset_index()

    added_years = list(new_co2)

    co2_df = co2_df.sort_values(by=['Country Name'])
    new_co2 = new_co2.sort_values(by=['Country Name'])
    co2_df.update(new_co2)

    for year in added_years:
        if year not in co2_df.columns:
            co2_df = pd.concat([co2_df, new_co2[year]], axis=1, sort=True)

    return co2_df


def update_population_data(pop_df):
    years = (datetime.datetime(2015, 1, 1), (datetime.datetime.now()))
    new_pop = wbdata.get_data(indicator='SP.POP.TOTL',
                              data_date=years, pandas=True).to_frame()
    new_pop = new_pop['value'].to_frame().reset_index()
    new_pop.rename(columns={'country': 'Country Name'}, inplace=True)
    new_pop = new_pop.pivot(index='Country Name',
                            columns='date', values='value')
    new_pop = new_pop.apply(pd.to_numeric).fillna(value=0).reset_index()
    added_years = list(new_pop)
    pop_df = pop_df.sort_values(by=['Country Name'])
    new_pop = new_pop.sort_values(by=['Country Name'])
    pop_df.update(new_pop)

    for year in added_years:
        if year not in pop_df.columns:
            pop_df = pd.concat([pop_df, new_pop[year]], axis=1, sort=True)

    return pop_df


co2_df = update_co2_data(co2_df)
population_df = update_population_data(population_df)


print(list(population_df['Country Name']))
