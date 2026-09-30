# TRƯỜNG XUÂN — GAME DESIGN DOCUMENT (GDD) v1.0

**Nguồn cốt truyện:** Story Bible v2 (không lặp lại ở đây; GDD chỉ định nghĩa *cách game vận hành*).
**Engine:** Godot 4.4 (pin phiên bản, xem ENGINEERING_RULES.md), GDScript, renderer Compatibility.
**Nền tảng:** PC (Windows/Linux) là mục tiêu chính. Android là stretch goal, không ảnh hưởng thiết kế v1.
**Nhân sự:** 1 người + AI (vibe coding). Mọi quyết định phạm vi ở đây ưu tiên *làm xong được*.

Ký hiệu: **[QUYẾT ĐỊNH]** = GDD chốt (thay cho điểm mở của bible mục 13). **[TUNABLE]** = số liệu khởi điểm, nằm trong `data/`, được phép chỉnh khi playtest.

---

## 0. CÁC QUYẾT ĐỊNH CHỐT TỪ BIBLE MỤC 13

| #   | Điểm mở           | Quyết định                                                                                                    |
| --- | ----------------- | ------------------------------------------------------------------------------------------------------------- |
| 1   | Tên hệ thống      | **Anchor** giữ nguyên.                                                                                        |
| 2   | Nhãn NẶNG         | Giữ trên mọi Real Anchor. Kèm màn hình cảnh báo nội dung và chế độ "Nhẹ Tay" (mục 12).                        |
| 3   | Cổng đóng         | Đóng ở cả hai ending.                                                                                         |
| 4   | Quy luật Cổng     | **Sợi Dây** (mục 9): Cổng được giữ mở bởi những Real Anchor mà nhóm đang giữ liên lạc.                        |
| 5   | Hoàn thành Key    | Hoàn thành = không ra đi một mình. K1 bà Tuệ còn sống ở true ending.                                          |
| 6   | Số Anchor         | **Bản gọn 9 Anchor** là baseline: 4 Key (K1–K4), 2 thường (N1, N3), 3 Tale (T1, T3, T4). N2 và T2 là stretch. |
| 7   | Bóng Gương        | Giữ, chi phí thấp (chỉ thêm vài dòng thoại và sprite tái dùng).                                               |
| 8   | Cảnh báo nội dung | Bắt buộc, chốt trong v1.                                                                                      |
| 9   | Tên               | Giữ tên bible.                                                                                                |
| 10  | Nhóm chính        | 4 người, cố định.                                                                                             |
| 11  | Demo              | Vertical slice ở mục 17.                                                                                      |

**Hệ quả của việc cắt N2 và T2:** gợi ý "Hint 2" (bé Tiểu Diệp hỏi "các anh đi đâu…") chuyển sang **Bà Hoa Tú (T1)**. Nửa đầu game vẫn có đủ 2 Helpless Fail (N1 tuần 4, N3 tuần 15) để huấn luyện né tránh.

**Sửa lỗi thiết kế đã thảo luận (bẫy công bằng):** xem mục 11.

---

## 1. TÓM TẮT

Người chơi là Phùng Nhật Vũ. Mỗi tuần có 10 **Khung** thời gian. Người chơi tiêu Khung vào hai thế giới:

- **Trường Xuân:** Action RPG top-down thời gian thực, nhẹ, sáng, luôn thưởng lớn.
- **Thế giới thực (Kim Lạc):** khám phá + hội thoại + nhiệm vụ Tuần Đêm ngắn, nặng, thưởng kín đáo.

Cuối tuần 39 Cổng đóng. Ending phụ thuộc bốn Key Anchor có được hoàn thành hay không.

**Thời lượng mục tiêu:** 12–15 giờ một lượt (bản 9 Anchor). Chơi lại để thử ending kia.

## 2. DESIGN PILLARS

1. **Trốn tránh là lựa chọn có ý thức.** Người chơi luôn biết trước cái nặng (Case Card, NẶNG, Gut Punch). Không có bẫy thông tin.
2. **Hai thế giới phải có "cảm giác tay" khác nhau.** Trường Xuân: nhanh, mạnh, âm thanh dày, mọi thứ trúng. Thực: chậm, yếu, im, kết quả mờ. Khác biệt này nằm ở *cơ chế*, không chỉ ở art.
3. **Sức mạnh không giải quyết được vết thương.** Mọi tình huống thế giới thực mà "đánh" là đáp án thì thiết kế sai.
4. **Ở lại có trọng lượng thật, kể cả khi không cứu được.** Crack, Sợi Dây, epilogue.
5. **Làm được trong phạm vi một người.** Data-driven, tái dùng asset, cắt mạnh tay.

## 3. VÒNG LẶP

### 3.1. Vòng lặp tuần (macro)

```
Đầu tuần  → sự kiện tuần (bản tin, tin nhắn, story beat nếu đến hạn)
          → chọn hoạt động cho từng Khung (10 Khung)
Cuối tuần → tính Sợi Dây / gate_strain, autosave, sang tuần mới
```

### 3.2. Hoạt động trong một Khung

| Hoạt động                              | Thế giới | Tốn     | Kết quả                                                                   |
| -------------------------------------- | -------- | ------- | ------------------------------------------------------------------------- |
| Quest Trường Xuân (chiến đấu/khám phá) | Xuân     | 1 Khung | XP, Renown, vật phẩm                                                      |
| Chap Tale Anchor                       | Xuân     | 1 Khung | +1 Rank Tale, tiệc, Renown                                                |
| Chap Real Anchor                       | Thực     | 1 Khung | +1 Rank Real (nếu đủ điều kiện)                                           |
| Tuần Đêm                               | Thực     | 1 Khung | Kết quả 3 trạng thái, hỗ trợ Real Anchor                                  |
| Họp Tâm Giao                           | Thực     | 1 Khung | Đọc Case Card, nói chuyện với cô Nghi, thầy Phúc, đồng đội; mở Anchor mới |
| Nghỉ / Ở nhà                           | Thực     | 1 Khung | Hồi phục, cảnh đời thường                                                 |

**Story beat** (chap chính) **không tốn Khung**; nó kích hoạt theo tuần và tự chèn vào đầu tuần hoặc khi vào khu vực.

### 3.3. Vòng lặp phản hồi cố ý (loop cám dỗ)

- Trường Xuân: Renown tăng nhanh, có tiệc, có tiếng vỗ tay, danh xưng thăng cấp. **Sự kiện Lễ Hội có hạn định** ở Trường Xuân (thưởng lớn, chỉ mở vài tuần) tạo áp lực chọn thời gian.
- Thực: phần thưởng chậm, kín đáo. Nhưng Deadline có thật.

Tổng Khung: 400. Tổng nhu cầu nếu max hết: khoảng 45 chap Anchor + ~10 Tuần Đêm bắt buộc/tùy chọn + nhu cầu quest. Người chơi **có đủ Khung** để làm tất cả, nhưng tiêu bao nhiêu vào Trường Xuân là tự chọn. **[QUYẾT ĐỊNH]** Áp lực đến từ **cooldown giữa Rank** (mục 5.4) và Deadline, không phải khan hiếm tài nguyên thô.

---

## 4. HỆ THỐNG THỜI GIAN

- **Tuần:** 1–40. **Khung/tuần:** 10 (hiển thị thành lịch tuần: 5 tối trong tuần, Thứ 7 ba Khung, Chủ nhật hai Khung).
- Khung không phân biệt loại; chỉ là đơn vị chi tiêu. Lịch chỉ để trình bày.
- Tuần kết thúc khi hết Khung hoặc người chơi bấm "Kết thúc tuần" (Khung dư mất).
- **Deadline** tính theo tuần (bảng bible 6.4). Real Anchor "mất" ngay khi bước sang tuần Deadline+1 mà chưa đạt Rank 5.
- Mọi phép tính thời gian dùng `TimeSystem` (domain, thuần), inject vào các hệ khác.

---

## 5. HỆ THỐNG ANCHOR

### 5.1. Mô hình dữ liệu

```
Anchor {
  id: StringName            # "K1", "N1", "T1"...
  kind: enum {KEY, NORMAL, TALE}
  world: enum {REAL, XUAN}
  unlock_week: int
  deadline_week: int|null   # null với Tale
  ranks: 5 × Rank
  fail_type: enum {NONE, HELPLESS, NEGLECT_ONLY}
  crack_id: StringName|null # với NORMAL
}
Rank {
  index: 1..5
  script_id: StringName     # file thoại/cảnh
  requires: [Condition]     # ví dụ: rank trước xong, cooldown, cờ
  cooldown_weeks: int       # tối thiểu giữa Rank trước và Rank này  [TUNABLE]
  patrol_id: StringName|null
}
```

### 5.2. Trạng thái Anchor

```
LOCKED → AVAILABLE → IN_PROGRESS → COMPLETED
                  ↘              ↘
                   LOST (quá Deadline)   CLOSED_HELPLESS (Rank 5 của NORMAL, có Crack)
```

- **LOCKED:** chưa tới `unlock_week`, hoặc chưa "nghe" qua Họp Tâm Giao. Không có thông tin hiện ra (bible: nếu không mở khóa thì không có gì hiện).
- **AVAILABLE:** Case Card xuất hiện ở bảng. Deadline hiển thị.
- **IN_PROGRESS:** đã làm ≥ 1 Rank.
- **COMPLETED:** Rank 5 xong. Với KEY = "được cứu theo nghĩa bible 5.5". Với TALE = tiệc.
- **CLOSED_HELPLESS:** NORMAL đã đến Rank 5 (kết cục bi thảm). Vẫn nhận Crack.
- **LOST:** quá Deadline.

Chuyển trạng thái chỉ xảy ra qua `AnchorSystem` (domain). UI không tự đổi trạng thái.

### 5.3. Luật tiến Rank

1. Rank N+1 chỉ mở khi Rank N đã xong **và** đã qua `cooldown_weeks` (mặc định 1 tuần với Real, 0 với Tale). **[TUNABLE]** Giữ cooldown là để ép người chơi trải dài công sức qua thời gian, tránh "đánh một mạch xong hết".
2. Một Rank chỉ cần 1 Khung. Có Rank kèm `patrol_id` thì Rank đó chỉ tính khi hoàn thành Tuần Đêm (mọi kết quả, xem mục 7).
3. Real Anchor bị mất khi `current_week > deadline_week` và trạng thái chưa COMPLETED/CLOSED_HELPLESS.

### 5.4. Bảng cửa sổ thời gian (baseline 9 Anchor) **[TUNABLE]**

| Anchor               | Loại   | Mở  | Hạn                         | Cửa sổ | Rank tối thiểu (tuần với cooldown 1) |
| -------------------- | ------ | --- | --------------------------- | ------ | ------------------------------------ |
| N1 Cung Hoài Thu     | NORMAL | 4   | 16                          | 12     | 5                                    |
| K1 Đinh Thị Tuệ      | KEY    | 8   | 32                          | 24     | 5                                    |
| N3 Lâm Trọng Nghĩa   | NORMAL | 15  | 28                          | 13     | 5                                    |
| K2 Hàn Bích Lam      | KEY    | 21  | 35                          | 14     | 5                                    |
| K3 Vương Đức Thành   | KEY    | 24  | 36                          | 12     | 5                                    |
| K4 Tiêu Hạo Nhiên    | KEY    | 27  | 38                          | 11     | 5                                    |
| T1 Bà Hoa Tú         | TALE   | 3   | (Hồi I kết thúc, tuần 13)   | –      | –                                    |
| T3 Ngư ông Trần Bách | TALE   | 14  | (Hồi II kết thúc, tuần 26)  | –      | –                                    |
| T4 Nữ hoàng Tuệ Anh  | TALE   | 28  | (Hồi III kết thúc, tuần 38) | –      | –                                    |

Tale "hết hạn" theo Hồi chỉ là **mở/đóng nội dung**, không phải mất Anchor: bỏ lỡ thì không xem được chap, không có hậu quả cốt truyện.

Kiểm tra bắt buộc bằng test dữ liệu (ENGINEERING_RULES 7): `deadline - unlock >= 5 + 1` với mọi Real Anchor.

### 5.5. Điều kiện Key Anchor và "không đánh dấu"

- Game **không** hiển thị Key/thường. Dấu hiệu nhận biết mềm (bible 5.6): Key Anchor chủ động liên lạc khi Vũ vắng mặt (tin nhắn, ấm trà, giấy dán cửa). Được hiện thực bằng **sự kiện đầu tuần** (`outreach`) chỉ dành cho KEY khi Anchor IN_PROGRESS nhưng không có tiến triển ≥ 2 tuần.
- Tất cả Real Anchor đều có nhãn NẶNG trên Case Card.

### 5.6. Crack (Vết Nứt)

- Mỗi NORMAL khi tới CLOSED_HELPLESS được trao **một Crack**, là một **vật phẩm hiển thị vĩnh viễn** trong Phòng Tâm Giao (kệ "Những gì còn lại"):
  - N1: bát mì "phần cho ai cần"
  - N3: bản nháp đơn xin việc gấp gọn
  - (N2 nếu làm: bài hát ông Sinh ngân nga, dạng music box)
- Crack có hiệu quả cơ chế nhỏ (mục 11) và được dùng lại ở epilogue.

---

## 6. CHIẾN ĐẤU TRƯỜNG XUÂN

### 6.1. Nguyên tắc

- Top-down 2D, thời gian thực, **nhẹ nhàng, mạnh mẽ, rộng lượng**: cảm giác quyền năng là ý đồ (pillar 2).
- Độ khó thấp–vừa; có chế độ **Dễ** (ít sát thương nhận, kẻ địch ít máu).
- Không có tử vong thật: hết HP toàn đội = quay về hub Trường Xuân, mất một phần vật phẩm tiêu hao (hoặc không mất gì ở chế độ Dễ). **[QUYẾT ĐỊNH]** Không tốn Khung thêm.

### 6.2. Điều khiển

Bàn phím + tay cầm:

| Hành động    | Bàn phím       | Ghi chú                                     |
| ------------ | -------------- | ------------------------------------------- |
| Di chuyển    | WASD / mũi tên | 8 hướng                                     |
| Đánh thường  | J              | Combo 3 nhịp cho Vũ; khác nhau mỗi nhân vật |
| Kỹ năng 1    | K              | Tốn Xuân Lực                                |
| Kỹ năng 2    | L              | Tốn Xuân Lực                                |
| Né           | Space          | Có i-frame ngắn                             |
| Đổi nhân vật | 1–4 hoặc Q/E   | Đổi tức thời, cooldown 1s                   |
| Tương tác    | E hoặc Enter   |                                             |
| Menu         | Esc            |                                             |

### 6.3. Đội hình

- Người chơi điều khiển **một** nhân vật, đổi bất cứ lúc nào. Ba người còn lại do AI đi theo và tấn công đơn giản (follow + tấn công khi kẻ địch trong tầm).
- HP dùng chung? **[QUYẾT ĐỊNH]** HP riêng từng người; người ngã (HP=0) nằm 10s rồi tự đứng dậy với 30% HP. Chỉ khi cả 4 ngã mới "thua".

### 6.4. Nhân vật **[TUNABLE — số chỉ để khởi động]**

| Nhân vật                | Vai             | HP  | ATK | DEF | SPD | Đánh thường          | Kỹ năng 1                   | Kỹ năng 2                                |
| ----------------------- | --------------- | --- | --- | --- | --- | -------------------- | --------------------------- | ---------------------------------------- |
| Nghĩa Kiếm (Vũ)         | Cận chiến nhanh | 100 | 12  | 4   | 110 | Combo kiếm 3 nhịp    | Xung Kích: lướt và chém     | Phong Vũ: xoay vòng, đẩy lui             |
| Hoan Cung (Bình An)     | Tầm xa          | 80  | 10  | 3   | 100 | Bắn tên (đạn thẳng)  | Tên Xuyên                   | Mưa Tên (khu vực)                        |
| Thiết Thuẫn (Khải Hưng) | Chịu đòn        | 140 | 8   | 8   | 85  | Đập khiên (tầm ngắn) | Khiên Chắn (chặn 3s, aggro) | Chấn Địa (choáng)                        |
| Tri Tuệ (Uyển Nhi)      | Hỗ trợ          | 70  | 7   | 2   | 95  | Đạn phép nhỏ         | Trị Liệu (hồi HP)           | Tiêu Điểm (kẻ địch nhận thêm sát thương) |

Xuân Lực: dùng chung mỗi nhân vật 100 điểm, hồi 5/giây khi không dùng kỹ năng. Kỹ năng tốn 20–40.

**Cấp độ:** XP từ quest và quái, cấp tối đa 30, mỗi cấp tăng chỉ số theo đường cong trong `data/characters.json`. Không có trang bị ở v1 (stretch: "Ấn Xuân" charm, một ô mỗi người).

### 6.5. Kẻ địch

Máy trạng thái chung: `Idle → Chase → Telegraph → Attack → Recover` (+ `Stagger`). **Mọi đòn đánh phải có telegraph ≥ 0.4s** để chiến đấu dễ đọc.

| Hồi                   | Loại thường (4)                               | Mini-boss           | Boss                        |
| --------------------- | --------------------------------------------- | ------------------- | --------------------------- |
| I: Thanh Đằng         | Sói con, Heo rừng, Quạ hoang, Sâu đất         | Sói đầu đàn         | (không)                     |
| II: Bạch Lộ           | Lính gác, Cung thủ lính, Kỵ binh nhẹ, Chó săn | Đội trưởng cấm quân | **Ngụy Huyền Cang** (3 pha) |
| III: Quốc Trường Xuân | Bóng nhỏ, Bóng gai, Bóng bay, Bóng đúc        | 3 thủ lĩnh Bóng Tàn | **Bóng Tàn** (4 pha)        |

Boss dùng cùng khung `Enemy` với script mẫu tấn công riêng (dạng danh sách pha trong data).

### 6.6. Renown

- Điểm Danh Vọng nhận từ quest hoàn thành, sự kiện Trường Xuân, Tale Anchor.
- Danh xưng theo ngưỡng (bible 5.8): Lữ Khách (0) → Hiệp Sĩ (100) → Thống Lĩnh (300) → Xuân Sứ (600) → Đại Xuân Sứ (1000) → Người Cứu Thế (1500). **[TUNABLE]**
- Đạt danh xưng mới: tiệc + cảnh khen. **Không có trạng thái thất bại** ở Trường Xuân (chỉ có thất bại chiến đấu tạm thời).
- Renown *chỉ* điều khiển: danh xưng, cảnh ăn mừng, cảnh dân làng tin cậy, và tỉ lệ hiện chi tiết ở ending xấu (tượng). Renown **không** ảnh hưởng ending logic.

### 6.7. Quest Trường Xuân

- Quest nền (đuổi thú, diệt quái, phục dựng): tái dùng khuôn mẫu từ data. Số lượng: ~8 mỗi Hồi ở baseline **[TUNABLE]**.
- Quest phục dựng: người chơi nộp nguyên liệu → công trình làng/thành hiện dần (ảnh hưởng thị giác, mở vài NPC phụ).

---

## 7. TUẦN ĐÊM (PATROL) — CƠ CHẾ

**[QUYẾT ĐỊNH]** Đây là thứ phải làm khác hẳn Trường Xuân (pillar 2, 3).

### 7.1. Nguyên tắc

- Cảnh ngắn **60–150 giây**, top-down, tại địa điểm thực (chợ đêm, hẻm, công viên).
- Vũ **không có vũ khí, không có kỹ năng Trường Xuân**. Tốc độ thấp hơn, có thể bị đẩy ngã.
- Không có thanh máu kẻ địch. Không có số sát thương. Không có nhạc dâng.
- Đánh bại đối phương bằng vũ lực **không phải** đáp án. Đối phương thường mạnh hơn hoặc đông hơn.
- Luôn có một cảnh sau (coda) yên lặng ngắn, **không có tiệc**.

### 7.2. Hành động của người chơi

| Hành động              | Hiệu ứng                                                             |
| ---------------------- | -------------------------------------------------------------------- |
| Chạy (stamina hữu hạn) | Đuổi, chạy tránh                                                     |
| Chắn                   | Đứng chắn lối/che người, giảm sát thương nhưng chậm                  |
| Hô lớn                 | Thu hút chú ý người xung quanh, làm đối phương do dự (cooldown lâu)  |
| Gọi hỗ trợ             | Gọi một đồng đội hoặc người lớn tới một lần; hiệu lực tùy tình huống |
| Ghi lại (Nhi)          | Thu thập bằng chứng/dấu vết; đo bằng thanh tiến độ khi đứng yên      |
| Kéo/đưa người          | Đưa Anchor ra khỏi nguy hiểm                                         |

### 7.3. Mục tiêu và kết quả

Mỗi Tuần Đêm là một **mục tiêu tổng hợp** (ví dụ: lấy lại túi tiền + ghi lại biển số + đưa nạn nhân đi), và có cấu hình `outcome_rules` trong data:

- **THÀNH CÔNG:** đạt đủ mục tiêu bắt buộc.
- **THẤT BẠI:** thiếu mục tiêu bắt buộc hoặc hết giờ.
- **THÀNH CÔNG_KHÔNG_CÔNG_NHẬN:** đạt mục tiêu nhưng cảnh sau cho thấy không ai tin/xin lỗi. Chỉ cấu hình cho những cảnh được kịch bản chỉ định (N3 Rank 2).

Một số Tuần Đêm được **kịch bản hóa** để kết quả không đổi theo kỹ năng (ví dụ K3 Rank 2: nhóm chỉ mua được thời gian). `scripted_outcome` cho phép ép kết quả trong data, và UI **không** nói dối: người chơi thấy khoảng cách giữa nỗ lực và kết quả (đây là ý đồ).

### 7.4. Tác động lên Anchor

- Với Rank có `patrol_id`, Rank được tính **cho mọi kết quả** (không phạt vì thất bại), nhưng nội dung chap tiếp theo phản ánh kết quả.
- Tuần Đêm **không cộng Renown**.
- Tuần Đêm không thể thay thế Rank hội thoại (Rank 5 luôn là cảnh hội thoại).

### 7.5. Kích thước công việc

Baseline có tối đa **6 Tuần Đêm**: N1 (Rank 2), N3 (Rank 2), K1 (không), K2 (không, đúng bible: đánh cha mẹ không phải đáp án), K3 (Rank 2), K4 (không). Khuôn scene chung `PatrolScene` + data.

---

## 8. THẾ GIỚI THỰC

### 8.1. Khám phá

- Bản đồ dạng **hub-and-spoke**: chọn địa điểm từ bản đồ thành phố (không tự đi bộ khắp nơi). Vào địa điểm thì là một phòng/cảnh nhỏ walkable với NPC, đồ vật, chi tiết giác quan.
- Địa điểm mở theo Anchor đang hoạt động (bible 3.2).
- Tương tác: nói chuyện, xem đồ vật (mô tả ngắn), khởi động Rank/Tuần Đêm.

### 8.2. Phòng Tâm Giao (hub thực)

- Bảng **Case Card** (mỗi Real Anchor AVAILABLE: một dòng tóm tắt, nhãn NẶNG, Deadline).
- Kệ **Những gì còn lại** (Crack).
- Đồng đội có mặt/vắng mặt theo **độ trôi dạt** (mục 9.3).
- Cổng Xuân ở cuối hành lang gác mái.

### 8.3. Phòng Tâm Giao ở Trường Xuân

Hub Trường Xuân: bảng quest và Tale Anchor. Cách bố trí khác hẳn (ấm, sáng, đông người).

### 8.4. Bản tin mất Anchor

Khi Anchor LOST: **sự kiện chèn** (bản tin TV/báo/tin nhắn), lạnh và ngắn, xuất hiện *đúng lúc* nhóm đang ăn mừng hoặc vừa quay về (bible 6.5). Không có lời bình.

---

## 9. CỔNG XUÂN, SỢI DÂY VÀ TRÔI DẠT

### 9.1. Sợi Dây (thay cho quy luật 9.3 của bible)

- Có tối đa 6 sợi (4 Key + 2 Normal). Mỗi sợi là một Real Anchor.
- Một sợi được coi là **"đang giữ"** nếu Anchor không LOST và (đã COMPLETED/CLOSED_HELPLESS hoặc có tiến triển trong 3 tuần gần nhất).
- **Sợi "đang bị bỏ":** AVAILABLE/IN_PROGRESS nhưng không tiến triển > 3 tuần.
- Sợi LOST bị **đứt vĩnh viễn**.

### 9.2. gate_strain

```
available = số Real Anchor đã AVAILABLE (tính tới tuần hiện tại)
held      = số sợi đang giữ trong số available
lost      = số sợi LOST
gate_strain = clamp( (available - held) / max(available, 1) * 0.7 + lost / 6 * 0.3, 0, 1 )   # [TUNABLE]
```

`gate_strain` chạy 0→1, hiển thị **gián tiếp** (không có thanh):

| gate_strain | Biểu hiện                                                                           |
| ----------- | ----------------------------------------------------------------------------------- |
| ≥ 0.15      | Cổng mở hơi chậm; nhạc Phòng Tâm Giao thấp một nhịp                                 |
| ≥ 0.35      | Sương quanh Cổng mờ; phòng Vũ có bụi                                                |
| ≥ 0.55      | Cổng phải thử 2–3 lần mới mở; nhạc Trường Xuân cắt sớm                              |
| ≥ 0.75      | Nhạc chính bị chậm và chệch nốt; dân làng nhắc "Xuân Sứ trước cũng đi rồi không về" |
| Tuần 39     | Cổng đóng (mọi trường hợp)                                                          |

Các hint bible mục 10 được ánh xạ lên bảng này; nội dung hint gắn cờ theo ngưỡng chứ không theo tuần cố định (nhưng có mốc tuần tối thiểu để không lộ quá sớm).

### 9.3. Trôi dạt của nhóm (Drift)

- Mỗi nhân vật có `drift ∈ [0,1]`, tăng khi người chơi tiêu nhiều Khung ở Trường Xuân liên tiếp và giảm khi làm Real Anchor/Họp Tâm Giao. **[TUNABLE]**
- `drift` điều khiển: có mặt ở Họp Tâm Giao, thoại ngoài đời cụt dần, đồ đạc Phòng Tâm Giao.
- Sự kiện "cú đấm thực" theo Hồi (bible 4.4) là **sự kiện kịch bản gắn tuần**, độc lập với drift.

---

## 10. ENDING

```
func evaluate_ending(anchors) -> Ending:
    if all(anchors[k].state == COMPLETED for k in [K1, K2, K3, K4]):
        return TRUE_ENDING   # "Người Ở Lại"
    return BAD_ENDING        # "Bức Tượng"
```

- Ending được đánh giá **duy nhất tại chap 38** (tuần 40). Không đánh giá sớm.
- **Epilogue biến thể** (đọc từ trạng thái, không thêm ending):
  - True: mỗi Key hiện đúng theo bible 9.1. Cảnh Crack: bát mì, bản nháp (tùy Crack người chơi có).
  - Bad: Anchor nào còn sống/mất quyết định chi tiết nhỏ (ngọn đèn nếu K1 còn, tin nhắn chưa mở). Renown quyết định chi tiết bức tượng.
- Cổng đóng ở cả hai.

**Kiểm thử bắt buộc:** các "bot" mô phỏng playthrough (ENGINEERING_RULES 8.4) chứng minh ending logic đúng với các tổ hợp.

---

## 11. BẪY CÔNG BẰNG — CÁC QUYẾT ĐỊNH SỬA

Vấn đề: người chơi bị dạy "Real nặng và vô ích" rồi bị phạt vì bỏ đi. Cách sửa:

1. **Crack hữu hình sớm.** N1 xong (khoảng tuần 12–16) → kệ "Những gì còn lại" xuất hiện trong Phòng Tâm Giao với bát mì. Người chơi thấy ngay việc "ở lại" để lại dấu vết.
2. **Crack có tác dụng nhỏ.** Mỗi Crack trên kệ: `+1 Sợi Dây được coi là "đang giữ" vĩnh viễn` (tức là giảm gate_strain), và mở một dòng thoại mới với cô Nghi/thầy Phúc. Không phải chỉ số chiến đấu.
3. **Foreshadow lý thuyết.** Thầy Phúc nói ở chap 2–3 và Hồi I: "Có những ca không cứu được. Người ta vẫn cần có ai đó ở lại." Không lặp lại lần thứ hai.
4. **Hint có thể hành động.** Cổng chậm là tín hiệu *có liên quan tới thế giới thực* (gắn với Sợi Dây); người chơi có thể quay lại Phòng Tâm Giao để thấy sợi nào đang bị bỏ.
5. **Sổ Ca (Journal).** Màn hình liệt kê các Anchor và tình trạng dạng chữ nhẹ ("Bà Tuệ: chờ bạn 3 tuần rồi"), **không** hiện tiến độ số học. Không lộ Key/thường.

Điều này giữ nguyên ý đồ (né tránh có ý thức) mà không biến bad ending thành phạt vì thiếu thông tin.

---

## 12. UI / UX

### 12.1. Danh sách màn hình

1. Màn hình tiêu đề, Cài đặt, Chọn slot lưu.
2. **Cảnh báo nội dung** (lần chạy đầu, có thể xem lại): bạo hành, mất mát, nợ nần, cô lập. Có nút "Chế độ Nhẹ Tay".
3. Bản đồ thành phố (thực), Bản đồ Trường Xuân.
4. Lịch tuần (chọn Khung).
5. Hội thoại/visual-novel (khung thoại, chân dung, lựa chọn).
6. Case Card / bảng Tâm Giao, Sổ Ca, Kệ "Những gì còn lại".
7. HUD chiến đấu, HUD Tuần Đêm (tối giản).
8. Menu tạm dừng, Nhân vật (chỉ số, kỹ năng), Vật phẩm, Danh vọng.
9. CG viewer (gallery mở dần).
10. Màn hình ending, credits.

### 12.2. Chế độ Nhẹ Tay

Tuỳ chọn toàn cục: giảm chi tiết của Gut Punch/chap nặng (thay đoạn mô tả bằng dạng gián tiếp, bỏ CG nặng). Cần **hai phiên bản** các cảnh được đánh dấu `heavy: true` trong data; cảnh không có bản nhẹ dùng bản chuẩn. Ưu tiên K2, N1, K4.

### 12.3. Nguyên tắc UI

- Trường Xuân: bảng màu ấm, chuyển cảnh nhanh, âm thanh phản hồi phong phú.
- Thực: bảng màu lạnh/xám, chữ chậm hơn, ít hiệu ứng.
- Phông chữ **phải hỗ trợ đầy đủ dấu tiếng Việt** (kiểm thử bằng chuỗi có `ệ ữ ằ ẫ ơ ư`); kiểm tra trước khi chọn phông.
- Tất cả văn bản UI qua bảng dịch (`tr()`); văn bản truyện nằm ở file script theo ngôn ngữ.
- Điều khiển đầy đủ bằng phím/tay cầm; cỡ chữ tùy chỉnh; tốc độ chữ tùy chỉnh.

---

## 13. ART DIRECTION VÀ ĐẶC TẢ ASSET

### 13.1. Thông số kỹ thuật **[QUYẾT ĐỊNH]**

| Hạng mục            | Giá trị                                                                                          |
| ------------------- | ------------------------------------------------------------------------------------------------ |
| Độ phân giải nội bộ | 640×360 (16:9), scale số nguyên (3× → 1920×1080)                                                 |
| Ô lưới (tile)       | 32×32                                                                                            |
| Sprite nhân vật     | 32×48 mỗi khung; 4 hướng × 3 khung đi; sheet riêng cho tấn công/né/ngã                           |
| Chân dung hội thoại | 256×256, 4 biểu cảm cơ bản (bình thường, vui, buồn, giận) cho nhân vật chính                     |
| CG                  | 1280×720 (giảm từ 1920×1080 để tiết kiệm công; hiển thị co dãn 1.5×) hoặc 1920×1080 nếu bạn muốn |
| Định dạng           | PNG (không nén mất mát), nền trong suốt cho sprite                                               |
| Bảng màu            | Hai bảng: **Xuân** (bão hòa, ấm) và **Thực** (giảm bão hòa, lạnh)                                |

Kỹ thuật chuyển thế giới: shader đổi bảng màu (palette swap/LUT) hoặc hai bộ tileset. Chọn LUT-based shader cho *cả hai* để tái dùng sprite nhân vật.

### 13.2. Quy ước tên file

```
assets/characters/<id>/<id>_walk.png
assets/characters/<id>/<id>_attack.png
assets/portraits/<id>_<expression>.png
assets/tilesets/<world>_<area>.png
assets/cg/cg_<anchorid>_r<rank>_<slug>.png
assets/audio/music/bgm_<slug>.ogg
assets/audio/sfx/sfx_<category>_<slug>.ogg
```

### 13.3. Danh sách asset baseline (ước tính)

**Nhân vật (sheet):** 4 chính; NPC Thực ~10 (cô Nghi, thầy Phúc, bà Tuệ, ông Thành, Bích Lam, Hạo Nhiên, Hoài Thu + bé, Trọng Nghĩa, bố mẹ Hạo Nhiên, người lớn phụ); NPC Xuân ~8; kẻ địch 12 + mini-boss 4 + boss 2 (nhiều biến thể tái dùng bằng đổi màu).

**Tileset:** Thực: Phòng Tâm Giao, hẻm/chợ đêm, công viên, quán mì, bệnh viện, nhà Vũ, nhà Hạo Nhiên, trạm xe buýt, bến cảng. Xuân: làng, rừng, thành, vương quốc, vùng Bóng Tàn.

**CG (baseline ~18):**
- Real (Gut Punch quan trọng): K1 ba chiếc chén, K2 "em ổn", K3 điện thoại rung, K4 cửa phòng, N1 bát mì, N3 tờ lý lịch
- Xuân: lễ hội mùa gặt, đăng quang Tuệ Anh, đại lễ Người Cứu Thế
- Endings: True ×4 (bà Tuệ/đèn, Bích Lam, ông Thành, Hạo Nhiên), Bad ×2 (bức tượng, Phòng Tâm Giao trống), epilogue Crack ×1

Mỗi CG heavy có phiên bản nhẹ tay (mục 12.2) nếu áp dụng.

---

## 14. ÂM THANH

### 14.1. Bus

`Master → Music, SFX, Voice(stretch), UI`. Hiệu ứng trên bus Music: `AudioEffectPitchShift` + `AudioEffectLowPassFilter`, điều khiển theo `gate_strain` cho hint 12 của bible (nhạc chậm, chệch nốt). Không dùng nhạc riêng cho hint; dùng chính nhạc đầu game biến dạng.

### 14.2. Danh sách nhạc baseline (~18)

Tiêu đề; Phòng Tâm Giao (biến thể thực, biến thể Trường Xuân); Làng Thanh Đằng (ngày, đêm/lễ hội); Bạch Lộ; Quốc Trường Xuân; Bóng Tàn; chiến đấu thường; boss ×2; Tuần Đêm (rất tối giản); các chủ đề Anchor (K1 đèn, K2, K3, K4, N1); true ending; bad ending; credits.

**Nhất quán motif:** chủ đề Phòng Tâm Giao là giai điệu nền được biến tấu ở mọi nơi (ngoài đời chậm/ít nhạc cụ; Trường Xuân rộng/nhiều nhạc cụ; ending méo).

### 14.3. SFX

UI (di chuyển, chọn, quay lại), chiến đấu (đánh, trúng, né, kỹ năng ×8), môi trường (bước chân theo bề mặt), Cổng (mở, kẹt, đóng), Thực (tiếng điện thoại rung, tiếng ấm trà, mưa), lễ hội (vỗ tay, chuông).

Định dạng: OGG Vorbis, nhạc loop có điểm loop chuẩn; SFX mono.

---

## 15. DỮ LIỆU VÀ KỊCH BẢN

### 15.1. Định dạng dữ liệu

- Toàn bộ nội dung nằm trong `data/` (JSON). Mã không chứa số cân bằng hay nội dung truyện.
- Mỗi file có `schema_version`. Loader kiểm tra và báo lỗi rõ ràng.
- Tệp: `anchors.json`, `characters.json`, `enemies.json`, `skills.json`, `quests.json`, `patrols.json`, `events.json`, `endings.json`, `gate.json`, và `scripts/<lang>/*.txt` (kịch bản).

Ví dụ `anchors.json`:

```json
{
  "schema_version": 1,
  "anchors": [
    {
      "id": "K1",
      "kind": "KEY",
      "world": "REAL",
      "name": "Đinh Thị Tuệ",
      "title": "Người Giữ Đèn",
      "unlock_week": 8,
      "deadline_week": 32,
      "fail_type": "NEGLECT_ONLY",
      "case_card": { "summary_key": "K1_CARD", "heavy_label": true },
      "ranks": [
        { "index": 1, "script": "k1_r1", "cooldown_weeks": 0, "heavy": true },
        { "index": 2, "script": "k1_r2", "cooldown_weeks": 1 },
        { "index": 3, "script": "k1_r3", "cooldown_weeks": 1 },
        { "index": 4, "script": "k1_r4", "cooldown_weeks": 1 },
        { "index": 5, "script": "k1_r5", "cooldown_weeks": 1 }
      ]
    }
  ]
}
```

### 15.2. Định dạng kịch bản (Script Lite)

Định dạng văn bản một dòng một lệnh, dễ viết cho người và AI, parse bằng parser có test:

```
# k1_r1.txt
@meta scene=tram_xe_buyt_7 world=real heavy=true
@bg tram_xe_buyt_7_night
@music bgm_real_rain
VU: (đứng ở quầy trà) Bà ơi, cho con ly trà nóng.
@cg cg_k1_r1_ba_chen
TUE: Con cũng vừa về hả... Thằng út?
@wait 1.0
@choice
  - "Con là Nhật Vũ ạ." -> vu_name
  - "..." -> vu_silence
@label vu_name
TUE: Ừ, ừ... ai cũng đi mất.
@end_rank
```

Lệnh cơ bản: `@bg @music @sfx @cg @wait @choice @label @goto @set @if @end_rank @unlock @give_crack @patrol @fade`.
Dòng nói: `TÊN: nội dung`; `TÊN: (mô tả hành động) nội dung`.
Các lệnh có hiệu ứng trạng thái (`@set`, `@unlock`, `@give_crack`, `@end_rank`) chỉ phát sự kiện để `app/` xử lý; parser và runner **không** trực tiếp sửa hệ thống.

### 15.3. Cờ (flag) và điều kiện

- `FlagStore` (domain): `Dictionary[StringName, Variant]` với API hạn chế (`set_flag`, `get_flag`, `has_flag`).
- Điều kiện dùng biểu thức nhỏ: `week>=8`, `anchor.K1.rank>=3`, `flag.met_hoa_tu`, có `and/or/not`. Parser điều kiện có test riêng.

---

## 16. LƯU GAME

- 3 slot thủ công + 1 autosave (đầu mỗi tuần).
- Định dạng JSON có `save_version`; **migration** từng phiên bản (test).
- Ghi nguyên tử (ghi file tạm rồi đổi tên).
- Nội dung lưu: tuần/Khung, FlagStore, trạng thái Anchor, đội hình (cấp, XP, HP tối đa, drift), Renown, kho vật phẩm, cờ Crack, cài đặt nội dung (Nhẹ Tay), seed RNG.
- Không lưu vị trí giữa trận. Chỉ lưu ở hub/đầu Khung.

---

## 17. LỘ TRÌNH VÀ TIÊU CHÍ HOÀN THÀNH

Mỗi milestone kết thúc bằng: toàn bộ test xanh, bản chạy được, ghi chú thay đổi.

| M      | Tên                    | Nội dung                                                                                                                                       | Tiêu chí hoàn thành                                                                                                         |
| ------ | ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **M0** | Nền tảng               | Repo, Godot 4.4, cấu trúc lớp, test runner (GUT), lint/format, CI, debug console                                                               | `run_tests` chạy headless và xanh; test kiểm tra kiến trúc chạy                                                             |
| **M1** | Lõi không giao diện    | `TimeSystem`, `FlagStore`, `AnchorSystem`, `GateSystem`, `EndingEvaluator`, ScriptParser/Runner, Save + migration                              | Toàn bộ logic domain có test; bot playthrough chứng minh true/bad ending                                                    |
| **M2** | Chiến đấu thẳng        | Vũ + 1 kẻ địch + hub Trường Xuân, đổi nhân vật (2 người)                                                                                       | Đánh, né, chết/hồi sinh hoạt động; test FSM kẻ địch                                                                         |
| **M3** | **Vertical slice**     | Làng Thanh Đằng; T1; N1 (Gut Punch + Helpless Fail + Crack); K1 thu nhỏ (Rank 1–2 + Rank 5); 1 Tuần Đêm; Deadline; Hint 1–3; cảnh báo nội dung | Chơi từ đầu tới hết Hồi I mà không lỗi; gate_strain có hiệu ứng nhìn/nghe thấy; sáu phút playtest xong cảm thấy đúng "vibe" |
| **M4** | Hồi I đầy đủ           | 4 đồng đội, kẻ địch/quest Hồi I, T1, N1, K1 đủ 5 Rank, chap chính 1–10                                                                         | Hồi I hoàn chỉnh                                                                                                            |
| **M5** | Hồi II                 | Bạch Lộ, Ngụy Huyền Cang, T3, N3, K2, K3                                                                                                       | Hồi II hoàn chỉnh                                                                                                           |
| **M6** | Hồi III                | Quốc Trường Xuân, Bóng Tàn, T4, K4                                                                                                             | Hồi III hoàn chỉnh                                                                                                          |
| **M7** | Chung kết + Hoàn thiện | Chap 35–38, hai ending, epilogue, CG viewer, cân bằng, Nhẹ Tay, hoàn thiện âm thanh                                                            | Hai ending chạy được; playtest đủ; build phát hành                                                                          |

**Vertical slice = kiểm tra sống còn.** Nếu người chơi ở M3 không cảm thấy được sự đối lập hai thế giới (pillar 2), dừng và chỉnh thiết kế trước khi đổ thêm nội dung.

**Danh sách cắt giảm (theo thứ tự cắt đầu tiên):** Bóng Gương → Chế độ Nhẹ Tay (chỉ giữ cảnh báo) → giảm số kẻ địch/quest → giảm biểu cảm chân dung → cắt CG phụ (giữ 6 Gut Punch + endings).

---

## 18. RỦI RO

| Rủi ro                          | Giảm thiểu                                                                |
| ------------------------------- | ------------------------------------------------------------------------- |
| Quy mô nội dung vượt sức        | Baseline 9 Anchor; data-driven; kịch bản dạng văn bản; vertical slice sớm |
| Tuần Đêm nhàm/hoặc "quá vui"    | Prototype riêng ở M2–M3; kiểm tra cảm giác trước khi làm 6 cảnh           |
| Đề tài nhạy cảm gây phản cảm    | Cảnh báo, Nhẹ Tay, không mô tả trực diện, người lớn đúng vai (bible 12)   |
| Nhạc/sprite tự làm chậm         | Tái dùng asset (đổi màu, LUT); ưu tiên asset gây cảm xúc (6 Gut Punch CG) |
| Vibe-coding sinh mã rối         | Quy tắc kỹ thuật + test kiến trúc + PR nhỏ                                |
| Ending/thời gian bị bug âm thầm | Bot playthrough mô phỏng cả 40 tuần trong test                            |

---

## 19. PHỤ LỤC — DEBUG TOOLS BẮT BUỘC

Game 40 tuần không thể test tay. Có sẵn từ M0/M1 (chỉ trong bản debug):

- Console: `week N`, `set_flag`, `anchor K1 rank 3`, `anchor K1 state LOST`, `gate_strain 0.8`, `ending true`, `give_xp`, `skip_patrol success|fail`.
- Overlay: tuần/Khung, gate_strain, trạng thái từng Anchor, FPS, số node mồ côi.
- Nút "Tua tới tuần…" và "In log trạng thái".

*HẾT GDD v1.0.*