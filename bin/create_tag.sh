#!/usr/bin/env bash
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BASE_DIR=$(dirname "${SCRIPT_DIR}")

name=$1
if [ -z "${name}" ]; then
    echo "A tag name is required! Usage: create_tag.sh <tag_name>"
    exit 1
fi

slug="$(echo -n "${name}" | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z)"

filename="${BASE_DIR}/blog/tag/${slug}.md"
echo "---" >> ${filename}
echo "layout: blog_by_tag" >> ${filename}
echo "title: 'Articles by tag: ${name}'" >> ${filename}
echo "tag: ${slug}" >> ${filename}
echo "---" >> ${filename}

tagsfile="${BASE_DIR}/_data/tags.yml"
echo "" >> ${tagsfile}
echo "- slug: ${slug}" >> ${tagsfile}
echo "  name: ${name}" >> ${tagsfile}

echo "Created the a new tag '${name}' with slug '${slug}'!"