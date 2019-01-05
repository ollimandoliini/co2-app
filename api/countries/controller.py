from flask import Flask, request
from flask_restful import Resource, Api, reqparse
from countries.service import emissions
TRUTHY = ['true', 'True', 'yes']


class Emissions(Resource):
    def get(self, country, year):
        percapita = True if request.args.get('percapita') in TRUTHY else False
        country_emissions = emissions(country, year)
        return {'country': country, 'year': year, 'percapita': str(percapita), 'emissions': country_emissions}


class Example(Resource):
    def get(self, param):
        return {'result': param}
