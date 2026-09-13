// Centralized error handler — keeps stack traces out of API responses
function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
}

function notFoundHandler(req, res) {
  res.status(404).json({ error: `Route ${req.method} ${req.originalUrl} not found` });
}

module.exports = { errorHandler, notFoundHandler };
