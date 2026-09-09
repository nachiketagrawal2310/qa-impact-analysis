# Evaluation Scenario: Irrelevant Technology Exclusion (Precision Check)

## Scenario Context
- **Developer Request:** "Changed button label from 'Submit' to 'Send Feedback' and updated CSS padding on the contact form."
- **Repository Inventory:**
  - Contains AWS Terraform files (`infra/*.tf`), DynamoDB models (`src/db/dynamo.ts`), and Lambda handlers (`src/handlers/*.ts`).
- **Files Modified:**
  - `src/components/ContactForm.tsx`: Label and CSS styling change only.

## Evaluation Target
- **Primary Check:** Checklist Inclusion/Exclusion Transparency & Anti-Test-Spam.
- **Required Verification:**
  - `web.md` MUST be loaded.
  - `aws.md`, `database.md`, `state-machines.md`, and `events.md` MUST be **EXCLUDED**.
  - The report must state: *"Excluded aws.md, database.md, and events.md because change is strictly localized to client UI presentation with no backend behavioral impact."*
  - The skill MUST NOT generate AWS/DynamoDB regression test cases.
