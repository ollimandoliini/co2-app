# CO2-APP

Web-application for exploring countries' CO2-emissions in both absolute and per capita values.

Project includes
- `/client` for web UI
- `/api` for API

Technology stack:
- Frontend: Elm
- Backend: Python/Flask

## Setup

Environmental variables:
- `ELM_APP_API_URL=backendurl`
- `ELM_DEBUGGER=false` [due to this issue](https://github.com/elm/compiler/issues/1802)


Installation:
1. `git clone git@github.com:ollimandoliini/co2-app.git`
2. `cd co2-app/api && pipenv install`
3. `pipenv run python app.py`
4. `cd .. && npm install`
5. `cd client && elm-app start`


