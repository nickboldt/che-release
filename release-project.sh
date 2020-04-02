#!/bin/bash

set -v


# set to 1 to actually trigger changes in the release branch
TRIGGER_RELEASE=0 

#flags that enable specific operations, if specific projects require it
GITHUB_TAG_CREATE=0
VERSIONS_FILE_UPDATE=0
MAVEN_PARENT_UPDATE=0
MAVEN_VERSION_UPDATE=0
CHE_UPDATE_IMAGES=0
CHE_UPDATE_DEPENDENCIES=0
CREATE_NEW_PLUGINS=0

init_variables() {
echo "init2131243251324rqfsfd"
REPO_DIR=${REPO##*/}
echo $REPO_DIR
case $REPO_DIR in

     che-machine-exec)
          echo "2"
          GITHUB_TAG_CREATE=1
          VERSION_FILE_UPDATE=1
          ;;
     che-devfile-registry)
          echo "3"
          GITHUB_TAG_CREATE=1
          VERSION_FILE_UPDATE=1
          ;; 
     che-plugin-registry)
          echo "4"
          GITHUB_TAG_CREATE=1
          VERSION_FILE_UPDATE=1
          ;; 
     che-parent)
          echo "5"
          MAVEN_VERSION_UPDATE=1
          ;; 
     che-dashboard)
          echo "6"
          MAVEN_PARENT_UPDATE=1
          MAVEN_VERSION_UPDATE=1
          ;; 
     che-docs)
          echo "7"
          MAVEN_PARENT_UPDATE=1
          MAVEN_VERSION_UPDATE=1
          ;; 
     che-workspace-loader)
          echo "8"
          MAVEN_PARENT_UPDATE=1
          MAVEN_VERSION_UPDATE=1
          ;; 
     che)
          echo "9"
          PARENT_UPDATE=1
          CHE_UPDATE_IMAGES=1
          CHE_UPDATE_DEPENDENCIES=1
          ;;
esac
}

bump_version() {
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  NEXTVERSION=$1
  BUMP_BRANCH=$2

  git checkout ${BUMP_BRANCH}

  echo "Updating project version to ${NEXTVERSION} in ${BUMP_BRANCH}"
  if [[ $MAVEN_VERSION_UPDATE -eq 1 ]]; then
    mvn versions:set versions:commit -DnewVersion=${NEXTVERSION} 
  fi
  if [[ $MAVEN_PARENT_UPDATE -eq 1 ]]; then
    mvn versions:update-parent versions:commit -DallowSnapshots=true -DparentVersion=${NEXTVERSION}
  fi

  if [[ $CHE_UPDATE_DEPENDENCIES -eq 1 ]]; then
    echo "sed"
    # set new dependencies versions 
    sed -i -e "s#${VERSION}-SNAPSHOT#${NEXTVERSION}#" pom.xml
  fi

  COMMIT_MSG="[release] Bump to ${NEXTVERSION} in ${BUMP_BRANCH}"
  git commit -a -s -m "${COMMIT_MSG}"

  PR_BRANCH=pr-master-to-${NEXTVERSION}
  # create pull request for master branch, as branch is restricted
  git branch "${PR_BRANCH}"
  git checkout "${PR_BRANCH}"
  git pull origin "${PR_BRANCH}"
  git push origin "${PR_BRANCH}"
  lastCommitComment="$(git log -1 --pretty=%B)"
  hub pull-request -o -f -m "${lastCommitComment}
  ${lastCommitComment}" -b "${BRANCH}" -h "${PR_BRANCH}"

  git checkout ${CURRENT_BRANCH}
}

usage ()
{
  echo "Provide the necessary parameters and make sure to choose either prerelease testing or trigger release option"
  echo "Usage: $0 --repo [GIT REPO TO EDIT] --version [VERSION TO RELEASE] [--trigger-release]"
  echo "Example: $0 --repo git@github.com:eclipse/che-subproject --version 7.7.0 --trigger-release"; echo
}

#TODO ensure this works!!!
createNewPlugins () {
  newVERSION=$1
  rsync -aPrz v3/plugins/eclipse/che-machine-exec-plugin/nightly/* "v3/plugins/eclipse/che-machine-exec-plugin/${newVERSION}/"
  rsync -aPrz v3/plugins/eclipse/che-theia/next/* "v3/plugins/eclipse/che-theia/${newVERSION}/"
  pwd
  for m in "v3/plugins/eclipse/che-theia/${newVERSION}/meta.yaml" "v3/plugins/eclipse/che-machine-exec-plugin/${newVERSION}/meta.yaml"; do
    sed -i "${m}" \
        -e "s#firstPublicationDate:.\+#firstPublicationDate: \"$(date +%Y-%m-%d)\"#" \
        -e "s#version: \(nightly\|next\)#version: ${newVERSION}#" \
        -e "s#image: \"\(.\+\):\(nightly\|next\)\"#image: \"\1:${newVERSION}\"#" \
        -e "s# development version\.##" \
        -e "s#, get the latest release each day\.##"
  done
  for m in v3/plugins/eclipse/che-theia/latest.txt v3/plugins/eclipse/che-machine-exec-plugin/latest.txt; do
    echo "${newVERSION}" > $m
  done
}

ask() {
    echo $1
  while true; do
    echo -e -n " (Y)es or (N)o "
    read -r yn
    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Please answer (Y)es or (N)o. ";;
    esac
  done
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-t'|'--trigger-release') TRIGGER_RELEASE=1; PRERELEASE_TESTING=0; shift 0;;
    '-r'|'--repo') REPO="$2"; shift 1;;
    '-v'|'--version') VERSION="$2"; shift 1;;
  esac
  shift 1
done

if [[ ! ${VERSION} ]] || [[ ! ${REPO} ]]; then
  usage
  exit 1
fi

init_variables

set +e
  ask "Remove the tag if it already exists?"
  result=$?
set -e

if [[ $result == 0 ]]; then
  git add -A
  git push origin :${VERSION}
fi

# DEBUG
echo ${VERSION}
echo ${REPO}
echo ${MAVEN_PARENT_UPDATE}

# derive branch from version
BRANCH=${VERSION%.*}.x

# if doing a .0 release, use master; if doing a .z release, use $BRANCH
if [[ ${VERSION} == *".0" ]]; then
  BASEBRANCH="master"
else 
  BASEBRANCH="${BRANCH}"
fi

# work in tmp dir
TMP=$(mktemp -d); pushd "$TMP" > /dev/null || exit 1

# get sources from ${BASEBRANCH} branch
echo "Check out ${REPO} to ${TMP}/${REPO##*/}"
git clone "${REPO}" -q
cd "${REPO##*/}" || exit 1
git fetch origin "${BASEBRANCH}":"${BASEBRANCH}" -u
git checkout "${BASEBRANCH}"

# create new branch off ${BASEBRANCH} (or check out latest commits if branch already exists), then push to origin
if [[ "${BASEBRANCH}" != "${BRANCH}" ]]; then
  git branch "${BRANCH}" || git checkout "${BRANCH}" && git pull origin "${BRANCH}"
  git push origin "${BRANCH}"
  git fetch origin "${BRANCH}:${BRANCH}"
  git checkout "${BRANCH}"
fi

if [[ $TRIGGER_RELEASE -eq 1 ]]; then
  # push new branch to release branch to trigger CI build
  git fetch origin "release-candidate:release-candidate"
  git checkout "release-candidate"
  git branch release -f
  git push origin release -f

  if [[$AUTO_TAG -eq 0 ]]; then
    # tag the release
    git checkout "${BRANCH}"
    git tag "${VERSION}"
    git push origin "${VERSION}"
  fi
fi

# now update ${BASEBRANCH} to the new snapshot version
git fetch origin "${BASEBRANCH}":"${BASEBRANCH}"
git checkout "${BASEBRANCH}"

# infer project version + commit change into ${BASEBRANCH} branch
if [[ "${BASEBRANCH}" != "${BRANCH}" ]]; then
  # bump the y digit
  [[ $BRANCH =~ ^([0-9]+)\.([0-9]+)\.x ]] && BASE=${BASH_REMATCH[1]}; NEXT=${BASH_REMATCH[2]}; (( NEXT=NEXT+1 )) # for BRANCH=7.10.x, get BASE=7, NEXT=11
  NEXTVERSION_Y="${BASE}.${NEXT}.0-SNAPSHOT"
  bump_version ${NEXTVERSION_Y} ${BASEBRANCH}
fi
# bump the z digit
[[ $VERSION =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]] && BASE="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"; NEXT="${BASH_REMATCH[3]}"; (( NEXT=NEXT+1 )) # for VERSION=7.7.1, get BASE=7.7, NEXT=2
NEXTVERSION_Z="${BASE}.${NEXT}-SNAPSHOT"
bump_version ${NEXTVERSION_Z} ${BRANCH}

popd > /dev/null || exit

# cleanup tmp dir
# cd /tmp && rm -fr "$TMP"
