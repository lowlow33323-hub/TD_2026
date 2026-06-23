# 架構決策紀錄

本文記錄專案中「為什麼這樣設計」。接手者如果想改掉某個架構，應先閱讀對應決策，避免把已解決的問題改回來。

## ADR 格式

每筆 ADR 建議包含：

- 狀態：`Accepted`、`Superseded`、`Proposed`。
- 背景：當時遇到的問題。
- 決策：選擇了什麼做法。
- 結果：帶來的好處與限制。
- 影響檔案：主要被這個決策影響的檔案。

## ADR 001 - `main.gd` 保留流程中樞，細節拆到 manager

狀態：`Accepted`

### 背景

早期 `main.gd` 同時負責 UI、繪圖、戰鬥、建造、波次、存檔與音效，檔案越來越大，後續新增塔、敵人與特效時維護成本上升。

### 決策

保留 `main.gd` 作為遊戲流程中樞，但將細節拆到：

- `game_ui.gd`
- `game_renderer.gd`
- `pathfinder.gd`
- `wave_manager.gd`
- `save_manager.gd`
- `combat_manager.gd`
- `build_manager.gd`
- `audio_manager.gd`
- `dialog_manager.gd`

### 結果

新增功能時應優先修改對應 manager。`main.gd` 可以保留 wrapper，讓既有呼叫穩定，但不要再把大型細節加回主檔。

### 影響檔案

- `scripts/main.gd`
- `scripts/combat_manager.gd`
- `scripts/build_manager.gd`
- `scripts/audio_manager.gd`
- `scripts/dialog_manager.gd`
- `scripts/game_ui.gd`
- `scripts/game_renderer.gd`

## ADR 002 - 塔與敵人數值資料化

狀態：`Accepted`

### 背景

塔與敵人平衡會頻繁調整。如果數值散落在程式碼裡，容易改一處忘一處，也不方便比較版本。

### 決策

使用：

- `data/towers.json`
- `data/enemies.json`

將成本、血量、速度、傷害、獎勵、顏色、特殊倍率集中管理。

### 結果

平衡修改優先改 JSON。只有新增特殊行為或新類型時，才同步修改 `.gd`。

### 影響檔案

- `data/towers.json`
- `data/enemies.json`
- `scripts/game_data.gd`
- `scripts/tower.gd`
- `scripts/enemy.gd`
- `scripts/wave_manager.gd`

## ADR 003 - Web 版使用內嵌中文字型與字型子集

狀態：`Accepted`

### 背景

Godot Web 版在部分環境中，未明確使用內嵌中文字型會造成中文亂碼。完整 Noto Sans TC 字型體積很大，會拖慢首次載入。

### 決策

使用 `fonts/NotoSansTC-Regular.ttf` 作為專案字型，並將它縮成遊戲用字子集。

### 結果

Web 中文可正常顯示，載入體積大幅降低。新增中文 UI、敵人、塔、提示字時，要確認字型子集包含新字。

### 影響檔案

- `fonts/NotoSansTC-Regular.ttf`
- `scripts/game_ui.gd`
- `scripts/game_renderer.gd`
- `scripts/dialog_manager.gd`

## ADR 004 - 不使用 Godot 內建 `ConfirmationDialog` 做 Web 確認視窗

狀態：`Accepted`

### 背景

Web 版曾出現 `回主選單`、`退出` 確認視窗內文亂碼，問題集中在動態內建 dialog 的字型套用。

### 決策

改用 `dialog_manager.gd` 建立自製確認視窗，文字與按鈕都走專案 UI 字型。

### 結果

確認視窗顯示穩定，也能在視窗開啟時暫停倒數、出怪與戰鬥更新。

### 影響檔案

- `scripts/dialog_manager.gd`
- `scripts/main.gd`
- `scripts/game_ui.gd`

## ADR 005 - 靜態與動態分層繪製

狀態：`Accepted`

### 背景

塔防後期會同時有大量塔、敵人、子彈與特效。若背景、格線、塔地板、路徑每幀重畫，Web 版容易卡頓。

### 決策

將背景格線、塔地板、路徑與部分塔靜態外觀放到靜態層。主動態層只繪製每幀真正會變的內容。

### 結果

後期效能明顯改善。新增靜態視覺元素時，優先放入靜態層，並在資料變化時才重繪。

### 影響檔案

- `scripts/static_board_layer.gd`
- `scripts/game_renderer.gd`
- `scripts/main.gd`

## ADR 006 - 高負載低畫質模式保留邏輯、降低繪製

狀態：`Accepted`

### 背景

第 40 波後可能出現大量敵人、子彈與特效。玩家更在意遊戲計算正確與操作流暢，而不是每顆子彈都完整顯示。

### 決策

高負載時：

- 不繪製部分或全部子彈。
- 減少一般敵人血條。
- 減少衝擊波。
- 範圍圈只畫外框。
- 速度 `4x` 以上自動降低畫面細節。

傷害、緩速、濺射與擊殺獎勵仍完整計算。

### 結果

遊戲邏輯不犧牲，Web 版後期更穩。新增特效時必須支援高負載降級。

### 影響檔案

- `scripts/game_renderer.gd`
- `scripts/combat_manager.gd`
- `scripts/main.gd`

## ADR 007 - Netlify 透過 GitHub 自動部署

狀態：`Accepted`

### 背景

手動部署可以快速測試，但維護時不容易追蹤版本，也不方便之後修 bug。

### 決策

Netlify 連接 GitHub repository，自動執行 `scripts/netlify_build.sh`。

### 結果

push 後 Netlify 會自動匯出 Web 版並部署。部署問題應先看 GitHub commit、Netlify build log 與 `netlify.toml`。

### 影響檔案

- `netlify.toml`
- `scripts/netlify_build.sh`
- `export_presets.cfg`

## ADR 008 - 核心 Web 資源使用版本化檔名與長快取

狀態：`Accepted`

### 背景

Godot Web 的 `.wasm`、`.pck` 檔案較大。如果每次進站都重新下載，載入速度會很慢。但若直接長快取固定檔名，又可能導致玩家拿到舊版。

### 決策

Netlify build 後將核心資源改成 `td-<hash>.*`，並讓 `index.html` 不長快取。

### 結果

玩家拿到最新版入口，同時瀏覽器能長快取版本化大檔案。

### 影響檔案

- `scripts/netlify_build.sh`
- `netlify.toml`

## ADR 009 - 效能優先考慮第 40 到 50 波

狀態：`Accepted`

### 背景

前期波次順暢不代表後期順暢。塔防遊戲後期才是物件數量最高、最容易卡頓的場景。

### 決策

新增特效、塔外觀、敵人外觀、子彈效果時，都要考慮第 40 到 50 波的畫面壓力。

### 結果

新視覺效果要有：

- 數量上限。
- 抽樣策略。
- 高負載簡化外觀。
- 可在高速模式關閉的繪製項目。

### 影響檔案

- `scripts/game_renderer.gd`
- `scripts/combat_manager.gd`
- `scripts/wave_manager.gd`

## ADR 010 - 文件與 changelog 是維護流程的一部分

狀態：`Accepted`

### 背景

專案經過多次版本調整，若只看程式碼，很難知道某個設計是臨時寫法還是刻意取捨。

### 決策

保留：

- `docs/GAME_LOGIC.md`
- `docs/CHANGELOG.md`
- `docs/ONBOARDING.md`
- `docs/DATA_SCHEMA.md`
- `docs/PERFORMANCE_GUIDE.md`
- `docs/ARCHITECTURE_DECISIONS.md`

### 結果

功能、架構、平衡、部署與效能變更都要同步更新文件。文件不是額外工作，而是讓未來修改變快的工具。

### 影響檔案

- `docs/*.md`
- `README.md`

## ADR 011 - 目前暫不把 `main.gd` 拆到完全無狀態

狀態：`Accepted`

### 背景

`main.gd` 已從巨型檔案逐步拆出 UI、渲染、戰鬥、建造、音效、對話框等模組，但它仍保存大量遊戲狀態。若一次把狀態全部搬成多個 manager，容易造成資料流變複雜，也會增加 bug 風險。

### 決策

短期保留 `main.gd` 作為狀態擁有者與流程協調者。Manager 以 `owner` 或明確參數讀寫狀態。

### 結果

目前修改風險較低，既有流程穩定。缺點是 `main.gd` 仍偏大，後續若要再拆，應優先拆「敵人生命週期」或「遊戲狀態容器」，而不是同時大搬家。

### 影響檔案

- `scripts/main.gd`
- 所有 manager

## ADR 012 - 路徑、塔地板與背景屬於靜態視覺資料

狀態：`Accepted`

### 背景

路徑顯示、塔地板、格線、Boss 波底色在大多數時間不變，但它們面積大、數量多。若放在動態層會讓每幀繪製成本變高。

### 決策

這類內容放入靜態層，只有建塔、拆塔、升級、路徑變化、顯示路徑開關、Boss 狀態改變時才重畫。

### 結果

畫面更新更穩。新增地形、裝飾、區域提示時，也應先判斷能否歸入靜態層。

### 影響檔案

- `scripts/static_board_layer.gd`
- `scripts/game_renderer.gd`
- `scripts/main.gd`

## ADR 013 - 操作介面與遊戲模擬要能暫停

狀態：`Accepted`

### 背景

玩家按 `回主選單` 或 `退出` 時，如果確認視窗開著但遊戲倒數與出怪仍繼續，會造成誤操作與不公平。

### 決策

確認視窗開啟時，遊戲更新暫停；關閉後再恢復。

### 結果

UI 操作更安全，也避免確認期間敵人移動、出怪或戰鬥繼續進行。

### 影響檔案

- `scripts/dialog_manager.gd`
- `scripts/main.gd`

## ADR 014 - 短期仍使用 Godot `_draw()` 幾何繪製，不導入完整美術素材流程

狀態：`Accepted`

### 背景

目前塔、敵人、子彈多數以幾何圖形繪製。這讓迭代很快，也方便效能降級，但外觀精細度有限。

### 決策

短期繼續使用 `_draw()` 與幾何繪製強化可讀性。若進入美術精修階段，再評估導入 sprite atlas、Texture2D 或粒子資源。

### 結果

目前開發速度與效能掌控較好。未來若導入圖片素材，必須先規劃 atlas、載入大小、LOD 與 Web 壓縮。

### 影響檔案

- `scripts/game_renderer.gd`
- `fonts/NotoSansTC-Regular.ttf`

## ADR 015 - Roadmap 採用「可測試成果」而不是單純功能清單

狀態：`Accepted`

### 背景

專案後期功能很多，如果 roadmap 只列想法，接手者很難判斷先後順序與完成標準。

### 決策

`docs/ROADMAP.md` 以階段、目標、完成標準與風險呈現。

### 結果

後續開發可以依 roadmap 分批執行，也能清楚知道每一階段是否真的完成。

### 影響檔案

- `docs/ROADMAP.md`
- `docs/CHANGELOG.md`
