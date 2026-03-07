import test from 'node:test';
import assert from 'node:assert/strict';
import { scenarios } from '../src/data/scenarios.js';
import { ScenarioEngine } from '../src/engine/scenarioEngine.js';

test('all scenarios can initialize in engine', () => {
  for (const scenario of scenarios) {
    const engine = new ScenarioEngine(scenario);
    assert.equal(engine.getCurrentNode().id, scenario.startNodeId);
  }
});

test('each scenario path reaches an ending by level 3', () => {
  for (const scenario of scenarios) {
    const queue = [scenario.startNodeId];
    const visited = new Set();

    while (queue.length > 0) {
      const nodeId = queue.shift();
      if (visited.has(nodeId)) continue;
      visited.add(nodeId);

      const node = scenario.nodes.find((item) => item.id === nodeId);
      assert.ok(node, `Node ${nodeId} should exist`);

      for (const option of node.options) {
        if (node.level < 3) {
          assert.ok(option.nextNodeId, `${scenario.id}:${node.id}:${option.id} should have nextNodeId`);
        } else {
          assert.ok(option.endingId, `${scenario.id}:${node.id}:${option.id} should end at endingId`);
          assert.ok(scenario.endings[option.endingId], `${scenario.id} ending ${option.endingId} should exist`);
        }

        if (option.nextNodeId) {
          queue.push(option.nextNodeId);
        }
      }
    }
  }
});

test('engine tracks 3 decisions then ends for representative path', () => {
  const engine = new ScenarioEngine(scenarios[0]);

  let step = engine.pickOption('b'); // level 1 -> level 2
  assert.equal(step.done, false);

  step = engine.pickOption('a'); // level 2 -> level 3
  assert.equal(step.done, false);

  step = engine.pickOption('a'); // level 3 -> ending
  assert.equal(step.done, true);
  assert.equal(engine.getHistory().length, 3);
  assert.equal(engine.getHistory()[0].level, 1);
  assert.equal(engine.getHistory()[1].level, 2);
  assert.equal(engine.getHistory()[2].level, 3);
});
