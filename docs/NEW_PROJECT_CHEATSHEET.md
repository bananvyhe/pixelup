# New Project Cheatsheet

This file is a running checklist of practical fixes that should be applied early when creating a new project from this template.

## 0) Environment strategy (agreed)

- Local development:
  - Run native (no Docker for now).
  - Use project scripts:
    - `make up-native-full`
    - `make down-native`
- Production / VPS:
  - Deploy in Docker.
  - Keep CI image build always enabled.
  - Push image to registry manually when needed (release/deploy moment).
  - Sidekiq is not used in this project, but should remain in template notes for future projects.

## 1) Native startup reliability

- Problem pattern:
  - Frontend opens before backend is ready.
  - Browser shows `ERR_CONNECTION_REFUSED` for API calls.
  - Stale PID files make scripts think services are running when they are not.

- Required baseline:
  - In startup scripts, remove stale PID files if process is not alive (`kill -0` check).
  - Wait for backend health endpoint before reporting success (for Rails: `GET /up`).
  - Fail fast with clear log pointer when backend does not start.

- Implemented in this project:
  - `scripts/native_up.sh`
  - `scripts/native_up_full.sh`

## 2) GitHub Actions: GHCR push

- Problem pattern:
  - `Build and Push Docker Image / build (push)` fails.
  - Wrong/static image name in workflow points to another package/repo.

- Required baseline:
  - Use dynamic image name from repo:
    - `ghcr.io/${{ github.repository }}`
  - Ensure repository Actions permissions allow write for packages.

- Implemented in this project:
  - `.github/workflows/build-image.yml`

## 3) Locked stack and versions

- Pin and keep in sync:
  - Ruby `3.3.5` in:
    - `.ruby-version`
    - `.tool-versions`
  - Node `22.22.0` in:
    - `.node-version`
    - `.tool-versions`
  - Postgres `16.12` in:
    - `.tool-versions`
  - Redis `7.4.8` in:
    - `.tool-versions`
  - Rails and Ruby gems in:
    - `backend/Gemfile.lock`
  - Frontend packages in:
    - `frontend/package-lock.json`
  - Docker build contract in:
    - `backend/Dockerfile` (`ARG RUBY_VERSION`, build args)
    - `.github/workflows/build-image.yml`

- Rule:
  - If tool/package version changes, update all related lock/version files in one commit.
  - Do not leave partial upgrades.

- Source of truth:
  - `docs/STACK.md`

## 4) Background jobs (future projects)

- Current project:
  - Sidekiq is intentionally not used.
- For next projects:
  - Plan Redis + Sidekiq from start.
  - Add process supervision for worker startup/shutdown.
  - In Docker deploy include a separate Sidekiq service/container.
  - In native dev provide dedicated start/stop scripts and PID handling like web process.

## 5) Frontend data loading

- Problem pattern:
  - Data appears missing on first page open.
  - Root cause is usually backend unavailable at startup, not Vue `nextTick`.

-- Required baseline:
  - First fix environment startup reliability.
  - Do not use `nextTick` as a network fix.
  - Add UI retry only if there are proven transient upstream failures.

## 6) SEO baseline

- Required baseline:
  - Correct `<title>` and `<meta name="description">`.
  - OG/Twitter tags.
  - Canonical link.
  - `robots.txt` with sitemap reference.
  - `sitemap.xml` with main public routes.

- Implemented in this project:
  - `frontend/index.html`
  - `frontend/src/packs/router/index.js` (route-level meta updates)
  - `backend/public/robots.txt`
  - `backend/public/sitemap.xml`
