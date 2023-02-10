#!/bin/sh

# wolfsentry/scripts/pre-push.sh
#
# Copyright (C) 2021-2023 wolfSSL Inc.
#
# This file is part of wolfSentry.
#
# wolfSentry is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# wolfSentry is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1335, USA

# shellcheck disable=SC2034 # allow unused variables

if [ "$TMPDIR" = "" ]; then
    WORKDIR=/tmp/wolfsentry_for_push_hook.$$
else
    WORKDIR="${TMPDIR}/wolfsentry_for_push_hook.$$"
fi

trap 'rm -rf "$WORKDIR"' EXIT

remote="$1"
url="$2"

REPO_ROOT="$(git rev-parse --show-toplevel)" || exit $?

git clone -q --shared -n "$REPO_ROOT" "$WORKDIR" || exit $?
cd "$WORKDIR" || exit $?

if [ "$(uname -s)" = 'Linux' ]; then
    have_linux=y
else
    have_linux=n
fi

while read -r local_ref local_oid remote_ref remote_oid
do
    if [ "$local_ref" = "(delete)" ]; then
	continue
    fi
    git checkout -q "$local_oid" || exit $?
    if [ "$have_linux" = 'y' ]; then
	echo "make --quiet -j check for ${local_ref} at ${local_oid} ..."
	make --quiet -j FREERTOS_TOP="${REPO_ROOT}/../third/FreeRTOS/FreeRTOS/Source" LWIP_TOP="${REPO_ROOT}/../third/lwip/src" check || exit $?
    else
	echo "make --quiet -j test for ${local_ref} at ${local_oid} ..."
	make --quiet -j test || exit $?
    fi
done

exit 0
