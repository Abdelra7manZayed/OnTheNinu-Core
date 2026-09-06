from sqlalchemy import Column, Float, ForeignKey, Integer, String, Text, text
from sqlalchemy.orm import relationship
from .database import Base


class Supplier(Base):
    __tablename__ = "supplier"
    id = Column(Integer, primary_key=True)
    sup_n = Column(String, nullable=False)
    contact_n = Column(String)
    phone = Column(String)
    email = Column(String, unique=True)
    address = Column(Text)
    tax_num = Column(String)
    pay_terms_days = Column(Integer, nullable=False, default=0)
    is_active = Column(Integer, nullable=False, default=1)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    created_by = Column(Integer)
    updated_by = Column(Integer)

    products = relationship("Product", back_populates="supplier")
    purchase_orders = relationship("PurchaseOrder", back_populates="supplier")


class Role(Base):
    __tablename__ = "role"
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False, unique=True)
    r_desc = Column(Text)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    created_by = Column(Integer)
    updated_by = Column(Integer)

    employees = relationship("Employee", back_populates="role")
    permissions = relationship("RolePermission", back_populates="role")


class Branch(Base):
    __tablename__ = "branch"
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    address = Column(Text)
    phone = Column(String)
    manager_id = Column(Integer, ForeignKey("employee.id"))
    is_active = Column(Integer, nullable=False, default=1)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    created_by = Column(Integer)
    updated_by = Column(Integer)

    manager = relationship("Employee", foreign_keys=[manager_id], post_update=True)
    registers = relationship("Register", back_populates="branch")
    departments = relationship("Department", back_populates="branch")


class Register(Base):
    __tablename__ = "register"
    id = Column(Integer, primary_key=True)
    branch_id = Column(Integer, ForeignKey("branch.id"), nullable=False)
    register_code = Column(String, nullable=False, unique=True)
    is_active = Column(Integer, nullable=False, default=1)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    created_by = Column(Integer)
    updated_by = Column(Integer)

    branch = relationship("Branch", back_populates="registers")
    sales = relationship("Sale", back_populates="register")
    shifts = relationship("Shift", back_populates="register")


class Department(Base):
    __tablename__ = "department"
    id = Column(Integer, primary_key=True)
    branch_id = Column(Integer, ForeignKey("branch.id"), nullable=False)
    dep_name = Column(String, nullable=False)
    manager_id = Column(Integer, ForeignKey("employee.id"))
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    created_by = Column(Integer)
    updated_by = Column(Integer)

    branch = relationship("Branch", back_populates="departments")
    manager = relationship("Employee", foreign_keys=[manager_id], post_update=True)
    employees = relationship("Employee", foreign_keys="Employee.dep_id", back_populates="department")


class Employee(Base):
    __tablename__ = "employee"
    id = Column(Integer, primary_key=True)
    first_n = Column(String, nullable=False)
    last_n = Column(String, nullable=False)
    national_ID = Column(String, unique=True)
    email = Column(String, unique=True)
    dep_id = Column(Integer, ForeignKey("department.id"))
    role_id = Column(Integer, ForeignKey("role.id"))
    salary = Column(Float)
    hire_date = Column(String)
    is_active = Column(Integer, nullable=False, default=1)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    created_by = Column(Integer)
    updated_by = Column(Integer)

    department = relationship("Department", foreign_keys=[dep_id], back_populates="employees")
    role = relationship("Role", back_populates="employees")
    sales = relationship("Sale", back_populates="employee")
    purchase_orders = relationship("PurchaseOrder", back_populates="employee")
    shifts = relationship("Shift", back_populates="employee")
    user_account = relationship("UserAccount", back_populates="employee", uselist=False)


class RolePermission(Base):
    __tablename__ = "role_permission"
    id = Column(Integer, primary_key=True)
    role_id = Column(Integer, ForeignKey("role.id"), nullable=False)
    module = Column(String, nullable=False)
    action = Column(String, nullable=False)
    descr = Column(Text)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    created_by = Column(Integer)
    updated_by = Column(Integer)

    role = relationship("Role", back_populates="permissions")


class Category(Base):
    __tablename__ = "category"
    id = Column(Integer, primary_key=True)
    parent_id = Column(Integer, ForeignKey("category.id"))
    cat_name = Column(String, nullable=False)
    is_active = Column(Integer, nullable=False, default=1)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    created_by = Column(Integer)
    updated_by = Column(Integer)

    parent = relationship("Category", remote_side=[id])
    products = relationship("Product", back_populates="category")


class Product(Base):
    __tablename__ = "product"
    id = Column(Integer, primary_key=True)
    product_name = Column(String, nullable=False)
    category_id = Column(Integer, ForeignKey("category.id"), nullable=False)
    supplier_id = Column(Integer, ForeignKey("supplier.id"))
    barcode = Column(String, unique=True)
    cost_price = Column(Float, nullable=False)
    sell_price = Column(Float, nullable=False)
    stock_qty = Column(Float, nullable=False, default=0)
    reorder_level = Column(Float, nullable=False, default=0)
    is_active = Column(Integer, nullable=False, default=1)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    created_by = Column(Integer)
    updated_by = Column(Integer)

    category = relationship("Category", back_populates="products")
    supplier = relationship("Supplier", back_populates="products")
    sale_items = relationship("SaleItem", back_populates="product")
    po_items = relationship("POItem", back_populates="product")
    inventory_movements = relationship("InventoryMovement", back_populates="product")
    discount_products = relationship("DiscountProduct", back_populates="product")
    return_items = relationship("SaleReturnItem", back_populates="product")


class InventoryMovement(Base):
    __tablename__ = "inventory_movement"
    id = Column(Integer, primary_key=True)
    product_id = Column(Integer, ForeignKey("product.id"), nullable=False)
    movement_type = Column(String, nullable=False)
    qty = Column(Float, nullable=False)
    movement_date = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    reason = Column(Text)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))

    product = relationship("Product", back_populates="inventory_movements")


class Discount(Base):
    __tablename__ = "discount"
    id = Column(Integer, primary_key=True)
    disc_name = Column(String, nullable=False)
    type_d = Column(String, nullable=False)
    value_d = Column(Float, nullable=False)
    st_date = Column(String, nullable=False)
    end_date = Column(String)
    is_active = Column(Integer, nullable=False, default=1)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    created_by = Column(Integer)
    updated_by = Column(Integer)

    discount_products = relationship("DiscountProduct", back_populates="discount")


class DiscountProduct(Base):
    __tablename__ = "discount_product"
    id = Column(Integer, primary_key=True)
    discount_id = Column(Integer, ForeignKey("discount.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("product.id"), nullable=False)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    created_by = Column(Integer)
    updated_by = Column(Integer)

    discount = relationship("Discount", back_populates="discount_products")
    product = relationship("Product", back_populates="discount_products")


class Customer(Base):
    __tablename__ = "customer"
    id = Column(Integer, primary_key=True)
    cus_name = Column(String, nullable=False)
    phone = Column(String, unique=True)
    email = Column(String, unique=True)
    loyalty_points = Column(Integer, nullable=False, default=0)
    is_active = Column(Integer, nullable=False, default=1)
    registered_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    created_by = Column(Integer)
    updated_by = Column(Integer)

    loyalty_account = relationship("LoyaltyAccount", back_populates="customer", uselist=False)
    sales = relationship("Sale", back_populates="customer")
    returns = relationship("SaleReturn", back_populates="customer")


class LoyaltyAccount(Base):
    __tablename__ = "loyalty_account"
    id = Column(Integer, primary_key=True)
    customer_id = Column(Integer, ForeignKey("customer.id"), nullable=False, unique=True)
    card_number = Column(String, nullable=False, unique=True)
    points_balance = Column(Integer, nullable=False, default=0)
    membership_level = Column(String, nullable=False, default="Basic")
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))

    customer = relationship("Customer", back_populates="loyalty_account")
    transactions = relationship("PointsTransaction", back_populates="loyalty_account")


class Sale(Base):
    __tablename__ = "sale"
    id = Column(Integer, primary_key=True)
    customer_id = Column(Integer, ForeignKey("customer.id"))
    employee_id = Column(Integer, ForeignKey("employee.id"), nullable=False)
    register_id = Column(Integer, ForeignKey("register.id"), nullable=False)
    sale_date = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    total_amount = Column(Float, nullable=False)
    tax_amount = Column(Float, nullable=False, default=0)
    discount_amount = Column(Float, nullable=False, default=0)
    final_amount = Column(Float, nullable=False)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))

    customer = relationship("Customer", back_populates="sales")
    employee = relationship("Employee", back_populates="sales")
    register = relationship("Register", back_populates="sales")
    items = relationship("SaleItem", back_populates="sale")
    payments = relationship("Payment", back_populates="sale")
    returns = relationship("SaleReturn", back_populates="sale")


class SaleItem(Base):
    __tablename__ = "sale_item"
    id = Column(Integer, primary_key=True)
    sale_id = Column(Integer, ForeignKey("sale.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("product.id"), nullable=False)
    qty = Column(Float, nullable=False)
    unit_price = Column(Float, nullable=False)
    total_price = Column(Float, nullable=False)

    sale = relationship("Sale", back_populates="items")
    product = relationship("Product", back_populates="sale_items")


class Payment(Base):
    __tablename__ = "payment"
    id = Column(Integer, primary_key=True)
    sale_id = Column(Integer, ForeignKey("sale.id"), nullable=False)
    amount = Column(Float, nullable=False)
    pay_date = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    status_p = Column(String, nullable=False)
    pay_method = Column(String, nullable=False)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))

    sale = relationship("Sale", back_populates="payments")


class SaleReturn(Base):
    __tablename__ = "sale_return"
    id = Column(Integer, primary_key=True)
    sale_id = Column(Integer, ForeignKey("sale.id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("customer.id"))
    return_date = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    total_return = Column(Float, nullable=False)
    reason = Column(Text)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))

    sale = relationship("Sale", back_populates="returns")
    customer = relationship("Customer", back_populates="returns")
    items = relationship("SaleReturnItem", back_populates="sale_return")


class SaleReturnItem(Base):
    __tablename__ = "sale_return_item"
    id = Column(Integer, primary_key=True)
    sale_return_id = Column(Integer, ForeignKey("sale_return.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("product.id"), nullable=False)
    qty = Column(Float, nullable=False)
    refund_amount = Column(Float, nullable=False)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))

    sale_return = relationship("SaleReturn", back_populates="items")
    product = relationship("Product", back_populates="return_items")


class PointsTransaction(Base):
    __tablename__ = "points_transaction"
    id = Column(Integer, primary_key=True)
    loyalty_id = Column(Integer, ForeignKey("loyalty_account.id"), nullable=False)
    points_change = Column(Integer, nullable=False)
    transaction_type = Column(String, nullable=False)
    transaction_date = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))

    loyalty_account = relationship("LoyaltyAccount", back_populates="transactions")


class PurchaseOrder(Base):
    __tablename__ = "purchase_order"
    id = Column(Integer, primary_key=True)
    supplier_id = Column(Integer, ForeignKey("supplier.id"), nullable=False)
    employee_id = Column(Integer, ForeignKey("employee.id"), nullable=False)
    order_date = Column(String, nullable=False)
    expected_date = Column(String)
    total_amount = Column(Float, nullable=False, default=0)
    status_po = Column(String, nullable=False)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))

    supplier = relationship("Supplier", back_populates="purchase_orders")
    employee = relationship("Employee", back_populates="purchase_orders")
    items = relationship("POItem", back_populates="purchase_order")


class POItem(Base):
    __tablename__ = "po_item"
    id = Column(Integer, primary_key=True)
    po_id = Column(Integer, ForeignKey("purchase_order.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("product.id"), nullable=False)
    qty = Column(Float, nullable=False)
    cost_price = Column(Float, nullable=False)
    total_cost = Column(Float, nullable=False)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))

    purchase_order = relationship("PurchaseOrder", back_populates="items")
    product = relationship("Product", back_populates="po_items")


class Shift(Base):
    __tablename__ = "shift"
    id = Column(Integer, primary_key=True)
    register_id = Column(Integer, ForeignKey("register.id"), nullable=False)
    employee_id = Column(Integer, ForeignKey("employee.id"), nullable=False)
    start_time = Column(String, nullable=False)
    end_time = Column(String)
    opening_balance = Column(Float, nullable=False, default=0)
    closing_balance = Column(Float)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))

    register = relationship("Register", back_populates="shifts")
    employee = relationship("Employee", back_populates="shifts")


class UserAccount(Base):
    """Authentication table added for the web app login system.

    It links to the ERD employee table instead of replacing it.
    """
    __tablename__ = "user_account"
    id = Column(Integer, primary_key=True)
    employee_id = Column(Integer, ForeignKey("employee.id"), nullable=False, unique=True)
    username = Column(String, nullable=False, unique=True)
    password_hash = Column(String, nullable=False)
    is_active = Column(Integer, nullable=False, default=1)
    last_login = Column(String)
    created_at = Column(String, nullable=False, server_default=text("CURRENT_TIMESTAMP"))

    employee = relationship("Employee", back_populates="user_account")
