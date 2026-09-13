# TaskFlow API

A small task management REST API. Built as a sample app — good candidate for
wrapping a CI/CD pipeline around, since it has real routes, real tests, and a
health check endpoint to poll.

## Run locally

```bash
npm install
cp .env.example .env
npm run dev
```

## Test

```bash
npm test              # unit + integration, with coverage
npm run test:unit
npm run test:integration
npm run lint
```

## Endpoints

| Method | Path             | Description          |
|--------|------------------|-----------------------|
| GET    | /health          | Liveness/readiness check |
| GET    | /api/tasks       | List tasks (optional `?status=` filter) |
| GET    | /api/tasks/:id   | Get one task          |
| POST   | /api/tasks       | Create a task (`title` required) |
| PUT    | /api/tasks/:id   | Update a task         |
| DELETE | /api/tasks/:id   | Delete a task          |

Task `status` is one of: `todo`, `in-progress`, `done`.

## Notes

- Data is stored in memory, so it resets on restart — swap `src/models/taskModel.js`
  for a real database when you're ready.
- `src/app.js` and `src/server.js` are split on purpose: `app.js` exports the
  Express app (used directly by the integration tests), `server.js` just boots it.
