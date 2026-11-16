# Phân tích Bait Soul và hướng phát triển riêng

Ngày kiểm tra: 16/11/2026. Phạm vi: phân tích tĩnh, không chạy chương trình Windows trong bộ nguồn tham chiếu.

## Những gì đã kiểm tra trực tiếp

- Chỉ `Bait Soul.part2(1).rar` có byte đọc được trong phiên này. `Bait Soul.part1(2).rar` không tải được.
- Đọc 84 khối tiêu đề RAR5 và kiểm tra CRC32 của từng tiêu đề. Tài nguyên đầu phần 2 nối tiếp từ phần trước nên không thể khôi phục đầy đủ.
- Các mục độc lập có Addressables catalog, settings, gói ngôn ngữ và thư viện Unity/Mono. Tên thư mục Managed không chứng minh đã đọc được thư viện gameplay trong phần này.
- Trích riêng `catalog.json` (80.977 byte), `settings.json` (1.604 byte), gói bảng chữ tiếng Anh (26.171 byte). Mỗi mục độc lập được giải nén thành công, không báo lỗi CRC dữ liệu.
- Trình giải nén mặc định không hỗ trợ khai báo từ điển 256 MiB. Chỉ trong bản tạm của các mục nhỏ, độc lập, không solid, điều chỉnh khai báo xuống 64 MiB; dữ liệu đầu vào giữ nguyên và giải nén kiểm CRC. Không áp dụng cho mục tiếp nối bị thiếu.
- Gói tiếng Anh có chữ ký UnityFS, định dạng 8, revision **2022.3.62f2c1**. Giải nén khối LZ4 và đọc chuỗi từ tài nguyên serialized; không khôi phục mã C#.
- Chuỗi đã đọc cho thấy ô linh hồn có thuộc tính riêng; có hỗ trợ vũ khí kề bên, tăng số lần kích hoạt, tăng sát thương và một số thuộc tính thay đổi theo điều kiện. Đây là dấu vết dữ liệu, không phải bằng chứng về mọi nhánh xử lý hay công thức nội bộ.

## Đối chiếu thiết kế

| Cơ chế tham chiếu | Bản Tiên Lộ triển khai |
|---|---|
| Tự đánh, ưu tiên di chuyển và né | Vũ khí tự tìm địch trong tầm; chạy bằng thể lực, lướt có miễn sát thương ngắn |
| Hỗ trợ lên vũ khí liền kề | Lưới 2 × 3, ba pháp khí hỗ trợ sát thương, tốc đánh hoặc tầm; chỉ cạnh chung |
| Xây bộ trang bị qua từng lượt | Chọn chiến lợi phẩm, ghép bậc, mở ô và mua đồ |
| Nhánh khám phá và sự kiện | Mỗi tầng có nhánh chiến đấu, thương nhân, cổ đàn và trùm |
| Nội dung tiên hiệp riêng | Ba tông môn, tuyệt kỹ Q, tu vi, năm cảnh giới và ba bí cảnh |

Nguồn công khai: [Bait Soul do Bold Fish giới thiệu trên Steam](https://store.steampowered.com/app/3484100/Bait_Soul/). Nguồn định dạng: [RAR5 của RARLAB](https://www.rarlab.com/technote.htm).

## Chưa xác nhận

Chưa có đầy đủ phần 1 để đọc `Assembly-CSharp.dll`/thư viện gameplay, phục hồi cấu trúc lớp, đối chiếu tất cả trang bị, công thức sinh phòng hay cân bằng combat. Không tuyên bố phục hồi toàn bộ mã nguồn hoặc tái tạo chính xác game gốc. Ghi chép trong bản Dạ Hành cũ được thay bằng phạm vi đã kiểm tra trực tiếp ở lần này.

## Hướng tiếp theo khi có đủ dữ liệu

1. Ghép đúng cặp part1/part2 và kiểm thử tính toàn vẹn toàn bộ archive.
2. Kiểm kê assembly, metadata và dữ liệu thiết kế; xác định phần thực sự đọc được.
3. Lập bảng cơ chế và tham số quan sát được, tách rõ suy luận.
4. Mở rộng bản độc lập theo các cơ chế phù hợp; giữ nội dung và tài nguyên riêng.
