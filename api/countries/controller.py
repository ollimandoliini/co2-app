from flask import send_file
from flask_restful import Resource
from countries.service import country_data, country_plot


class Country(Resource):
    def get(self, country):
        data = country_data(country)
        return {'country': country.title(), 'years': data}


class CountryPlot(Resource):
    def get(self, country):
        plot = country_plot(country)
        plot.seek(0)
        file = send_file(plot, mimetype='image/png')
        return file


class Example(Resource):
    def get(self, param):
        return {'result': param}


class Picture(Resource):
    def get(self):
        response = send_file("cat.jpg")
        return response
