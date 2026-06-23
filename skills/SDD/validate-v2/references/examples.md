# validate-v2 — worked examples

Illustrative — based on a real validation pattern from a separate substrate. Paths are representative, not repo-verifiable. They show what a thesis-aware, consumer-aware catch looks like; copy the *shape*, not the paths.

## Why local-correct still fails (the MarkdownEditor catch)

**Artifact**: Phase 1 ships `MarkdownEditor`, a React component wrapping Tiptap with the `editor` instance held as a private field.

A shallow per-file sweep passes everything: file exists, types match, plan says "ship MarkdownEditor", tests cover render/onChange/disabled → ✅. Nothing asked whether Phase 2's planned toolbar could *consume* the output. The miss landed as rework.

The adaptive run builds the Contract first:

- **Purpose / outcome**: inline markdown authoring without leaving the viewer — *"Authors can edit, format, and link markdown inline without leaving the viewer."* (quoted from `083-md-editor-spec.md`).
- **Promise**: downstream toolbar + viewer phases compose with the editor primitive without refactoring its lifecycle.
- **Proof target**: Integration. **Proof required**: public editor access (or equivalent), tests that extend to toolbar/editor integration.
- **Consumers**: Phase 2 `tasks.md` (needs public `editor`); Phase 5 workshop §15.3 (needs a composable editor).
- **Position**: public `{ value, onChange }` prop API; internal selection state private.

One Contract/Compatibility critic, scoped to those two named consumers, returns:

| Consumer | Requirement | Mode | Verdict | Evidence |
|---|---|---|---|---|
| Phase 2 toolbar | public `editor` instance | encapsulation lockout | ❌ | `MarkdownEditor.tsx:12` — `editor` closed over, not exposed via ref/prop/context |
| Phase 5 FileViewerPanel | composable editor | lifecycle ownership | ❌ | editor lifecycle tied to `MarkdownEditor` mount; sibling can't share the instance |

**Verdict**: ❌ NEEDS ATTENTION — proof target Integration, actual Implementation. Smallest fix: expose `editor` via `forwardRef` (or context, or hoist to a parent hook). The thesis ("compose without refactoring") is *blocked*, even though every file is locally correct.

## Mini-examples — the five forward-compatibility modes

- **Shape mismatch** — Phase 1 ships `useDocumentState(): { value, onChange }`; Phase 3 autosave destructures `{ value, onChange, selection, isDirty }`. → extend the return type, update tests, re-export.
- **Contract drift** — ADR-012 mandates 200ms debounce; implementation ships `debounce(100)`. → set `DEBOUNCE_MS = 200` with a comment linking the ADR.
- **Lifecycle ownership** — parent owns the editor lifecycle; a sibling toolbar must nest rather than compose beside. → hoist lifecycle to a shared parent/hook.
- **Test boundary** — Phase 1 mocks the editor via `createMockEditor()`; Phase 3 needs real toolbar-editor integration assertions. → split `unit-mocks.ts` from `integration-real.tsx`; document the boundary.
- **Encapsulation lockout** — see the MarkdownEditor catch above.

## Mini-examples — thesis failure modes

- **Proxy optimization** — a workshop is extremely detailed but never produces the state table / examples / proof that would reduce implementation ambiguity. → add contract-ready evidence, not more prose.
- **Wrong beneficiary** — a tasks dossier optimises for the implementer but omits the reviewer-facing acceptance criteria the Contract's Promise names. → add validation commands, expected outputs, review checkpoints.
- **Proof mismatch** — a plan labelled implementation-ready holds only phase names and vague deliverables. → add ACs, concrete files, dependencies, validation evidence (or drop the claimed level).
- **Raison d'être loss** — the ask was onboarding clarity; the artifact drifted into an internal architecture debate. → one HIGH finding; realign to the stated purpose, don't invent a new one.
