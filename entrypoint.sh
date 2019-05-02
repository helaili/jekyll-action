#!/bin/bash
set -e

echo "#################################################"
echo "Starting the Jekyll Action"

bundle install
echo "#################################################"
echo "Installion completed"

if [[ -z "${SRC}" ]]; then
  SRC=$(find . -name _config.yml -exec dirname {} \;)
fi

echo "#################################################"
echo "Source for the Jekyll site is set to ${SRC}"

bundle exec jekyll build -s ${SRC} -d build
echo "#################################################"
echo "Jekyll build done"

cd build

# No need to have GitHub Pages to run Jekyll
touch .nojekyll

echo "#################################################"
echo "Now publishing"
if [[ -z "${JEKYLL_PAT}" ]]; then
  TOKEN=${GITHUB_TOKEN}
else 
  TOKEN=${JEKYLL_PAT}
fi

echo ${GITHUB_REPOSITORY} | grep -E '^([a-z]*)\/\1\.github\.io$' > /dev/null
if [ $? -eq 0 ]; then
  remote_branch="master"
else
  remote_branch="gh-pages"
fi

if [ "${GITHUB_REF}" == "refs/heads/${remote_branch}" ]; then
  echo "Cannot publish on branch ${remote_branch}"
  exit 1
else
  echo "Pushing on branch ${remote_branch}"
fi

remote_repo="https://${TOKEN}@github.com/${GITHUB_REPOSITORY}.git" && \
git init && \
git config user.name "${GITHUB_ACTOR}" && \
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com" && \
git add . && \
git commit -m 'jekyll build from Action' && \
git push --force $remote_repo master:$remote_branch && \
rm -fr .git && \
cd ..
