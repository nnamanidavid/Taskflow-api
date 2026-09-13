const taskModel = require('../models/taskModel');

function listTasks(req, res) {
  const { status } = req.query;
  let tasks = taskModel.getAll();
  if (status) {
    tasks = tasks.filter((t) => t.status === status);
  }
  res.status(200).json({ count: tasks.length, tasks });
}

function getTask(req, res) {
  const task = taskModel.getById(req.params.id);
  if (!task) {
    return res.status(404).json({ error: 'Task not found' });
  }
  res.status(200).json(task);
}

function createTask(req, res) {
  const { title, description, status } = req.body;
  if (!title || typeof title !== 'string' || !title.trim()) {
    return res.status(400).json({ error: 'title is required' });
  }
  if (status && !taskModel.VALID_STATUSES.includes(status)) {
    return res.status(400).json({ error: `status must be one of: ${taskModel.VALID_STATUSES.join(', ')}` });
  }
  const task = taskModel.create({ title, description, status });
  res.status(201).json(task);
}

function updateTask(req, res) {
  try {
    const task = taskModel.update(req.params.id, req.body);
    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }
    res.status(200).json(task);
  } catch (err) {
    if (err.message === 'INVALID_STATUS') {
      return res.status(400).json({ error: `status must be one of: ${taskModel.VALID_STATUSES.join(', ')}` });
    }
    throw err;
  }
}

function deleteTask(req, res) {
  const deleted = taskModel.remove(req.params.id);
  if (!deleted) {
    return res.status(404).json({ error: 'Task not found' });
  }
  res.status(204).send();
}

module.exports = { listTasks, getTask, createTask, updateTask, deleteTask };
