import type { HarnessVerb, VerbContext, VerbResult } from '@ai-substrate/engineering-harness/contract';

/**
 * One quality gate. Each wraps a real repo command, run from the repo root,
 * expected to exit 0 on pass. Order matters — gates run top-to-bottom and
 * `checks` fails on the first red.
 *
 * To ADD a gate (e.g. the skill-frontmatter linter), append one entry here.
 * Every caller — `harness boot`, CI, an agent's pre-done gate — picks it up
 * for free. That is the whole point of one composable `checks`.
 */
interface Gate {
  name: string;
  command: string;
  args: string[];
}

const GATES: Gate[] = [
  // Slug uniqueness — `npx skills` flattens categories on install, so a
  // duplicate slug silently overwrites another skill.
  { name: 'skill-slugs', command: 'bash', args: ['scripts/check-skill-slugs.sh'] },
  // Flow-architecture lint — the-flow must satisfy the flow-architecture pattern
  // (Registry/Graph/grammar, frontmatter parses, description <= 1024 chars).
  { name: 'flow-architecture', command: 'bash', args: ['scripts/check-flow-architecture.sh', 'skills/SDD/the-flow'] },
  // Skill frontmatter — every SKILL.md has valid frontmatter: name matches its
  // folder slug, description present and <= 1024 chars (the host budget).
  { name: 'skill-frontmatter', command: 'bash', args: ['scripts/check-skill-frontmatter.sh'] },
];

const checks: HarnessVerb = {
  name: 'checks',
  summary: 'Run the repo quality gates (skill-slug collisions, flow-architecture lint) in order; fail on the first red.',
  async run(ctx: VerbContext): Promise<VerbResult> {
    const results: { gate: string; ok: boolean; code: number }[] = [];
    for (const gate of GATES) {
      const r = await ctx.exec(gate.command, gate.args);
      results.push({ gate: gate.name, ok: r.ok, code: r.code });
      if (!r.ok) {
        const log = (r.stdout || '') + (r.stderr || '');
        return ctx.error('E_CHECKS', `gate '${gate.name}' failed (exit ${r.code})`, {
          details: log.trim().slice(-2000),
          next_action: `Fix the '${gate.name}' gate, then re-run \`harness checks\`. Command: ${gate.command} ${gate.args.join(' ')}`,
        });
      }
    }
    return ctx.ok({ gates: results, passed: results.length });
  },
};

export default checks;
