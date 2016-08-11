#!/usr/bin/env sh

# only publish appcast for master branch
export SOURCE_BRANCH="master"
export APPCAST_BRANCH="gh-pages"

if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]; then
    exit 0
fi

# remove all redundant files
find . -not -name "appcast" -not -name ".git" -maxdepth 1 -print0 | xargs -0 rm -rf --
# copy appcast files to root
cp -r appcast/. .
rm -rf appcast/

# push update
git checkout --orphan gh-pages
git add .
git -c user.name="Travis CI" commit -m "Publish appcast"
git push --force --quiet https://$GITHUB_API_KEY@github.com/zhuhaow/SpechtLite.git gh-pages > /dev/null 2>&1
