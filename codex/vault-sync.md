## vault-sync — 프로젝트 문서 ↔ 옵시디언 볼트 동기화

### 트리거

사용자가 `vault-sync [경로] [mode]` 형식으로 요청하면 이 스킬을 실행한다.

```
vault-sync enable
vault-sync [source_path] status
vault-sync [source_path] classify
vault-sync [source_path] refactor
vault-sync [source_path] full
vault-sync disable
```

### 상태 파일

`~/.claude/vault-sync-state.json` 을 읽어 `enabled` 와 `vault_path` 를 확인한다.
파일이 없으면 `{"enabled": false, "vault_path": null}` 로 간주한다.

### Step 0 — 활성화 게이트

**mode == "enable" 이고 vault_path == null (최초)**:
1. 옵시디언 소개 및 설치 안내 출력
2. 볼트 생성 방법 안내 (Obsidian에서 Create new vault)
3. 사용자에게 볼트 경로 입력 요청
4. 경로 존재 확인 후 볼트 전체 구조 생성:
   - `.clauderules`, `000_Index.md`, `00_Wiki_Standard_Architecture.md`
   - `00_Inbox/`, `10_Wiki_Knowledge/Concepts/Entities/Domains/`, `20_Projects/`, `30_Sources/`, `40_Templates/`, `99_System_Agent/`
   - 각 폴더에 `_README.md` 생성 (에이전트 지침 포함)
   - `40_Templates/Tpl_Concept.md`, `Tpl_Meeting.md` 생성
   - `99_System_Agent/Architecture_Separation_Doctrine.md` 생성
5. `vault-sync-state.json` 업데이트: `enabled: true`, `vault_path: {경로}`

**mode == "enable" 이고 vault_path 이미 설정됨**: `enabled: true` 로만 업데이트.

**enabled == false 이고 mode가 classify/refactor/full**: 알림만 출력 후 종료.

**mode == "disable"**: `enabled: false` 로 업데이트 후 종료.

**mode == "status"**: enabled 여부 무관하게 항상 실행.

### Step 1 — 준비

1. `{vault_path}/.clauderules` 읽기
2. `{vault_path}/99_System_Agent/Architecture_Separation_Doctrine.md` 읽기
3. `{vault_path}/000_Index.md` 읽기
4. `{vault_path}/20_Projects/` 스캔
5. `source_path`의 `.md` 파일 목록 수집

### Step 2 — classify

| 내용 | 볼트 위치 |
|------|-----------|
| 추상 개념, 이론, 패턴 | `10_Wiki_Knowledge/Concepts/` |
| 도구, 회사, 인물 | `10_Wiki_Knowledge/Entities/` |
| 기술 도메인 전체 | `10_Wiki_Knowledge/Domains/` |
| 외부 논문, 스펙 | `30_Sources/` |
| plan.md, progress.md, 로그 | **제외** |

- 기존 파일 있으면 병합 (덮어쓰기 금지)
- YAML frontmatter 필수
- `[[문서명]]` 양방향 링크
- `20_Projects/` 인덱스: 링크 진입점만

### Step 3 — refactor

일반 개념 설명 → 볼트 링크로 대체:
```markdown
> 📖 이 문서는 프로젝트 레퍼런스입니다.
> [개념명](obsidian://open?vault={볼트명}&file=10_Wiki_Knowledge/Concepts/개념명)
```

### Step 4 — status

변경 없이 분석 결과만 출력.

### 절대 금지

- `20_Projects/` 에 plan.md, progress.md 생성 금지
- `99_System_Agent/` 수정 금지
- 소스 문서 고유 내용 삭제 금지
- 양쪽 중복 내용 생성 금지
