# SmartNutri - Trợ Lý Dinh Dưỡng & Ngân Sách Thông Minh

> Hệ thống trợ lý dinh dưỡng và quản lý ngân sách sinh viên Việt Nam, giải quyết bài toán: **Tối ưu dinh dưỡng thuần Việt theo ngân sách sinh viên**.

---

## Kiến Trúc Hệ Thống

```
SmartNutri/
├── backend/                   # Backend Java Spring Boot 3.4.2 REST API
│   ├── src/main/java/com/smartnutri/
│   │   ├── config/            # DataSeeder, CorsConfig
│   │   ├── controller/        # Vision, Receipt, Pantry, Optimizer, Dashboard, User
│   │   ├── dto/               # DTOs cho API Vision, OCR, MILP Optimizer
│   │   ├── model/             # JPA Entities: User, Meal, PantryItem, IngredientRef...
│   │   ├── repository/        # Spring Data JPA Repositories
│   │   └── service/           # Gemini Vision, Receipt OCR, MILP Optimizer, Pantry, Dashboard
│   ├── src/main/resources/
│   │   ├── application.properties        # Cấu hình chính (chọn profile mysql hoặc dev)
│   │   ├── application-mysql.properties  # Kết nối MySQL 8.0 (database: smartnutri)
│   │   ├── application-dev.properties    # H2 Database in-memory chạy test ngay
│   │   └── schema.sql                    # Toàn bộ DDL 7 bảng MySQL chuẩn theo HD.txt
│   └── pom.xml
│
├── mobile/                    # Frontend Mobile / Web App (Flutter 3.x)
│   ├── lib/
│   │   ├── api/api_service.dart          # REST client kết nối Backend + Fallback offline
│   │   ├── models/                       # Models: Meal, PantryItem, DashboardStats...
│   │   ├── screens/                      # Dashboard, Snap & Log, Tủ Lạnh, MILP Optimizer, Hồ Sơ
│   │   ├── theme/app_theme.dart          # Giao diện hiện đại (Emerald Green + Dark Mode)
│   │   └── widgets/                      # MacroRingCard, BudgetWatchdog, CpgpCard...
│   └── pubspec.yaml
│
├── .env                       # File cấu hình biến môi trường (MySQL password, Gemini API Key)
├── .env.example               # File mẫu hướng dẫn cấu hình
└── HD.txt                     # Tài liệu đặc tả và thiết kế hệ thống gốc
```

---



### Bước 1: Khởi động Backend (Spring Boot + MySQL)


## 4 Phân Hệ Tính Năng Cốt Lõi Theo `HD.txt`

### 1. Phân hệ 1: Thị giác & Nhận diện Món ăn Việt (Snap & Log)
- Chụp hoặc chọn ảnh đĩa thức ăn truyền thống Việt Nam (Cơm tấm, Phở bò, Bún chả...).
- Multimodal LLM (Google Gemini) bóc tách chi tiết từng thành phần và ước tính gram, calo, protein.
- **Chế độ chỉnh sửa Human-in-the-Loop**: Chạm vào từng thành phần để tăng/giảm định lượng (+1 trứng, +1 bát cơm, bỏ mỡ hành) ➔ Calo & Macros tự động tính lại theo thời gian thực.
- Tùy chọn: **Tự động trừ nguyên liệu tương ứng trong Tủ lạnh ảo**.

### 2. Phân hệ 2: Quản lý Chi tiêu & Scan Hóa đơn (Receipt-to-Pantry)
- Quét hóa đơn thanh toán siêu thị (WinMart, Bách Hóa Xanh, Co.opmart...).
- Gemini OCR trích xuất tên mặt hàng, phân loại `FOOD` vs `NON_FOOD`, giải mã từ viết tắt ("UC GA CP" ➔ "Ức gà").
- Tự động ước tính hạn sử dụng (Thịt sống: 3 ngày; Rau: 4 ngày; Trứng: 21 ngày).
- Modal Review bóc tách hóa đơn ➔ Bấm **"Thêm vào tủ lạnh & Cập nhật chi tiêu"** để nạp nguyên liệu vào tủ lạnh ảo và cộng chi phí tuần.
- **Budget Watchdog**: Theo dõi hạn mức chi tiêu tuần (ví dụ: 450.000 VNĐ) và cảnh báo tốc độ chi tiêu (Burn Rate Warning).

### 3. Phân hệ 3: Gợi ý Thực đơn Tiết kiệm Mục tiêu (MILP Optimizer) & Tủ Lạnh
- **Smart Leftovers (Nấu gì với tủ lạnh?)**: AI gợi ý 2-3 công thức nấu nhanh bằng dụng cụ sinh viên (chảo chống dính, nồi cơm điện) dựa trên đồ đang có trong tủ lạnh.
- **Target Budget Meal Planner (Core Differentiator)**:
  - Giải bài toán: *"Tôi còn 35.000 VNĐ hôm nay và cần nạp thêm ít nhất 50g protein. Tôi nên mua gì?"*
  - Thuật toán **Quy hoạch tuyến tính nguyên hỗn hợp (MILP)** kết hợp ràng buộc khẩu vị và đa dạng hóa (không để 1 món chiếm quá 60% đạm).
  - **Khấu trừ đồ trong Tủ lạnh với chi phí 0 VNĐ**.
  - Xuất danh sách mua sắm cụ thể: *"Mua 2 lạng ức gà (13k) + 2 bìa đậu (8k) + 2 quả trứng (6k) = 27k VNĐ ➔ Cung cấp 68g protein"*.
  - Nếu ngân sách không đủ: Thông báo số tiền tối thiểu chính xác cần bù thêm thay vì báo lỗi.

### 4. Phân hệ 4: Hồ sơ Thể trạng & Báo cáo Tiến độ
- Nhập chiều cao, cân nặng, mục tiêu, lộ trình: **Lean Bulk**, **Cut**, **Maintain**.
- Tính toán tự động **RMR (Mifflin-St Jeor)** và **TDEE**, phân bổ Calo, Protein, Carbs, Fat.
- **Chỉ số CPGP Độc Quyền (Cost per Gram of Protein)**: Đo lường chi phí trên từng gram đạm nạp vào (ví dụ: 450đ/g đạm là tiết kiệm xuất sắc).
