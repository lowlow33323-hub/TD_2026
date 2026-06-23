# 資料表規格

本文說明 `data/towers.json` 與 `data/enemies.json` 的欄位用途。調整平衡時優先修改資料表，避免把數值硬寫進 `.gd`。

## 共通原則

- JSON key 是程式使用的識別碼，不要隨意改名。
- `name` 是遊戲中顯示文字，可以改。
- 顏色使用 `#rrggbb`。
- 速度、血量、傷害、獎勵都是平衡數值，改完要實際測第 20、40、50 波。
- 新增欄位前先確認讀取端是否有預設值。

## `data/towers.json`

目前塔種：

| key | 顯示名稱 | 說明 |
| --- | --- | --- |
| `cannon` | 砲塔 | 高傷害、低攻速、濺射，不能攻擊飛行敵人 |
| `arrow` | 箭塔 | 高攻速、遠射程，可作為主要迷宮火力 |
| `ice` | 冰凍塔 | 傷害較低，提供緩速 |

### 塔欄位

| 欄位 | 單位/型別 | 說明 |
| --- | --- | --- |
| `name` | 字串 | UI 顯示名稱 |
| `cost` | 金幣 | 建造成本 |
| `range` | 像素 | 1 級攻擊範圍 |
| `range_per_level` | 像素 | 每升 1 級增加的範圍 |
| `fire_rate` | 秒 | 1 級攻擊間隔，越小越快 |
| `fire_rate_per_level` | 秒 | 每升 1 級攻擊間隔變化，通常是負數 |
| `min_fire_rate` | 秒 | 攻擊間隔下限 |
| `damage` | 數值 | 1 級傷害 |
| `damage_per_level` | 數值 | 每升 1 級增加傷害 |
| `target_count` | 數量 | 基礎同時攻擊目標數 |
| `target_count_bonus_levels` | 陣列 | 到達指定等級時，目標數額外 +1 |
| `splash_radius` | 像素 | 濺射半徑，`0` 表示沒有濺射 |
| `splash_radius_per_level` | 像素 | 每升 1 級增加的濺射半徑 |
| `slow_factor` | 倍率 | 緩速後速度倍率，`1.0` 表示不緩速 |
| `slow_factor_per_level` | 倍率 | 每升 1 級緩速倍率變化，通常是負數 |
| `min_slow_factor` | 倍率 | 緩速倍率下限 |
| `slow_duration` | 秒 | 緩速持續時間 |
| `slow_duration_per_level` | 秒 | 每升 1 級增加的緩速時間 |
| `color` | 顏色 | 繪製與特效使用的主色 |

### 平衡注意

- `fire_rate` 與 `damage` 會直接影響後期效能，攻速太快會產生大量子彈。
- `splash_radius` 會放大砲塔價值，也會增加命中特效壓力。
- `arrow` 的成本較低，用來鼓勵玩家建造迷宮。
- 如果新增塔種，除了資料表，還要補 `game_defs.gd` 類型、`game_ui.gd` 按鈕、`game_renderer.gd` 外觀、`combat_manager.gd` 特殊攻擊規則。

## `data/enemies.json`

目前敵人：

| key | 顯示名稱 | 說明 |
| --- | --- | --- |
| `basic` | 螞蟻 | 基礎敵人 |
| `tank` | 獨角仙 | 高血量，對箭塔有防禦 |
| `fast` | 蟑螂 | 高速度 |
| `reviver` | 蜘蛛 | 死亡後墓碑延遲復活 |
| `flying` | 蝗蟲 | 飛行，無視地面路徑 |
| `boss` | 多種 Boss | 每 10 波出現 |
| `auditor` | 攻擊量審查員 | 第 50 波後統計承受傷害與耗時 |

## `base` 欄位

`base` 是普通敵人的波次成長基準。

| 欄位 | 單位/型別 | 說明 |
| --- | --- | --- |
| `speed` | 像素/秒 | 基礎速度 |
| `speed_per_wave` | 像素/秒 | 每波速度增加 |
| `hp` | 數值 | 基礎血量 |
| `hp_per_wave` | 數值 | 每波血量增加 |
| `reward` | 金幣 | 基礎擊殺獎勵 |
| `reward_per_wave` | 金幣 | 每波獎勵增加 |
| `reward_soft_cap_wave` | 波數 | 獎勵成長開始壓低的波數 |
| `reward_late_scale` | 倍率 | 後期單隻獎勵成長倍率 |
| `reward_late_total_scale_wave` | 波數 | 後期總獎勵壓低開始波數 |
| `reward_late_total_scale` | 倍率 | 後期總獎勵縮放 |

## 敵人欄位

| 欄位 | 單位/型別 | 說明 |
| --- | --- | --- |
| `name` | 字串 | UI 或內部顯示名稱 |
| `names` | 字串陣列 | Boss 依序使用的名稱 |
| `color` | 顏色 | 繪製使用的主色 |
| `speed_multiplier` | 倍率 | 套用在基礎速度上的倍率 |
| `hp_multiplier` | 倍率 | 套用在基礎血量上的倍率 |
| `reward_bonus` | 金幣 | 擊殺額外獎勵 |
| `reward_multiplier` | 倍率 | Boss 擊殺獎勵倍率 |
| `arrow_damage_taken` | 倍率 | 承受箭塔傷害倍率，低於 `1.0` 表示抗箭塔 |
| `revives` | 次數 | 可復活次數 |
| `revive_hp_ratio` | 倍率 | 復活後血量比例 |
| `revive_speed_multiplier` | 倍率 | 復活後速度倍率 |
| `revive_delay` | 秒 | 死亡後墓碑停留多久才復活 |
| `revive_invulnerable_duration` | 秒 | 復活後無敵時間 |
| `flying` | 布林 | 是否為飛行敵人 |
| `auditor` | 布林 | 是否為攻擊量審查員 |

## 新增敵人流程

1. 在 `data/enemies.json` 新增敵人 key 與數值。
2. 在 `wave_manager.gd` 決定何時出現。
3. 如果有特殊行為，補 `enemy.gd` 狀態與 `main.gd` 死亡/移動流程。
4. 在 `game_renderer.gd` 補外觀。
5. 測試第 20、30、40 波之後是否過強或過弱。

## 新增塔流程

1. 在 `data/towers.json` 新增塔 key 與數值。
2. 在 `game_defs.gd` 新增塔類型常數。
3. 在 `game_ui.gd` 新增按鈕與快捷鍵提示。
4. 在 `build_manager.gd` 確認建造與升級可識別新類型。
5. 在 `combat_manager.gd` 補攻擊邏輯。
6. 在 `game_renderer.gd` 補塔、子彈、衝擊波外觀。
7. 在字型子集加入新中文名稱。
8. 更新 `docs/CHANGELOG.md` 與 `docs/GAME_LOGIC.md`。
