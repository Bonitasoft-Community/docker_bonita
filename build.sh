#!/bin/bash

set -e

print_error() {
  RED='\033[0;31m'
  NC='\033[0m' # No Color
  printf "${RED}ERROR - $1\n${NC}"
}

exit_with_usage() {
  SCRIPT_NAME=`basename "$0"`
  [ ! -z "$1" ] && print_error "$1" >&2
  echo ""
  echo "Usage: ./$SCRIPT_NAME [options] -- <Path_to_Dockerfile> [--build-arg key=value]"
  echo ""
  echo "Options:"
  echo "  -a docker_build_args_file  file to read docker build arguments from"
  echo "  -c                         use Docker cache while building image - by default build is performed with '--no-cache=true'"
  echo ""
  echo "Examples:"
  echo "  $> ./$SCRIPT_NAME -- 7.5"
  echo "  $> ./$SCRIPT_NAME -a build_args -c -- 7.5 --build-arg key1=value1 --build-arg key2=value2"
  echo ""
  exit 1
}

# parse command line arguments
no_cache="true"
while [ "$#" -gt 0 ]
do
  # process next argument
  case $1 in
    -a)
      shift
      BUILD_ARGS_FILE=$1
      if [ -z "$BUILD_ARGS_FILE" ]
      then
        exit_with_usage "Option -a requires an argument."
      fi
      if [ ! -f "$BUILD_ARGS_FILE" ]
      then
        exit_with_usage "Build args file not found: $BUILD_ARGS_FILE"
      fi
      ;;
    -c)
      no_cache="false"
      ;;
    --)
      shift
      break
      ;;
    *)
      exit_with_usage "Unrecognized option: $1"
      ;;
  esac
  if [ "$#" -gt 0 ]
  then
    shift
  fi
done

if [ "$#" -lt 1 ]
then
    exit_with_usage
fi


BUILD_PATH=$1
shift
BUILD_ARGS="--no-cache=${no_cache}"

# validate build path
if [ -z "${BUILD_PATH}" ]
then
  exit_with_usage
fi
if [ ! -f "${BUILD_PATH}/Dockerfile" ]
then
  exit_with_usage "File not found: ${BUILD_PATH}/Dockerfile"
fi

# append build args found in docker_build_args_file
if [ ! -z "$BUILD_ARGS_FILE" ] && [ ! -f "$BUILD_ARGS_FILE" ]
then
  exit_with_usage "Build args file not found: $BUILD_ARGS_FILE"
fi
if [ ! -z "$BUILD_ARGS_FILE" ] && [ -f "$BUILD_ARGS_FILE" ]
then
  BUILD_ARGS="$BUILD_ARGS $(echo $(cat $BUILD_ARGS_FILE | sed 's/^/--build-arg /g'))"
fi

# append build args found on command line
BUILD_ARGS="$BUILD_ARGS $*"

IMAGE_NAME=bonitasoft/bonita

echo ". Building image <${IMAGE_NAME}>"
echo "Docker build caching strategy: --no-cache=${no_cache}"
build_cmd="docker build ${BUILD_ARGS} -t ${IMAGE_NAME}:latest ${BUILD_PATH}"
eval $build_cmd
BONITA_VERSION=$(docker inspect ${IMAGE_NAME}:latest -f '{{range .Config.Env}}{{println .}}{{end}}' | sed -n 's/^BONITA_VERSION=\(.*\)$/\1/p')
docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${BONITA_VERSION}

ARCHIVE_NAME=bonita_${BONITA_VERSION}.tar.gz
echo ". Saving image to archive file <${ARCHIVE_NAME}>"
docker save ${IMAGE_NAME}:${BONITA_VERSION} | gzip > ${ARCHIVE_NAME}

echo ". Done!"
