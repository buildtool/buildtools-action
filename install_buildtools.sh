#!/usr/bin/env bash

#MIT License
#
#Copyright (c) 2019 buildtool
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

set -euo pipefail

check_required_binaries() {
  if ! is_command tar; then
    log_err "missing command tar"
  fi
  if ! (is_command curl || is_command wget); then
    log_err "missing command curl or wget"
  fi
}

fetch_curl() {
  log_debug "http_download $2"
  if is_command curl; then
    http_download_curl "$@"
    return
  elif is_command wget; then
    http_download_wget "$@"
    return
  fi
  log_crit "http_download unable to find wget or curl"
  return 1
}

http_download_curl() {
  source_url="${1}"
  local_file="${2}"
  header="${3:-}"
  if [ -z "$header" ]; then
    code=$(curl -w '%{http_code}' -sL -o "$local_file" "$source_url")
  else
    code=$(curl -w '%{http_code}' -sL -H "$header" -o "$local_file" "$source_url")
  fi
  if [ "$code" != "200" ]; then
    log_debug "http_download_curl received HTTP status $code"
    return 1
  fi
  return 0
}

http_download_wget() {
  source_url="${1}"
  local_file="${2}"
  header="${3:-}"
  if [ -z "$header" ]; then
    wget -q -O "$local_file" "$source_url"
  else
    wget -q --header "$header" -O "$local_file" "$source_url"
  fi
}

http_download() {
  log_debug "http_download ${1} ${2}"
  if is_command curl; then
    http_download_curl "$@"
    return
  elif is_command wget; then
    http_download_wget "$@"
    return
  fi
  log_crit "http_download unable to find wget or curl"
  return 1
}

http_copy() {
  tmp=$(mktemp)
  http_download "${1}" "${tmp}" "${2:-}" || return 1
  body=$(cat "$tmp")
  rm -f "${tmp}"
  echo "$body"
}

wanted_version() {
  local version github_url
  version="${1}"
  github_url="${GITHUB_BASE}/${version}"
  json=$(http_copy "$github_url" "Accept:application/json")
  test -z "$json" && return 1
  version=$(echo "$json" | tr -s '\n' ' ' | sed 's/.*"tag_name":"//' | sed 's/".*//')
  test -z "$version" && return 1
  echo "${version#v}"
}

download_if_needed() {
  local wanted current buildtools_path github_url
  wanted=$(wanted_version "${1}")
  buildtools_path="/tmp/buildtools-v${wanted}"
  log_info "want version: ${wanted}"

  if [[ -f "${buildtools_path}/build" ]]; then
    log_debug "got version: ${wanted}"
  else
    mkdir -p "${buildtools_path}"
    log_debug "downloading buildtools version ${wanted}"
    github_url="${GITHUB_BASE}/download/v${wanted}/build-tools_${wanted}_${OS}_${ARCH}.tar.gz"
    http_download "${github_url}" "${buildtools_path}/buildtools.tgz"
    tar -C "${buildtools_path}" -xzf "${buildtools_path}/buildtools.tgz"
  fi
  log_debug "adding ${buildtools_path} to path"
  echo "${buildtools_path}" >>"${GITHUB_PATH}"
}

is_command() {
  command -v "$1" >/dev/null
}

log() {
  echo "$@" 1>&2
}

log_err() {
  log "error:" "$@"
  exit 1
}

log_debug() {
  [ "${DEBUG_LOG}" != "true" ] && return
  log "debug:" "$@"
}

log_info() {
  log "info:" "$@"

}

adjust_arch() {
  # adjust ARCHive name based on ARCH
  local org
  org=${ARCH}
  case ${ARCH} in
  X86) ARCH=x86_64 ;;
  X64) ARCH=x86_64 ;;
  ARM) ARCH=arm64 ;;
  ARM64) ARCH=arm64 ;;
  x86) ARCH=x86_64 ;;
  x64) ARCH=x86_64 ;;
  arm) ARCH=arm64 ;;
  arm64) ARCH=arm64 ;;
  *) log_err "Unsupported release ARCH ${ARCH}"
  esac
  if [[ "${org}" != "${ARCH}" ]]; then
    log_debug "adjusted architecture from ${org} to ${ARCH}"
  fi
}

adjust_os() {
  # adjust archive name based on OS
  local org
  org=${OS}
  case ${OS} in
  macOS) OS=Darwin ;;
  Linux) OS=Linux ;;
  Windows) OS=Windows ;;
  *) log_err "Unsupported release OS ${OS}"
  esac
  if [[ "${org}" != "${OS}" ]]; then
    log_debug "adjusted operating system from ${org} to ${ARCH}"
  fi
}

# start
VERSION=${1:-latest}
DEBUG_LOG=${2:-false}
GITHUB_BASE="https://github.com/buildtool/build-tools/releases"
# RUNNER_ARCH	The architecture of the runner executing the job.
# Possible values are X86, X64, ARM, or ARM64.
ARCH="${RUNNER_ARCH}"
# RUNNER_OS	The operating system of the runner executing the job.
# Possible values are Linux, Windows, or macOS.
OS="${RUNNER_OS}"
check_required_binaries
adjust_arch
adjust_os
download_if_needed "${VERSION}"
