# Contributing

## Setup

**Prerequisites:**
- Terraform v1.12+
- AWS CLI with appropriate permissions
- kubectl + helm
- AWS account with GitHub Actions OIDC provider configured

**Local checks before opening a PR:**
```bash
terraform fmt -recursive
terraform init && terraform validate
tfsec .
```

## Branching

| Branch | Purpose |
|--------|---------|
| `main` | Production. Push here triggers terraform apply |
| `feature/*` | New features |
| `fix/*` | Bug fixes |
| `docs/*` | Docs only |

## Pull Request Process

1. Branch off main: `git checkout -b feature/your-feature`
2. Make changes and run local checks
3. Open a PR  CI runs tfsec and posts a plan comment automatically
4. Get a review, then squash merge

## Commit Convention

Follows [Conventional Commits](https://www.conventionalcommits.org/):
```
feat:      new infrastructure component
fix:       broken config or bug
docs:      documentation only
ci:        workflow changes
refactor:  restructure without behaviour change
chore:     deps, formatting
```

## Architecture Decisions

Any significant infrastructure decision needs an ADR in `docs/adr/`.
Copy an existing one as a template  must include Context, Decision,
Alternatives Considered, and Consequences.

## Issues

Open a GitHub Issue with the affected resource, error output, and steps to reproduce.
