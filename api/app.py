from flask import Flask
from flask_restful import Api
from countries.controller import Emissions, Population, Example, Picture

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


api.add_resource(Emissions, '/countries/<country>/emissions/')
api.add_resource(Population, '/countries/<country>/population/')
api.add_resource(Example, '/<param>')
api.add_resource(Picture, '/picture')

if __name__ == '__main__':
    app.run(debug=True)
