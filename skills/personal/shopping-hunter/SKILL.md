---
name: shopping-hunter
description: Deep shopping research skill for finding products similar to a reference link or image, benchmarking global pricing, comparing quality/provenance, and creating a reusable buying dossier with links, per-item prices, shipping notes, and value-focused recommendations.
---
# Shopping Hunter

Use this skill when the user wants to find, benchmark, compare, or source products similar to a reference item, image, aesthetic, material, maker, or buying goal. The default mode is **deep global shopping research** with Australia prioritized, AUD-normalized pricing, and a documented dossier.

## Default operating mode

- Produce all of the following:
  - A buying dossier.
  - A concise shortlist of the best buys.
  - A market benchmark showing cheap, mid-market, premium, and high-end pricing.
- Prioritize **Australia first**, then **global sources**.
- Normalize prices to **AUD primary**, while preserving original currency and set size.
- Be **value-focused**: call out bargains, fair pricing, overpricing, provenance premiums, hidden shipping risk, and “cheap but not equivalent” alternatives.
- Prefer actual purchasable product links over inspiration-only pages.
- Include official brand/maker sites, marketplaces, local retailers, boutiques/design stores, secondhand/vintage listings, high-end benchmarks, and wholesale/B2B leads when relevant.
- Search deeply: use regional/source passes, price-tier passes, terminology/source-origin research, exact-source tracing, and high-end benchmarks.

## Required intake questions

Before starting, ask for the missing items from this list. If the user already provided some, only ask for the missing/high-impact ones.

1. Reference link(s) and/or image(s).
2. What they like about the reference: colours, shape, material, finish, dimensions, provenance, vibe, brand, price, etc.
3. Budget or price bands to benchmark.
4. Must-have traits vs nice-to-have traits.
5. Regions to prioritize, with Australia as the default priority.
6. Whether vintage/used/one-off listings are acceptable.
7. Whether wholesale/B2B/MOQ sources are acceptable.
8. Quantity needed and whether sets are preferred.
9. Deal-breakers: materials, countries, shipping, lead times, ethics, returns, fragility, defects.
10. Whether to create a Markdown dossier file; default is yes.

If the user says “don’t hold back,” “deep search,” or similar, proceed with a deep multi-pass workflow and do not over-ask beyond truly missing constraints.

## Research workflow

### 1. Parse the target

Extract a target profile:

- Product category and functional use.
- Visual traits.
- Materials and construction.
- Dimensions/capacity if relevant.
- Likely origin/provenance clues.
- Search vocabulary and synonyms.
- Known brand/source clues from the reference page.

Separate:

- **Exact match**: same brand/product/source.
- **Close match**: same material/process/aesthetic, different maker.
- **Adjacent**: same vibe, different process or quality.
- **Budget lookalike**: visually similar but materially different.
- **Premium benchmark**: higher-end equivalent for price context.

### 2. Run parallel research passes

When available, use parallel subagents or independent searches by scope. Good default passes:

- Exact-source tracing: same product, same brand, resellers, wholesale clues.
- Australia/NZ retailers.
- Etsy/global marketplace alternatives.
- Official brand/maker sites.
- US homeware/boutique sources.
- UK/EU homeware/boutique sources.
- Budget marketplace and mass-market alternatives.
- Wholesale/B2B/source-origin pass.
- High-end/designer/artisan benchmark.
- Search-terms/provenance map.

Do not duplicate work already delegated to an agent. Wait for required research before final synthesis when feasible.

### 3. Verify and normalize

For each candidate, capture:

- Product name.
- Merchant/seller.
- URL.
- Price as listed.
- Currency.
- Set size / quantity.
- Calculated per-item price.
- Approximate AUD per item.
- Shipping to Australia or availability notes.
- Materials and process.
- Origin/provenance.
- Dimensions/capacity.
- Similarity rating.
- Recommendation tier.
- Risk notes: blocked page, unverified price, vintage defect, MOQ, sold out, surface coating vs material colour, import/customs risk.

Never invent prices. If a price is from a snippet, archive, search result, or blocked page, label it clearly as unverified or partially verified.

### 4. Build the dossier

If the user wants a file, create a Markdown dossier in the session files folder unless they explicitly request a repository path. If the user explicitly asks for a repo file, create it where requested.

Recommended dossier structure:

1. Executive verdict.
2. Price bands / market map.
3. Best shortlist.
4. Exact-source findings.
5. Local/Australia options.
6. Global alternatives by region.
7. Budget/mass-market benchmarks.
8. Premium/high-end benchmarks.
9. Wholesale/source-origin leads.
10. Search terms and sourcing vocabulary.
11. Buying guidance.
12. Research limitations and unverifiable leads.

Use dense tables for product comparisons. Keep a short chat summary after creating the dossier and include the file path.

## Recommendation style

Be direct and opinionated:

- Say which option is the best exact match.
- Say which option is the best value.
- Say which option is cheapest but materially different.
- Say which option is premium and why.
- Say whether the reference price looks fair, inflated, or unusually cheap.
- Explain when provenance, material, handmade process, or shipping justifies a higher price.

## Quality rules

- Prefer current, live product pages, but include archived/snippet data when clearly labeled.
- Include sold-out/vintage listings only when useful for benchmarking or search vocabulary.
- Distinguish colour-in-glass from sprayed/painted/electroplated finishes.
- Distinguish handmade, mouth-blown, machine-made, pressed, molded, and studio-art products.
- Distinguish retail price from landed cost; shipping can dominate international purchases.
- Flag fragile/shipping-sensitive categories.
- Do not treat marketplace SEO claims as proven provenance without corroborating text.

## Final response pattern

Lead with the outcome:

- “Created the dossier: `<path>`”
- “Best exact match: ...”
- “Best value: ...”
- “Price verdict: ...”

Keep the chat response concise; the dossier carries the detail.