---
name: structured-output-schema-design
description: Rules for designing JSON schemas that reliably pass through Claude's grammar-constrained decoding. Load when designing agent output schemas, debugging StructuredOutput failures, or seeing stop_reason=tool_use errors.
---

# Structured Output Schema Design Rules

Reference for designing JSON schemas that reliably pass through Claude's grammar-constrained decoding. Derived from Anthropic's official documentation and observed failure modes in multi-agent systems.

## How It Works Under the Hood

Structured outputs compile your JSON schema into a grammar artifact. At each token, the grammar masks out tokens that would produce invalid JSON for your schema. The compiled grammar is cached for 24 hours from last use. Changing the schema structure, the tool set, or switching between output_config.format and strict: true invalidates the cache and triggers recompilation.

Grammar state resets between sections. Extended thinking, tool calls, and tool results are unconstrained. The grammar only applies to Claude's direct output (final response or tool call arguments).

There is a compilation timeout of 180 seconds. Schemas that pass all explicit checks but produce very large compiled grammars may hit this timeout.

## Hard Limits (API-Enforced)

| Limit | Value | Notes |
|-------|-------|-------|
| Strict tools per request | 20 | Only tools with strict: true count. Non-strict tools are exempt. |
| Total optional parameters | 24 | Across ALL strict schemas in a single request. Each field not in required counts. |
| Parameters with union types | 16 | Fields using anyOf or type arrays (e.g., ["string", "null"]). Exponentially expensive to compile. |

These limits are cumulative. Four strict tools with 6 optional params each = 24, hitting the ceiling even though no single tool looks complex.

## Supported JSON Schema Features

- All basic types: object, array, string, number, integer, boolean, null
- enum and const
- required
- Nested objects
- $ref definitions (for reusable sub-schemas)
- additionalProperties: false

## NOT Supported

- minimum, maximum, minLength, maxLength (stripped by SDK, moved to descriptions)
- minItems, maxItems on arrays
- patternProperties
- if / then / else
- oneOf (use anyOf instead)
- not
- Most format values (only a limited set of string formats are supported)
- default values

The Python and TypeScript SDKs auto-transform schemas: they remove unsupported constraints, update field descriptions with the constraint info (e.g., "Must be at least 100"), add additionalProperties: false to all objects, and validate the response against the original schema post-generation.

## Property Ordering Behavior

Required properties appear first (in schema-defined order), then optional properties (in schema-defined order). This is not configurable.

Given:
```json
{
  "properties": { "notes": {}, "name": {}, "email": {}, "age": {} },
  "required": ["name", "email"]
}
```

Output order will be: name, email, notes, age.

If output order matters to your application, mark all fields as required.

## Invalid Output Scenarios

Even with constrained decoding, output may not match your schema in two cases:

1. **Refusal** (stop_reason: "refusal"): Safety refusal takes precedence over schema constraints. You still get billed.
2. **Token limit** (stop_reason: "max_tokens"): Output truncated before completion. Retry with higher max_tokens.

## Complexity Failure Modes (Observed, Not Documented)

These are the practical failure patterns from running complex schemas through constrained decoding, ordered by severity.

### 1. Long Arrays of Complex Objects (Worst Case)

An array of 10+ objects, each with multiple fields, is the primary failure mode. The grammar must track "am I still in the array or closing it?" at every item boundary. Each item resets the full object grammar. By item 8 or 9, the model's natural generation pressure (wanting to wrap up) fights the grammar's structural requirements.

**Symptoms:** stop_reason: tool_use after retries, or error_max_structured_output_retries.

**Mitigation:** Cap arrays at 5-7 items per schema. If you need more, split across multiple calls or write to a file and return only metadata through the schema.

### 2. Deep Nesting with Optional Fields

Each level of nesting adds bracket-tracking overhead. Optional fields at each level create a combinatorial explosion of valid-at-this-token paths. The grammar's state space roughly doubles for each optional field in a nested context.

**Mitigation:** Flatten where possible. Prefer 2 levels max. Make fields required unless they are genuinely sometimes absent.

### 3. Union Types (anyOf, nullable fields)

Each union parameter creates branching paths in the compiled grammar. The 16-parameter limit on union types exists because they are "especially expensive" and "create exponential compilation cost." Even within the limit, heavy use of nullable fields ("type": ["string", "null"]) adds up.

**Mitigation:** Avoid nullable fields unless the data genuinely can be absent. Use empty string "" or sentinel values instead of null where semantics allow.

### 4. Enum Fields with Many Values

A field with 3-4 enum values is fine. 20+ enum values narrows the token mask at that position but doesn't cascade. The issue is more about token-level generation friction than grammar compilation.

**Mitigation:** Keep enums under 10 values. If you need more, use a free string field with validation on your side.

### 5. Large Flat Objects (Mostly Fine)

20 string fields on a single flat object is easier than 5 objects nested 3 deep. The grammar is linear, not recursive. This is the safest shape for complex output.

## Schema Design Rules (Prioritized)

### Rule 1: Minimize Array Length

Arrays of complex objects are the #1 reliability killer. If your output naturally has 12+ items, either:
- Split into multiple calls (each returning 3-5 items)
- Write the array to a file and return metadata through the schema
- Paginate: return a fixed-size batch with a continuation token

### Rule 2: Flatten Aggressively

```json
// BAD: 3 levels deep with optionals
{
  "findings": [{
    "details": {
      "context": {
        "file": "string",
        "line": "integer | null"
      }
    }
  }]
}

// GOOD: flat
{
  "findings": [{
    "file": "string",
    "line": "integer",
    "detail": "string"
  }]
}
```

### Rule 3: Make Fields Required

Every optional field roughly doubles a portion of the grammar's state space. If a field always has a reasonable value, make it required. Use empty string or zero as defaults rather than making the field optional.

### Rule 4: Avoid Nullable Types

"type": ["string", "null"] counts toward the 16-parameter union limit AND adds grammar branching. Prefer empty string over null.

### Rule 5: Keep Enums Small

Under 10 values. If classification needs more granularity, use a free string with post-hoc validation.

### Rule 6: Use additionalProperties: false

Always. The SDK adds this automatically, but being explicit prevents ambiguity in the grammar.

### Rule 7: One Strict Schema Per Concept

Don't combine unrelated data in one schema. If you need findings AND metadata AND summary, consider whether those should be separate calls with simple schemas rather than one call with a complex schema.

## Debugging Strategies

### Symptom: stop_reason: tool_use After Retries

The model called the StructuredOutput tool but the grammar couldn't produce valid output. The SDK retried internally and gave up.

Check:
- Array length in your schema. Are you asking for 10+ items?
- Nesting depth. More than 2 levels?
- Optional field count. Above 10?
- Total schema size. Simplify and test incrementally.

### Symptom: error_max_structured_output_retries

Same root cause as above but surfaced through the Agent SDK's error reporting.

### Symptom: Schema is too complex for compilation (400 Error)

The compiled grammar exceeds internal size limits. This fires before any generation attempt.

Check:
- Count strict tools * optional params. Are you near the limits?
- Count union-typed fields across all schemas.
- Simplify or split into multiple requests.

### Symptom: Compilation Timeout (180s)

Schema compiles but takes too long. Usually means deeply nested optional structures or many union types interacting.

### Symptom: Model Burns Turns Before Producing Output

The model keeps calling tools (reading files, running commands) instead of transitioning to structured output. This is a prompt issue, not a schema issue.

Fix: Add explicit budget hints: "You have at most N tool calls. After analysis, produce your output." Or add a "planning" step where the model declares what it will investigate before starting.

### Incremental Testing

When a schema fails, bisect:
1. Start with a minimal schema (2-3 required string fields). Confirm it works.
2. Add one dimension at a time: more fields, an array, nesting, optionals.
3. Find the threshold where it breaks.
4. Redesign that dimension (flatten, split, cap array size).

## The File-Write Escape Hatch

For complex output that exceeds what constrained decoding handles reliably:

1. Let the agent write full JSON to a file (unconstrained, using the Write tool)
2. Return only a flat manifest through the structured output schema:

```json
{
  "type": "object",
  "properties": {
    "phase": { "type": "string" },
    "output_path": { "type": "string" },
    "item_count": { "type": "integer" },
    "status": { "type": "string", "enum": ["complete", "partial", "error"] }
  },
  "required": ["phase", "output_path", "item_count", "status"],
  "additionalProperties": false
}
```

This trivial schema will never choke the grammar. Your orchestrator reads the file and validates with Pydantic after the fact. You trade "guaranteed valid on first try" for "virtually always valid, with a cheap retry if not."

## Compatibility Notes

- **Works with:** Batch processing, token counting, streaming, combined JSON output + strict tool use.
- **Incompatible with:** Citations (returns 400), message prefilling (deprecated on 4.5+).
- **Extended thinking:** Grammar applies only to final output. Thinking blocks are unconstrained.

## Quick Reference: Schema Complexity Budget

| Dimension | Safe | Risky | Likely Failure |
|-----------|------|-------|----------------|
| Array items | 1-5 | 6-9 | 10+ |
| Nesting depth | 1-2 | 3 | 4+ |
| Optional fields | 0-5 | 6-15 | 16+ |
| Union-typed fields | 0-3 | 4-10 | 11+ |
| Enum values per field | 2-8 | 9-15 | 16+ |
| Total flat fields | 1-20 | 21-40 | 40+ |

When multiple dimensions are in the "risky" range simultaneously, expect intermittent failures. The interactions are multiplicative, not additive.
