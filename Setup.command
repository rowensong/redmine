#!/bin/zsh
set -euo pipefail

echo "==== Redmine 초기 셋업 시작 ===="

PROJECT_DIR="/Users/shs/Desktop/Git/redmine_opale"
cd "$PROJECT_DIR" || exit 1

# 공통 경로
export PATH="$HOME/.homebrew/bin:$HOME/.rbenv/bin:$HOME/.local/bin:$PATH"
LOG_DIR="$PROJECT_DIR/tmp/logs"
PID_DIR="$PROJECT_DIR/tmp/pids"
mkdir -p "$LOG_DIR" "$PID_DIR"

# 1) Homebrew(로컬) 설치
if ! command -v brew >/dev/null 2>&1; then
  echo "[Homebrew] 로컬 홈에 설치합니다 (~/.homebrew)"
  git clone https://github.com/Homebrew/brew ~/.homebrew
  export PATH="$HOME/.homebrew/bin:$PATH"
fi

# 2) rbenv + ruby-build 설치
if ! command -v rbenv >/dev/null 2>&1; then
  echo "[rbenv] 설치 중"
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  mkdir -p ~/.rbenv/plugins
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

# 3) zshrc에 PATH/rbenv init 영구 반영 (중복 방지)
if ! grep -q 'export PATH="$HOME/.rbenv/bin:$PATH"' ~/.zshrc 2>/dev/null; then
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
fi
if ! grep -q 'export PATH="$HOME/.homebrew/bin:$PATH"' ~/.zshrc 2>/dev/null; then
  echo 'export PATH="$HOME/.homebrew/bin:$PATH"' >> ~/.zshrc
fi
if ! grep -q 'eval "$(rbenv init - zsh)"' ~/.zshrc 2>/dev/null; then
  echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
fi

# 현재 세션에 rbenv 적용
eval "$(~/.rbenv/bin/rbenv init - zsh)"

# 4) OpenSSL/libyaml (소스 빌드, 존재 시 생략)
OPENSSL_PREFIX="$HOME/.local/openssl"
LIBYAML_PREFIX="$HOME/.local/libyaml"

if [ ! -x "$OPENSSL_PREFIX/bin/openssl" ]; then
  echo "[OpenSSL] 빌드/설치 중 ($OPENSSL_PREFIX)"
  SRC="$HOME/.local/src"; mkdir -p "$SRC"; cd "$SRC"
  curl -fL -O https://www.openssl.org/source/openssl-3.3.2.tar.gz || \
  curl -fL -O https://www.openssl.org/source/openssl-3.3.1.tar.gz || \
  curl -fL -O https://www.openssl.org/source/openssl-3.3.0.tar.gz
  TARBALL=$(ls -1 openssl-3.3*.tar.gz | head -n 1)
  tar -xf "$TARBALL"
  DIR=$(tar -tf "$TARBALL" | head -n 1 | cut -d/ -f1)
  cd "$DIR"
  ./Configure darwin64-arm64-cc --prefix="$OPENSSL_PREFIX" --libdir=lib no-ssl3 no-comp no-hw no-engine
  make -j"$(sysctl -n hw.ncpu)"
  make install_sw
fi

if [ ! -f "$LIBYAML_PREFIX/lib/libyaml.dylib" ]; then
  echo "[libyaml] 빌드/설치 중 ($LIBYAML_PREFIX)"
  SRC="$HOME/.local/src"; mkdir -p "$SRC"; cd "$SRC"
  curl -fL -O https://github.com/yaml/libyaml/releases/download/0.2.5/yaml-0.2.5.tar.gz
  tar -xf yaml-0.2.5.tar.gz && cd yaml-0.2.5
  ./configure --prefix="$LIBYAML_PREFIX"
  make -j"$(sysctl -n hw.ncpu)"
  make install
fi

cd "$PROJECT_DIR"

# 5) Ruby 3.3.9 설치 및 활성화
export OPENSSL_DIR="$OPENSSL_PREFIX"
export LIBYAML_DIR="$LIBYAML_PREFIX"
export LDFLAGS="-L$OPENSSL_DIR/lib -L$LIBYAML_DIR/lib"
export CPPFLAGS="-I$OPENSSL_DIR/include -I$LIBYAML_DIR/include"
export PKG_CONFIG_PATH="$OPENSSL_DIR/lib/pkgconfig:$LIBYAML_DIR/lib/pkgconfig"

if ! rbenv versions --bare | grep -q '^3\.3\.9$'; then
  echo "[Ruby] 3.3.9 설치 중 (rbenv)"
  RUBY_CONFIGURE_OPTS="--with-openssl-dir=$OPENSSL_DIR --with-libyaml-dir=$LIBYAML_DIR --enable-shared" \
  rbenv install -s 3.3.9
fi
rbenv global 3.3.9
hash -r
echo "Ruby 버전: $(ruby -v)"

# 6) Bundler 설치
if ! gem list -i bundler >/dev/null 2>&1; then
  gem install bundler -v '~> 2.5' --no-document
fi

# 7) DB 설정 파일 준비(없으면 SQLite 기본값 생성)
if [ ! -f "config/database.yml" ]; then
  cat > config/database.yml <<'YML'
default: &default
  adapter: sqlite3
  pool: 5
  timeout: 5000

development:
  <<: *default
  database: db/redmine_development.sqlite3

test:
  <<: *default
  database: db/redmine_test.sqlite3

production:
  <<: *default
  database: db/redmine_production.sqlite3
YML
fi

# 8) 의존성 설치
bundle config set --local path 'vendor/bundle'
bundle install

# 9) 시크릿 생성 + DB 준비 + 기본 데이터(한국어)
if [ ! -f "config/initializers/secret_token.rb" ]; then
  bundle exec rake generate_secret_token
fi

bundle exec rails db:create db:migrate
REDMINE_LANG=ko bundle exec rake redmine:load_default_data || true

# 10) 테마 npm 의존성 (선택)
THEME_DIR="$PROJECT_DIR/themes/opale-redmine-6.x"
if [ -d "$THEME_DIR" ] && command -v npm >/dev/null 2>&1; then
  echo "[Theme] npm install"
  (cd "$THEME_DIR" && npm ci --silent || npm install --silent)
else
  echo "[Theme] npm이 없어 테마 의존성 설치를 건너뜁니다 (선택 사항)"
fi

echo "==== 초기 셋업 완료 ===="
echo "- 이제 'Start Redmine.command'를 더블클릭하여 서버와 테마 감시를 실행하세요."


