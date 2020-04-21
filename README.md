Che release guide

Contents:
release-all.sh, release-projects.sh - script to release the whole Che setup. WIP (not working)

cico_release.sh - CI Centos script for releasing all Che Server Maven artifacts/images
pom.xml - a reactor that is used to build all Che projects, ranging from che-parent to che-docs
VERSION - version file that lists bash properties such as CHE_VERSION=target.release.version

Release Che Parent - Che Server artifacts & images:
- create "release" branch, edit VERSION file to feature your desired release and push the release branch to origin, which would trigger the job on CI

