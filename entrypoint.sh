#!/bin/sh
set -e

echo "Starting the Jekyll Action"

if [ -z "${JEKYLL_PAT}" ]; then
  echo "::error::No token provided. Please set the JEKYLL_PAT environment variable."
  exit 1
fi 

if [ -n "${INPUT_JEKYLL_SRC}" ]; then
  JEKYLL_SRC="${INPUT_JEKYLL_SRC}"
  echo "::debug::Source directory is set via input parameter"
elif [ -n "${SRC}" ]; then
  JEKYLL_SRC=${SRC}
  echo "::debug::Source directory is set via SRC environment var"
else
  JEKYLL_SRC=$(find . -path '*/vendor/bundle' -prune -o -name '_config.yml' -exec dirname {} \;)
  JEKYLL_FILES_COUNT=$(echo "$JEKYLL_SRC" | wc -l)
  if [ "$JEKYLL_FILES_COUNT" != "1" ]; then
    echo "::error::Found $JEKYLL_FILES_COUNT Jekyll sites! Please define which to use with input variable \"jekyll_src\""
    echo "$JEKYLL_SRC"
    exit 1
  fi
  JEKYLL_SRC=$(echo $JEKYLL_SRC | tr -d '\n')
  echo "::debug::Source directory is found in file system"
fi
echo "::debug::Using \"${JEKYLL_SRC}\" as a source directory"

if [ -n "${INPUT_GEM_SRC}" ]; then
  GEM_SRC="${INPUT_GEM_SRC}"
  echo "::debug::Gem directory is set via input parameter"
elif [ -f "${JEKYLL_SRC}/Gemfile" ]; then
  GEM_SRC="${JEKYLL_SRC}"
  echo "::debug::Gem directory is set via source directory"
fi

if [ -z "${GEM_SRC}" ]; then
  GEM_SRC=$(find . -path '*/vendor/bundle' -prune -o -name Gemfile -exec dirname {} \;)
  GEM_FILES_COUNT=$(echo "$GEM_SRC" | wc -l)
  if [ "$GEM_FILES_COUNT" != "1" ]; then
    echo "::error::Found $GEM_FILES_COUNT Gemfiles! Please define which to use with input variable \"gem_src\""
    echo "$GEM_SRC"
    exit 1
  fi
  GEM_SRC=$(echo $GEM_SRC | tr -d '\n')
  echo "::debug::Gem directory is found in file system"
fi
echo "::debug::Using \"${GEM_SRC}\" as Gem directory"

cd $GEM_SRC

bundle config path "$PWD/vendor/bundle"
echo "::debug::Bundle config set succesfully"
bundle install
echo "::debug::Completed bundle install"

VERBOSE=""
if [ "${JEKYLL_DEBUG}" = true ]; then
  # Activating debug for Jekyll
  echo "::debug::Jekyll debug is on"
  VERBOSE="--verbose"
else 
  echo "::debug::Jekyll debug is off"
fi

JEKYLL_ENV=production bundle exec ${BUNDLE_ARGS} jekyll build -s ${GITHUB_WORKSPACE}/${JEKYLL_SRC} -d build ${VERBOSE}
echo "Jekyll build done"

if [ "${INPUT_BUILD_ONLY}" = true ]; then
  exit $?
fi

cd build

# No need to have GitHub Pages to run Jekyll
touch .nojekyll


if [ -n "${INPUT_TARGET_BRANCH}" ]; then
  remote_branch="${INPUT_TARGET_BRANCH}"
  echo "::debug::target branch is set via input parameter"
else
  # Is this a regular repo or an org.github.io type of repo
  case "${GITHUB_REPOSITORY}" in
    *.github.io) remote_branch="master" ;;
    *)           remote_branch="gh-pages" ;;
  esac
fi

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
