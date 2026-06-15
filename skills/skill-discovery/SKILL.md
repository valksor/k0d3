---
name: skill-discovery
description: Routing table — given a topic keyword, returns recommended skill slugs to load. Auto-generated; do not edit body.
last-generated: "2026-06-15T22:38:34Z"
metadata:
  type: meta
  status: active
  invokes_shell: false
  shell_reviewed: "valksor 2026-06-02"
  related: [using-k0d3]
---

# Skill discovery

When the user mentions a topic, look up here. Each row maps a keyword to one or more relevant skill slugs. To add manual routing entries, add a `keywords:` field to the target skill's frontmatter and regenerate via `bash scripts/generate-skill-graph.sh` — manual edits to this file will be overwritten.

| Keyword | Skills |
|---|---|
| a11y | ux-wcag-a11y |
| abbreviation | tooling-shell-fish |
| abbreviations | tooling-shell-fish |
| access | orm-overview |
| accessibility | frontend-charts, ux-wcag-a11y |
| accessible | frontend-radix-ui |
| accessing | go-pgx |
| ack | tooling-ripgrep |
| acp | acp-protocol |
| across | mcp-protocol, orm-overview |
| action | ci-github-actions, frontend-react-router |
| actions | ci-github-actions, frontend-react-router |
| actix | rust-axum-actix |
| actual | root-cause |
| actually | requirements-gathering, testing-fuzzing-mutation |
| adc | python-gcp-clients |
| add | secrets-kms |
| adding | go-slog, observability-essentials, tooling-fzf |
| adopting | frontend-shadcn-ui |
| adr | technical-writing |
| advanced | tooling-git-advanced |
| after | brainstorming, incident-response, planning |
| against | claude-api |
| agent | acp-protocol, agent-design, dispatching-parallel-agents, go-langchaingo |
| agents | dispatching-parallel-agents, go-langchaingo |
| alembic | migrations-overview |
| alert | incident-response |
| alerting | infra-prometheus-grafana |
| allow-plugin | php-composer |
| allow-plugins | php-composer |
| alloy | observability-loki-alloy |
| alpine | infra-docker-images |
| alt-c | tooling-fzf |
| alternative | tooling-eslint-prettier |
| ambiguou | requirements-gathering |
| ambiguous | requirements-gathering |
| analysi | debugging |
| analysis | debugging |
| android | ts-capacitor |
| annotation | go-sqlc |
| annotations | go-sqlc |
| ant | frontend-ant-design, frontend-react-hook-form |
| antd | frontend-ant-design |
| anthropic | claude-api, go-anthropic |
| anthropic-sdk-go | go-anthropic |
| any | debugging, go-essentials, llm-essentials, php-essentials, python-essentials, rust-essentials, security, tdd, typescript |
| anyhow | rust-cli |
| aof | database-redis |
| api | bun-essentials, claude-api, frontend-msw, gdscript, go-anthropic, graphql-essentials, infra-gotenberg, python-django, python-fastapi, python-openai-sdk, python-strawberry-graphql, rest-essentials, secrets-kms, technical-writing |
| api-docs | technical-writing |
| apis | bun-essentials, frontend-msw, gdscript, graphql-essentials, python-django, python-fastapi, python-strawberry-graphql, rest-essentials |
| app | frontend-feature-sliced-design, infra-docker-compose, php-symfony, ts-capacitor, ts-electron, ts-tauri |
| apply | frontend-tailwind |
| applying | frontend-feature-sliced-design |
| approle | secrets-vault |
| approved | brainstorming, planning, subagent-driven-development |
| apps | infra-docker-compose, php-symfony, ts-electron, ts-tauri |
| apscheduler | python-job-queues |
| arbitrary | frontend-tailwind |
| architecting | agent-design |
| architecture | architecture-essentials, architecture-event-driven-cqrs, frontend-design-essentials, ux-essentials |
| are | brainstorming, commit-writer |
| aria | ux-wcag-a11y |
| arq | python-job-queues |
| artifact | ci-gitlab-ci |
| artifacts | ci-gitlab-ci |
| aschild | frontend-radix-ui |
| ask | receiving-code-review |
| asset | game-dev-essentials, rust-cli |
| asset-mapper | php-symfony |
| assets | rust-cli |
| association | php-doctrine |
| associations | php-doctrine |
| assume | requirements-gathering |
| assumes | requirements-gathering |
| assuming | receiving-code-review |
| async | architecture-event-driven-cqrs, frontend-react-hook-form, python-essentials, python-job-queues, python-openai-sdk, python-testing, rust-async-tokio, typescript |
| async-api | python-fastapi |
| atla | migrations-overview |
| atlas | migrations-overview |
| attr | go-slog |
| attribute | observability-opentelemetry, php-essentials, php-symfony, php-testing |
| attribute-mapped | php-doctrine |
| attributes | observability-opentelemetry, php-essentials, php-testing |
| attrs | go-slog |
| audio | game-dev-essentials |
| auditing | ux-wcag-a11y |
| auth | python-gcp-clients, python-keycloak-oidc, secrets-vault, security |
| authn | security |
| authz | graphql-essentials, security |
| auto-update | ts-electron |
| autoload | php-composer |
| autowiring | php-symfony |
| avoidance | php-doctrine, python-strawberry-graphql |
| aws | secrets-kms |
| axum | rust-axum-actix |
| axum-first | rust-axum-actix |
| back | root-cause, using-git-worktrees |
| backend | python-keycloak-oidc, ts-tauri |
| backoff | websocket-essentials |
| base | infra-distroless |
| base-image | infra-docker-images |
| based | testing-property-based |
| basemodel | python-pydantic-v2 |
| bash | tooling-shell-fish |
| basic | observability-loki-alloy, sql |
| basics | observability-loki-alloy, sql |
| batch | claude-api |
| beat | frontend-daisyui, tooling-ripgrep |
| beats | frontend-daisyui, tooling-ripgrep |
| before | brainstorming, debugging, deploy-checklist, receiving-code-review, requirements-gathering, tdd, using-git-worktrees |
| behavior | debugging, game-dev-essentials, refactoring |
| benchmark | go-testing |
| benchmarks | go-testing |
| better | tooling-fzf |
| bigquery | python-gcp-clients |
| binding | infra-cloudflare-workers, rust-gdext, tooling-fzf |
| bindings | infra-cloudflare-workers, tooling-fzf |
| biome | tooling-eslint-prettier |
| bisect | tooling-git-advanced |
| bite-sized | planning |
| blameless | incident-response |
| block | infra-nginx |
| blocks | infra-nginx |
| bodie | commit-writer |
| bodies | commit-writer |
| bottleneck | node-essentials |
| bottlenecks | node-essentials |
| boundarie | frontend-react-router, testing-fuzzing-mutation, ts-zod |
| boundaries | frontend-react-router, testing-fuzzing-mutation, ts-zod |
| boundary | react |
| bounded | observability-essentials |
| brainstorming | brainstorming, planning, requirements-gathering |
| branch | finishing-a-development-branch |
| brand | typescript |
| brands | typescript |
| breadcrumb | observability-sentry |
| breadcrumbs | observability-sentry |
| break | go-essentials, incident-response, php-essentials, python-essentials |
| breaks | incident-response |
| bridge | ts-capacitor |
| brief | concise-output |
| brotli | infra-nginx |
| browser | frontend-msw, tooling-playwright-cli, ts-vitest |
| bubble | go-bubbletea-charm |
| bubbles | go-bubbletea-charm |
| bubbletea | go-bubbletea-charm |
| bug | debugging, root-cause, testing-fuzzing-mutation |
| bugfix | tdd |
| bugs | testing-fuzzing-mutation |
| build | agent-design, ci-github-actions, infra-docker-images, rust-gdext, ts-capacitor, ts-vite |
| building | frontend-ant-design, frontend-pwa-workbox, frontend-radix-ui, frontend-react-hook-form, frontend-tiptap, go-bubbletea-charm, go-chi, go-cobra, go-grpc, go-mcp, godot, graphql-essentials, infra-prometheus-grafana, php-symfony, python-fastapi, python-strawberry-graphql, rust-axum-actix, rust-cli, ts-electron, ts-tauri, ts-zustand, unix-socket-essentials, ux-wcag-a11y |
| builds | ci-github-actions, infra-docker-images |
| bun | bun-essentials |
| bundle | bun-essentials |
| bundled | rust-cli |
| bunx | bun-essentials |
| bus | architecture-event-driven-cqrs |
| busy | database-sqlite-pure-go |
| but | root-cause |
| cache | ci-gitlab-ci, database-redis |
| caches | ci-gitlab-ci |
| caching | ci-github-actions, claude-api, frontend-pwa-workbox, go-anthropic, infra-nginx |
| caddy | infra-frankenphp |
| call | secrets-kms |
| calling | go-anthropic, incident-response, python-openai-sdk |
| calls | secrets-kms |
| cancellation | rust-async-tokio |
| capabilitie | ts-tauri |
| capabilities | ts-tauri |
| capability | acp-protocol, mcp-protocol |
| capacitor | ts-capacitor |
| cardinality | observability-essentials, observability-loki-alloy |
| cargo | rust-essentials |
| cat | commit-writer |
| catch | code-review, testing-fuzzing-mutation |
| categorie | security |
| categories | security |
| cause | debugging, root-cause |
| celery | python-job-queues |
| cgo | database-sqlite-pure-go |
| chain | go-langchaingo, security |
| chains | go-langchaingo |
| change | pr-description |
| changing | refactoring |
| channel | go-concurrency |
| channels | go-concurrency |
| chao | testing-strategy |
| chaos | testing-strategy |
| charm | go-bubbletea-charm |
| chart | frontend-charts |
| charts | frontend-charts |
| checklist | deploy-checklist |
| checkout | go-stripe-sdk, tooling-git-advanced |
| chi | go-chi |
| choosing | infra-docker-images, orm-overview, unix-socket-essentials |
| chromium | infra-gotenberg |
| chunk | ts-vite |
| chunks | ts-vite |
| citation | claude-api |
| citations | claude-api |
| cjs | node-essentials, typescript |
| clap | rust-cli |
| classe | frontend-daisyui, php-essentials |
| classes | frontend-daisyui, php-essentials |
| claude | ci-github-actions, ci-gitlab-ci, claude-api, unix-socket-essentials |
| clean | finishing-a-development-branch |
| clear | brainstorming |
| cli | ci-gitlab-ci, frontend-shadcn-ui, go-cobra, observability-sentry, rust-cli, tooling-playwright-cli |
| client | acp-protocol, go-anthropic, mcp-protocol, python-gcp-clients |
| clients | mcp-protocol, python-gcp-clients |
| clis | go-cobra |
| clone | tooling-git-advanced |
| cloudflare | infra-cloudflare-workers |
| cluster | database-redis |
| cobra | go-cobra |
| code | brainstorming, code-review, frontend-design-essentials, go-grpc, go-sqlc, infra-prometheus-grafana, planning, receiving-code-review, refactoring, rust-testing, security, tdd, tooling-ripgrep, unix-socket-essentials |
| code-first | python-strawberry-graphql |
| collaboration | frontend-tiptap |
| collector | observability-opentelemetry |
| color | frontend-design-essentials |
| come | tooling-jq |
| coming | root-cause |
| command | architecture-event-driven-cqrs, go-cobra, tooling-jq, tooling-playwright-cli, ts-tauri |
| commands | architecture-event-driven-cqrs, ts-tauri |
| comment | code-review |
| commit | commit-writer, refactoring, tooling-git-advanced |
| commits | refactoring |
| common | database-redis, frontend-charts, infra-distroless, infra-gotenberg, infra-nginx, node-essentials, python-data-pipeline, python-keycloak-oidc, python-pydantic-v2 |
| completion | go-cobra, tooling-shell-fish |
| completions | go-cobra, tooling-shell-fish |
| component | frontend-daisyui, frontend-design-essentials, frontend-radix-ui |
| components | frontend-radix-ui |
| compose | infra-docker-compose, infra-gotenberg |
| composer | php-composer |
| composition | frontend-msw, frontend-radix-ui, go-chi, react, ts-zustand |
| comprehensive | planning |
| concise | concise-output |
| concurrency | database-sqlite-pure-go, go-concurrency, rust-async-tokio |
| concurrent | dispatching-parallel-agents, go-concurrency, rust-testing |
| concurrently | dispatching-parallel-agents |
| config | frontend-tailwind, go-sqlc, infra-docker-swarm, infra-frankenphp, infra-prometheus-grafana, observability-loki-alloy, observability-opentelemetry, python-pydantic-v2, tooling-eslint-prettier, ts-jest, ts-vitest |
| configprovider | frontend-ant-design |
| configs | infra-docker-swarm, infra-prometheus-grafana |
| configuring | infra-nginx, python-ruff-mypy, tooling-eslint-prettier, tooling-shell-fish, ts-vite |
| consistency | architecture-event-driven-cqrs |
| console | php-symfony |
| constraint | php-composer, ux-essentials |
| constraints | php-composer, ux-essentials |
| container | go-testcontainers, infra-distroless |
| containers | go-testcontainers, infra-distroless |
| content | frontend-tiptap |
| content-disposition | storage-object-s3 |
| context | go-concurrency, go-slog, llm-essentials, observability-sentry, ts-electron |
| context-first | go-chi |
| contract | rest-essentials |
| contracts | rest-essentials |
| contrast | ux-wcag-a11y |
| control | godot |
| controller | frontend-react-hook-form |
| convention | observability-opentelemetry, project-memory |
| conventions | observability-opentelemetry, project-memory |
| copy | go-pgx |
| copy-paste | frontend-shadcn-ui |
| core | ts-capacitor |
| correlation | go-slog |
| cost | go-testcontainers, llm-essentials, python-gcp-clients, python-openai-sdk, secrets-kms |
| cover | migrations-overview, orm-overview |
| coverage | testing-strategy, ts-vitest |
| coverage-guided | testing-fuzzing-mutation |
| covers | migrations-overview, orm-overview |
| cqr | architecture-event-driven-cqrs |
| cqrs | architecture-event-driven-cqrs |
| createbrowserrouter | frontend-react-router |
| credential | secrets-vault |
| credentials | secrets-vault |
| criterion | rust-testing |
| cross-account | secrets-kms |
| cross-session | project-memory |
| css | frontend-radix-ui, frontend-tailwind |
| css-first | frontend-tailwind |
| cte | sql |
| ctes | sql |
| ctrl-r | tooling-fzf |
| ctrl-t | tooling-fzf |
| current | concise-output, technical-writing, using-git-worktrees |
| custom | frontend-tiptap |
| customization | frontend-daisyui |
| daily | tooling-jq |
| daisyui | frontend-daisyui, frontend-shadcn-ui |
| dashboard | infra-prometheus-grafana |
| data | frontend-react-router, php-testing, python-data-pipeline, ts-zod |
| database | database-redis, database-sqlite-pure-go, orm-overview, postgres |
| dataloader | graphql-essentials |
| dataset | frontend-charts |
| datasets | frontend-charts |
| deadline | go-grpc |
| deadlines | go-grpc |
| debian | infra-docker-images |
| debugging | debugging, infra-distroless |
| deciding | testing-strategy |
| decision | architecture-essentials, frontend-charts, project-memory, python-data-pipeline |
| decisions | architecture-essentials, project-memory |
| deep | gdscript |
| deeper | tooling-git-advanced |
| default | architecture-essentials |
| defining | infra-docker-compose |
| dep | pnpm-essentials, python-uv |
| depend | python-fastapi |
| dependencie | php-composer |
| dependencies | php-composer |
| dependency | python-uv |
| depends | python-fastapi |
| deploy | deploy-checklist, infra-docker-compose |
| deployment | infra-cloudflare-workers, infra-docker-compose |
| deps | pnpm-essentials, python-uv |
| derive | rust-cli, rust-gdext |
| descent | tooling-jq |
| description | pr-description |
| design | agent-design, brainstorming, database-redis, frontend-ant-design, frontend-design-essentials, frontend-feature-sliced-design, frontend-react-hook-form, graphql-essentials |
| designing | architecture-event-driven-cqrs, claude-api, game-dev-essentials, llm-essentials, mcp-protocol, postgres, rest-essentials, ux-essentials, websocket-essentials |
| desktop | ts-electron, ts-tauri |
| detect | finishing-a-development-branch |
| dev | game-dev-essentials, infra-cloudflare-workers, ts-vite |
| development | finishing-a-development-branch, subagent-driven-development |
| dialogue | brainstorming |
| dialoguer | rust-cli |
| difference | tooling-shell-fish |
| differences | tooling-shell-fish |
| discard | finishing-a-development-branch |
| discriminated | python-pydantic-v2 |
| dispatch | code-review |
| dispatching | dispatching-parallel-agents |
| dispatching-parallel-agent | subagent-driven-development |
| dispatching-parallel-agents | subagent-driven-development |
| distroless | infra-distroless, infra-docker-images |
| django | python-django, python-strawberry-graphql |
| django-stub | python-ruff-mypy |
| django-stubs | python-ruff-mypy |
| doc | rust-testing, technical-writing |
| docker | infra-docker-compose, infra-docker-images, infra-docker-swarm, infra-frankenphp, infra-gotenberg |
| dockerfile | infra-docker-images |
| dockerfiles | infra-docker-images |
| docs | technical-writing |
| doctrine | php-doctrine |
| document | python-document-pipeline |
| documentation | technical-writing |
| docx | python-document-pipeline |
| docxcompose | python-document-pipeline |
| docxtpl | python-document-pipeline |
| doe | pr-description |
| does | pr-description |
| domain | dispatching-parallel-agents, unix-socket-essentials |
| don | go-essentials, php-essentials, python-essentials, root-cause |
| done | finishing-a-development-branch |
| double | php-testing |
| doubles | php-testing |
| down | deploy-checklist |
| dql | php-doctrine |
| dramatiq | python-job-queues |
| drf | python-django, python-keycloak-oidc |
| driven | architecture-event-driven-cqrs, subagent-driven-development |
| driving | tooling-playwright-cli |
| drizzle | migrations-overview, orm-overview |
| durable | concise-output, infra-cloudflare-workers |
| dynamic | secrets-vault |
| e2e | testing-strategy |
| echart | frontend-charts |
| echarts | frontend-charts |
| economic | llm-essentials |
| economics | llm-essentials |
| ecosystem | go-bubbletea-charm |
| ecs | game-dev-essentials |
| edge | testing-strategy |
| edges | testing-strategy |
| editor | acp-protocol, frontend-tiptap |
| electron | ts-electron |
| electron-builder | ts-electron |
| embedding | go-langchaingo |
| embeddings | go-langchaingo |
| encryption | secrets-kms, storage-object-s3 |
| engine | infra-gotenberg |
| engine-agnostic | game-dev-essentials |
| engineering | technical-writing |
| engines | infra-gotenberg |
| entitie | frontend-feature-sliced-design, php-doctrine, project-memory |
| entities | frontend-feature-sliced-design, php-doctrine, project-memory |
| entitymanager | php-doctrine |
| enum | php-essentials |
| enums | php-essentials |
| env | tooling-shell-fish, ts-vite |
| envelope | acp-protocol, mcp-protocol, secrets-kms |
| environment | finishing-a-development-branch |
| error | frontend-react-router, go-concurrency, go-essentials, go-grpc, go-mcp, mcp-protocol, rest-essentials, rust-axum-actix, rust-essentials, ts-zod, ux-essentials |
| errors | go-essentials, go-mcp, mcp-protocol, rust-essentials |
| eslint | tooling-eslint-prettier |
| esm | node-essentials, typescript |
| especially | receiving-code-review |
| essentials | architecture-essentials, bun-essentials, frontend-design-essentials, game-dev-essentials, go-essentials, graphql-essentials, llm-essentials, node-essentials, observability-essentials, php-essentials, pnpm-essentials, python-essentials, rest-essentials, rust-essentials, unix-socket-essentials, ux-essentials, websocket-essentials |
| eval | agent-design, llm-essentials |
| evaluating | ux-essentials |
| event | architecture-event-driven-cqrs, node-essentials |
| events | architecture-event-driven-cqrs |
| eventual | architecture-event-driven-cqrs |
| everything | tooling-fzf |
| exact | concise-output, planning |
| execute | finishing-a-development-branch, subagent-driven-development |
| executing | using-git-worktrees |
| exist | pr-description |
| exists | pr-description |
| expiration | database-redis |
| explain | commit-writer, sql |
| exploit | security |
| export | godot, rust-gdext |
| exports | godot, rust-gdext |
| extended | claude-api |
| extension | frontend-tiptap, godot |
| extensions | frontend-tiptap, godot |
| extract | commit-writer |
| extractor | rust-axum-actix |
| extractors | rust-axum-actix |
| fact | project-memory |
| facts | project-memory |
| failing | tdd |
| failure | agent-design, code-review, debugging |
| failures | code-review |
| fall | using-git-worktrees |
| fallback | frontend-pwa-workbox, unix-socket-essentials |
| falls | using-git-worktrees |
| fast-check | testing-property-based |
| fastapi | python-fastapi |
| feature | frontend-feature-sliced-design, llm-essentials, postgres, tdd, using-git-worktrees |
| feature-sliced | frontend-feature-sliced-design |
| features | frontend-feature-sliced-design, postgres |
| federation | graphql-essentials, python-strawberry-graphql |
| feedback | receiving-code-review |
| fetching | frontend-tanstack-query |
| field | python-pydantic-v2 |
| field-level | graphql-essentials |
| figma | frontend-design-essentials |
| file | claude-api, go-essentials, go-sqlc, infra-docker-compose, planning, tooling-ripgrep |
| files | claude-api, go-sqlc, infra-docker-compose, planning |
| filesystem | unix-socket-essentials |
| filtering | tooling-jq |
| finding | tooling-fzf |
| finishing | finishing-a-development-branch |
| first | commit-writer, requirements-gathering, tdd |
| fish | tooling-shell-fish |
| fisher | tooling-shell-fish |
| fit | frontend-shadcn-ui |
| fits | frontend-shadcn-ui |
| fix | debugging, incident-response |
| fixe | debugging |
| fixed | game-dev-essentials, root-cause |
| fixes | debugging |
| fixture | php-testing, python-testing |
| fixtures | php-testing, python-testing |
| flag | deploy-checklist, go-cobra, tooling-fzf, typescript |
| flags | deploy-checklist, go-cobra, typescript |
| flaky | testing-strategy |
| flat | tooling-eslint-prettier |
| flow | frontend-pwa-workbox |
| focu | ux-wcag-a11y |
| focus | ux-wcag-a11y |
| focused | pr-description |
| force | root-cause |
| forces | root-cause |
| form | frontend-ant-design, frontend-react-hook-form, php-symfony |
| format | python-ruff-mypy |
| forms | frontend-react-hook-form |
| four | debugging |
| frame | python-data-pipeline |
| frames | python-data-pipeline |
| framework | python-django |
| framework-bundle | php-symfony |
| framing | websocket-essentials |
| frankenphp | infra-frankenphp, php-symfony |
| free-form | go-slog |
| frequent | refactoring |
| fresh | subagent-driven-development |
| frontend | frontend-ant-design, frontend-charts, frontend-daisyui, frontend-design-essentials, frontend-feature-sliced-design, frontend-msw, frontend-pwa-workbox, frontend-radix-ui, frontend-react-hook-form, frontend-react-router, frontend-shadcn-ui, frontend-tailwind, frontend-tanstack-query, frontend-tiptap, react, ts-tauri |
| frontends | frontend-tailwind, react |
| fsd | frontend-feature-sliced-design |
| full | orm-overview, planning |
| function | tooling-shell-fish |
| functions | tooling-shell-fish |
| future | rust-async-tokio |
| futures | rust-async-tokio |
| fuzzing | go-testing, rust-testing, testing-fuzzing-mutation |
| fuzzy | tooling-fzf |
| fzf | tooling-fzf |
| game | game-dev-essentials |
| gate | brainstorming |
| gathering | requirements-gathering |
| gcp | python-gcp-clients, secrets-kms |
| gcs | python-gcp-clients, storage-object-s3 |
| gdext | rust-gdext |
| gdextension | godot |
| gdscript | gdscript |
| gdscript-performance | gdscript |
| generating | go-sqlc, python-document-pipeline |
| generation | go-grpc |
| generator | testing-property-based |
| generators | testing-property-based |
| generic | go-essentials, python-keycloak-oidc |
| generics | go-essentials |
| git | commit-writer, tooling-git-advanced, using-git-worktrees |
| github | ci-github-actions |
| gitlab | ci-gitlab-ci |
| gitlab-ci | ci-gitlab-ci |
| glab | ci-gitlab-ci |
| glob | tooling-ripgrep |
| globs | tooling-ripgrep |
| go-ergonomic | go-langchaingo |
| go-sqlite3 | database-sqlite-pure-go |
| goal | requirements-gathering |
| godot | gdscript, godot, rust-gdext |
| godot-rust | rust-gdext |
| godotclass | rust-gdext |
| gof | architecture-essentials |
| google-cloud- | python-gcp-clients |
| goose | migrations-overview |
| goroutine | go-concurrency |
| goroutines | go-concurrency |
| gotcha | bun-essentials, python-data-pipeline, sql |
| gotchas | bun-essentials, python-data-pipeline, sql |
| gotenberg | infra-gotenberg, python-document-pipeline |
| grafana | infra-prometheus-grafana, observability-loki-alloy |
| grant | secrets-kms |
| grants | secrets-kms |
| graphql | frontend-msw, graphql-essentials, python-strawberry-graphql |
| green | refactoring |
| grep | tooling-ripgrep |
| group | go-concurrency, python-uv, tooling-jq |
| groups | go-concurrency, python-uv |
| grpc | go-grpc |
| guardrail | llm-essentials, python-gcp-clients, python-openai-sdk |
| guardrails | llm-essentials, python-gcp-clients, python-openai-sdk |
| guide | technical-writing |
| gzip | infra-nginx |
| hand-rolled | frontend-daisyui |
| handler | frontend-msw, go-chi, go-slog |
| handlers | frontend-msw, go-chi |
| handling | rust-axum-actix, ts-zod |
| harden | security |
| hardening | security |
| harnesse | agent-design, llm-essentials |
| harnesses | agent-design, llm-essentials |
| has | testing-property-based |
| hashicorp | secrets-vault |
| headed | tooling-playwright-cli |
| headless | ci-gitlab-ci, tooling-playwright-cli |
| healthcheck | infra-docker-compose, infra-nginx |
| healthchecks | infra-docker-compose, infra-nginx |
| heartbeat | websocket-essentials |
| heartbeats | websocket-essentials |
| helper | go-testing |
| helpers | go-testing |
| heuristic | ux-essentials |
| heuristics | ux-essentials |
| hexagonal | architecture-essentials |
| hold | testing-property-based |
| hook | frontend-react-hook-form, frontend-react-router, php-essentials, react |
| hooks | frontend-react-router, php-essentials, react |
| hot | infra-frankenphp |
| how | pr-description |
| html | infra-gotenberg, ux-wcag-a11y |
| http | go-chi, infra-gotenberg, python-document-pipeline, python-fastapi, rust-axum-actix |
| hurt | frontend-feature-sliced-design |
| hurts | frontend-feature-sliced-design |
| hypothesi | debugging, testing-property-based |
| hypothesis | debugging, testing-property-based |
| iam | secrets-kms |
| idempotency | go-stripe-sdk |
| identity | python-gcp-clients |
| ids | go-slog |
| image | infra-distroless, infra-docker-images, infra-frankenphp, python-document-pipeline |
| images | infra-docker-images, infra-frankenphp, python-document-pipeline |
| imperative | commit-writer |
| implementation | brainstorming, debugging, dispatching-parallel-agents, finishing-a-development-branch, planning, subagent-driven-development, tdd, using-git-worktrees |
| implementing | receiving-code-review, tdd |
| in-place | tooling-ripgrep |
| in-session | subagent-driven-development |
| in-source | ts-vitest |
| incident | incident-response |
| independent | dispatching-parallel-agents |
| indexe | postgres |
| indexes | postgres |
| indexing | sql |
| infer | ts-zod |
| inference | ts-zustand |
| infinite | frontend-tanstack-query |
| information | ux-essentials |
| infra | infra-cloudflare-workers, infra-distroless, infra-docker-compose, infra-docker-images, infra-docker-swarm, infra-frankenphp, infra-gotenberg, infra-nginx, infra-prometheus-grafana |
| init | go-anthropic, observability-sentry, rust-gdext |
| input | testing-property-based |
| inputs | testing-property-based |
| install | bun-essentials, frontend-pwa-workbox, frontend-shadcn-ui |
| instrumenting | observability-opentelemetry |
| integrate | finishing-a-development-branch |
| integrating | acp-protocol, go-langchaingo, go-stripe-sdk, python-keycloak-oidc, secrets-vault |
| integration | ci-github-actions, frontend-ant-design, frontend-msw, frontend-react-hook-form, frontend-tiptap, go-cobra, go-sqlc, go-testcontainers, python-strawberry-graphql, rust-testing, testing-strategy, tooling-eslint-prettier, tooling-fzf |
| interceptor | go-grpc |
| interceptors | go-grpc |
| interop | node-essentials, python-data-pipeline, typescript |
| into | brainstorming, python-keycloak-oidc |
| invalidation | frontend-tanstack-query |
| invariant | testing-property-based |
| invariants | testing-property-based |
| invent | commit-writer |
| investigation | dispatching-parallel-agents, subagent-driven-development |
| investigations | dispatching-parallel-agents |
| ipc | ts-electron, ts-tauri, unix-socket-essentials |
| iron | tdd |
| isolation | architecture-essentials, sql, ts-electron, using-git-worktrees |
| its | refactoring |
| java | infra-distroless |
| jest | ts-jest |
| job | python-job-queues |
| join | sql |
| joins | sql |
| json | go-slog, python-openai-sdk, tooling-jq, tooling-ripgrep |
| json-rpc | acp-protocol, mcp-protocol |
| jsonb | postgres |
| jwk | python-keycloak-oidc |
| jwks | python-keycloak-oidc |
| jwt | secrets-vault |
| k0d3 | concise-output |
| k8s | secrets-vault |
| kafka | go-testcontainers |
| keepalive | go-pgx |
| keepalives | go-pgx |
| keeps | root-cause |
| kept | technical-writing |
| kerneltestcase | php-testing |
| key | frontend-tanstack-query, go-stripe-sdk, python-gcp-clients, secrets-kms, tooling-fzf |
| keyboard | ux-wcag-a11y |
| keycloak | python-keycloak-oidc |
| keys | frontend-tanstack-query, go-stripe-sdk, python-gcp-clients |
| keyspace | database-redis |
| kms | secrets-kms |
| know | pr-description, root-cause |
| knowledge graph | project-memory |
| knowledge-graph | project-memory |
| known | requirements-gathering |
| label | observability-loki-alloy |
| land | incident-response |
| lands | incident-response |
| langchaingo | go-langchaingo |
| language | mcp-protocol |
| languages | mcp-protocol |
| large | frontend-charts |
| law | tdd |
| layer | frontend-design-essentials, frontend-feature-sliced-design, orm-overview |
| layout | go-essentials, python-essentials |
| lazy | python-data-pipeline |
| lazy-loading | frontend-react-router |
| lease | secrets-vault |
| lib | frontend-charts |
| libreoffice | infra-gotenberg |
| lifecycle | frontend-pwa-workbox, gdscript, go-testcontainers, storage-object-s3 |
| limiting | rest-essentials |
| line | tooling-jq, tooling-playwright-cli |
| lint | python-ruff-mypy |
| linter | frontend-feature-sliced-design |
| linting | php-quality |
| lipgloss | go-bubbletea-charm |
| listen | postgres, python-job-queues |
| live | incident-response |
| llm | agent-design, go-langchaingo, llm-essentials |
| llm-backed | llm-essentials |
| llms | go-langchaingo |
| load | python-gcp-clients |
| loader | frontend-react-router |
| loaders | frontend-react-router |
| local | infra-cloudflare-workers, project-memory, unix-socket-essentials |
| locale | frontend-ant-design |
| locator | tooling-playwright-cli |
| locators | tooling-playwright-cli |
| lockfile | pnpm-essentials, python-uv |
| log | commit-writer, observability-essentials, observability-loki-alloy |
| logging | go-slog, observability-essentials |
| logql | observability-loki-alloy |
| logs | observability-essentials, observability-loki-alloy |
| loki | observability-loki-alloy |
| loom | rust-testing |
| loop | agent-design, go-bubbletea-charm, node-essentials, tooling-playwright-cli |
| loopback | unix-socket-essentials |
| machine | game-dev-essentials |
| machines | game-dev-essentials |
| main | ts-electron |
| make | tooling-fzf |
| makes | tooling-fzf |
| making | architecture-essentials |
| management | ux-wcag-a11y |
| manager | tooling-shell-fish |
| managing | php-composer, python-uv |
| mandatory | brainstorming |
| manifest | frontend-pwa-workbox |
| manual | ts-vite, using-git-worktrees |
| many | testing-property-based |
| map | observability-sentry |
| mapping | tooling-jq |
| maps | observability-sentry |
| mark | frontend-tiptap |
| mark3lab | go-mcp |
| mark3labs | go-mcp |
| markdown | infra-gotenberg |
| marks | frontend-tiptap |
| matching | frontend-msw |
| matrix | ci-github-actions, frontend-charts, python-data-pipeline |
| matter | gdscript |
| mattn | database-sqlite-pure-go |
| mcp | go-mcp, mcp-protocol, project-memory |
| mcp memory | project-memory |
| mcp-go | go-mcp |
| measuring | testing-fuzzing-mutation |
| memory | agent-design, project-memory |
| merge | finishing-a-development-branch |
| message | claude-api, commit-writer, go-anthropic, go-bubbletea-charm, go-slog |
| messages | claude-api, go-anthropic, go-bubbletea-charm, go-slog |
| messaging | ux-essentials |
| method | secrets-vault |
| methods | secrets-vault |
| metric | observability-essentials |
| metrics | observability-essentials |
| middleware | go-chi, rust-axum-actix, ts-zustand |
| migration | bun-essentials, database-sqlite-pure-go, deploy-checklist, go-sqlc, migrations-overview, observability-loki-alloy, php-doctrine, python-django, python-pydantic-v2 |
| migrations | deploy-checklist, go-sqlc, migrations-overview, php-doctrine, python-django, python-pydantic-v2 |
| minimum-stability | php-composer |
| minio | storage-object-s3 |
| missing | code-review |
| mobile | ts-capacitor |
| mobile-first | ux-essentials |
| mock | frontend-msw |
| mockery | php-testing |
| mocking | frontend-msw, python-testing, ts-jest, ts-vitest |
| mode | agent-design, database-redis, database-sqlite-pure-go, go-stripe-sdk, infra-frankenphp, python-ruff-mypy, ts-vite, ts-vitest |
| model | claude-api, database-sqlite-pure-go, frontend-feature-sliced-design, frontend-shadcn-ui, go-bubbletea-charm, go-grpc, python-django, python-pydantic-v2 |
| modeling | rest-essentials |
| models | go-bubbletea-charm, python-django |
| modernc | database-sqlite-pure-go |
| modes | agent-design, ts-vite |
| modular | architecture-essentials |
| module | go-essentials |
| modules | go-essentials |
| monitoring | observability-essentials, observability-sentry |
| monolith | architecture-essentials |
| monorepo | bun-essentials, pnpm-essentials, tooling-eslint-prettier |
| msw | frontend-msw |
| multi-container | infra-docker-compose |
| multi-package | go-sqlc |
| multi-stage | infra-docker-images |
| multi-task | subagent-driven-development |
| multi-tenant | observability-loki-alloy |
| multipart | storage-object-s3 |
| multiplayer | godot |
| must | refactoring |
| mutation | frontend-tanstack-query, testing-fuzzing-mutation |
| mutations | frontend-tanstack-query |
| mvc | go-bubbletea-charm |
| mypy | python-ruff-mypy |
| named | project-memory |
| naming | go-essentials, python-essentials |
| native | bun-essentials, ts-capacitor, using-git-worktrees |
| navigation | frontend-react-router, tooling-playwright-cli |
| need | deploy-checklist, pr-description, using-git-worktrees |
| needed | requirements-gathering |
| needs | using-git-worktrees |
| negotiation | acp-protocol, mcp-protocol |
| network | infra-docker-swarm |
| networking | godot |
| networks | infra-docker-swarm |
| never | commit-writer |
| next | react |
| nginx | infra-frankenphp, infra-nginx |
| nielsen | ux-essentials |
| node | bun-essentials, frontend-msw, frontend-tiptap, node-essentials, observability-opentelemetry, typescript |
| nodej | infra-distroless |
| nodejs | infra-distroless |
| nodes | frontend-tiptap |
| non-negotiable | rust-essentials |
| non-negotiables | rust-essentials |
| nonroot | infra-distroless |
| not | agent-design, commit-writer, dispatching-parallel-agents, project-memory |
| note | python-strawberry-graphql |
| notify | postgres, python-job-queues |
| now | concise-output |
| null | sql |
| object | infra-cloudflare-workers, php-doctrine, python-gcp-clients, storage-object-s3 |
| objects | infra-cloudflare-workers, php-doctrine |
| observability | infra-cloudflare-workers, infra-prometheus-grafana, observability-essentials, observability-loki-alloy, observability-opentelemetry, observability-sentry |
| observations | project-memory |
| occurred | root-cause |
| official | go-anthropic |
| offline | frontend-pwa-workbox |
| oidc | ci-github-actions, python-keycloak-oidc |
| onboarding | technical-writing |
| onboarding-guide | technical-writing |
| one | commit-writer, dispatching-parallel-agents, refactoring |
| one-liner | tooling-jq |
| one-liners | tooling-jq |
| oop | game-dev-essentials |
| openai | python-openai-sdk |
| openapi | rest-essentials |
| opening | pr-description |
| openpyxl | python-document-pipeline |
| opentelemetry | observability-essentials, observability-opentelemetry |
| operating | migrations-overview, postgres |
| opinion | architecture-essentials |
| opinions | architecture-essentials |
| ops | python-gcp-clients |
| optimistic | frontend-tanstack-query |
| optimization | sql |
| option | finishing-a-development-branch |
| options | finishing-a-development-branch |
| orchestration | pnpm-essentials |
| org | database-sqlite-pure-go |
| orm | orm-overview, php-doctrine, python-django |
| orms | orm-overview |
| oss-fuzz | testing-fuzzing-mutation |
| output | concise-output, go-anthropic, llm-essentials, python-openai-sdk, tooling-ripgrep |
| outputs | go-anthropic, llm-essentials, python-openai-sdk |
| over | unix-socket-essentials |
| overlay | infra-docker-swarm |
| override | infra-docker-compose |
| overview | migrations-overview, orm-overview |
| owasp | security |
| ownership | rust-essentials |
| package | go-testing, tooling-shell-fish |
| packaging | python-essentials, ts-electron |
| page | frontend-feature-sliced-design |
| pages | frontend-feature-sliced-design |
| panda | python-data-pipeline |
| pandas | python-data-pipeline |
| parallel | dispatching-parallel-agents, ts-vitest |
| parallelism | go-testcontainers |
| param | frontend-react-router |
| parameterization | sql |
| parametrization | python-testing |
| params | frontend-react-router |
| parse-don | ts-zod |
| parser | testing-fuzzing-mutation |
| parsers | testing-fuzzing-mutation |
| partitioning | postgres |
| pass | finishing-a-development-branch |
| past | root-cause |
| patch | pnpm-essentials |
| patching | pnpm-essentials |
| path | php-composer, rust-cli |
| paths | rust-cli |
| pattern | agent-design, architecture-essentials, database-redis, database-sqlite-pure-go, debugging, frontend-charts, frontend-tailwind, gdscript, go-langchaingo, python-gcp-clients, python-testing, tooling-ripgrep, typescript |
| patterns | agent-design, architecture-essentials, database-redis, database-sqlite-pure-go, frontend-charts, frontend-tailwind, gdscript, go-langchaingo, python-gcp-clients, python-testing, tooling-ripgrep, typescript |
| pdf | infra-gotenberg, python-document-pipeline |
| pdfs | python-document-pipeline |
| per | dispatching-parallel-agents, subagent-driven-development |
| perf | gdscript |
| performance | frontend-charts, frontend-react-hook-form, go-bubbletea-charm, node-essentials, observability-sentry, react |
| permission | acp-protocol |
| permissions | acp-protocol |
| persist | project-memory |
| persistence | database-redis |
| persistent | go-cobra, project-memory |
| persisting | php-doctrine |
| pgx | go-pgx |
| pgxpool | go-pgx |
| phase | debugging |
| phases | debugging |
| php | infra-frankenphp, php-composer, php-doctrine, php-essentials, php-quality, php-symfony, php-testing |
| php-cs-fixer | php-quality |
| php-fpm | infra-frankenphp |
| phpstan | php-quality |
| phpunit | php-testing |
| physic | game-dev-essentials, rust-gdext |
| physics | game-dev-essentials, rust-gdext |
| picker | infra-distroless |
| picking | frontend-charts, migrations-overview, python-data-pipeline, python-job-queues |
| pikepdf | python-document-pipeline |
| pillow | python-document-pipeline |
| pinning | infra-distroless |
| pip | python-uv |
| pipeline | ci-gitlab-ci, database-redis, game-dev-essentials, observability-loki-alloy, python-data-pipeline, python-document-pipeline, rust-gdext |
| pipelines | ci-gitlab-ci, database-redis, game-dev-essentials |
| pipenv | python-uv |
| pitfall | frontend-tailwind, infra-distroless, infra-gotenberg, infra-nginx, python-keycloak-oidc |
| pitfalls | frontend-tailwind, infra-distroless, infra-gotenberg, infra-nginx, python-keycloak-oidc |
| placeholder | planning |
| placeholders | planning |
| placement | infra-docker-swarm |
| plan | planning, sql, subagent-driven-development, using-git-worktrees |
| planning | agent-design, planning |
| playwright | tooling-playwright-cli |
| playwright-cli | tooling-playwright-cli |
| plugin | frontend-tailwind, tooling-eslint-prettier, ts-capacitor, ts-tauri, ts-vite |
| plugins | frontend-tailwind, ts-capacitor, ts-tauri, ts-vite |
| pnpm | pnpm-essentials |
| poetry | python-uv |
| point | concise-output |
| polar | python-data-pipeline |
| polars | python-data-pipeline |
| policie | infra-docker-compose, storage-object-s3 |
| policies | infra-docker-compose, storage-object-s3 |
| pool | ts-vitest |
| pooling | postgres |
| pools | ts-vitest |
| postgre | go-pgx, go-testcontainers, postgres, python-job-queues |
| postgres | go-pgx, go-testcontainers, postgres, python-job-queues |
| postgresql | postgres |
| postmortem | incident-response |
| pre-commit | python-ruff-mypy |
| prefer | using-git-worktrees |
| prefers | using-git-worktrees |
| preload | ts-electron |
| prepared | go-pgx |
| present | finishing-a-development-branch |
| presigned | storage-object-s3 |
| prettier | tooling-eslint-prettier |
| preview | tooling-fzf |
| primitive | frontend-radix-ui, frontend-shadcn-ui, go-concurrency |
| primitives | frontend-radix-ui, frontend-shadcn-ui, go-concurrency |
| prisma | migrations-overview, orm-overview |
| process | rust-gdext |
| processing | python-document-pipeline, tooling-jq |
| procrastinate | python-job-queues |
| prod | infra-docker-compose, observability-essentials, postgres, security |
| production | deploy-checklist, incident-response, infra-docker-compose, observability-essentials, postgres, security, tdd |
| profiling | node-essentials |
| project | project-memory |
| prometheu | infra-prometheus-grafana, observability-essentials |
| prometheus | infra-prometheus-grafana, observability-essentials |
| prompt | acp-protocol, claude-api, frontend-pwa-workbox, go-anthropic, go-mcp, mcp-protocol, rust-cli |
| prompts | go-mcp, mcp-protocol, rust-cli |
| promtail | observability-loki-alloy |
| propagation | go-slog, observability-opentelemetry |
| propertie | testing-property-based |
| properties | testing-property-based |
| property | php-essentials, testing-property-based |
| property-based | python-testing |
| proportion | testing-strategy |
| proportions | testing-strategy |
| proposing | debugging |
| proptest | rust-testing, testing-property-based |
| prose | concise-output |
| protobuf | go-grpc |
| protocol | acp-protocol, mcp-protocol |
| provider | go-langchaingo, llm-essentials, php-testing, ts-vitest |
| providers | go-langchaingo, php-testing, ts-vitest |
| provisioning | infra-prometheus-grafana |
| proxy | infra-nginx, ts-vite |
| psr-4 | php-composer |
| pub-sub | websocket-essentials |
| pubsub | database-redis |
| pull | pr-description |
| pure | database-sqlite-pure-go |
| pure-go | database-sqlite-pure-go |
| pwa | frontend-pwa-workbox, ts-capacitor |
| pyarrow | python-data-pipeline |
| pydantic | python-fastapi, python-pydantic-v2 |
| pydantic-setting | python-pydantic-v2 |
| pydantic-settings | python-pydantic-v2 |
| pytest | python-testing |
| pytest-django | python-django |
| python | infra-distroless, observability-opentelemetry, orm-overview, python-data-pipeline, python-django, python-document-pipeline, python-essentials, python-fastapi, python-gcp-clients, python-job-queues, python-keycloak-oidc, python-openai-sdk, python-pydantic-v2, python-ruff-mypy, python-strawberry-graphql, python-testing, python-uv |
| python-jose | python-keycloak-oidc |
| pyvip | python-document-pipeline |
| pyvips | python-document-pipeline |
| quality | php-quality |
| querie | frontend-tanstack-query |
| queries | frontend-tanstack-query |
| query | frontend-tanstack-query, go-sqlc, observability-loki-alloy, python-gcp-clients |
| query-builder | orm-overview |
| query-builders | orm-overview |
| querybuilder | php-doctrine |
| question | requirements-gathering |
| questionable | receiving-code-review |
| questions | requirements-gathering |
| queue | infra-cloudflare-workers, python-job-queues |
| queueing | infra-gotenberg |
| queues | infra-cloudflare-workers, python-job-queues |
| quickcheck | testing-property-based |
| radix | frontend-radix-ui, frontend-shadcn-ui |
| rate | rest-essentials |
| rdb | database-redis |
| reaching | frontend-daisyui, tooling-git-advanced |
| react | frontend-charts, frontend-feature-sliced-design, frontend-react-hook-form, frontend-react-router, frontend-tanstack-query, frontend-tiptap, react, tooling-eslint-prettier, ts-zustand |
| react-hook-form | frontend-ant-design, frontend-react-hook-form |
| react-router | frontend-react-router |
| read | architecture-event-driven-cqrs, technical-writing |
| reader | ux-wcag-a11y |
| readers | ux-wcag-a11y |
| readiness | deploy-checklist |
| reading | sql |
| readme | technical-writing |
| readonly | php-essentials |
| real-time | websocket-essentials |
| recall | project-memory |
| receiving | receiving-code-review |
| rechart | frontend-charts |
| recharts | frontend-charts |
| reconnection | websocket-essentials |
| recorded | project-memory |
| recording | infra-prometheus-grafana |
| recursive | tooling-jq |
| red-green-refactor | tdd |
| redi | database-redis, go-testcontainers |
| redis | database-redis, go-testcontainers |
| ref | tooling-playwright-cli |
| refactoring | refactoring |
| reference | gdscript, technical-writing |
| references | gdscript |
| refinement | ts-zod |
| refinements | ts-zod |
| reflog | tooling-git-advanced |
| register | frontend-react-hook-form |
| release | observability-sentry |
| releases | observability-sentry |
| reload | infra-frankenphp |
| remediation | security |
| remember | project-memory |
| renderer | ts-electron |
| renewal | secrets-vault |
| replacement | tooling-ripgrep |
| replacing | python-uv |
| replication | postgres |
| replie | concise-output |
| replies | concise-output |
| reply | concise-output |
| reportlab | python-document-pipeline |
| repositorie | php-composer |
| repositories | php-composer |
| request | brainstorming, frontend-msw, pr-description, requirements-gathering |
| requesting | code-review |
| requirement | brainstorming |
| requirements | brainstorming, requirements-gathering |
| reqwest | rust-cli |
| rerere | tooling-git-advanced |
| resolver | frontend-react-hook-form |
| resolvers | frontend-react-hook-form |
| resource | go-mcp, mcp-protocol, observability-opentelemetry, rest-essentials |
| resources | go-mcp, mcp-protocol |
| response | frontend-msw, incident-response, python-openai-sdk |
| responses | python-openai-sdk |
| rest | frontend-msw, python-django, rest-essentials |
| restart | infra-docker-compose |
| retention | observability-loki-alloy |
| retrie | go-anthropic, llm-essentials |
| retries | go-anthropic, llm-essentials |
| retry | python-openai-sdk |
| reuse | go-testcontainers |
| reverse | infra-nginx |
| review | code-review, receiving-code-review, subagent-driven-development |
| reviewer | code-review, pr-description |
| reviewers | pr-description |
| reviewing | ci-github-actions, ci-gitlab-ci, code-review, graphql-essentials, rest-essentials, security, sql |
| rich-text | frontend-tiptap |
| ripgrep | tooling-ripgrep |
| rollback | deploy-checklist |
| rolling | infra-docker-swarm |
| root | debugging, root-cause |
| root-cause | debugging |
| rot | code-review |
| rotation | python-keycloak-oidc, secrets-kms, secrets-vault |
| route | frontend-react-router |
| router | frontend-react-router, python-fastapi |
| routers | python-fastapi |
| routing | frontend-react-router, go-chi, php-symfony, rust-axum-actix |
| rsc | react |
| ruff | python-ruff-mypy |
| rule | go-essentials, infra-prometheus-grafana, php-essentials, python-essentials, tooling-eslint-prettier |
| rules | go-essentials, infra-prometheus-grafana, php-essentials, python-essentials, tooling-eslint-prettier |
| run | bun-essentials, go-testing, python-uv |
| runbook | technical-writing |
| runnable | dispatching-parallel-agents |
| runner | ci-gitlab-ci |
| runners | ci-gitlab-ci |
| running | incident-response, infra-docker-swarm, infra-frankenphp, infra-gotenberg |
| runtime | php-symfony |
| rust | godot, rust-async-tokio, rust-axum-actix, rust-cli, rust-essentials, rust-gdext, rust-testing, ts-tauri |
| safety | rust-async-tokio |
| saga | architecture-event-driven-cqrs |
| sagas | architecture-event-driven-cqrs |
| same | root-cause |
| sampling | llm-essentials, observability-opentelemetry |
| sandbox | unix-socket-essentials |
| sast | security |
| satisfie | typescript |
| satisfies | typescript |
| scaling | websocket-essentials |
| scene | godot |
| scenes | godot |
| schema | frontend-react-hook-form, frontend-tiptap, graphql-essentials, migrations-overview, postgres, python-fastapi, python-openai-sdk, python-strawberry-graphql, ts-zod |
| schemas | frontend-tiptap, python-fastapi, ts-zod |
| scrape | infra-prometheus-grafana |
| scratch | infra-docker-images, project-memory |
| screen | ux-wcag-a11y |
| script | php-composer |
| scripting | tooling-shell-fish |
| scripts | php-composer |
| sdd | subagent-driven-development |
| sdk | go-stripe-sdk, observability-opentelemetry, observability-sentry, python-openai-sdk |
| search | frontend-react-router |
| searching | tooling-ripgrep |
| secret | ci-github-actions, infra-docker-compose, infra-docker-swarm, security |
| secrets | ci-github-actions, infra-docker-compose, infra-docker-swarm, secrets-kms, secrets-vault, security |
| security | postgres, security, testing-fuzzing-mutation, ts-electron, unix-socket-essentials |
| see | gdscript |
| select | rust-async-tokio, tooling-jq |
| selection | claude-api, tooling-eslint-prettier |
| selector | ts-zustand |
| selectors | ts-zustand |
| semantic | database-redis, frontend-daisyui, observability-opentelemetry, ux-wcag-a11y |
| semantics | database-redis |
| sentry | observability-sentry |
| sequencing | deploy-checklist |
| sequential | subagent-driven-development |
| serialization | frontend-tiptap |
| serializer | php-symfony |
| serie | commit-writer |
| series | commit-writer |
| server | frontend-tanstack-query, go-mcp, mcp-protocol, project-memory, rust-axum-actix, ts-vite |
| server-action | react |
| server-side | storage-object-s3 |
| servers | mcp-protocol, rust-axum-actix |
| service | frontend-msw, frontend-pwa-workbox, go-chi, go-grpc, infra-docker-compose, infra-docker-swarm, infra-gotenberg |
| services | go-chi, go-grpc, infra-docker-compose, infra-docker-swarm |
| session | concise-output, go-stripe-sdk, tooling-playwright-cli |
| sessions | go-stripe-sdk, tooling-playwright-cli |
| setting | python-django |
| settings | python-django |
| setup | observability-opentelemetry |
| severity | incident-response |
| shadcn | frontend-daisyui, frontend-radix-ui, frontend-react-hook-form, frontend-shadcn-ui |
| shallow | tooling-git-advanced |
| shape | agent-design, claude-api, rest-essentials |
| shapes | claude-api, rest-essentials |
| shared | dispatching-parallel-agents, frontend-feature-sliced-design |
| sharp | architecture-essentials |
| shell | infra-distroless, tooling-shell-fish |
| shine | frontend-feature-sliced-design |
| shines | frontend-feature-sliced-design |
| shipping | deploy-checklist, infra-cloudflare-workers, infra-distroless, observability-loki-alloy |
| should | code-review |
| shrinking | testing-property-based |
| signal | gdscript, godot, rust-gdext, testing-strategy |
| signals | gdscript, godot, rust-gdext |
| signature | go-stripe-sdk |
| signing | secrets-kms, tooling-git-advanced |
| silent | code-review |
| size | infra-docker-images |
| sizing | go-pgx, infra-gotenberg |
| slice | ts-zustand |
| sliced | frontend-feature-sliced-design |
| slog | go-slog |
| small | refactoring |
| snapshot | tooling-playwright-cli, ts-jest, ts-vitest |
| snapshots | tooling-playwright-cli, ts-jest |
| socket | unix-socket-essentials |
| sockets | unix-socket-essentials |
| socratic | brainstorming |
| solid | architecture-essentials |
| source | observability-sentry, tooling-ripgrep |
| sourcing | architecture-event-driven-cqrs |
| spa | react |
| sparse | tooling-git-advanced |
| spawn | rust-async-tokio |
| spec | planning |
| split | architecture-event-driven-cqrs |
| sql | go-sqlc, sql |
| sqlalchemy | orm-overview |
| sqlc | go-sqlc, orm-overview |
| sqlite | database-sqlite-pure-go |
| sqlx | migrations-overview, orm-overview |
| sse | claude-api |
| ssr | react, ts-vite |
| stack | infra-docker-swarm |
| stacks | infra-docker-swarm |
| stampede | database-redis |
| starlette | python-fastapi |
| state | dispatching-parallel-agents, frontend-tanstack-query, game-dev-essentials, rust-axum-actix, ts-zustand |
| statement | go-pgx |
| statements | go-pgx |
| static | infra-distroless |
| static-analysing | php-quality |
| stay | refactoring |
| steiger | frontend-feature-sliced-design |
| step | refactoring |
| steps | refactoring |
| storage | storage-object-s3 |
| store | go-langchaingo |
| stores | go-langchaingo |
| strategie | frontend-pwa-workbox |
| strategies | frontend-pwa-workbox |
| strategy | infra-docker-images, testing-strategy |
| strawberry | python-strawberry-graphql |
| stream | database-redis |
| streaming | claude-api, go-anthropic, go-grpc, python-openai-sdk |
| streams | database-redis |
| strict | php-essentials, python-ruff-mypy |
| strict-mode | typescript |
| stripe | go-stripe-sdk |
| structure | ci-gitlab-ci, refactoring |
| structured | go-anthropic, go-mcp, go-slog, llm-essentials, observability-essentials, python-openai-sdk, rust-async-tokio |
| style | commit-writer, concise-output, frontend-radix-ui |
| sub-router | go-chi |
| sub-routers | go-chi |
| subagent | subagent-driven-development |
| subagent-driven-development | dispatching-parallel-agents |
| subcommand | rust-cli |
| subcommands | rust-cli |
| subject | commit-writer |
| subjects | commit-writer |
| subscription | go-stripe-sdk, graphql-essentials, python-strawberry-graphql |
| subscriptions | go-stripe-sdk, graphql-essentials, python-strawberry-graphql |
| substance | concise-output |
| subtest | go-testing |
| subtests | go-testing |
| suggestion | receiving-code-review |
| suggestions | receiving-code-review |
| supply | security |
| supply-chain | infra-docker-images |
| surface | requirements-gathering |
| suspense | frontend-tanstack-query |
| swarm | infra-docker-swarm |
| swc | ts-jest |
| symfony | php-symfony, php-testing |
| symptom | root-cause |
| sync | go-anthropic, go-concurrency, python-openai-sdk, python-uv |
| syntax | gdscript, tooling-shell-fish |
| system | architecture-event-driven-cqrs, frontend-design-essentials, game-dev-essentials, websocket-essentials |
| systems | architecture-event-driven-cqrs, frontend-design-essentials, game-dev-essentials, websocket-essentials |
| t-validate | ts-zod |
| table | frontend-ant-design |
| table-driven | go-testing |
| tabular | python-data-pipeline |
| tag | observability-sentry |
| tags | observability-sentry |
| tailwind | frontend-daisyui, frontend-radix-ui, frontend-shadcn-ui, frontend-tailwind |
| tanstack | frontend-tanstack-query |
| targeted | requirements-gathering |
| task | planning, subagent-driven-development |
| tasks | planning |
| tauri | ts-tauri |
| tcp | go-pgx, unix-socket-essentials |
| tdd | planning, tdd |
| tea | go-bubbletea-charm |
| technical | technical-writing |
| terminal | acp-protocol |
| termination | infra-nginx |
| terse | concise-output |
| terser | concise-output |
| test | bun-essentials, code-review, debugging, finishing-a-development-branch, go-stripe-sdk, go-testcontainers, go-testing, php-testing, python-testing, refactoring, rust-testing, tdd, testing-fuzzing-mutation, testing-strategy, ts-vitest |
| testcontainers | go-testcontainers |
| testcontainers-go | go-testcontainers |
| testing | go-testing, php-testing, python-django, python-fastapi, python-testing, react, rust-testing, testing-fuzzing-mutation, testing-property-based, testing-strategy, ts-jest |
| tests | code-review, finishing-a-development-branch, go-testcontainers, go-testing, python-testing, refactoring, rust-testing, testing-fuzzing-mutation, ts-vitest |
| that | gdscript, testing-property-based, tooling-fzf, tooling-jq |
| them | deploy-checklist |
| theme | frontend-daisyui |
| themes | frontend-daisyui |
| theming | frontend-ant-design, frontend-shadcn-ui |
| then | finishing-a-development-branch |
| thinking | claude-api |
| thiserror | rust-cli |
| throughout | planning, refactoring |
| tier | agent-design |
| tiers | agent-design |
| time | refactoring |
| timeout | database-sqlite-pure-go, python-openai-sdk |
| timeouts | database-sqlite-pure-go |
| timestep | game-dev-essentials |
| tiptap | frontend-tiptap |
| tls | infra-nginx |
| tmux | tooling-fzf |
| token | concise-output, frontend-design-essentials, llm-essentials, python-keycloak-oidc |
| token-lean | concise-output |
| tokens | concise-output, frontend-design-essentials |
| tokio | rust-async-tokio |
| toml | infra-cloudflare-workers |
| tool | agent-design, claude-api, go-anthropic, go-mcp, mcp-protocol, migrations-overview, python-openai-sdk, using-git-worktrees |
| tooling | security, tooling-eslint-prettier, tooling-fzf, tooling-git-advanced, tooling-jq, tooling-playwright-cli, tooling-ripgrep, tooling-shell-fish |
| tools | go-mcp, mcp-protocol, using-git-worktrees |
| toolset | tooling-git-advanced |
| top | frontend-daisyui |
| trace | observability-essentials |
| traces | observability-essentials |
| tracing | tooling-playwright-cli |
| trade-off | infra-docker-images |
| trade-offs | infra-docker-images |
| trait | rust-essentials |
| traits | rust-essentials |
| transaction | go-pgx, sql |
| transactions | go-pgx, sql |
| transform | ts-jest, ts-zod |
| transformation | refactoring |
| transforms | ts-zod |
| transit | secrets-vault |
| transport | go-mcp, mcp-protocol |
| transports | go-mcp, mcp-protocol |
| tree | game-dev-essentials, go-cobra, tooling-ripgrep |
| trees | game-dev-essentials, tooling-ripgrep |
| tremor | frontend-charts |
| triage | testing-strategy |
| trigger | ci-github-actions, deploy-checklist |
| triggers | ci-github-actions, deploy-checklist |
| trusted | technical-writing |
| tui | go-bubbletea-charm |
| tuis | go-bubbletea-charm |
| turn | acp-protocol, brainstorming |
| turns | acp-protocol |
| twig | php-symfony |
| twig-cs-fixer | php-quality |
| two-stage | subagent-driven-development |
| type | code-review, gdscript, php-essentials, tooling-ripgrep, ts-zod, typescript |
| type-check | python-ruff-mypy |
| typed | go-sqlc |
| types | code-review, gdscript, php-essentials, tooling-ripgrep, ts-zod |
| typescript | react, ts-zod, ts-zustand, typescript |
| typing | python-essentials |
| typography | frontend-design-essentials |
| uds | unix-socket-essentials |
| unclear | receiving-code-review |
| unexpected | debugging |
| union | python-pydantic-v2, typescript |
| unions | python-pydantic-v2, typescript |
| unit | rust-testing, testing-property-based, testing-strategy |
| unix | unix-socket-essentials |
| unstyled | frontend-radix-ui |
| until | brainstorming |
| update | frontend-pwa-workbox, frontend-tanstack-query, go-bubbletea-charm, infra-docker-swarm |
| updates | frontend-tanstack-query, infra-docker-swarm |
| upgrade | python-django |
| upgrades | python-django |
| upload | storage-object-s3 |
| upstream | infra-nginx |
| url | infra-gotenberg, storage-object-s3 |
| urls | storage-object-s3 |
| usefieldarray | frontend-react-hook-form |
| using | database-redis, database-sqlite-pure-go, python-gcp-clients, secrets-kms, storage-object-s3, using-git-worktrees |
| utility-first | frontend-tailwind |
| vague | requirements-gathering |
| validating | ts-zod |
| validation | frontend-react-hook-form, go-cobra, python-fastapi, python-keycloak-oidc |
| validator | php-symfony, python-pydantic-v2 |
| validators | python-pydantic-v2 |
| value | frontend-tailwind |
| values | frontend-tailwind |
| var | tooling-shell-fish, ts-vite |
| vars | tooling-shell-fish, ts-vite |
| vault | secrets-vault |
| vcs | php-composer |
| vector | go-langchaingo |
| verification | go-stripe-sdk |
| verify | finishing-a-development-branch, pr-description, receiving-code-review |
| verifying | deploy-checklist |
| version | infra-distroless, php-composer, python-django |
| version-specific | postgres |
| versioning | rest-essentials |
| view | python-django |
| views | python-django |
| viper | go-cobra |
| virtualization | frontend-ant-design |
| visual | frontend-design-essentials |
| visx | frontend-charts |
| vite | ts-vite |
| vitest | ts-jest, ts-vitest |
| vocabulary | architecture-essentials |
| wal | database-sqlite-pure-go |
| watch | pr-description |
| wcag | ux-wcag-a11y |
| weak | code-review |
| web | ts-capacitor, ts-tauri, ux-wcag-a11y |
| webhook | go-stripe-sdk |
| webhooks | go-stripe-sdk |
| websocket | infra-nginx, websocket-essentials |
| websockets | infra-nginx |
| webtestcase | php-testing |
| what | code-review, commit-writer, pr-description, requirements-gathering, testing-strategy |
| when | acp-protocol, agent-design, architecture-essentials, architecture-event-driven-cqrs, bun-essentials, ci-github-actions, ci-gitlab-ci, claude-api, code-review, commit-writer, concise-output, database-redis, database-sqlite-pure-go, finishing-a-development-branch, frontend-ant-design, frontend-charts, frontend-daisyui, frontend-feature-sliced-design, frontend-msw, frontend-pwa-workbox, frontend-radix-ui, frontend-react-hook-form, frontend-react-router, frontend-shadcn-ui, frontend-tailwind, frontend-tanstack-query, frontend-tiptap, game-dev-essentials, gdscript, go-anthropic, go-bubbletea-charm, go-chi, go-cobra, go-concurrency, go-essentials, go-grpc, go-langchaingo, go-mcp, go-pgx, go-slog, go-sqlc, go-stripe-sdk, go-testcontainers, go-testing, godot, graphql-essentials, incident-response, infra-cloudflare-workers, infra-distroless, infra-docker-compose, infra-docker-images, infra-docker-swarm, infra-frankenphp, infra-gotenberg, infra-nginx, infra-prometheus-grafana, llm-essentials, mcp-protocol, migrations-overview, node-essentials, observability-essentials, observability-loki-alloy, observability-opentelemetry, observability-sentry, orm-overview, php-composer, php-doctrine, php-essentials, php-quality, php-symfony, php-testing, pnpm-essentials, postgres, pr-description, python-data-pipeline, python-django, python-document-pipeline, python-essentials, python-fastapi, python-gcp-clients, python-job-queues, python-keycloak-oidc, python-openai-sdk, python-pydantic-v2, python-ruff-mypy, python-strawberry-graphql, python-testing, python-uv, react, receiving-code-review, refactoring, requirements-gathering, rest-essentials, root-cause, rust-async-tokio, rust-axum-actix, rust-cli, rust-essentials, rust-gdext, rust-testing, secrets-kms, secrets-vault, security, sql, storage-object-s3, tdd, technical-writing, testing-fuzzing-mutation, testing-property-based, testing-strategy, tooling-eslint-prettier, tooling-fzf, tooling-git-advanced, tooling-jq, tooling-playwright-cli, tooling-ripgrep, tooling-shell-fish, ts-capacitor, ts-electron, ts-jest, ts-tauri, ts-vite, ts-vitest, ts-zod, ts-zustand, typescript, unix-socket-essentials, using-git-worktrees, ux-essentials, ux-wcag-a11y, websocket-essentials |
| where | testing-strategy |
| whether | testing-fuzzing-mutation |
| which | code-review |
| whole | concise-output, frontend-design-essentials |
| why | commit-writer, pr-description, root-cause, tooling-ripgrep |
| widget | frontend-feature-sliced-design |
| widgets | frontend-feature-sliced-design |
| window | llm-essentials, sql |
| windows | llm-essentials, sql |
| wiring | php-quality, python-ruff-mypy |
| within-session | project-memory |
| without | debugging, dispatching-parallel-agents, infra-distroless, refactoring, tdd |
| work | finishing-a-development-branch, using-git-worktrees |
| workbox | frontend-pwa-workbox |
| worker | frontend-msw, frontend-pwa-workbox, infra-cloudflare-workers, infra-frankenphp |
| workers | infra-cloudflare-workers |
| workflow | ci-github-actions, tooling-fzf |
| workflows | ci-github-actions |
| working | bun-essentials, frontend-tailwind, node-essentials, observability-sentry, pnpm-essentials, python-django |
| workload | python-gcp-clients |
| workspace | pnpm-essentials, python-uv, ts-vitest, using-git-worktrees |
| workspaces | pnpm-essentials, python-uv |
| worktree | tooling-git-advanced, using-git-worktrees |
| worktrees | using-git-worktrees |
| workup | gdscript |
| workups | gdscript |
| wrangler | infra-cloudflare-workers |
| wrapping | ts-capacitor |
| write | architecture-event-driven-cqrs, planning, pr-description |
| writer | commit-writer |
| writes | pr-description |
| writing | ci-github-actions, ci-gitlab-ci, commit-writer, deploy-checklist, gdscript, go-concurrency, go-essentials, go-testcontainers, go-testing, incident-response, infra-docker-images, php-essentials, python-essentials, python-pydantic-v2, python-testing, react, rust-async-tokio, rust-essentials, security, sql, tdd, technical-writing, ts-vitest, typescript |
| xdg | rust-cli |
| xlsx | python-document-pipeline |
| yaml | go-sqlc |
| yet | root-cause |
| yml | ci-gitlab-ci |
| you | deploy-checklist, frontend-radix-ui, go-essentials, php-essentials, python-essentials, root-cause, technical-writing |
| zed | acp-protocol |
| zod | frontend-react-hook-form, ts-zod |
| zsh | tooling-shell-fish |
| zustand | ts-zustand |
