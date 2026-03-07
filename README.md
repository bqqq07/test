# ERT Branching Scenario Prototype

A lightweight, mobile-friendly prototype for training Emergency Response Team members using decision-based branching scenarios.

## Run locally

Because this project uses ES modules, run it with a local server:

```bash
python3 -m http.server 4173
```

Then open `http://localhost:4173`.

## Project structure

```text
.
├── index.html
├── package.json
├── src
│   ├── main.js
│   ├── data
│   │   └── scenarios.js
│   ├── engine
│   │   └── scenarioEngine.js
│   └── ui
│       ├── renderers.js
│       └── styles.css
├── tests
│   └── scenarioEngine.test.js
└── README.md
```

- `src/data/scenarios.js`: all editable scenario content in one place (nodes, options, endings).
- `src/engine/scenarioEngine.js`: flow rules, validation, progress/history tracking.
- `src/ui/renderers.js`: UI rendering for list, play screen, and debrief screen.
- `src/main.js`: application wiring between data, engine, and UI.
- `tests/scenarioEngine.test.js`: sanity checks for scenario integrity and engine behavior.

## How to add a new scenario

1. Open `src/data/scenarios.js`.
2. Add a new object inside the exported `scenarios` array.
3. Define:
   - `id`, `title`, `summary`, `startNodeId`
   - `nodes` (3 levels, 4 options each)
   - `endings` (multiple possible results)
4. Ensure each option points to either:
   - `nextNodeId` (another node), or
   - `endingId` (existing key in `endings`).

The engine validates missing links, duplicated IDs, invalid option wiring, and incorrect option counts automatically.

## Where to edit texts and endings

- Scenario text (context/questions/options): `src/data/scenarios.js` under each scenario's `nodes`.
- Outcome/debrief text: `src/data/scenarios.js` under each scenario's `endings`:
  - `outcome`
  - `possibleConsequence`
  - `keyLessons` (exactly 3 points)
  - `correctApproach` (short clear steps)

## Validation

Run structural tests:

```bash
npm test
```
