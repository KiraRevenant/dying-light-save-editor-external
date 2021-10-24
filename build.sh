#!/usr/bin/env bash

script_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source_dir=${script_dir}/source
build_dir=${script_dir}/build
install_dir=${script_dir}/install
vcpkg_commit=2169ab765b49cfc5cd7eddfc8ff3e579326776f8
wxwidgets_version=3.1.5

for dir in "${source_dir}" "${build_dir}" "${install_dir}"; do
    if [[ ! -d "${dir}" ]]; then
        mkdir --parents "${dir}" || exit 1
        echo "*" > "${dir}/.gitignore"
    fi
done

function build_vcpkg {
    if [[ ! -d "./vcpkg-${vcpkg_commit}" ]]; then
        curl -sSL "https://github.com/microsoft/vcpkg/archive/${vcpkg_commit}.tar.gz" | tar -xz || return 1
    fi
    cd "./vcpkg-${vcpkg_commit}" || return 1
    if [[ ! -f ./vcpkg ]]; then
        ./bootstrap-vcpkg.sh -disableMetrics || return 1
    fi
    ./vcpkg install Catch2 palsigslot sqlite3 zlib || return 1
    if [[ "${OSTYPE}" == "linux-gnu" ]]; then
        ./vcpkg install libuuid || return 1
    fi
    ./vcpkg upgrade --no-dry-run || return 1
    ./vcpkg export --x-all-installed --zip --output=vcpkg-export || return 1
    if [[ -d "${install_dir}/vcpkg" ]]; then
        rm -rf "${install_dir}/vcpkg" || return 1
    fi
    if [[ -d "${install_dir}/vcpkg-export" ]]; then
        rm -rf "${install_dir}/vcpkg-export" || return 1
    fi
    unzip -d "${install_dir}" ./vcpkg-export.zip || return 1
    mv "${install_dir}/vcpkg-export" "${install_dir}/vcpkg" || return 1
}

function build_wxwidgets {
    if [[ ! -d "./wxWidgets-${wxwidgets_version}" ]]; then
        curl -sSL "https://github.com/wxWidgets/wxWidgets/releases/download/v${wxwidgets_version}/wxWidgets-${wxwidgets_version}.tar.bz2" | tar -x || return 1
    fi
    cd "./wxWidgets-${wxwidgets_version}" || return 1
    for config in Debug Release; do
        cmake -G Ninja -B "${build_dir}/wxwidgets/${config,,}" -S . \
            "-DCMAKE_BUILD_TYPE=${config}" \
            "-DCMAKE_INSTALL_PREFIX=${install_dir}/wxwidgets/${config,,}" \
            -DwxBUILD_COMPATIBILITY=3.1 -DwxUSE_LIBJPEG=OFF -DwxUSE_LIBTIFF=OFF -DwxBUILD_DEMOS=OFF || return 1
        cmake --build "${build_dir}/wxwidgets/${config,,}" || return 1
        if [[ -d "${install_dir}/wxwidgets/${config,,}" ]]; then
            rm -rf "${install_dir}/wxwidgets/${config,,}" || return 1
        fi
        cmake --install "${build_dir}/wxwidgets/${config,,}" || return 1
    done
}

function build_all {
    for fn in build_vcpkg build_wxwidgets; do
        (cd "${source_dir}" && ${fn}) || return 1
    done
}

function main {
    cd "${source_dir}" || return 1
    case "$1" in
        all)
            build_all || return 1
            ;;
        vcpkg)
            build_vcpkg || return 1
            ;;
        wxwidgets)
            build_wxwidgets || return 1
            ;;
        *)
            echo "Script invoked incorrectly."
            return 1
            ;;
    esac
}

(main $@) || exit 1
