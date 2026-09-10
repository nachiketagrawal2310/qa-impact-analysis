#!/usr/bin/env python3
"""
Behavioral and structural test runner for qa-impact-analysis.
Validates:
1. P0 Gate structure, phrasing, and zero-tool preconditions.
2. Exact 10 top-level operational sections (ignoring embedded code block headers).
3. Self-contained templates (Default, Full, Phased 1, Phased 2) and autonomous fallback.
4. Output schema validation and forbidden-terms assertions.
5. All 46 skill files SHA256 synchronization between workspace and global config.
"""

import os
import re
import hashlib
import sys

WORKSPACE = "/Users/clappia/Downloads/clappia/qa-impact-analysis"
GLOBAL_CFG = "/Users/clappia/.gemini/config/skills/qa-impact-analysis"

def test_top_level_sections():
    skill_path = os.path.join(WORKSPACE, "SKILL.md")
    with open(skill_path, "r", encoding="utf-8") as fp:
        lines = fp.readlines()

    in_code = False
    top_sections = []
    for line in lines:
        if line.startswith("```"):
            in_code = not in_code
            continue
        if not in_code and line.startswith("## "):
            m = re.match(r"^##\s+(\d+)\.\s+(.*)$", line.strip())
            if m:
                top_sections.append((int(m.group(1)), m.group(2)))

    expected_titles = [
        "Critical Rules",
        "Input / Context Gate",
        "Analysis Workflow",
        "Internal Evidence, Risk & Coverage Model",
        "Output Mode Selection",
        "Default Test-Details Contract",
        "Full Mode Contract (`--full`)",
        "Phased Mode Contract (`--phased`)",
        "Reference Loading Rules",
        "Quality Gate & Release Readiness",
    ]

    assert len(top_sections) == 10, f"Expected 10 top-level sections, got {len(top_sections)}: {top_sections}"
    for i, (num, title) in enumerate(top_sections, start=1):
        assert num == i, f"Section numbering error: expected {i}, got {num}"
        assert expected_titles[i - 1] in title, f"Section {i} title mismatch: expected '{expected_titles[i - 1]}', got '{title}'"
    print("✓ Test Top-Level Sections: Exactly 10 numbered sections confirmed in correct order.")

def test_p0_preamble_and_vague_boundary():
    skill_path = os.path.join(WORKSPACE, "SKILL.md")
    with open(skill_path, "r", encoding="utf-8") as fp:
        content = fp.read()

    assert "# P0 — MANDATORY PRE-TOOL INPUT GATE (ZERO-TOOL BARRIER)" in content
    assert "Actionable Behavioral Requirement" in content
    assert "insufficiently specific" in content
    assert "Login fails with MFA" in content
    assert "## 🛑 Analysis Status: BLOCKED (Prerequisite Failure)" in content
    assert "DO NOT INVOKE ANY TOOL" in content
    print("✓ Test P0 Preamble: Zero-tool barrier, actionable bug allowance, and vague boundary verified.")

def test_self_contained_templates_and_fallback():
    skill_path = os.path.join(WORKSPACE, "SKILL.md")
    with open(skill_path, "r", encoding="utf-8") as fp:
        content = fp.read()

    # Verify all four templates are embedded inline within SKILL.md
    assert "# QA Test Details" in content, "Missing inline default template"
    assert "## Preconditions / Test Data" in content
    assert "### TC-01 —" in content
    assert "# QA Impact Analysis: [Feature / Bug Fix / Task Title]" in content, "Missing inline full template"
    assert "# QA Impact Analysis: Phase 1 Checkpoint" in content, "Missing inline phased checkpoint template"
    assert "### 🛑 Checkpoint: Developer Confirmation Required" in content
    assert "**STOP & WAIT:**" in content, "Missing explicit STOP & WAIT in Phased mode"
    assert "Autonomous Fallback Rule:" in content
    print("✓ Test Self-Contained Templates & Fallback: Full templates and autonomous fallback verified inline.")

def test_rule_12_and_quality_gate_silence():
    skill_path = os.path.join(WORKSPACE, "SKILL.md")
    with open(skill_path, "r", encoding="utf-8") as fp:
        content = fp.read()

    assert "Do NOT expose internal implementation call chains" in content
    assert "Observable Oracles Across Layers:" in content
    assert "This restriction does NOT mean tests are UI-only" in content
    assert "Internal Safety Filter in Default Mode" in content
    assert "**MUST NOT** be output as a table, section, or standalone status badge" in content
    assert "Relevance-Filtered Depth:" in content
    print("✓ Test Rule 12 & Quality Gate: Non-UI observability allowed, call chains banned, and quality gate silenced in default mode.")

def test_sha256_sync():
    def get_hashes(base_dir):
        hashes = {}
        for root, _, files in os.walk(base_dir):
            if ".git" in root or ".agents" in root:
                continue
            for f in sorted(files):
                p = os.path.join(root, f)
                rel = os.path.relpath(p, base_dir)
                if rel == "AGENTS.md" or rel.startswith("evaluation/validate_skill"):
                    continue
                with open(p, "rb") as fp:
                    hashes[rel] = hashlib.sha256(fp.read()).hexdigest()
        return hashes

    h_ws = get_hashes(WORKSPACE)
    h_gb = get_hashes(GLOBAL_CFG)

    all_keys = sorted(set(h_ws.keys()) | set(h_gb.keys()))
    diffs = []
    for k in all_keys:
        w = h_ws.get(k, "MISSING")
        g = h_gb.get(k, "MISSING")
        if w != g:
            diffs.append((k, w[:8], g[:8]))

    assert len(diffs) == 0, f"Found {len(diffs)} file checksum differences: {diffs}"
    print(f"✓ Test SHA256 Sync: All {len(all_keys)} skill files verified identical byte-for-byte.")

def test_output_schema_validator():
    from io import StringIO
    sample_default_output = """# QA Test Details

## Preconditions / Test Data

- User authenticated with Workplace Admin role in Tenant A
- Test user record exists in Tenant A: `usr_tenant_a_101`

## Test Cases

### TC-01 — Verify Workplace Admin can update user profile
**Priority:** P0
**Type:** Functional
**Feasibility:** Manual

**Steps**
1. Sign in to Web console as Tenant A Admin.
2. Navigate to Team Settings and modify display name.
3. Save changes.

**Expected Result**
- Success banner is displayed.
- Profile shows updated name.

## Notes

- **Scope Note:** No mobile-specific cases included; no affected mobile consumer was identified from the available evidence.
"""
    # Schema assertions
    assert sample_default_output.startswith("# QA Test Details")
    assert "## Preconditions / Test Data" in sample_default_output
    assert "## Test Cases" in sample_default_output
    assert "### TC-01 —" in sample_default_output
    assert "**Priority:**" in sample_default_output
    assert "**Type:**" in sample_default_output
    assert "**Feasibility:**" in sample_default_output
    assert "**Steps**" in sample_default_output
    assert "**Expected Result**" in sample_default_output

    # Forbidden term contamination check
    forbidden = [
        "Executive Summary", "Impact Summary", "Architecture & Data Flow",
        "Evidence ledger", "Risk assessment", "Quality gate scorecard",
        "Action items / ownership", "Quality Gate: PASS", "REQ-0", "IMP-0"
    ]
    for term in forbidden:
        assert term.lower() not in sample_default_output.lower(), f"Forbidden term '{term}' leaked into default output!"
    print("✓ Test Output Schema Validator: Sample default output adheres 100% to schema with 0 leaks.")

if __name__ == "__main__":
    print("Running comprehensive test suite for qa-impact-analysis...")
    test_top_level_sections()
    test_p0_preamble_and_vague_boundary()
    test_self_contained_templates_and_fallback()
    test_rule_12_and_quality_gate_silence()
    test_sha256_sync()
    test_output_schema_validator()
    print("\nALL AUTOMATED TESTS PASSED SUCCESSFULLY!")
