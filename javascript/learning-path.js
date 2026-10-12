// Learning path progress (spec 006): checkboxes per step, kept in localStorage under the path key; no account,
// nothing sent anywhere. Without JavaScript the path stays a readable ordered list.
(function () {
  var root = document.querySelector('.learning-path[data-path-key]');
  if (!root) return;
  var key = root.getAttribute('data-path-key');
  var pt = document.documentElement.lang === 'pt-BR';
  var steps = Array.prototype.slice.call(root.querySelectorAll('.learning-path-step'));
  var done = {};
  try { done = JSON.parse(localStorage.getItem(key) || '{}') || {}; } catch (e) { done = {}; }

  var progress = root.querySelector('.learning-path-progress');
  var bar = root.querySelector('.learning-path-bar');
  var track = root.querySelector('[role="progressbar"]');
  var count = root.querySelector('.learning-path-count');
  var status = root.querySelector('.learning-path-status');

  function render(announce) {
    var finished = steps.filter(function (step) { return done[step.getAttribute('data-step')]; }).length;
    var text = finished + ' / ' + steps.length;
    count.textContent = text;
    bar.style.width = (steps.length ? Math.round((finished / steps.length) * 100) : 0) + '%';
    track.setAttribute('aria-valuenow', String(finished));
    if (announce) status.textContent = (pt ? 'Etapas concluídas: ' : 'Steps finished: ') + text;
  }

  steps.forEach(function (step) {
    var id = step.getAttribute('data-step');
    var label = step.querySelector('.learning-path-done');
    var box = label.querySelector('input');
    label.classList.remove('hidden');
    box.checked = !!done[id];
    step.classList.toggle('opacity-75', box.checked);
    box.addEventListener('change', function () {
      if (box.checked) done[id] = true; else delete done[id];
      try { localStorage.setItem(key, JSON.stringify(done)); } catch (e) { /* private mode: progress lasts this visit */ }
      step.classList.toggle('opacity-75', box.checked);
      render(true);
    });
  });
  // Steps are open without JavaScript; with it, only the next unfinished step stays open.
  var next = steps.filter(function (step) { return !done[step.getAttribute('data-step')]; })[0];
  steps.forEach(function (step) { var d = step.querySelector('details'); if (d && step !== next) d.open = false; });
  progress.classList.remove('hidden');
  render(false);
})();
