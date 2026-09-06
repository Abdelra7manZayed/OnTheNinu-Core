import hashlib
import hmac
import os
import secrets
from datetime import datetime
from typing import Optional

from fastapi import HTTPException, Request, status
from sqlalchemy.orm import Session

from .models import UserAccount

PBKDF2_ITERATIONS = 120_000

# Table/resource access rules. Admin can do everything.
ROLE_ACCESS = {
    "Admin": {"*": {"*"}},
    "Manager": {
        "dashboard": {"read"}, "reports": {"read", "export"},
        "products": {"read", "create", "update"}, "categories": {"read", "create", "update"},
        "suppliers": {"read", "create", "update"}, "discounts": {"read", "create", "update"},
        "discount-products": {"read", "create", "update", "delete"},
        "customers": {"read", "create", "update"}, "loyalty-accounts": {"read", "create", "update"},
        "points-transactions": {"read", "create"},
        "sales": {"read", "create", "update"}, "sale-items": {"read", "create", "update"},
        "payments": {"read", "create", "update"}, "sale-returns": {"read", "create", "update"},
        "sale-return-items": {"read", "create", "update"},
        "purchase-orders": {"read", "create", "update"}, "po-items": {"read", "create", "update"},
        "inventory-movements": {"read", "create", "update"},
        "branches": {"read"}, "registers": {"read"}, "employees": {"read"}, "shifts": {"read", "create", "update"},
    },
    "Cashier": {
        "dashboard": {"read"}, "reports": {"read"},
        "customers": {"read", "create", "update"}, "loyalty-accounts": {"read", "create", "update"},
        "points-transactions": {"read", "create"},
        "sales": {"read", "create", "update"}, "sale-items": {"read", "create", "update"},
        "payments": {"read", "create", "update"}, "sale-returns": {"read", "create"},
        "sale-return-items": {"read", "create"}, "products": {"read"}, "discounts": {"read"},
    },
    "Inventory Clerk": {
        "dashboard": {"read"}, "reports": {"read", "export"},
        "products": {"read", "create", "update"}, "categories": {"read", "create", "update"},
        "suppliers": {"read", "create", "update"}, "inventory-movements": {"read", "create", "update"},
        "purchase-orders": {"read", "create", "update"}, "po-items": {"read", "create", "update"},
        "discounts": {"read"}, "discount-products": {"read"},
    },
    "Inventory Staff": {
        "dashboard": {"read"}, "reports": {"read", "export"},
        "products": {"read", "create", "update"}, "categories": {"read", "create", "update"},
        "suppliers": {"read", "create", "update"}, "inventory-movements": {"read", "create", "update"},
        "purchase-orders": {"read", "create", "update"}, "po-items": {"read", "create", "update"},
    },
}

def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    derived = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), PBKDF2_ITERATIONS)
    return f"pbkdf2_sha256${PBKDF2_ITERATIONS}${salt}${derived.hex()}"

def verify_password(password: str, stored_hash: str) -> bool:
    try:
        algorithm, iteration_text, salt, expected_hex = stored_hash.split("$", 3)
        if algorithm != "pbkdf2_sha256":
            return False
        iterations = int(iteration_text)
        derived = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), iterations).hex()
        return hmac.compare_digest(derived, expected_hex)
    except Exception:
        return False

def authenticate(db: Session, username: str, password: str) -> Optional[UserAccount]:
    user = db.query(UserAccount).filter(UserAccount.username == username.strip()).first()
    if not user or not user.is_active or not user.employee or not user.employee.is_active:
        return None
    if not verify_password(password, user.password_hash):
        return None
    user.last_login = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    db.commit()
    db.refresh(user)
    return user

def login_user(request: Request, user: UserAccount) -> None:
    role_name = user.employee.role.name if user.employee and user.employee.role else "General User"
    request.session["user"] = {
        "id": user.id,
        "username": user.username,
        "employee_id": user.employee_id,
        "name": f"{user.employee.first_n} {user.employee.last_n}".strip(),
        "role": role_name,
    }

def logout_user(request: Request) -> None:
    request.session.clear()

def current_user(request: Request):
    return request.session.get("user")

def is_allowed(user: dict, resource: str, action: str = "read") -> bool:
    if not user:
        return False
    rules = ROLE_ACCESS.get(user.get("role"), {})
    if "*" in rules and ("*" in rules["*"] or action in rules["*"]):
        return True
    actions = rules.get(resource, set())
    return "*" in actions or action in actions

def require_login(request: Request):
    user = current_user(request)
    if not user:
        raise HTTPException(status_code=status.HTTP_303_SEE_OTHER, headers={"Location": "/login"})
    return user

def require_permission(request: Request, resource: str, action: str = "read"):
    user = require_login(request)
    if not is_allowed(user, resource, action):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You do not have permission to access this page.")
    return user

def api_require_permission(request: Request, resource: str, action: str = "read"):
    user = current_user(request)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Login required")
    if not is_allowed(user, resource, action):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Permission denied")
    return user

def flash(request: Request, category: str, message: str) -> None:
    messages = request.session.get("flash", [])
    messages.append({"category": category, "message": message})
    request.session["flash"] = messages

def pop_flash(request: Request):
    return request.session.pop("flash", [])
