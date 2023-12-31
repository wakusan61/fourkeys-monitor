#!/bin/bash
set -e
git checkout main
git pull
since=""
if [ "yesterday" = "$1" ]; then
  since="--since=yesterday"
fi
# Debug
echo "::warning::since $since"
token=$GOOGLE_TOKEN
url=$SPREAD_SHEET_URL
# Get the date and author of all merge commits on the main branch
commit_info=$(git log --merges --first-parent $since --pretty=format:'%aI "%an" %H' main)
# Save the data to Google SpreadSheet
echo "$commit_info" | while read line; do
  commit_date=$(echo $line | awk '{print $1}')
  commit_author=$(echo $line | awk -F'"' '{print $2}')
  commit_hash=$(echo $line | awk -F'"' '{print $3}')
  echo $commit_date $commit_author $commit_hash
  # GitHub Actions は対象外のため除外
  if [ "GitHub Action" != "$commit_author" ]; then
    # Debug
    echo "::warning::Execute Action $commit_date $commit_author $commit_hash"
    response=$(curl -s -w "\n%{http_code}\n" -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" -d "{\"date\":\"$commit_date\",\"author\":\"$commit_author\", \"hash\":\"$commit_hash\"}" -L $url)
    if [ $(echo "$response" | tail -n 1) -ne 200 ]; then
      echo "エラー：POSTリクエストの送信に失敗しました。レスポンスボディ：$response" >&2; exit 1;
    fi
  fi
done