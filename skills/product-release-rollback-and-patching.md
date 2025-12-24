# Rolling Back and/or Patching a Product Release

This document is intended for AI agents operating within a DocOps Lab environment.

As an AI agent, you can assist DocOps Lab developers in executing product-release patching and rolling back.

Table of Contents

- Rollback Failsafe
- Standard Patching

## Rollback Failsafe

If a release must be rolled back and retracted, you must revert the changes and “yank” the artifacts.

```
git tag -d v<major.minor>.<patch>
git push origin :refs/tags/v<major.minor>.<patch>
git revert -m 1 <merge-commit>
git push origin main
```

Retract or yank the artifacts (DockerHub, RubyGems, etc) and nullify the GH release.

```
gh release delete v<major.minor>.<patch>
gem yank --version <major.minor>.<patch> <gemname>
docker rmi <image>:<major.minor>.<patch>
```

Be sure to un-publish any additional artifacts specific to the project.

## Standard Patching

Perform patch work against the earliest affected `release/x.y`. These examples use `1.1`, `1.2`, and `1.2.1` as example versions.

Patch development procedure

```
git checkout release/1.1
git checkout -b fix/parser-typo
# … FIX …
git add .
git commit -m "fix: correct parser typo"
git push origin fix/parser-typo
# … TEST …
git checkout release/1.1
git merge --squash fix/parser-typo
git commit -m "fix: correct parser typo"
git push origin release/1.1
git tag -a v1.2 -m "Patch release 1.2"
git push origin v1.2
```

Example forward porting procedure

```
git checkout release/1.2
git cherry-pick <commit-hash>
# … TEST …
git push origin release/1.2
git tag -a v1.2.1 -m "Patch release 1.2.1"
git push origin v1.2.1
```

> **NOTE:** Be sure to change `1.1`, `1.2`, and `1.2.1` to the actual affected branches and versions.

Repeat for every affected branch then release the patched versions.

> **NOTE:** Between minor versions, patch versions may vary due to inconsistent applicability of patches.

