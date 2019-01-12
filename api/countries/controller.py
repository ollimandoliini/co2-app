from flask import request, send_file
from flask_restful import Resource
from countries.service import co2_dict, population_dict

TRUTHY = ['true', 'True', 'yes']


class Emissions(Resource):
    def get(self, country):
        percapita = True if request.args.get('percapita') in TRUTHY else False
        co2_emissions = co2_dict(country)
        return {'country': country, 'percapita': str(percapita),
                'emissions': co2_emissions}


class Population(Resource):
    def get(self, country):
        population = population_dict(country)
        return {'country': country, 'population': population}


class Example(Resource):
    def get(self, param):
        return {'result': param}


class Picture(Resource):
    def get(self):
        response = send_file("cat.jpg")
        return response
