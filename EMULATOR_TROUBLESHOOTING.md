# 안드로이드 스튜디오 시스템 이미지 다운로드 오류 해결 가이드

`Connection reset` 오류는 구글 서버에서 파일을 다운로드하는 중에 네트워크 연결이 끊어졌을 때 발생합니다. 특히 용량이 큰 시스템 이미지(태블릿 등)를 받을 때 자주 발생합니다. 다음 단계들을 시도해 보세요.

---

### 1. SDK Manager를 통한 직접 설치 (가장 추천)
가상 기기 생성 창에서 다운로드하지 말고, **SDK Manager**에서 미리 이미지를 받아두면 더 안정적입니다.
1. Android Studio 상단 메뉴: **Settings** (macOS는 `Settings`, Windows는 `File > Settings`)
2. **Languages & Frameworks > Android SDK**로 이동
3. **SDK Platforms** 탭에서 **'show package details'** 체크 (오른쪽 하단)
4. **Android 15.0 (VanillaIceCream)** (또는 API 35) 항목 아래에서 **Google Play Intel/ARM 64 v8a System Image**를 체크한 후 **Apply** 버튼 클릭하여 설치
5. 설치가 완료된 후 다시 가상 기기 생성을 진행하세요.

### 2. 네트워크 및 VPN 확인
- **VPN 사용 중**: 한국 네트워크에서 구글 서버 연결이 불안정할 경우 VPN을 끄거나, 반대로 해외 서버 VPN을 켜서 시도해 보세요.
- **프록시 설정**: 회사나 공공장소라면 `Settings > Appearance & Behavior > System Settings > HTTP Proxy`에서 프록시 설정을 확인하세요 (대부분 'No proxy'가 맞습니다).

### 3. 대안 시스템 이미지 사용
'Google Play' 버전 대신 **'Google APIs'** 버전을 선택해 보세요.
- **Google Play**: Play 스토어가 포함되어 있지만 보안 정책이 까다롭고 용량이 큼.
- **Google APIs**: Play 스토어는 없지만 앱 설치 및 테스트에는 충분하며 안정성이 높음. (스크린샷 촬영용으로 충분합니다.)

### 4. 터미널 명령어로 강제 설치 (고급)
터미널에서 아래 명령어를 입력하여 다운로드를 시도할 수 있습니다 (안드로이드 SDK 경로 확인 필요).
```bash
~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --install "system-images;android-35;google_apis_playstore_tablet;arm64-v8a"
```
### 5. INSTALL_FAILED_INSUFFICIENT_STORAGE 오류 해결
에뮬레이터의 내부 저장 공간이 가득 차서 앱을 설치할 수 없는 상태입니다.

- **해결방법 A: 에뮬레이터 데이터 초기화 (Wipe Data)**
  1. Android Studio의 **Device Manager**를 엽니다.
  2. 사용 중인 에뮬레이터 오른쪽의 점 세 개(⋮) 메뉴를 클릭합니다.
  3. **Wipe Data**를 선택합니다. (기기 내의 모든 데이터가 초기화되지만 용량은 확보됩니다.)

- **해결방법 B: 에뮬레이터 용량 늘리기**
  1. Device Manager에서 에뮬레이터 옆의 연필 아이콘(**Edit**)을 클릭합니다.
  2. **Show Advanced Settings** 버튼을 클릭합니다.
  3. 아래로 내려서 **Storage and RAM** 섹션의 **Internal Storage** 값을 늘려줍니다. (예: 2048 MB -> 4096 MB)
  4. **Finish**를 누르고 에뮬레이터를 재시작하세요.

---

### 스크린샷 팁
태블릿 에뮬레이터 설치가 계속 안 된다면, **기존 휴대폰 에뮬레이터의 해상도를 태블릿 규격으로 강제로 바꿔서** 스크린샷만 찍는 편법도 있습니다. 혹은 웹 브라우저의 '기기 모드(Inspect)'에서 태블릿 크기를 설정한 뒤 렌더링된 화면을 찍는 방법도 고려해 보세요.
