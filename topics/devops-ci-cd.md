# AI Agent Orientation to DocOps Lab DevOps/CI/CD Practices

This document is intended for AI agents operating within a DocOps Lab environment.

DocOps Lab is in a very nascent stage of establishing shared (cross-repo) tools, workflows, and protocols to for automating development, integration, build, and deployment processes.

DocOps Lab uses GitHub Actions and Docker as primary platforms for integration and deployment automation.

For now you can get a good idea for getting started with automation by checking the standard paths in the current project (`Dockerfile`, `docker-compose.yml`, `.github/workflos/`, `Rakefile`, `scripts/`) as well as looking at similar DocOps Lab projects that have more established CI/CD workflows.

The rest of this document is snippets from various relevant internal documentation.

Table of Contents

- Common Automation Scripts
- Docker Usage
- Application Dockerfiles and Images
- See Also

## Common Automation Scripts

Some DocOps Lab projects include highly customized automation scripts, but most contain or employ some common scripts that are primarily stored in this repository and/or deployed as Docker images for universal access during development, testing, and deployment.

These procedures can always be invoked by way of local scripts located in `scripts/`. These include:

- `build.sh`
- `publish.sh`

Common scripts are managed through the lnk:/docs/lab-dev-setup/[`docopslab-dev` gem].

Ruby projects will generally include a `Rakefile` (in the base directory), which automates various Ruby tasks.

## Docker Usage

DocOps Lab projects make extensive use of Docker.

All runtime projects provide have their own Docker image hosted on Docker Hub and sourced in their own repo’s `Dockerfile`. This way a reliable executable is available across all platforms and environments.

Some of our CI/CD pipelines will be “Dockerized” to provide consistent builds and tests across numerous repos.

The DocOps Box project maintains an elaborate Dockerfile and image/container management script (`docksh`) that can help manage multiple environments. This is most advantageous for non-Ruby/non-programmer users building a complex documentation codebase in the Ruby/DocOps Lab ecosystem or using multiple DocOps Lab or similar tools across numerous multiple codebases.

### Application Dockerfiles and Images

Each runtime application project has its own `Dockerfile` in the root of its repository.

This Dockerfile defines the image that will be built and pushed to Docker Hub for use by anyone needing to run the application.

> **NOTE:** Some Dockerfiles combine multiple applications, such as the [issuer-rhx image](https://github.com/DocOps), which combines both the Issuer and ReleaseHx applications.

## See Also

- `./dev-tooling-usage.md`
- `../skills/git.md`

