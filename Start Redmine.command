#!/bin/zsh
# Start Redmine (Mac, zsh)
# - LF 줄바꿈 필수
# - 3000 점유 시 자동으로 4000 포트로 폴백
# - 서버 Health-check 후 브라우저 오픈

set -euo pipefail
setopt null_glob
setopt extended_glob

PROJECT_DIR="/Users/shs/Desktop/Git/redmine_opale"
cd "$PROJECT_DIR" || { echo "[FATAL] 프로젝트 경로 진입 실패: $PROJECT_DIR"; exit 1; }

THEME_DIR="$PROJECT_DIR/themes/opale-redmine-6.x"
LOG_DIR="$PROJECT_DIR/tmp/logs"
PID_DIR="$PROJECT_DIR/tmp/pids"
mkdir -p "$LOG_DIR" "$PID_DIR" tmp/cache tmp/pids

# PATH 및 rbenv
export PATH="/opt/homebrew/bin:$HOME/.rbenv/bin:$HOME/.local/bin:$PATH"
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init -)" || { echo "[FATAL] rbenv init 실패"; exit 1; }
  # 플러그인 호환 이슈 있으면 3.2.x로 바꿔 테스트
  export RBENV_VERSION="${RBENV_VERSION:-3.3.9}"
else
  echo "[WARN] rbenv 미설치: 시스템 Ruby 사용(비권장)"
fi

echo "[Info] ruby: $(command -v ruby || echo 'N/A') / $(ruby -v || echo 'N/A')"
echo "[Info] bundle: $(command -v bundle || echo 'N/A')"

# Bundler 설치/확인
if ! command -v bundle >/dev/null 2>&1; then
  gem install bundler -v '~> 2.5' --no-document
fi
bundle -v || { echo "[FATAL] bundler 확인 실패"; exit 1; }

# 의존성 설치
echo "[Step] bundle install/check"
if ! bundle check >/dev/null 2>&1; then
  bundle install --path vendor/bundle --jobs 4 --retry 2
fi

# secret token (태스크 존재 시에만)
echo "[Step] secret token 체크"
if [ ! -f "config/initializers/secret_token.rb" ]; then
  if bundle exec rake -T | grep -q "generate_secret_token"; then
    bundle exec rake generate_secret_token
  else
    echo "[Info] generate_secret_token 태스크 없음 - 스킵"
  fi
fi

# DB 마이그레이션
export RAILS_ENV="${RAILS_ENV:-development}"
echo "[Step] DB migrate ($RAILS_ENV)"
bundle exec rails db:environment:set || true
bundle exec rails db:migrate

# 정리
echo "[Cleanup] stopping old servers/watchers and clearing cache"
pkill -f "rails server" >/dev/null 2>&1 || true
pkill -f "grunt watch"  >/dev/null 2>&1 || true
[ -f "$PID_DIR/theme_watch.pid" ] && kill -TERM "$(cat "$PID_DIR/theme_watch.pid")" >/dev/null 2>&1 || true
rm -f tmp/pids/server.pid "$PID_DIR/theme_watch.pid" || true
rm -rf tmp/cache/*(N) || true

# 테마 watch (선택)
if [ -d "$THEME_DIR" ] && command -v npm >/dev/null 2>&1; then
  (
    cd "$THEME_DIR"
    echo "[Theme] npm install (ci fallback)"
    npm ci --silent || npm install --silent
    export LIVERELOAD_PORT=${LIVERELOAD_PORT:-35731}
    nohup npx grunt watch --verbose >> "$LOG_DIR/theme-watch.log" 2>&1 & echo $! > "$PID_DIR/theme_watch.pid"
  )
  echo "[Theme] watcher started (logs: $LOG_DIR/theme-watch.log)"
  
  # 테마 파일들을 public/themes로 링크
  echo "[Theme] public/themes 링크 생성"
  mkdir -p "public/themes/opale-redmine-6.x"
  ln -sf "../../../themes/opale-redmine-6.x/stylesheets" "public/themes/opale-redmine-6.x/stylesheets" 2>/dev/null || true
  ln -sf "../../../themes/opale-redmine-6.x/javascripts" "public/themes/opale-redmine-6.x/javascripts" 2>/dev/null || true
  ln -sf "../../../themes/opale-redmine-6.x/webfonts" "public/themes/opale-redmine-6.x/webfonts" 2>/dev/null || true
else
  echo "[Theme] 테마 감시는 스킵(npm 또는 디렉터리 없음)"
fi

# Rails 서버 상태 확인 및 시작 (3000→4000 폴백)
BIND_ADDR="${BIND_ADDR:-0.0.0.0}"
PORT_DEFAULT="${PORT:-3000}"
PORT="$PORT_DEFAULT"

# stale PID 정리
if [ -f tmp/pids/server.pid ] && ! ps -p "$(cat tmp/pids/server.pid)" >/dev/null 2>&1; then
  echo "[Rails] stale PID 제거"
  rm -f tmp/pids/server.pid
fi

# 포트 점유 시 4000으로 변경
if lsof -i :"$PORT" >/dev/null 2>&1; then
  echo "[WARN] ${PORT} 포트 점유됨 → 4000 포트로 변경"
  PORT=4000
fi

ROOT_URL="http://localhost:${PORT}"
HEALTH_URL="${ROOT_URL}/projects"

# 이미 떠 있으면 그대로 사용
if [ -f tmp/pids/server.pid ] && ps -p "$(cat tmp/pids/server.pid)" >/dev/null 2>&1; then
  echo "[Rails] 이미 실행 중 (PID $(cat tmp/pids/server.pid))"
else
  echo "[Step] Rails 서버 시작: ${ROOT_URL}"
  bundle exec rails server -d -b "$BIND_ADDR" -p "$PORT"
  echo "[Rails] started (logs: log/development.log)"
fi

# 서버 Health-check: 200/302까지 대기 (최대 30초)
echo "[Wait] 서버 기동 대기(최대 30초): ${HEALTH_URL}"
ok=0
for i in {1..30}; do
  code="$(curl -s -o /dev/null -w "%{http_code}" "${HEALTH_URL}" || echo 000)"
  if [[ "$code" == "200" || "$code" == "302" ]]; then
    ok=1; break
  fi
  sleep 1
done

if [[ $ok -eq 1 ]]; then
  echo "[OK] 서버 응답: ${code} → ${ROOT_URL}"
  # Chrome DevTools의 404 잡음 제거(선택)
  if [ ! -f "public/.well-known/appspecific/com.chrome.devtools.json" ]; then
    mkdir -p public/.well-known/appspecific
    printf '{}\n' > public/.well-known/appspecific/com.chrome.devtools.json || true
  fi
  command -v open >/dev/null 2>&1 && open "${ROOT_URL}" || true
  exit 0
else
  echo "[ERROR] 서버가 예상 시간 내 응답하지 않음."
  echo "------- tail log/development.log (마지막 200줄) -------"
  tail -n 200 log/development.log || true
  exit 1
fi