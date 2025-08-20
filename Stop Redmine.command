#!/bin/zsh
# Stop Redmine (Mac, zsh)
# - Rails 서버와 테마 watch 프로세스를 모두 종료
# - PID 파일 정리

set -euo pipefail

PROJECT_DIR="/Users/shs/Desktop/Git/redmine_opale"
cd "$PROJECT_DIR" || { echo "[FATAL] 프로젝트 경로 진입 실패: $PROJECT_DIR"; exit 1; }

PID_DIR="$PROJECT_DIR/tmp/pids"
LOG_DIR="$PROJECT_DIR/tmp/logs"

echo "[Stop] 레드마인 서비스 종료 중..."

# 1. Rails 서버 종료
if [ -f "tmp/pids/server.pid" ]; then
  RAILS_PID=$(cat tmp/pids/server.pid)
  if ps -p "$RAILS_PID" >/dev/null 2>&1; then
    echo "[Rails] 서버 종료 중 (PID: $RAILS_PID)"
    kill -TERM "$RAILS_PID" 2>/dev/null || true
    sleep 2
    if ps -p "$RAILS_PID" >/dev/null 2>&1; then
      echo "[Rails] 강제 종료 (PID: $RAILS_PID)"
      kill -KILL "$RAILS_PID" 2>/dev/null || true
    fi
  else
    echo "[Rails] 서버가 이미 종료됨"
  fi
  rm -f tmp/pids/server.pid
else
  echo "[Rails] PID 파일 없음 - 프로세스 직접 종료"
fi

# 2. 테마 watch 프로세스 종료
if [ -f "$PID_DIR/theme_watch.pid" ]; then
  WATCH_PID=$(cat "$PID_DIR/theme_watch.pid")
  if ps -p "$WATCH_PID" >/dev/null 2>&1; then
    echo "[Theme] watch 프로세스 종료 중 (PID: $WATCH_PID)"
    kill -TERM "$WATCH_PID" 2>/dev/null || true
    sleep 1
    if ps -p "$WATCH_PID" >/dev/null 2>&1; then
      echo "[Theme] 강제 종료 (PID: $WATCH_PID)"
      kill -KILL "$WATCH_PID" 2>/dev/null || true
    fi
  else
    echo "[Theme] watch 프로세스가 이미 종료됨"
  fi
  rm -f "$PID_DIR/theme_watch.pid"
fi

# 3. 남은 프로세스 정리 (안전장치)
echo "[Cleanup] 남은 프로세스 정리"
pkill -f "rails server" >/dev/null 2>&1 || true
pkill -f "grunt watch" >/dev/null 2>&1 || true
pkill -f "bundle exec rails" >/dev/null 2>&1 || true

# 포트별 프로세스 강제 종료
echo "[Force] 포트별 프로세스 강제 종료"
for port in 3000 4000 35731; do
  if lsof -i :"$port" >/dev/null 2>&1; then
    echo "[Port $port] 프로세스 강제 종료"
    lsof -ti :"$port" | xargs kill -KILL 2>/dev/null || true
  fi
done

# 4. 포트 점유 확인
echo "[Check] 포트 점유 상태 확인"
if lsof -i :3000 >/dev/null 2>&1; then
  echo "[WARN] 3000 포트가 여전히 점유됨"
  lsof -i :3000
fi
if lsof -i :4000 >/dev/null 2>&1; then
  echo "[WARN] 4000 포트가 여전히 점유됨"
  lsof -i :4000
fi
if lsof -i :35731 >/dev/null 2>&1; then
  echo "[WARN] 35731 포트(LiveReload)가 여전히 점유됨"
  lsof -i :35731
fi

echo "[OK] 레드마인 서비스 종료 완료"
