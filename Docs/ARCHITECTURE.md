# TRƯỜNG XUÂN — KIẾN TRÚC KỸ THUẬT (Backbone v0.2)

Tài liệu này mô tả **cách code được tổ chức** và **cách mở rộng**. Thiết kế game xem `v0.1/GGD.md`; quy tắc viết code xem `ENGINEERING_RULES.md`.

- Engine: **Godot 4.7** (bản Steam), GDScript có kiểu tĩnh, renderer **Compatibility**.
- Độ phân giải nội bộ 640×360, stretch `canvas_items` + integer scale (chữ tiếng Việt sắc nét, pixel art không méo).
- Test: **GUT 9.7.1** (`addons/gut`), chạy `./run_tests.sh`.

---

## 1. Phân lớp và luật phụ thuộc

```
            ┌──────────────────────────────┐
            │  ui/  (HUD, dialogue, menus) │   chỉ đọc state + nghe signal
            └──────────────┬───────────────┘
                           │
 ┌─────────────────────────▼──────────────────────────┐
 │ gameplay/  (Node, scene, component, entity, world) │
 │   definitions/  (Resource schema cho data/)        │
 └──────────┬──────────────────────────┬──────────────┘
            │                          │
 ┌──────────▼──────────┐    ┌──────────▼───────────┐
 │ core/  (logic thuần)│◄───│ autoload/ (services) │
 └─────────────────────┘    └──────────────────────┘
```

| Lớp | Được phép dùng | Không được |
|---|---|---|
| `src/core/` | Engine types thuần (`RefCounted`, `Resource`, `RandomNumberGenerator`, JSON) | `extends Node*`, `get_tree()`, autoload |
| `src/gameplay/definitions/` | `core`, các definition khác, behavior resource | Node, scene tree, autoload |
| `src/autoload/` | `core`, definitions | Tham chiếu trực tiếp tới entity cụ thể |
| `src/gameplay/` | `core`, definitions, autoload | Gọi ngược vào UI |
| `src/ui/` | Đọc mọi thứ; nghe `EventBus` | Sửa state gameplay (thêm đồ, gây sát thương, set flag) |

Luật được **kiểm tra tự động** trong `tests/architecture/test_layers.gd`.

## 2. Cây thư mục

```
res://
  src/
    core/            logic thuần: combat (DamageInfo, DamageCalculator, Faction, CombatConfig),
                     stats (StatBlock, ResourcePool), inventory, progression, save (codec, migrator),
                     input (ActionBuffer, ActorIntent), util (Cooldown, CommandLine)
    autoload/        EventBus, InputGate, Registry, GameState, SettingsService, AudioService (+SfxSynth),
                     SaveService, SceneRouter, HitstopService, DebugService
    gameplay/
      definitions/   CharacterDef, EnemyDef, AbilityDef, ProjectileDef, ItemDef, LootTable, DialogueData
      components/    Stats, Health, Hurtbox, Hitbox, Movement, Flash, StateMachine/State,
                     Interactable, LootDropper
      abilities/     AbilityComponent, AbilityContext, AbilityBehavior + behaviors/, AreaStrike
      entities/      Actor, ActorVisual; party/ (PartyMember, PartyManager, controllers, states);
                     enemies/ (Enemy + FSM states); props/ (Chest, Door, SignPost, Npc, Breakable, Pickup, Tree)
      projectiles/   Projectile
      effects/       Fx (factory hiệu ứng), TelegraphIndicator, DebugDraw
      world/         MapBase, MapHost, Spawner, GameCamera, PaletteController, FeedbackDirector
    ui/              hud/, dialogue/, menus/, debug/
    main.tscn/.gd    composition root
  data/              nội dung dạng .tres: characters/, enemies/, abilities/, items/, config/
  maps/              test_field.tscn, test_house.tscn
  assets/            sprites/, tilesets/, fonts/, audio/, shaders/, ui/theme.tres
  tools/             generate_placeholders.gd, build_maps.gd
  tests/             unit/, integration/, architecture/
```

## 3. Các luồng chính

### 3.1. Một đòn đánh (từ phím bấm tới số sát thương)

```
Phím J ──► PartyManager._unhandled_input ──► leader.intent.actions.press("attack")   (buffer 0.18s)
        ──► LocomotionState / AbilityState ──► PartyMember.try_start_queued_action()
        ──► AbilityComponent.try_use(AbilityDef)       trừ năng lượng, bắt đầu cooldown
              WINDUP ─► ACTIVE ─► RECOVERY             thời gian chạy theo game time (hitstop dừng được)
              behavior.on_active_start(ctx)            MeleeBehavior: bật Hitbox, lướt theo aim
        ──► HitboxComponent quét overlap mỗi physics frame
        ──► HurtboxComponent.receive_hit(DamageInfo)   lọc phe (Faction)
        ──► HealthComponent.apply_damage()             DamageCalculator (ATK/DEF, crit, variance)
              ├─► EventBus.damage_applied ──► FeedbackDirector: hitstop, rung camera, số, tia lửa, SFX
              └─► Actor._on_hit_received: knockback, flash, poise ─► Stagger/Flinch
```

Party và quái dùng **chung** hệ thống ability. Khác biệt chỉ ở ai điền `intent` (người chơi/AI) hoặc ai chọn ability (FSM quái).

### 3.2. Điều khiển nhân vật và đổi nhân vật

`PartyMember` **không biết ai điều khiển mình**: nó chỉ đọc `ActorIntent`. `PlayerController` (input) và `AIController` (theo leader, đánh quái gần) là hai cách điền intent. Đổi nhân vật = `PartyManager` đổi controller.

Phím hành động là **event-driven** (`_unhandled_input`), không poll trong `_physics_process`: khi hitstop, physics tick rất thưa nên poll sẽ làm mất phím (đã có test hồi quy).

### 3.3. Chuyển map

`Door` ─► `SceneRouter.change_map(path, spawn)` (fade, khoá input) ─► `MapHost.load_map()`: tách party khỏi map cũ, nạp map mới, đặt party vào `Entities` tại spawn, đặt giới hạn camera, áp bảng màu của map, phát `EventBus.map_loaded`. Party **tồn tại xuyên map**.

### 3.4. Lưu / tải

`SaveService.save_game(slot)` ─► `EventBus.before_save` (party ghi HP/vị trí vào `GameState`) ─► `GameState.to_dict()` ─► JSON ghi nguyên tử (tmp → rename, có .bak).
`load_game` ─► `SaveCodec.decode` (chạy `SaveMigrator`) ─► `GameState.load_dict` ─► `EventBus.after_load` (party dựng lại) ─► `SceneRouter.change_map`.

`GameState` là **model thụ động**: không tự nghe sự kiện, không chạm scene tree. Hệ thống cốt truyện sau này (Tuần, Anchor, Cổng) sẽ thêm section của mình vào đây và vào `SaveMigrator`.

### 3.5. Luồng khởi động

`title_screen.tscn` (main scene) ─► lần đầu: cảnh báo nội dung (+ Chế độ Nhẹ Tay) ─► menu.
- **Chơi mới**: `GameState.new_game()` ─► `SceneRouter.change_scene(GAME_SCENE)`.
- **Tiếp tục / Tải**: `SaveService.read_into_state(slot)` ─► `change_scene(GAME_SCENE)`; `main.gd` dựng party từ `GameState` và vào đúng map/vị trí.
- Pause ─► "Về màn hình chính": `change_scene(TITLE_SCENE)` (xoá khoá input, hitstop, pause cũ).

`SceneRouter.change_map` gọi trong lúc đang chuyển map sẽ **xếp hàng** (chạy yêu cầu mới nhất ngay sau đó), không bị bỏ.

### 3.6. Điều phối tấn công

`AttackDirector` (node trong main) giữ `TokenPool`: tối đa `CombatConfig.max_simultaneous_attackers` quái được ở Telegraph/Attack cùng lúc. Quái chưa có token thì lượn quanh chờ; token tự trả khi rời Telegraph/Attack, khi bị choáng, chết hoặc bị xoá. Quái đứng gần nhau tự đẩy ra (`Enemy.separation()`), nên bầy quái vây quanh thay vì dồn một cục.

### 3.7. Dùng vật phẩm (command qua EventBus)

UI hoặc phím `R` phát `EventBus.item_use_requested(id)` (id rỗng = thuốc nhỏ nhất còn có ích) ─► `PartyManager.use_item` kiểm tra, trừ đồ, hồi máu leader, phát `item_used`. UI không bao giờ tự sửa inventory.

### 3.8. Đa ngôn ngữ

Chữ UI là key trong `assets/i18n/ui.csv` (cột `vi`, `en`). Label/Button tĩnh gán thẳng key (Godot tự dịch và đổi ngay khi đổi ngôn ngữ); chuỗi có tham số dùng `tr("KEY") % [...]`. Test `test_i18n.gd` chặn key thiếu. Nội dung truyện/vật phẩm hiện vẫn là data tiếng Việt (sẽ bản địa hoá cùng hệ thống kịch bản).

### 3.9. Input gate

`InputGate.acquire(reason)` / `release(reason)` khoá input gameplay khi có hội thoại, console, chuyển map, wipe. Mỗi nguồn khoá bằng lý do riêng nên không mở nhầm khoá của nhau.

## 4. Mở rộng: công thức cho từng loại nội dung

| Muốn thêm | Làm gì | Cần sửa code? |
|---|---|---|
| **Quái mới** (hành vi có sẵn) | Tạo `data/enemies/<id>.tres` (EnemyDef) + sprite sheet 3×4 | Không. `Registry` tự nạp; `spawn <id>` dùng được ngay |
| **Đòn đánh / skill mới** | Tạo `data/abilities/<id>.tres`, chọn behavior Melee / Projectile / Area | Không |
| **Cơ chế skill mới** (vd. hồi máu, triệu hồi) | Subclass `AbilityBehavior`, override các hook | Chỉ thêm 1 file behavior |
| **Nhân vật mới** (Khải Hưng, Uyển Nhi) | `data/characters/<id>.tres` + thêm id vào `GameState.DEFAULT_PARTY` | 1 dòng |
| **Vật phẩm** | `data/items/<id>.tres` | Không |
| **Map mới** | Scene gốc gắn `map_base.gd` với Ground/Entities/SpawnPoints; vẽ bằng TileMapLayer; thả prop/Spawner vào Entities | Không |
| **NPC / biển báo** | Thả `npc.tscn` / `sign_post.tscn`, gán `DialogueData` hoặc `lines` | Không |
| **Chữ UI mới** | Thêm dòng vào `assets/i18n/ui.csv`, dùng key trong code | Không |
| **Chỉnh số liệu khi đang chơi** | Console: `tune <id> <thuộc tính> <giá trị>`, ưng thì `tune_save <id>` | Không |
| **Độ đông của trận** | `max_simultaneous_attackers`, `enemy_separation_radius` trong `combat_config.tres` | Không |
| **Lệnh debug** | `DebugService.register("tên", callable, "mô tả")` trong hệ thống sở hữu nó | 1 dòng |
| **Âm thanh thật** | Đặt `assets/audio/sfx/sfx_<id>.ogg`, sẽ đè lên synth placeholder cùng id | Không |
| **Art thật** | Ghi đè PNG cùng tên/kích thước (xem GDD 13) | Không |

Test `tests/unit/test_data_integrity.gd` chặn nội dung hỏng (ví dụ đòn quái có telegraph < 0.4s theo GDD 6.5, projectile ability thiếu projectile, map thiếu spawn mặc định).

## 5. Công cụ debug (chỉ bản debug)

- **F3**: overlay (FPS, node/orphan, state leader, phase ability, input gate…).
- **` hoặc F1**: console. Gõ `help`. Có `spawn`, `give`, `xp`, `heal`, `hurt`, `god`, `tp`, `kill_all`, `map`, `save`, `load`, `timescale`, `hitboxes`, `palette xuan|thuc|none`, `lang vi|en`, `tune`, `tune_save`, `enemies`, `items`, `abilities`.
- **F5 / F9**: lưu / tải nhanh (autosave slot).
- **Tự động hoá qua dòng lệnh** (để AI hoặc CI chụp màn hình, chơi thử theo kịch bản):
  ```
  # Truyền đường dẫn scene để vào thẳng game (bỏ qua màn hình tiêu đề):
  godot --path . res://src/main.tscn -- "--exec=60:spawn wolf 3;god" "--press=120:attack,140:skill_1:0.1" \
        "--shots=200:user://shot.png" "--quit-at=240"
  ```
  Số frame là process frame (FPS không khoá, ~120+), không phải giây.

## 6. Quy trình công cụ

```bash
# Sinh lại placeholder art (ghi đè PNG trong assets/)
godot --headless --path . -s res://tools/generate_placeholders.gd
godot --headless --path . --import
# Dựng lại TileSet + 2 map test (ghi đè maps/*.tscn)
godot --headless --path . -s res://tools/build_maps.gd
# Chạy toàn bộ test
./run_tests.sh
```

**CI**: `.github/workflows/tests.yml` tải Godot 4.7.2 Linux, import 2 lần, chạy GUT headless ở mỗi push/PR.

## 7. Chỗ gắn cho các milestone sau

| Milestone GDD | Gắn vào đâu |
|---|---|
| M1 TimeSystem, AnchorSystem, GateSystem, EndingEvaluator | `src/core/` (logic thuần + test), state lưu trong `GameState` + migration |
| Script Lite / Dialogue Manager | Thay/đặt cạnh `DialogueBox`; NPC vẫn chỉ phát `EventBus.dialogue_requested` |
| Tuần Đêm (Patrol) | Map mới với palette `thuc` + `CharacterDef` "Vũ đời thực" (không skill, chậm) — dùng lại Actor/Intent |
| gate_strain lên âm thanh | Hiệu ứng bus `Music` + `PaletteController` (đã có preset, thêm tham số) |
| Chế độ Nhẹ Tay | `SettingsService` đã có key `gentle_mode` (bật từ cảnh báo nội dung hoặc Cài đặt) |
| Rebind phím | `InputHints` đã đọc tên phím từ Input Map; chỉ cần UI ghi đè InputMap + lưu vào settings |
