import { scenarios } from "./data/scenarios.js";
import { ScenarioEngine } from "./engine/scenarioEngine.js";
import { renderScenarioList, renderNode, renderEnding, showView } from "./ui/renderers.js";

const views = {
  listView: document.getElementById("scenario-list-view"),
  playView: document.getElementById("scenario-play-view"),
  resultView: document.getElementById("scenario-result-view")
};

let activeScenario = null;
let engine = null;

renderScenarioList(views.listView, scenarios, startScenario);
showView(views, "list");

function startScenario(scenarioId) {
  activeScenario = scenarios.find((scenario) => scenario.id === scenarioId);
  if (!activeScenario) return;

  engine = new ScenarioEngine(activeScenario);
  showView(views, "play");
  renderCurrentNode();
}

function renderCurrentNode() {
  const node = engine.getCurrentNode();
  const progress = engine.getProgress();
  renderNode(views.playView, activeScenario, node, progress, onPickOption);
}

function onPickOption(optionId) {
  const result = engine.pickOption(optionId);

  if (result.done) {
    showView(views, "result");
    renderEnding(
      views.resultView,
      result.ending,
      engine.getHistory(),
      () => startScenario(activeScenario.id),
      backToList
    );
    return;
  }

  renderCurrentNode();
}

function backToList() {
  showView(views, "list");
  activeScenario = null;
  engine = null;
}
