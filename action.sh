#!/bin/bash

# Fail if variables are unset
set -eu -o pipefail

echo '🚧 Check for configuration file'
if [ -f "./config.toml" ]; then
    echo "Hugo TOML configuration file found."
elif [ -f "./config.yaml" ]; then
    echo "Hugo YAML configuration file found."
elif [ -f "./config.json" ]; then
    echo "Hugo JSON configuration file found."
else
    echo "🛑 No valid Hugo configuration file found. Stopping." && exit 1
fi

echo '🔧 Install tools'
npm init -y && npm install -y postcss postcss-cli autoprefixer

echo '🤵 Install Hugo'
HUGO_VERSION=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | jq -r '.tag_name')
apt-get install hugo
hugo version || exit 1

echo '👯 Clone remote repository'
git clone https://github.com/${REMOTE} ${DEST}

echo '🧹 Clean site'
if [ -d "${DEST}" ]; then
    rm -rf ${DEST}/*
fi

echo '🍳 Build site'
hugo ${HUGO_ARGS:-""} -d ${DEST}

echo '🎁 Publish to remote repository'
COMMIT_MESSAGE=${INPUT_COMMIT_MESSAGE}
[ -z $COMMIT_MESSAGE ] && COMMIT_MESSAGE="🚀 Deploy with ${GITHUB_WORKFLOW}"

cd ${DEST}
git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git add .
git commit -am "$COMMIT_MESSAGE"

CONTEXT=${INPUT_BRANCH-master}
[ -z $CONTEXT ] && CONTEXT='master'

git push -f -q https://${TOKEN}@github.com/${REMOTE} $CONTEXT
