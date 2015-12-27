#!/bin/bash
# Variables
if [[ -n "$WERCKER_BITBUCKET_CREATE_PR_DEST_BRANCH" ]]; then
  DESTINATION_BRANCH=',
    "destination": {
           "branch": {
               "name": "'$WERCKER_BITBUCKET_CREATE_PR_DEST_BRANCH'"
           }
      }'
fi
if [[ -z "$WERCKER_BITBUCKET_CREATE_PR_EXCLUDE" ]]; then
  WERCKER_BITBUCKET_CREATE_PR_EXCLUDE="master"
fi
RESULT="$WERCKER_STEP_TEMP/result.json"
JQ=$WERCKER_STEP_ROOT/bin/jq

# Functions
function fail() {
  echo "$1"
  exit 1
}

function failWithResult() {
  echo "$1"
  if [[ -f "$RESULT" ]]; then
    cat "$RESULT" | $JQ .
  fi
  exit 1 
}

function doPost() {
  POST='curl -X POST -H "Content-Type: application/json" -s 
        -u '$WERCKER_BITBUCKET_CREATE_PR_USERNAME':'$WERCKER_BITBUCKET_CREATE_PR_PASSWORD' 
        --output '$RESULT' 
        -w "%{http_code}" 
        https://api.bitbucket.org/2.0/repositories/'$WERCKER_GIT_OWNER'/'$WERCKER_GIT_REPOSITORY'/pullrequests 
        -d '"'"'
        {
            "title": "Opened by wercker step",
            "source": {
                "branch": {
                    "name": "'$WERCKER_GIT_BRANCH'"
                }
            }'$DESTINATION_BRANCH'
        }
        '"'"''
  RESULT_CODE=$(eval $POST)
}

function verifyResult {
  if [[ "$RESULT_CODE" = "201" ]]; then
    echo "PR link: $(cat "$RESULT" | $JQ .links.html.href)"
    return 0
  fi

  echo $RESULT_CODE
  if [ "$RESULT_CODE" = "400" ]; then
    failWithResult "Bad request"
  elif [ "$RESULT_CODE" = "401" ]; then
    failWithResult "Invalid username or password"
  elif [ "$RESULT_CODE" = "404" ]; then
    failWithResult "Subdomain or token not found."
  elif [ "$RESULT_CODE" = "500" ]; then
    if grep -Fqx "No token" $WERCKER_STEP_TEMP/result.txt; then
      failWithResult "No token is specified."
    fi

    if grep -Fqx "No hooks" $WERCKER_STEP_TEMP/result.txt; then
      failWithResult "No hook can be found for specified subdomain/token"
    fi

    if grep -Fqx "Invalid channel specified" $WERCKER_STEP_TEMP/result.txt; then
      failWithResult "Could not find specified channel for subdomain/token."
    fi

    if grep -Fqx "No text specified" $WERCKER_STEP_TEMP/result.txt; then
      failWithResult "No text specified."
    fi
  else
    failWithResult "Unknown error."
  fi
}

# Validations
if [ -z "$WERCKER_BITBUCKET_CREATE_PR_PASSWORD" ]; then
  fail 'Missing password property'
fi

if [ -z "$WERCKER_BITBUCKET_CREATE_PR_USERNAME" ]; then
  fail 'Missing username property'
fi

if [ -n "$DEPLOY" ]; then
  fail 'Should be used for build steps'
fi

if [[ "$WERCKER_GIT_BRANCH" =~ $WERCKER_BITBUCKET_CREATE_PR_EXCLUDE ]]; then
  echo "Branch '$WERCKER_GIT_BRANCH' match to exclude filter '$WERCKER_BITBUCKET_CREATE_PR_EXCLUDE'"
  echo "Exiting step"
  return 0
fi

# Execution
if [ "$WERCKER_RESULT" = "passed" ]; then
  rm -f "$RESULT"
  doPost
  verifyResult
fi
