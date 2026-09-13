const taskModel = require('../../src/models/taskModel');

describe('taskModel', () => {
  beforeEach(() => {
    taskModel._reset();
  });

  test('create() adds a task with defaults', () => {
    const task = taskModel.create({ title: 'Write README' });
    expect(task.id).toBeDefined();
    expect(task.title).toBe('Write README');
    expect(task.status).toBe('todo');
    expect(taskModel.getAll()).toHaveLength(1);
  });

  test('create() falls back to todo on an invalid status', () => {
    const task = taskModel.create({ title: 'Bad status', status: 'nonsense' });
    expect(task.status).toBe('todo');
  });

  test('getById() returns undefined for unknown id', () => {
    expect(taskModel.getById('missing-id')).toBeUndefined();
  });

  test('update() modifies an existing task', () => {
    const task = taskModel.create({ title: 'Old title' });
    const updated = taskModel.update(task.id, { title: 'New title', status: 'in-progress' });
    expect(updated.title).toBe('New title');
    expect(updated.status).toBe('in-progress');
  });

  test('update() throws on invalid status', () => {
    const task = taskModel.create({ title: 'Task' });
    expect(() => taskModel.update(task.id, { status: 'bogus' })).toThrow('INVALID_STATUS');
  });

  test('update() returns null for unknown id', () => {
    expect(taskModel.update('missing-id', { title: 'x' })).toBeNull();
  });

  test('remove() deletes a task and returns true', () => {
    const task = taskModel.create({ title: 'Delete me' });
    expect(taskModel.remove(task.id)).toBe(true);
    expect(taskModel.getAll()).toHaveLength(0);
  });

  test('remove() returns false for unknown id', () => {
    expect(taskModel.remove('missing-id')).toBe(false);
  });
});
