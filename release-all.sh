#!/bin/bash

$RELEASE_VERSION=$1

usage ()
{
  echo "Usage: release.sh 7.11.0"
}

verify_release() {
    #part 1 - look up the release images on quay? (with skopeo)
    #part 2 - find release artifacts on nexus?
}

if [[ ! ${RELEASE_VERSION} ]]; then
  usage
  exit 1
fi

#1. Release che-theia
# TODO

#2. Release machine-exec

./release-project.sh --repo https://github.com/eclipse/che-machine-exec --version $RELEASE_VERSION --trigger-release
veryfy_release --image che-machine-exec:$RELEASE_VERSION
#3. Release plugin-registry
./release-project.sh --repo git@github.com:eclipse/che-plugin-registry --version $RELEASE_VERSION --trigger-release

#4. Release devfile-registry
./release-project.sh --repo git@github.com:eclipse/che-devfile-registry --version $RELEASE_VERSION --trigger-release

#5. Release che-parent
./release-project.sh --repo git@github.com:eclipse/che-parent --version $RELEASE_VERSION --trigger-release

#6. Release che-docs
./release-project.sh --repo git@github.com:eclipse/che-docs --version $RELEASE_VERSION --trigger-release

#7. Release che-dashboard
./release-project.sh --repo git@github.com:eclipse/che-dashboard --version $RELEASE_VERSION --trigger-release

#8. Release che-workspace-loader
./release-project.sh --repo git@github.com:eclipse/che-workspace-loader --version $RELEASE_VERSION --trigger-release

#9. Release che
./release-project.sh --repo git@github.com:eclipse/che-workspace-loader --version $RELEASE_VERSION --trigger-release

#10. Release che-operator

#11. Release chectl