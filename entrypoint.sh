#!/bin/sh
set -e

echo "Starting the Jekyll Action"

if [ -z "${JEKYLL_PAT}" ]; then
  echo "::error::No token provided. Please set the JEKYLL_PAT environment variable."
  exit 1
fi 

BUNDLE_ARGS=""

if [ -n "${INPUT_JEKYLL_SRC}" ]; then
  JEKYLL_SRC="${INPUT_JEKYLL_SRC}"
  echo "::debug::Source directory is set via input parameter"
elif [ -n "${SRC}" ]; then
  JEKYLL_SRC=${SRC}
  echo "::debug::Source directory is set via SRC environment var"
else
  JEKYLL_SRC=$(find . -path '*/vendor/bundle' -prune -o -name '_config.yml' -exec dirname {} \;)
  echo "::debug::Source directory is found in file system"
fi
echo "::debug::Using \"${JEKYLL_SRC}\" as a source directory"

if [ -n "${INPUT_GEM_SRC}" ]; then
  GEM_SRC="${INPUT_GEM_SRC}"
  echo "::debug::Gem directory is set via input parameter"
elif [ -f "${JEKYLL_SRC}/Gemfile.lock" ]; then
  GEM_SRC="${JEKYLL_SRC}"
  echo "::debug::Gem directory is set via source directory"
fi

if [ -z "${GEM_SRC}" ]; then
  GEM_SRC=$(find . -path '*/vendor/bundle' -prune -o -name Gemfile.lock -exec dirname {} \;)
  GEM_FILES_COUNT=$(echo "$GEM_SRC" | wc -l)
  if [ "$GEM_FILES_COUNT" != "1" ]; then
    echo "::error::Found $GEM_FILES_COUNT Gemfiles! Please define which to use with input variable \"GEM_SRC\""
    echo "$GEM_SRC"
    exit 1
  fi
  GEM_SRC=$(echo $GEM_SRC | tr -d '\n')
  echo "::debug::Gem directory is found in file system"
fi
echo "::debug::Using \"${GEM_SRC}\" as Gem directory"

BUNDLE_ARGS="$BUNDLE_ARGS --gemfile $GEM_SRC/Gemfile"

echo "::debug::Starting bundle install with BUNDLE_ARGS=${BUNDLE_ARGS}"
bundle config set deployment true
bundle config path "$PWD/vendor/bundle"
bundle install ${BUNDLE_ARGS}
echo "::debug::Completed bundle install"

cp $GEM_SRC/Gemfile* .

JEKYLL_ENV=production bundle exec ${BUNDLE_ARGS} jekyll build -s ${JEKYLL_SRC} -d build
echo "Jekyll build done"

cd build

# No need to have GitHub Pages to run Jekyll
touch .nojekyll

# Is this a regular repo or an org.github.io type of repo
case "${GITHUB_REPOSITORY}" in
  *.github.io) remote_branch="master" ;;
  *)           remote_branch="gh-pages" ;;
esac

if [ "${GITHUB_REF}" = "refs/heads/${remote_branch}" ]; then
  echo "::error::Cannot publish on branch ${remote_branch}"
  exit 1
fi

echo "Publishing to ${GITHUB_REPOSITORY} on branch ${remote_branch}"
echo "::debug::Pushing to https://${JEKYLL_PAT}@github.com/${GITHUB_REPOSITORY}.git"

remote_repo="https://${JEKYLL_PAT}@github.com/${GITHUB_REPOSITORY}.git" && \
git init && \
git config user.name "${GITHUB_ACTOR}" && \
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com" && \
git add . && \
git commit -m "jekyll build from Action ${GITHUB_SHA}" && \
git push --force $remote_repo master:$remote_branch && \
rm -fr .git && \
cd .. 

exit $?
