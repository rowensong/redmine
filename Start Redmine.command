#!/bin/zsh
set -euo pipefail

PROJECT_DIR="/Users/shs/Desktop/Git/redmine_opale"
cd "$PROJECT_DIR" || exit 1

# 테마/로그/프로세스 경로
THEME_DIR="$PROJECT_DIR/themes/opale-redmine-6.x"
LOG_DIR="$PROJECT_DIR/tmp/logs"
PID_DIR="$PROJECT_DIR/tmp/pids"
mkdir -p "$LOG_DIR" "$PID_DIR"

# PATH 및 rbenv 초기화
export PATH="$HOME/.rbenv/bin:$HOME/.homebrew/bin:$HOME/.local/bin:$PATH"
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
  # 이 프로젝트에서 사용할 루비 버전 고정 (설치되어 있음)
  export RBENV_VERSION="3.3.9"
fi

# Bundler 확인/설치
if ! command -v bundle >/dev/null 2>&1; then
  gem install bundler -v '~> 2.5' --no-document
fi

# 의존성 설치 (필요 시)
bundle check >/dev/null 2>&1 || bundle install

# 시크릿 토큰 생성 (없을 때만)
if [ ! -f "config/initializers/secret_token.rb" ]; then
  bundle exec rake generate_secret_token
fi

# DB 마이그레이션
bundle exec rails db:migrate

# 워처/서버 정리 및 캐시 비우기
echo "[Cleanup] stopping old servers/watchers and clearing cache"
pkill -f "rails server" >/dev/null 2>&1 || true
pkill -f "grunt watch" >/dev/null 2>&1 || true
test -f "$PID_DIR/theme_watch.pid" && kill -TERM "$(cat "$PID_DIR/theme_watch.pid")" >/dev/null 2>&1 || true
rm -f tmp/pids/server.pid "$PID_DIR/theme_watch.pid"
rm -rf tmp/cache/*

# 테마 SCSS 감시(자동 컴파일) 시작
if [ -d "$THEME_DIR" ]; then
  if command -v npm >/dev/null 2>&1; then
    # 의존성 설치 (최초 1회 정도만)
    (
      cd "$THEME_DIR"
      npm ci --silent || npm install --silent
    )
    # 워처 강제 재시작 (포트 충돌 방지: 고정 포트 사용)
    (
      cd "$THEME_DIR"
      export LIVERELOAD_PORT=${LIVERELOAD_PORT:-35731}
      nohup npx grunt watch --verbose >> "$LOG_DIR/theme-watch.log" 2>&1 & echo $! > "$PID_DIR/theme_watch.pid"
    )
    echo "[Theme] watcher started (port:$LIVERELOAD_PORT, logs: $LOG_DIR/theme-watch.log)"

    # 공개 경로에 테마 산출물만 노출(절대 경로 심볼릭 링크)
    PUBLIC_THEME_DIR="$PROJECT_DIR/public/themes/opale-redmine-6.x"
    mkdir -p "$PUBLIC_THEME_DIR"
    ln -snf "$THEME_DIR/stylesheets"  "$PUBLIC_THEME_DIR/stylesheets"
    ln -snf "$THEME_DIR/webfonts"     "$PUBLIC_THEME_DIR/webfonts"
    ln -snf "$THEME_DIR/javascripts"  "$PUBLIC_THEME_DIR/javascripts"
  else
    echo "[Theme] npm이 없어 SCSS 자동 반영이 비활성화되었습니다. Homebrew 사용 시: brew install node"
  fi
fi

# 이미 서버가 떠 있으면 브라우저만 열고 종료
if [ -f tmp/pids/server.pid ] && ps -p "$(cat tmp/pids/server.pid)" >/dev/null 2>&1; then
  echo "Redmine already running on http://localhost:3000"
  command -v open >/dev/null 2>&1 && open "http://localhost:3000" || true
  exit 0
fi

echo "Starting Redmine on http://localhost:3000"
command -v open >/dev/null 2>&1 && open "http://localhost:3000" || true

# 서버 실행 (데몬)
# 1) stale PID 정리
if [ -f tmp/pids/server.pid ] && ! ps -p "$(cat tmp/pids/server.pid)" >/dev/null 2>&1; then
  echo "[Rails] removing stale PID file"
  rm -f tmp/pids/server.pid
fi

# 2) 이미 실행 중인지 확인
if [ -f tmp/pids/server.pid ] && ps -p "$(cat tmp/pids/server.pid)" >/dev/null 2>&1; then
  echo "[Rails] already running (PID $(cat tmp/pids/server.pid))"
else
  bundle exec rails server -d -b 0.0.0.0 -p 3000
  echo "[Rails] started (logs: log/development.log)"
fi

exit 0


