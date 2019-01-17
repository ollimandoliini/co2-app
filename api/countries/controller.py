from flask_restful import Resource
from countries.service import get_country_data, get_country_plot, get_country_names


class Country(Resource):
    def get(self, country):
        data = get_country_data(country)
        return {'country': country.title(), 'dataPoints': data}


class CountryPlot(Resource):
    def get(self, country):
        file = get_country_plot(country)
        return file


class CountryNames(Resource):
    def get(self):
        data = get_country_names()
        return data
