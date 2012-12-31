#!/bin/sh

URL_PRE="https://mlcs.medu.com/api/b2_registration/refresh_info?q=&carrier_code=&carrier_name=&device_name=&platform=&client_id="
URL_POST="&timestamp=&registration_id=&f=xml&device_id=&android=1&v=1&language=en_GB&ver=3.1.2"
MAX_CLIENT_ID=22000
showBar() {
    width=$((`tput cols` - 10 - 6))
    percent=$(( 100 * $1 / $2 ))
    printf "\r%3d%% [" $percent 1>&2

    # print progress bar
    bar=$((($width * $1) / $2))
    if [ "$bar" -gt "0" ]; then
        for i in $(seq 1 $bar); do printf "=" 1>&2; done
    fi
    if [ "$1" -ne "$2" ]; then
        printf ">"
        for i in $(seq $bar $(( $width))); do printf " " 1>&2; done
    else
        printf "=="
    fi
    printf "] %6d" $1 1>&2
}

OUTPUT_XML_FILE="output.xml"
FAILURE_FILE="badIds.md"
OUTPUT_MARKDOWN_FILE="output.md"

if [ -n "$1" ]; then
    OUTPUT_XML_FILE="$1"
fi
if [ -n "$2" ]; then
    FAILURE_FILE="$2"
fi
if [ -n "$3" ]; then
    OUTPUT_MARKDOWN_FILE="$3"
fi

mkdir raw > /dev/null 2>&1

clear
showBar 0 $MAX_CLIENT_ID

###XML FILE INIT
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<data>" > "$OUTPUT_XML_FILE"

###FAILURE FILE INIT
echo "Client ID's With No Support" > "$FAILURE_FILE"
echo "===========================" >> "$FAILURE_FILE"

###MARKDOWN FILE INIT
echo "Client Names Sorted By ID" > "$OUTPUT_MARKDOWN_FILE"
echo "=========================" >> "$OUTPUT_MARKDOWN_FILE"

for CLIENT_ID in $(seq 0 $MAX_CLIENT_ID); do
    TEMP_OUTPUT=`curl -s "$URL_PRE$CLIENT_ID$URL_POST"`
    if echo "$TEMP_OUTPUT" | fgrep -q "<s>" -; then
        echo "$TEMP_OUTPUT" | grep "[\\s]*<[^?].*$" - >> "$OUTPUT_XML_FILE"
        echo "$TEMP_OUTPUT" > "raw/$CLIENT_ID.xml"
        UNI_NAME=`echo "$TEMP_OUTPUT" | fgrep "<name>" - | sed -e "s|<name>\(<\!\[CDATA\[\)\{0,1\}\([^]<]*\)\(]]>\)\{0,1\}</name>|\2|"`
        B2_URL=`echo "$TEMP_OUTPUT" | fgrep "<b2_url>" - | sed -e "s/<b2_url>\(.*\)<\/b2_url>/\1/"`
        echo "$CLIENT_ID => $UNI_NAME (\`$B2_URL\`)" >> "$OUTPUT_MARKDOWN_FILE"
    else
        echo " - $CLIENT_ID" >> "$FAILURE_FILE"
    fi
    showBar $CLIENT_ID $MAX_CLIENT_ID
done
echo "</data>" >> "$OUTPUT_XML_FILE"
echo "Done"