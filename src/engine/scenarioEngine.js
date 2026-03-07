export class ScenarioEngine {
  constructor(scenario) {
    this.scenario = scenario;
    this.nodeMap = new Map(scenario.nodes.map((node) => [node.id, node]));
    this.history = [];
    this.currentNodeId = scenario.startNodeId;
    this.endingId = null;

    this.validateScenario();
  }

  validateScenario() {
    if (!this.nodeMap.has(this.scenario.startNodeId)) {
      throw new Error(`Invalid start node: ${this.scenario.startNodeId}`);
    }

    const seenNodeIds = new Set();

    for (const node of this.scenario.nodes) {
      if (seenNodeIds.has(node.id)) {
        throw new Error(`Duplicate node id found: ${node.id}`);
      }
      seenNodeIds.add(node.id);

      if (![1, 2, 3].includes(node.level)) {
        throw new Error(`Node ${node.id} has invalid level ${node.level}. Levels must be 1, 2, or 3.`);
      }

      if (node.options.length !== 4) {
        throw new Error(`Node ${node.id} must have exactly 4 options.`);
      }

      const optionIds = new Set();

      for (const option of node.options) {
        if (optionIds.has(option.id)) {
          throw new Error(`Node ${node.id} has duplicated option id ${option.id}.`);
        }
        optionIds.add(option.id);

        if (option.nextNodeId && !this.nodeMap.has(option.nextNodeId)) {
          throw new Error(`Option ${node.id}:${option.id} points to unknown node ${option.nextNodeId}`);
        }

        if (option.endingId && !this.scenario.endings[option.endingId]) {
          throw new Error(`Option ${node.id}:${option.id} points to unknown ending ${option.endingId}`);
        }

        if ((option.nextNodeId && option.endingId) || (!option.nextNodeId && !option.endingId)) {
          throw new Error(`Option ${node.id}:${option.id} must reference exactly one of nextNodeId or endingId.`);
        }

        if (node.level < 3 && option.endingId) {
          throw new Error(`Node ${node.id} is level ${node.level}; options must route to nextNodeId only before level 3.`);
        }

        if (node.level === 3 && option.nextNodeId) {
          throw new Error(`Node ${node.id} is level 3; options must route to endingId only.`);
        }
      }
    }
  }

  getCurrentNode() {
    return this.nodeMap.get(this.currentNodeId);
  }

  pickOption(optionId) {
    if (this.endingId) {
      return { done: true, ending: this.scenario.endings[this.endingId] };
    }

    const node = this.getCurrentNode();
    const chosen = node.options.find((option) => option.id === optionId);

    if (!chosen) {
      throw new Error(`Unknown option ${optionId} for node ${node.id}`);
    }

    this.history.push({
      nodeId: node.id,
      optionId,
      optionText: chosen.text,
      level: node.level
    });

    if (chosen.endingId) {
      this.endingId = chosen.endingId;
      return { done: true, ending: this.scenario.endings[chosen.endingId] };
    }

    this.currentNodeId = chosen.nextNodeId;
    return { done: false, node: this.getCurrentNode() };
  }

  getProgress() {
    const node = this.getCurrentNode();
    return {
      currentLevel: node?.level ?? 3,
      totalLevels: 3
    };
  }

  getHistory() {
    return this.history;
  }
}
