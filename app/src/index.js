const express = require('express');
const { Pool } = require('pg');

const app = express();
const port = process.env.PORT || 3001;

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'factice_db',
  user: process.env.DB_USER || 'factice_user',
  password: process.env.DB_PASSWORD || '',
});

app.use(express.json());

app.get('/health', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({ status: 'ok', timestamp: result.rows[0].now });
  } catch (err) {
    console.error('Health check failed:', err);
    res.status(503).json({ status: 'error', message: err.message });
  }
});

app.get('/items', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM items ORDER BY created_at DESC');
    res.json({ items: result.rows, count: result.rows.length });
  } catch (err) {
    console.error('GET /items failed:', err);
    res.status(500).json({ error: err.message });
  }
});

app.post('/items', async (req, res) => {
  const { name } = req.body;
  if (!name) {
    return res.status(400).json({ error: 'name is required' });
  }

  try {
    const result = await pool.query(
      'INSERT INTO items (name) VALUES ($1) RETURNING *',
      [name]
    );
    res.status(201).json({ item: result.rows[0] });
  } catch (err) {
    console.error('POST /items failed:', err);
    res.status(500).json({ error: err.message });
  }
});

const server = app.listen(port, () => {
  console.log(`✅ Factice app listening on port ${port}`);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    pool.end(() => process.exit(0));
  });
});
