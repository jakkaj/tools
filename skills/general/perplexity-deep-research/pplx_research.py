#!/usr/bin/env python3
"""perplexity-deep-research — call the Perplexity API directly, no MCP wrapper.

Why this exists: the bundled perplexity MCP server times out at ~5 minutes, but
`sonar-deep-research` routinely runs longer (it fans out many web searches +
thousands of reasoning tokens). This calls the HTTP endpoint directly with a long
client-side timeout, so deep research jobs actually finish.

Stdlib only — no pip dependencies. Reads the key from $PERPLEXITY_API_KEY.

Usage:
    pplx_research.py "your research question"
    pplx_research.py --model sonar "quick question"
    pplx_research.py --timeout 2400 --recency month "what changed recently in X?"
    pplx_research.py --json "..."   # raw API response
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

ENDPOINT = "https://api.perplexity.ai/chat/completions"
DEFAULT_MODEL = "sonar-deep-research"   # the slow one the MCP can't survive
DEFAULT_TIMEOUT = 1800                   # 30 min — must exceed the MCP's ~5 min cap
# Live-verified models (2026-06-07): sonar, sonar-pro, sonar-deep-research.
# sonar-reasoning is DEPRECATED (HTTP 400).
KNOWN_MODELS = ["sonar", "sonar-pro", "sonar-deep-research"]


def build_parser():
    p = argparse.ArgumentParser(
        prog="pplx_research.py",
        description="Direct Perplexity API research call (bypasses the 5-min MCP timeout).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Known models: " + ", ".join(KNOWN_MODELS),
    )
    p.add_argument("prompt", help="the question / research prompt")
    p.add_argument("--model", default=DEFAULT_MODEL,
                   help=f"model id (default: {DEFAULT_MODEL})")
    p.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT,
                   help=f"client timeout in seconds (default: {DEFAULT_TIMEOUT})")
    p.add_argument("--system", default=None,
                   help="optional system prompt prepended to the conversation")
    p.add_argument("--recency", choices=["hour", "day", "week", "month", "year"],
                   default=None, help="restrict search results by recency")
    p.add_argument("--json", action="store_true",
                   help="print the raw JSON API response instead of formatted text")
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)

    key = os.environ.get("PERPLEXITY_API_KEY")
    if not key:
        print("error: PERPLEXITY_API_KEY is not set (check env or your MCP config).",
              file=sys.stderr)
        return 2

    messages = []
    if args.system:
        messages.append({"role": "system", "content": args.system})
    messages.append({"role": "user", "content": args.prompt})

    body = {"model": args.model, "messages": messages}
    if args.recency:
        body["search_recency_filter"] = args.recency

    req = urllib.request.Request(
        ENDPOINT,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=args.timeout) as resp:
            payload = json.load(resp)
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace")[:600]
        print(f"error: HTTP {e.code} from Perplexity: {detail}", file=sys.stderr)
        return 1
    except urllib.error.URLError as e:
        print(f"error: request failed: {e.reason}", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(payload, indent=2))
        return 0

    try:
        content = payload["choices"][0]["message"]["content"]
    except (KeyError, IndexError):
        print("error: unexpected response shape:\n"
              + json.dumps(payload, indent=2)[:600], file=sys.stderr)
        return 1

    print(content)

    citations = payload.get("citations") or []
    if citations:
        print("\nCitations:")
        for i, url in enumerate(citations, 1):
            print(f"  [{i}] {url}")

    # cost/usage to stderr so stdout stays clean for piping
    usage = payload.get("usage", {})
    cost = (usage.get("cost") or {}).get("total_cost")
    bits = [f"model={payload.get('model', args.model)}"]
    if cost is not None:
        bits.append(f"cost=${cost}")
    print(f"\n({' '.join(bits)})", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
