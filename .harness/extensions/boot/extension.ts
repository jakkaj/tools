import type { HarnessVerb, VerbContext, VerbResult } from '@ai-substrate/engineering-harness/contract';

/**
 * `harness boot` — the first proof + re-orientation an agent runs before work.
 *
 * This repo is a skills repository + dev-tooling installer: there is no running
 * service to start, so readiness == the quality gate is green. Boot therefore
 * composes `harness checks` and folds its verdict into its own, then prints
 * short orientation.
 */
const boot: HarnessVerb = {
  name: 'boot',
  summary: 'Ready the repo for work: compose `harness checks` and orient the agent.',
  async run(ctx: VerbContext): Promise<VerbResult> {
    const orient =
      'tools — skills repo (skills/<category>/<slug>/SKILL.md) + dev-tooling installer. ' +
      'Edit skills under skills/, run `harness checks` before done, `just` for dev tasks. ' +
      'Git is read-only unless the user asks.';

    // Deterministic missing-`checks` degrade — never a silent omission.
    if (!ctx.fs.exists('.harness/extensions/checks')) {
      return ctx.degraded(
        { verdict: 'degraded', orient, checks: 'absent' },
        'No `checks` extension exists — create one (`harness new checks`) or move quality checks (slug/flow/lint/test) into a `checks` extension so `boot` and agents can gate on it.',
      );
    }

    const r = await ctx.exec('harness', ['checks', '--json']);
    if (r.ok) {
      return ctx.ok({ verdict: 'ready', orient, checks: 'green' });
    }
    return ctx.degraded(
      { verdict: 'degraded', orient, checks: 'red', checksExit: r.code },
      'Quality gate is red — run `harness checks` and fix the failing gate before starting work.',
    );
  },
};

export default boot;
