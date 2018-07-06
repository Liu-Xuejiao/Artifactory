#!/bin/bash

# Recursively deploys folder content. Attempt checksum deploy first to optimize upload time.

repo_url="http://screpo1.mul.ie.ibm.com"
tgt_repo="external-p2-local/org/codehaus/groovy-updatesite/2.9.2/"
user=xliu2@ie.ibm.com
pass=********

dir="$1"

if [ -z "$dir" ]; then echo "Please specify a directory to recursively upload from!"; exit 1; fi

if [ ! -x "`which sha1sum`" ]; then echo "You need to have the 'sha1sum' command in your path."; exit 1; fi

# Upload by checksum all files from the source dir to the target repo
find "$dir" -type f | sort | while read f; do
    rel="$(echo "$f" | sed -e "s#$dir##" -e "s# /#/#")";
    sha1=$(sha1sum "$f")
    sha1="${sha1:0:40}"
    printf "\n\nUploading '$f' (cs=${sha1}) to '${repo_url}/${tgt_repo}/${rel}'"
    status=$(curl -k -u $user:$pass -X PUT -H "X-Checksum-Deploy:true" -H "X-Checksum-Sha1:$sha1" --write-out %{http_code} --silent --output /dev/null "${repo_url}/${tgt_repo}/${rel}")
    echo "status=$status"
    # No checksum found - deploy + content
    [ ${status} -eq 404 ] && {
        curl -k -u $user:$pass -H "X-Checksum-Sha1:$sha1" -T "$f" "${repo_url}/${tgt_repo}/${rel}"
    }
done

