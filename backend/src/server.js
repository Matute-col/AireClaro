const env = require('./config/env');
const app = require('./app');

app.listen(env.PORT, () => {
  console.log(`AireClaro API escuchando en http://localhost:${env.PORT}/api (modo de correo: ${env.MAIL_MODE})`);
});
