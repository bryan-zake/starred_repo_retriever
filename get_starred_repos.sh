#!/bin/bash

#############################################################################
# MIT License
# Copyright (c) 2020-Present Bryan Zake
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#############################################################################

#############################################################################
# Get all the starred repos for your github user.
# This file doesn't cover duplicate named starred repos
# You will need to add an authorization.sh file to your directory
# That way you get the AUTHORIZATION_TOKEN for your user
# Pass in a $DIRECTORY value if you'd like. Otherwise writes and creates a repos directory
#############################################################################

source authorization.sh
# Determine the number of pages of starred repos you need to get prior to and modify this value
NUMBER_OF_PAGES=10
API_URL=https://api.github.com/user/starred?page=

if [ -z "$1" ]; then
    mkdir repos
    DIRECTORY="repos"
else
    DIRECTORY=$1
fi

for ((i=0; i <= $NUMBER_OF_PAGES; i+=1)); do
  contents=$(curl -H "Authorization: token $AUTHORIZATION_TOKEN" "$API_URL$i")
  echo "Page "$i
  echo "$contents" > $i.json
done

# Put all the starred github urls into a single file and clean up the fluff around the url
cat *.json | grep \"url\" | grep -v licenses | grep -v users | grep -v null | sed -e 's/\(\"url\": \"\)//g' | sed -e 's/\(\"\,\)//g' > starred_urls.data

# Clone all the starred repos or check if a refresh can be performed with a pull on an existing repo
while read repo; do
  # Strip the trailing whitespace in the repo url
  repo=$(echo "$repo" | tr -d '[:space:]')
  echo 'Refreshing or Cloning into '$repo

  # Check whether or not to pull the repo if it already exists
  # Get the repo_name as this will be the directory we check to determine whether to do a pull
  repo_name=$(echo $repo  | rev | sed 's/\/.*//' | rev)
  if [[ -d $DIRECTORY"/"$repo_name ]]; then
    cd $DIRECTORY"/"$repo_name
    git pull --all
    echo
  else
    echo "Cloning "$DIRECTORY"/"$repo_name
    # The url given is not clonable in its current form so replace it with the clonable url
    api_url="api.github.com/repos"
    html_url="github.com"
    html_repo=${repo/$api_url/$html_url}.git
    # Finally, clone our starred repo into our directory
    # Note that we accept an argument, which can be a directory.
    git clone $html_repo $DIRECTORY"/"$repo_name
  fi
done < starred_urls.data
