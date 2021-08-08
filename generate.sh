#!/usr/bin/env bash

set -euo pipefail

DEFID_BRCM="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/definitions?name=Azure.sonic-buildimage.official.broadcom' | jq -r '.value[0].id')"
DEFID_MLNX="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/definitions?name=Azure.sonic-buildimage.official.mellanox' | jq -r '.value[0].id')"

echo '{'
first=1
for BRANCH in 202012 202106 master
do
	if [[ -z "${first}" ]]; then
		echo ','
	fi
	first=''
	BUILD_BRCM="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds?definitions='"${DEFID_BRCM}"'&branchName=refs/heads/'"${BRANCH}"'&$top=1&resultFilter=succeeded&api-version=6.0' | jq -r '.value[0].id')"
	BUILD_BRCM_TS="$(curl 'https://dev.azure.com/mssonic/build/_apis/build/builds/'"${BUILD_BRCM}"'?api-version=6.0' | jq -r '.queueTime')"
	BUILD_MLNX="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds?definitions='"${DEFID_MLNX}"'&branchName=refs/heads/'"${BRANCH}"'&$top=1&resultFilter=succeeded&api-version=6.0' | jq -r '.value[0].id')"
	BUILD_MLNX_TS="$(curl 'https://dev.azure.com/mssonic/build/_apis/build/builds/'"${BUILD_MLNX}"'?api-version=6.0' | jq -r '.queueTime')"

	echo " [*] Last successful builds for \"${BRANCH}\":" >> /dev/stderr
	echo "     Broadcom: ${BUILD_BRCM}" >> /dev/stderr
	echo "     Mellanox: ${BUILD_MLNX}" >> /dev/stderr

	ARTF_BRCM="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds/'"${BUILD_BRCM}"'/artifacts?artifactName=sonic-buildimage.broadcom&api-version=5.1' | jq -r '.resource.downloadUrl')"
	ARTF_MLNX="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds/'"${BUILD_MLNX}"'/artifacts?artifactName=sonic-buildimage.mellanox&api-version=5.1' | jq -r '.resource.downloadUrl')"

	echo "\"${BRANCH}\": {"
	echo "\"sonic-broadcom.bin\": {"
	echo "  \"url\": \"$(echo "${ARTF_BRCM}" | sed 's/format=zip/format=file\&subpath=\/target\/sonic-broadcom.bin/')\","
	echo "  \"build\": \"https://dev.azure.com/mssonic/build/_build/results?buildId=${BUILD_BRCM}&view=results\","
	echo "  \"date\": \"${BUILD_BRCM_TS}\""
	echo " },"
	echo "\"sonic-aboot-broadcom.swi\": {"
	echo "  \"url\": \"$(echo "${ARTF_BRCM}" | sed 's/format=zip/format=file\&subpath=\/target\/sonic-aboot-broadcom.swi/')\","
	echo "  \"build\": \"https://dev.azure.com/mssonic/build/_build/results?buildId=${BUILD_BRCM}&view=results\","
	echo "  \"date\": \"${BUILD_BRCM_TS}\""
	echo " },"
	echo "\"sonic-mellanox.swi\": {"
	echo "  \"url\": \"$(echo "${ARTF_MLNX}" | sed 's/format=zip/format=file\&subpath=\/target\/sonic-mellanox.bin/')\","
	echo "  \"build\": \"https://dev.azure.com/mssonic/build/_build/results?buildId=${BUILD_MLNX}&view=results\","
	echo "  \"date\": \"${BUILD_MLNX_TS}\""
	echo " }" # Final object
	echo "}"
done
echo "}"
