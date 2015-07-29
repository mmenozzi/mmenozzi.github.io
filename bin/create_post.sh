#!/usr/bin/env bash
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BASE_DIR=$(dirname "${SCRIPT_DIR}")

title=$1
if [ -z "${title}" ]; then
    echo "Title is required!"
    exit 1
fi

slug="$(echo -n "${title}" | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z)"
date=$(date +"%Y-%m-%d")
filename="${BASE_DIR}/_posts/${date}-${slug}.md"

if [ -f "${filename}" ]; then
    echo "File ${filename} already exists! Skipping."
    exit 1
fi

echo "---" >> ${filename}
echo "layout:   post" >> ${filename}
echo "title:    \"${title}\"" >> ${filename}
echo "date:     ${date} 00:00:00" >> ${filename}
echo "author:   \"Manuele Menozzi\"" >> ${filename}
echo "tags:     []" >> ${filename}
echo "---" >> ${filename}

echo "Post created in ${filename}"
