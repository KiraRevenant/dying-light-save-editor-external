#!/usr/bin/env bash

script_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
destination_dir=${script_dir}/dist
source_dir=${script_dir}/install
package_name=$1

if [[ ! -d "${destination_dir}" ]]; then
    mkdir --parents "${destination_dir}" || exit 1
fi

function zip_cmd {
    if [[ "${OSTYPE}" == "cygwin" || "${OSTYPE}" == "msys" ]]; then
        # The zip tool used on Windows doesn't support symlinks (-y)
        zip -r "$@" || return 1
    else
        zip -ry "$@" || return 1
    fi
}

(cd "${source_dir}" && zip_cmd "${destination_dir}/${package_name}.zip" .) || exit 1
