---
persona: novice-no-task
path: fallback
task_source: sandbox
required_markers: [phase-minus-1, phase-0, phase-3, phase-4, phase-5, phase-6, phase-7]
failure_branches: [F-01, F-05, F-06, F-08, F-11, F-12]
---

# Golden Transcript: Novice No-Task Fallback

> SDD is the practice. RPIV is HVE Core's canonical workflow for doing SDD: Research -> Plan -> Implement -> Review, with a Validator layer running inside Plan and Review.

## Markers

- phase-minus-1: first attempt blocks on protected branch, second attempt passes
- phase-0: examples-heavy pacing
- phase-3: fallback task selected from F1-F7
- phase-4: learner types `/task-research`
- phase-5: learner types `/task-plan`
- phase-6: artifact-only review when no test command exists
- phase-7: continue-learning next path chosen

## Sketch

Failure branch F-11 appears first because the learner starts on `main`. F-01 is demonstrated as an installation-check branch in setup notes. F-05 and F-12 appear when the learner proposes an unsafe broad task, then chooses F1. F-06 records no verification command. F-08 appears when the learner asks the tutor to skip explanation; the tutor shortens the next explanation but keeps the learner in control.
