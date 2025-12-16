What the literature gives you for “spec success” measurement

SPACE (Forsgren et al., ACM Queue)

SPACE is valuable here because it explicitly rejects the exact trap you describe: collapsing “productivity” into a single output proxy (story points, lines of code, PR counts). It highlights three measurement failure modes that matter directly to Spec Driven Development (SDD):
	•	“Productivity = activity” is a myth. Activity metrics (commits, LOC, PR counts) can be easy to collect but are weak proxies for impact and can be actively misleading.  ￼
	•	“Productivity = individual output” is also a myth. A spec is a coordination artifact across multiple people/systems; measuring “per dev” often damages the system you’re trying to improve.  ￼
	•	No single metric defines productivity. The point is not a universal score; it’s a balanced, contextual set across different dimensions.  ￼

This is why SPACE is so compatible with your flow: your workflow is already building a system of traceability and evidence; SPACE tells you what kinds of outcomes to connect that evidence to.

Engineering System Success Playbook (GitHub ESSP)

ESSP operationalizes SPACE into a systems approach: pick a small set of “downstream” (lagging) outcomes, then connect them to “leading” indicators you can influence in the delivery system.  ￼

Key concepts you can directly lift:
	•	Four zones, twelve downstream metrics (3 per zone) so you don’t accidentally optimize one dimension and degrade another.  ￼
	•	Downstream metrics are lagging indicators; you need leading metrics across the SDLC to actually drive change.  ￼
	•	Companion metrics: a metric that provides context (and prevents misreads / Goodharting).  ￼
	•	Avoid individual-level measurement and gaming. ESSP explicitly warns that measuring individual productivity is problematic and that metrics can be gamed.  ￼  ￼

ESSP’s actual downstream set (useful as a “balanced dashboard” for spec success at the system level):
	•	Developer happiness: flow state experience, engineering tooling satisfaction, Copilot satisfaction.  ￼
	•	Velocity: lead time, deployment frequency, PRs merged per developer (mean).  ￼
	•	Quality: change failure rate, failed deployment recovery time, code security & maintainability.  ￼  ￼
	•	Business outcomes: AI leverage, engineering expenses to revenue, feature engineering expenses to total engineering expenses.  ￼  ￼

Accelerate (Forsgren/Humble/Kim)

Accelerate contributes two crucial additions for your context:
	1.	Delivery performance is measurable in a small set of outcomes, and speed + stability move together (you don’t have to trade one off against the other).  ￼
	2.	The research explicitly broadened beyond “commit → prod” into upstream (“fuzzy front end”) product management and development process measures—i.e., exactly the “inception through production” value-stream concern you raised.  ￼

Also, Accelerate is unusually direct about measurement culture: in bureaucratic/pathological contexts, measurement becomes control and leads to information hiding—i.e., the perfect recipe for metric gaming and spec theatre.  ￼

And the “24 capabilities” list (adapted from Accelerate) matters because several capabilities map cleanly to SDD improvements: make work visible through the value stream, work in small batches, foster experimentation, loosely coupled architecture, and generative culture.  ￼

⸻

Review of your SDD agent flow: how /0 → /7 produces an outcome

Your flow is best understood as a traceable value pipeline that progressively tightens ambiguity into executable work, then turns work into evidence, and evidence into a merge decision.

/plan-0-constitution — establish doctrine and boundaries

This sets the system-level constraints by creating doctrine files (constitution, rules, idioms, architecture).  ￼
This is important because it establishes what “good” looks like before you start measuring anything.

/plan-1b-specify — define intent (WHAT/WHY) and scope boundaries

You explicitly emphasize starting with specification and focusing on WHAT/WHY before HOW.  ￼
The spec template includes the usual “requirements + acceptance criteria + risks/assumptions/open questions” structure.  ￼

/plan-2-clarify — reduce ambiguity and lock testing/docs intent

This updates the spec with a Clarifications section and populates testing/documentation strategy; it also refines FRs/NFRs and edge cases.  ￼
This is your first real “quality gate” against unclear requirements (one of the highest-leverage failure points in the ESSP anti-patterns).  ￼

/plan-3-architect — convert spec into a phase plan with gates + critical findings

This is your “systems analysis” step: it produces a multi-section plan (critical findings, phases mapped to acceptance criteria, cross-cutting concerns, complexity tracking, etc.).  ￼
It uses parallel subagents to generate 15–20+ critical findings and applies multiple gates (clarification, constitution, architecture, ADRs).  ￼

/plan-4-complete-the-plan — validate readiness before coding

A multi-validator readiness check (structure/testing/completeness/doctrine/ADR).  ￼
This is where you can most cleanly add measurement readiness gates (more below).

/plan-5-phase-tasks-and-brief — translate the plan into executable work (one phase)

Creates a combined dossier (tasks.md) with a 9-column task table plus alignment brief, evidence artifacts, and footnote stubs.  ￼
It forces a phase to be operationally “GO/NO-GO” ready.  ￼

/plan-6-implement-phase + /plan-6a-update-progress — implement with evidence and atomic provenance

Implementation supports multiple testing approaches; critically, it auto-calls /plan-6a after each task.  ￼
/plan-6a is your atomic integrity mechanism: it updates (1) dossier task table, (2) plan task table, and (3) both ledgers, and treats “any location not updated” as incomplete.  ￼

This is a major asset for measurement because it gives you a consistent event stream of task-level progress tied to code diffs and evidence.

/plan-7-code-review — enforce doctrine + graph integrity + quality/safety

This creates a review report and uses parallel validators, including bidirectional link validation and explicit reviewers for correctness/security/performance/observability.  ￼

Net effect: your /0→/7 flow produces (1) aligned intent, (2) executable tasks, (3) implementation evidence, and (4) a merge gate—while maintaining a provenance graph that can be navigated and audited.

What’s missing for “value from inception to production” is not traceability or rigor; it’s that the graph ends at merge, unless you explicitly extend it to production telemetry and business outcomes.

⸻

What to measure to judge “spec success” (without devolving into LOC/story points)

A spec is successful if it functions as a high-quality coordination and hypothesis artifact:
	•	It reduces avoidable ambiguity and rework (efficiency/flow).
	•	It improves delivery performance (speed + stability).
	•	It preserves/raises developer well-being (satisfaction).
	•	It moves a real outcome (business/customer impact).
	•	It produces learning (validated or invalidated hypotheses).

The right answer is not “one metric.” SPACE explicitly rejects that.  ￼
ESSP similarly pushes a balanced set and companion metrics.  ￼

A practical “Spec Success Scorecard” (SPACE × ESSP × Accelerate)

Below is a spec-centric scorecard that avoids output proxies and maps to the literature. It’s designed so each spec has:
	•	1–2 primary outcome metrics (why we’re doing this)
	•	2–3 delivery/system metrics (how safely/quickly we shipped)
	•	2–3 leading indicators (did the spec reduce uncertainty early?)
	•	1–2 guardrails (what must not get worse)

1) Performance (SPACE) / Business outcomes (ESSP)
Pick based on spec type:
	•	Feature spec: activation, retention, conversion, feature adoption, task success rate, customer support contact rate (down).
	•	Reliability spec: availability/SLO attainment, incident rate, error budget burn.
	•	Cost spec: infrastructure cost per transaction, compute efficiency.
	•	Security spec: vulnerability exposure window, time-to-remediate.

ESSP’s business outcomes zone reminds you to include some business framing (even if not all specs map cleanly): AI leverage and engineering spend ratios are examples at the system level.  ￼

Spec success test (performance): did the measured outcome move in the expected direction, with guardrails respected?

2) Efficiency & flow (SPACE) / Velocity (ESSP) / DORA
Here you can use the classic delivery-performance metrics, but attribute them per spec by tagging work:
	•	Lead time for changes and deployment frequency are explicitly part of ESSP’s velocity zone.  ￼
	•	DORA defines them as key delivery performance metrics, alongside stability measures.  ￼

Spec success test (flow): did the spec (and the workflow around it) allow work to move smoothly—without large queues, excessive waiting, or oversized batches?

Also: you already have a built-in way to contextualize lead time without using estimates: your Complexity Score doctrine (“never use time estimates; use complexity scores”).  ￼
That’s a natural companion metric: track lead time per complexity band rather than raw lead time.

3) Quality (SPACE performance + ESSP quality) / DORA stability
This is where specs are often “secretly” decided. A spec that is clear but produces fragile change is not successful.

Use ESSP’s quality zone:
	•	change failure rate
	•	failed deployment recovery time
	•	code security & maintainability  ￼

These align tightly with DORA’s stability side (change failure rate, time to restore).  ￼

4) Satisfaction & well-being (SPACE) / Developer happiness (ESSP)
This is the dimension SDD implementations often forget, and it’s where “measurement” can backfire hardest if it becomes surveillance.

ESSP’s developer happiness metrics are directly usable:
	•	flow state experience
	•	engineering tooling satisfaction
	•	Copilot satisfaction  ￼

A spec that is “perfect” but creates constant interruptions, churn, and micromanagement is not an improvement.

5) Communication & collaboration (SPACE)
This is the “spec dimension” many teams miss because it isn’t in DORA. Specs are communication artifacts; measure communication quality as a system.

Examples that don’t devolve into vanity metrics:
	•	time-to-clarity: elapsed time from first [NEEDS CLARIFICATION] to resolved (you already gate on this)  ￼
	•	number of cross-team decisions requiring ADRs, and whether ADR constraints are mapped to tasks (your /plan-5 brief explicitly supports this)  ￼
	•	“decision latency”: time between question raised and decision recorded (in spec clarifications or ADRs)

⸻

The key move: extend your provenance graph to include production outcomes

Right now your graph is extremely strong from task → log → file → plan/dossier, and /plan-7 enforces link integrity aggressively.  ￼

To measure “value from inception through production,” you need one more set of nodes:
	•	Outcome nodes: dashboards, experiment results, KPIs, SLOs, customer feedback
	•	Instrumentation nodes: analytics events, logs, metrics, traces, feature flags

This is the “missing edge” that lets you answer:
Which spec produced which production impact, and what evidence supports it?

⸻

A) How to improve the flow to make it more measurable and outcome-driven

Below are improvements that are “native” to your current system design (phases, dossiers, evidence artifacts, atomic updates, and validators). They don’t require abandoning SDD; they require closing the loop.

1) Add a first-class “Measurement Plan” section to the spec (and make it a gate)

Your spec already includes cross-cutting concerns like observability (“metrics to capture”).  ￼
Promote this from “nice to have” to required structure.

Add a Spec Success Canvas block (example template):

## Success Metrics (Spec Success Canvas)

### Primary outcome (1–2)
- Metric:
- Baseline:
- Target / expected direction:
- Measurement window:
- Data source / dashboard:

### Guardrails (1–3)
- Reliability/SLO:
- Error rate / performance:
- Security/privacy constraints:

### Leading indicators (during delivery)
- Clarification completion:
- Spec churn:
- Rework indicators:

### Instrumentation & verification
- Events/logs/metrics to add:
- Dashboard link(s):
- Verification steps (pre-prod and prod):

Then update /plan-4-complete-the-plan to include a “Measurement Readiness Validator” alongside its existing validators. /plan-4 already runs parallel validators and produces READY/NOT READY.  ￼
Measurement readiness becomes one more validator.

Why this works with ESSP: downstream metrics are lagging; you need leading metrics and process instrumentation to influence them.  ￼

2) Introduce a new command after /plan-7: /plan-8-outcome-review

Your current lifecycle effectively ends at merge/review. /plan-7 is a pre-merge quality gate.  ￼
But your stated problem requires a loop closure in production.

Add a command that:
	•	reads spec + plan + execution logs
	•	pulls or prompts for production telemetry links (dashboards, experiment results)
	•	writes a structured Outcome Review doc:
	•	what moved, what didn’t, why
	•	unintended consequences (guardrail impact)
	•	follow-up work (new spec or phase)

This mirrors ESSP’s “implement changes and monitor results” loop.  ￼

3) Make “instrumentation tasks” mandatory and early in each phase dossier

Your phase dossier already has:
	•	an Alignment Brief with objectives, test plan, and a GO/NO-GO gate  ￼
	•	a task table with a Validation column  ￼

Use that Validation column to include measurement validation, not only functional correctness:
	•	“Dashboard shows event X”
	•	“SLO burn alert wired”
	•	“Feature flag metrics segmented”

And enforce a rule: “No phase is ‘done’ unless instrumentation validation is complete.”

This prevents the common failure where teams ship code and later discover they cannot prove impact.

4) Add “companion metrics” explicitly to prevent local optimization

ESSP’s companion metrics idea is extremely applicable to SDD because SDD can create new local optima (“we produced great specs!”).  ￼

Example companions:
	•	If you track lead time, companion it with change failure rate (speed without stability is not success).  ￼
	•	If you track PR throughput, companion it with code security & maintainability or flow state experience (avoid “busier is better”).  ￼
	•	If you track AI leverage, companion it with quality and post-release defects (AI can increase throughput while harming maintainability).  ￼

Operationally: store companions in the spec’s Success Metrics section so they are visible from inception.

5) Add “value stream” fields to the plan to measure inception-to-production time

Accelerate research explicitly expanded upstream into the “fuzzy front end.”  ￼
SDD as written begins at spec creation; your broader problem begins earlier.

Add a small set of timestamps/fields in spec metadata:
	•	problem identified
	•	spec started
	•	spec approved
	•	first code merged
	•	first production exposure (feature flag on for X%)
	•	outcome review completed

This gives you idea-to-value lead time, not just commit-to-prod.

6) Use your existing “Complexity Score” to normalize outcome metrics

You already prohibit time estimates and use complexity scores.  ￼
This is a measurement advantage if you use it correctly:
	•	Track DORA/ESSP velocity and quality by complexity band (CS-1..CS-5).
	•	Track “spec churn” by complexity (higher complexity should tolerate more learning churn).
	•	Track “outcome movement probability” by complexity (bigger bets should have stronger discovery work).

This avoids the common trap: “spec A took longer than spec B” when A was fundamentally more complex.

⸻

B) Insights you might not have considered (viewed through Forsgren/Accelerate)

1) The biggest hidden risk: SDD can become a control system unless you explicitly design the culture around it

Your flow is traceable, auditable, and integrity-enforced (/plan-6a atomic updates; /plan-7 link validators).  ￼  ￼

That is powerful—and culturally dangerous if the organization treats it as surveillance. Accelerate explicitly calls out that in bureaucratic/pathological cultures, measurement becomes control and people hide information.  ￼

Design implication: include in /plan-0-constitution (or an org-level doctrine) a clear statement:
	•	metrics are for system improvement, not individual evaluation
	•	audits are for learning, not blame
	•	“broken graph” is a quality issue, not a performance issue

This is consistent with ESSP’s warnings about individual measurement and gamification.  ￼  ￼

2) The “spec” is not the unit of value unless it is explicitly a hypothesis with a measurable outcome

A spec can be perfectly executed and still deliver no value if it’s solving the wrong problem (or the value wasn’t observable). Accelerate’s expansion into product management and upstream process is a reminder that you must measure from problem framing through learning.  ￼

Design implication: treat each spec as an experiment with expected outcome, even for internal work:
	•	Reliability work: expected reduction in incidents / MTTR
	•	DX work: expected increase in flow state experience or reduced time-to-first-commit for new contributors
	•	Security work: reduced remediation time / exposure window

3) “Work in small batches” is a capability SDD can accidentally undermine

Accelerate’s capabilities list highlights “work in small batches” and “make flow visible through the value stream.”  ￼
SDD can drift into “big design up front” unless you explicitly push slicing.

You already have an enabling mechanism: phase-by-phase execution and “one phase at a time.”  ￼
But to fully align with the research, you want phases to be:
	•	independently releasable (or at least independently testable and demoable)
	•	tied to incremental outcome signals (even if intermediate)

Design implication: add a rule in /plan-3 that every phase must define:
	•	incremental user value or learning
	•	incremental production telemetry check (even for dark launches)

4) Sustainability outcomes: burnout and “deployment pain” are part of the model

Accelerate’s research mentions sustainability outcomes like burnout and deployment pain (i.e., the human cost of delivery).  ￼
ESSP explicitly includes developer happiness metrics like flow state experience.  ￼

Design implication: SDD should measure its own overhead:
	•	spec creation time is not a goal, but “spec churn” and “interrupt load” are signals
	•	add a lightweight periodic pulse survey tied to phases: “Did this workflow help or hinder deep work?”

5) “PRs merged per developer” is particularly risky in an AI + SDD world

ESSP includes “PRs merged per developer (mean)” as a velocity metric.  ￼
This is exactly the kind of activity-adjacent metric SPACE warns can mislead if treated as productivity.  ￼

Design implication: if you keep it, hard-code guardrails:
	•	report at team/system level, never for ranking
	•	always pair with quality + satisfaction companions
	•	consider replacing with PR cycle time / queue time as “flow” measures (less gameable, more diagnostic)

⸻

C) Creative additions: other high-leverage things to know (and do)

1) Add a “Spec Churn Ledger” (the analog of Change Footnotes)

You already maintain a rigorous Change Footnotes Ledger for code changes.  ￼

Create a similar ledger for spec evolution:
	•	number of clarification sessions  ￼
	•	acceptance criteria additions/removals after implementation begins
	•	scope change classification (learning vs avoidable ambiguity)

This becomes a leading indicator of unclear requirements (an ESSP anti-pattern).  ￼

2) “Outcome Footnotes”: make production evidence navigable like code evidence

Extend your FlowSpace node idea with an outcome namespace, for example:
	•	metric:<system>:<metric_name>
	•	dashboard:<tool>:<id>
	•	experiment:<platform>:<experiment_id>

Then, in /plan-6a, allow capturing:
	•	which metrics were instrumented for that task
	•	where the dashboard is
	•	what the expected signal is

This creates task → instrumentation → dashboard → outcome review traversal, completing your “inception to production value” goal.

3) Add “anti-pattern detectors” that are triggered by your own workflow signals

ESSP provides concrete anti-patterns and examples of leading signals (e.g., unclear requirements correlating with time in meetings, WIP, rework, frustration).  ￼

Because your flow captures task state changes and logs, you can build detectors like:
	•	high reopen rate / repeated partial completions (rework)
	•	unusually high number of clarification sessions for low-complexity work (requirements quality issue)
	•	large number of tasks without clear Validation criteria (testing/measurement weakness)
	•	long “in progress” dwell time without log evidence (WIP / blockage)

These are far more actionable than “lines of code.”

4) Treat SDD itself as an intervention and measure its impact with the ESSP zones

If you are deploying SDD as a way of working, measure whether SDD improves:
	•	Flow state experience (deep work)  ￼
	•	lead time and deployment frequency  ￼
	•	change failure rate and recovery time  ￼
	•	maintainability/security  ￼

This answers your meta-question: “Did SDD make measurement worse?” You’ll know by whether the system metrics improved without harming satisfaction.

5) Use “work visibility through the value stream” explicitly (Accelerate capability)

Accelerate’s capability list includes making work visible through the value stream and using WIP limits.  ￼
Your dossiers already make work visible inside engineering. The leap is to include:
	•	product discovery status
	•	dependency readiness
	•	rollout readiness
	•	outcome review status

This becomes a true inception-to-production measurement pipeline, not just a planning pipeline.

⸻

A minimal, implementable measurement baseline (if you want a starting point)

If you want the smallest set that still honors SPACE/ESSP/Accelerate:
	1.	Per spec: 1 primary outcome metric + 2 guardrails (defined in spec).
	2.	Per spec delivery: DORA 4-key metrics (at least lead time + change failure rate).  ￼
	3.	Per team, monthly: flow state experience + tooling satisfaction pulse.  ￼
	4.	Per spec workflow health: spec churn (clarifications + late AC changes) and rework rate (task reopen/partial).

Everything else can be layered on once this is stable and trusted.

⸻

Bottom line

Your flow already has a rare asset: evidence-grade traceability and integrity gates (atomic progress updates, bidirectional link validation, phase dossiers with explicit validation criteria).  ￼  ￼

To measure spec success the way SPACE/ESSP/Accelerate intend, the key changes are:
	•	treat the spec as a hypothesis with explicit outcome metrics
	•	extend the provenance graph to production outcomes
	•	add measurement readiness and outcome review gates
	•	use balanced metrics (with companions) and keep them away from individual ranking to prevent the cultural failure modes Forsgren warns about  ￼

If you want, I can propose concrete diffs to your /plan-1b spec template, /plan-4 validator checklist, and a draft /plan-8-outcome-review command definition in the same style as your existing commands.