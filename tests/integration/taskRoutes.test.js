const request = require('supertest');
const createApp = require('../../src/app');
const taskModel = require('../../src/models/taskModel');

const app = createApp();

describe('GET /health', () => {
  test('returns 200 and status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('Task API', () => {
  beforeEach(() => {
    taskModel._reset();
  });

  test('POST /api/tasks creates a task', async () => {
    const res = await request(app)
      .post('/api/tasks')
      .send({ title: 'Set up CI pipeline' });
    expect(res.statusCode).toBe(201);
    expect(res.body.title).toBe('Set up CI pipeline');
    expect(res.body.status).toBe('todo');
  });

  test('POST /api/tasks rejects missing title', async () => {
    const res = await request(app).post('/api/tasks').send({ description: 'no title' });
    expect(res.statusCode).toBe(400);
  });

  test('GET /api/tasks lists all tasks', async () => {
    await request(app).post('/api/tasks').send({ title: 'Task 1' });
    await request(app).post('/api/tasks').send({ title: 'Task 2' });

    const res = await request(app).get('/api/tasks');
    expect(res.statusCode).toBe(200);
    expect(res.body.count).toBe(2);
  });

  test('GET /api/tasks?status=todo filters tasks', async () => {
    await request(app).post('/api/tasks').send({ title: 'Todo task' });
    const created = await request(app).post('/api/tasks').send({ title: 'Done task' });
    await request(app).put(`/api/tasks/${created.body.id}`).send({ status: 'done' });

    const res = await request(app).get('/api/tasks?status=done');
    expect(res.body.count).toBe(1);
    expect(res.body.tasks[0].title).toBe('Done task');
  });

  test('GET /api/tasks/:id returns 404 for unknown task', async () => {
    const res = await request(app).get('/api/tasks/does-not-exist');
    expect(res.statusCode).toBe(404);
  });

  test('PUT /api/tasks/:id updates a task', async () => {
    const created = await request(app).post('/api/tasks').send({ title: 'Original' });
    const res = await request(app)
      .put(`/api/tasks/${created.body.id}`)
      .send({ status: 'in-progress' });
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('in-progress');
  });

  test('DELETE /api/tasks/:id removes a task', async () => {
    const created = await request(app).post('/api/tasks').send({ title: 'To delete' });
    const res = await request(app).delete(`/api/tasks/${created.body.id}`);
    expect(res.statusCode).toBe(204);

    const check = await request(app).get(`/api/tasks/${created.body.id}`);
    expect(check.statusCode).toBe(404);
  });

  test('GET /unknown-route returns 404', async () => {
    const res = await request(app).get('/unknown-route');
    expect(res.statusCode).toBe(404);
  });
});
