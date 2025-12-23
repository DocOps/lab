FROM ruby:3.2-slim

LABEL Name="DocOps Lab Dev Container" \
      Vendor="DocOps Lab" \
      Version="0.1.0"

ARG DEBIAN_FRONTEND=noninteractive
ARG VALE_VERSION=3.12.0
ARG ACTIONLINT_VERSION=1.7.1

ENV TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_DISABLE_SHARED_GEMS=0

# System packages (single layer, no recommends, clean properly)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      git \
      curl \
      wget \
      build-essential \
      shellcheck \
      jq \
      tree \
      fd-find \
      ripgrep \
      python3-pip \
      yamllint \
      pre-commit \
    && rm -rf /var/lib/apt/lists/*

# Vale
RUN set -euo pipefail; \
    wget -O- "https://github.com/errata-ai/vale/releases/download/v${VALE_VERSION}/vale_${VALE_VERSION}_Linux_64-bit.tar.gz" \
    | tar -xz -C /usr/local/bin vale

# actionlint
RUN set -euo pipefail; \
    wget -O- "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz" \
    | tar -xz -C /usr/local/bin actionlint

# Create non-root user
RUN groupadd --gid 1000 docops && \
    useradd --uid 1000 --gid docops --shell /bin/bash --create-home docops

WORKDIR /workspace
RUN chown docops:docops /workspace

# Copy only what’s needed to resolve our gem’s deps up front,
#  for better cache use
COPY --chown=docops:docops docopslab-dev.gemspec Gemfile* /tmp/docopslab-dev/
COPY --chown=docops:docops lib/docopslab/dev/version.rb /tmp/docopslab-dev/lib/docopslab/dev/

USER docops

# Install bundler 2.7.2
RUN gem install --no-document bundler -v 2.7.2

# Install our gem’s dependencies into the image (system path)
RUN cd /tmp/docopslab-dev && \
    bundle install --jobs 4 --retry 3

# Common global tools we want available for everyone (system path)
RUN gem install --no-document asciidoctor rake

COPY --chown=docops:docops . /tmp/docopslab-dev

# Now build and install your gem into the image
RUN cd /tmp/docopslab-dev && \
    gem build docopslab-dev.gemspec && \
    gem install docopslab-dev-*.gem && \
    gem cleanup

# Entrypoint
USER root
COPY --chown=root:root scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER docops
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
