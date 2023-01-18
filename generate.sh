#!/usr/bin/env bash

set -euo pipefail

DEFID_BRCM="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/definitions?name=Azure.sonic-buildimage.official.broadcom' | jq -r '.value[0].id')"
DEFID_BARE="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/definitions?name=Azure.sonic-buildimage.official.barefoot' | jq -r '.value[0].id')"
DEFID_MLNX="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/definitions?name=Azure.sonic-buildimage.official.mellanox' | jq -r '.value[0].id')"
DEFID_VS="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/definitions?name=Azure.sonic-buildimage.official.vs' | jq -r '.value[0].id')"

echo '{'
first=1
for BRANCH in 202012 202106 202111 202205 master
do
	if [[ -z "${first}" ]]; then
		echo ','
	fi
	first=''
	BUILD_BRCM_TS=null
	BUILD_MLNX_TS=null
	BUILD_BARE_TS=null
	BUILD_VS_TS=null
	BUILD_BRCM="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds?definitions='"${DEFID_BRCM}"'&branchName=refs/heads/'"${BRANCH}"'&$top=1&resultFilter=succeeded&api-version=6.0' | jq -r '.value[0].id')"
	if [[ "${BUILD_BRCM}" != "null" ]]; then
		BUILD_BRCM_TS="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds/'"${BUILD_BRCM}"'?api-version=6.0' | jq -r '.queueTime')"
	fi
	BUILD_MLNX="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds?definitions='"${DEFID_MLNX}"'&branchName=refs/heads/'"${BRANCH}"'&$top=1&resultFilter=succeeded&api-version=6.0' | jq -r '.value[0].id')"
	if [[ "${BUILD_MLNX}" != "null" ]]; then
		BUILD_MLNX_TS="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds/'"${BUILD_MLNX}"'?api-version=6.0' | jq -r '.queueTime')"
	fi
	BUILD_BARE="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds?definitions='"${DEFID_BARE}"'&branchName=refs/heads/'"${BRANCH}"'&$top=1&resultFilter=succeeded&api-version=6.0' | jq -r '.value[0].id')"
	if [[ "${BUILD_BARE}" != "null" ]]; then
		BUILD_BARE_TS="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds/'"${BUILD_BARE}"'?api-version=6.0' | jq -r '.queueTime')"
	fi
	BUILD_VS="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds?definitions='"${DEFID_VS}"'&branchName=refs/heads/'"${BRANCH}"'&$top=1&resultFilter=succeeded&api-version=6.0' | jq -r '.value[0].id')"
	if [[ "${BUILD_VS}" != "null" ]]; then
		BUILD_VS_TS="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds/'"${BUILD_VS}"'?api-version=6.0' | jq -r '.queueTime')"
	fi

	echo " [*] Last successful builds for \"${BRANCH}\":" >> /dev/stderr
	echo "     Broadcom: ${BUILD_BRCM}" >> /dev/stderr
	echo "     Mellanox: ${BUILD_MLNX}" >> /dev/stderr
	echo "     Barefoot: ${BUILD_BARE}" >> /dev/stderr
	echo "     Virtual Switch: ${BUILD_VS}" >> /dev/stderr

	ARTF_BRCM=null
	ARTF_MLNX=null
	ARTF_BARE=null
	ARTF_VS=null
	if [[ "${BUILD_BRCM}" != "null" ]]; then
		ARTF_BRCM="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds/'"${BUILD_BRCM}"'/artifacts?artifactName=sonic-buildimage.broadcom&api-version=5.1' | jq -r '.resource.downloadUrl')"
	fi
	if [[ "${BUILD_MLNX}" != "null" ]]; then
		ARTF_MLNX="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds/'"${BUILD_MLNX}"'/artifacts?artifactName=sonic-buildimage.mellanox&api-version=5.1' | jq -r '.resource.downloadUrl')"
	fi
	if [[ "${BUILD_BARE}" != "null" ]]; then
		ARTF_BARE="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds/'"${BUILD_BARE}"'/artifacts?artifactName=sonic-buildimage.barefoot&api-version=5.1' | jq -r '.resource.downloadUrl')"
	fi
	if [[ "${BUILD_VS}" != "null" ]]; then
		ARTF_VS="$(curl -s 'https://dev.azure.com/mssonic/build/_apis/build/builds/'"${BUILD_VS}"'/artifacts?artifactName=sonic-buildimage.vs&api-version=5.1' | jq -r '.resource.downloadUrl')"
	fi

	echo "\"${BRANCH}\": {"
	if [[ "${BUILD_BRCM}" != "null" ]]; then
		echo "\"sonic-broadcom.bin\": {"
		echo "  \"url\": \"$(echo "${ARTF_BRCM}" | sed 's/format=zip/format=file\&subpath=\/target\/sonic-broadcom.bin/')\","
		echo "  \"build-url\": \"https://dev.azure.com/mssonic/build/_build/results?buildId=${BUILD_BRCM}&view=results\","
		echo "  \"build\": \"${BUILD_BRCM}\","
		echo "  \"date\": \"${BUILD_BRCM_TS}\""
		echo " },"
		echo "\"sonic-aboot-broadcom.swi\": {"
		echo "  \"url\": \"$(echo "${ARTF_BRCM}" | sed 's/format=zip/format=file\&subpath=\/target\/sonic-aboot-broadcom.swi/')\","
		echo "  \"build-url\": \"https://dev.azure.com/mssonic/build/_build/results?buildId=${BUILD_BRCM}&view=results\","
		echo "  \"build\": \"${BUILD_BRCM}\","
		echo "  \"date\": \"${BUILD_BRCM_TS}\""
		echo " }"
		if [[ "${BUILD_VS}" != "null" || "${BUILD_MLNX}" != "null" || "${BUILD_BARE}" != "null" ]]; then
			echo ","
		fi
	fi
	if [[ "${BUILD_MLNX}" != "null" ]]; then
		echo "\"sonic-mellanox.bin\": {"
		echo "  \"url\": \"$(echo "${ARTF_MLNX}" | sed 's/format=zip/format=file\&subpath=\/target\/sonic-mellanox.bin/')\","
		echo "  \"build-url\": \"https://dev.azure.com/mssonic/build/_build/results?buildId=${BUILD_MLNX}&view=results\","
		echo "  \"build\": \"${BUILD_MLNX}\","
		echo "  \"date\": \"${BUILD_MLNX_TS}\""
		echo " }"
		if [[ "${BUILD_VS}" != "null" || "${BUILD_BARE}" != "null" ]]; then
			echo ","
		fi
	fi
	if [[ "${BUILD_BARE}" != "null" ]]; then
		echo "\"sonic-barefoot.bin\": {"
		echo "  \"url\": \"$(echo "${ARTF_BARE}" | sed 's/format=zip/format=file\&subpath=\/target\/sonic-barefoot.bin/')\","
		echo "  \"build-url\": \"https://dev.azure.com/mssonic/build/_build/results?buildId=${BUILD_BARE}&view=results\","
		echo "  \"build\": \"${BUILD_BARE}\","
		echo "  \"date\": \"${BUILD_BARE_TS}\""
		echo " }"
		if [[ "${BUILD_VS}" != "null" ]]; then
			echo ","
		fi
	fi
	if [[ "${BUILD_VS}" != "null" ]]; then
		echo "\"sonic-vs.img.gz\": {"
		echo "  \"url\": \"$(echo "${ARTF_VS}" | sed 's/format=zip/format=file\&subpath=\/target\/sonic-vs.img.gz/')\","
		echo "  \"build-url\": \"https://dev.azure.com/mssonic/build/_build/results?buildId=${BUILD_VS}&view=results\","
		echo "  \"build\": \"${BUILD_VS}\","
		echo "  \"date\": \"${BUILD_VS_TS}\""
		echo " },"
		echo "\"docker-sonic-vs.gz\": {"
		echo "  \"url\": \"$(echo "${ARTF_VS}" | sed 's/format=zip/format=file\&subpath=\/target\/docker-sonic-vs.gz/')\","
		echo "  \"build-url\": \"https://dev.azure.com/mssonic/build/_build/results?buildId=${BUILD_VS}&view=results\","
		echo "  \"build\": \"${BUILD_VS}\","
		echo "  \"date\": \"${BUILD_VS_TS}\""
		echo " }"
	fi
	echo "}"
done
echo "}"
