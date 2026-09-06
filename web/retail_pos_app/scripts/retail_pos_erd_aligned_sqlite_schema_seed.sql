-- =========================================================
-- Retail / POS Database Project
-- ERD-aligned schema + 30-row seed data
-- DBMS: SQLite / FastAPI local development
-- Generated edit: matches the uploaded ERD table structure and names.
-- =========================================================

PRAGMA foreign_keys = OFF;

-- Drop child tables first
DROP TABLE IF EXISTS sale_return_item;
DROP TABLE IF EXISTS sale_return;
DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS sale_item;
DROP TABLE IF EXISTS sale;
DROP TABLE IF EXISTS points_transaction;
DROP TABLE IF EXISTS loyalty_account;
DROP TABLE IF EXISTS po_item;
DROP TABLE IF EXISTS purchase_order;
DROP TABLE IF EXISTS shift;
DROP TABLE IF EXISTS inventory_movement;
DROP TABLE IF EXISTS discount_product;
DROP TABLE IF EXISTS discount;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS role_permission;
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS department;
DROP TABLE IF EXISTS register;
DROP TABLE IF EXISTS branch;
DROP TABLE IF EXISTS role;
DROP TABLE IF EXISTS supplier;

PRAGMA foreign_keys = ON;

-- =========================================================
-- Core master data
-- =========================================================

CREATE TABLE supplier (
    id INTEGER PRIMARY KEY,
    sup_n TEXT NOT NULL,
    contact_n TEXT,
    phone TEXT,
    email TEXT UNIQUE,
    address TEXT,
    tax_num TEXT,
    pay_terms_days INTEGER NOT NULL DEFAULT 0 CHECK (pay_terms_days >= 0),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER
);

CREATE TABLE role (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    r_desc TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER
);

CREATE TABLE branch (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    manager_id INTEGER,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER,
    FOREIGN KEY (manager_id) REFERENCES employee(id)
);

CREATE TABLE register (
    id INTEGER PRIMARY KEY,
    branch_id INTEGER NOT NULL,
    register_code TEXT NOT NULL UNIQUE,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER,
    FOREIGN KEY (branch_id) REFERENCES branch(id)
);

CREATE TABLE department (
    id INTEGER PRIMARY KEY,
    branch_id INTEGER NOT NULL,
    dep_name TEXT NOT NULL,
    manager_id INTEGER,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER,
    FOREIGN KEY (branch_id) REFERENCES branch(id),
    FOREIGN KEY (manager_id) REFERENCES employee(id)
);

CREATE TABLE employee (
    id INTEGER PRIMARY KEY,
    first_n TEXT NOT NULL,
    last_n TEXT NOT NULL,
    national_ID TEXT UNIQUE,
    email TEXT UNIQUE,
    dep_id INTEGER,
    role_id INTEGER,
    salary REAL CHECK (salary IS NULL OR salary >= 0),
    hire_date TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER,
    FOREIGN KEY (dep_id) REFERENCES department(id),
    FOREIGN KEY (role_id) REFERENCES role(id)
);

CREATE TABLE role_permission (
    id INTEGER PRIMARY KEY,
    role_id INTEGER NOT NULL,
    module TEXT NOT NULL,
    action TEXT NOT NULL,
    descr TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER,
    FOREIGN KEY (role_id) REFERENCES role(id)
);

-- =========================================================
-- Product and supplier area
-- =========================================================

CREATE TABLE category (
    id INTEGER PRIMARY KEY,
    parent_id INTEGER,
    cat_name TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER,
    FOREIGN KEY (parent_id) REFERENCES category(id)
);

CREATE TABLE product (
    id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER NOT NULL,
    supplier_id INTEGER,
    barcode TEXT UNIQUE,
    cost_price REAL NOT NULL CHECK (cost_price >= 0),
    sell_price REAL NOT NULL CHECK (sell_price >= 0),
    stock_qty REAL NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
    reorder_level REAL NOT NULL DEFAULT 0 CHECK (reorder_level >= 0),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER,
    FOREIGN KEY (category_id) REFERENCES category(id),
    FOREIGN KEY (supplier_id) REFERENCES supplier(id)
);

CREATE TABLE inventory_movement (
    id INTEGER PRIMARY KEY,
    product_id INTEGER NOT NULL,
    movement_type TEXT NOT NULL CHECK (movement_type IN ('opening_stock', 'purchase', 'sale', 'return', 'adjustment_in', 'adjustment_out')),
    qty REAL NOT NULL,
    movement_date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES product(id)
);

CREATE TABLE discount (
    id INTEGER PRIMARY KEY,
    disc_name TEXT NOT NULL,
    type_d TEXT NOT NULL CHECK (type_d IN ('percentage', 'fixed_amount')),
    value_d REAL NOT NULL CHECK (value_d >= 0),
    st_date TEXT NOT NULL,
    end_date TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER
);

CREATE TABLE discount_product (
    id INTEGER PRIMARY KEY,
    discount_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER,
    FOREIGN KEY (discount_id) REFERENCES discount(id),
    FOREIGN KEY (product_id) REFERENCES product(id),
    UNIQUE (discount_id, product_id)
);

-- =========================================================
-- Customer, loyalty and sales area
-- =========================================================

CREATE TABLE customer (
    id INTEGER PRIMARY KEY,
    cus_name TEXT NOT NULL,
    phone TEXT UNIQUE,
    email TEXT UNIQUE,
    loyalty_points INTEGER NOT NULL DEFAULT 0 CHECK (loyalty_points >= 0),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    registered_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER
);

CREATE TABLE loyalty_account (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL UNIQUE,
    card_number TEXT NOT NULL UNIQUE,
    points_balance INTEGER NOT NULL DEFAULT 0 CHECK (points_balance >= 0),
    membership_level TEXT NOT NULL DEFAULT 'Basic' CHECK (membership_level IN ('Basic', 'Silver', 'Gold', 'Platinum')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customer(id)
);

CREATE TABLE sale (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    employee_id INTEGER NOT NULL,
    register_id INTEGER NOT NULL,
    sale_date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount REAL NOT NULL CHECK (total_amount >= 0),
    tax_amount REAL NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    discount_amount REAL NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    final_amount REAL NOT NULL CHECK (final_amount >= 0),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customer(id),
    FOREIGN KEY (employee_id) REFERENCES employee(id),
    FOREIGN KEY (register_id) REFERENCES register(id)
);

CREATE TABLE sale_item (
    id INTEGER PRIMARY KEY,
    sale_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    qty REAL NOT NULL CHECK (qty > 0),
    unit_price REAL NOT NULL CHECK (unit_price >= 0),
    total_price REAL NOT NULL CHECK (total_price >= 0),
    FOREIGN KEY (sale_id) REFERENCES sale(id),
    FOREIGN KEY (product_id) REFERENCES product(id)
);

CREATE TABLE payment (
    id INTEGER PRIMARY KEY,
    sale_id INTEGER NOT NULL,
    amount REAL NOT NULL CHECK (amount >= 0),
    pay_date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_p TEXT NOT NULL CHECK (status_p IN ('pending', 'paid', 'failed', 'refunded')),
    pay_method TEXT NOT NULL CHECK (pay_method IN ('cash', 'card', 'wallet', 'bank_transfer')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sale_id) REFERENCES sale(id)
);

CREATE TABLE sale_return (
    id INTEGER PRIMARY KEY,
    sale_id INTEGER NOT NULL,
    customer_id INTEGER,
    return_date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_return REAL NOT NULL CHECK (total_return >= 0),
    reason TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sale_id) REFERENCES sale(id),
    FOREIGN KEY (customer_id) REFERENCES customer(id)
);

CREATE TABLE sale_return_item (
    id INTEGER PRIMARY KEY,
    sale_return_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    qty REAL NOT NULL CHECK (qty > 0),
    refund_amount REAL NOT NULL CHECK (refund_amount >= 0),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sale_return_id) REFERENCES sale_return(id),
    FOREIGN KEY (product_id) REFERENCES product(id)
);

CREATE TABLE points_transaction (
    id INTEGER PRIMARY KEY,
    loyalty_id INTEGER NOT NULL,
    points_change INTEGER NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('earn', 'redeem', 'refund', 'adjustment')),
    transaction_date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loyalty_id) REFERENCES loyalty_account(id)
);

-- =========================================================
-- Purchasing area
-- =========================================================

CREATE TABLE purchase_order (
    id INTEGER PRIMARY KEY,
    supplier_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    order_date TEXT NOT NULL,
    expected_date TEXT,
    total_amount REAL NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    status_po TEXT NOT NULL CHECK (status_po IN ('pending', 'ordered', 'received', 'cancelled')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES supplier(id),
    FOREIGN KEY (employee_id) REFERENCES employee(id)
);

CREATE TABLE po_item (
    id INTEGER PRIMARY KEY,
    po_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    qty REAL NOT NULL CHECK (qty > 0),
    cost_price REAL NOT NULL CHECK (cost_price >= 0),
    total_cost REAL NOT NULL CHECK (total_cost >= 0),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (po_id) REFERENCES purchase_order(id),
    FOREIGN KEY (product_id) REFERENCES product(id)
);

CREATE TABLE shift (
    id INTEGER PRIMARY KEY,
    register_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT,
    opening_balance REAL NOT NULL DEFAULT 0 CHECK (opening_balance >= 0),
    closing_balance REAL CHECK (closing_balance IS NULL OR closing_balance >= 0),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (register_id) REFERENCES register(id),
    FOREIGN KEY (employee_id) REFERENCES employee(id)
);



-- =========================================================
-- Seed data: 30 rows per table
-- =========================================================

INSERT INTO role (id, name, r_desc, created_at, created_by, updated_by) VALUES
(1, 'Admin', 'Admin permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(2, 'Manager', 'Manager permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(3, 'Cashier', 'Cashier permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(4, 'Inventory Clerk', 'Inventory Clerk permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(5, 'Sales Employee', 'Sales Employee permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(6, 'Purchasing Officer', 'Purchasing Officer permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(7, 'Finance Officer', 'Finance Officer permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(8, 'HR Officer', 'HR Officer permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(9, 'Marketing Officer', 'Marketing Officer permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(10, 'Auditor', 'Auditor permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(11, 'Customer Service', 'Customer Service permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(12, 'Warehouse Supervisor', 'Warehouse Supervisor permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(13, 'Branch Supervisor', 'Branch Supervisor permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(14, 'Data Analyst', 'Data Analyst permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(15, 'IT Support', 'IT Support permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(16, 'Security Officer', 'Security Officer permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(17, 'Delivery Coordinator', 'Delivery Coordinator permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(18, 'Supplier Manager', 'Supplier Manager permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(19, 'Quality Inspector', 'Quality Inspector permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(20, 'Accountant', 'Accountant permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(21, 'Regional Manager', 'Regional Manager permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(22, 'Trainee', 'Trainee permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(23, 'Product Manager', 'Product Manager permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(24, 'Category Manager', 'Category Manager permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(25, 'Loyalty Manager', 'Loyalty Manager permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(26, 'Shift Leader', 'Shift Leader permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(27, 'Return Officer', 'Return Officer permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(28, 'Procurement Analyst', 'Procurement Analyst permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(29, 'Operations Officer', 'Operations Officer permissions and responsibilities', '2026-05-08 12:00:00', 1, 1),
(30, 'General User', 'General User permissions and responsibilities', '2026-05-08 12:00:00', 1, 1);

INSERT INTO supplier (id, sup_n, contact_n, phone, email, address, tax_num, pay_terms_days, is_active, created_at, created_by, updated_by) VALUES
(1, 'Nile Food Supplies', 'Youssef Mahmoud', '01010000001', 'supplier1@example.com', 'Cairo, Egypt - Industrial Zone 1', 'TAX-10001', 30, 1, '2026-05-08 12:00:00', 1, 1),
(2, 'Delta Fresh Trading', 'Ahmed Hassan', '01010000002', 'supplier2@example.com', 'Giza, Egypt - Industrial Zone 2', 'TAX-10002', 45, 1, '2026-05-08 12:00:00', 1, 1),
(3, 'Cairo Pack Co', 'Mohamed Ali', '01010000003', 'supplier3@example.com', 'Alexandria, Egypt - Industrial Zone 3', 'TAX-10003', 60, 1, '2026-05-08 12:00:00', 1, 1),
(4, 'Alex Bottles Factory', 'Mahmoud Ibrahim', '01010000004', 'supplier4@example.com', 'Ismailia, Egypt - Industrial Zone 4', 'TAX-10004', 15, 1, '2026-05-08 12:00:00', 1, 1),
(5, 'Suez Oils Supplier', 'Omar Mostafa', '01010000005', 'supplier5@example.com', 'Suez, Egypt - Industrial Zone 5', 'TAX-10005', 30, 1, '2026-05-08 12:00:00', 1, 1),
(6, 'Canal Retail Supply', 'Khaled Sayed', '01010000006', 'supplier6@example.com', 'Port Said, Egypt - Industrial Zone 6', 'TAX-10006', 45, 1, '2026-05-08 12:00:00', 1, 1),
(7, 'Green Valley Farms', 'Mostafa Adel', '01010000007', 'supplier7@example.com', 'Mansoura, Egypt - Industrial Zone 7', 'TAX-10007', 60, 1, '2026-05-08 12:00:00', 1, 1),
(8, 'Upper Egypt Foods', 'Hassan Fathy', '01010000008', 'supplier8@example.com', 'Tanta, Egypt - Industrial Zone 8', 'TAX-10008', 15, 1, '2026-05-08 12:00:00', 1, 1),
(9, 'Misr Dairy Products', 'Ali Nasser', '01010000009', 'supplier9@example.com', 'Zagazig, Egypt - Industrial Zone 9', 'TAX-10009', 30, 1, '2026-05-08 12:00:00', 1, 1),
(10, 'Lotus Cleaning Supplies', 'Ibrahim Saleh', '01010000010', 'supplier10@example.com', 'Fayoum, Egypt - Industrial Zone 10', 'TAX-10010', 45, 0, '2026-05-08 12:00:00', 1, 1),
(11, 'Sinai Water Co', 'Mazen Samir', '01010000011', 'supplier11@example.com', 'Minya, Egypt - Industrial Zone 11', 'TAX-10011', 60, 1, '2026-05-08 12:00:00', 1, 1),
(12, 'Pharaoh Paper Products', 'Karim Kamal', '01010000012', 'supplier12@example.com', 'Assiut, Egypt - Industrial Zone 12', 'TAX-10012', 15, 1, '2026-05-08 12:00:00', 1, 1),
(13, 'Nour Frozen Foods', 'Tarek Farouk', '01010000013', 'supplier13@example.com', 'Sohag, Egypt - Industrial Zone 13', 'TAX-10013', 30, 1, '2026-05-08 12:00:00', 1, 1),
(14, 'Smart Retail Devices', 'Hany Gaber', '01010000014', 'supplier14@example.com', 'Qena, Egypt - Industrial Zone 14', 'TAX-10014', 45, 1, '2026-05-08 12:00:00', 1, 1),
(15, 'Badr Plastic Industries', 'Samir Younis', '01010000015', 'supplier15@example.com', 'Luxor, Egypt - Industrial Zone 15', 'TAX-10015', 60, 1, '2026-05-08 12:00:00', 1, 1),
(16, 'Ismailia Fresh Market', 'Mariam Ashraf', '01010000016', 'supplier16@example.com', 'Cairo, Egypt - Industrial Zone 16', 'TAX-10016', 15, 1, '2026-05-08 12:00:00', 1, 1),
(17, 'Golden Grains Egypt', 'Nour Taha', '01010000017', 'supplier17@example.com', 'Giza, Egypt - Industrial Zone 17', 'TAX-10017', 30, 1, '2026-05-08 12:00:00', 1, 1),
(18, 'Red Sea Beverages', 'Menna Amin', '01010000018', 'supplier18@example.com', 'Alexandria, Egypt - Industrial Zone 18', 'TAX-10018', 45, 1, '2026-05-08 12:00:00', 1, 1),
(19, 'Mansoura Snacks Co', 'Salma Hamdy', '01010000019', 'supplier19@example.com', 'Ismailia, Egypt - Industrial Zone 19', 'TAX-10019', 60, 1, '2026-05-08 12:00:00', 1, 1),
(20, 'Tanta Sugar Trade', 'Sara Mansour', '01010000020', 'supplier20@example.com', 'Suez, Egypt - Industrial Zone 20', 'TAX-10020', 15, 0, '2026-05-08 12:00:00', 1, 1),
(21, 'Zagazig Rice Mills', 'Nada Lotfy', '01010000021', 'supplier21@example.com', 'Port Said, Egypt - Industrial Zone 21', 'TAX-10021', 30, 1, '2026-05-08 12:00:00', 1, 1),
(22, 'Fayoum Herbs Co', 'Heba Fouad', '01010000022', 'supplier22@example.com', 'Mansoura, Egypt - Industrial Zone 22', 'TAX-10022', 45, 1, '2026-05-08 12:00:00', 1, 1),
(23, 'Minya Pasta Factory', 'Aya Shahin', '01010000023', 'supplier23@example.com', 'Tanta, Egypt - Industrial Zone 23', 'TAX-10023', 60, 1, '2026-05-08 12:00:00', 1, 1),
(24, 'Assiut Canned Food', 'Reem Osman', '01010000024', 'supplier24@example.com', 'Zagazig, Egypt - Industrial Zone 24', 'TAX-10024', 15, 1, '2026-05-08 12:00:00', 1, 1),
(25, 'Sohag Dates Co', 'Farah Zaki', '01010000025', 'supplier25@example.com', 'Fayoum, Egypt - Industrial Zone 25', 'TAX-10025', 30, 1, '2026-05-08 12:00:00', 1, 1),
(26, 'Qena Spices House', 'Dina Riad', '01010000026', 'supplier26@example.com', 'Minya, Egypt - Industrial Zone 26', 'TAX-10026', 45, 1, '2026-05-08 12:00:00', 1, 1),
(27, 'Luxor Honey Farm', 'Jana Khalil', '01010000027', 'supplier27@example.com', 'Assiut, Egypt - Industrial Zone 27', 'TAX-10027', 60, 1, '2026-05-08 12:00:00', 1, 1),
(28, 'Giza Frozen Meat', 'Rana Ezz', '01010000028', 'supplier28@example.com', 'Sohag, Egypt - Industrial Zone 28', 'TAX-10028', 15, 1, '2026-05-08 12:00:00', 1, 1),
(29, 'Cairo Coffee Roasters', 'Esraa Saber', '01010000029', 'supplier29@example.com', 'Qena, Egypt - Industrial Zone 29', 'TAX-10029', 30, 1, '2026-05-08 12:00:00', 1, 1),
(30, 'Delta Home Care', 'Malak Nabil', '01010000030', 'supplier30@example.com', 'Luxor, Egypt - Industrial Zone 30', 'TAX-10030', 45, 0, '2026-05-08 12:00:00', 1, 1);

INSERT INTO branch (id, name, address, phone, manager_id, is_active, created_at, created_by, updated_by) VALUES
(1, 'Cairo Nasr City', 'Cairo Nasr City, Egypt', '022000001', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(2, 'Cairo Maadi', 'Cairo Maadi, Egypt', '022000002', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(3, 'Giza Dokki', 'Giza Dokki, Egypt', '022000003', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(4, 'Giza 6 October', 'Giza 6 October, Egypt', '022000004', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(5, 'Alex Smouha', 'Alex Smouha, Egypt', '022000005', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(6, 'Alex Miami', 'Alex Miami, Egypt', '022000006', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(7, 'Ismailia Downtown', 'Ismailia Downtown, Egypt', '022000007', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(8, 'Suez City', 'Suez City, Egypt', '022000008', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(9, 'Port Said Center', 'Port Said Center, Egypt', '022000009', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(10, 'Mansoura Main', 'Mansoura Main, Egypt', '022000010', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(11, 'Tanta Main', 'Tanta Main, Egypt', '022000011', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(12, 'Zagazig Main', 'Zagazig Main, Egypt', '022000012', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(13, 'Fayoum Main', 'Fayoum Main, Egypt', '022000013', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(14, 'Minya Main', 'Minya Main, Egypt', '022000014', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(15, 'Assiut Main', 'Assiut Main, Egypt', '022000015', NULL, 0, '2026-05-08 12:00:00', 1, 1),
(16, 'Sohag Main', 'Sohag Main, Egypt', '022000016', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(17, 'Qena Main', 'Qena Main, Egypt', '022000017', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(18, 'Luxor Main', 'Luxor Main, Egypt', '022000018', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(19, 'Hurghada Main', 'Hurghada Main, Egypt', '022000019', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(20, 'Sharm El Sheikh', 'Sharm El Sheikh, Egypt', '022000020', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(21, 'New Cairo', 'New Cairo, Egypt', '022000021', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(22, 'Obour City', 'Obour City, Egypt', '022000022', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(23, 'Badr City', 'Badr City, Egypt', '022000023', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(24, '10th Ramadan', '10th Ramadan, Egypt', '022000024', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(25, 'Damietta Main', 'Damietta Main, Egypt', '022000025', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(26, 'Damanhur Main', 'Damanhur Main, Egypt', '022000026', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(27, 'Banha Main', 'Banha Main, Egypt', '022000027', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(28, 'Kafr El Sheikh', 'Kafr El Sheikh, Egypt', '022000028', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(29, 'Arish Main', 'Arish Main, Egypt', '022000029', NULL, 1, '2026-05-08 12:00:00', 1, 1),
(30, 'Ismailia Ring Road', 'Ismailia Ring Road, Egypt', '022000030', NULL, 1, '2026-05-08 12:00:00', 1, 1);

INSERT INTO register (id, branch_id, register_code, is_active, created_at, created_by, updated_by) VALUES
(1, 1, 'REG-001', 1, '2026-05-08 12:00:00', 1, 1),
(2, 2, 'REG-002', 1, '2026-05-08 12:00:00', 1, 1),
(3, 3, 'REG-003', 1, '2026-05-08 12:00:00', 1, 1),
(4, 4, 'REG-004', 1, '2026-05-08 12:00:00', 1, 1),
(5, 5, 'REG-005', 1, '2026-05-08 12:00:00', 1, 1),
(6, 6, 'REG-006', 1, '2026-05-08 12:00:00', 1, 1),
(7, 7, 'REG-007', 1, '2026-05-08 12:00:00', 1, 1),
(8, 8, 'REG-008', 1, '2026-05-08 12:00:00', 1, 1),
(9, 9, 'REG-009', 1, '2026-05-08 12:00:00', 1, 1),
(10, 10, 'REG-010', 1, '2026-05-08 12:00:00', 1, 1),
(11, 11, 'REG-011', 1, '2026-05-08 12:00:00', 1, 1),
(12, 12, 'REG-012', 1, '2026-05-08 12:00:00', 1, 1),
(13, 13, 'REG-013', 1, '2026-05-08 12:00:00', 1, 1),
(14, 14, 'REG-014', 1, '2026-05-08 12:00:00', 1, 1),
(15, 15, 'REG-015', 1, '2026-05-08 12:00:00', 1, 1),
(16, 16, 'REG-016', 1, '2026-05-08 12:00:00', 1, 1),
(17, 17, 'REG-017', 1, '2026-05-08 12:00:00', 1, 1),
(18, 18, 'REG-018', 1, '2026-05-08 12:00:00', 1, 1),
(19, 19, 'REG-019', 1, '2026-05-08 12:00:00', 1, 1),
(20, 20, 'REG-020', 1, '2026-05-08 12:00:00', 1, 1),
(21, 21, 'REG-021', 1, '2026-05-08 12:00:00', 1, 1),
(22, 22, 'REG-022', 1, '2026-05-08 12:00:00', 1, 1),
(23, 23, 'REG-023', 1, '2026-05-08 12:00:00', 1, 1),
(24, 24, 'REG-024', 1, '2026-05-08 12:00:00', 1, 1),
(25, 25, 'REG-025', 1, '2026-05-08 12:00:00', 1, 1),
(26, 26, 'REG-026', 1, '2026-05-08 12:00:00', 1, 1),
(27, 27, 'REG-027', 1, '2026-05-08 12:00:00', 1, 1),
(28, 28, 'REG-028', 1, '2026-05-08 12:00:00', 1, 1),
(29, 29, 'REG-029', 1, '2026-05-08 12:00:00', 1, 1),
(30, 30, 'REG-030', 1, '2026-05-08 12:00:00', 1, 1);

INSERT INTO department (id, branch_id, dep_name, manager_id, created_at, created_by, updated_by) VALUES
(1, 1, 'Management', NULL, '2026-05-08 12:00:00', 1, 1),
(2, 2, 'Sales', NULL, '2026-05-08 12:00:00', 1, 1),
(3, 3, 'Cashier', NULL, '2026-05-08 12:00:00', 1, 1),
(4, 4, 'Inventory', NULL, '2026-05-08 12:00:00', 1, 1),
(5, 5, 'Purchasing', NULL, '2026-05-08 12:00:00', 1, 1),
(6, 6, 'Finance', NULL, '2026-05-08 12:00:00', 1, 1),
(7, 7, 'HR', NULL, '2026-05-08 12:00:00', 1, 1),
(8, 8, 'Marketing', NULL, '2026-05-08 12:00:00', 1, 1),
(9, 9, 'IT', NULL, '2026-05-08 12:00:00', 1, 1),
(10, 10, 'Security', NULL, '2026-05-08 12:00:00', 1, 1),
(11, 11, 'Customer Service', NULL, '2026-05-08 12:00:00', 1, 1),
(12, 12, 'Warehouse', NULL, '2026-05-08 12:00:00', 1, 1),
(13, 13, 'Operations', NULL, '2026-05-08 12:00:00', 1, 1),
(14, 14, 'Quality', NULL, '2026-05-08 12:00:00', 1, 1),
(15, 15, 'Delivery', NULL, '2026-05-08 12:00:00', 1, 1),
(16, 16, 'Management', NULL, '2026-05-08 12:00:00', 1, 1),
(17, 17, 'Sales', NULL, '2026-05-08 12:00:00', 1, 1),
(18, 18, 'Cashier', NULL, '2026-05-08 12:00:00', 1, 1),
(19, 19, 'Inventory', NULL, '2026-05-08 12:00:00', 1, 1),
(20, 20, 'Purchasing', NULL, '2026-05-08 12:00:00', 1, 1),
(21, 21, 'Finance', NULL, '2026-05-08 12:00:00', 1, 1),
(22, 22, 'HR', NULL, '2026-05-08 12:00:00', 1, 1),
(23, 23, 'Marketing', NULL, '2026-05-08 12:00:00', 1, 1),
(24, 24, 'IT', NULL, '2026-05-08 12:00:00', 1, 1),
(25, 25, 'Security', NULL, '2026-05-08 12:00:00', 1, 1),
(26, 26, 'Customer Service', NULL, '2026-05-08 12:00:00', 1, 1),
(27, 27, 'Warehouse', NULL, '2026-05-08 12:00:00', 1, 1),
(28, 28, 'Operations', NULL, '2026-05-08 12:00:00', 1, 1),
(29, 29, 'Quality', NULL, '2026-05-08 12:00:00', 1, 1),
(30, 30, 'Delivery', NULL, '2026-05-08 12:00:00', 1, 1);

INSERT INTO employee (id, first_n, last_n, national_ID, email, dep_id, role_id, salary, hire_date, is_active, created_at, created_by, updated_by) VALUES
(1, 'Youssef', 'Mahmoud', '30000000000001', 'employee1@retail.local', 1, 1, 6850, '2021-01-02', 1, '2026-05-08 12:00:00', 1, 1),
(2, 'Ahmed', 'Hassan', '30000000000002', 'employee2@retail.local', 2, 2, 7200, '2022-02-04', 1, '2026-05-08 12:00:00', 1, 1),
(3, 'Mohamed', 'Ali', '30000000000003', 'employee3@retail.local', 3, 3, 7550, '2023-03-06', 1, '2026-05-08 12:00:00', 1, 1),
(4, 'Mahmoud', 'Ibrahim', '30000000000004', 'employee4@retail.local', 4, 4, 7900, '2024-04-08', 1, '2026-05-08 12:00:00', 1, 1),
(5, 'Omar', 'Mostafa', '30000000000005', 'employee5@retail.local', 5, 5, 8250, '2020-05-10', 1, '2026-05-08 12:00:00', 1, 1),
(6, 'Khaled', 'Sayed', '30000000000006', 'employee6@retail.local', 6, 6, 8600, '2021-06-12', 1, '2026-05-08 12:00:00', 1, 1),
(7, 'Mostafa', 'Adel', '30000000000007', 'employee7@retail.local', 7, 7, 8950, '2022-07-14', 1, '2026-05-08 12:00:00', 1, 1),
(8, 'Hassan', 'Fathy', '30000000000008', 'employee8@retail.local', 8, 8, 9300, '2023-08-16', 1, '2026-05-08 12:00:00', 1, 1),
(9, 'Ali', 'Nasser', '30000000000009', 'employee9@retail.local', 9, 9, 9650, '2024-09-18', 1, '2026-05-08 12:00:00', 1, 1),
(10, 'Ibrahim', 'Saleh', '30000000000010', 'employee10@retail.local', 10, 10, 10000, '2020-10-20', 1, '2026-05-08 12:00:00', 1, 1),
(11, 'Mazen', 'Samir', '30000000000011', 'employee11@retail.local', 11, 11, 10350, '2021-11-22', 1, '2026-05-08 12:00:00', 1, 1),
(12, 'Karim', 'Kamal', '30000000000012', 'employee12@retail.local', 12, 12, 10700, '2022-12-24', 0, '2026-05-08 12:00:00', 1, 1),
(13, 'Tarek', 'Farouk', '30000000000013', 'employee13@retail.local', 13, 13, 11050, '2023-01-26', 1, '2026-05-08 12:00:00', 1, 1),
(14, 'Hany', 'Gaber', '30000000000014', 'employee14@retail.local', 14, 14, 11400, '2024-02-28', 1, '2026-05-08 12:00:00', 1, 1),
(15, 'Samir', 'Younis', '30000000000015', 'employee15@retail.local', 15, 15, 11750, '2020-03-02', 1, '2026-05-08 12:00:00', 1, 1),
(16, 'Mariam', 'Ashraf', '30000000000016', 'employee16@retail.local', 16, 16, 12100, '2021-04-04', 1, '2026-05-08 12:00:00', 1, 1),
(17, 'Nour', 'Taha', '30000000000017', 'employee17@retail.local', 17, 17, 12450, '2022-05-06', 1, '2026-05-08 12:00:00', 1, 1),
(18, 'Menna', 'Amin', '30000000000018', 'employee18@retail.local', 18, 18, 12800, '2023-06-08', 1, '2026-05-08 12:00:00', 1, 1),
(19, 'Salma', 'Hamdy', '30000000000019', 'employee19@retail.local', 19, 19, 13150, '2024-07-10', 1, '2026-05-08 12:00:00', 1, 1),
(20, 'Sara', 'Mansour', '30000000000020', 'employee20@retail.local', 20, 20, 13500, '2020-08-12', 1, '2026-05-08 12:00:00', 1, 1),
(21, 'Nada', 'Lotfy', '30000000000021', 'employee21@retail.local', 21, 21, 13850, '2021-09-14', 1, '2026-05-08 12:00:00', 1, 1),
(22, 'Heba', 'Fouad', '30000000000022', 'employee22@retail.local', 22, 22, 14200, '2022-10-16', 1, '2026-05-08 12:00:00', 1, 1),
(23, 'Aya', 'Shahin', '30000000000023', 'employee23@retail.local', 23, 23, 14550, '2023-11-18', 1, '2026-05-08 12:00:00', 1, 1),
(24, 'Reem', 'Osman', '30000000000024', 'employee24@retail.local', 24, 24, 14900, '2024-12-20', 0, '2026-05-08 12:00:00', 1, 1),
(25, 'Farah', 'Zaki', '30000000000025', 'employee25@retail.local', 25, 25, 15250, '2020-01-22', 1, '2026-05-08 12:00:00', 1, 1),
(26, 'Dina', 'Riad', '30000000000026', 'employee26@retail.local', 26, 26, 15600, '2021-02-24', 1, '2026-05-08 12:00:00', 1, 1),
(27, 'Jana', 'Khalil', '30000000000027', 'employee27@retail.local', 27, 27, 15950, '2022-03-26', 1, '2026-05-08 12:00:00', 1, 1),
(28, 'Rana', 'Ezz', '30000000000028', 'employee28@retail.local', 28, 28, 16300, '2023-04-28', 1, '2026-05-08 12:00:00', 1, 1),
(29, 'Esraa', 'Saber', '30000000000029', 'employee29@retail.local', 29, 29, 16650, '2024-05-02', 1, '2026-05-08 12:00:00', 1, 1),
(30, 'Malak', 'Nabil', '30000000000030', 'employee30@retail.local', 30, 30, 17000, '2020-06-04', 1, '2026-05-08 12:00:00', 1, 1);

UPDATE branch SET manager_id = 1 WHERE id = 1;
UPDATE branch SET manager_id = 2 WHERE id = 2;
UPDATE branch SET manager_id = 3 WHERE id = 3;
UPDATE branch SET manager_id = 4 WHERE id = 4;
UPDATE branch SET manager_id = 5 WHERE id = 5;
UPDATE branch SET manager_id = 6 WHERE id = 6;
UPDATE branch SET manager_id = 7 WHERE id = 7;
UPDATE branch SET manager_id = 8 WHERE id = 8;
UPDATE branch SET manager_id = 9 WHERE id = 9;
UPDATE branch SET manager_id = 10 WHERE id = 10;
UPDATE branch SET manager_id = 11 WHERE id = 11;
UPDATE branch SET manager_id = 12 WHERE id = 12;
UPDATE branch SET manager_id = 13 WHERE id = 13;
UPDATE branch SET manager_id = 14 WHERE id = 14;
UPDATE branch SET manager_id = 15 WHERE id = 15;
UPDATE branch SET manager_id = 16 WHERE id = 16;
UPDATE branch SET manager_id = 17 WHERE id = 17;
UPDATE branch SET manager_id = 18 WHERE id = 18;
UPDATE branch SET manager_id = 19 WHERE id = 19;
UPDATE branch SET manager_id = 20 WHERE id = 20;
UPDATE branch SET manager_id = 21 WHERE id = 21;
UPDATE branch SET manager_id = 22 WHERE id = 22;
UPDATE branch SET manager_id = 23 WHERE id = 23;
UPDATE branch SET manager_id = 24 WHERE id = 24;
UPDATE branch SET manager_id = 25 WHERE id = 25;
UPDATE branch SET manager_id = 26 WHERE id = 26;
UPDATE branch SET manager_id = 27 WHERE id = 27;
UPDATE branch SET manager_id = 28 WHERE id = 28;
UPDATE branch SET manager_id = 29 WHERE id = 29;
UPDATE branch SET manager_id = 30 WHERE id = 30;

UPDATE department SET manager_id = 1 WHERE id = 1;
UPDATE department SET manager_id = 2 WHERE id = 2;
UPDATE department SET manager_id = 3 WHERE id = 3;
UPDATE department SET manager_id = 4 WHERE id = 4;
UPDATE department SET manager_id = 5 WHERE id = 5;
UPDATE department SET manager_id = 6 WHERE id = 6;
UPDATE department SET manager_id = 7 WHERE id = 7;
UPDATE department SET manager_id = 8 WHERE id = 8;
UPDATE department SET manager_id = 9 WHERE id = 9;
UPDATE department SET manager_id = 10 WHERE id = 10;
UPDATE department SET manager_id = 11 WHERE id = 11;
UPDATE department SET manager_id = 12 WHERE id = 12;
UPDATE department SET manager_id = 13 WHERE id = 13;
UPDATE department SET manager_id = 14 WHERE id = 14;
UPDATE department SET manager_id = 15 WHERE id = 15;
UPDATE department SET manager_id = 16 WHERE id = 16;
UPDATE department SET manager_id = 17 WHERE id = 17;
UPDATE department SET manager_id = 18 WHERE id = 18;
UPDATE department SET manager_id = 19 WHERE id = 19;
UPDATE department SET manager_id = 20 WHERE id = 20;
UPDATE department SET manager_id = 21 WHERE id = 21;
UPDATE department SET manager_id = 22 WHERE id = 22;
UPDATE department SET manager_id = 23 WHERE id = 23;
UPDATE department SET manager_id = 24 WHERE id = 24;
UPDATE department SET manager_id = 25 WHERE id = 25;
UPDATE department SET manager_id = 26 WHERE id = 26;
UPDATE department SET manager_id = 27 WHERE id = 27;
UPDATE department SET manager_id = 28 WHERE id = 28;
UPDATE department SET manager_id = 29 WHERE id = 29;
UPDATE department SET manager_id = 30 WHERE id = 30;

INSERT INTO role_permission (id, role_id, module, action, descr, created_at, created_by, updated_by) VALUES
(1, 1, 'users', 'create', 'Can create users', '2026-05-08 12:00:00', 1, 1),
(2, 2, 'sales', 'read', 'Can read sales', '2026-05-08 12:00:00', 1, 1),
(3, 3, 'products', 'update', 'Can update products', '2026-05-08 12:00:00', 1, 1),
(4, 4, 'inventory', 'delete', 'Can delete inventory', '2026-05-08 12:00:00', 1, 1),
(5, 5, 'purchases', 'approve', 'Can approve purchases', '2026-05-08 12:00:00', 1, 1),
(6, 6, 'reports', 'create', 'Can create reports', '2026-05-08 12:00:00', 1, 1),
(7, 7, 'customers', 'read', 'Can read customers', '2026-05-08 12:00:00', 1, 1),
(8, 8, 'discounts', 'update', 'Can update discounts', '2026-05-08 12:00:00', 1, 1),
(9, 9, 'returns', 'delete', 'Can delete returns', '2026-05-08 12:00:00', 1, 1),
(10, 10, 'settings', 'approve', 'Can approve settings', '2026-05-08 12:00:00', 1, 1),
(11, 11, 'users', 'create', 'Can create users', '2026-05-08 12:00:00', 1, 1),
(12, 12, 'sales', 'read', 'Can read sales', '2026-05-08 12:00:00', 1, 1),
(13, 13, 'products', 'update', 'Can update products', '2026-05-08 12:00:00', 1, 1),
(14, 14, 'inventory', 'delete', 'Can delete inventory', '2026-05-08 12:00:00', 1, 1),
(15, 15, 'purchases', 'approve', 'Can approve purchases', '2026-05-08 12:00:00', 1, 1),
(16, 16, 'reports', 'create', 'Can create reports', '2026-05-08 12:00:00', 1, 1),
(17, 17, 'customers', 'read', 'Can read customers', '2026-05-08 12:00:00', 1, 1),
(18, 18, 'discounts', 'update', 'Can update discounts', '2026-05-08 12:00:00', 1, 1),
(19, 19, 'returns', 'delete', 'Can delete returns', '2026-05-08 12:00:00', 1, 1),
(20, 20, 'settings', 'approve', 'Can approve settings', '2026-05-08 12:00:00', 1, 1),
(21, 21, 'users', 'create', 'Can create users', '2026-05-08 12:00:00', 1, 1),
(22, 22, 'sales', 'read', 'Can read sales', '2026-05-08 12:00:00', 1, 1),
(23, 23, 'products', 'update', 'Can update products', '2026-05-08 12:00:00', 1, 1),
(24, 24, 'inventory', 'delete', 'Can delete inventory', '2026-05-08 12:00:00', 1, 1),
(25, 25, 'purchases', 'approve', 'Can approve purchases', '2026-05-08 12:00:00', 1, 1),
(26, 26, 'reports', 'create', 'Can create reports', '2026-05-08 12:00:00', 1, 1),
(27, 27, 'customers', 'read', 'Can read customers', '2026-05-08 12:00:00', 1, 1),
(28, 28, 'discounts', 'update', 'Can update discounts', '2026-05-08 12:00:00', 1, 1),
(29, 29, 'returns', 'delete', 'Can delete returns', '2026-05-08 12:00:00', 1, 1),
(30, 30, 'settings', 'approve', 'Can approve settings', '2026-05-08 12:00:00', 1, 1);

INSERT INTO category (id, parent_id, cat_name, is_active, created_at, created_by, updated_by) VALUES
(1, NULL, 'Food', 1, '2026-05-08 12:00:00', 1, 1),
(2, NULL, 'Beverages', 1, '2026-05-08 12:00:00', 1, 1),
(3, NULL, 'Dairy', 1, '2026-05-08 12:00:00', 1, 1),
(4, NULL, 'Bakery', 1, '2026-05-08 12:00:00', 1, 1),
(5, NULL, 'Frozen', 1, '2026-05-08 12:00:00', 1, 1),
(6, NULL, 'Cleaning', 1, '2026-05-08 12:00:00', 1, 1),
(7, NULL, 'Personal Care', 1, '2026-05-08 12:00:00', 1, 1),
(8, NULL, 'Electronics', 1, '2026-05-08 12:00:00', 1, 1),
(9, NULL, 'Household', 1, '2026-05-08 12:00:00', 1, 1),
(10, NULL, 'Snacks', 1, '2026-05-08 12:00:00', 1, 1),
(11, 1, 'Rice and Pasta', 1, '2026-05-08 12:00:00', 1, 1),
(12, 2, 'Oil and Ghee', 1, '2026-05-08 12:00:00', 1, 1),
(13, 3, 'Canned Food', 1, '2026-05-08 12:00:00', 1, 1),
(14, 4, 'Spices', 1, '2026-05-08 12:00:00', 1, 1),
(15, 5, 'Sweets', 1, '2026-05-08 12:00:00', 1, 1),
(16, 6, 'Tea and Coffee', 1, '2026-05-08 12:00:00', 1, 1),
(17, 7, 'Water', 1, '2026-05-08 12:00:00', 1, 1),
(18, 8, 'Juice', 1, '2026-05-08 12:00:00', 1, 1),
(19, 9, 'Meat', 1, '2026-05-08 12:00:00', 1, 1),
(20, 10, 'Chicken', 1, '2026-05-08 12:00:00', 1, 1),
(21, 1, 'Fish', 1, '2026-05-08 12:00:00', 1, 1),
(22, 2, 'Vegetables', 1, '2026-05-08 12:00:00', 1, 1),
(23, 3, 'Fruits', 1, '2026-05-08 12:00:00', 1, 1),
(24, 4, 'Paper Products', 1, '2026-05-08 12:00:00', 1, 1),
(25, 5, 'Baby Care', 1, '2026-05-08 12:00:00', 1, 1),
(26, 6, 'Pet Food', 1, '2026-05-08 12:00:00', 1, 1),
(27, 7, 'Stationery', 1, '2026-05-08 12:00:00', 1, 1),
(28, 8, 'Kitchen Tools', 1, '2026-05-08 12:00:00', 1, 1),
(29, 9, 'Health Care', 1, '2026-05-08 12:00:00', 1, 1),
(30, 10, 'Offers', 1, '2026-05-08 12:00:00', 1, 1);

INSERT INTO product (id, product_name, category_id, supplier_id, barcode, cost_price, sell_price, stock_qty, reorder_level, is_active, created_at, created_by, updated_by) VALUES
(1, 'Egyptian Rice 1kg', 1, 1, '6223000000001', 12.25, 18.31, 107, 11, 1, '2026-05-08 12:00:00', 1, 1),
(2, 'Sugar 1kg', 2, 2, '6223000000002', 14.5, 21.12, 114, 12, 1, '2026-05-08 12:00:00', 1, 1),
(3, 'Sunflower Oil 1L', 3, 3, '6223000000003', 16.75, 23.94, 121, 13, 1, '2026-05-08 12:00:00', 1, 1),
(4, 'Pasta 400g', 4, 4, '6223000000004', 19.0, 26.75, 128, 14, 1, '2026-05-08 12:00:00', 1, 1),
(5, 'Tomato Paste', 5, 5, '6223000000005', 21.25, 29.56, 135, 15, 1, '2026-05-08 12:00:00', 1, 1),
(6, 'Mineral Water 1.5L', 6, 6, '6223000000006', 23.5, 32.38, 142, 10, 1, '2026-05-08 12:00:00', 1, 1),
(7, 'Milk 1L', 7, 7, '6223000000007', 25.75, 35.19, 149, 11, 1, '2026-05-08 12:00:00', 1, 1),
(8, 'Yogurt Cup', 8, 8, '6223000000008', 28.0, 38.0, 156, 12, 1, '2026-05-08 12:00:00', 1, 1),
(9, 'White Cheese', 9, 9, '6223000000009', 30.25, 40.81, 163, 13, 1, '2026-05-08 12:00:00', 1, 1),
(10, 'Tea Box', 10, 10, '6223000000010', 32.5, 43.62, 170, 14, 1, '2026-05-08 12:00:00', 1, 1),
(11, 'Coffee 200g', 11, 11, '6223000000011', 34.75, 46.44, 177, 15, 1, '2026-05-08 12:00:00', 1, 1),
(12, 'Orange Juice 1L', 12, 12, '6223000000012', 37.0, 49.25, 184, 10, 1, '2026-05-08 12:00:00', 1, 1),
(13, 'Cola Bottle', 13, 13, '6223000000013', 39.25, 52.06, 191, 11, 1, '2026-05-08 12:00:00', 1, 1),
(14, 'Biscuits Pack', 14, 14, '6223000000014', 41.5, 54.88, 198, 12, 1, '2026-05-08 12:00:00', 1, 1),
(15, 'Chips Pack', 15, 15, '6223000000015', 43.75, 57.69, 205, 13, 1, '2026-05-08 12:00:00', 1, 1),
(16, 'Frozen Peas', 16, 16, '6223000000016', 46.0, 60.5, 212, 14, 1, '2026-05-08 12:00:00', 1, 1),
(17, 'Frozen Chicken', 17, 17, '6223000000017', 48.25, 63.31, 219, 15, 1, '2026-05-08 12:00:00', 1, 1),
(18, 'Beef Mince', 18, 18, '6223000000018', 50.5, 66.12, 226, 10, 1, '2026-05-08 12:00:00', 1, 1),
(19, 'Tuna Can', 19, 19, '6223000000019', 52.75, 68.94, 233, 11, 1, '2026-05-08 12:00:00', 1, 1),
(20, 'Beans Can', 20, 20, '6223000000020', 55.0, 71.75, 240, 12, 1, '2026-05-08 12:00:00', 1, 1),
(21, 'Dish Soap', 21, 21, '6223000000021', 57.25, 74.56, 247, 13, 1, '2026-05-08 12:00:00', 1, 1),
(22, 'Laundry Powder', 22, 22, '6223000000022', 59.5, 77.38, 254, 14, 1, '2026-05-08 12:00:00', 1, 1),
(23, 'Shampoo', 23, 23, '6223000000023', 61.75, 80.19, 261, 15, 1, '2026-05-08 12:00:00', 1, 1),
(24, 'Toothpaste', 24, 24, '6223000000024', 64.0, 83.0, 268, 10, 1, '2026-05-08 12:00:00', 1, 1),
(25, 'Tissues Box', 25, 25, '6223000000025', 66.25, 85.81, 275, 11, 1, '2026-05-08 12:00:00', 1, 1),
(26, 'Baby Diapers', 26, 26, '6223000000026', 68.5, 88.62, 282, 12, 1, '2026-05-08 12:00:00', 1, 1),
(27, 'Notebook', 27, 27, '6223000000027', 70.75, 91.44, 289, 13, 1, '2026-05-08 12:00:00', 1, 1),
(28, 'Plastic Cups', 28, 28, '6223000000028', 73.0, 94.25, 296, 14, 1, '2026-05-08 12:00:00', 1, 1),
(29, 'Honey Jar', 29, 29, '6223000000029', 75.25, 97.06, 303, 15, 1, '2026-05-08 12:00:00', 1, 1),
(30, 'Dates Pack', 30, 30, '6223000000030', 77.5, 99.88, 310, 10, 1, '2026-05-08 12:00:00', 1, 1);

INSERT INTO inventory_movement (id, product_id, movement_type, qty, movement_date, reason, created_at) VALUES
(1, 1, 'opening_stock', 51, '2026-05-01 09:00:00', 'opening_stock movement', '2026-05-08 12:00:00'),
(2, 2, 'purchase', 52, '2026-05-02 09:00:00', 'purchase movement', '2026-05-08 12:00:00'),
(3, 3, 'sale', -4, '2026-05-03 09:00:00', 'sale movement', '2026-05-08 12:00:00'),
(4, 4, 'return', 54, '2026-05-04 09:00:00', 'return movement', '2026-05-08 12:00:00'),
(5, 5, 'adjustment_in', 55, '2026-05-05 09:00:00', 'adjustment_in movement', '2026-05-08 12:00:00'),
(6, 6, 'adjustment_out', -7, '2026-05-06 09:00:00', 'adjustment_out movement', '2026-05-08 12:00:00'),
(7, 7, 'opening_stock', 57, '2026-05-07 09:00:00', 'opening_stock movement', '2026-05-08 12:00:00'),
(8, 8, 'purchase', 58, '2026-05-08 09:00:00', 'purchase movement', '2026-05-08 12:00:00'),
(9, 9, 'sale', -10, '2026-05-09 09:00:00', 'sale movement', '2026-05-08 12:00:00'),
(10, 10, 'return', 60, '2026-05-10 09:00:00', 'return movement', '2026-05-08 12:00:00'),
(11, 11, 'adjustment_in', 61, '2026-05-11 09:00:00', 'adjustment_in movement', '2026-05-08 12:00:00'),
(12, 12, 'adjustment_out', -3, '2026-05-12 09:00:00', 'adjustment_out movement', '2026-05-08 12:00:00'),
(13, 13, 'opening_stock', 63, '2026-05-13 09:00:00', 'opening_stock movement', '2026-05-08 12:00:00'),
(14, 14, 'purchase', 64, '2026-05-14 09:00:00', 'purchase movement', '2026-05-08 12:00:00'),
(15, 15, 'sale', -6, '2026-05-15 09:00:00', 'sale movement', '2026-05-08 12:00:00'),
(16, 16, 'return', 66, '2026-05-16 09:00:00', 'return movement', '2026-05-08 12:00:00'),
(17, 17, 'adjustment_in', 67, '2026-05-17 09:00:00', 'adjustment_in movement', '2026-05-08 12:00:00'),
(18, 18, 'adjustment_out', -9, '2026-05-18 09:00:00', 'adjustment_out movement', '2026-05-08 12:00:00'),
(19, 19, 'opening_stock', 69, '2026-05-19 09:00:00', 'opening_stock movement', '2026-05-08 12:00:00'),
(20, 20, 'purchase', 70, '2026-05-20 09:00:00', 'purchase movement', '2026-05-08 12:00:00'),
(21, 21, 'sale', -2, '2026-05-21 09:00:00', 'sale movement', '2026-05-08 12:00:00'),
(22, 22, 'return', 72, '2026-05-22 09:00:00', 'return movement', '2026-05-08 12:00:00'),
(23, 23, 'adjustment_in', 73, '2026-05-23 09:00:00', 'adjustment_in movement', '2026-05-08 12:00:00'),
(24, 24, 'adjustment_out', -5, '2026-05-24 09:00:00', 'adjustment_out movement', '2026-05-08 12:00:00'),
(25, 25, 'opening_stock', 75, '2026-05-25 09:00:00', 'opening_stock movement', '2026-05-08 12:00:00'),
(26, 26, 'purchase', 76, '2026-05-26 09:00:00', 'purchase movement', '2026-05-08 12:00:00'),
(27, 27, 'sale', -8, '2026-05-27 09:00:00', 'sale movement', '2026-05-08 12:00:00'),
(28, 28, 'return', 78, '2026-05-28 09:00:00', 'return movement', '2026-05-08 12:00:00'),
(29, 29, 'adjustment_in', 79, '2026-05-01 09:00:00', 'adjustment_in movement', '2026-05-08 12:00:00'),
(30, 30, 'adjustment_out', -1, '2026-05-02 09:00:00', 'adjustment_out movement', '2026-05-08 12:00:00');

INSERT INTO discount (id, disc_name, type_d, value_d, st_date, end_date, is_active, created_at, created_by, updated_by) VALUES
(1, 'Discount 1', 'percentage', 6, '2026-05-01', '2026-06-01', 1, '2026-05-08 12:00:00', 1, 1),
(2, 'Discount 2', 'fixed_amount', 12, '2026-05-02', '2026-06-02', 1, '2026-05-08 12:00:00', 1, 1),
(3, 'Discount 3', 'percentage', 8, '2026-05-03', '2026-06-03', 1, '2026-05-08 12:00:00', 1, 1),
(4, 'Discount 4', 'fixed_amount', 14, '2026-05-04', '2026-06-04', 1, '2026-05-08 12:00:00', 1, 1),
(5, 'Discount 5', 'percentage', 10, '2026-05-05', '2026-06-05', 1, '2026-05-08 12:00:00', 1, 1),
(6, 'Discount 6', 'fixed_amount', 16, '2026-05-06', '2026-06-06', 0, '2026-05-08 12:00:00', 1, 1),
(7, 'Discount 7', 'percentage', 12, '2026-05-07', '2026-06-07', 1, '2026-05-08 12:00:00', 1, 1),
(8, 'Discount 8', 'fixed_amount', 18, '2026-05-08', '2026-06-08', 1, '2026-05-08 12:00:00', 1, 1),
(9, 'Discount 9', 'percentage', 14, '2026-05-09', '2026-06-09', 1, '2026-05-08 12:00:00', 1, 1),
(10, 'Discount 10', 'fixed_amount', 20, '2026-05-10', '2026-06-10', 1, '2026-05-08 12:00:00', 1, 1),
(11, 'Discount 11', 'percentage', 6, '2026-05-11', '2026-06-11', 1, '2026-05-08 12:00:00', 1, 1),
(12, 'Discount 12', 'fixed_amount', 22, '2026-05-12', '2026-06-12', 0, '2026-05-08 12:00:00', 1, 1),
(13, 'Discount 13', 'percentage', 8, '2026-05-13', '2026-06-13', 1, '2026-05-08 12:00:00', 1, 1),
(14, 'Discount 14', 'fixed_amount', 24, '2026-05-14', '2026-06-14', 1, '2026-05-08 12:00:00', 1, 1),
(15, 'Discount 15', 'percentage', 10, '2026-05-15', '2026-06-15', 1, '2026-05-08 12:00:00', 1, 1),
(16, 'Discount 16', 'fixed_amount', 26, '2026-05-16', '2026-06-16', 1, '2026-05-08 12:00:00', 1, 1),
(17, 'Discount 17', 'percentage', 12, '2026-05-17', '2026-06-17', 1, '2026-05-08 12:00:00', 1, 1),
(18, 'Discount 18', 'fixed_amount', 28, '2026-05-18', '2026-06-18', 0, '2026-05-08 12:00:00', 1, 1),
(19, 'Discount 19', 'percentage', 14, '2026-05-19', '2026-06-19', 1, '2026-05-08 12:00:00', 1, 1),
(20, 'Discount 20', 'fixed_amount', 30, '2026-05-20', '2026-06-20', 1, '2026-05-08 12:00:00', 1, 1),
(21, 'Discount 21', 'percentage', 6, '2026-05-21', '2026-06-21', 1, '2026-05-08 12:00:00', 1, 1),
(22, 'Discount 22', 'fixed_amount', 32, '2026-05-22', '2026-06-22', 1, '2026-05-08 12:00:00', 1, 1),
(23, 'Discount 23', 'percentage', 8, '2026-05-23', '2026-06-23', 1, '2026-05-08 12:00:00', 1, 1),
(24, 'Discount 24', 'fixed_amount', 34, '2026-05-24', '2026-06-24', 0, '2026-05-08 12:00:00', 1, 1),
(25, 'Discount 25', 'percentage', 10, '2026-05-25', '2026-06-25', 1, '2026-05-08 12:00:00', 1, 1),
(26, 'Discount 26', 'fixed_amount', 36, '2026-05-26', '2026-06-26', 1, '2026-05-08 12:00:00', 1, 1),
(27, 'Discount 27', 'percentage', 12, '2026-05-27', '2026-06-27', 1, '2026-05-08 12:00:00', 1, 1),
(28, 'Discount 28', 'fixed_amount', 38, '2026-05-28', '2026-06-28', 1, '2026-05-08 12:00:00', 1, 1),
(29, 'Discount 29', 'percentage', 14, '2026-05-01', '2026-06-01', 1, '2026-05-08 12:00:00', 1, 1),
(30, 'Discount 30', 'fixed_amount', 40, '2026-05-02', '2026-06-02', 0, '2026-05-08 12:00:00', 1, 1);

INSERT INTO discount_product (id, discount_id, product_id, created_at, created_by, updated_by) VALUES
(1, 1, 1, '2026-05-08 12:00:00', 1, 1),
(2, 2, 2, '2026-05-08 12:00:00', 1, 1),
(3, 3, 3, '2026-05-08 12:00:00', 1, 1),
(4, 4, 4, '2026-05-08 12:00:00', 1, 1),
(5, 5, 5, '2026-05-08 12:00:00', 1, 1),
(6, 6, 6, '2026-05-08 12:00:00', 1, 1),
(7, 7, 7, '2026-05-08 12:00:00', 1, 1),
(8, 8, 8, '2026-05-08 12:00:00', 1, 1),
(9, 9, 9, '2026-05-08 12:00:00', 1, 1),
(10, 10, 10, '2026-05-08 12:00:00', 1, 1),
(11, 11, 11, '2026-05-08 12:00:00', 1, 1),
(12, 12, 12, '2026-05-08 12:00:00', 1, 1),
(13, 13, 13, '2026-05-08 12:00:00', 1, 1),
(14, 14, 14, '2026-05-08 12:00:00', 1, 1),
(15, 15, 15, '2026-05-08 12:00:00', 1, 1),
(16, 16, 16, '2026-05-08 12:00:00', 1, 1),
(17, 17, 17, '2026-05-08 12:00:00', 1, 1),
(18, 18, 18, '2026-05-08 12:00:00', 1, 1),
(19, 19, 19, '2026-05-08 12:00:00', 1, 1),
(20, 20, 20, '2026-05-08 12:00:00', 1, 1),
(21, 21, 21, '2026-05-08 12:00:00', 1, 1),
(22, 22, 22, '2026-05-08 12:00:00', 1, 1),
(23, 23, 23, '2026-05-08 12:00:00', 1, 1),
(24, 24, 24, '2026-05-08 12:00:00', 1, 1),
(25, 25, 25, '2026-05-08 12:00:00', 1, 1),
(26, 26, 26, '2026-05-08 12:00:00', 1, 1),
(27, 27, 27, '2026-05-08 12:00:00', 1, 1),
(28, 28, 28, '2026-05-08 12:00:00', 1, 1),
(29, 29, 29, '2026-05-08 12:00:00', 1, 1),
(30, 30, 30, '2026-05-08 12:00:00', 1, 1);

INSERT INTO customer (id, cus_name, phone, email, loyalty_points, is_active, registered_at, created_by, updated_by) VALUES
(1, 'Omar Adel', '01120000001', 'customer1@example.com', 20, 1, '2026-04-01 10:00:00', 1, 1),
(2, 'Khaled Fathy', '01120000002', 'customer2@example.com', 40, 1, '2026-04-02 10:00:00', 1, 1),
(3, 'Mostafa Nasser', '01120000003', 'customer3@example.com', 60, 1, '2026-04-03 10:00:00', 1, 1),
(4, 'Hassan Saleh', '01120000004', 'customer4@example.com', 80, 1, '2026-04-04 10:00:00', 1, 1),
(5, 'Ali Samir', '01120000005', 'customer5@example.com', 100, 1, '2026-04-05 10:00:00', 1, 1),
(6, 'Ibrahim Kamal', '01120000006', 'customer6@example.com', 120, 1, '2026-04-06 10:00:00', 1, 1),
(7, 'Mazen Farouk', '01120000007', 'customer7@example.com', 140, 1, '2026-04-07 10:00:00', 1, 1),
(8, 'Karim Gaber', '01120000008', 'customer8@example.com', 160, 1, '2026-04-08 10:00:00', 1, 1),
(9, 'Tarek Younis', '01120000009', 'customer9@example.com', 180, 1, '2026-04-09 10:00:00', 1, 1),
(10, 'Hany Ashraf', '01120000010', 'customer10@example.com', 200, 1, '2026-04-10 10:00:00', 1, 1),
(11, 'Samir Taha', '01120000011', 'customer11@example.com', 220, 1, '2026-04-11 10:00:00', 1, 1),
(12, 'Mariam Amin', '01120000012', 'customer12@example.com', 240, 1, '2026-04-12 10:00:00', 1, 1),
(13, 'Nour Hamdy', '01120000013', 'customer13@example.com', 260, 1, '2026-04-13 10:00:00', 1, 1),
(14, 'Menna Mansour', '01120000014', 'customer14@example.com', 280, 1, '2026-04-14 10:00:00', 1, 1),
(15, 'Salma Lotfy', '01120000015', 'customer15@example.com', 300, 1, '2026-04-15 10:00:00', 1, 1),
(16, 'Sara Fouad', '01120000016', 'customer16@example.com', 320, 1, '2026-04-16 10:00:00', 1, 1),
(17, 'Nada Shahin', '01120000017', 'customer17@example.com', 340, 1, '2026-04-17 10:00:00', 1, 1),
(18, 'Heba Osman', '01120000018', 'customer18@example.com', 360, 1, '2026-04-18 10:00:00', 1, 1),
(19, 'Aya Zaki', '01120000019', 'customer19@example.com', 380, 1, '2026-04-19 10:00:00', 1, 1),
(20, 'Reem Riad', '01120000020', 'customer20@example.com', 400, 1, '2026-04-20 10:00:00', 1, 1),
(21, 'Farah Khalil', '01120000021', 'customer21@example.com', 420, 1, '2026-04-21 10:00:00', 1, 1),
(22, 'Dina Ezz', '01120000022', 'customer22@example.com', 440, 1, '2026-04-22 10:00:00', 1, 1),
(23, 'Jana Saber', '01120000023', 'customer23@example.com', 460, 1, '2026-04-23 10:00:00', 1, 1),
(24, 'Rana Nabil', '01120000024', 'customer24@example.com', 480, 1, '2026-04-24 10:00:00', 1, 1),
(25, 'Esraa Mahmoud', '01120000025', 'customer25@example.com', 500, 1, '2026-04-25 10:00:00', 1, 1),
(26, 'Malak Hassan', '01120000026', 'customer26@example.com', 520, 1, '2026-04-26 10:00:00', 1, 1),
(27, 'Youssef Ali', '01120000027', 'customer27@example.com', 540, 1, '2026-04-27 10:00:00', 1, 1),
(28, 'Ahmed Ibrahim', '01120000028', 'customer28@example.com', 560, 1, '2026-04-28 10:00:00', 1, 1),
(29, 'Mohamed Mostafa', '01120000029', 'customer29@example.com', 580, 1, '2026-04-01 10:00:00', 1, 1),
(30, 'Mahmoud Sayed', '01120000030', 'customer30@example.com', 600, 1, '2026-04-02 10:00:00', 1, 1);

INSERT INTO loyalty_account (id, customer_id, card_number, points_balance, membership_level, created_at) VALUES
(1, 1, 'CARD-1001', 20, 'Basic', '2026-05-08 12:00:00'),
(2, 2, 'CARD-1002', 40, 'Silver', '2026-05-08 12:00:00'),
(3, 3, 'CARD-1003', 60, 'Gold', '2026-05-08 12:00:00'),
(4, 4, 'CARD-1004', 80, 'Platinum', '2026-05-08 12:00:00'),
(5, 5, 'CARD-1005', 100, 'Basic', '2026-05-08 12:00:00'),
(6, 6, 'CARD-1006', 120, 'Silver', '2026-05-08 12:00:00'),
(7, 7, 'CARD-1007', 140, 'Gold', '2026-05-08 12:00:00'),
(8, 8, 'CARD-1008', 160, 'Platinum', '2026-05-08 12:00:00'),
(9, 9, 'CARD-1009', 180, 'Basic', '2026-05-08 12:00:00'),
(10, 10, 'CARD-1010', 200, 'Silver', '2026-05-08 12:00:00'),
(11, 11, 'CARD-1011', 220, 'Gold', '2026-05-08 12:00:00'),
(12, 12, 'CARD-1012', 240, 'Platinum', '2026-05-08 12:00:00'),
(13, 13, 'CARD-1013', 260, 'Basic', '2026-05-08 12:00:00'),
(14, 14, 'CARD-1014', 280, 'Silver', '2026-05-08 12:00:00'),
(15, 15, 'CARD-1015', 300, 'Gold', '2026-05-08 12:00:00'),
(16, 16, 'CARD-1016', 320, 'Platinum', '2026-05-08 12:00:00'),
(17, 17, 'CARD-1017', 340, 'Basic', '2026-05-08 12:00:00'),
(18, 18, 'CARD-1018', 360, 'Silver', '2026-05-08 12:00:00'),
(19, 19, 'CARD-1019', 380, 'Gold', '2026-05-08 12:00:00'),
(20, 20, 'CARD-1020', 400, 'Platinum', '2026-05-08 12:00:00'),
(21, 21, 'CARD-1021', 420, 'Basic', '2026-05-08 12:00:00'),
(22, 22, 'CARD-1022', 440, 'Silver', '2026-05-08 12:00:00'),
(23, 23, 'CARD-1023', 460, 'Gold', '2026-05-08 12:00:00'),
(24, 24, 'CARD-1024', 480, 'Platinum', '2026-05-08 12:00:00'),
(25, 25, 'CARD-1025', 500, 'Basic', '2026-05-08 12:00:00'),
(26, 26, 'CARD-1026', 520, 'Silver', '2026-05-08 12:00:00'),
(27, 27, 'CARD-1027', 540, 'Gold', '2026-05-08 12:00:00'),
(28, 28, 'CARD-1028', 560, 'Platinum', '2026-05-08 12:00:00'),
(29, 29, 'CARD-1029', 580, 'Basic', '2026-05-08 12:00:00'),
(30, 30, 'CARD-1030', 600, 'Silver', '2026-05-08 12:00:00');

INSERT INTO purchase_order (id, supplier_id, employee_id, order_date, expected_date, total_amount, status_po, created_at) VALUES
(1, 1, 1, '2026-04-01', '2026-05-01', 257.25, 'pending', '2026-05-08 12:00:00'),
(2, 2, 2, '2026-04-02', '2026-05-02', 319.0, 'ordered', '2026-05-08 12:00:00'),
(3, 3, 3, '2026-04-03', '2026-05-03', 385.25, 'received', '2026-05-08 12:00:00'),
(4, 4, 4, '2026-04-04', '2026-05-04', 456.0, 'cancelled', '2026-05-08 12:00:00'),
(5, 5, 5, '2026-04-05', '2026-05-05', 531.25, 'pending', '2026-05-08 12:00:00'),
(6, 6, 6, '2026-04-06', '2026-05-06', 611.0, 'ordered', '2026-05-08 12:00:00'),
(7, 7, 7, '2026-04-07', '2026-05-07', 695.25, 'received', '2026-05-08 12:00:00'),
(8, 8, 8, '2026-04-08', '2026-05-08', 784.0, 'cancelled', '2026-05-08 12:00:00'),
(9, 9, 9, '2026-04-09', '2026-05-09', 877.25, 'pending', '2026-05-08 12:00:00'),
(10, 10, 10, '2026-04-10', '2026-05-10', 975.0, 'ordered', '2026-05-08 12:00:00'),
(11, 11, 11, '2026-04-11', '2026-05-11', 1077.25, 'received', '2026-05-08 12:00:00'),
(12, 12, 12, '2026-04-12', '2026-05-12', 1184.0, 'cancelled', '2026-05-08 12:00:00'),
(13, 13, 13, '2026-04-13', '2026-05-13', 1295.25, 'pending', '2026-05-08 12:00:00'),
(14, 14, 14, '2026-04-14', '2026-05-14', 1411.0, 'ordered', '2026-05-08 12:00:00'),
(15, 15, 15, '2026-04-15', '2026-05-15', 1531.25, 'received', '2026-05-08 12:00:00'),
(16, 16, 16, '2026-04-16', '2026-05-16', 1656.0, 'cancelled', '2026-05-08 12:00:00'),
(17, 17, 17, '2026-04-17', '2026-05-17', 1785.25, 'pending', '2026-05-08 12:00:00'),
(18, 18, 18, '2026-04-18', '2026-05-18', 1919.0, 'ordered', '2026-05-08 12:00:00'),
(19, 19, 19, '2026-04-19', '2026-05-19', 2057.25, 'received', '2026-05-08 12:00:00'),
(20, 20, 20, '2026-04-20', '2026-05-20', 2200.0, 'cancelled', '2026-05-08 12:00:00'),
(21, 21, 21, '2026-04-21', '2026-05-21', 2347.25, 'pending', '2026-05-08 12:00:00'),
(22, 22, 22, '2026-04-22', '2026-05-22', 2499.0, 'ordered', '2026-05-08 12:00:00'),
(23, 23, 23, '2026-04-23', '2026-05-23', 2655.25, 'received', '2026-05-08 12:00:00'),
(24, 24, 24, '2026-04-24', '2026-05-24', 2816.0, 'cancelled', '2026-05-08 12:00:00'),
(25, 25, 25, '2026-04-25', '2026-05-25', 2981.25, 'pending', '2026-05-08 12:00:00'),
(26, 26, 26, '2026-04-26', '2026-05-26', 3151.0, 'ordered', '2026-05-08 12:00:00'),
(27, 27, 27, '2026-04-27', '2026-05-27', 3325.25, 'received', '2026-05-08 12:00:00'),
(28, 28, 28, '2026-04-28', '2026-05-28', 3504.0, 'cancelled', '2026-05-08 12:00:00'),
(29, 29, 29, '2026-04-01', '2026-05-01', 3687.25, 'pending', '2026-05-08 12:00:00'),
(30, 30, 30, '2026-04-02', '2026-05-02', 3875.0, 'ordered', '2026-05-08 12:00:00');

INSERT INTO po_item (id, po_id, product_id, qty, cost_price, total_cost, created_at) VALUES
(1, 1, 1, 21, 12.25, 257.25, '2026-05-08 12:00:00'),
(2, 2, 2, 22, 14.5, 319.0, '2026-05-08 12:00:00'),
(3, 3, 3, 23, 16.75, 385.25, '2026-05-08 12:00:00'),
(4, 4, 4, 24, 19.0, 456.0, '2026-05-08 12:00:00'),
(5, 5, 5, 25, 21.25, 531.25, '2026-05-08 12:00:00'),
(6, 6, 6, 26, 23.5, 611.0, '2026-05-08 12:00:00'),
(7, 7, 7, 27, 25.75, 695.25, '2026-05-08 12:00:00'),
(8, 8, 8, 28, 28.0, 784.0, '2026-05-08 12:00:00'),
(9, 9, 9, 29, 30.25, 877.25, '2026-05-08 12:00:00'),
(10, 10, 10, 30, 32.5, 975.0, '2026-05-08 12:00:00'),
(11, 11, 11, 31, 34.75, 1077.25, '2026-05-08 12:00:00'),
(12, 12, 12, 32, 37.0, 1184.0, '2026-05-08 12:00:00'),
(13, 13, 13, 33, 39.25, 1295.25, '2026-05-08 12:00:00'),
(14, 14, 14, 34, 41.5, 1411.0, '2026-05-08 12:00:00'),
(15, 15, 15, 35, 43.75, 1531.25, '2026-05-08 12:00:00'),
(16, 16, 16, 36, 46.0, 1656.0, '2026-05-08 12:00:00'),
(17, 17, 17, 37, 48.25, 1785.25, '2026-05-08 12:00:00'),
(18, 18, 18, 38, 50.5, 1919.0, '2026-05-08 12:00:00'),
(19, 19, 19, 39, 52.75, 2057.25, '2026-05-08 12:00:00'),
(20, 20, 20, 40, 55.0, 2200.0, '2026-05-08 12:00:00'),
(21, 21, 21, 41, 57.25, 2347.25, '2026-05-08 12:00:00'),
(22, 22, 22, 42, 59.5, 2499.0, '2026-05-08 12:00:00'),
(23, 23, 23, 43, 61.75, 2655.25, '2026-05-08 12:00:00'),
(24, 24, 24, 44, 64.0, 2816.0, '2026-05-08 12:00:00'),
(25, 25, 25, 45, 66.25, 2981.25, '2026-05-08 12:00:00'),
(26, 26, 26, 46, 68.5, 3151.0, '2026-05-08 12:00:00'),
(27, 27, 27, 47, 70.75, 3325.25, '2026-05-08 12:00:00'),
(28, 28, 28, 48, 73.0, 3504.0, '2026-05-08 12:00:00'),
(29, 29, 29, 49, 75.25, 3687.25, '2026-05-08 12:00:00'),
(30, 30, 30, 50, 77.5, 3875.0, '2026-05-08 12:00:00');

INSERT INTO shift (id, register_id, employee_id, start_time, end_time, opening_balance, closing_balance, created_at) VALUES
(1, 1, 1, '2026-05-01 08:00:00', '2026-05-01 16:00:00', 510, 661, '2026-05-08 12:00:00'),
(2, 2, 2, '2026-05-02 08:00:00', '2026-05-02 16:00:00', 520, 672, '2026-05-08 12:00:00'),
(3, 3, 3, '2026-05-03 08:00:00', '2026-05-03 16:00:00', 530, 683, '2026-05-08 12:00:00'),
(4, 4, 4, '2026-05-04 08:00:00', '2026-05-04 16:00:00', 540, 694, '2026-05-08 12:00:00'),
(5, 5, 5, '2026-05-05 08:00:00', '2026-05-05 16:00:00', 550, 705, '2026-05-08 12:00:00'),
(6, 6, 6, '2026-05-06 08:00:00', '2026-05-06 16:00:00', 560, 716, '2026-05-08 12:00:00'),
(7, 7, 7, '2026-05-07 08:00:00', '2026-05-07 16:00:00', 570, 727, '2026-05-08 12:00:00'),
(8, 8, 8, '2026-05-08 08:00:00', '2026-05-08 16:00:00', 580, 738, '2026-05-08 12:00:00'),
(9, 9, 9, '2026-05-09 08:00:00', '2026-05-09 16:00:00', 590, 749, '2026-05-08 12:00:00'),
(10, 10, 10, '2026-05-10 08:00:00', '2026-05-10 16:00:00', 600, 760, '2026-05-08 12:00:00'),
(11, 11, 11, '2026-05-11 08:00:00', '2026-05-11 16:00:00', 610, 771, '2026-05-08 12:00:00'),
(12, 12, 12, '2026-05-12 08:00:00', '2026-05-12 16:00:00', 620, 782, '2026-05-08 12:00:00'),
(13, 13, 13, '2026-05-13 08:00:00', '2026-05-13 16:00:00', 630, 793, '2026-05-08 12:00:00'),
(14, 14, 14, '2026-05-14 08:00:00', '2026-05-14 16:00:00', 640, 804, '2026-05-08 12:00:00'),
(15, 15, 15, '2026-05-15 08:00:00', '2026-05-15 16:00:00', 650, 815, '2026-05-08 12:00:00'),
(16, 16, 16, '2026-05-16 08:00:00', '2026-05-16 16:00:00', 660, 826, '2026-05-08 12:00:00'),
(17, 17, 17, '2026-05-17 08:00:00', '2026-05-17 16:00:00', 670, 837, '2026-05-08 12:00:00'),
(18, 18, 18, '2026-05-18 08:00:00', '2026-05-18 16:00:00', 680, 848, '2026-05-08 12:00:00'),
(19, 19, 19, '2026-05-19 08:00:00', '2026-05-19 16:00:00', 690, 859, '2026-05-08 12:00:00'),
(20, 20, 20, '2026-05-20 08:00:00', '2026-05-20 16:00:00', 700, 870, '2026-05-08 12:00:00'),
(21, 21, 21, '2026-05-21 08:00:00', '2026-05-21 16:00:00', 710, 881, '2026-05-08 12:00:00'),
(22, 22, 22, '2026-05-22 08:00:00', '2026-05-22 16:00:00', 720, 892, '2026-05-08 12:00:00'),
(23, 23, 23, '2026-05-23 08:00:00', '2026-05-23 16:00:00', 730, 903, '2026-05-08 12:00:00'),
(24, 24, 24, '2026-05-24 08:00:00', '2026-05-24 16:00:00', 740, 914, '2026-05-08 12:00:00'),
(25, 25, 25, '2026-05-25 08:00:00', '2026-05-25 16:00:00', 750, 925, '2026-05-08 12:00:00'),
(26, 26, 26, '2026-05-26 08:00:00', '2026-05-26 16:00:00', 760, 936, '2026-05-08 12:00:00'),
(27, 27, 27, '2026-05-27 08:00:00', '2026-05-27 16:00:00', 770, 947, '2026-05-08 12:00:00'),
(28, 28, 28, '2026-05-28 08:00:00', '2026-05-28 16:00:00', 780, 958, '2026-05-08 12:00:00'),
(29, 29, 29, '2026-05-01 08:00:00', '2026-05-01 16:00:00', 790, 969, '2026-05-08 12:00:00'),
(30, 30, 30, '2026-05-02 08:00:00', '2026-05-02 16:00:00', 800, 980, '2026-05-08 12:00:00');

INSERT INTO sale (id, customer_id, employee_id, register_id, sale_date, total_amount, tax_amount, discount_amount, final_amount, created_at) VALUES
(1, 1, 1, 1, '2026-05-01 12:00:00', 36.62, 5.13, 0, 41.75, '2026-05-08 12:00:00'),
(2, 2, 2, 2, '2026-05-02 12:00:00', 63.36, 8.87, 0, 72.23, '2026-05-08 12:00:00'),
(3, 3, 3, 3, '2026-05-03 12:00:00', 95.76, 13.41, 4.79, 104.38, '2026-05-08 12:00:00'),
(4, 4, 4, 4, '2026-05-04 12:00:00', 133.75, 18.73, 0, 152.48, '2026-05-08 12:00:00'),
(5, 5, 5, 5, '2026-05-05 12:00:00', 29.56, 4.14, 0, 33.7, '2026-05-08 12:00:00'),
(6, 6, 6, 6, '2026-05-06 12:00:00', 64.76, 9.07, 3.24, 70.59, '2026-05-08 12:00:00'),
(7, 7, 7, 7, '2026-05-07 12:00:00', 105.57, 14.78, 0, 120.35, '2026-05-08 12:00:00'),
(8, 8, 8, 8, '2026-05-08 12:00:00', 152.0, 21.28, 0, 173.28, '2026-05-08 12:00:00'),
(9, 9, 9, 9, '2026-05-09 12:00:00', 204.05, 28.57, 10.2, 222.42, '2026-05-08 12:00:00'),
(10, 10, 10, 10, '2026-05-10 12:00:00', 43.62, 6.11, 0, 49.73, '2026-05-08 12:00:00'),
(11, 11, 11, 11, '2026-05-11 12:00:00', 92.88, 13.0, 0, 105.88, '2026-05-08 12:00:00'),
(12, 12, 12, 12, '2026-05-12 12:00:00', 147.75, 20.69, 7.39, 161.05, '2026-05-08 12:00:00'),
(13, 13, 13, 13, '2026-05-13 12:00:00', 208.24, 29.15, 0, 237.39, '2026-05-08 12:00:00'),
(14, 14, 14, 14, '2026-05-14 12:00:00', 274.4, 38.42, 0, 312.82, '2026-05-08 12:00:00'),
(15, 15, 15, 15, '2026-05-15 12:00:00', 57.69, 8.08, 2.88, 62.89, '2026-05-08 12:00:00'),
(16, 16, 16, 16, '2026-05-16 12:00:00', 121.0, 16.94, 0, 137.94, '2026-05-08 12:00:00'),
(17, 17, 17, 17, '2026-05-17 12:00:00', 189.93, 26.59, 0, 216.52, '2026-05-08 12:00:00'),
(18, 18, 18, 18, '2026-05-18 12:00:00', 264.48, 37.03, 13.22, 288.29, '2026-05-08 12:00:00'),
(19, 19, 19, 19, '2026-05-19 12:00:00', 344.7, 48.26, 0, 392.96, '2026-05-08 12:00:00'),
(20, 20, 20, 20, '2026-05-20 12:00:00', 71.75, 10.05, 0, 81.8, '2026-05-08 12:00:00'),
(21, 21, 21, 21, '2026-05-21 12:00:00', 149.12, 20.88, 7.46, 162.54, '2026-05-08 12:00:00'),
(22, 22, 22, 22, '2026-05-22 12:00:00', 232.14, 32.5, 0, 264.64, '2026-05-08 12:00:00'),
(23, 23, 23, 23, '2026-05-23 12:00:00', 320.76, 44.91, 0, 365.67, '2026-05-08 12:00:00'),
(24, 24, 24, 24, '2026-05-24 12:00:00', 415.0, 58.1, 20.75, 452.35, '2026-05-08 12:00:00'),
(25, 25, 25, 25, '2026-05-25 12:00:00', 85.81, 12.01, 0, 97.82, '2026-05-08 12:00:00'),
(26, 26, 26, 26, '2026-05-26 12:00:00', 177.24, 24.81, 0, 202.05, '2026-05-08 12:00:00'),
(27, 27, 27, 27, '2026-05-27 12:00:00', 274.32, 38.4, 13.72, 299.0, '2026-05-08 12:00:00'),
(28, 28, 28, 28, '2026-05-28 12:00:00', 377.0, 52.78, 0, 429.78, '2026-05-08 12:00:00'),
(29, 29, 29, 29, '2026-05-01 12:00:00', 485.3, 67.94, 0, 553.24, '2026-05-08 12:00:00'),
(30, 30, 30, 30, '2026-05-02 12:00:00', 99.88, 13.98, 4.99, 108.87, '2026-05-08 12:00:00');

INSERT INTO sale_item (id, sale_id, product_id, qty, unit_price, total_price) VALUES
(1, 1, 1, 2, 18.31, 36.62),
(2, 2, 2, 3, 21.12, 63.36),
(3, 3, 3, 4, 23.94, 95.76),
(4, 4, 4, 5, 26.75, 133.75),
(5, 5, 5, 1, 29.56, 29.56),
(6, 6, 6, 2, 32.38, 64.76),
(7, 7, 7, 3, 35.19, 105.57),
(8, 8, 8, 4, 38.0, 152.0),
(9, 9, 9, 5, 40.81, 204.05),
(10, 10, 10, 1, 43.62, 43.62),
(11, 11, 11, 2, 46.44, 92.88),
(12, 12, 12, 3, 49.25, 147.75),
(13, 13, 13, 4, 52.06, 208.24),
(14, 14, 14, 5, 54.88, 274.4),
(15, 15, 15, 1, 57.69, 57.69),
(16, 16, 16, 2, 60.5, 121.0),
(17, 17, 17, 3, 63.31, 189.93),
(18, 18, 18, 4, 66.12, 264.48),
(19, 19, 19, 5, 68.94, 344.7),
(20, 20, 20, 1, 71.75, 71.75),
(21, 21, 21, 2, 74.56, 149.12),
(22, 22, 22, 3, 77.38, 232.14),
(23, 23, 23, 4, 80.19, 320.76),
(24, 24, 24, 5, 83.0, 415.0),
(25, 25, 25, 1, 85.81, 85.81),
(26, 26, 26, 2, 88.62, 177.24),
(27, 27, 27, 3, 91.44, 274.32),
(28, 28, 28, 4, 94.25, 377.0),
(29, 29, 29, 5, 97.06, 485.3),
(30, 30, 30, 1, 99.88, 99.88);

INSERT INTO payment (id, sale_id, amount, pay_date, status_p, pay_method, created_at) VALUES
(1, 1, 41.75, '2026-05-01 12:05:00', 'paid', 'cash', '2026-05-08 12:00:00'),
(2, 2, 72.23, '2026-05-02 12:05:00', 'paid', 'card', '2026-05-08 12:00:00'),
(3, 3, 104.38, '2026-05-03 12:05:00', 'paid', 'wallet', '2026-05-08 12:00:00'),
(4, 4, 152.48, '2026-05-04 12:05:00', 'paid', 'bank_transfer', '2026-05-08 12:00:00'),
(5, 5, 33.7, '2026-05-05 12:05:00', 'paid', 'cash', '2026-05-08 12:00:00'),
(6, 6, 70.59, '2026-05-06 12:05:00', 'paid', 'card', '2026-05-08 12:00:00'),
(7, 7, 120.35, '2026-05-07 12:05:00', 'paid', 'wallet', '2026-05-08 12:00:00'),
(8, 8, 173.28, '2026-05-08 12:05:00', 'paid', 'bank_transfer', '2026-05-08 12:00:00'),
(9, 9, 222.42, '2026-05-09 12:05:00', 'paid', 'cash', '2026-05-08 12:00:00'),
(10, 10, 49.73, '2026-05-10 12:05:00', 'paid', 'card', '2026-05-08 12:00:00'),
(11, 11, 105.88, '2026-05-11 12:05:00', 'paid', 'wallet', '2026-05-08 12:00:00'),
(12, 12, 161.05, '2026-05-12 12:05:00', 'paid', 'bank_transfer', '2026-05-08 12:00:00'),
(13, 13, 237.39, '2026-05-13 12:05:00', 'paid', 'cash', '2026-05-08 12:00:00'),
(14, 14, 312.82, '2026-05-14 12:05:00', 'paid', 'card', '2026-05-08 12:00:00'),
(15, 15, 62.89, '2026-05-15 12:05:00', 'paid', 'wallet', '2026-05-08 12:00:00'),
(16, 16, 137.94, '2026-05-16 12:05:00', 'paid', 'bank_transfer', '2026-05-08 12:00:00'),
(17, 17, 216.52, '2026-05-17 12:05:00', 'paid', 'cash', '2026-05-08 12:00:00'),
(18, 18, 288.29, '2026-05-18 12:05:00', 'paid', 'card', '2026-05-08 12:00:00'),
(19, 19, 392.96, '2026-05-19 12:05:00', 'paid', 'wallet', '2026-05-08 12:00:00'),
(20, 20, 81.8, '2026-05-20 12:05:00', 'paid', 'bank_transfer', '2026-05-08 12:00:00'),
(21, 21, 162.54, '2026-05-21 12:05:00', 'paid', 'cash', '2026-05-08 12:00:00'),
(22, 22, 264.64, '2026-05-22 12:05:00', 'paid', 'card', '2026-05-08 12:00:00'),
(23, 23, 365.67, '2026-05-23 12:05:00', 'paid', 'wallet', '2026-05-08 12:00:00'),
(24, 24, 452.35, '2026-05-24 12:05:00', 'paid', 'bank_transfer', '2026-05-08 12:00:00'),
(25, 25, 97.82, '2026-05-25 12:05:00', 'paid', 'cash', '2026-05-08 12:00:00'),
(26, 26, 202.05, '2026-05-26 12:05:00', 'paid', 'card', '2026-05-08 12:00:00'),
(27, 27, 299.0, '2026-05-27 12:05:00', 'paid', 'wallet', '2026-05-08 12:00:00'),
(28, 28, 429.78, '2026-05-28 12:05:00', 'paid', 'bank_transfer', '2026-05-08 12:00:00'),
(29, 29, 553.24, '2026-05-01 12:05:00', 'paid', 'cash', '2026-05-08 12:00:00'),
(30, 30, 108.87, '2026-05-02 12:05:00', 'paid', 'card', '2026-05-08 12:00:00');

INSERT INTO sale_return (id, sale_id, customer_id, return_date, total_return, reason, created_at) VALUES
(1, 1, 1, '2026-05-01 14:00:00', 18.31, 'Customer returned item', '2026-05-08 12:00:00'),
(2, 2, 2, '2026-05-02 14:00:00', 21.12, 'Customer returned item', '2026-05-08 12:00:00'),
(3, 3, 3, '2026-05-03 14:00:00', 23.94, 'Customer returned item', '2026-05-08 12:00:00'),
(4, 4, 4, '2026-05-04 14:00:00', 26.75, 'Customer returned item', '2026-05-08 12:00:00'),
(5, 5, 5, '2026-05-05 14:00:00', 29.56, 'Customer returned item', '2026-05-08 12:00:00'),
(6, 6, 6, '2026-05-06 14:00:00', 32.38, 'Customer returned item', '2026-05-08 12:00:00'),
(7, 7, 7, '2026-05-07 14:00:00', 35.19, 'Customer returned item', '2026-05-08 12:00:00'),
(8, 8, 8, '2026-05-08 14:00:00', 38.0, 'Customer returned item', '2026-05-08 12:00:00'),
(9, 9, 9, '2026-05-09 14:00:00', 40.81, 'Customer returned item', '2026-05-08 12:00:00'),
(10, 10, 10, '2026-05-10 14:00:00', 43.62, 'Customer returned item', '2026-05-08 12:00:00'),
(11, 11, 11, '2026-05-11 14:00:00', 46.44, 'Customer returned item', '2026-05-08 12:00:00'),
(12, 12, 12, '2026-05-12 14:00:00', 49.25, 'Customer returned item', '2026-05-08 12:00:00'),
(13, 13, 13, '2026-05-13 14:00:00', 52.06, 'Customer returned item', '2026-05-08 12:00:00'),
(14, 14, 14, '2026-05-14 14:00:00', 54.88, 'Customer returned item', '2026-05-08 12:00:00'),
(15, 15, 15, '2026-05-15 14:00:00', 57.69, 'Customer returned item', '2026-05-08 12:00:00'),
(16, 16, 16, '2026-05-16 14:00:00', 60.5, 'Customer returned item', '2026-05-08 12:00:00'),
(17, 17, 17, '2026-05-17 14:00:00', 63.31, 'Customer returned item', '2026-05-08 12:00:00'),
(18, 18, 18, '2026-05-18 14:00:00', 66.12, 'Customer returned item', '2026-05-08 12:00:00'),
(19, 19, 19, '2026-05-19 14:00:00', 68.94, 'Customer returned item', '2026-05-08 12:00:00'),
(20, 20, 20, '2026-05-20 14:00:00', 71.75, 'Customer returned item', '2026-05-08 12:00:00'),
(21, 21, 21, '2026-05-21 14:00:00', 74.56, 'Customer returned item', '2026-05-08 12:00:00'),
(22, 22, 22, '2026-05-22 14:00:00', 77.38, 'Customer returned item', '2026-05-08 12:00:00'),
(23, 23, 23, '2026-05-23 14:00:00', 80.19, 'Customer returned item', '2026-05-08 12:00:00'),
(24, 24, 24, '2026-05-24 14:00:00', 83.0, 'Customer returned item', '2026-05-08 12:00:00'),
(25, 25, 25, '2026-05-25 14:00:00', 85.81, 'Customer returned item', '2026-05-08 12:00:00'),
(26, 26, 26, '2026-05-26 14:00:00', 88.62, 'Customer returned item', '2026-05-08 12:00:00'),
(27, 27, 27, '2026-05-27 14:00:00', 91.44, 'Customer returned item', '2026-05-08 12:00:00'),
(28, 28, 28, '2026-05-28 14:00:00', 94.25, 'Customer returned item', '2026-05-08 12:00:00'),
(29, 29, 29, '2026-05-01 14:00:00', 97.06, 'Customer returned item', '2026-05-08 12:00:00'),
(30, 30, 30, '2026-05-02 14:00:00', 99.88, 'Customer returned item', '2026-05-08 12:00:00');

INSERT INTO sale_return_item (id, sale_return_id, product_id, qty, refund_amount, created_at) VALUES
(1, 1, 1, 1, 18.31, '2026-05-08 12:00:00'),
(2, 2, 2, 1, 21.12, '2026-05-08 12:00:00'),
(3, 3, 3, 1, 23.94, '2026-05-08 12:00:00'),
(4, 4, 4, 1, 26.75, '2026-05-08 12:00:00'),
(5, 5, 5, 1, 29.56, '2026-05-08 12:00:00'),
(6, 6, 6, 1, 32.38, '2026-05-08 12:00:00'),
(7, 7, 7, 1, 35.19, '2026-05-08 12:00:00'),
(8, 8, 8, 1, 38.0, '2026-05-08 12:00:00'),
(9, 9, 9, 1, 40.81, '2026-05-08 12:00:00'),
(10, 10, 10, 1, 43.62, '2026-05-08 12:00:00'),
(11, 11, 11, 1, 46.44, '2026-05-08 12:00:00'),
(12, 12, 12, 1, 49.25, '2026-05-08 12:00:00'),
(13, 13, 13, 1, 52.06, '2026-05-08 12:00:00'),
(14, 14, 14, 1, 54.88, '2026-05-08 12:00:00'),
(15, 15, 15, 1, 57.69, '2026-05-08 12:00:00'),
(16, 16, 16, 1, 60.5, '2026-05-08 12:00:00'),
(17, 17, 17, 1, 63.31, '2026-05-08 12:00:00'),
(18, 18, 18, 1, 66.12, '2026-05-08 12:00:00'),
(19, 19, 19, 1, 68.94, '2026-05-08 12:00:00'),
(20, 20, 20, 1, 71.75, '2026-05-08 12:00:00'),
(21, 21, 21, 1, 74.56, '2026-05-08 12:00:00'),
(22, 22, 22, 1, 77.38, '2026-05-08 12:00:00'),
(23, 23, 23, 1, 80.19, '2026-05-08 12:00:00'),
(24, 24, 24, 1, 83.0, '2026-05-08 12:00:00'),
(25, 25, 25, 1, 85.81, '2026-05-08 12:00:00'),
(26, 26, 26, 1, 88.62, '2026-05-08 12:00:00'),
(27, 27, 27, 1, 91.44, '2026-05-08 12:00:00'),
(28, 28, 28, 1, 94.25, '2026-05-08 12:00:00'),
(29, 29, 29, 1, 97.06, '2026-05-08 12:00:00'),
(30, 30, 30, 1, 99.88, '2026-05-08 12:00:00');

INSERT INTO points_transaction (id, loyalty_id, points_change, transaction_type, transaction_date, created_at) VALUES
(1, 1, 4, 'earn', '2026-05-01 12:10:00', '2026-05-08 12:00:00'),
(2, 2, 7, 'earn', '2026-05-02 12:10:00', '2026-05-08 12:00:00'),
(3, 3, 10, 'earn', '2026-05-03 12:10:00', '2026-05-08 12:00:00'),
(4, 4, 15, 'earn', '2026-05-04 12:10:00', '2026-05-08 12:00:00'),
(5, 5, 3, 'earn', '2026-05-05 12:10:00', '2026-05-08 12:00:00'),
(6, 6, 7, 'earn', '2026-05-06 12:10:00', '2026-05-08 12:00:00'),
(7, 7, 12, 'earn', '2026-05-07 12:10:00', '2026-05-08 12:00:00'),
(8, 8, 17, 'earn', '2026-05-08 12:10:00', '2026-05-08 12:00:00'),
(9, 9, 22, 'earn', '2026-05-09 12:10:00', '2026-05-08 12:00:00'),
(10, 10, 4, 'earn', '2026-05-10 12:10:00', '2026-05-08 12:00:00'),
(11, 11, 10, 'earn', '2026-05-11 12:10:00', '2026-05-08 12:00:00'),
(12, 12, 16, 'earn', '2026-05-12 12:10:00', '2026-05-08 12:00:00'),
(13, 13, 23, 'earn', '2026-05-13 12:10:00', '2026-05-08 12:00:00'),
(14, 14, 31, 'earn', '2026-05-14 12:10:00', '2026-05-08 12:00:00'),
(15, 15, 6, 'earn', '2026-05-15 12:10:00', '2026-05-08 12:00:00'),
(16, 16, 13, 'earn', '2026-05-16 12:10:00', '2026-05-08 12:00:00'),
(17, 17, 21, 'earn', '2026-05-17 12:10:00', '2026-05-08 12:00:00'),
(18, 18, 28, 'earn', '2026-05-18 12:10:00', '2026-05-08 12:00:00'),
(19, 19, 39, 'earn', '2026-05-19 12:10:00', '2026-05-08 12:00:00'),
(20, 20, 8, 'earn', '2026-05-20 12:10:00', '2026-05-08 12:00:00'),
(21, 21, 16, 'earn', '2026-05-21 12:10:00', '2026-05-08 12:00:00'),
(22, 22, 26, 'earn', '2026-05-22 12:10:00', '2026-05-08 12:00:00'),
(23, 23, 36, 'earn', '2026-05-23 12:10:00', '2026-05-08 12:00:00'),
(24, 24, 45, 'earn', '2026-05-24 12:10:00', '2026-05-08 12:00:00'),
(25, 25, 9, 'earn', '2026-05-25 12:10:00', '2026-05-08 12:00:00'),
(26, 26, 20, 'earn', '2026-05-26 12:10:00', '2026-05-08 12:00:00'),
(27, 27, 29, 'earn', '2026-05-27 12:10:00', '2026-05-08 12:00:00'),
(28, 28, 42, 'earn', '2026-05-28 12:10:00', '2026-05-08 12:00:00'),
(29, 29, 55, 'earn', '2026-05-01 12:10:00', '2026-05-08 12:00:00'),
(30, 30, 10, 'earn', '2026-05-02 12:10:00', '2026-05-08 12:00:00');


-- =========================================================
-- Helpful indexes for FastAPI list/search pages
-- =========================================================
CREATE INDEX idx_product_category_id ON product(category_id);
CREATE INDEX idx_product_supplier_id ON product(supplier_id);
CREATE INDEX idx_sale_customer_id ON sale(customer_id);
CREATE INDEX idx_sale_employee_id ON sale(employee_id);
CREATE INDEX idx_sale_register_id ON sale(register_id);
CREATE INDEX idx_sale_item_sale_id ON sale_item(sale_id);
CREATE INDEX idx_payment_sale_id ON payment(sale_id);
CREATE INDEX idx_purchase_order_supplier_id ON purchase_order(supplier_id);
CREATE INDEX idx_po_item_po_id ON po_item(po_id);
CREATE INDEX idx_inventory_movement_product_id ON inventory_movement(product_id);
CREATE INDEX idx_sale_return_sale_id ON sale_return(sale_id);

PRAGMA foreign_key_check;
