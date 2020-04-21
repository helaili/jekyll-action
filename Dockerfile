FROM ruby:2.7.1-slim

LABEL version="2.0.1"
LABEL repository="https://github.com/helaili/jekyll-action"
LABEL homepage="https://github.com/helaili/jekyll-action"
LABEL maintainer="Alain Hélaïli <helaili@github.com>"

COPY LICENSE README.md /

# ENV BUNDLER_VERSION 1.17.3
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        git \
        ruby-dev

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
