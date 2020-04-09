#!/bin/bash

$RELEASE_VERSION=$1

usage ()
{
  echo "Must provide release version. Example usage: release.sh 7.11.0"
}

verify_maven_artifact_exists() {
  until wget -O/dev/null -q $1
  do
    echo "unresolved Maven artifact ${1}"
    sleep 60
  done
  echo "resolved Maven artifact ${1}"
}

MAVEN_PARENT_ARTIFACT="https://repo.maven.apache.org/maven2/org/eclipse/che/depmgt/maven-depmgt-pom/${RELEASE_VERSION}/maven-depmgt-pom-${RELEASE_VERSION}.pom"
MAVEN_DOCS_ARTIFACT="https://repo.maven.apache.org/maven2/org/eclipse/che/docs/che-docs/${RELEASE_VERSION}/che-docs-${RELEASE_VERSION}.pom"
MAVEN_DASHBOARD_ARTIFACT="https://repo.maven.apache.org/maven2/org/eclipse/che/dashboard/che-dashboard-war/${RELEASE_VERSION}/che-dashboard-war-${RELEASE_VERSION}.pom"
MAVEN_WORKSPACE_LOADER_ARTIFACT="https://repo.maven.apache.org/maven2/org/eclipse/che/workspace/loader/che-workspace-loader/${RELEASE_VERSION}/che-workspace-loader-${RELEASE_VERSION}.pom"

if [[ ! ${RELEASE_VERSION} ]]; then
  usage
  exit 1
fi

# FLOW FOR RELEASING CHE-PARENT ... CHE-SERVER ARTIFACTS ONLY
release_maven_projects() {
  if [[ $SKIP_CHE_PARENT -eq 0 ]]; then
    ./release-project.sh --repo git@github.com:eclipse/che-parent --version $RELEASE_VERSION --trigger-release
  fi

  if [[ $SKIP_CHE_DOCS -eq 0 ]]; then
    verify_maven_artifact_exists $MAVEN_PARENT_ARTIFACT
    ./release-project.sh --repo git@github.com:eclipse/che-docs --version $RELEASE_VERSION --trigger-release
  fi

  if [[ $SKIP_CHE_WORKSPACE_LOADER -eq 0 ]]; then
    verify_maven_artifact_exists $MAVEN_PARENT_ARTIFACT
    ./release-project.sh --repo git@github.com:eclipse/che-workspace-loader --version $RELEASE_VERSION --trigger-release
  fi

  if [[ $SKIP_CHE_DASHBOARD -eq 0 ]]; then
    verify_maven_artifact_exists $MAVEN_PARENT_ARTIFACT
    ./release-project.sh --repo git@github.com:eclipse/che-dashboard --version $RELEASE_VERSION --trigger-release
  fi

  if [[ $SKIP_CHE_SERVER -eq 0 ]]; then
    verify_maven_artifact_exists $MAVEN_PARENT_ARTIFACT
    verify_maven_artifact_exists $MAVEN_DOCS_ARTIFACT
    verify_maven_artifact_exists $MAVEN_DASHBOARD_ARTIFACT
    verify_maven_artifact_exists $MAVEN_WORKSPACE_LOADER_ARTIFACT
    ./release-project.sh --repo git@github.com:eclipse/che-parent --version $RELEASE_VERSION --trigger-release
  fi
}


#1. Release che-theia
# TODO

#2. Release machine-exec

#./release-project.sh --repo https://github.com/eclipse/che-machine-exec --version $RELEASE_VERSION --trigger-release
#veryfy_release --image che-machine-exec:$RELEASE_VERSION
#3. Release plugin-registry
#./release-project.sh --repo git@github.com:eclipse/che-plugin-registry --version $RELEASE_VERSION --trigger-release

#4. Release devfile-registry
#./release-project.sh --repo git@github.com:eclipse/che-devfile-registry --version $RELEASE_VERSION --trigger-release

#5. Release che-parent
#./release-project.sh --repo git@github.com:eclipse/che-parent --version $RELEASE_VERSION --trigger-release

#6. Release che-docs
#./release-project.sh --repo git@github.com:eclipse/che-docs --version $RELEASE_VERSION --trigger-release

#7. Release che-dashboard
#./release-project.sh --repo git@github.com:eclipse/che-dashboard --version $RELEASE_VERSION --trigger-release

#8. Release che-workspace-loader
#./release-project.sh --repo git@github.com:eclipse/che-workspace-loader --version $RELEASE_VERSION --trigger-release

#9. Release che
#./release-project.sh --repo git@github.com:eclipse/che-workspace-loader --version $RELEASE_VERSION --trigger-release

#10. Release che-operator

#11. Release chectl