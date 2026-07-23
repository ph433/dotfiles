#!/bin/bash
LAYER="$1"
# Tạo JSON chuẩn, không bị lỗi escape ký tự
JSON_PAYLOAD="{\"ChangeLayer\": {\"new\": \"$LAYER\"}}"

# Gửi qua netcat tới daemon
echo "$JSON_PAYLOAD" | nc -w 1 localhost 1234
