# Next CR Template

Use this compact template for future CR prompts.

## Title

`CR-XXXX: <short title>`

## Context

- Current implemented CR baseline
- Relevant current behavior
- Relevant files/components

## Problem

- What is broken or missing
- Why it matters now

## Goal

- Desired outcome in one paragraph

## Scope

- Concrete implementation bullets
- Required docs/validation updates

## MCP

- Use one of: `do not use`, `read-only first`, `allowed scoped edits`.
- State whether native `mcp__godot_ai__...` tools or direct JSON-RPC may be used.
- If writes are allowed, list exactly which scene/node/script/resource actions are in scope.

## Restrictions

- Explicit non-goals for this CR
- Systems that must not be changed
- Editor state restrictions, for example `must stop playing before MCP writes`.
- Whether `scene_save`, `project_run`, `script_patch`, `batch_execute`, or project setting writes are forbidden.

## Acceptance criteria

- Observable manual outcomes
- Required architectural constraints
- For visual CRs, explicit nodes/panels/buttons that must be visible.
- For visual CRs, forbidden overlaps/clipping and expected screen state.

## Validation command

Run after implementation:

`powershell -ExecutionPolicy Bypass -File .\tools\run_validation.ps1`

If validation fails, fix using exact output before completion.

## Manual test

- Step-by-step user test path
- Expected result per step
- Manual screenshot required: yes/no
- If yes, describe the screenshot state that proves acceptance.

## Editor state requirements

- May inspect while playing: yes/no
- Must stop playing before writes: yes/no
- Scene/resource save through editor allowed: yes/no

## Global references

- Follow `AGENTS.md`
- Follow `docs/current_workflow.md`
- Follow `docs/lifecycle_rules.md`
