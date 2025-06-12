# 🤖 AGNT STRT HR

## 🚨 CRTCL RLS - ENFCD BY SYSTM

### Fl Accss
- ✅ RD: Only fls endng _COMPACT.md
- ✅ WRT: Only fls endng _COMPACT.md  
- ❌ NVR: Accss .human/ dir (systm blckd)
- ❌ NVR: Rd/wrt uncmprsd .md fls

### Yr Tls R Ptchd
- Rd tl auto-rdircts to _COMPACT vrsns
- Wrt tl blcks wrts to .human/
- Git hks prvnt cmttng wrng fls

### Avlbl Cmprsd Dcs
- ./docs/HANDOFF.md → .compressed/HANDOFF_COMPACT.md
- ./docs/dev_log.md → .compressed/dev_log_COMPACT.md  
- ./docs/CRITICAL_PATHS.md → .compressed/CRITICAL_PATHS_COMPACT.md
- ./docs/SESSION_CONTEXT.md → .compressed/SESSION_CONTEXT_COMPACT.md

### 🛠️ Dfnsv Tlkt

| Prblm | Scrpt | Desc |
|-------|-------|------|
| Strt sessn | ./scripts/check-everything.sh | Fl systm diag |
| Bfr cdng | ./scripts/pre-code-check.sh | Ensrs env rdy |
| Any err | ./scripts/fix-common.sh | Fxs 90% auto |
| Spcfc err | ./scripts/explain-error.sh "err" | Pst err gt sltn |
| Nd undo | ./scripts/rollback-safe.sh | Sf rvrt gd st |
| Prt blckd | ./scripts/when-port-blocked.sh | Klls blckng proc |
| Mdl nt fnd | ./scripts/when-deps-broken.sh | Rnstlls deps |
| Tsts fl | ./scripts/when-tests-fail.sh | Dbgs tst env |
| Mssng env | ./scripts/when-env-missing.sh | Crts/fxs .env |

### Tmp Wrkspc
- ALL tmp scrpts → .scratch/
- NEVER crt fls in prjct rt
- Cln wth: rm .scratch/*

### Git Cmmts
- Wrt hmn-rdbl cmt msgs (thy'r fr git lg, nt dcs)
- Exmpl: "feat: implement user authentication"
- Nt: "ft: impl usr auth"

### Wrkflw
1. Strt: ./scripts/check-everything.sh
2. Rd: docs/HANDOFF.md (auto-cmprsd)
3. Chk: TodoRead tl
4. Cde: Mk chngs
5. Err?: ./scripts/fix-common.sh
6. Cmt: git commit -m "human readable message"

## Rmmbr
- Dcs in docs/ r symlnks to cmprsd vrsns
- Nvr try to rd/wrt .human/ (blckd)
- Tmp wrk gos in .scratch/
- Dfnsv scrpts slv mst prblms