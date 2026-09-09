# Evaluation Scenario: Dynamic Feature Flag Rollout

## Scenario Context
- **Developer Request:** "Replaced legacy PDF generation engine with new headless Chrome renderer. Guarded behind feature flag `USE_CHROME_PDF_RENDERER`."
- **Code Modified:**
  - `src/services/pdf.ts`: Checks `if (featureFlags.isEnabled("USE_CHROME_PDF_RENDERER"))`.
  - `src/renderers/chrome.ts`: New rendering engine.
  - `src/renderers/legacy.ts`: Existing rendering engine.

## Evaluation Target
- **Primary Check:** Feature Flag Lifecycle Coverage (Flag OFF, Flag ON, Rollback).
- **Required Verification:**
  - Must generate a test for `Flag = OFF`: verify legacy renderer generates PDF without regression.
  - Must generate a test for `Flag = ON`: verify new Chrome renderer generates PDF with correct layout.
  - Must verify fallback behavior if Chrome renderer crashes: does it fall back to legacy or return an error?
  - Must include memory/timeout boundary test for large multi-page reports.
