export function renderScenarioList(container, scenarios, onStart) {
  container.innerHTML = `
    <h2>Choose a scenario</h2>
    <p class="muted">Each scenario has 3 levels and multiple possible outcomes.</p>
    <div class="scenario-list">
      ${scenarios
        .map(
          (scenario) => `
        <button class="scenario-card" data-scenario-id="${scenario.id}">
          <h3>${scenario.title}</h3>
          <p>${scenario.summary}</p>
        </button>
      `
        )
        .join("")}
    </div>
  `;

  container.querySelectorAll("[data-scenario-id]").forEach((button) => {
    button.addEventListener("click", () => onStart(button.dataset.scenarioId));
  });
}

export function renderNode(container, scenario, node, progress, onPick) {
  container.innerHTML = `
    <div class="progress">Level ${progress.currentLevel} / ${progress.totalLevels}</div>
    <h2>${scenario.title}</h2>
    <p class="context">${node.context}</p>
    <h3 class="question">${node.question}</h3>
    <div class="options">
      ${node.options
        .map(
          (option) => `
        <button class="option-button" data-option-id="${option.id}">${option.text}</button>
      `
        )
        .join("")}
    </div>
  `;

  container.querySelectorAll("[data-option-id]").forEach((button) => {
    button.addEventListener("click", () => onPick(button.dataset.optionId));
  });
}

export function renderEnding(container, ending, history, onRetry, onBack) {
  const decisionTrail = history
    .map((step) => `<li>Level ${step.level}: ${step.optionText}</li>`)
    .join("");

  container.innerHTML = `
    <h2>Debrief</h2>
    <p><strong>Outcome:</strong> ${ending.outcome}</p>
    <p><strong>Possible consequence:</strong> ${ending.possibleConsequence}</p>

    <h3>Key lessons</h3>
    <ul>
      ${ending.keyLessons.map((lesson) => `<li>${lesson}</li>`).join("")}
    </ul>

    <h3>Correct approach</h3>
    <ol>
      ${ending.correctApproach.map((item) => `<li>${item}</li>`).join("")}
    </ol>

    <h3>Your path</h3>
    <ul>${decisionTrail}</ul>

    <div class="actions">
      <button class="secondary" id="retry-button">Retry scenario</button>
      <button id="back-button">Back to scenarios</button>
    </div>
  `;

  container.querySelector("#retry-button")?.addEventListener("click", onRetry);
  container.querySelector("#back-button")?.addEventListener("click", onBack);
}

export function showView({ listView, playView, resultView }, viewName) {
  listView.classList.toggle("hidden", viewName !== "list");
  playView.classList.toggle("hidden", viewName !== "play");
  resultView.classList.toggle("hidden", viewName !== "result");
}
