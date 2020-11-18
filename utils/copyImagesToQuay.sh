#!/bin/bash -e
#
# Copyright (c) 2019-2020 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

# script to copy latest tags from a list of images into quay.io/eclipse/che- namespace
# REQUIRES: 
#    * skopeo >=0.40 (for authenticated registry queries)
#    * jq to do json queries
# 
# https://registry.redhat.io is v2 and requires authentication to query, so login in first like this:
# docker login registry.redhat.io -u=USERNAME -p=PASSWORD

command -v jq >/dev/null 2>&1 || { echo "jq is not installed. Aborting."; exit 1; }
command -v skopeo >/dev/null 2>&1 || { echo "skopeo is not installed. Aborting."; exit 1; }
checkVersion() {
  if [[  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]]; then
    # echo "[INFO] $3 version $2 >= $1, can proceed."
	true
  else 
    echo "[ERROR] Must install $3 version >= $1"
    exit 1
  fi
}
checkVersion 0.40 "$(skopeo --version | sed -e "s/skopeo version //")" skopeo

DOCOPY=1    # normally, do the copy; optionally can just list images to copy
QUIET=0 	# less output - omit container tag URLs
VERBOSE=1	# more output
WORKDIR=$(pwd)

usage () {
	echo "
1. Log into quay.io using a QUAY_USER that has permission to create repos under quay.io/eclipse. 

2. Go to you user's settings page, and click 'Generate Encrypted Password' to get a token

3. Export that token and log in via commandline

export QUAY_TOKEN=\"your token goes here\"
echo \"\${QUAY_TOKEN}\" | podman login -u=\"\${QUAY_USER}\" --password-stdin quay.io

4. Finally, run this script. Note that if your connection to quay.io times out pulling or pushing, 
you can re-run this script until it's successful.

Usage:   $0 -f [IMAGE LIST FILE] [--nocopy]
Example: $0 -f copyImagesToQuay.txt --nocopy

Options: 
	-q, -v             quiet, verbose output
	--nocopy           just collect the list of destination images + SHAs, but don't actually do the copy
	--help, -h         help
"
	exit 
}

if [[ $# -lt 1 ]]; then usage; exit; fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-w') WORKDIR="$2"; shift 1;;
    '-f') LISTFILE="$2"; shift 1;;
    '-q') QUIET=1; shift 0;;
    '-v') QUIET=0; VERBOSE=1; shift 0;;
	'--nocopy') DOCOPY=0; shift 0;;
    '--help'|'-h') usage;;
    *) OTHER="${OTHER} $1"; shift 0;; 
  esac
  shift 1
done

# check for valid list file
if [[ ! $LISTFILE ]]; then usage; fi
if [[ ! -r $LISTFILE ]] && [[ ! -r ${WORKDIR}/${LISTFILE} ]]; then usage; fi

while IFS= read -r image; do
	if [[ ${image} ]]; then 
		# transform source image to new image
		imageNew="${image/docker.io\//che--}"
		imageNew="quay.io/eclipse/${imageNew//\//--}"
		if [[ ${imageNew} != *":"* ]] && [[ ${imageNew} != *"sha256"* ]]; then 
			# image has no tag or sha, so assume :latest
			imageNew="${imageNew}:latest"
		fi
		# get the digest of the image and use that instead of a potentially moving tag
		digest="$(skopeo inspect docker://${image} | yq -r '.Digest' | sed -r -e "s#sha256:##g")"
		if [[ ${VERBOSE} -eq 1 ]]; then echo "
[INFO] Skopeo copy $image to
        ${imageNew}-${digest} ... "
		fi
		# note that the target image in quay must exist; or the user pushing must be an administrator to create the repo on the fly
		if [[ ${DOCOPY} -eq 1 ]]; then skopeo copy --all "docker://${image}" "docker://${imageNew}-${digest}"; fi
		digest=""
	fi
done < <(grep -v '^ *#' < ${LISTFILE}) # exclude commented lines
