# 5주차 — SystemVerilog과 도어락 FSM

SystemVerilog의 데이터 타입과 제한 조건 기반 난수 생성을 연습하고, 비밀번호 도어락을 단계적으로 확장한 실습입니다.

## 구성

| 구분 | 파일 | 내용 |
| --- | --- | --- |
| 기본 문법 | [`practice/datatype.sv`](practice/datatype.sv) | 4-state 값을 정수형 변수에 대입하고 비트 단위 결과 확인 |
| 제한 조건 난수 | [`practice/lottery.sv`](practice/lottery.sv) | 클래스, `randc`, constraint, seed를 이용한 1~45 번호 생성 |
| 도어락 Step 1 | [`doorlock/step1`](doorlock/step1/) | 고정 비밀번호 `0327`을 검사하는 기본 FSM |
| 도어락 Step 2 | [`doorlock/step2`](doorlock/step2/) | 4~12자리 비밀번호 설정과 입력 스트림 비교 |
| 도어락 Step 3 | [`doorlock/step3`](doorlock/step3/) | task와 문자열 입력을 사용한 대화형 테스트벤치 |

## 도어락 인터페이스

| 신호 | 방향 | 설명 |
| --- | --- | --- |
| `clk` | 입력 | 동작 클록 |
| `reset` | 입력 | active-low 비동기 리셋 |
| `start` | 입력 | 비밀번호 입력 시작 |
| `din[3:0]` | 입력 | 한 자리 숫자 입력 |
| `stop` | 입력 | 비밀번호 입력 종료 |
| `init` | 입력 | 새 비밀번호 설정 시작(Step 2·3) |
| `unlock` | 출력 | 비밀번호 일치 시 한 사이클 활성화 |

## 단계별 동작

### Step 1 — 고정 비밀번호

`IDLE → DATA → STOP → DONE` 상태로 동작합니다. `start` 이후 네 자리 `0, 3, 2, 7`을 순서대로 입력하고 `stop`을 인가하면 `unlock`이 활성화됩니다.

### Step 2 — 가변 비밀번호

`init`으로 설정 모드에 진입해 4~12자리 비밀번호를 저장합니다. 이후 `start`로 입력을 시작하고 `stop`으로 종료하면 저장된 비밀번호가 입력 스트림에 나타났는지 검사합니다.

### Step 3 — 대화형 검증

Step 2의 RTL에 명령형 테스트벤치를 추가했습니다.

- `set`: 새 비밀번호 설정
- `try`: 비밀번호 입력 및 잠금 해제 확인
- `reset`: DUT 초기화
- `quit`: 시뮬레이션 종료

테스트벤치는 Cadence SHM 파형 기록을 위해 `$shm_open`과 `$shm_probe`를 사용합니다.
