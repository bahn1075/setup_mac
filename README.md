# setup_macos

최신 macOS(맥북) 초기 세팅용 스크립트 모음입니다.

## 파일 구성

- `native.sh`: macOS 개발환경 초기 세팅
- `ubuntu-cleanup.sh`: macOS 캐시/로그/개발 도구 정리 스크립트

## 포함 내용

- Xcode Command Line Tools 확인
- Homebrew 설치 및 업데이트
- CLI 도구 설치
- GUI 앱(cask) 설치
- Oh My Zsh / zsh plugin / Starship 설정
- Ghostty / fastfetch / eza 기본 설정
- kubectl / minikube / Docker Desktop 설치
- Finder / Dock 등 macOS 기본 설정 일부 적용

## 사용 방법

```bash
chmod +x native.sh ubuntu-cleanup.sh
./native.sh
sudo ./ubuntu-cleanup.sh
```

## 주의

- `native.sh`는 사용자 환경 파일(`~/.zshrc`, `~/.config/ghostty/config`)을 수정합니다.
- `ubuntu-cleanup.sh` 파일명은 유지했지만 내용은 macOS 정리 스크립트로 변경했습니다.
- Docker Desktop, Ghostty, VS Code 같은 GUI 앱은 설치 후 macOS 보안 승인이나 최초 실행이 필요할 수 있습니다.
