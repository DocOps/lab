# AI Agent Instructions for In-house Dev-Tooling Usage

This document is intended for AI agents operating within a DocOps Lab environment.

This guide pertains to the `docopslab-dev` environment. For complete documentation, see the [project’s README]({xref_projects_docops-box_url}).

> **IMPORTANT:** The environment described and provided here is _not_ optimized for DocOps Lab _applications_ used in third-party projects. For your own applications of DocOps Labs products like ReleaseHx and Issuer, see [DocOps Box](/box) for a full-featured docs-focused workspace, runtime, and production environment.

This gem mainly supplies rake tasks for performing common development operations across unified configurations and sub-libraries.

Table of Contents

- Standard Usage
- Override Commands
- More Example Commands
- Tasks and Workflow
- Typical Workflow
- Customization
- Local Overrides

## Standard Usage

Run all linters

```
bundle exec rake labdev:lint:all
```

Auto-fix safe issues

```
bundle exec rake labdev:heal
```

## Override Commands

Most executions of the packaged tools are handled through Rake tasks, but you can always run them directly, especially to pass arguments not built into the tasks.

**RuboCop** :
   ```
   bundle exec rubocop --config .config/rubocop.yml [options]
   bundle exec rubocop --config .config/rubocop.yml --auto-correct-all
   bundle exec rubocop --config .config/rubocop.yml --only Style/StringLiterals
   ```

**Vale** :
   ```
   vale --config=.config/vale.ini [options] [files]
   vale --config=.config/vale.ini README.adoc
   vale --config=.config/vale.ini --minAlertLevel=error .
   ```

**HTMLProofer** :
   ```
   bundle exec htmlproofer --ignore-urls "/www.github.com/,/foo.com/" ./_site
   ```

## More Example Commands

Lint specific Ruby file with specific rule

```
bundle exec rake 'labdev:lint:ruby[lib/myfile.rb,Style/StringLiterals]'
```

Lint all AsciiDoc files for a specific Vale rule

```
bundle exec rake 'labdev:lint:adoc[,DocOpsLab-Authoring.ExNotEg]'
```

Lint specific shell script

```
bundle exec rake 'labdev:lint:bash[scripts/docksh]'
```

Lint specific file with Vale (text mode)

```
bundle exec rake 'labdev:lint:text[_docs/myfile.adoc]'
```

Show a specific lint rule profile

```
bundle exec rake 'labdev:show:rule[vale,RedHat]'
```

## Tasks and Workflow

```
bundle exec rake --tasks | grep labdev:
```

> **TIP:** To hide the `labdev:` tasks from the standard `rake --tasks` output for an integrated project, use:
>
>
>
>
>
> ```
> bundle exec rake --tasks | grep -v labdev:
> ```

### Typical Workflow

This tool is for working on DocOps Lab projects or possibly unrelated projects that wish to follow our methodology. A typical workflow might look as follows.

Normal development

```
git add .
git commit -m "Add new feature"
```

+ This should yield warnings and errors if active linters find issues.

1. Auto-fix what you can.

```
bundle exec rake labdev:heal
```
2. Review the changes.

```
git diff
```
3. Commit the fixes.

```
git add -A
git commit -m "Auto-fix linting issues"
```
4. Handle any remaining manual fixes.

```
bundle exec rake labdev:lint:all
```
5. Fix remaining issues manually.

```
git add -A
git commit -m "Fix remaining linting issues"
```
6. Try pushing.

```
git push
```

If all blocking issues are cleared, the push should succeed. Otherwise, more cleanup is needed.

> **TIP:** Bypass the pre-push gates (usually to test or demo the failure at origin):
>
>
>
>
>
> ```
> git push --no-verify
> ```

## Customization

Override settings by editing the project configs:

- `.config/docopslab-dev.yml`
- `.config/rubocop.yml`
- `.config/vale.ini`
- `.config/htmlproofer.yml`
- `.config/actionlint.yml`
- `.config/shellcheckrc`

Your configurations will inherit from the base configurations and source libraries as sourced in the Git-ignored `.config/.vendor/docopslab/` path.

### Local Overrides

Projects using `docopslab-dev` will have a configuration structure like the following:

```tree
.config/
├── docopslab-dev.yml # Project manifest (tracked)
├── actionlint.yml # Project config (tracked; inherits from base)
├── htmlproofer.local.yml # Project config (tracked; inherits from base)
├── htmlproofer.yml # Generated config (untracked)
├── rubocop.yml # Project config (tracked; inherits from base)
├── shellcheckrc # ShellCheck config (tracked)
├── vale.ini # Generated active config (untracked)
├── vale.local.ini # Project config (tracked; inherits from base)
├── .vendor/ # Base configs (untracked; synced)
│ └── docopslab/
│ ├── htmlproofer.yml # Centrally managed base
│ ├── rubocop.yml # Centrally managed base
│ └── vale.ini # Centrally managed base
scripts/ # Project override scripts
    └── .vendor/ # Centrally managed scripts
.github/workflows/ # CI/CD workflows (tracked)
env.docopslab # Environment variables (git tracked)
env.private # Environment variables (git ignored)
```

