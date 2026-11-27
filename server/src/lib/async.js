// Lets Express 4 routes be async: a rejected promise goes to the error handler.
const Layer = require('express/lib/router/layer');
const handle = Layer.prototype.handle_request;
Layer.prototype.handle_request = function (req, res, next) {
  if (this.handle.length > 3) return handle.call(this, req, res, next);
  try {
    const out = this.handle(req, res, next);
    if (out && typeof out.catch === 'function') out.catch(next);
  } catch (e) {
    next(e);
  }
};
