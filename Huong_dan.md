# Huyền Môn · Tiên Lộ

Bản chơi thử game hành động 2D góc nhìn từ trên xuống, xây bằng **Godot 4.6.3**. Giao diện, hướng dẫn, trang bị và cốt truyện dùng tiếng Việt. Phát triển tiếp từ dự án Huyền Môn · Dạ Hành.

## Chơi ngay từ mã nguồn

1. Tải mã nguồn của nhánh này bằng **Code → Download ZIP** và giải nén.
2. Mở Godot 4.6.3 bản tiêu chuẩn, chọn **Import**, chọn `project.godot`.
3. Nhấn **F5**. Chọn một tông môn để bắt đầu chuyến mới, hoặc **Tiếp tục chuyến đang lưu**.

Không cần .NET hoặc tiện ích ngoài. Font tiếng Việt đã đóng gói kèm giấy phép.

## Bản Windows

Workflow **Kiểm tra và đóng gói Windows** chạy khi mở/cập nhật pull request hoặc đẩy mã. Khi thành công, tải artifact **Huyen-Mon-Tien-Lo-Windows**, giải nén và mở `HuyenMonTienLo.exe`. Bản này chưa ký số.

Có thể xuất thủ công trong Godot: cài Export Templates 4.6.3, mở **Project → Export → Windows Desktop → Export Project**. Để cả `.exe` và `.pck` cùng thư mục.

## Nội dung chơi được

- Ba tông môn: **Thanh Vân Kiếm Tông**, **Cửu Tiêu Lôi Tông**, **Liên Hoa Đan Tông**; mỗi môn có vũ khí, sinh lực và tuyệt kỹ riêng.
- Ba bí cảnh: **Thanh Vân Sơn → U Minh Cổ Điện → Đài Độ Kiếp**; mỗi tầng có hai nhánh chiến đấu, cửa hàng, cổ đàn và trùm.
- Năm cảnh giới: **Luyện Khí → Trúc Cơ → Kim Đan → Nguyên Anh → Hóa Thần**. Tích tu vi khi dọn phòng; chọn tăng sát thương, tốc đánh hoặc sinh lực khi đột phá.
- Chín loại trang bị, năm linh bảo. Pháp trận 2 × 3, khởi đầu bốn ô; hỗ trợ chỉ tác động lên ô chung cạnh. Ghép hai món cùng loại, cùng bậc đến bậc 4.
- Tự đánh; kiếm quét, vòng lửa, phi châm làm chậm, tên xuyên, sét truyền và vòng băng. Tuyệt kỹ dùng chủ động bằng Q.
- Ba trùm, báo trước đòn đánh; trùm cuối chuyển pha dưới 50% sinh lực.
- Hai mức khó, âm thanh tổng hợp, kỷ lục và lưu chuyến đang chơi.

| Thao tác | Điều khiển |
|---|---|
| Di chuyển | WASD hoặc mũi tên |
| Chạy nhanh | Giữ Shift; dùng thể lực |
| Lướt né | Phím cách; miễn sát thương ngắn |
| Tuyệt kỹ tông môn | Q |
| Tương tác / nhận thưởng | E |
| Bản đồ | M; ngoài giao chiến |
| Tạm dừng | Esc |
| Đổi chỗ / ghép pháp khí | Bấm lần lượt hai ô ngoài giao chiến |

Tiến độ tự lưu khi vào phòng, nhận thưởng, ghép đồ, mua hàng, nhận linh bảo và chọn đột phá. Thoát giữa trận sẽ trở lại **đầu phòng**, không phải đúng khung hình đã thoát. Thắng hoặc tử trận kết thúc chuyến và xóa checkpoint. Bắt đầu chuyến mới thay thế bản lưu trước đó. Không có lưu đám mây.

## Phạm vi tham chiếu Bait Soul

Tham chiếu lối chơi được mô tả công khai và phân tích tĩnh các tài nguyên độc lập đọc được trong phần 2 của bộ RAR. **Chưa dịch ngược đầy đủ mã gameplay**, vì phần 1 không tải được trong phiên này. Xem [ghi chép phân tích](docs/phan_tich_tham_chieu.md).

Mã gameplay, thông số, tên gọi và hình vẽ trong dự án được xây dựng riêng. Kho này không chứa mã DLL, ảnh, âm thanh, bảng dịch hoặc tệp RAR của Bait Soul. Hình ảnh hiện là đồ họa vector đơn giản phục vụ bản chơi thử; chưa tương đương mức hoàn thiện của một game thương mại.

## Kiểm tra

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/kiem_thu.gd
```

Kiểm tra logic bao phủ tông môn, hỗ trợ liền cạnh, ghép đồ, lướt né, tuyệt kỹ, sét truyền, làm chậm, lưu/khôi phục, bản lưu lỗi, luồng ba tầng, thắng/thua và tạm dừng. Kiểm tra chiến dịch chủ động hạ địch để xác minh chuyển trạng thái; không thay thế chơi thử cân bằng độ khó. Cấu hình mục tiêu 60 FPS và 60 physics ticks/s; không phải cam kết hiệu năng trên mọi máy.

## Cấu trúc

| Tệp | Vai trò |
|---|---|
| `scripts/noi_dung.gd` | Tông môn, cảnh giới, trang bị, linh bảo, bản đồ |
| `scripts/chien_dau.gd` | Di chuyển, AI, đạn, kỹ năng và đồ họa vector |
| `scripts/tro_choi.gd` | Giao diện, phần thưởng, thương nhân, đột phá và chuyến chơi |
| `scripts/luu_tru.gd` | Kiểm tra và ghi bản lưu JSON |
| `tests/kiem_thu.gd` | Kiểm tra logic tích hợp |

Phông Noto: SIL Open Font License 1.1; xem `fonts/Giay_phep_phong_chu.txt`.
