# 下個 Godot 遊戲專案前期規劃 Checklist

這份文件記錄本專案開發到 Web 部署與後期效能優化後得到的經驗，方便下一個專案一開始就規劃好，避免後期大改。

## 1. 繪製架構先分層

建議一開始就切成：

```text
Main
├─ StaticBoardLayer
├─ DynamicGameLayer
├─ EffectLayer
└─ UILayer
```

靜態層放：

- 背景
- 格線
- 地板
- 路徑
- 已建塔底座
- 塔等級標記
- 不常變動的裝飾

動態層放：

- 敵人
- 子彈
- 塔的旋轉砲管或發射臂
- hover 預覽
- 選取範圍

特效層放：

- 衝擊波
- 飄字
- 爆炸
- 短暫提示動畫

UI 層放：

- 金幣、生命、波數
- 操作按鈕
- 選單
- 確認視窗

原則：大量存在但不常變動的東西，不要每幀重畫。

## 2. 一開始就設計效能模式

不要等後期卡頓才補。

建議預留：

- `visual_load`：敵人數 + 子彈數 + 特效數。
- `BUSY_VISUAL_LOAD`：中負載門檻。
- `HEAVY_VISUAL_LOAD`：高負載門檻。
- 高負載時自動關閉或簡化：
  - 子彈繪製
  - 一般敵人血條
  - 大面積透明範圍圈
  - 多段衝擊波
  - 過多飄字

遊戲邏輯與傷害照算，視覺可降級。

## 3. UI 不要每幀重刷

UI 更新應該走狀態變更，而不是每幀改 Label/Button。

建議一開始就做：

- `ui_update_signature`
- 金幣、生命、波數、速度、選取塔、倒數等變動時才刷新 UI。
- 音量 slider、checkbox 不要每幀重設 value，避免造成 UI 負擔或互相觸發。

## 4. Hover 與尋路要快取

建造預覽不要每幀跑 pathfinding。

建議：

- 記錄 `last_hover_cell`。
- 只有滑鼠移到新格子才重新檢查。
- 同一格停留時沿用上次結果。
- 波次進行中不能建塔時，直接跳過 hover 尋路。

## 5. Pathfinding 與目標搜尋前期拆出

塔防類遊戲很容易在這兩塊變重：

- 敵人尋路
- 塔找目標

建議前期就拆：

- `pathfinder.gd`
- `targeting_manager.gd` 或類似模組

中後期可加入：

- 路徑快取
- 敵人空間分區
- 塔只檢查附近敵人
- 每幀分批更新塔目標，而不是所有塔同時掃描所有敵人

## 6. 資料化要早做

塔、敵人、波次、難度不要長期硬編碼。

建議前期建立：

- `data/towers.json`
- `data/enemies.json`
- `data/waves.json` 或 `wave_manager.gd`
- `game_defs.gd`

平衡調整優先改資料，不要一直改主程式。

## 7. 存檔、波次、UI、渲染早拆檔

避免 `main.gd` 過早變成巨型檔案。

建議早期拆：

- `game_defs.gd`
- `game_data.gd`
- `game_ui.gd`
- `game_renderer.gd`
- `pathfinder.gd`
- `wave_manager.gd`
- `save_manager.gd`
- `enemy.gd`
- `tower.gd`
- `projectile.gd`

`main.gd` 保持負責流程協調，不塞所有細節。

## 8. Web 字型與中文顯示先規劃

Web 版中文字容易亂碼。

建議：

- 一開始就內嵌中文字型。
- 不直接放完整大字型進正式版。
- 開發期可用完整 Noto Sans TC。
- 發布前產生只包含遊戲用字的子集字型。
- 新增中文 UI 後，要重新產生字型子集。

## 9. Web 部署與快取先規劃

如果目標包含 Web，前期就準備：

- `export_presets.cfg`
- `netlify.toml`
- 自動 build script
- Web export templates 版本固定
- `.wasm` / `.pck` / `.js` headers
- `index.html` 不長快取
- 版本化資源檔名，例如 `td-<hash>.wasm`

原則：

- HTML 保持容易更新。
- 大型資源檔可長快取。
- 每次改版用 hash 檔名避免玩家卡舊檔。

## 10. 彈出視窗不要依賴系統字型

Godot 內建 `ConfirmationDialog` 可能在 Web 上吃不到專案字型。

建議：

- 重要確認視窗直接自製。
- 標題、內文、按鈕都用專案字型。
- 開啟確認視窗時暫停遊戲邏輯。

## 11. 版本與 changelog 持續維護

每次有功能或平衡改動：

- 更新 `GAME_VERSION`
- 更新 `CHANGELOG.md`
- 本地測試
- commit
- push
- Netlify 自動部署

版本紀錄能避免回頭查不到「哪一版改了什麼」。

## 12. 先定義測試場景

塔防後期問題通常早期看不出來。

建議準備：

- 快速跳到第 20 / 30 / 40 / 50 波的 debug 功能。
- 自動生成大量塔與敵人的壓力測試。
- Web 版測 CPU / 記憶體 / LCP。
- Chrome 與 Safari 都測。

## 13. 前期就決定視覺上限

美術越細，後期越容易卡。

建議先定規則：

- 畫面最多顯示幾顆子彈。
- 同時最多幾個衝擊波。
- 什麼狀況隱藏一般敵人血條。
- 什麼狀況簡化敵人外型。
- 塔射程圈是否只畫線、不畫填色。

不要讓視覺物件無限制增加。

## 14. 音效與音樂策略

Web 版要注意載入大小。

建議：

- 短音效用壓縮格式，例如 `.ogg`。
- 背景音樂做短循環。
- 可程式生成的音效不佔下載空間，但要注意 CPU。
- 一開始就做音樂/音效開關與音量 slider。

## 15. 下一個塔防專案推薦起手順序

1. 建立 `game_defs.gd` 與資料表。
2. 建立主場景與三層以上繪製節點。
3. 先做格線、路徑、建塔、敵人移動。
4. 拆出 pathfinder。
5. 拆出 renderer。
6. 拆出 UI。
7. 加入 wave manager。
8. 加入 save manager。
9. 加入效能模式門檻。
10. 做 Web export 與 Netlify 自動部署。
11. 再開始美術精緻化與大量內容擴充。

核心原則：先讓架構能承受後期內容，再增加畫面細節。
