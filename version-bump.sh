#!/bin/bash

# Directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#
# Takes a version number, and the mode to bump it, and increments/resets
# the proper components so that the result is placed in the variable
# `NEW_VERSION`.
#
# $1 = mode (major, minor, patch)
# $2 = version (x.y.z)
#
function bump {
  local mode="$1"
  local old="$2"
  local parts=( ${old//./ } )
  case "$1" in
    major)
      local bv=$((parts[0] + 1))
      NEW_VERSION="${bv}.0.0"
      ;;
    minor)
      local bv=$((parts[1] + 1))
      NEW_VERSION="${parts[0]}.${bv}.0"
      ;;
    patch)
      local bv=$((parts[2] + 1))
      NEW_VERSION="${parts[0]}.${parts[1]}.${bv}"
      ;;
    esac
}

git config --global user.email $EMAIL
git config --global user.name $NAME

OLD_VERSION=$($DIR/get-version.sh)

BUMP_MODE="patch"
if git log -1 | grep -q "major"; then
  BUMP_MODE="major"
elif git log -1 | grep -q "minor"; then
  BUMP_MODE="minor"
elif git log -1 | grep -q "patch"; then
  BUMP_MODE="patch"
fi

if [[ "${PR}" == "true" ]];
then
  echo $BUMP_MODE "version bump detected"
  bump $BUMP_MODE $OLD_VERSION
  PR_VERSION="${NEW_VERSION}"
  echo "pom.xml at" $POMPATH "will be bumped from" $OLD_VERSION "to" $PR_VERSION
  mvn -q versions:set -DnewVersion=${PR_VERSION}
  git add $POMPATH/pom.xml
  REPO="https://$GITHUB_ACTOR:$TOKEN@github.com/$GITHUB_REPOSITORY.git"
  git commit -m "Bump pom.xml from $OLD_VERSION to $PR_VERSION"
  git push $REPO
else
#  echo $BUMP_MODE "version bump detected on a push to main"
#  bump $BUMP_MODE $OLD_VERSION
#  echo "pom.xml at" $POMPATH "will be bumped from" $OLD_VERSION "to" $NEW_VERSION
#  mvn -q versions:set -DnewVersion="${NEW_VERSION}"
#  git add $POMPATH/pom.xml
#  REPO="https://$GITHUB_ACTOR:$TOKEN@github.com/$GITHUB_REPOSITORY.git"
#  git commit -m "Bump pom.xml from $OLD_VERSION to $NEW_VERSION"
  echo "tag version in main"
  MAIN_VERSION=$($DIR/get-version.sh)
  git tag $MAIN_VERSION
  git push $REPO --follow-tags
  git push $REPO --tags
fi


