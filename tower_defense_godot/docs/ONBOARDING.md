# 專案接手指南

本文給第一次接手 `Path Bender Tower Defense` 的開發者使用。目標是讓接手者能快速知道如何打開、執行、修改、測試與部署。

## 快速結論

- Godot 版本：`4.6.3`
- 專案目錄：`tower_defense_godot`
- 主場景：`scenes/main.tscn`
- 主流程：`scripts/main.gd`
- 遊戲邏輯說明：`docs/GAME_LOGIC.md`
- 修改紀錄：`docs/CHANGELOG.md`
- Netlify 設定：根目錄 `netlify.toml`
- Netlify build script：根目錄 `scripts/netlify_build.sh`

## 本地執行

1. 開啟 Godot `4.6.3`。
2. 匯入或開啟 `tower_defense_godot/project.godot`。
3. 執行主場景 `scenes/main.tscn`。

命令列檢查可用：

```bash
/Users/qqq/Downloads/Godot.app/Contents/MacOS/Godot --headless --path tower_defense_godot --quit
```

如果只看到 Godot 退出時的 `ObjectDB instances leaked at exit` 類型警告，但沒有腳本編譯錯誤，通常代表語法檢查通過。

## 推薦閱讀順序

1. `docs/GAME_LOGIC.md`
2. `docs/DATA_SCHEMA.md`
3. `docs/PERFORMANCE_GUIDE.md`
4. `docs/ARCHITECTURE_DECISIONS.md`
5. `docs/CHANGELOG.md`

不要一開始就從 `main.gd` 從頭讀到尾。先理解 manager 分工，再回頭看主流程會快很多。

## 常見修改位置

| 想修改的內容 | 優先檔案 |
| --- | --- |
| 塔數值、成本、傷害、攻速 | `data/towers.json` |
| 敵人數值、名稱、血量、速度、獎勵 | `data/enemies.json` |
| 出怪節奏、波次、難度倍率 | `scripts/wave_manager.gd` |
| 建塔、拆塔、升級、退款 | `scripts/build_manager.gd` |
| 塔攻擊、子彈命中、濺射、目標選擇 | `scripts/combat_manager.gd` |
| 敵人移動、死亡、復活處理 | `scripts/main.gd`、`scripts/enemy.gd` |
| UI 按鈕、右側操作區、HUD | `scripts/game_ui.gd` |
| 塔、敵人、子彈、路徑、特效繪製 | `scripts/game_renderer.gd` |
| 背景音樂、音效、音量 | `scripts/audio_manager.gd` |
| 確認視窗 | `scripts/dialog_manager.gd` |
| 路徑搜尋、防堵路 | `scripts/pathfinder.gd` |
| 存檔、排行榜、meta | `scripts/save_manager.gd` |

## 修改流程建議

1. 先確認需求屬於哪個模組。
2. 優先修改資料表或 manager。
3. 避免把新細節直接塞回 `main.gd`。
4. 修改完成後更新 `docs/CHANGELOG.md`。
5. 如果新增規則或改架構，同步更新 `docs/GAME_LOGIC.md`。
6. 若影響 Web 效能，同步更新 `docs/PERFORMANCE_GUIDE.md`。

## 本地測試清單

每次修改遊戲邏輯後，至少測：

- 主選單可進入遊戲。
- 簡單、普通、困難都能開始。
- 可以建塔、選塔、升級、拆塔。
- 建塔不會完全堵死路徑。
- 敵人能從出生點走到終點。
- 飛行敵人不受地面路徑阻擋。
- 速度 `1x`、`4x`、`16x` 下不會明顯破圖。
- `回主選單`、`退出` 確認視窗中文字正常。
- Web 版中文沒有亂碼。

平衡修改建議額外測：

- 普通難度第 20 波後。
- 普通難度第 40 波後。
- 困難難度前 10 波。
- 第 50 波與攻擊量審查員。

## Web 部署

目前使用 GitHub repository 連接 Netlify 自動部署。

一般流程：

1. 本地修改。
2. Godot headless 檢查。
3. commit。
4. push 到 GitHub。
5. Netlify 自動 build 與部署。

Netlify build 會：

- 下載 Godot Linux `4.6.3`。
- 下載官方 export templates。
- 匯出 Web 版。
- 將核心檔案改成 `td-<hash>.*`。
- 產生 `.gz`，有 brotli 時產生 `.br`。
- 套用長快取與跨源隔離 headers。

## 常見問題

### Web 中文亂碼

優先檢查：

- UI 是否使用 `fonts/NotoSansTC-Regular.ttf`。
- 新增文字是否已包含在字型子集。
- 自製 dialog 是否走 `dialog_manager.gd`，不要改回 Godot 內建 `ConfirmationDialog`。

### 後期大量子彈卡頓

優先檢查：

- `game_renderer.gd` 的高負載門檻。
- 是否新增了每幀大量透明繪製。
- 新特效是否有數量上限。
- 速度 `4x` 以上是否仍繪製太多物件。

### 改了塔或路徑但畫面沒更新

優先檢查：

- 是否有呼叫靜態層重繪。
- 建塔/拆塔/升級後是否有刷新路徑。
- `static_board_layer.gd` 是否仍正確回呼 `main.gd`。

### 新增 UI 後位置跑掉

優先檢查：

- `game_ui.gd` 的 layout 計算。
- 右側操作欄是否超出視窗。
- 手機版與窄視窗是否仍可操作。

## 接手原則

- 先改資料，再改 manager，最後才改 `main.gd`。
- 大型調整先寫小計畫。
- 效能相關功能要想到第 40 到 50 波。
- 新增特效一定要有上限。
- 改 Web 部署前先理解 `netlify.toml` 與 `scripts/netlify_build.sh`。
