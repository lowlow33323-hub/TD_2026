# Path Bender Tower Defense

Godot 4.6.3 prototype for a side-to-side tower defense game.

Current version: `Beta 0.7.1`

## 維護文件

- `docs/ONBOARDING.md`：接手、執行、測試、部署指南。
- `docs/GAME_LOGIC.md`：主要遊戲流程與 `.gd` 檔案調用關係。
- `docs/DATA_SCHEMA.md`：塔與敵人資料表欄位規格。
- `docs/PERFORMANCE_GUIDE.md`：Web 版與後期效能規則。
- `docs/ARCHITECTURE_DECISIONS.md`：重要架構決策紀錄。
- `docs/ROADMAP.md`：後續開發階段、完成標準與暫緩項目。
- `docs/CHANGELOG.md`：版本修改紀錄。

## 畫面與頁面

- 遊戲會依視窗大小自動縮放，支援手機直向/窄螢幕與電腦寬螢幕。
- 啟動後先進入主選單。
- 主選單包含：`開始遊戲`、`繼續遊戲`、`操作規則`、`排行榜`、`難度調整`。

## 操作

- 按 `1` 或點 `砲塔`：選擇砲塔。
- 按 `2` 或點 `箭塔`：選擇箭塔。
- 按 `3` 或點 `冰凍塔`：選擇冰凍塔。
- 按 `N`：開始下一波。
- 左鍵/觸控空格：預設第一次點空地顯示半透明塔預覽，第二次點同一格開始建造。
- 建造需要短暫時間，上方會顯示進度條：箭塔 `0.2` 秒、砲塔 `0.3` 秒、冰凍塔 `0.5` 秒。
- 右側 `建造二次確認` 可取消勾選，改回點一下直接建造；快捷鍵 `B` 可切換。
- 左鍵已有塔：選取該塔。
- 按 `U`：升級選取的塔。
- 按 `I`：嘗試將選取塔升到最高等。
- 按 `D` / `S`：加快或降低遊戲速度。
- 按 `R`：切換敵人路徑顯示。
- 按 `A`：切換自動開始。
- 右鍵已有塔：拆除該塔。
- 點 `下一波`：開始產生敵人。
- 遊戲中 UI 提供：`存檔`、`回主選單`、`退出`。
- `存檔` 會保存目前難度、金幣、生命、波數、塔的位置與等級；有存檔時可在主選單按 `繼續遊戲`。
- 按 `下一波` 會播放提示音，入口會發光提示出生點。

## 塔種

- 砲塔：攻速慢，單發傷害高，命中後造成範圍傷害。升級會提升射程、爆炸範圍、傷害與攻速。
- 箭塔：攻速快，射程遠，傷害普通。升級會提升射程、傷害與可同時攻擊目標數。
- 冰凍塔：造成傷害並降低敵人速度。升級會提升射程、傷害、緩速強度與持續時間。

## 規則

- 敵人從左側進入，往右側出口前進。
- 建造區目前為 `45x25` 格。
- 塔佔地為 `2x2` 格，所以建塔會更明顯地改變敵人路線。
- 滑鼠移到建造區會顯示半透明的 2x2 建造預覽。
- 如果建塔會完全堵住入口到出口，系統會拒絕建造。
- 敵人可斜向移動，但不能斜穿過被塔封住的角落。
- 進攻波進行中不能建造新塔。
- 敵人會隨波數提高生命與速度。
- 每 10 波是 Boss 關，只會出現一隻巨大 Boss，不會出現小怪。
- 第 50 波是最後一波，通過後遊戲勝利。
- 第 50 波後會出現攻擊量審查員，排行榜記錄承受攻擊量與耗時。

## 主要檔案

- `project.godot` opens the project.
- `scenes/main.tscn` is the launch scene.
- `scripts/main.gd` coordinates the game flow.
- `scripts/game_ui.gd` builds and updates UI.
- `scripts/game_renderer.gd` draws the board, towers, enemies, projectiles and effects.
- `scripts/combat_manager.gd` handles tower attacks and projectile hits.
- `scripts/build_manager.gd` handles build, sell and upgrade actions.
- `scripts/wave_manager.gd` handles waves and difficulty scaling.
