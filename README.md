# On Air Companion

Zoom 회의 중 마이크와 카메라 상태를 기본형 또는 동물형으로 보여 주는 macOS 메뉴바 앱입니다.

<p align="center"><strong>Designed and built by Ara Jung</strong></p>

<p align="center">
  <img src="preview/basic.png" width="49%" alt="기본형 선택 화면">
  <img src="preview/animals.png" width="49%" alt="동물형 선택 화면">
</p>

## 다운로드

최신 베타는 [GitHub Releases](https://github.com/arajung-hub/on-air-companion/releases/latest)에서 받을 수 있습니다.

[Mac용 베타 설치 파일 받기 (DMG)](https://github.com/arajung-hub/on-air-companion/releases/download/v0.4.7-beta/On-Air-Companion-0.4.7-beta-macOS.dmg)

[기존 ZIP 파일 받기](https://github.com/arajung-hub/on-air-companion/releases/download/v0.4.7-beta/on-air-companion-beta-v14.zip)

<p align="center">
  <a href="https://github.com/arajung-hub/on-air-companion/releases/latest">
    <img src="preview/downloadqr.png" width="180" alt="최신 베타 다운로드 QR 코드">
  </a>
</p>

Apple Silicon Mac과 macOS 13 이상을 대상으로 만든 수업용 베타입니다. Intel Mac과 Windows는 지원하지 않습니다. 다른 Mac에서의 설치와 사용은 추가 검증 중입니다.

Developer ID 서명과 Apple 공증이 없어서 첫 실행이 차단될 수 있습니다. 경고 없이 바로 실행되는 정식 배포본은 아직 준비하지 못했습니다. 출처를 신뢰하는 사용자만 직접 실행 여부를 결정해 주세요. [첫 실행과 접근성 설정 안내](DISTRIBUTION.md)를 확인한 뒤 설치해 주세요.

## 설치와 첫 실행

받은 파일이 이 저장소의 배포본인지 확인하고, 앱을 신뢰하는 경우에만 실행을 허용해 주세요.

1. DMG를 열고 `On Air Companion.app`을 `Applications(응용 프로그램)` 폴더로 끌어 옮깁니다. ZIP은 압축을 풀고 앱을 옮깁니다.
2. 응용 프로그램 폴더의 앱을 실행합니다. ‘Apple이 악성 코드가 없음을 확인할 수 없음’ 경고가 나오면 **완료**를 눌러 닫습니다.
3. **시스템 설정의 개인정보 보호 및 보안**에서 아래쪽 보안 항목으로 내려가, On Air Companion에 대한 **그래도 열기**를 선택합니다.
4. 추가 확인창에서 **열기**를 선택합니다. 필요한 경우 Mac 암호나 Touch ID로 직접 승인합니다.
5. 개인정보 보호 및 보안의 **손쉬운 사용(접근성)**에서 On Air Companion 스위치를 켭니다. 목록에 없으면 **+** 버튼으로 응용 프로그램 폴더의 앱을 추가합니다.
6. 앱을 종료했다가 다시 실행합니다. 메뉴바 아이콘을 눌러 기본형 또는 동물형을 선택한 뒤 Zoom 회의에서 상태를 확인합니다.

Dock에 아이콘이 없어도 메뉴바 앱은 실행 중일 수 있습니다. 회의가 없으면 떠 있는 알림창은 숨습니다. 처음 실행했을 때 익명 통계 여부는 원하는 대로 선택할 수 있으며, 동의하지 않아도 상태 감지를 사용할 수 있습니다.

‘컴퓨터를 손상시킴’이나 ‘손상된 앱’ 경고는 무시하지 마세요. 관리되는 Mac에서는 관리자 정책 때문에 실행을 허용할 수 없을 수 있습니다. [Apple 공식 실행 안내](https://support.apple.com/ko-kr/102445)

권한을 켰는데도 ‘권한 필요’가 표시되면 [자세한 설치 안내](DISTRIBUTION.md#접근성-권한)를 확인해 주세요. 예전 복사본을 함께 실행하지 말고 응용 프로그램 폴더의 설치본만 사용해 주세요.

## 발표자료

[최신 발표 PPT](https://github.com/arajung-hub/on-air-companion/releases/download/v0.4.7-beta/On-Air-Companion-story-v5.pptx)

[웹 발표자료 ZIP](https://github.com/arajung-hub/on-air-companion/releases/download/v0.4.7-beta/On-Air-Companion-web-v5.zip)

## 익명 사용 통계

첫 실행에서 사용자가 동의한 경우에만 앱 실행, 기본형과 동물형 선택, 캐릭터 선택을 Supabase에 익명으로 기록합니다. 이름, Zoom 회의 정보, 마이크와 카메라 상태, 음성, 영상은 수집하지 않습니다. 메뉴의 `통계 설정`에서 언제든 전송을 끌 수 있습니다.

Supabase 데이터 구조와 집계 방법은 [ANALYTICS.md](ANALYTICS.md)에서 확인할 수 있습니다.

## 프로젝트 배경

Zoom 회의에서 마이크가 켜진 사실을 놓치고 개인 대화를 했던 경험에서 시작했습니다. 작은 알림창으로 상태를 더 잘 알아차릴 수 있는지 살펴보기 위해, 같은 감지 로직에 기본형과 동물형을 적용했습니다.

## 표시 스타일

### 기본형

상태 캡슐, 듀얼 타일, 아이콘 바, 상태 링 중 하나를 고를 수 있습니다. 상태 캡슐은 상태 문구를 크게 보여 주며, 듀얼 타일은 마이크와 카메라 상태를 따로 표시합니다. 아이콘 바는 작은 공간에 두 아이콘을 담고, 상태 링은 원의 양쪽으로 두 장치의 상태를 보여 줍니다. 선택한 모양은 다음 실행에도 유지됩니다.

네 가지 기본형은 반투명 색면, 유리 테두리, 내부 하이라이트를 공유합니다. 화면에서는 동물형과 같은 강도로 부드럽게 위아래로 움직입니다.

꺼진 장치는 어두운 배경과 빗금으로, 켜진 마이크는 산호색, 켜진 카메라는 보라색으로 구분합니다. 상태 캡슐에서 둘 다 켜진 경우에는 빨간색을 사용합니다.

기본형 메뉴바는 마이크와 카메라를 나란히 표시합니다. 마이크 꺼짐은 회색 점 세 개, 켜짐은 움직이는 산호색 파동입니다. 카메라 꺼짐은 회색 빈 원, 켜짐은 빨간 점입니다. 권한이 필요하면 원 안에 느낌표를 표시합니다.

### 동물형

카피바라, 햄스터, 말티즈, 청록 용공룡, 샴고양이, 여우, 롭이어 토끼, 오리, 아홀로틀, 펭귄, 거북이, 물범 중 하나를 고를 수 있습니다. 꺼짐 상태에서는 눈을 감고 쉬며 마이크나 카메라가 켜지면 눈을 뜹니다. 카메라가 켜지면 빨간 점이 움직이고, 마이크가 켜지면 산호색 파동이 움직입니다.

두 스타일은 같은 Zoom 감지 로직을 사용합니다. 런처에서 스타일을 바꾸면 알림창과 메뉴바 아이콘이 함께 바뀌며 선택값은 다음 실행에도 유지됩니다.

동물형 메뉴바에는 선택한 동물이 표시되며, 카메라 빨간 점과 마이크 파동이 함께 움직입니다.

## 앱 아이콘

앱 번들에 여러 해상도를 포함한 macOS 아이콘을 추가했습니다. Finder와 시스템 설정의 접근성 권한 목록에서 On Air Companion 아이콘을 확인할 수 있습니다.

## 감지 방식

앱은 Zoom Workplace의 접근성 버튼 이름을 읽어 상태를 판별합니다. 실제 음성과 영상 내용은 읽거나 저장하지 않습니다. Zoom 회의가 없으면 알림창은 자동으로 숨고 메뉴바 아이콘만 남습니다.

최종 앱은 Zoom 실제 감지만 사용합니다. 회의가 없거나 접근성 권한이 필요한 경우에는 선택 화면 상단에 현재 상황을 표시합니다. 앱은 Zoom의 마이크와 카메라를 직접 켜거나 끄지 않습니다.

## 빌드

```bash
./scripts/build-app.sh
```

개발용 화면 이미지 생성 방법은 [DEVELOPMENT.md](DEVELOPMENT.md)에서 확인할 수 있습니다.
