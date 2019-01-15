from flask import send_file
from flask_restful import Resource
from countries.service import get_country_data, get_country_plot


class Country(Resource):
    def get(self, country):
        data = get_country_data(country)
        return {'country': country.title(), 'dataPoints': data}


class CountryPlot(Resource):
    def get(self, country):
        file = get_country_plot(country)
        return file


class Example(Resource):
    def get(self, param):
        return {'result': param}


class Picture(Resource):
    def get(self):
        response = send_file("cat.jpg")
        return response
