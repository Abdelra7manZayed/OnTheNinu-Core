from collections import OrderedDict
from . import models

# Slug -> table configuration used by generic CRUD/API pages.
TABLES = OrderedDict([
    ("suppliers", {"model": models.Supplier, "title": "Suppliers", "group": "Products & Inventory", "label": "sup_n", "search": ["sup_n", "contact_n", "phone", "email", "tax_num"]}),
    ("roles", {"model": models.Role, "title": "Roles", "group": "People & Access", "label": "name", "search": ["name", "r_desc"]}),
    ("branches", {"model": models.Branch, "title": "Branches", "group": "People & Access", "label": "name", "search": ["name", "address", "phone"]}),
    ("registers", {"model": models.Register, "title": "Registers", "group": "People & Access", "label": "register_code", "search": ["register_code"]}),
    ("departments", {"model": models.Department, "title": "Departments", "group": "People & Access", "label": "dep_name", "search": ["dep_name"]}),
    ("employees", {"model": models.Employee, "title": "Employees", "group": "People & Access", "label": "first_n", "search": ["first_n", "last_n", "national_ID", "email"]}),
    ("role-permissions", {"model": models.RolePermission, "title": "Role Permissions", "group": "People & Access", "label": "module", "search": ["module", "action", "descr"]}),
    ("users", {"model": models.UserAccount, "title": "Login Users", "group": "People & Access", "label": "username", "search": ["username"]}),
    ("categories", {"model": models.Category, "title": "Categories", "group": "Products & Inventory", "label": "cat_name", "search": ["cat_name"]}),
    ("products", {"model": models.Product, "title": "Products", "group": "Products & Inventory", "label": "product_name", "search": ["product_name", "barcode"]}),
    ("inventory-movements", {"model": models.InventoryMovement, "title": "Inventory Movements", "group": "Products & Inventory", "label": "movement_type", "search": ["movement_type", "reason"]}),
    ("discounts", {"model": models.Discount, "title": "Discounts", "group": "Products & Inventory", "label": "disc_name", "search": ["disc_name", "type_d"]}),
    ("discount-products", {"model": models.DiscountProduct, "title": "Discount Products", "group": "Products & Inventory", "label": "id", "search": []}),
    ("customers", {"model": models.Customer, "title": "Customers", "group": "Sales & Customers", "label": "cus_name", "search": ["cus_name", "phone", "email"]}),
    ("loyalty-accounts", {"model": models.LoyaltyAccount, "title": "Loyalty Accounts", "group": "Sales & Customers", "label": "card_number", "search": ["card_number", "membership_level"]}),
    ("points-transactions", {"model": models.PointsTransaction, "title": "Points Transactions", "group": "Sales & Customers", "label": "transaction_type", "search": ["transaction_type"]}),
    ("sales", {"model": models.Sale, "title": "Sales", "group": "Sales & Customers", "label": "id", "search": []}),
    ("sale-items", {"model": models.SaleItem, "title": "Sale Items", "group": "Sales & Customers", "label": "id", "search": []}),
    ("payments", {"model": models.Payment, "title": "Payments", "group": "Sales & Customers", "label": "pay_method", "search": ["pay_method", "status_p"]}),
    ("sale-returns", {"model": models.SaleReturn, "title": "Sale Returns", "group": "Sales & Customers", "label": "reason", "search": ["reason"]}),
    ("sale-return-items", {"model": models.SaleReturnItem, "title": "Sale Return Items", "group": "Sales & Customers", "label": "id", "search": []}),
    ("purchase-orders", {"model": models.PurchaseOrder, "title": "Purchase Orders", "group": "Purchasing", "label": "status_po", "search": ["status_po"]}),
    ("po-items", {"model": models.POItem, "title": "Purchase Order Items", "group": "Purchasing", "label": "id", "search": []}),
    ("shifts", {"model": models.Shift, "title": "Shifts", "group": "People & Access", "label": "id", "search": []}),
])

TABLE_BY_NAME = {config["model"].__tablename__: slug for slug, config in TABLES.items()}
MODEL_BY_TABLE_NAME = {config["model"].__tablename__: config["model"] for config in TABLES.values()}

ENUM_OPTIONS = {
    "is_active": [(1, "Active"), (0, "Inactive")],
    "movement_type": [
        ("opening_stock", "Opening stock"), ("purchase", "Purchase"), ("sale", "Sale"),
        ("return", "Return"), ("adjustment_in", "Adjustment in"), ("adjustment_out", "Adjustment out"),
    ],
    "type_d": [("percentage", "Percentage"), ("fixed_amount", "Fixed amount")],
    "membership_level": [("Basic", "Basic"), ("Silver", "Silver"), ("Gold", "Gold"), ("Platinum", "Platinum")],
    "transaction_type": [("earn", "Earn"), ("redeem", "Redeem"), ("refund", "Refund"), ("adjustment", "Adjustment")],
    "status_p": [("pending", "Pending"), ("paid", "Paid"), ("failed", "Failed"), ("refunded", "Refunded")],
    "pay_method": [("cash", "Cash"), ("card", "Card"), ("wallet", "Wallet"), ("bank_transfer", "Bank transfer")],
    "status_po": [("pending", "Pending"), ("ordered", "Ordered"), ("received", "Received"), ("cancelled", "Cancelled")],
}

HIDDEN_FORM_FIELDS = {"id", "created_at", "last_login"}
READONLY_FIELDS = {"created_at", "last_login"}

def nav_groups():
    grouped = OrderedDict()
    for slug, config in TABLES.items():
        grouped.setdefault(config["group"], []).append((slug, config))
    return grouped
