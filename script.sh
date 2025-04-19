#!/bin/sh
set -e
if [ -z "$1" ]; then
  echo "Usage: $0 <GuideNumber> <Duration> <unit string (hours/minutes)>"
  exit 1
fi
if [ -z "$2" ]; then
  echo "Duration Needed. $0 <GuideNumber> <Duration>"
  exit 1
fi
if [ -z "$3" ]; then
  echo "Unit String Needed. $0 <GuideNumber> <Duration> <unit string (hours/minutes)>"
  exit 1
fi
if [ "$3" = "hours" ]; then
  DURATION=$(($2 * 3600))
elif [ "$3" = "minutes" ]; then
  DURATION=$(($2 * 60))
else
  echo "Invalid unit string. Use 'hours' or 'minutes'."
  exit 1
fi
echo Downloading lineup
curl -s http://10.0.0.2/lineup.json > lineup.json
GuideName=$(cat lineup.json | jq -r ".[] | select(.GuideNumber == \"$1\") | .GuideName")
VideoCodec=$(cat lineup.json | jq -r ".[] | select(.GuideNumber == \"$1\") | .VideoCodec")
AudioCodec=$(cat lineup.json | jq -r ".[] | select(.GuideNumber == \"$1\") | .AudioCodec")
SupportsHD=$(cat lineup.json | jq -r ".[] | select(.GuideNumber == \"$1\") | .HD")
URL=$(cat lineup.json | jq -r ".[] | select(.GuideNumber == \"$1\") | .URL")
DATE=$(date +'%d-%m-%Y')
IADATE=$(date +'%Y-%m-%d')
StartTime=$(date +"%s")
if [ -z "$GuideName" ]; then
  echo "No channel found with GuideNumber $1"
  exit 1
fi
if [ "$SupportsHD" != 1 ]; then
    SupportsHD="0"
fi
echo "GuideName: $GuideName"
echo "VideoCodec: $VideoCodec"
echo "AudioCodec: $AudioCodec"
echo "Supports HD: $SupportsHD"
echo "Start Time: $StartTime"
aria2c "$URL?duration=$DURATION" --out "$1.mpeg"
EndTime=$(date +"%s")
#Generate identifier string and check if its available

ID=$(echo "$GuideName $DATE" | sed -E 's/[^a-zA-Z0-9]+/-/g; s/^-//; s/-$//; y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/')
echo "Checking if $ID is available"
METACHECK=$(ia metadata "$ID")
if [ "$METACHECK" != "{}" ]; then
  echo "ID is already in use. Adding start time epoch for randomness"
  ID=$(echo "$GuideName $DATE $StartTime" | sed -E 's/[^a-zA-Z0-9]+/-/g; s/^-//; s/-$//; y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/')
  else
  echo "Passed ID validation. Uploading."
fi
ia upload $ID "$1.mpeg" --metadata "title: $GuideName $DATE" --metadata "subject:tivibot" --metadata "subject:$GuideName" --metadata "date:$IADATE" --metadata "publisher:tivibot" --metadata "start-epoch:$StartTime" --metadata "end-epoch:$EndTime" --metadata "video-codec:$VideoCodec" --metadata "audio-codec:$AudioCodec" --metadata "supports-hd:$SupportsHD" --metadata "expected-duration:$DURATION" --metadata "channel-id:$1"