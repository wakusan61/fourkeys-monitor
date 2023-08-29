#!/bin/bash
set -e

token=$GOOGLE_TOKEN
url=$SPREAD_SHEET_URL
if [ "" == url] ; then
  echo "URLが設定されていません。SPREAD_SHEET_URLをSecretsに設定してください。"
  exit 3
fi 
# Get the date and author of all merge commits on the main branch
commit_info=$(git log --merges --first-parent --pretty=format:'%aI "%an" %H' $1 main)
# Save the data to Google SpreadSheet
echo "$commit_info" | while read line; do
  commit_date=$(echo $line | awk '{print $1}')
  commit_author=$(echo $line | awk -F'"' '{print $2}')
  commit_hash=$(echo $line | awk -F'"' '{print $3}')
  echo $commit_date $commit_author $commit_hash
  # GitHub Actions は対象外のため除外
  if [ "GitHub Action" != "$commit_author" ]; then
    response=$(curl -s -w "\n%{http_code}\n" -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" -d "{\"date\":\"$commit_date\",\"author\":\"$commit_author\", \"hash\":\"$commit_hash\"}" -L $url)
    if [ $(echo "$response" | tail -n 1) -ne 200 ]; then
      echo "エラー：POSTリクエストの送信に失敗しました。レスポンスボディ：$response" >&2; exit 1;
    fi
  fi
done