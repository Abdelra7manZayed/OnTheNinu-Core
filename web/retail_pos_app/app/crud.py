from typing import Any, Dict, Iterable, List, Tuple

from sqlalchemy import Float, Integer, String, Text, inspect, or_
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .table_config import ENUM_OPTIONS, HIDDEN_FORM_FIELDS, MODEL_BY_TABLE_NAME, TABLES


def get_model(slug: str):
    config = TABLES.get(slug)
    return config["model"] if config else None


def get_table_config(slug: str):
    return TABLES.get(slug)


def primary_key_name(model) -> str:
    return inspect(model).primary_key[0].name


def model_columns(model):
    return list(model.__table__.columns)


def display_label(obj) -> str:
    table_name = obj.__table__.name
    slug = next((s for s, c in TABLES.items() if c["model"].__tablename__ == table_name), None)
    config = TABLES.get(slug, {})
    label_field = config.get("label", "id")
    if table_name == "employee":
        return f"#{obj.id} - {obj.first_n} {obj.last_n}"
    if table_name == "sale":
        return f"Sale #{obj.id} - {getattr(obj, 'final_amount', '')} EGP"
    if table_name == "purchase_order":
        return f"PO #{obj.id} - {getattr(obj, 'status_po', '')}"
    if table_name == "product":
        return f"#{obj.id} - {obj.product_name}"
    value = getattr(obj, label_field, None)
    return f"#{getattr(obj, 'id', '')} - {value if value is not None else table_name}"


def serialize_instance(obj) -> Dict[str, Any]:
    return {column.name: getattr(obj, column.name) for column in obj.__table__.columns}


def serialize_many(items: Iterable) -> List[Dict[str, Any]]:
    return [serialize_instance(item) for item in items]


def fk_target_model(column):
    if not column.foreign_keys:
        return None
    fk = next(iter(column.foreign_keys))
    return MODEL_BY_TABLE_NAME.get(fk.column.table.name)


def field_type(column) -> str:
    if column.name in ENUM_OPTIONS:
        return "select"
    if column.foreign_keys:
        return "foreign_key"
    if isinstance(column.type, Integer):
        return "number"
    if isinstance(column.type, Float):
        return "decimal"
    if column.name.endswith("_date") or column.name.endswith("_at") or column.name.endswith("time"):
        return "datetime"
    if isinstance(column.type, Text):
        return "textarea"
    return "text"


def build_form_fields(db: Session, model, obj=None):
    fields = []
    for column in model_columns(model):
        if column.name in HIDDEN_FORM_FIELDS or column.primary_key:
            continue
        value = getattr(obj, column.name) if obj is not None else None
        required = not column.nullable and column.default is None and column.server_default is None
        ftype = field_type(column)
        field = {
            "name": column.name,
            "label": column.name.replace("_", " ").title(),
            "type": ftype,
            "required": required,
            "value": "" if value is None else value,
            "help": "",
            "choices": [],
        }
        if column.name in ENUM_OPTIONS:
            field["choices"] = ENUM_OPTIONS[column.name]
        elif column.foreign_keys:
            target_model = fk_target_model(column)
            if target_model:
                field["choices"] = [(getattr(row, primary_key_name(target_model)), display_label(row)) for row in db.query(target_model).limit(300).all()]
                field["help"] = f"Select related {target_model.__tablename__.replace('_', ' ')}"
        fields.append(field)
    return fields


def convert_value(column, value):
    if value == "" or value is None:
        return None if column.nullable or column.default is not None or column.server_default is not None else value
    if isinstance(column.type, Integer):
        return int(value)
    if isinstance(column.type, Float):
        return float(value)
    return str(value).strip()


def clean_payload(model, payload: Dict[str, Any]) -> Dict[str, Any]:
    columns = {column.name: column for column in model_columns(model)}
    data = {}
    errors = []
    for key, value in payload.items():
        if key not in columns or columns[key].primary_key:
            continue
        try:
            data[key] = convert_value(columns[key], value)
        except ValueError:
            errors.append(f"{key} has invalid value: {value}")
    for column in columns.values():
        if column.primary_key:
            continue
        required = not column.nullable and column.default is None and column.server_default is None
        if required and column.name not in data:
            errors.append(f"{column.name} is required")
    if errors:
        raise ValueError("; ".join(errors))
    return data


def list_records(db: Session, model, q: str = "", search_columns: List[str] = None, limit: int = 100, offset: int = 0):
    query = db.query(model)
    if q and search_columns:
        filters = []
        for col_name in search_columns:
            if hasattr(model, col_name):
                column = getattr(model, col_name)
                filters.append(column.ilike(f"%{q}%"))
        if filters:
            query = query.filter(or_(*filters))
    total = query.count()
    pk = getattr(model, primary_key_name(model))
    rows = query.order_by(pk.desc()).offset(offset).limit(limit).all()
    return rows, total


def create_record(db: Session, model, payload: Dict[str, Any]):
    data = clean_payload(model, payload)
    obj = model(**data)
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
    except IntegrityError as exc:
        db.rollback()
        raise ValueError(f"Database constraint error: {str(exc.orig)}") from exc
    return obj


def update_record(db: Session, model, obj_id: int, payload: Dict[str, Any]):
    obj = db.get(model, obj_id)
    if not obj:
        return None
    data = clean_payload(model, payload)
    for key, value in data.items():
        setattr(obj, key, value)
    try:
        db.commit()
        db.refresh(obj)
    except IntegrityError as exc:
        db.rollback()
        raise ValueError(f"Database constraint error: {str(exc.orig)}") from exc
    return obj


def reference_counts(db: Session, model, obj_id: int) -> List[Tuple[str, int]]:
    table_name = model.__tablename__
    counts = []
    for config in TABLES.values():
        other_model = config["model"]
        for column in other_model.__table__.columns:
            for fk in column.foreign_keys:
                if fk.column.table.name == table_name:
                    count = db.query(other_model).filter(getattr(other_model, column.name) == obj_id).count()
                    if count:
                        counts.append((other_model.__tablename__, count))
    return counts


def delete_record(db: Session, model, obj_id: int):
    obj = db.get(model, obj_id)
    if not obj:
        return False, "Record not found"
    refs = reference_counts(db, model, obj_id)
    if refs:
        detail = ", ".join([f"{count} row(s) in {table}" for table, count in refs])
        return False, f"Cannot delete this record because it is referenced by: {detail}. Update or remove the child records first."
    db.delete(obj)
    try:
        db.commit()
        return True, "Deleted successfully"
    except IntegrityError as exc:
        db.rollback()
        return False, f"Delete blocked by database constraint: {str(exc.orig)}"
