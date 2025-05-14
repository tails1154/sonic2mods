#!/bin/bash

# Make sure you're running inside an existing Git repo
if [ ! -d .git ]; then
  echo "This script must be run inside an existing Git repository."
  exit 1
fi

# Loop through all s2* directories that are Git repos
for dir in s2*/; do
  dir="${dir%/}"  # Remove trailing slash
  if [ yes ]; then
    echo "Merging $dir into subfolder..."

    # Add the repo as a remote
    git remote add "$dir" "./$dir"
    git fetch "$dir"

    # Create a new branch from the repo's main or master branch
    if git show-ref --verify --quiet "refs/remotes/$dir/main"; then
      git checkout -b "$dir-branch" "$dir/main"
    elif git show-ref --verify --quiet "refs/remotes/$dir/master"; then
      git checkout -b "$dir-branch" "$dir/master"
    else
      echo "No main or master branch found in $dir. Skipping."
      git remote remove "$dir"
      continue
    fi

    # Move files into a subfolder
    mkdir "$dir"
    git ls-tree --name-only HEAD | while read file; do
      [ "$file" != "$dir" ] && git mv "$file" "$dir/" 2>/dev/null
    done

    git commit -m "Move $dir files into subfolder"

    # Go back to main branch
    git checkout main
    git merge "$dir-branch" --allow-unrelated-histories -m "Merge $dir into monorepo"

    # Cleanup
    git branch -d "$dir-branch"
    git remote remove "$dir"
  else
    echo "Skipping $dir — not a Git repo."
  fi
done

echo "✅ All s2* repos merged into this repository."
