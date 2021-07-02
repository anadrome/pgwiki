#!/bin/bash

# Update a site to current Markdown sources
# Mark Nelson, 2021

# Arguments:
#   $1: the subdirectory to put the site into
#   $2: the GitHub URL where the source lives
# Note that we must be able to clone/pull from $2, either because it's public,
# or because the user running the CGI script has appropriate credentials.

shopt -s nullglob

# these should be absolute paths
HTMLDIR=
TMPDIR=

# Given a git repo's HTTPS url, how do we get a URL to view or edit specific
# files in a web interface? We chop off the .git extension, then append one of the
# strings below, and then append main/filename.md (TODO: don't hardcode the
# name of the main branch).
# The below defaults work on GitHub. For GitLab, they should be "-/blob/ and
# "-/edit/" instead.
GIT_WEB_VIEW="blob/"
GIT_WEB_EDIT="edit/"

# Clone or pull the repository
if [ ! -d "$1" ]
then
  git clone "$2" "$1"
  cd "$1"
  git config pull.rebase false # avoid noise in logs
else
  cd "$1"
  git pull "$2"
fi

# (Re)generate any new or updated pages
mkdir -p "$HTMLDIR/$1"
declare -A title
for page in *.md
do
  # pandoc's AST splits strings into an array of objects, so we have to join
  # them back together to get the title. E.g. "Two words" looks like:
  #   [ { "t": "Str", "c": "Two" }, { "t": "Space" }, { "t": "Str", "c": "words" } ]
  title[$page]=$(pandoc -t json $page | jq -r '.meta.title.c | map(if .t=="Space" then " " else .c end) | join("")')

  dest="$HTMLDIR/$1/${page%.md}.html"
  if [ ! -f "$dest" ] || [ "$page" -nt "$dest" ]
  then
    echo "----" > "$TMPDIR/footer.md"
    echo "[View Markdown Source](${2%.git}/$GIT_WEB_VIEW/main/$page) --- [Edit in Browser](${2%.git}/$GIT_WEB_EDIT/main/$page)" >> "$TMPDIR/footer.md"
    pandoc --standalone --mathjax -o "$dest" "$page" "$TMPDIR/footer.md"
    rm "$TMPDIR/footer.md"
  fi
done

# Delete any deleted pages
for path in "$HTMLDIR/$1/"/*
do
  file=${path##*/}
  if [ ! -f "${file%.html}.md" ]
  then
    rm "$path"
  fi
done

# Generate the ToC
printf "%% Table of contents\n\n" > "$TMPDIR/index.md"
for page in "${!title[@]}"
do
  echo "* [${title[$page]}](${page%.md}.html)" >> "$TMPDIR/index.md"
done
pandoc --standalone -o "$HTMLDIR/$1/index.html" "$TMPDIR/index.md"
rm "$TMPDIR/index.md"
