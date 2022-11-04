#!/bin/sh
set -e

echo "Starting the Jekyll Action"

if [ -n "${INPUT_BUNDLER_VERSION}" ]; then
  echo "Installing bundler version specified by the user."
  gem install bundler -v ${INPUT_BUNDLER_VERSION}
fi 

if [ -n "$INPUT_PRE_BUILD_COMMANDS" ]; then
  echo "Execute pre-build commands specified by the user."
  eval "$INPUT_PRE_BUILD_COMMANDS"
fi 

if [ -z "${INPUT_TOKEN}" ] && [ -n "${JEKYLL_PAT}" ]; then
  echo "::warning::The JEKYLL_PAT environment variable is deprecated. Please use the token parameter"
  INPUT_TOKEN=${JEKYLL_PAT}
fi

if [ -z "${INPUT_TOKEN}" ] && [ "${INPUT_BUILD_ONLY}" != true ]; then
  echo "::error::No token provided. Please set the token parameter."
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
    echo "::error::Found $JEKYLL_FILES_COUNT Jekyll sites from $JEKYLL_SRC! Please define which to use with input variable \"jekyll_src\""
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

if [ -n "${INPUT_JEKYLL_ENV}" ]; then
  echo "::debug::Environment is set via input parameter"
else
  echo "::debug::Environment default in use - production"
  INPUT_JEKYLL_ENV="production"
fi  

# Which branch will be used for publishing? 
# It can be provided, or dectected through API or inferred from the repo name, which is a bit of a legacy behavior.
if [ -n "${INPUT_TARGET_BRANCH}" ]; then
  remote_branch="${INPUT_TARGET_BRANCH}"
  echo "::debug::target branch is set via input parameter"
elif [ -n "${INPUT_TOKEN}" ]; then
  response=$(curl -sH "Authorization: token ${INPUT_TOKEN}" \
                  "https://api.github.com/repos/${GITHUB_REPOSITORY}/pages")
  remote_branch=$(echo "$response" | awk -F'"' '/\"branch\"/ { print $4 }')
  if [ -z "${remote_branch}" ]; then
    echo "::warning::Cannot get GitHub Pages source branch via API."
    echo "::warning::${response}"
  else 
    echo "::debug::using the branch ${remote_branch} set on the repo settings"
  fi
fi

# In case the remote branch was neither provided nor detected via API.
if [ -z "${remote_branch}" ]; then
  case "${GITHUB_REPOSITORY}" in
    *.github.io) remote_branch="master" ;;
    *)           remote_branch="gh-pages" ;;
  esac
  echo "::debug::resolving to ${remote_branch} with a bit of a guess. Maybe we should default to main instead of master?"
fi

echo "Remote branch is ${remote_branch}"



REMOTE_REPO="https://${GITHUB_ACTOR}:${INPUT_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
echo "::debug::Remote is ${REMOTE_REPO}"
if [ -n "${INPUT_BUILD_DIR}" ]; then
  BUILD_DIR="${INPUT_BUILD_DIR}"
else
  BUILD_DIR="${GITHUB_WORKSPACE}/../jekyll_build"
fi

echo "::debug::Build dir is ${BUILD_DIR}"

mkdir -p $BUILD_DIR
cd $BUILD_DIR

if [ -n "${INPUT_TARGET_PATH}" ] && [ "${INPUT_TARGET_PATH}" != '/' ]; then
  TARGET_DIR="${BUILD_DIR}/${INPUT_TARGET_PATH}"
  echo "::debug::target path is set to ${INPUT_TARGET_PATH}"
else
  TARGET_DIR=$BUILD_DIR
fi

if [ "${INPUT_KEEP_HISTORY}" = true ]; then
  echo "::debug::Cloning ${remote_branch} from repo ${REMOTE_REPO}"
  git clone --branch $remote_branch $REMOTE_REPO .
  LOCAL_BRANCH=$remote_branch
  PUSH_OPTIONS=""
  COMMIT_OPTIONS="--allow-empty"
fi

echo "::debug::Local branch is ${LOCAL_BRANCH}"

cd "${GITHUB_WORKSPACE}/${GEM_SRC}"

if [ -z "${INPUT_BUNDLER_VERSION}" ] && [ -f "Gemfile.lock" ]; then 
  echo "Resolving bundler version from Gemfile.lock"
  VERSION_LINE_NUMBER=$(($(cat Gemfile.lock | grep -n 'BUNDLED WITH' | grep -oE '\d+')+1))
  BUNDLER_VERSION=$(head -n ${VERSION_LINE_NUMBER} Gemfile.lock  | tail -n 1 | xargs)
  gem install bundler -v ${BUNDLER_VERSION}
fi

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

JEKYLL_ENV=${INPUT_JEKYLL_ENV} bundle exec ${BUNDLE_ARGS} jekyll build -s ${GITHUB_WORKSPACE}/${JEKYLL_SRC} -d ${TARGET_DIR} ${INPUT_JEKYLL_BUILD_OPTIONS} ${VERBOSE} 
echo "Jekyll build done"

if [ "${INPUT_BUILD_ONLY}" = true ]; then
  exit $?
fi

if [ "${GITHUB_REF}" = "refs/heads/${remote_branch}" ]; then
  echo "::error::Cannot publish on branch ${remote_branch}"
  exit 1
fi

cd ${BUILD_DIR}

# Initializing the repo now to prevent the Jekyll build from overwriting the .git folder 
if [ "${INPUT_KEEP_HISTORY}" != true ]; then
  echo "::debug::Initializing new repo"
  LOCAL_BRANCH="main"
  git init -b $LOCAL_BRANCH
  PUSH_OPTIONS="--force"
  COMMIT_OPTIONS=""
fi

# No need to have GitHub Pages to run Jekyll
touch .nojekyll

echo "Publishing to ${GITHUB_REPOSITORY} on branch ${remote_branch}"

git config user.name "${GITHUB_ACTOR}" && \
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com" && \
git add . && \
git commit $COMMIT_OPTIONS -m "jekyll build from Action ${GITHUB_SHA}" && \
git push $PUSH_OPTIONS $REMOTE_REPO $LOCAL_BRANCH:$remote_branch && \
echo "SHA=$( git rev-parse ${LOCAL_BRANCH} )" >> $GITHUB_OUTPUT
rm -fr .git && \
cd .. 

exit $?
