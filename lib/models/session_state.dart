enum SessionState {
  idle,
  scanning,
  connecting,
  oobExchange,
  armed,
  ranging,
  error,
}

extension SessionStateX on SessionState {
  String get label => switch (this) {
        SessionState.idle => '대기',
        SessionState.scanning => '스캔 중',
        SessionState.connecting => '연결 중',
        SessionState.oobExchange => '세션 협상 중',
        SessionState.armed => '준비됨',
        SessionState.ranging => '거리 측정 중',
        SessionState.error => '오류',
      };
}
