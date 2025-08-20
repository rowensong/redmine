#!/bin/zsh
# Restart Redmine (Mac, zsh)
# - 기존 서비스 종료 후 재시작

set -euo pipefail

PROJECT_DIR="/Users/shs/Desktop/Git/redmine_opale"
cd "$PROJECT_DIR" || { echo "[FATAL] 프로젝트 경로 진입 실패: $PROJECT_DIR"; exit 1; }

echo "[Restart] 레드마인 서비스 재시작 중..."

# 1. 기존 서비스 종료
if [ -f "Stop Redmine.command" ]; then
  echo "[Step] 기존 서비스 종료"
  ./Stop\ Redmine.command
  sleep 2
else
  echo "[WARN] Stop Redmine.command 파일 없음 - 수동으로 종료 필요"
fi

# 2. 서비스 재시작
if [ -f "Start Redmine.command" ]; then
  echo "[Step] 서비스 재시작"
  ./Start\ Redmine.command
else
  echo "[FATAL] Start Redmine.command 파일 없음"
  exit 1
fi

echo "[OK] 레드마인 서비스 재시작 완료"
