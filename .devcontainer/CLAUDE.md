# DevContainer Success Rules

## Project-Specific Rules (from firewall implementation)

1. **Use published feature URLs** - Use `ghcr.io/stardevs/dev-container-features/<feature>:1` not relative paths like `../src/feature`. Relative paths fail in CI.

2. **Include all system packages** - Ensure `install.sh` has all dependencies (e.g., `iproute2` for `ip` command). Missing packages cause silent failures.

3. **Bump versions for releases** - Increment version in `devcontainer-feature.json` (e.g., 1.0.0 → 1.1.0) to trigger new releases. Code changes alone don't republish.

4. **Use docker exec for user control** - Use `docker exec -u root/node` instead of `devcontainer exec` in CI tests. The devcontainer CLI doesn't support `--remote-user`.

5. **Scope sudo to specific scripts** - Create `/etc/sudoers.d/` entries for specific scripts only, not full sudo access. Follow principle of least privilege.

## Generalized Rules for Success

1. **Test in CI what you test locally** - Ensure CI environment matches local assumptions (packages, permissions, capabilities, network access).

2. **Fail fast with clear errors** - Check prerequisites early and provide actionable error messages. Don't let failures cascade silently.

3. **Version everything** - Semantic versioning enables controlled rollouts and easy rollbacks. Tag releases, bump versions for changes.

4. **Principle of least privilege** - Grant minimum permissions needed (scoped sudo, specific Linux capabilities like NET_ADMIN).

5. **Iterate incrementally** - Small commits, quick feedback loops, fix issues one at a time. Don't batch large changes.
