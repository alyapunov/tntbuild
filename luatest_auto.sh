#!/bin/bash

if ! [[ -f /tmp/luatest_auto.txt ]]; then
    echo "Error: luatest_auto.txt is not present"
    exit 1
fi

rm -f /tmp/luatest_auto.work.txt
mv /tmp/luatest_auto.txt /tmp/luatest_auto.work.txt

fileline=`head -n 1 /tmp/luatest_auto.work.txt`
value=`tail -n +2 /tmp/luatest_auto.work.txt`

if [[ "$value" == "" ]]; then
    echo "Error: no value"
    exit 1
fi

if [[ `echo "$value" | wc -l` -ne 1 ]]; then
    echo "Error: value is not one-line"
    exit 1
fi

value=$(echo "$value" | sed 's/\//\\\//g')
value=$(echo "$value" | sed 's/\[/\{/g')
value=$(echo "$value" | sed 's/\]/\}/g')
value=$(echo "$value" | sed -E "s/\{'([^']+)'\:/\{\1 =/g")
value=$(echo "$value" | sed -E "s/, '([^']+)'\:/, \1 =/g")
if ! [[ $value =~ ^.*\'.*$ ]]; then
    value=$(echo "$value" | sed "s/\"/'/g")
fi

if ! [[ "$fileline" =~ ^@(.*):([0-9]+)$ ]]; then
    echo "Error: Filed to parse filename and line"
    exit 1
fi

filename=${BASH_REMATCH[1]}
fileline=${BASH_REMATCH[2]}

if ! [[ -f "$filename" ]]; then
    echo "Error: test file was not found"
    exit 1
fi

if ! [[ -d /tmp/luatest_auto ]]; then
    mkdir /tmp/luatest_auto
fi

if ! [[ -f /tmp/luatest_auto/i ]]; then
    echo 0 > /tmp/luatest_auto/i
fi
i=`cat /tmp/luatest_auto/i`
tmp_file=`printf %02d $i`
tmp_file="/tmp/luatest_auto/backup$tmp_file"
((i=(i+1)%100))
echo $i > /tmp/luatest_auto/i

rm -f $tmp_file
mv "$filename" "$tmp_file"

((before=fileline-1))
head -n $before "$tmp_file" > "$filename"
tail -n "+$fileline" "$tmp_file" | sed -z "s/\"auto\"/$value/" >> "$filename"
