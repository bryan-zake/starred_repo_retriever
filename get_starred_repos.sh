#!/bin/bash
# A somewhat simple bash program to get all the starred repos for your user.
# Goes to the github REST v3 API and pulls down the starred repos
# This file doesn't cover edge cases like duplicate repos 
# You will need to add an authorization.sh file to your directory 
# for your AUTHORIZATION_TOKEN to get your starred repos

source authorization.sh
# Determine the number of pages of starred repos you need to get 
NUMBER_OF_PAGES=10
API_URL=https://api.github.com/user/starred?page=

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
  if [[ -d $1$repo_name ]]; then
    cd $1$repo_name
    git pull --all
    echo
  else
    echo "Cloning "$1$repo_name
    # The url given is not clonable in its current form so replace it with the clonable url
    api_url="api.github.com/repos"
    html_url="github.com"
    html_repo=${repo/$api_url/$html_url}.git
    # Finally, clone our starred repo into our directory
    # Note that we accept an argument, which can be a directory. 
    git clone $html_repo $1$repo_name
  fi
done < starred_urls.data

