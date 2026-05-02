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

## Restrictions

- Explicit non-goals for this CR
- Systems that must not be changed

## Acceptance criteria

- Observable manual outcomes
- Required architectural constraints

## Validation command

Run after implementation:

`powershell -ExecutionPolicy Bypass -File .\tools\run_validation.ps1`

If validation fails, fix using exact output before completion.

## Manual test

- Step-by-step user test path
- Expected result per step

## Global references

- Follow `AGENTS.md`
- Follow `docs/current_workflow.md`
- Follow `docs/lifecycle_rules.md`
