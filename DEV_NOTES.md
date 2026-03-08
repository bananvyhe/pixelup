# Dev Notes

- Local manual edits from the user in the editor are expected and should be treated as intentional.
- Do not flag unrelated user changes as accidental; only modify files needed for the current task.
- For future projects based on this repo, keep/update the bootstrap cheat sheet:
  - `docs/NEW_PROJECT_CHEATSHEET.md`
- Project rules:
  - Frontend is always `Vue 3 Composition API`.
  - Rails is backend/API and executes all security-sensitive logic.
  - Keep local development environment fully running while working:
    - PostgreSQL
    - Redis
    - Rails
    - Sidekiq
    - Vite frontend
  - Periodic jobs are scheduled through `whenever`, not `sidekiq-cron`.
