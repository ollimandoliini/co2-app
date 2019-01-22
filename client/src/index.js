import './main.css';
import { Elm } from './Main.elm';
import { Main } from './Main.elm';

Elm.Main.init({
  node: document.getElementById('root'),
  flags: {
    environment: process.env.NODE_ENV || 'development',
    apiUrl: process.env.ELM_APP_API_URL || 'http://127.0.0.1:5000/'
  },
});
