-- SMARTNUTRI DATABASE SCHEMA (MySQL 8.0)
-- Bảng 1: users - Thông tin người dùng, thể trạng và ngân sách
CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(150) NOT NULL UNIQUE,
    full_name VARCHAR(150),
    height DOUBLE,
    weight DOUBLE,
    target_weight DOUBLE,
    goal_type VARCHAR(20) DEFAULT 'BULK',
    activity_level VARCHAR(30) DEFAULT 'MODERATE',
    daily_calorie_target DOUBLE,
    daily_protein_target DOUBLE,
    daily_carbs_target DOUBLE,
    daily_fat_target DOUBLE,
    weekly_budget DOUBLE DEFAULT 450000.0,
    rmr DOUBLE,
    tdee DOUBLE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Bảng 2: local_ingredients_ref - Tham chiếu giá & dinh dưỡng thực phẩm bình dân địa phương
CREATE TABLE IF NOT EXISTS local_ingredients_ref (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL UNIQUE,
    aliases TEXT,
    avg_price_vnd DOUBLE NOT NULL,
    standard_unit VARCHAR(30) NOT NULL,
    standard_weight_g DOUBLE NOT NULL,
    protein_per_100g DOUBLE NOT NULL,
    calories_per_100g DOUBLE NOT NULL,
    carbs_per_100g DOUBLE NOT NULL,
    fat_per_100g DOUBLE NOT NULL,
    is_discrete BOOLEAN DEFAULT FALSE,
    max_portion DOUBLE DEFAULT 3.0,
    default_shelf_life_days INT DEFAULT 7,
    category VARCHAR(50)
);

-- Bảng 3: meals - Nhật ký bữa ăn
CREATE TABLE IF NOT EXISTS meals (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    dish_name VARCHAR(200) NOT NULL,
    meal_type VARCHAR(20) NOT NULL,
    image_url TEXT,
    total_calories DOUBLE,
    total_protein DOUBLE,
    total_carbs DOUBLE,
    total_fat DOUBLE,
    cost DOUBLE DEFAULT 0,
    health_note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Bảng 4: meal_items - Chi tiết thành phần bữa ăn
CREATE TABLE IF NOT EXISTS meal_items (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    meal_id BIGINT NOT NULL,
    item_name VARCHAR(150) NOT NULL,
    weight_g DOUBLE NOT NULL,
    calories DOUBLE,
    protein DOUBLE,
    carbs DOUBLE,
    fat DOUBLE,
    FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE
);

-- Bảng 5: pantry_items - Tủ lạnh ảo (Virtual Pantry)
CREATE TABLE IF NOT EXISTS pantry_items (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    ingredient_ref_id BIGINT,
    custom_name VARCHAR(150) NOT NULL,
    raw_name VARCHAR(200),
    quantity DOUBLE NOT NULL,
    unit VARCHAR(30) NOT NULL,
    cost_paid DOUBLE DEFAULT 0,
    purchase_date DATE NOT NULL,
    expiry_date DATE,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_ref_id) REFERENCES local_ingredients_ref(id) ON DELETE SET NULL
);

-- Bảng 6: receipt_logs - Lịch sử quét hóa đơn
CREATE TABLE IF NOT EXISTS receipt_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    merchant_name VARCHAR(150),
    total_amount DOUBLE NOT NULL,
    food_amount DOUBLE NOT NULL,
    receipt_image_url TEXT,
    purchase_date DATE NOT NULL,
    items_json TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Bảng 7: budget_logs - Nhật ký chi tiêu thực phẩm
CREATE TABLE IF NOT EXISTS budget_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    amount DOUBLE NOT NULL,
    category VARCHAR(50) DEFAULT 'FOOD',
    note VARCHAR(255),
    receipt_image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
