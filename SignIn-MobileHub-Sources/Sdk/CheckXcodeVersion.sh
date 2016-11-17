#!/bin/sh
#
# This script confirms that you are running a compatible version of
# Xcode. If your version is too old, then the project will not build
# properly.
#
if [ ${XCODE_VERSION_ACTUAL} -lt 710 ]; then
    echo "########################################################################" 1>&2
    echo "CheckXcodeVersion.sh: AWS Mobile Hub Xcode Version Checker" 1>&2
    echo 1>&2
    echo "ERROR: Detected unsupported version of Xcode: ${XCODE_VERSION_ACTUAL}." 1>&2
    echo 1>%2
    echo "AWS Mobile Hub projects require that you use a newer version of Xcode." 1>&2
    echo "Please upgrade to Xcode 7.1 or newer." 1>&2
    echo "########################################################################" 1>&2
    exit -1;
fi
