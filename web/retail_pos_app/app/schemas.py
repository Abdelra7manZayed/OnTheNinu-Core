from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field


class Message(BaseModel):
    detail: str


class GenericRecord(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="allow")
    id: Optional[int] = None


class RecordsPage(BaseModel):
    table: str
    total: int
    rows: List[Dict[str, Any]]


class LoginPayload(BaseModel):
    username: str = Field(min_length=1, max_length=80)
    password: str = Field(min_length=1, max_length=200)


class DashboardCounts(BaseModel):
    suppliers: int
    products: int
    customers: int
    sales: int
    employees: int
    purchase_orders: int


# The project uses generic CRUD endpoints because the ERD has many tables.
# Validation is handled dynamically in app/crud.py using SQLAlchemy column metadata.
# This file keeps shared API response schemas in one place.
