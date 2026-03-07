export const scenarios = [
  {
    id: "lifting-suspended-load",
    title: "Lifting Incident / Suspended Load",
    summary: "A load swings unexpectedly and one worker is down near the lift zone.",
    startNodeId: "lift-l1",
    nodes: [
      {
        id: "lift-l1",
        level: 1,
        context: "During steel beam lifting, wind increases and the suspended load starts rotating. A rigger slips and falls near the red zone.",
        question: "What is your first action as arriving ERT member?",
        options: [
          { id: "a", text: "Run to the fallen worker and start first aid immediately.", nextNodeId: "lift-l2-unsafe" },
          { id: "b", text: "Stop all movement, secure crane operations, and enforce exclusion zone before approaching.", nextNodeId: "lift-l2-control" },
          { id: "c", text: "Ask bystanders to keep distance while you assess from the edge.", nextNodeId: "lift-l2-partial" },
          { id: "d", text: "Use radio to request ambulance first, then wait for their arrival.", nextNodeId: "lift-l2-delay" }
        ]
      },
      {
        id: "lift-l2-unsafe",
        level: 2,
        context: "You move in quickly while the load is still suspended and drifting. Another worker follows you.",
        question: "What do you do now?",
        options: [
          { id: "a", text: "Continue treatment; every second matters more than crane movement.", nextNodeId: "lift-l3-secondary-victim" },
          { id: "b", text: "Order both of you out, reset scene control, and stop crane motion now.", nextNodeId: "lift-l3-recover" },
          { id: "c", text: "Signal operator to lower load without a clear landing zone.", nextNodeId: "lift-l3-instability" },
          { id: "d", text: "Send partner for spine board while you stay under the load.", nextNodeId: "lift-l3-secondary-victim" }
        ]
      },
      {
        id: "lift-l2-control",
        level: 2,
        context: "The lift is paused, tag lines are stabilized, and area is isolated. Injured worker is conscious but in pain.",
        question: "Which next step is best?",
        options: [
          { id: "a", text: "Perform rapid trauma assessment while assigning one member to incident command communication.", nextNodeId: "lift-l3-best-path" },
          { id: "b", text: "Move worker immediately to safe office area before assessment.", nextNodeId: "lift-l3-unnecessary-move" },
          { id: "c", text: "Wait for site manager approval before any intervention.", nextNodeId: "lift-l3-delay" },
          { id: "d", text: "Restart nearby operations to reduce schedule impact while treating.", nextNodeId: "lift-l3-distraction" }
        ]
      },
      {
        id: "lift-l2-partial",
        level: 2,
        context: "Crowd is pushed back, but crane is still loaded and no formal stop-work call was made.",
        question: "How do you close this gap?",
        options: [
          { id: "a", text: "Formally activate stop-work and confirm suspended load is landed/secured.", nextNodeId: "lift-l3-best-path" },
          { id: "b", text: "Start casualty care now; assume operator will hold steady.", nextNodeId: "lift-l3-secondary-victim" },
          { id: "c", text: "Ask one worker to watch load while team treats patient.", nextNodeId: "lift-l3-instability" },
          { id: "d", text: "Focus on collecting witness statements first.", nextNodeId: "lift-l3-delay" }
        ]
      },
      {
        id: "lift-l2-delay",
        level: 2,
        context: "External help is requested, but on-site hazards are still dynamic and no one owns the scene.",
        question: "What should happen before ambulance arrives?",
        options: [
          { id: "a", text: "Establish on-site control: stop movement, isolate area, assign roles, then assess patient.", nextNodeId: "lift-l3-recover" },
          { id: "b", text: "Do nothing further to avoid liability.", nextNodeId: "lift-l3-delay" },
          { id: "c", text: "Move patient with nearby labor crew to speed evacuation.", nextNodeId: "lift-l3-unnecessary-move" },
          { id: "d", text: "Let crane continue because patient is not directly under the hook now.", nextNodeId: "lift-l3-distraction" }
        ]
      },
      {
        id: "lift-l3-secondary-victim",
        level: 3,
        context: "While rescue starts in the hot zone, load shifts suddenly and near-miss escalates.",
        question: "Final decision point:",
        options: endingOptions("lift-secondary-victim", "lift-delay-cost", "lift-chaotic-control", "lift-secondary-victim")
      },
      {
        id: "lift-l3-recover",
        level: 3,
        context: "You regain control after an initial delay and hazards become stable.",
        question: "Final decision point:",
        options: endingOptions("lift-contained", "lift-contained", "lift-delay-cost", "lift-delay-cost")
      },
      {
        id: "lift-l3-instability",
        level: 3,
        context: "Load path remains uncertain and communication between crane team and ERT is weak.",
        question: "Final decision point:",
        options: endingOptions("lift-chaotic-control", "lift-secondary-victim", "lift-chaotic-control", "lift-delay-cost")
      },
      {
        id: "lift-l3-best-path",
        level: 3,
        context: "Scene is stabilized, command is clear, and casualty care is coordinated safely.",
        question: "Final decision point:",
        options: endingOptions("lift-contained", "lift-contained", "lift-delay-cost", "lift-contained")
      },
      {
        id: "lift-l3-unnecessary-move",
        level: 3,
        context: "Patient was moved early without full hazard and injury check.",
        question: "Final decision point:",
        options: endingOptions("lift-delay-cost", "lift-delay-cost", "lift-contained", "lift-chaotic-control")
      },
      {
        id: "lift-l3-delay",
        level: 3,
        context: "Critical minutes pass with limited intervention and uncertain command.",
        question: "Final decision point:",
        options: endingOptions("lift-delay-cost", "lift-chaotic-control", "lift-delay-cost", "lift-contained")
      },
      {
        id: "lift-l3-distraction",
        level: 3,
        context: "Competing priorities reduce situational awareness around suspended load controls.",
        question: "Final decision point:",
        options: endingOptions("lift-chaotic-control", "lift-secondary-victim", "lift-delay-cost", "lift-chaotic-control")
      }
    ],
    endings: {
      "lift-contained": {
        outcome: "Incident contained with no additional casualties.",
        possibleConsequence: "Primary injury managed quickly; operational downtime remains controlled.",
        keyLessons: [
          "Scene safety must precede patient contact around suspended loads.",
          "Explicit incident command prevents role confusion.",
          "Early, structured communication improves rescue speed and quality."
        ],
        correctApproach: [
          "Stop lift activity and secure suspended load.",
          "Create and enforce exclusion zone.",
          "Assign command, medical lead, and communications.",
          "Assess and treat only after hazard stabilization."
        ]
      },
      "lift-delay-cost": {
        outcome: "Patient eventually treated, but delayed control worsened impact.",
        possibleConsequence: "Injury severity and downtime increased due to slow incident organization.",
        keyLessons: [
          "Calling external help is not a substitute for on-scene control.",
          "Good intentions without structure create operational gaps.",
          "Time lost in early minutes compounds consequences."
        ],
        correctApproach: [
          "Control hazards immediately before advanced actions.",
          "Use concise radio call with clear requests.",
          "Begin focused trauma care once zone is declared safe.",
          "Track actions and handover details for incoming responders."
        ]
      },
      "lift-chaotic-control": {
        outcome: "Response remained fragmented and risk stayed high.",
        possibleConsequence: "Near-miss escalation and prolonged shutdown due to weak coordination.",
        keyLessons: [
          "Partial controls are not equivalent to scene safety.",
          "ERT must lead incident structure early.",
          "Competing priorities can hide critical hazards."
        ],
        correctApproach: [
          "Declare stop-work and isolate lift corridor.",
          "Verify load is stable/landed before close access.",
          "Set one communication channel and role ownership.",
          "Execute rescue tasks in controlled sequence."
        ]
      },
      "lift-secondary-victim": {
        outcome: "Secondary victim occurred during unsafe rescue attempt.",
        possibleConsequence: "Incident severity doubled with additional injuries and possible regulatory action.",
        keyLessons: [
          "Rescue without hazard control can create new casualties.",
          "Pressure to act fast must not override risk barriers.",
          "Team members mirror unsafe leadership decisions."
        ],
        correctApproach: [
          "Pause and reset if responders enter unsafe zone.",
          "Stabilize suspended load and exclusion perimeter first.",
          "Use disciplined entry authorization for rescue.",
          "Treat casualty only when residual risk is acceptable."
        ]
      }
    }
  },
  {
    id: "confined-space-unconscious-worker",
    title: "Confined Space Unconscious Worker",
    summary: "Worker collapses inside tank entry during maintenance prep.",
    startNodeId: "cs-l1",
    nodes: [
      {
        id: "cs-l1",
        level: 1,
        context: "A worker inside a vertical tank stops responding. Attendant reports no recent gas reading update.",
        question: "What is your immediate response?",
        options: [
          { id: "a", text: "Enter immediately with another coworker to pull the worker out.", nextNodeId: "cs-l2-rush-entry" },
          { id: "b", text: "Stop entry, verify atmospheric status, and activate confined-space rescue protocol.", nextNodeId: "cs-l2-protocol" },
          { id: "c", text: "Call ambulance and wait at manway.", nextNodeId: "cs-l2-delay" },
          { id: "d", text: "Ask standby worker to enter with lifeline while you monitor.", nextNodeId: "cs-l2-rush-entry" }
        ]
      },
      {
        id: "cs-l2-rush-entry",
        level: 2,
        context: "Unauthorized rescue entry is about to happen; no confirmed ventilation or gas testing.",
        question: "What should you do now?",
        options: [
          { id: "a", text: "Abort entry, secure portal, and prepare non-entry retrieval setup.", nextNodeId: "cs-l3-recovery" },
          { id: "b", text: "Allow quick entry for 30 seconds only.", nextNodeId: "cs-l3-secondary-victim" },
          { id: "c", text: "Send SCBA user even without rescue standby team.", nextNodeId: "cs-l3-fragmented" },
          { id: "d", text: "Continue shouting to victim from opening.", nextNodeId: "cs-l3-delay" }
        ]
      },
      {
        id: "cs-l2-protocol",
        level: 2,
        context: "Entry is frozen, retrieval tripod available, rescue team en route, and ventilation can be increased.",
        question: "Choose your next operational priority.",
        options: [
          { id: "a", text: "Start non-entry retrieval while monitoring atmosphere continuously.", nextNodeId: "cs-l3-best-path" },
          { id: "b", text: "Wait for full external team before doing anything.", nextNodeId: "cs-l3-delay" },
          { id: "c", text: "Send one trained entrant now to speed rescue.", nextNodeId: "cs-l3-fragmented" },
          { id: "d", text: "Stop ventilation to avoid spreading unknown gases.", nextNodeId: "cs-l3-secondary-victim" }
        ]
      },
      {
        id: "cs-l2-delay",
        level: 2,
        context: "No one enters, but no active mitigation or retrieval prep is occurring.",
        question: "How do you improve the response?",
        options: [
          { id: "a", text: "Activate permit-rescue plan, ventilation, gas monitoring, and retrieval readiness.", nextNodeId: "cs-l3-recovery" },
          { id: "b", text: "Keep waiting for fire department only.", nextNodeId: "cs-l3-delay" },
          { id: "c", text: "Send attendant inside with rope for a quick check.", nextNodeId: "cs-l3-secondary-victim" },
          { id: "d", text: "Close hatch and isolate area without rescue preparation.", nextNodeId: "cs-l3-fragmented" }
        ]
      },
      {
        id: "cs-l3-best-path",
        level: 3,
        context: "Team follows permit controls and non-entry rescue plan with clear command.",
        question: "Final decision point:",
        options: endingOptions("cs-contained", "cs-contained", "cs-delay-cost", "cs-contained")
      },
      {
        id: "cs-l3-recovery",
        level: 3,
        context: "You corrected an early gap and recovered to safer operations.",
        question: "Final decision point:",
        options: endingOptions("cs-contained", "cs-delay-cost", "cs-contained", "cs-fragmented")
      },
      {
        id: "cs-l3-fragmented",
        level: 3,
        context: "Pieces of the plan are active, but control barriers remain incomplete.",
        question: "Final decision point:",
        options: endingOptions("cs-fragmented", "cs-delay-cost", "cs-fragmented", "cs-secondary-victim")
      },
      {
        id: "cs-l3-delay",
        level: 3,
        context: "Response is passive while victim condition may deteriorate.",
        question: "Final decision point:",
        options: endingOptions("cs-delay-cost", "cs-fragmented", "cs-delay-cost", "cs-contained")
      },
      {
        id: "cs-l3-secondary-victim",
        level: 3,
        context: "Unsafe entry attempts create risk of multiple downed workers.",
        question: "Final decision point:",
        options: endingOptions("cs-secondary-victim", "cs-secondary-victim", "cs-fragmented", "cs-delay-cost")
      }
    ],
    endings: {
      "cs-contained": {
        outcome: "Victim retrieved under controlled rescue conditions.",
        possibleConsequence: "Serious incident contained without additional entrants harmed.",
        keyLessons: [
          "Confined-space rescue starts with atmospheric and entry control.",
          "Non-entry retrieval is often the safest early tactic.",
          "Command clarity reduces impulsive hero behavior."
        ],
        correctApproach: [
          "Stop unauthorized entry immediately.",
          "Activate permit-specific rescue protocol.",
          "Ventilate and monitor atmosphere continuously.",
          "Use non-entry retrieval first; enter only with full controls."
        ]
      },
      "cs-delay-cost": {
        outcome: "Rescue eventually executed, but avoidable delays reduced outcome quality.",
        possibleConsequence: "Higher medical severity and delayed site recovery.",
        keyLessons: [
          "Waiting without mitigation is not a safe strategy.",
          "Time-critical actions can still be methodical.",
          "Prepared equipment must be activated, not just available."
        ],
        correctApproach: [
          "Start rescue workflow immediately after alarm.",
          "Assign roles: incident lead, atmosphere monitor, retrieval operator.",
          "Communicate status updates at fixed intervals.",
          "Document timeline for handover."
        ]
      },
      "cs-fragmented": {
        outcome: "Response quality varied; risks remained partially uncontrolled.",
        possibleConsequence: "Near-miss recurrence risk stays high on next incident.",
        keyLessons: [
          "Incomplete controls create hidden failure points.",
          "Rescue competence requires process discipline, not only equipment.",
          "One channel of command and communication is critical."
        ],
        correctApproach: [
          "Use checklist-based activation for confined-space emergencies.",
          "Confirm barriers before each operational step.",
          "Avoid ad-hoc entries outside permit conditions.",
          "Debrief immediately to close procedural gaps."
        ]
      },
      "cs-secondary-victim": {
        outcome: "Secondary victim risk became imminent due to unauthorized entry behavior.",
        possibleConsequence: "Multi-casualty confined-space event with severe escalation.",
        keyLessons: [
          "Most confined-space fatalities involve would-be rescuers.",
          "Urgency never justifies blind entry.",
          "Stopping unsafe actions is an essential rescue task."
        ],
        correctApproach: [
          "Lock down entry point and account for personnel.",
          "Deploy retrieval/ventilation and continuous gas checks.",
          "Authorize entry rescue only with full team and PPE readiness.",
          "Maintain strict command over who enters and when."
        ]
      }
    }
  },
  {
    id: "electrical-shock-incident",
    title: "Electrical Shock Incident",
    summary: "Technician receives shock near temporary power distribution board.",
    startNodeId: "elec-l1",
    nodes: [
      {
        id: "elec-l1",
        level: 1,
        context: "You arrive and see a worker collapsed near a wet floor and energized temporary panel.",
        question: "What is your immediate first step?",
        options: [
          { id: "a", text: "Touch and drag the worker away from danger quickly.", nextNodeId: "elec-l2-live-risk" },
          { id: "b", text: "Isolate power source and verify de-energization before contact.", nextNodeId: "elec-l2-control" },
          { id: "c", text: "Throw a dry cloth over cables then approach.", nextNodeId: "elec-l2-live-risk" },
          { id: "d", text: "Call emergency line first and wait for electricians.", nextNodeId: "elec-l2-delay" }
        ]
      },
      {
        id: "elec-l2-live-risk",
        level: 2,
        context: "Live hazard may still exist and one helper is moving closer.",
        question: "What do you do now?",
        options: [
          { id: "a", text: "Stop all approach, isolate energy, and control perimeter immediately.", nextNodeId: "elec-l3-recovery" },
          { id: "b", text: "Use metal tool to move cable away from victim.", nextNodeId: "elec-l3-secondary-victim" },
          { id: "c", text: "Begin CPR immediately without confirming de-energization.", nextNodeId: "elec-l3-secondary-victim" },
          { id: "d", text: "Wait for supervisor while area stays open.", nextNodeId: "elec-l3-delay" }
        ]
      },
      {
        id: "elec-l2-control",
        level: 2,
        context: "Power is locked out and tested. Victim is unresponsive with shallow breathing.",
        question: "Choose the next best action.",
        options: [
          { id: "a", text: "Start medical assessment/CPR protocol and request AED + advanced support.", nextNodeId: "elec-l3-best-path" },
          { id: "b", text: "Pour water to cool possible burns before assessment.", nextNodeId: "elec-l3-fragmented" },
          { id: "c", text: "Move victim immediately to clinic vehicle without stabilization.", nextNodeId: "elec-l3-delay" },
          { id: "d", text: "Allow bystanders to film panel condition for investigation.", nextNodeId: "elec-l3-fragmented" }
        ]
      },
      {
        id: "elec-l2-delay",
        level: 2,
        context: "External call is made, but no one is actively securing the energized area.",
        question: "How should you correct course?",
        options: [
          { id: "a", text: "Assign one person to isolate power and one to scene control while preparing medical response.", nextNodeId: "elec-l3-recovery" },
          { id: "b", text: "Wait untouched scene for investigators.", nextNodeId: "elec-l3-delay" },
          { id: "c", text: "Allow trained electrician alone to manage both rescue and hazard.", nextNodeId: "elec-l3-fragmented" },
          { id: "d", text: "Ask workers to crowd in and identify what happened.", nextNodeId: "elec-l3-secondary-victim" }
        ]
      },
      {
        id: "elec-l3-best-path",
        level: 3,
        context: "Hazard is isolated and clinical response is initiated promptly.",
        question: "Final decision point:",
        options: endingOptions("elec-contained", "elec-contained", "elec-delay-cost", "elec-contained")
      },
      {
        id: "elec-l3-recovery",
        level: 3,
        context: "Initial actions were incomplete, but scene control is improving.",
        question: "Final decision point:",
        options: endingOptions("elec-contained", "elec-delay-cost", "elec-fragmented", "elec-contained")
      },
      {
        id: "elec-l3-fragmented",
        level: 3,
        context: "Medical and hazard controls are active but not tightly coordinated.",
        question: "Final decision point:",
        options: endingOptions("elec-fragmented", "elec-delay-cost", "elec-fragmented", "elec-secondary-victim")
      },
      {
        id: "elec-l3-delay",
        level: 3,
        context: "Valuable minutes are lost with uncertain ownership of tasks.",
        question: "Final decision point:",
        options: endingOptions("elec-delay-cost", "elec-fragmented", "elec-delay-cost", "elec-contained")
      },
      {
        id: "elec-l3-secondary-victim",
        level: 3,
        context: "Unsafe contact with energized components threatens additional casualties.",
        question: "Final decision point:",
        options: endingOptions("elec-secondary-victim", "elec-secondary-victim", "elec-delay-cost", "elec-fragmented")
      }
    ],
    endings: {
      "elec-contained": {
        outcome: "Electrical incident controlled with rapid, safe patient care.",
        possibleConsequence: "Single casualty with improved survival chance and reduced site disruption.",
        keyLessons: [
          "No-touch until confirmed de-energization.",
          "Energy isolation and medical response must run in parallel.",
          "Crowd control protects both victim and responders."
        ],
        correctApproach: [
          "Isolate and verify zero energy state.",
          "Set perimeter to prevent secondary contact.",
          "Start CPR/AED pathway as clinically indicated.",
          "Maintain command updates and prepare handover."
        ]
      },
      "elec-delay-cost": {
        outcome: "Victim care was delayed by indecision and weak task allocation.",
        possibleConsequence: "Lower recovery probability and longer operational stoppage.",
        keyLessons: [
          "Calling for help must be paired with immediate site actions.",
          "Delay in power isolation extends danger window.",
          "Clear role assignment improves tempo under stress."
        ],
        correctApproach: [
          "Split tasks quickly: hazard control, patient care, communication.",
          "Verify safe approach before contact.",
          "Start evidence-safe documentation after life safety tasks.",
          "Reassess scene every few minutes."
        ]
      },
      "elec-fragmented": {
        outcome: "Response achieved partial control but remained operationally inconsistent.",
        possibleConsequence: "Residual risk and procedural weakness persist for future incidents.",
        keyLessons: [
          "Single good action cannot offset weak overall coordination.",
          "Incident control is a system, not an isolated step.",
          "Responder workload must be distributed intentionally."
        ],
        correctApproach: [
          "Use a short command checklist for electrical events.",
          "Validate hazard status before each medical task.",
          "Keep non-essential personnel outside control zone.",
          "Debrief process gaps immediately post-incident."
        ]
      },
      "elec-secondary-victim": {
        outcome: "Secondary contact risk escalated the event toward multiple victims.",
        possibleConsequence: "Potential fatality escalation and major regulatory consequences.",
        keyLessons: [
          "Unverified electrical scenes can injure rescuers instantly.",
          "Improvised contact methods are unsafe.",
          "First command objective is preventing additional exposure."
        ],
        correctApproach: [
          "Freeze approach and isolate source.",
          "Confirm de-energization with competent person/testing.",
          "Control zone access and remove bystanders.",
          "Begin patient treatment only after scene declared safe."
        ]
      }
    }
  }
];

function endingOptions(endA, endB, endC, endD) {
  return [
    { id: "a", text: "Prioritize scene control and coordinated response.", endingId: endA },
    { id: "b", text: "Focus on fast victim contact even with residual hazards.", endingId: endB },
    { id: "c", text: "Delay action until external team takes full control.", endingId: endC },
    { id: "d", text: "Split team informally without clear command owner.", endingId: endD }
  ];
}
