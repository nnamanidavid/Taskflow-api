const { v4: uuidv4 } = require('uuid');

// In-memory store (swap for a real DB later — Postgres, DynamoDB, etc.)
let tasks = [];

const VALID_STATUSES = ['todo', 'in-progress', 'done'];

function getAll() {
  return tasks;
}

function getById(id) {
  return tasks.find((t) => t.id === id);
}

function create({ title, description = '', status = 'todo' }) {
  const task = {
    id: uuidv4(),
    title,
    description,
    status: VALID_STATUSES.includes(status) ? status : 'todo',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  tasks.push(task);
  return task;
}

function update(id, updates) {
  const task = getById(id);
  if (!task) return null;

  if (updates.title !== undefined) task.title = updates.title;
  if (updates.description !== undefined) task.description = updates.description;
  if (updates.status !== undefined) {
    if (!VALID_STATUSES.includes(updates.status)) {
      throw new Error('INVALID_STATUS');
    }
    task.status = updates.status;
  }
  task.updatedAt = new Date().toISOString();
  return task;
}

function remove(id) {
  const index = tasks.findIndex((t) => t.id === id);
  if (index === -1) return false;
  tasks.splice(index, 1);
  return true;
}

// Exposed for tests so each test file can start from a clean slate
function _reset() {
  tasks = [];
}

module.exports = { getAll, getById, create, update, remove, _reset, VALID_STATUSES };
