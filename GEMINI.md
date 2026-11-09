# Project Execution Rules for Antigravity

## Git Workflow Rule
- **Automated Commit & Push to `dev`:**
  - After making changes and verifying them with targeted tests and static analysis, automatically stage and commit the changes using a proper, short, descriptive commit message (e.g. `feat: ...`, `fix: ...`, `refactor: ...`, `docs: ...`).
  - Automatically push the commit to the `dev` branch (`git push origin dev`).
  - Follow this behavior consistently for all code/documentation updates unless the user explicitly instructs otherwise (e.g., "do not commit", "do not push").

## Architecture & Code Standards
- Refer to `PROJECT_RULES.md`, `BUILD_STATUS.md`, and `MODULE_INDEX.md` for project conventions, Clean Architecture guidelines, state management standards, and implementation status.
