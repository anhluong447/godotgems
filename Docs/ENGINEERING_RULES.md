# TRƯỜNG XUÂN — ENGINEERING RULES

Quy tắc bắt buộc cho mọi thay đổi, dù người hay AI viết. Mục tiêu: một người + AI vẫn giữ được code sạch trong 12–15 giờ nội dung.

## 1. Phiên bản và công cụ

- **Godot 4.7.x** (hiện tại 4.7.2). Không nâng phiên bản giữa milestone. Renderer Compatibility.
- GDScript, **kiểu tĩnh bắt buộc**: project bật `untyped_declaration = error`. Mọi biến, tham số, giá trị trả về, biến vòng lặp đều có kiểu.
- Test: GUT. Addon khác chỉ thêm khi có lý do rõ và ghi vào `ARCHITECTURE.md`.

## 2. Phân lớp (xem ARCHITECTURE.md §1)

1. `core/` thuần: không Node, không `get_tree()`, không autoload.
2. `definitions/` chỉ là Resource dữ liệu.
3. UI không sửa state gameplay.
4. **Call down, signal up**: cha gọi hàm con; con phát signal. Giao tiếp giữa các hệ thống xa nhau đi qua `EventBus`.
5. `EventBus` chỉ chứa signal **liên hệ thống**. Không dùng nó thay cho signal cục bộ.
6. Autoload giữ ít và mỏng. Thêm autoload mới phải có lý do (không đặt vào node trong scene được).

## 3. Dữ liệu

- **Không có số cân bằng trong code.** Chỉ số, thời gian đòn, sát thương, loot… nằm trong `data/*.tres`. Tuning toàn cục ở `data/config/combat_config.tres`.
- Mỗi definition có `id` (StringName) duy nhất. `Registry` báo lỗi khi trùng.
- Văn bản UI và truyện: hiện đang viết thẳng tiếng Việt; khi bắt đầu nội dung thật sẽ chuyển UI sang `tr()` (GDD 12.3).

## 4. Đặt tên

| Loại | Quy ước | Ví dụ |
|---|---|---|
| File, thư mục | `snake_case` | `health_component.gd` |
| `class_name` | `PascalCase` | `HealthComponent` |
| Hàm, biến | `snake_case`; private có `_` | `apply_damage()`, `_rng` |
| Hằng số | `UPPER_SNAKE` | `MAX_LINES` |
| Signal | thì quá khứ / sự kiện | `died`, `hit_received`, `leader_changed` |
| State node | `PascalCase`, trùng id state | `Locomotion`, `Telegraph` |
| Asset | theo GDD 13.2 | `assets/sprites/enemies/wolf/wolf_walk.png` |
| Input action | `snake_case` | `skill_1`, `switch_next` |

## 5. Scene và component

- Entity = một body + các component con. Tránh kế thừa sâu (hiện chỉ có `Actor` → `PartyMember`/`Enemy`).
- Resource dùng chung từ scene (shape…) **phải duplicate** trước khi sửa theo từng instance.
- Thứ tự xử lý khung hình của actor là tường minh (`Actor._physics_process`): think → state → ability → movement → regen → visual. Không để component tự `_physics_process` nếu kết quả phụ thuộc thứ tự.
- Hành động rời rạc (phím bấm) xử lý bằng event (`_unhandled_input`), không poll trong `_physics_process`.
- Thời gian gameplay đi theo game time (bị hitstop/pause ảnh hưởng). Hệ thống cần thời gian thực (hitstop, UI) dùng `process_mode = ALWAYS` + đồng hồ thực.

## 6. Test

- Logic `core/` mới **phải** có unit test.
- Component/entity mới: integration test cho luồng chính, ưu tiên bước thời gian thủ công (`physics_step(dt)`) thay vì chờ frame.
- Mỗi bug sửa xong phải có **test hồi quy** (ví dụ: hitstop không được kẹt, phím bấm trong hitstop không bị mất, UI cập nhật sau khi tải save).
- Nội dung mới phải qua được `test_data_integrity.gd`.
- `./run_tests.sh` xanh 100% trước mỗi commit.

## 7. Git

- Commit nhỏ, một mục đích. Message dạng `phạm vi: mô tả`, ví dụ `combat: add poise break to enemies`.
- Không commit `.godot/`. Có commit các file `.uid` và `.import`.
- Asset lớn (nhạc, CG) cân nhắc Git LFS khi bắt đầu có.

## 8. Checklist khi thêm một hệ thống

1. Phần logic thuần tách ra `core/` được không? Nếu được thì tách và viết test.
2. Số liệu có nằm trong data không?
3. Có cần lưu vào save không? Nếu có: thêm vào `GameState.to_dict/load_dict` và bump `SaveMigrator` nếu đổi format.
4. Có lệnh debug để test nhanh chưa?
5. Đã cập nhật `ARCHITECTURE.md` (bảng "Mở rộng") chưa?
