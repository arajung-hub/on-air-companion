# 설치와 사용 안내

## 다운로드 전 확인

On Air Companion은 Zoom의 마이크와 카메라 상태를 화면 한쪽에 띄워 주는 macOS 메뉴바 앱입니다.

Apple Silicon Mac과 macOS 13 이상을 대상으로 만든 수업용 베타입니다. Intel Mac과 Windows는 지원하지 않습니다. 다른 Mac과 Zoom 버전에서는 추가 검증 중입니다.

현재 파일에는 임시 코드 서명만 적용되어 있습니다. Developer ID 서명과 Apple 공증은 적용하지 않았으므로 첫 실행이 차단될 수 있습니다. 경고 없이 바로 실행되는 정식 배포본은 아직 준비하지 못했습니다.

## 다운로드

[Mac용 베타 설치 파일 (DMG)](https://github.com/arajung-hub/on-air-companion/releases/download/v0.4.7-beta/On-Air-Companion-0.4.7-beta-macOS.dmg)

[기존 ZIP 파일](https://github.com/arajung-hub/on-air-companion/releases/download/v0.4.7-beta/on-air-companion-beta-v14.zip)

[GitHub 최신 Release](https://github.com/arajung-hub/on-air-companion/releases/latest)

## 설치

1. DMG를 열고 안에 있는 On Air Companion 앱을 Applications 폴더로 끌어 옮깁니다.
2. Finder의 응용 프로그램 폴더에서 앱을 실행합니다. DMG 안의 앱을 바로 실행하지 않습니다.
3. 예전 버전이 실행 중이면 먼저 종료합니다.

ZIP을 받은 경우에는 압축을 풀고 앱을 응용 프로그램 폴더로 옮깁니다.

## 첫 실행이 차단되는 경우

출처를 신뢰하고 설치를 진행하려는 경우에만 직접 실행을 허용해 주세요. macOS에서 앱 실행을 시도한 뒤 시스템 설정의 개인정보 보호 및 보안에서 해당 앱의 ‘그래도 열기’를 선택하고 안내를 따릅니다. Apple이 확인한 앱이라는 뜻은 아닙니다. [Apple 공식 실행 안내](https://support.apple.com/ko-kr/102445)

‘컴퓨터를 손상시킴’이나 ‘손상된 앱’ 경고는 무시하지 마세요. 회사나 학교에서 관리하는 Mac은 관리자 정책에 따라 실행을 허용할 수 없을 수 있습니다.

macOS의 보안 보호를 전체적으로 끄는 방법이나 격리 속성을 제거하는 설치 스크립트는 제공하지 않습니다.

## 접근성 권한

Zoom의 버튼 상태를 읽기 위해 이 앱의 접근성 권한이 필요합니다.

1. 시스템 설정에서 개인정보 보호 및 보안을 엽니다.
2. 손쉬운 사용(접근성) 목록에서 On Air Companion을 찾습니다.
3. 없으면 + 버튼으로 응용 프로그램 폴더의 On Air Companion.app을 추가합니다.
4. 이 앱의 스위치를 켜고 앱을 종료한 뒤 다시 실행합니다.

다른 앱의 권한을 바꿀 필요는 없습니다.

권한을 켰는데도 ‘권한 필요’가 표시되면 예전 복사본이 함께 실행 중인지 확인합니다. 다운로드 폴더나 프로젝트 폴더의 예전 앱을 종료하고 응용 프로그램의 설치본만 실행합니다. 앱 업데이트 후에는 이 앱의 등록을 다시 확인해야 할 수 있습니다.

## 사용

메뉴바 아이콘을 눌러 기본형 또는 동물형을 고릅니다. 동물형에서는 원하는 동물을 선택할 수 있습니다.

Zoom 데스크톱 앱에서 회의에 들어간 뒤 마이크와 카메라 상태를 바꾸면 알림창에 반영됩니다. 회의가 없으면 알림창이 숨고 메뉴바 아이콘만 남습니다. 메뉴바 앱이라 Dock에 아이콘이 계속 나타나지는 않습니다.

이 앱은 Zoom의 마이크와 카메라를 직접 켜거나 끄지 않습니다. 상태가 잘못 보이면 Zoom 자체 아이콘으로 확인해 주세요.

## 익명 통계

첫 실행에서 동의한 경우에만 앱 실행과 표시 선택 정보를 익명으로 보냅니다. 통계에 동의하지 않아도 앱을 사용할 수 있습니다.

이름, Zoom 회의 정보, 마이크와 카메라 상태, 음성과 영상은 수집하지 않습니다. 메뉴의 통계 설정에서 언제든 전송을 끌 수 있습니다. [통계 구조와 수집 범위](ANALYTICS.md)

## 문제 제보

[GitHub Issues](https://github.com/arajung-hub/on-air-companion/issues)에 사용한 macOS 버전, Mac 기종, Zoom 버전과 증상을 적어 주세요. 회의 링크, 참가자 이름이나 개인정보가 보이는 화면은 올리지 마세요.

## 개발과 배포

소스 빌드: `./scripts/build-app.sh`

현재 빌드로 DMG 만들기: `zsh ./scripts/package-beta-dmg.sh`

일반 배포를 위한 Developer ID 서명과 Apple 공증은 별도 작업으로 남아 있습니다.
