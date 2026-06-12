# /vault-sync — 프로젝트 문서 ↔ 옵시디언 볼트 동기화

프로젝트 문서를 글로벌 위키(옵시디언 볼트)로 분류·동기화하고,
원본 문서를 레퍼런스/매뉴얼 스타일로 변환합니다.
반복 수행에도 안전하게 동작합니다(멱등성 보장).

## 상태 파일

```
STATE_FILE = ~/.claude/vault-sync-state.json
```

상태 파일 스키마:
```json
{
  "enabled": false,
  "vault_path": null,
  "enabled_at": null,
  "disabled_at": "YYYY-MM-DD"
}
```

`vault_path`가 상태 파일에 저장되면 이후 모든 작업에서 하드코딩 대신 이 값을 사용한다.

## 사용법

```
/vault-sync [source_path] [mode]

mode:
  enable     LLM Wiki 초기 셋업 및 활성화 (처음 한 번 실행)
  disable    기능 비활성화
  status     동기화 대상 목록만 출력 (변경 없음, 항상 실행 가능)
  classify   소스 문서 → 볼트 엔트리 생성  ⟵ 활성화 필요
  refactor   소스 문서 → 레퍼런스 스타일 변환  ⟵ 활성화 필요
  full       classify + refactor 한 번에  ⟵ 활성화 필요
```

**Args 없이 호출 시**: 현재 작업 디렉토리를 source_path로 사용, mode=status

---

## Step 0 — 활성화 게이트 (모든 호출의 첫 번째 단계)

`~/.claude/vault-sync-state.json` 읽기 → `enabled`, `vault_path` 확인.

---

### mode == "enable" 처리

#### 분기 A: vault_path가 이미 설정되어 있음

이미 셋업 완료 상태. `enabled`만 true로 업데이트:
```json
{ "enabled": true, "enabled_at": "YYYY-MM-DD" }
```
메시지 출력 후 종료:
```
✅ LLM Wiki 동기화가 활성화되었습니다.
볼트 경로: {vault_path}

/vault-sync [경로] classify|refactor|full|status 로 사용하세요.
```

#### 분기 B: vault_path가 null (최초 활성화)

**초기 셋업 위자드를 실행한다.** 아래 순서대로 진행:

---

**[1단계] 옵시디언 소개 및 설치 안내**

다음 안내문을 출력한다:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🧠 LLM Wiki — 옵시디언 볼트 초기 설정
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LLM Wiki는 Obsidian(옵시디언)을 지식 관리 허브로 사용합니다.

📦 Obsidian이란?
  - 마크다운 기반의 로컬 지식 관리 도구
  - 양방향 링크([[문서명]])로 지식 그래프를 형성
  - 모든 파일은 사용자 PC에 저장 (클라우드 의존 없음)
  - 공식 다운로드: https://obsidian.md

✅ 이미 설치되어 있다면 다음 단계로 넘어가세요.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[다음] 볼트(Vault) 생성 방법 안내
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

**[2단계] 볼트 생성 안내**

다음 안내문을 출력한다:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📁 볼트(Vault) 생성 방법
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

볼트는 옵시디언이 관리하는 폴더입니다.
프로젝트 코드와 분리된 위치에 만드는 것을 권장합니다.

📋 생성 방법:
  1. 옵시디언 실행
  2. 메인 화면에서 "Create new vault" 클릭
  3. Vault name: 원하는 이름 입력 (예: My_Brain)
  4. Location: 저장 위치 선택 (예: C:\Users\{이름}\My-Brain)
  5. "Create" 클릭

💡 권장 경로 예시:
  - Windows: C:\Users\{이름}\My-Brain\My_Brain
  - Mac:     /Users/{이름}/My-Brain/My_Brain

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
볼트를 생성했으면, 볼트 폴더의 전체 경로를 알려주세요.
예: I:\My-Brain\My_Brain
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

**[3단계] 볼트 경로 수신**

사용자가 볼트 경로를 입력하면:

1. 해당 폴더가 실제 존재하는지 확인 (PowerShell `Test-Path`)
2. 존재하지 않으면:
   ```
   ❌ 경로를 찾을 수 없습니다: {입력한 경로}
   폴더를 먼저 생성하거나 정확한 경로를 다시 입력해주세요.
   ```
3. 존재하면 → Step 4(볼트 구조 생성)로 진행

---

**[4단계] 볼트 기본 구조 생성**

아래 파일 및 폴더를 모두 생성한다.
이미 존재하는 파일은 덮어쓰지 않고 건너뛴다.

##### 폴더 생성
```
{vault_path}/00_Inbox/
{vault_path}/10_Wiki_Knowledge/Concepts/
{vault_path}/10_Wiki_Knowledge/Entities/
{vault_path}/10_Wiki_Knowledge/Domains/
{vault_path}/20_Projects/
{vault_path}/30_Sources/
{vault_path}/40_Templates/
{vault_path}/99_System_Agent/
```

##### 파일 생성 목록 및 내용

**`{vault_path}/.clauderules`**
```
# LLM Wiki - System Rules for AI Agents

규칙 설명: 이 볼트(Vault) 내에서 AI 에이전트가 문서를 읽거나 작성할 때 반드시 준수해야 하는 규칙입니다.

1. 언어 규칙 (Language):
   - 모든 문서는 명확하고 자연스러운 '한국어'로 작성합니다.
   - 전문 용어는 필요한 경우 영문을 병기합니다.

2. 마크다운 및 양방향 링크 (Markdown & Linking):
   - 옵시디언(Obsidian) 환경에 최적화된 마크다운 포맷을 사용합니다.
   - 관련된 개념, 프로젝트, 인물 등이 언급될 때는 반드시 [[문서명]] 형식의 양방향 링크를 사용합니다.
   - 해시태그(#)를 활용하여 문서의 상태나 종류를 표기합니다 (예: #idea, #project/active).

3. 메타데이터 (YAML Frontmatter):
   - 모든 새 문서의 최상단에는 반드시 YAML 프론트매터를 포함합니다.
   ---
   title: "문서 제목"
   date: YYYY-MM-DD
   tags: []
   aliases: []
   ---

4. 구조화 및 명확성 (Structure):
   - 제목 체계(#, ##, ###)를 명확하게 사용하여 위계를 줍니다.
   - 결론이나 요약은 문서의 상단이나 하단에 명확히 표기합니다.
```

**`{vault_path}/000_Index.md`**
```markdown
---
title: "🧠 LLM Wiki — 메인 인덱스"
date: YYYY-MM-DD
tags: ["#moc", "#index"]
aliases: ["홈", "대시보드"]
---

# 🧠 LLM Wiki

> AI 에이전트와 함께 쌓아가는 영구적 지식 허브.
> 프로젝트는 끝나도 지식은 남는다.

---

## 📥 00_Inbox
새로 들어온 아이디어, 스크랩, 미분류 메모.
- (비어있음 — 정리 후 각 영역으로 이동)

## 🧠 10_Wiki_Knowledge

### Concepts (개념)
- (아직 없음)

### Entities (도구/인물/회사)
- (아직 없음)

### Domains (도메인 지식)
- (아직 없음)

## 🏗️ 20_Projects
- (아직 없음)

## 📚 30_Sources
- (아직 없음)
```

**`{vault_path}/00_Inbox/_README.md`**
```markdown
---
title: "00_Inbox 안내"
date: YYYY-MM-DD
tags: ["#system"]
---

# 📥 00_Inbox

## 목적
아직 분류되지 않은 메모, 스크랩, 아이디어를 임시 보관합니다.
생각날 때마다 빠르게 캡처하는 공간입니다.

## 에이전트 지침
- 사용자의 명시적 지시 없이 자동 분류하지 않는다.
- 빠른 메모는 형식을 강제하지 않고 그대로 저장한다.
- 정기적으로 비워 각 영역으로 이동시킨다 (Inbox Zero).
```

**`{vault_path}/10_Wiki_Knowledge/_README.md`**
```markdown
---
title: "10_Wiki_Knowledge 안내"
date: YYYY-MM-DD
tags: ["#system"]
---

# 🧠 10_Wiki_Knowledge

## 목적
프로젝트가 종료되어도 평생 보존되는 핵심 지식을 저장합니다.

## 하위 구조
- **Concepts/**: 추상 개념, 이론, 아키텍처 패턴
- **Entities/**: 특정 도구, 라이브러리, 회사, 인물
- **Domains/**: 특정 기술 도메인의 전체 지식 체계

## 에이전트 지침
1. **원자성**: 하나의 파일은 하나의 개념만 다룬다.
2. **강제 연결**: 언급되는 모든 개념을 [[문서명]] 양방향 링크로 감싼다.
3. **템플릿 준수**: 40_Templates/Tpl_Concept.md 구조를 따른다.
```

**`{vault_path}/20_Projects/_README.md`**
```markdown
---
title: "20_Projects 안내"
date: YYYY-MM-DD
tags: ["#system"]
---

# 🏗️ 20_Projects

## 목적
진행 중이거나 완료된 프로젝트의 진입점 인덱스를 보관합니다.
실제 코드와 산출물은 원본 저장소에 있으며, 여기엔 링크만 둡니다.

## 에이전트 지침
1. **원천 존중**: 00_Project_Index.md 내 절대 URI를 통해 원본 폴더로 이동.
2. **중복 생성 금지**: plan.md, progress.md 등 워크플로우 산출물을 이 폴더에 생성하지 않는다.
3. **대시보드 갱신**: 프로젝트 상태 변경 시 해당 인덱스 파일을 최신화한다.
```

**`{vault_path}/30_Sources/_README.md`**
```markdown
---
title: "30_Sources 안내"
date: YYYY-MM-DD
tags: ["#system"]
---

# 📚 30_Sources

## 목적
외부 원본 자료(논문, 기사, 데이터시트, 웹 스크랩 등)를 불변 상태로 보관합니다.

## 에이전트 지침
1. **불변성**: 원본의 성격을 유지하고, 임의로 요약하거나 삭제하지 않는다.
2. **인용 규칙**: 내용 복사 대신 [[30_Sources/파일명]] 링크로 참조한다.
3. **메타데이터 필수**: YAML 프론트매터에 url, author, scraped_date를 기입한다.
```

**`{vault_path}/40_Templates/_README.md`**
```markdown
---
title: "40_Templates 안내"
date: YYYY-MM-DD
tags: ["#system"]
---

# 📝 40_Templates

## 목적
일관된 문서 형식을 유지하기 위한 템플릿을 보관합니다.

## 에이전트 지침
1. 특정 유형의 문서 작성 시 먼저 적합한 Tpl_XXX.md를 찾는다.
2. Templater 문법(<% ... %>)은 Obsidian이 자동 치환하므로 수동 수정하지 않는다.
3. 사용자의 명시적 지시 없이 템플릿 원본을 수정하지 않는다.
```

**`{vault_path}/40_Templates/Tpl_Concept.md`**
```markdown
---
title: "새 개념"
date: YYYY-MM-DD
tags: ["#concept"]
aliases: []
---

# 💡 개념명

## 📌 핵심 요약 (TL;DR)
> 한 줄로 요약하세요.

## 📖 개념 정의


## ⚙️ 특징 및 원리
- 
- 

## 🔗 관련 개념 및 링크
- **상위 개념**: [[ ]]
- **하위 개념**: [[ ]]
- **유사 개념**: [[ ]]

## 📚 참고 자료
- [참고 링크 이름](URL)
```

**`{vault_path}/40_Templates/Tpl_Meeting.md`**
```markdown
---
title: "회의록"
date: YYYY-MM-DD
tags: ["#meeting"]
aliases: []
---

# 📋 회의명

## 개요
| 항목 | 내용 |
|------|------|
| 일시 | YYYY-MM-DD HH:MM |
| 장소 | |
| 참석자 | |

## 안건 (Agenda)
1. 

## 논의 사항


## Action Items
- [ ] 담당자: 내용 (기한: YYYY-MM-DD)

## 관련 문서
- [[ ]]
```

**`{vault_path}/99_System_Agent/_README.md`**
```markdown
---
title: "99_System_Agent 안내"
date: YYYY-MM-DD
tags: ["#system"]
---

# ⚙️ 99_System_Agent

## 목적
LLM 에이전트 제어 규칙, 프롬프트, 시스템 메타 문서를 격리 보관합니다.

## 에이전트 지침
- 작업 시작 전 이 폴더의 .clauderules 또는 AGENTS.md를 우선 읽는다.
- 이 폴더의 파일은 사용자 명시 지시 없이 수정하지 않는다.
- 이 폴더의 지식을 일반 지식처럼 답변하지 않는다 (시스템 프롬프트 격리).
```

**`{vault_path}/99_System_Agent/Architecture_Separation_Doctrine.md`**
```markdown
---
title: "LLM Wiki ↔ 프로젝트 분리 구조 독트린"
date: YYYY-MM-DD
tags: ["#system", "#architecture"]
---

# 🏛️ LLM Wiki ↔ 프로젝트 연동 (분리 구조) 아키텍처 독트린

## 1. 지식의 물리적 분리 원칙

| 공간 | 위치 | 목적 |
|------|------|------|
| **글로벌 위키 (이 볼트)** | {vault_path} | 프로젝트 종료 후에도 보존되는 영구적 지식 |
| **프로젝트 저장소** | 각 코드 저장소 | 소스 코드, 워크플로우 로그, 납품 문서 |

## 2. 링크 방향 규칙

### 위키 → 프로젝트 (Absolute URI)
```
[문서명](file:///절대/경로/파일.md)
```

### 프로젝트 → 위키 (Obsidian URI)
```
[개념명](obsidian://open?vault={볼트명}&file=10_Wiki_Knowledge/Concepts/개념명)
```

## 3. 핵심 원칙 (TL;DR)

> AI 에이전트는 위키의 20_Projects 폴더에 개발 산출물(plan.md, progress.md)을
> 절대 생성하지 않는다. 위키에는 원본 저장소로 향하는 링크 진입점만 남기고,
> 실제 작업은 원본 저장소에서 수행한다.
```

**`{vault_path}/00_Wiki_Standard_Architecture.md`**
```markdown
---
title: "볼트 표준 아키텍처"
date: YYYY-MM-DD
tags: ["#system", "#architecture"]
---

# 📐 볼트 표준 아키텍처

## 폴더 구조

| 폴더 | 역할 | 보존 기간 |
|------|------|-----------|
| 00_Inbox/ | 임시 수집, 미분류 메모 | 단기 (정기 비우기) |
| 10_Wiki_Knowledge/ | 영구 지식 (Concepts/Entities/Domains) | 영구 |
| 20_Projects/ | 프로젝트 링크 인덱스 | 프로젝트 생명주기 |
| 30_Sources/ | 외부 원본 자료 | 영구 (불변) |
| 40_Templates/ | 문서 템플릿 | 영구 |
| 99_System_Agent/ | 에이전트 룰, 시스템 메타 | 영구 |

## 핵심 원칙
1. 원자성: 하나의 파일 = 하나의 개념
2. 양방향 링크: 모든 관련 개념은 [[문서명]]으로 연결
3. 물리적 분리: 위키 ↔ 프로젝트 저장소 절대 분리
4. 에이전트 친화: 모든 폴더에 _README.md로 AI 지침 내장
```

---

**[5단계] 셋업 완료 및 state.json 업데이트**

state.json을 다음으로 업데이트:
```json
{
  "enabled": true,
  "vault_path": "{사용자가 입력한 경로}",
  "enabled_at": "YYYY-MM-DD",
  "disabled_at": null,
  "note": "LLM Wiki 동기화 기능. /vault-sync enable 로 활성화, /vault-sync disable 로 비활성화."
}
```

완료 메시지 출력:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅ LLM Wiki 초기 설정 완료!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

볼트 경로: {vault_path}

생성된 구조:
  ├── .clauderules
  ├── 000_Index.md
  ├── 00_Wiki_Standard_Architecture.md
  ├── 00_Inbox/_README.md
  ├── 10_Wiki_Knowledge/_README.md (+ Concepts/ Entities/ Domains/)
  ├── 20_Projects/_README.md
  ├── 30_Sources/_README.md
  ├── 40_Templates/ (Tpl_Concept.md, Tpl_Meeting.md)
  └── 99_System_Agent/ (_README.md, Architecture_Separation_Doctrine.md)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
다음 단계: Obsidian에서 이 폴더를 볼트로 열어보세요!
  1. Obsidian 실행
  2. "Open folder as vault" 선택
  3. {vault_path} 선택

프로젝트 문서 동기화 시작:
  /vault-sync [프로젝트경로] status   ← 먼저 대상 확인
  /vault-sync [프로젝트경로] full     ← 전체 동기화
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### mode == "disable" 처리

state.json 업데이트:
```json
{ "enabled": false, "disabled_at": "YYYY-MM-DD", "enabled_at": null }
```
메시지 출력 후 종료:
```
⏸️ LLM Wiki 동기화가 비활성화되었습니다.
활성화하려면: /vault-sync enable
```

---

### enabled == false 이고 mode가 classify/refactor/full 인 경우

아무 파일도 변경하지 않고 알림만 출력 후 종료:
```
💤 LLM Wiki 동기화가 현재 비활성화 상태입니다.

요청하신 작업({mode})은 실행되지 않았습니다.

  활성화하려면:       /vault-sync enable
  대상만 미리 보려면: /vault-sync {source_path} status
```

---

### enabled == true 이고 mode가 classify/refactor/full/status 인 경우

`vault_path`는 state.json의 `vault_path` 값을 사용. Step 1부터 정상 실행.

---

## Step 1 — 준비

1. `{vault_path}/.clauderules` 읽기
2. `{vault_path}/99_System_Agent/Architecture_Separation_Doctrine.md` 읽기
3. `{vault_path}/000_Index.md` 읽기
4. `{vault_path}/20_Projects/` 스캔 → 이 프로젝트의 기존 인덱스 파일 확인
5. source_path의 `.md` 문서 목록 수집

---

## Step 2 — classify 모드

### 분류 기준

| 판단 기준 | 볼트 카테고리 |
|-----------|--------------|
| 추상 개념, 이론, 패턴, 아키텍처 원칙 | `10_Wiki_Knowledge/Concepts/` |
| 특정 도구, 라이브러리, 회사, 인물 | `10_Wiki_Knowledge/Entities/` |
| 특정 기술 도메인 전체 지식 체계 | `10_Wiki_Knowledge/Domains/` |
| 외부 논문, 데이터시트, 스펙 | `30_Sources/` |
| 프로젝트 계획/진행/로그/코드 산출물 | **제외** (원본 저장소에 유지) |

### 볼트 엔트리 생성 규칙

- 파일명: PascalCase 또는 언더스코어 (공백 없음)
- 기존 파일 있으면 덮어쓰지 않고 병합/업데이트
- YAML 프론트매터 필수 (`source: "file:///절대경로"` 포함)
- 볼트 내 관련 개념은 반드시 `[[문서명]]` 양방향 링크

### 20_Projects 인덱스

- `{vault_path}/20_Projects/{프로젝트명}/00_Project_Index.md` 없으면 생성
- 링크 진입점만 포함 (`file:///` 절대 URI 링크)

### 000_Index.md 업데이트

새 볼트 엔트리를 해당 섹션에 `[[문서명]]`으로 추가 (기존 항목 건드리지 않음)

---

## Step 3 — refactor 모드

원본 소스 문서를 레퍼런스 스타일로 변환.

### 변환 패턴

**Before**: 개념 설명이 직접 포함된 문서
**After**: 개념은 볼트 링크로 대체, 프로젝트 고유 내용만 남김

```markdown
> 📖 이 문서는 프로젝트 레퍼런스입니다.
> 개념 상세 → [개념명](obsidian://open?vault={볼트명}&file=10_Wiki_Knowledge/Concepts/개념명)
```

### 제외 대상

- `progress.md`, `plan.md` (작업 산출물)
- `_README.md` (구조 문서)
- 이미 `> 📖 이 문서는 프로젝트 레퍼런스입니다.` 헤더 있는 파일

---

## Step 4 — status 모드 (항상 실행 가능)

변경 없이 분석 결과만 출력:

```
=== Vault Sync Status ===
LLM Wiki: {비활성화 ⏸️ | 활성화 ✅}
볼트 경로: {vault_path | 미설정}
소스 경로: {source_path}

[동기화 대상]     → classify 실행 시 생성 예정
[이미 동기화됨]
[제외됨]         → 프로젝트 산출물
[refactor 대상]  → refactor 실행 시 변환 예정
```

---

## 절대 금지 사항

- 볼트 `20_Projects/` 안에 `plan.md`, `progress.md` 생성 금지
- 볼트 `99_System_Agent/` 파일 수정 금지 (사용자 명시 지시 제외)
- 볼트 `40_Templates/` 원본 수정 금지
- 소스 문서의 프로젝트 고유 내용 삭제 금지
- 양쪽에 중복 내용 생성 금지
- enabled == false 상태에서 status 외 모드 실행 금지
