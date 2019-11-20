#!/bin/bash

build_root=$(pwd)
patches_path="$build_root/vendor/extra/patch/device/$MY_BUILD/"
pushd "$patches_path" > /dev/null
unset repos
for patch in `find -type f -name '*.patch'|cut -d / -f 2-|sort`; do
    # Strip patch title to get git commit title - git ignore [text] prefixes in beginning of patch title during git am
    title=$(sed -rn "s/Subject: (\[[^]]+] *)*//p" "$patch")
    absolute_patch_path="$patches_path/$patch"
    # Supported both path/to/repo_with_underlines/file.patch and path_to_repo+with+underlines/file.patch (both leads to path/to/repo_with_underlines)
    repo_to_patch="$(if dirname $patch|grep -q /; then dirname $patch; else dirname $patch |tr '_' '/'|tr '+' '_'; fi)"

    echo -e "Is ${CL_BLU}$repo_to_patch${CL_RST} patched for ${CL_BLU}'$title'${CL_RST} ? "

        if [ ! -d $build_root/$repo_to_patch ] ; then
                echo "$repo_to_patch NOT EXIST! Go away and check your manifests. Skipping this patch."
                continue
        fi

    pushd "$build_root/$repo_to_patch" > /dev/null
    if (git log |fgrep -qm1 "$title" ); then
        echo -n
      commit_hash=$(git log --oneline |fgrep -m1 "$title"|cut -d ' ' -f 1)
      if [ q"$commit_hash" != "q" ]; then
          commit_id=$(git format-patch -1 --stdout $commit_hash |git patch-id|cut -d ' ' -f 1)
          patch_id=$(git patch-id < $absolute_patch_path|cut -d ' ' -f 1)
          if [ "$commit_id" = "$patch_id" ]; then
              echo -e ${CL_GRN}'Yes, patch matches\n'${CL_RST}
          else
          echo -e ${CL_RED}"PATCH MISMATCH!: done"${CL_RST}
              sed '0,/^$/d' $absolute_patch_path|head -n -3  > /tmp/patch
              git show --stat $commit_hash -p --pretty=format:%b > /tmp/commit
              diff -u /tmp/patch /tmp/commit
              rm /tmp/patch /tmp/commit
              echo ' Resetting branch!'
              git checkout $commit_hash~1
              git am $absolute_patch_path || git am --abort
          fi
    else
        echo "Unable to get commit hash for '$title'! Something went wrong!"
        sleep 20
    fi
    else
        echo No
        echo -e ${CL_GRN}"Trying to apply patch $(basename "$patch") to '$repo_to_patch'"${CL_RST}
        if ! git am $absolute_patch_path; then
            echo -e ${CL_RED}"Failed, aborting git am"${CL_RST}
            git am --abort
                echo -e ${CL_RED}"Retry git am -3"${CL_RST}
                    if ! git am -3 $absolute_patch_path; then
                        echo -e ${CL_RED}"Failed -3, aborting git am"${CL_RST}
                        git am --abort
                    fi
        fi
    fi
    popd > /dev/null
done
popd > /dev/null
        echo -e ${CL_GRN}"Patching done"${CL_RST}
