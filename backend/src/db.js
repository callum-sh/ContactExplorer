// db.js
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Optionally, test the connection
pool
  .connect()
  .then(client => {
    return client
      .query('SELECT NOW()')
      .then(res => {
        console.log('Connected to PostgreSQL at', res.rows[0].now);
        client.release();
      })
      .catch(err => {
        client.release();
        console.error('Error executing test query', err.stack);
      });
  })
  .catch(err => console.error('Error acquiring client', err.stack));

module.exports = pool;
