# Redmine Opale - 로컬 개발 실행 가이드

## 요구 사항

- macOS (Apple Silicon 권장)
- 인터넷 연결

## 1) 최초 셋업(자동)

프로젝트 루트의 `Setup.command`를 더블클릭하세요. 자동으로 다음을 수행합니다.

- Homebrew(로컬, `~/.homebrew`) 설치
- rbenv + ruby-build 설치 및 셸 설정 반영
- OpenSSL 3.3.x / libyaml 소스 빌드(사용자 홈 경로)
- Ruby 3.3.9 설치/활성화(rbenv)
- Bundler 설치 및 `bundle install`
- `config/database.yml` 미존재 시 SQLite 기본값 생성
- 시크릿 토큰 생성, DB 생성/마이그레이션, 기본 데이터 로드(한국어)
- 테마(`themes/opale-redmine-6.x`) npm 의존성 설치(설치된 경우)

완료 후, 터미널 재시작 없이도 곧바로 실행이 가능합니다.

## 2) 서버/테마 실행(원클릭)

- `Start Redmine.command` 더블클릭
  - rbenv 초기화 + Ruby 3.3.9 사용
  - Bundler 확인/설치 및 의존성 체크
  - 시크릿 토큰 생성(없을 때만)
  - `rails db:migrate`
  - 실행 전 정리: 기존 서버/워처 종료, PID 정리, `tmp/cache/*` 캐시 삭제
  - 테마 자동 감시(`npm run watch`) 백그라운드 실행
    - SCSS: 저장 시 자동 컴파일 → `themes/opale-redmine-6.x/stylesheets/application.css`
    - JS: `themes/opale-redmine-6.x/src/js/**/*.js` 저장 시 자동 복사 → `themes/opale-redmine-6.x/javascripts/`
    - 자동 새로고침(안전 모드): CSS 산출물(`stylesheets/*.css`) 변경 시에만 라이브리로드 트리거
  - 공개 경로 링크 보장: `public/themes/opale-redmine-6.x/{stylesheets,webfonts,javascripts}` → 실제 테마 산출물로 심볼릭 링크
    - 로그: `tmp/logs/theme-watch.log`
    - PID: `tmp/pids/theme_watch.pid`
  - 서버 실행: http://localhost:3000

이미 서버가 실행 중이면 브라우저만 열고 종료합니다.

## 3) SCSS/JS 수정 방법

### SCSS 수정

- 편집 위치: `themes/opale-redmine-6.x/src/sass/**/*.scss` (예: `src/sass/application.scss`)
- 실행 중인 워처: `Start Redmine.command`가 `npm run watch`를 백그라운드로 실행합니다.
  - SCSS 저장 → 빌드만 수행(리로드 없음) → CSS 산출물 변경 시에만 자동 새로고침
  - JS 저장 → `javascripts/`로 복사(기본은 수동 새로고침)
- 저장하면 자동으로 컴파일되어 아래 파일이 갱신됩니다:
  - 출력: `themes/opale-redmine-6.x/stylesheets/application.css`
- 브라우저에서 페이지 새로고침만 하면 반영됩니다.

명령어로 직접(대안):

```bash
cd themes/opale-redmine-6.x
npm install
# 새 창: 워처만 실행 (SCSS/JS 자동 반영)
npm run watch
# 또는
npm run build   # 1회 빌드
```

### JS 수정

- 편집 위치: `themes/opale-redmine-6.x/src/js/**/*.js`
- 실행 중인 워처: 저장 시 자동으로 아래 경로로 복사됩니다.
  - 출력: `themes/opale-redmine-6.x/javascripts/**/*.js`
- 브라우저에서 페이지 새로고침만 하면 최신 파일이 서빙됩니다.
- (페이지에 포함) 필요한 화면에서 `<script src="/themes/opale-redmine-6.x/javascripts/파일명.js"></script>` 형태로 포함해 사용할 수 있습니다. 운영 방식에 따라 레이아웃/플러그인/커스텀 HTML 등을 활용하세요.

## 3) 기본 계정

- ID: `admin`
- PW: `admin` (첫 로그인 시 변경 필요)

## 4) 문제 해결

- Node/npm 미설치로 테마 자동 감시가 비활성화될 수 있습니다. 필요 시:
  ```bash
  brew install node
  ```
  설치 후 테마 패키지 설치:
  ```bash
  cd themes/opale-redmine-6.x
  npm install
  ```
- 포트 점유로 서버가 뜨지 않으면 기존 프로세스를 종료하세요:
  ```bash
  lsof -n -P -iTCP:3000 -sTCP:LISTEN
  kill -9 <PID>
  ```
- 첫 요청이 느린 경우(개발 모드)
  - 브라우저 강력 새로고침(Cmd+Shift+R) 또는 시크릿 창으로 테스트
  - 127.0.0.1로 접속: http://127.0.0.1:3000 (hosts/프록시 영향 최소화)
  - LiveReload 비활성화 비교: `pkill -f "rails server"; bundle exec rails server -d -b 0.0.0.0 -p 3000`
  - 심볼릭 링크 확인: `public/themes/opale-redmine-6.x` 아래가 `stylesheets/webfonts/javascripts`로 연결되어 있는지 확인
  - dev 캐시 토글: `bundle exec rails dev:cache`
  - 서버 캐시 삭제: `rm -rf tmp/cache/*`

## 6) 최근 변경 요약(속도/안정화)

- Start 실행 시 자동 정리: 기존 서버/워처 종료, PID/캐시 정리 후 재기동
- 테마 링크 최소화: 산출물(Stylesheets/Webfonts/Javascripts)만 `public/themes`로 노출
- 개발환경에서 테마 경로를 정적 `/themes/...`로 서빙하여 Propshaft 스캔/지연 제거
- 안전한 자동 새로고침: CSS 산출물 변경 시에만 트리거(빌드 전 리로드로 인한 404 방지)
- Ruby 빌드 실패 시 `Setup.command`를 다시 실행해 의존성(OpenSSL/libyaml) 경로를 재설정하세요.

## 5) MySQL로 전환(선택)

1. MySQL 설치/구동

```bash
brew install mysql
brew services start mysql
mysql -u root -e "CREATE DATABASE redmine_development CHARACTER SET utf8mb4;"
```

2. `config/database.yml` 수정

```yaml
development:
  adapter: mysql2
  database: redmine_development
  host: localhost
  username: root
  password: ''
  encoding: utf8mb4
  variables:
    transaction_isolation: 'READ-COMMITTED'
```

3. 의존성 및 마이그레이션

```bash
bundle install
bundle exec rails db:create db:migrate
```

4. scss watch 는 수동으로 돌려야함 (프로젝트 폴더에서 실행필요)

```
npm run watch
```
