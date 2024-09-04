#!/usr/bin/env bash

#from mypriv.sh  #test fromat not support by dash [[]]
if [[ "x$BB_ASH_VERSION" != "x" ]] ; then SCRIPT=$0; if [[ "x${SCRIPT}" == "x-ash" ]]; then SCRIPT=$1; fi; SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${SCRIPT}")" && pwd) ; fi
if [[ "x$ZSH_VERSION" != "x" ]] ; then SCRIPT_DIR=${0:a:h} ; fi
if [[ "x$BASH_VERSION" != "x" ]] ; then SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )" ; fi
if [[ "x$SHELL" == "x/bin/ash" ]] ; then SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) ; fi
if [[ "x$SCRIPT_DIR" == "x" ]] ; then SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) ; fi #some busybox early version ont SHELL env var
if [[ "x$SCRIPT_DIR" == "x" ]] ; then echo waring can not get SCRIPT_DIR, dont trust use it ; fi
#[[ "x$0" == "x-ash" ]]  is source ash script case

set -x
cd ${SCRIPT_DIR}
set +x


WRTC_SRC_ROOT=${SCRIPT_DIR}
WEBRTC_BUILD_ROOT=${SCRIPT_DIR}
set -euox pipefail




export DEPOT_TOOLS_UPDATE=0



install_dependencies_ubuntu() {
    options="$(echo "$@" | tr ' ' '|')"
    # Dependencies
    # python*       : resolve ImportError: No module named pkg_resources
    # libglib2.0-dev: resolve pkg_config("glib")
    $SUDO apt-get update
    $SUDO apt-get install -y \
        apt-transport-https \
        build-essential \
        ca-certificates \
        git \
        gnupg \
        libglib2.0-dev \
        python3 \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        software-properties-common \
        tree \
        curl
    curl https://apt.kitware.com/keys/kitware-archive-latest.asc \
        2>/dev/null | gpg --dearmor - |
        $SUDO sed -n 'w /etc/apt/trusted.gpg.d/kitware.gpg' # Write to file, no stdout
    source <(grep VERSION_CODENAME /etc/os-release)
    $SUDO apt-add-repository --yes "deb https://apt.kitware.com/ubuntu/ $VERSION_CODENAME main"
    $SUDO apt-get update
    $SUDO apt-get --yes install cmake
    cmake --version >/dev/null
    if [[ "purge-cache" =~ ^($options)$ ]]; then
        $SUDO apt-get clean
        $SUDO rm -rf /var/lib/apt/lists/*
    fi
}

build_webrtc_one() {
  pushd ${WEBRTC_BUILD_ROOT}
    arg_target_debugrelease=$1
    arg_target_os=$2
    arg_target_cpu=$3
  args_val=' treat_warnings_as_errors=true fatal_linker_warnings=true rtc_build_examples=false rtc_include_tests=false ffmpeg_branding = "Chrome" rtc_use_h264=true rtc_use_h265=false rtc_enable_protobuf=false clang_use_chrome_plugins=false enable_dsyms=true  rtc_enable_sctp=false'
  if [ "x$arg_target_debugrelease" == "xdebug" ]; then
    args_val+=' is_debug = true'
  else
    args_val+=' is_debug = false'
  fi

  if [ x"$arg_target_os" == x"android" ] ; then
	args_val+=' target_os="android"'
  fi
  if [ x"$arg_target_os" == x"ios" ] ; then
	args_val+=' target_os="ios" ios_enable_code_signing = false'
  fi
  if [ x"$arg_target_os" == x"mac" ] ; then
	args_val+=' target_os="mac"'
  fi


  if [ x"$arg_target_cpu" == x"armeabi" ] ; then
	args_val+=' target_cpu="arm"'
  fi
  if [ x"$arg_target_cpu" == x"armeabi-v7a" ] ; then
	args_val+=' target_cpu="arm" arm_version=7'
  fi
  if [ x"$arg_target_cpu" == x"arm64" ] ; then
	args_val+=' target_cpu="arm64"'
  fi
  if [ x"$arg_target_cpu" == x"arm64-v8a" ] ; then
	args_val+=' target_cpu="arm64" arm_version=8'
  fi
  if [ x"$arg_target_cpu" == x"x86" ] ; then
	args_val+=' target_cpu="x86"'
  fi
  if [ x"$arg_target_cpu" == x"x64" ] ; then
	args_val+=' target_cpu="x64"'
  fi

  if [ ! -d out/${arg_target_debugrelease}/${arg_target_os}/${arg_target_cpu} ]; then
    gn gen --args="$args_val" out/${arg_target_debugrelease}/${arg_target_os}/${arg_target_cpu}
  fi
  ninja -C out/${arg_target_debugrelease}/${arg_target_os}/${arg_target_cpu}
  ls -alh out/${arg_target_debugrelease}/${arg_target_os}/${arg_target_cpu}
  popd
}
#ref: https://github.com/rfazi/android_webrtc_build/blob/main/entrypoint.sh
function androidMoveJniLibs() {
  pushd ${WEBRTC_BUILD_ROOT}
  LIB_FOLDER=out/${1}/${2}/_libout/_jniLibs/${3}
  mkdir -p $LIB_FOLDER
  cp -av out/${1}/${2}/${3}/libjingle_peerconnection_so.so $LIB_FOLDER/
  popd
}
function androidMoveJavaLib() {
    pushd ${WEBRTC_BUILD_ROOT}
    LIB_FOLDER=out/${1}/${2}/_libout/_libs/${3}
    mkdir -p $LIB_FOLDER
    cp -av out/${1}/${2}/${3}/lib.java/sdk/android/libwebrtc.jar $LIB_FOLDER/
    popd
}
function androidRemoveBuild() {
    pushd ${WEBRTC_BUILD_ROOT}
    rm -rf out/${1}/${2}/${3}
    popd
}

function android_build_one() {
    build_webrtc_one $1 android $2
    androidMoveJniLibs $1 android $2
    androidMoveJavaCode $1 android $2
    #androidRemoveBuild $1 android $2
}
build() {
    # PWD=Open3D
    WEBRTC_COMMIT_SHORT=$(git -C ${WEBRTC_BUILD_ROOT} rev-parse --short=7 HEAD)

    [ "`uname`" == "Darwin" ] && {
        build_webrtc_one debug ios arm64-v8a
        build_webrtc_one release ios arm64-v8a
        build_webrtc_one debub mac x64
        build_webrtc_one release mac x64
    }

    [ "`uname`" == "Linux" ] && {
        android_build_one debug armeabi-v7a
        # android_build_one release armeabi
        # android_build_one debug arm64
        # android_build_one release arm64
        
        ls $WEBRTC_BUILD_ROOT/out/*/*/_libout
        tar -czvf out/webrtc_${WEBRTC_COMMIT_SHORT}_android.tar.gz -C $WEBRTC_BUILD_ROOT/out/*/*/_libout
    }

}


if [[ $# < 1 ]]; then
    echo "Usage: $0 install_dependencies_ubuntu|build"
    exit 1
else
    $1
fi

