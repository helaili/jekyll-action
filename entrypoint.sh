#!/bin/sh
set -eu

echo "Starting the Jekyll Action from ${SRC} to ${DEST}"

bundle install
echo "Done installing"
bundle exec jekyll build -s ${SRC} -d ${DEST}
mkdir ${DEST}
cd ${DEST}
remote_repo="https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" && \
remote_branch="gh-pages" && \
git init && \
git config user.name "${GITHUB_ACTOR}" && \
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com" && \
git add . && \
git commit -m 'jekyll build' > /dev/null 2>&1 && \
git push --force $remote_repo master:$remote_branch > /dev/null 2>&1 && \
rm -fr .git && \
cd ../

echo "Done"
