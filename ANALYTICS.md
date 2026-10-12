# 익명 사용 통계

On Air Companion은 사용자가 동의한 경우에만 다음 네 가지 이벤트를 Supabase로 전송합니다.

1. `app_open`: 앱 실행
2. `style_selected`: 기본형 또는 동물형 선택
3. `character_selected`: 동물 선택
4. `basic_variant_selected`: 기본형 종류 선택

이름, 이메일, Zoom 회의 정보, 마이크와 카메라 상태, 음성, 영상은 수집하지 않습니다. 설치마다 생성되는 무작위 UUID는 대략적인 고유 설치 수를 계산하는 용도로만 사용합니다.

## Supabase 연결

배포 빌드는 `on-air-companion` Supabase 프로젝트에 연결되어 있으며, Publishable key만 앱 번들에 포함합니다. Secret key는 앱이나 저장소에 넣지 않습니다.

1. Supabase에서 새 프로젝트를 만듭니다.
2. SQL Editor에서 `supabase/migrations/20261012000000_create_analytics.sql`을 실행합니다.
3. 프로젝트의 Connect 화면에서 Project URL과 Publishable key를 확인합니다.
4. `Resources/Info.plist`의 `OACSupabaseURL`과 `OACSupabasePublishableKey`에 값을 넣습니다.
5. `./scripts/build-app.sh`로 앱을 다시 빌드합니다.

다른 Supabase 프로젝트로 교체할 때만 위 연결 절차를 다시 진행합니다.

## 확인 가능한 수치

GitHub Release에서는 ZIP의 전체 다운로드 수를 확인할 수 있습니다. 개인별 다운로드 정보는 제공하지 않습니다. 앱을 설치한 뒤의 기본형과 동물형 선택 비율은 사용자가 익명 통계에 동의한 경우에만 Supabase에서 확인할 수 있습니다.

## 집계 쿼리

대략적인 고유 설치 수:

```sql
select count(distinct install_id) as unique_installs
from public.analytics_events
where event_name = 'app_open';
```

기본형과 동물형 선택 수:

```sql
select style, count(*) as selections
from public.analytics_events
where event_name = 'style_selected'
group by style
order by selections desc;
```

동물별 선택 수:

```sql
select selection as character, count(*) as selections
from public.analytics_events
where event_name = 'character_selected'
group by selection
order by selections desc;
```

날짜별 요약은 `public.analytics_daily_summary` 뷰에서 확인할 수 있습니다.
