from flask import Flask, request
from flask_restful import Resource, Api, reqparse
from countries.controller import Emissions, Example

app = Flask(__name__)
api = Api(app)


@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers',
                         'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods',
                         'GET,PUT,POST,DELETE,OPTIONS')
    return response


api.add_resource(Emissions, '/countries/<country>/<int:year>')
api.add_resource(Example, '/<param>')

if __name__ == '__main__':
    app.run(debug=True)
