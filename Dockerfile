FROM ruby:2-slim

LABEL version="1.0.0"
LABEL repository="https://github.com/helaili/jekyll-action"
LABEL homepage="https://github.com/helaili/jekyll-action"
LABEL maintainer="Alain Hélaïli <helaili@github.com>"

LABEL "com.github.actions.name"="Jekyll Action"
LABEL "com.github.actions.description"="A GitHub Action to build and publish Jekyll sites to GitHub Pages"
LABEL "com.github.actions.icon"="book"
LABEL "com.github.actions.color"="blue"
COPY LICENSE README.md /

ENV BUNDLER_VERSION 1.17.3
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        bats \
        build-essential \
        ca-certificates \
        curl \
        libffi6 \
        make \
        shellcheck \
        libffi6 \
        git-all \
    && bundle config --global silence_root_warning 1

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
