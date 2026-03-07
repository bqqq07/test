# === Imports ===
import os, logging, urllib.parse
from datetime import datetime, date, timedelta
from typing import Tuple
from functools import wraps
from collections import defaultdict
from flask import (
    Flask, render_template, request, redirect, url_for,
    session, flash, abort, g, Response, current_app
)
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import UniqueConstraint, or_, func, text
from typing import Optional
from datetime import timezone
from zoneinfo import ZoneInfo  # بايثون 3.9+ موجودة افتراضيًا

# === Paths (عرّف BASE_DIR أولاً) ===
BASE_DIR = os.path.abspath(os.path.dirname(__file__))

# === Flask app ===
app = Flask(__name__, template_folder="templates", static_folder="static")
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "set-a-strong-secret")
app.config["SQLALCHEMY_ECHO"] = True  # مؤقتاً للتشخيص
application = app 

# (اختياري) logging بعد إنشاء app
try:
    os.makedirs(os.path.join(BASE_DIR, "tmp"), exist_ok=True)
    fh = logging.FileHandler(os.path.join(BASE_DIR, "tmp", "app.log"))
    fh.setLevel(logging.INFO)
    app.logger.setLevel(logging.INFO)
    app.logger.addHandler(fh)
    app.logger.info("App booted")
except Exception as e:
    print("log init error:", e)

import os
import urllib.parse
from flask_sqlalchemy import SQLAlchemy

# ---- Database (FORCE MySQL ONLY) ----

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "zappimiw_nsh")
DB_USER = os.getenv("DB_USER", "zappimiw_nsh")
DB_PASS = os.getenv("DB_PASS", "Hg.gtd123@@@")

# تأكد أن كل القيم موجودة
if not all([DB_HOST, DB_NAME, DB_USER, DB_PASS]):
    raise Exception("❌ Database environment variables are missing")

# ترميز كلمة المرور
safe_pass = urllib.parse.quote_plus(DB_PASS)

# ربط MySQL فقط (بدون SQLite نهائياً)
app.config["SQLALCHEMY_DATABASE_URI"] = (
    f"mysql+pymysql://{DB_USER}:{safe_pass}@{DB_HOST}/{DB_NAME}?charset=utf8mb4"
)

app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config.setdefault("SQLALCHEMY_ENGINE_OPTIONS", {"pool_pre_ping": True})

db = SQLAlchemy(app)

# طباعة للتأكد
print("USING DATABASE:", app.config["SQLALCHEMY_DATABASE_URI"])
from werkzeug.exceptions import NotFound

@app.before_request
def load_logged_in_user():
    if request.endpoint and request.endpoint.startswith('static'):
        return
    user_id = session.get("user_id")
    g.user = db.session.get(User, user_id) if user_id else None
    g.role = g.user.role if g.user else None


# ===================== Constants =====================
WEIGHTS = {
    "targets_rows": 4,
    "target_per_row": 10,
    "perf_items": {
        "punctuality": 10,
        "quality": 10,
        "productivity": 10,
        "communication": 10,
        "problemsolving": 10,
        "compliance": 10,
    },
    "perf_scale_max": 5,
    "bands": {"excellent": 90, "good": 80, "satisfactory": 70},
}

SE_WEIGHTS = {
    "perf_items": {
        "leadership": 1,
        "communication": 1,
        "scheduling": 1,
        "compliance": 1,
        "team_support": 1,
        "reporting": 1,
    },
    "perf_scale_max": 5,
    "bands": {"excellent": 90, "good": 80, "satisfactory": 70},
}

# Week definition: Sunday → Thursday (Python weekday: Mon=0 ... Sun=6)
WEEK_START_WEEKDAY = 6  # Sunday
WEEK_END_WEEKDAY = 3    # Thursday


RIYADH_TZ = ZoneInfo("Asia/Riyadh")

def to_local(dt):
    if dt is None:
        return None
    # لو التاريخ naive (بدون tzinfo)، اعتبره UTC لأنه محفوظ بـ utcnow()
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(RIYADH_TZ)
    
@app.template_filter("local_dt")
def local_dt(dt, fmt="%Y-%m-%d %H:%M"):
    dt_local = to_local(dt)
    return dt_local.strftime(fmt) if dt_local else "—"
    
# ===================== Models =====================
# ========== Model: Request ==========
class Request(db.Model):
    __tablename__ = "requests"
    id = db.Column(db.Integer, primary_key=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    supervisor_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)      # كان users.id
    supervisor = db.relationship("User", foreign_keys=[supervisor_id])

    employee_id = db.Column(db.Integer, db.ForeignKey("employee.id"), nullable=False)    # كان employees.id
    employee = db.relationship("Employee", foreign_keys=[employee_id])

    type = db.Column(db.String(32), nullable=False, default="leave")
    start_date = db.Column(db.Date, nullable=True)
    end_date   = db.Column(db.Date, nullable=True)
    reason = db.Column(db.Text, nullable=True)

    status = db.Column(db.String(16), nullable=False, default="pending")
    decided_by = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=True)          # كان users.id
    decided_at = db.Column(db.DateTime, nullable=True)
    admin_comment = db.Column(db.Text, nullable=True)

    __table_args__ = (
        db.Index("ix_requests_emp_created", "employee_id", "created_at"),
        db.Index("ix_requests_status", "status"),
    )

class HRTask(db.Model):
    __tablename__ = "hr_task"
    id          = db.Column(db.Integer, primary_key=True)
    request_id  = db.Column(db.Integer, db.ForeignKey("requests.id"), nullable=False, unique=True)
    employee_id = db.Column(db.Integer, db.ForeignKey("employee.id"), nullable=False)
    type        = db.Column(db.String(32), nullable=False)  # مطابق ل requests.type
    status      = db.Column(db.String(16), nullable=False, default="pending")  # pending/applied/cancelled
    created_at  = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    applied_at  = db.Column(db.DateTime, nullable=True)
    applied_by  = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=True)

    request  = db.relationship("Request",  foreign_keys=[request_id])
    employee = db.relationship("Employee", foreign_keys=[employee_id])

# ===================== Models =====================

# تأكد إنك مستورد Employee و User قبل هذا الموديل
# from your_module import Employee, User  # أو حسب مكانهم

class DailyEvaluation(db.Model):
    __tablename__ = "daily_evaluation"
    id = db.Column(db.Integer, primary_key=True)

    # FK صحيحة: employee (مفرد) و user
    employee_id  = db.Column(db.Integer, db.ForeignKey("employee.id"), nullable=False)
    evaluator_id = db.Column(db.Integer, db.ForeignKey("user.id"),     nullable=False)

    eval_date = db.Column(db.Date, nullable=False)

    # Targets
    t1_text = db.Column(db.Text); t1_percent = db.Column(db.Float); t1_remarks = db.Column(db.Text)
    t2_text = db.Column(db.Text); t2_percent = db.Column(db.Float); t2_remarks = db.Column(db.Text)
    t3_text = db.Column(db.Text); t3_percent = db.Column(db.Float); t3_remarks = db.Column(db.Text)
    t4_text = db.Column(db.Text); t4_percent = db.Column(db.Float); t4_remarks = db.Column(db.Text)

    # Performance + comments
    p_punctuality = db.Column(db.Integer);    c_punctuality = db.Column(db.Text)
    p_quality = db.Column(db.Integer);        c_quality = db.Column(db.Text)
    p_productivity = db.Column(db.Integer);   c_productivity = db.Column(db.Text)
    p_communication = db.Column(db.Integer);  c_communication = db.Column(db.Text)
    p_problemsolving = db.Column(db.Integer); c_problemsolving = db.Column(db.Text)
    p_compliance = db.Column(db.Integer);     c_compliance = db.Column(db.Text)

    strengths = db.Column(db.Text)
    improvements = db.Column(db.Text)
    training_needed = db.Column(db.Text)

    targets_score = db.Column(db.Float)
    performance_score = db.Column(db.Float)
    total_score = db.Column(db.Float)
    overall_band = db.Column(db.String(30))

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint("employee_id", "eval_date", name="uq_daily_emp_date"),
    )

    # (اختياري لطيف) علاقات ORM
    employee  = db.relationship("Employee", backref=db.backref("daily_evaluations", lazy="dynamic"))
    evaluator = db.relationship("User",     backref=db.backref("daily_evaluations_given", lazy="dynamic"))




def compute_daily_scores(de: "DailyEvaluation") -> None:
    # نحسب الأداء فقط (لو حاب تحسب targets اليومية أضف معادلتها وادمجها)
    items = [
        de.p_punctuality, de.p_quality, de.p_productivity,
        de.p_communication, de.p_problemsolving, de.p_compliance
    ]
    per_item_weight = 100.0 / len(items)
    p_score = 0.0
    for r in items:
        r = int(r or 0)
        p_score += (r / WEIGHTS["perf_scale_max"]) * per_item_weight

    total = round(p_score, 2)
    if total >= WEIGHTS["bands"]["excellent"]:
        band = "Excellent"
    elif total >= WEIGHTS["bands"]["good"]:
        band = "Good"
    elif total >= WEIGHTS["bands"]["satisfactory"]:
        band = "Satisfactory"
    else:
        band = "Needs Improvement"

    de.perf_score = total
    # إن أردت دمج targets في المجموع اليومي، احسبها وخزنها في targets_score ثم:
    # de.total_score = round((targets_component) + p_score, 2)
    de.total_score = total
    de.overall_band = band


class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    supervisor_code = db.Column(db.String(50), unique=True, nullable=False)
    name = db.Column(db.String(120), default="")
    role = db.Column(db.String(20), default="supervisor")  # supervisor | admin | site_supervisor
    is_active = db.Column(db.Boolean, default=True)
    @property
    def is_supervisor(self):
        return self.role in ("supervisor", "site_supervisor")

class Employee(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    emp_number = db.Column(db.String(50), nullable=False, unique=True)
    name = db.Column(db.String(120), nullable=False)
    department = db.Column(db.String(120), default="")
    site = db.Column(db.String(120), default="")
    is_active = db.Column(db.Boolean, default=True)
    

class Evaluation(db.Model):
    __table_args__ = (UniqueConstraint("employee_id", "week_start", "week_end", name="uq_emp_week"),)
    id = db.Column(db.Integer, primary_key=True)
    employee_id = db.Column(db.Integer, db.ForeignKey("employee.id"), nullable=False)
    evaluator_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)

    week_start = db.Column(db.Date, nullable=False)
    week_end   = db.Column(db.Date, nullable=False)

    # Targets (4 rows)
    t1_text = db.Column(db.String(255), default=""); t1_percent = db.Column(db.Float, default=0); t1_remarks = db.Column(db.String(255), default="")
    t2_text = db.Column(db.String(255), default=""); t2_percent = db.Column(db.Float, default=0); t2_remarks = db.Column(db.String(255), default="")
    t3_text = db.Column(db.String(255), default=""); t3_percent = db.Column(db.Float, default=0); t3_remarks = db.Column(db.String(255), default="")
    t4_text = db.Column(db.String(255), default=""); t4_percent = db.Column(db.Float, default=0); t4_remarks = db.Column(db.String(255), default="")

    # Performance (ratings 1..5 + comments)
    p_punctuality = db.Column(db.Integer, default=0); c_punctuality = db.Column(db.String(255), default="")
    p_quality = db.Column(db.Integer, default=0); c_quality = db.Column(db.String(255), default="")
    p_productivity = db.Column(db.Integer, default=0); c_productivity = db.Column(db.String(255), default="")
    p_communication = db.Column(db.Integer, default=0); c_communication = db.Column(db.String(255), default="")
    p_problemsolving = db.Column(db.Integer, default=0); c_problemsolving = db.Column(db.String(255), default="")
    p_compliance = db.Column(db.Integer, default=0); c_compliance = db.Column(db.String(255), default="")

    strengths = db.Column(db.Text, default="")
    improvements = db.Column(db.Text, default="")
    training_needed = db.Column(db.Text, default="")

    targets_score = db.Column(db.Float, default=0)
    perf_score    = db.Column(db.Float, default=0)
    total_score   = db.Column(db.Float, default=0)
    overall_band  = db.Column(db.String(30), default="")

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class SiteSupervisorMap(db.Model):
    __table_args__ = (UniqueConstraint("site_sup_id", "supervisor_id", name="uq_site_sup_pair"),)
    id = db.Column(db.Integer, primary_key=True)
    site_sup_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    supervisor_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)

class SupervisorEvaluation(db.Model):
    __table_args__ = (UniqueConstraint("supervisor_id", "week_start", "week_end", name="uq_sup_week"),)
    id = db.Column(db.Integer, primary_key=True)
    supervisor_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    evaluator_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)

    week_start = db.Column(db.Date, nullable=False)
    week_end   = db.Column(db.Date, nullable=False)

    # Targets (4 rows)
    t1_text = db.Column(db.String(255), default=""); t1_percent = db.Column(db.Float, default=0); t1_remarks = db.Column(db.String(255), default="")
    t2_text = db.Column(db.String(255), default=""); t2_percent = db.Column(db.Float, default=0); t2_remarks = db.Column(db.String(255), default="")
    t3_text = db.Column(db.String(255), default=""); t3_percent = db.Column(db.Float, default=0); t3_remarks = db.Column(db.String(255), default="")
    t4_text = db.Column(db.String(255), default=""); t4_percent = db.Column(db.Float, default=0); t4_remarks = db.Column(db.String(255), default="")

    # Performance (ratings 1..5 + comments)
    p_punctuality = db.Column(db.Integer, default=0); c_punctuality = db.Column(db.String(255), default="")
    p_quality = db.Column(db.Integer, default=0); c_quality = db.Column(db.String(255), default="")
    p_productivity = db.Column(db.Integer, default=0); c_productivity = db.Column(db.String(255), default="")
    p_communication = db.Column(db.Integer, default=0); c_communication = db.Column(db.String(255), default="")
    p_problemsolving = db.Column(db.Integer, default=0); c_problemsolving = db.Column(db.String(255), default="")
    p_compliance = db.Column(db.Integer, default=0); c_compliance = db.Column(db.String(255), default="")

    strengths = db.Column(db.Text, default="")
    improvements = db.Column(db.Text, default="")
    training_needed = db.Column(db.Text, default="")

    targets_score = db.Column(db.Float, default=0)
    perf_score    = db.Column(db.Float, default=0)
    total_score   = db.Column(db.Float, default=0)
    overall_band  = db.Column(db.String(30), default="")

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
class Attendance(db.Model):
    __table_args__ = (UniqueConstraint("employee_id", "date", name="uq_emp_date"),)
    id = db.Column(db.Integer, primary_key=True)
    employee_id = db.Column(db.Integer, db.ForeignKey("employee.id"), nullable=False)
    supervisor_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    date = db.Column(db.Date, nullable=False)
    status = db.Column(db.String(20), nullable=False)  # present / absent / leave
    remarks = db.Column(db.String(255), default="")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    employee = db.relationship("Employee", backref="attendances")
    supervisor = db.relationship("User", backref="attendances")


# ===================== Helpers =====================
def _apply_leave_attendance_for_request(req: Request):
    """
    يعلّم حضور الموظّف كـ Leave لكل يوم بين start_date و end_date (شاملاً).
    يتعامل مع التكرار (يحدّث السجل إن وُجد أو ينشئه إن لم يوجد).
    نستخدم supervisor_id من الطلب لأنه مطلوب في Attendance.
    نضع وسم صغير في remarks لتمييز السجلات المرتبطة بهذا الطلب (للتراجع إن لزم).
    """
    if not (req and req.employee_id and req.start_date and req.end_date):
        return

    marker = f"auto_leave_req_{req.id}"
    cur = req.start_date
    while cur <= req.end_date:
        rec = Attendance.query.filter_by(employee_id=req.employee_id, date=cur).first()
        if rec:
            # غيّر الحالة إلى إجازة
            rec.status = "leave"
            # أضف الوسم إذا مو موجود
            if marker not in (rec.remarks or ""):
                rec.remarks = (rec.remarks + " " + marker).strip() if rec.remarks else marker
        else:
            # أنشئ سجل جديد (supervisor_id مطلوب)
            rec = Attendance(
                employee_id=req.employee_id,
                supervisor_id=req.supervisor_id,  # صاحب الطلب
                date=cur,
                status="leave",
                remarks=marker,
            )
            db.session.add(rec)
        cur += timedelta(days=1)

def get_employee_summary(emp_id: int):
    # الحضور/الغياب آخر 90 يوم
    since = date.today() - timedelta(days=90)
    total_days = 0
    present = 0
    absent = 0

    # عدّل أسماء الموديلات والحقول حسب مشروعك
    # نفترض Attendance(date=..., status in {"present","absent"})
    q_att = Attendance.query.filter(
        Attendance.employee_id == emp_id,
        Attendance.date >= since
    ).all()
    for a in q_att:
        total_days += 1
        if (a.status or "").lower() == "present":
            present += 1
        elif (a.status or "").lower() == "absent":
            absent += 1

    # متوسط تقييم أسبوعي آخر 8 أسابيع
    # نفترض Evaluation(total_score)
    weeks_since = date.today() - timedelta(days=7*8)
    evals = Evaluation.query.filter(
        Evaluation.employee_id == emp_id,
        Evaluation.week_start >= weeks_since
    ).all()
    avg_score = round(sum((e.total_score or 0) for e in evals) / len(evals), 2) if evals else None

    return {
        "since": since,
        "total_days": total_days,
        "present": present,
        "absent": absent,
        "avg_score_8w": avg_score,
        "eval_count_8w": len(evals),
    }
    
# ✅ استبدل الدالة بالكامل بهذا الإصدار
def aggregate_week_from_dailies(emp_id: int, ws: date, we: date) -> Optional[Evaluation]:
    # اجلب الأيام (أحد..خميس)
    dailies = (DailyEvaluation.query
               .filter(DailyEvaluation.employee_id == emp_id,
                       DailyEvaluation.eval_date >= ws,
                       DailyEvaluation.eval_date <= we)
               .all())
    if not dailies:
        return None

    n = len(dailies)
    # متوسط الأرقام من الحقول الصحيحة
    avg_targets = sum((d.targets_score or 0) for d in dailies) / n
    # كان خطأ: d.perf_score  ← اليومي يستخدم performance_score
    avg_perf    = sum((d.performance_score or 0) for d in dailies) / n
    # نجمع المتوسطين بدل متوسط total اليومي
    avg_total   = round(avg_targets + avg_perf, 2)

    # حدد Band
    if   avg_total >= WEIGHTS["bands"]["excellent"]:
        band = "Excellent"
    elif avg_total >= WEIGHTS["bands"]["good"]:
        band = "Good"
    elif avg_total >= WEIGHTS["bands"]["satisfactory"]:
        band = "Satisfactory"
    else:
        band = "Needs Improvement"

    # أنشئ/حدّث Evaluation الأسبوعي
    ev = Evaluation.query.filter_by(employee_id=emp_id, week_start=ws, week_end=we).first()
    if not ev:
        # نأخذ آخر مُقيّم يومي كـ evaluator (أو مدير الموظف إذا تحب)
        last_evaluator = max(dailies, key=lambda d: d.created_at).evaluator_id
        ev = Evaluation(employee_id=emp_id, evaluator_id=last_evaluator,
                        week_start=ws, week_end=we)
        db.session.add(ev)

    ev.targets_score = round(avg_targets, 2)
    ev.perf_score    = round(avg_perf, 2)
    ev.total_score   = avg_total
    ev.overall_band  = band

    db.session.commit()
    return ev


def previous_week_range(ws: date) -> Tuple[date, date]:
    prev_ws = ws - timedelta(days=7)
    prev_we = prev_ws + timedelta(days=4)
    return prev_ws, prev_we


def compute_supervisor_scores(se: SupervisorEvaluation) -> None:
    items = {
        "leadership": getattr(se, "p_leadership", 0),
        "communication": se.p_communication,
        "scheduling": getattr(se, "p_scheduling", 0),
        "compliance": se.p_compliance,
        "team_support": getattr(se, "p_team_support", 0),
        "reporting": getattr(se, "p_reporting", 0),
    }
    per_item_weight = 100.0 / len(items)
    p_score = 0.0
    for _, rating in items.items():
        rating = int(rating or 0)
        p_score += (rating / SE_WEIGHTS["perf_scale_max"]) * per_item_weight

    total = round(p_score, 2)
    if total >= SE_WEIGHTS["bands"]["excellent"]:
        band = "Excellent"
    elif total >= SE_WEIGHTS["bands"]["good"]:
        band = "Good"
    elif total >= SE_WEIGHTS["bands"]["satisfactory"]:
        band = "Satisfactory"
    else:
        band = "Needs Improvement"

    se.perf_score = total
    se.total_score = total
    se.overall_band = band

def default_week_today() -> Tuple[date, date]:
    today = date.today()
    days_since_sun = (today.weekday() - WEEK_START_WEEKDAY) % 7
    start = today - timedelta(days=days_since_sun)
    end = start + timedelta(days=4)
    return start, end

def ensure_db_and_admin() -> None:
    """Create DB tables and bootstrap admin if ADMIN_ID is set."""
    with app.app_context():
        db.create_all()
        admin_id = os.environ.get("ADMIN_ID")
        if admin_id:
            existing = User.query.filter_by(supervisor_code=admin_id).first()
            if not existing:
                admin = User(supervisor_code=admin_id, name="Admin", role="admin", is_active=True)
                db.session.add(admin)
                db.session.commit()
                
# ===== Helpers missing / fixes =====
def parse_date(s: str) -> date:
    return datetime.strptime(s, "%Y-%m-%d").date()

def validate_week_sun_to_thu(ws: date, we: date):
    # Sun=6, Thu=3
    if ws.weekday() != 6 or we.weekday() != 3:
        return False, "Week must be Sunday → Thursday."
    if (we - ws).days != 4:
        return False, "Week should be exactly 5 days (Sun→Thu)."
    return True, ""
def _safe_date(s):
    """Parse date or return None if invalid/empty."""
    try:
        return parse_date(s) if s else None
    except Exception:
        return None

WEEK_START_WEEKDAY = 6  # Sunday (Mon=0..Sun=6)
WEEK_END_WEEKDAY   = 3  # Thursday
def cur_user():
    uid = session.get("user_id")
    return db.session.get(User, uid) if uid else None

def login_required(f):
    @wraps(f)
    def inner(*args, **kwargs):
        if not cur_user():
            return redirect(url_for("login"))
        return f(*args, **kwargs)
    return inner

def admin_required(f):
    @wraps(f)
    def inner(*args, **kwargs):
        u = cur_user()
        if not u or u.role != "admin":
            return redirect(url_for("login"))
        return f(*args, **kwargs)
    return inner

def hr_required(f):
    @wraps(f)
    def inner(*args, **kwargs):
        u = cur_user()
        if not u or u.role != "hr":
            return redirect(url_for("login"))
        return f(*args, **kwargs)
    return inner

# يحدد مشرفًا من نص البحث (ID مطابق أو اسم مطابق بالكامل)
# يحدد مشرفًا من نص البحث (ID مطابق أو اسم مطابق بالكامل)
def find_supervisor_from_query(q: str):
    if not q:
        return None
    q = q.strip()
    # جرّب Supervisor ID (supervisor_code) أولًا
    sup = User.query.filter(
        User.role == "supervisor",
        User.supervisor_code == q
    ).first()
    if sup:
        return sup
    # جرّب اسم مطابق بالكامل (case-insensitive)
    return (User.query
            .filter(User.role == "supervisor",
                    func.lower(User.name) == q.lower())
            .first())


# ===================== Auth & Helpers =====================


def parse_date(s: str) -> date:
    """يحاول تحويل نص 'YYYY-MM-DD' إلى كائن تاريخ."""
    return datetime.strptime(s, "%Y-%m-%d").date()

def validate_week_sun_to_thu(ws: date, we: date) -> tuple[bool, str]:
    """يتأكد أن الأسبوع يبدأ أحد وينتهي خميس ومدته 5 أيام."""
    if not ws or not we:
        return False, "Invalid week dates."
    if we < ws:
        return False, "Week end before start."
    if (we - ws).days != 4:
        return False, "Week must be 5 days (Sun→Thu)."
    if ws.weekday() != WEEK_START_WEEKDAY or we.weekday() != WEEK_END_WEEKDAY:
        return False, "Week must start on Sunday and end on Thursday."
    return True, ""

# ✅ هذه النسخة هي المعتمدة للأسبوعي فقط
def compute_scores(
    ev,
    target_percent_attrs=("t1_percent","t2_percent","t3_percent","t4_percent"),
    rating_attrs=("p_punctuality","p_quality","p_productivity",
                  "p_communication","p_problemsolving","p_compliance"),
):
    def clamp(x, lo, hi):
        try:
            return max(lo, min(hi, x))
        except Exception:
            return lo

    # ===== Targets (40) =====
    target_values = []
    for attr in target_percent_attrs:
        v = getattr(ev, attr, None)
        try:
            v = float(v) if v not in (None, "") else 0.0
        except Exception:
            v = 0.0
        target_values.append(clamp(v, 0.0, 100.0))

    n_targets = len(target_values) or 1
    per_target_points = 40.0 / n_targets
    ev.targets_score = round(sum((v / 100.0) * per_target_points for v in target_values), 2)

    # ===== Performance (60) — الآن الافتراضي 0 =====
    rating_values = []
    for attr in rating_attrs:
        raw = getattr(ev, attr, None)

        # لو فاضية أو None → 0
        if raw in (None, "", 0):
            r = 0
        else:
            try:
                r = int(raw)
            except Exception:
                r = 0

        # خليه يقبل 0 إلى 5
        rating_values.append(clamp(r, 0, 5))

    n_ratings = len(rating_values) or 1
    per_item_points = 60.0 / n_ratings
    ev.perf_score = round(sum((r / 5.0) * per_item_points for r in rating_values), 2)

    # ===== Total & Band =====
    ev.total_score = round(ev.targets_score + ev.perf_score, 2)
    ev.overall_band = ("Excellent" if ev.total_score >= 90 else
                       "Good" if ev.total_score >= 80 else
                       "Satisfactory" if ev.total_score >= 70 else
                       "Needs Improvement")

# (اختياري) لو عندك استدعاءات قديمة:
# compute_weekly_scores = compute_scores
                       
# ==== Auth & helpers glue (ضعها بعد الـ Helpers) ====


# 5) parse_date بسيطة متسامحة مع YYYY-MM-DD
def parse_date(s: str) -> date:
    s = (s or "").strip()
    try:
        return date.fromisoformat(s)          # 2025-10-16
    except Exception:
        # fallback: dd/mm/yyyy أو dd-mm-yyyy
        for sep in ("/", "-"):
            parts = s.split(sep)
            if len(parts) == 3 and len(parts[0]) <= 2:
                d, m, y = map(int, parts)
                return date(y, m, d)
        raise

# 6) تحقق أن الأسبوع أحد→خميس
def validate_week_sun_to_thu(ws: date, we: date):
    if not ws or not we:
        return False, "Week start/end are required."
    if we != ws + timedelta(days=4):
        return False, "Week must be 5 days (Sun→Thu)."
    if ws.weekday() != WEEK_START_WEEKDAY or we.weekday() != WEEK_END_WEEKDAY:
        return False, "Start must be Sunday and end must be Thursday."
    return True, ""
# --- Safe scoring function for daily evaluation ---

# --- Safe scoring function for daily evaluation ---
def compute_daily_scores(de):
    """
    حساب الديلي بناءً على البنود المدخلة فقط.
    """
    # ===== Daily Targets (40) =====
    filled_percents = []
    for i in range(1, 5):
        txt = getattr(de, f"t{i}_text", "") or ""
        pct = getattr(de, f"t{i}_percent", 0) or 0
        try:
            pct = float(pct)
        except Exception:
            pct = 0.0

        # احسبه لو فيه نص أو نسبة
        if txt.strip() or pct > 0:
            pct = max(0.0, min(100.0, pct))
            filled_percents.append(pct)

    if filled_percents:
        n_targets = len(filled_percents)
        per_target_points = 40.0 / n_targets
        de.targets_score = round(
            sum((p / 100.0) * per_target_points for p in filled_percents),
            2
        )
    else:
        de.targets_score = 0.0

    # ===== Performance (60) =====
    rating_fields = [
        "p_punctuality",
        "p_quality",
        "p_productivity",
        "p_communication",
        "p_problemsolving",
        "p_compliance",
    ]
    rating_values = []
    for f in rating_fields:
        r = getattr(de, f, 0) or 0
        try:
            r = int(r)
        except Exception:
            r = 0
        r = max(0, min(5, r))
        rating_values.append(r)

    if rating_values:
        n_ratings = len(rating_values)
        per_item_points = 60.0 / n_ratings
        de.perf_score = round(
            sum((r / 5.0) * per_item_points for r in rating_values),
            2
        )
    else:
        de.perf_score = 0.0

    # ===== Total & Band =====
    de.total_score = round(de.targets_score + de.perf_score, 2)
    de.overall_band = (
        "Excellent" if de.total_score >= 90 else
        "Good" if de.total_score >= 80 else
        "Satisfactory" if de.total_score >= 70 else
        "Needs Improvement"
    )


@app.get("/logo")
def logo():
    return app.send_static_file("img/logo.png")
    

@app.route("/daily2/evaluate/<int:emp_id>/new", methods=["GET", "POST"])
@login_required
def daily2_evaluate_new(emp_id):
    u = cur_user()
    emp = (Employee.query.get_or_404(emp_id) if u.role=="admin"
           else Employee.query.filter_by(id=emp_id, user_id=u.id).first_or_404())

    if request.method == "POST":
        # تاريخ اليوم أو اللي اختاره
        d_raw = request.form.get("eval_date") or date.today().isoformat()
        y, m, d = map(int, d_raw.split("-"))
        eval_date = date(y, m, d)

        # منع تكرار نفس اليوم
        exists = DailyEvaluation.query.filter_by(employee_id=emp.id, eval_date=eval_date).first()
        if exists:
            flash("Daily evaluation for this date already exists.", "warning")
            return redirect(url_for("daily_report_employee", emp_id=emp.id, d=eval_date.isoformat()))

        de = DailyEvaluation(
            employee_id=emp.id,
            evaluator_id=u.id,
            eval_date=eval_date,

            # Daily targets
            t1_text=request.form.get("t1_text",""),
            t1_percent=request.form.get("t1_percent") or 0,
            t1_remarks=request.form.get("t1_remarks",""),
            t2_text=request.form.get("t2_text",""),
            t2_percent=request.form.get("t2_percent") or 0,
            t2_remarks=request.form.get("t2_remarks",""),
            t3_text=request.form.get("t3_text",""),
            t3_percent=request.form.get("t3_percent") or 0,
            t3_remarks=request.form.get("t3_remarks",""),
            t4_text=request.form.get("t4_text",""),
            t4_percent=request.form.get("t4_percent") or 0,
            t4_remarks=request.form.get("t4_remarks",""),

            # Performance
            p_punctuality=request.form.get("p_punctuality", type=int),
            c_punctuality=request.form.get("c_punctuality",""),
            p_quality=request.form.get("p_quality", type=int),
            c_quality=request.form.get("c_quality",""),
            p_productivity=request.form.get("p_productivity", type=int),
            c_productivity=request.form.get("c_productivity",""),
            p_communication=request.form.get("p_communication", type=int),
            c_communication=request.form.get("c_communication",""),
            p_problemsolving=request.form.get("p_problemsolving", type=int),
            c_problemsolving=request.form.get("c_problemsolving",""),
            p_compliance=request.form.get("p_compliance", type=int),
            c_compliance=request.form.get("c_compliance",""),

            strengths=request.form.get("strengths",""),
            improvements=request.form.get("improvements",""),
            training_needed=request.form.get("training_needed",""),
        )

        compute_daily_scores(de)
        db.session.add(de)
        db.session.commit()

        flash("Daily evaluation saved.", "success")
        return redirect(url_for("daily_report_employee", emp_id=emp.id, d=eval_date.isoformat()))

    # GET
    today = date.today()
    return render_template("daily_eval_form_v2.html", employee=emp, d=today, weights=WEIGHTS)
    
@app.route("/daily2/reports/employee/<int:emp_id>")
@login_required
def daily2_report_employee(emp_id):
    u = cur_user()
    emp = (Employee.query.get_or_404(emp_id) if u.role == "admin"
           else Employee.query.filter_by(id=emp_id, user_id=u.id).first_or_404())

    d_str = request.args.get("d")
    if not d_str:
        flash("Missing date.", "warning")
        return redirect(url_for("employees"))

    d_val = date.fromisoformat(d_str)
    de = DailyEvaluation.query.filter_by(employee_id=emp.id, eval_date=d_val).first_or_404()

    evaluator = db.session.get(User, de.evaluator_id)
    return render_template(
        "daily_report_employee_v2.html",
        employee=emp,
        de=de,
        evaluator_code=evaluator.supervisor_code if evaluator else "",
        evaluator_name=(evaluator.name if (evaluator and evaluator.name) else "")
    )


# ===================== Routes =====================
@app.route("/requests/new", methods=["GET", "POST"])
@login_required
def request_new():
    u = cur_user()
    if not (u and getattr(u, "role", None) in ("supervisor", "site_supervisor", "admin")):
        abort(403)

    # فلترة موظفي المشرف فقط (حسب ما طبّقناه سابقًا بالـ join على User أو user_id=u.id)
    employees = (Employee.query
                 .filter_by(user_id=u.id, is_active=True)
                 .order_by(Employee.name.asc())
                 .all())

    def _parse_date(s):
        s = (s or "").strip()
        if not s: return None
        from datetime import datetime
        try: return datetime.strptime(s, "%Y-%m-%d").date()
        except: return None

    if request.method == "POST":
        # التقاط
        emp_id     = request.form.get("employee_id")
        rtype      = (request.form.get("type") or "").strip().lower()
        reason     = (request.form.get("reason") or "").strip()
        start_date = _parse_date(request.form.get("start_date"))
        end_date   = _parse_date(request.form.get("end_date"))
        from_time  = (request.form.get("from_time") or "").strip()
        to_time    = (request.form.get("to_time") or "").strip()
        priority   = (request.form.get("priority") or "").strip().lower()

        # تحقق أساسي
        try: emp_id = int(emp_id or 0)
        except: emp_id = 0
        emp = Employee.query.get(emp_id) if emp_id else None
        if not emp or emp.user_id != u.id:
            flash("Please choose a valid employee.", "danger")
            return render_template("requests_new.html", employees=employees,
                                   pre_emp_id=emp_id, pre_type=rtype,
                                   pre_start=request.form.get("start_date"),
                                   pre_end=request.form.get("end_date"),
                                   pre_from_time=from_time, pre_to_time=to_time,
                                   pre_priority=priority, pre_reason=reason)

        # قواعد خفيفة لكل نوع (بدون ترحيل DB)
        if rtype in {"leave","shift","overtime","absence","late"}:
            if not start_date:
                flash("Start date is required for the selected type.", "danger")
                return render_template("requests_new.html", employees=employees,
                                       pre_emp_id=emp_id, pre_type=rtype,
                                       pre_start=request.form.get("start_date"),
                                       pre_end=request.form.get("end_date"),
                                       pre_priority=priority, pre_reason=reason)
        if rtype == "permission":
            # ننسّق الوقت داخل الـ reason
            tag = f"[Permission {from_time or '?'}→{to_time or '?'}]"
            reason = f"{tag} {reason}".strip()
            # تواريخ ليست مطلوبة هنا
            start_date = start_date or None
            end_date   = end_date or None
        if rtype == "warning":
            # نضيف أولوية لو موجودة
            if priority in {"low","normal","high"}:
                reason = f"[Warning {priority}] {reason}".strip()

        # الإنشاء
        r = Request(
            supervisor_id=u.id,
            employee_id=emp.id,
            type=rtype if rtype in {"leave","permission","warning","late","other"} else "other",
            start_date=start_date,
            end_date=end_date,
            reason=reason,
            status="pending",
        )
        db.session.add(r); db.session.commit()
        flash("Request submitted.", "success")
        return redirect(url_for("requests_mine"))

    # GET
    return render_template("requests_new.html", employees=employees,
                           pre_emp_id=None, pre_type="leave")



@app.route("/requests/mine")
@login_required
def requests_mine():
    u = cur_user()
    # الطلبات التي قدّمها هذا المستخدم (سوبرفايزر)
    reqs = Request.query.filter(Request.supervisor_id == u.id) \
                        .order_by(Request.created_at.desc()).all()
    return render_template("requests_mine.html", rows=reqs)


@app.post("/daily/aggregate/week")
@login_required
def daily_aggregate_week():
    # احصل على أسبوع مستهدف
    ws = parse_date(request.form.get("week_start"))
    we = parse_date(request.form.get("week_end"))
    ok, msg = validate_week_sun_to_thu(ws, we)
    if not ok:
        flash(msg, "danger")
        return redirect(request.referrer or url_for("admin_report_picker"))

    u = cur_user()
    # من يشمل؟
    if u.role == "admin":
        emp_ids = [e.id for e in Employee.query.filter_by(is_active=True).all()]
    else:
        emp_ids = [e.id for e in Employee.query.filter_by(user_id=u.id, is_active=True).all()]

    done = 0
    for emp_id in emp_ids:
        if aggregate_week_from_dailies(emp_id, ws, we):
            done += 1

    flash(f"Aggregated weekly evaluations for {done} employees.", "success")
    # رجّع للأدمن إلى /admin/reports/all أو للمشرف لصفحته
    if u.role == "admin":
        return redirect(url_for("admin_reports_all",
                                week_start=ws.isoformat(), week_end=we.isoformat()))
    return redirect(url_for("report_supervisor",
                            week_start=ws.isoformat(), week_end=we.isoformat()))



@app.route("/admin/employee/<int:emp_id>/summary", methods=["GET"])
@login_required
@admin_required
def employee_summary(emp_id):
    emp = Employee.query.get_or_404(emp_id)
    summary = get_employee_summary(emp_id)
    return render_template("employee_summary.html", emp=emp, summary=summary)


@app.route("/daily/evaluate/<int:emp_id>/new", methods=["GET", "POST"])
@login_required
def daily_evaluate_new(emp_id):
    u = cur_user()
    # المشرف يشوف موظفينه فقط، الأدمن يشوف الكل
    emp = (Employee.query.get_or_404(emp_id) if u.role=="admin"
           else Employee.query.filter_by(id=emp_id, user_id=u.id).first_or_404())

    if request.method == "POST":
        try:
            # 1) التاريخ
            eval_date_raw = request.form.get("eval_date")
            if not eval_date_raw:
                flash("Date is required.", "danger")
                return redirect(url_for("daily_evaluate_new", emp_id=emp.id))
            eval_date = parse_date(eval_date_raw)  # تأكد إنها موجودة: strptime("%Y-%m-%d")

            # 2) منع التكرار
            exists = DailyEvaluation.query.filter_by(
                employee_id=emp.id, eval_date=eval_date
            ).first()
            if exists:
                flash("A daily evaluation for this date already exists.", "warning")
                return redirect(url_for("daily_report_employee", emp_id=emp.id, d=eval_date.isoformat()))

            # 3) قراءة آمنة للقيم + قصّ المدى
            gi = lambda n, lo=0, hi=5: max(lo, min(hi, int(request.form.get(n) or 0)))
            gf = lambda n, lo=0, hi=100: max(lo, min(hi, float(request.form.get(n) or 0)))

            de = DailyEvaluation(
                employee_id=emp.id,
                evaluator_id=u.id,
                eval_date=eval_date,

                t1_text=request.form.get("t1_text",""),
                t1_percent=gf("t1_percent"), t1_remarks=request.form.get("t1_remarks",""),
                t2_text=request.form.get("t2_text",""),
                t2_percent=gf("t2_percent"), t2_remarks=request.form.get("t2_remarks",""),
                t3_text=request.form.get("t3_text",""),
                t3_percent=gf("t3_percent"), t3_remarks=request.form.get("t3_remarks",""),
                t4_text=request.form.get("t4_text",""),
                t4_percent=gf("t4_percent"), t4_remarks=request.form.get("t4_remarks",""),

                p_punctuality=gi("p_punctuality"), c_punctuality=request.form.get("c_punctuality",""),
                p_quality=gi("p_quality"),         c_quality=request.form.get("c_quality",""),
                p_productivity=gi("p_productivity"), c_productivity=request.form.get("c_productivity",""),
                p_communication=gi("p_communication"), c_communication=request.form.get("c_communication",""),
                p_problemsolving=gi("p_problemsolving"), c_problemsolving=request.form.get("c_problemsolving",""),
                p_compliance=gi("p_compliance"),     c_compliance=request.form.get("c_compliance",""),

                strengths=request.form.get("strengths",""),
                improvements=request.form.get("improvements",""),
                training_needed=request.form.get("training_needed",""),
            )

            # 4) احسب الدرجات — بدون اعتماد خارجي
            compute_daily_scores(de)

            # 5) احفظ
            db.session.add(de)
            db.session.commit()

            flash("Daily evaluation saved.", "success")
            return redirect(url_for("daily_report_employee", emp_id=emp.id, d=eval_date.isoformat()))

        except Exception as e:
            # مهم: رجوع المعاملة + تسجيل الخطأ
            db.session.rollback()
            import traceback
            app.logger.error("Error saving daily evaluation:\n%s", traceback.format_exc())
            flash("Error while saving the daily evaluation.", "danger")
            return redirect(url_for("daily_evaluate_new", emp_id=emp.id))

    # GET — نفس تمبليتك الحالية
    d = date.today()
    return render_template("daily_eval_form.html", employee=emp, d=d, weights=WEIGHTS)


@app.route("/daily/reports/employee/<int:emp_id>")
@login_required
def daily_report_employee(emp_id):
    u = cur_user()

    # 1) get employee
    emp = Employee.query.get_or_404(emp_id)

    # 2) permission check
    allowed = False

    # admin can see all
    if u.role == "admin":
        allowed = True

    # supervisor of this employee
    elif emp.user_id == u.id:
        allowed = True

    # site supervisor: check mapping
    elif u.role == "site_supervisor":
        link = (db.session.query(SiteSupervisorMap)
                .filter_by(site_sup_id=u.id, supervisor_id=emp.user_id)
                .first())
        if link:
            allowed = True

    if not allowed:
        abort(403)

    # 3) date
    d_str = request.args.get("d")
    if not d_str:
        flash("Missing date.", "warning")
        return redirect(url_for("employees"))
    d_val = parse_date(d_str)

    # 4) daily evaluation
    de = (DailyEvaluation.query
          .filter_by(employee_id=emp.id, eval_date=d_val)
          .first_or_404())

    # important: recompute
    compute_daily_scores(de)

    evaluator = db.session.get(User, de.evaluator_id)
    return render_template(
        "daily_report_employee_v2.html",
        employee=emp,
        de=de,
        evaluator_code=(evaluator.supervisor_code if evaluator else ""),
        evaluator_name=(evaluator.name if (evaluator and evaluator.name) else "")
    )





@app.route("/daily/reports")
@login_required
def daily_reports():
    u = cur_user()

    d_str = request.args.get("d")
    if d_str:
        d_val = parse_date(d_str)
    else:
        # لو ما وصل تاريخ، استخدم تاريخ اليوم
        d_val = date.today()

    q = (db.session.query(DailyEvaluation, Employee)
         .join(Employee, DailyEvaluation.employee_id == Employee.id))

    # لو المستخدم مو أدمن، فلتر على موظفيه
    if u.role != "admin":
        q = q.filter(Employee.user_id == u.id)

    rows = (q.filter(DailyEvaluation.eval_date == d_val)
              .order_by(Employee.name.asc()).all())

    return render_template("daily_reports.html", rows=rows, d=d_val)


from datetime import date  # تأكد أنه موجود فوق

@app.route("/admin/reports/daily/all")
@admin_required
def admin_reports_daily_all():
    # 1) التاريخ
    d_s = request.args.get("eval_date")
    if d_s:
        d = parse_date(d_s)
    else:
        d = date.today()

    # 2) الفلتر اللي يكتبه الأدمن
    q = (request.args.get("q") or "").strip()
    focus_sup = find_supervisor_from_query(q)

    # 3) الجدول الرئيسي (نفس اللي كان عندك)
    query = (db.session.query(DailyEvaluation, Employee, User)
             .join(Employee, DailyEvaluation.employee_id == Employee.id)
             .join(User, Employee.user_id == User.id)
             .filter(DailyEvaluation.eval_date == d))

    if focus_sup:
        query = query.filter(Employee.user_id == focus_sup.id)

    if q and not focus_sup:
        like = f"%{q}%"
        query = query.filter(or_(
            Employee.name.ilike(like),
            Employee.emp_number.ilike(like),
            Employee.department.ilike(like),
            Employee.site.ilike(like),
            User.supervisor_code.ilike(like),
            DailyEvaluation.overall_band.ilike(like),
        ))

    rows = query.order_by(User.supervisor_code.asc(), Employee.name.asc()).all()

    # 4) كل المشرفين (علشان نطلع تحت "من اللي ما قيّم")
    supervisors = (User.query
                   .filter_by(role="supervisor", is_active=True)
                   .order_by(User.name.asc(), User.supervisor_code.asc())
                   .all())

    all_sup_stats = []  # هنا بنحط كل مشرف مع تغطيته
    for s in supervisors:
        # موظفين هذا المشرف
        emps = (Employee.query
                .filter_by(user_id=s.id, is_active=True)
                .order_by(Employee.name.asc())
                .all())
        total_emp = len(emps)
        emp_ids = [e.id for e in emps]

        if emp_ids:
            done_rows = (db.session.query(DailyEvaluation.employee_id)
                         .filter(DailyEvaluation.eval_date == d,
                                 DailyEvaluation.employee_id.in_(emp_ids))
                         .all())
            done_ids = {r[0] for r in done_rows}
        else:
            done_ids = set()

        done_emp_count = len(done_ids)
        coverage = (done_emp_count / total_emp * 100.0) if total_emp else 0.0
        missing_emps = [e for e in emps if e.id not in done_ids]

        all_sup_stats.append({
            "sup": s,
            "total_emp": total_emp,
            "done_emp_count": done_emp_count,
            "coverage": coverage,
            "missing_emps": missing_emps,
        })

    # 5) اقتراحات البحث اللي كانت عندك
    sup_suggestions, seen = [], set()
    for s in supervisors:
        val = (s.supervisor_code or "").strip()
        if val and val.lower() not in seen:
            sup_suggestions.append((val, f"{s.name or '—'} — ID: {s.supervisor_code}"))
            seen.add(val.lower())
    for s in supervisors:
        nm = (s.name or "").strip()
        if nm and nm.lower() not in seen:
            sup_suggestions.append((nm, f"{nm} — ID: {s.supervisor_code}"))
            seen.add(nm.lower())

    return render_template(
        "report_admin_daily_all.html",
        eval_date=d,
        rows=rows,
        q=q,
        focus_sup=focus_sup,
        supervisors=supervisors,
        sup_suggestions=sup_suggestions,
        all_sup_stats=all_sup_stats,   # <= الجديد
    )



# ---------- Admin: Requests ----------


@app.route("/attendance", methods=["GET", "POST"])
@admin_required
def attendance_admin():
    """
    صفحة الأدمن الرئيسية للحضور:
      - mode=day  : تاريخ واحد (d)
      - mode=week : أسبوع (ws..we) أحد->خميس
    """
    mode = request.args.get("mode") or "day"

    if request.method == "POST":
        mode = request.form.get("mode") or "day"
        if mode == "day":
            d = request.form.get("day_date") or ""
            return redirect(url_for("attendance_admin", mode="day", d=d))
        else:
            ws = request.form.get("week_start") or ""
            we = request.form.get("week_end") or ""
            # لو وضع أسبوع فقط تاريخ بداية، احسب النهاية = +4 أيام
            if ws and not we:
                try:
                    ws_dt = parse_date(ws)
                    we = (ws_dt + timedelta(days=4)).isoformat()
                except:
                    pass
            return redirect(url_for("attendance_admin", mode="week", ws=ws, we=we))

    # قراءة المعطيات من الquerystring
    if mode == "week":
        ws = _safe_date(request.args.get("ws")) or default_week_today()[0]
        we = _safe_date(request.args.get("we")) or (ws + timedelta(days=4))
        # تأكد أحد→خميس
        ok, msg = validate_week_sun_to_thu(ws, we)
        if not ok:
            flash(msg, "danger")
            ws, we = default_week_today()
    else:
        d = _safe_date(request.args.get("d")) or date.today()

    # الموظفون
    employees = (db.session.query(Employee, User)
                 .join(User, Employee.user_id == User.id)
                 .filter(Employee.is_active == True)
                 .order_by(User.supervisor_code.asc(), Employee.name.asc())
                 .all())

    rows = []
    kpi = {"total_days": 0, "total_present": 0}

    if mode == "day":
        # احضر سجلات هذا اليوم
        atts = Attendance.query.filter_by(date=d).all()
        att_by_emp = {a.employee_id: a for a in atts}
        for emp, sup in employees:
            a = att_by_emp.get(emp.id)
            rows.append({
                "emp": emp,
                "sup": sup,
                "status": (a.status if a else None),
                "remarks": (a.remarks if a else ""),
                "marked_by": (db.session.get(User, a.supervisor_id) if a else None)
            })
        # KPI يومي بسيط
        kpi["total_days"] = len([r for r in rows if r["status"]])
        kpi["total_present"] = len([r for r in rows if r["status"] == "present"])

        return render_template("attendance_admin.html",
                               mode="day", day_date=d, rows=rows, kpi=kpi)

    else:  # mode == "week"
        # اجلب كل الحضور ضمن المدى
        emp_ids = [emp.id for emp, _ in employees]
        atts = []
        if emp_ids:
            atts = (Attendance.query
                    .filter(Attendance.employee_id.in_(emp_ids),
                            Attendance.date >= ws,
                            Attendance.date <= we)
                    .all())
        # احصائيات لكل موظف
        stats = defaultdict(lambda: {"present": 0, "absent": 0, "leave": 0, "total": 0})
        for a in atts:
            stats[a.employee_id]["total"] += 1
            if a.status in ("present", "absent", "leave"):
                stats[a.employee_id][a.status] += 1
        for emp, sup in employees:
            s = stats[emp.id]
            pct = (s["present"] / s["total"] * 100.0) if s["total"] else 0.0
            kpi["total_days"] += s["total"]
            kpi["total_present"] += s["present"]
            rows.append({
                "emp": emp,
                "sup": sup,
                "present": s["present"],
                "absent": s["absent"],
                "leave": s["leave"],
                "total": s["total"],
                "percent": round(pct, 1)
            })

        return render_template("attendance_admin.html",
                               mode="week", ws=ws, we=we, rows=rows, kpi=kpi)


from sqlalchemy.exc import IntegrityError
from sqlalchemy import text
@app.route("/employees/add", methods=["POST"], endpoint="employees_add", strict_slashes=False)
@login_required
def employees_add():
    u = cur_user()
    
    # فقط السوبرفايزر
    if not u or getattr(u, "role", "") != "supervisor":
        abort(403)

    emp_number = (request.form.get("emp_number") or "").strip()
    name       = (request.form.get("name") or "").strip()
    department = (request.form.get("department") or "").strip()
    site       = (request.form.get("site") or "").strip()

    if not emp_number or not name:
        flash("Employee number and name are required.", "danger")
        return redirect(url_for("employees"))

    # رقم الموظف أرقام فقط
    if not emp_number.isdigit():
        flash("Employee number must contain digits only (0-9).", "danger")
        return redirect(url_for("employees"))

    # بحث عن الموظف (نشط أو غير نشط)
    emp = Employee.query.filter_by(emp_number=emp_number).first()

    if emp:
        # إعادة تفعيل إذا كان ملغي
        if not emp.is_active:
            emp.is_active = True

        # نقل الملكية إلى السوبرفايزر الحالي
        if emp.user_id != u.id:
            emp.user_id = u.id
            db.session.commit()
            flash(f"Employee {emp.name} ({emp.emp_number}) reactivated and assigned to you.", "success")
        else:
            flash(f"Employee {emp.name} ({emp.emp_number}) is already under your account.", "info")

        return redirect(url_for("employees"))

    # إنشاء موظف جديد
    try:
        emp = Employee(
            emp_number=emp_number,
            name=name,
            department=department,
            site=site,
            user_id=u.id,
            is_active=True,
        )
        db.session.add(emp)
        db.session.commit()
        flash(f"Employee {emp.name} ({emp.emp_number}) added successfully.", "success")

    except IntegrityError:
        db.session.rollback()
        flash("Duplicate employee number. Try again.", "danger")

    return redirect(url_for("employees"))

@app.route("/employees/<int:emp_id>/deactivate", methods=["POST"], endpoint="employees_deactivate", strict_slashes=False)
@login_required
def employees_deactivate(emp_id):
    u = cur_user()

    # فقط السوبرفايزر
    if not u or getattr(u, "role", "") != "supervisor":
        abort(403)

    emp = Employee.query.get_or_404(emp_id)

    # تأكد أنه تحت حساب السوبرفايزر نفسه
    if emp.user_id != u.id:
        abort(403)

    emp.is_active = False

    try:
        db.session.commit()
        flash(f"Employee {emp.name} ({emp.emp_number}) deactivated.", "success")
    except:
        db.session.rollback()
        flash("Error occurred while deactivating employee.", "danger")

    return redirect(url_for("employees"))



@app.route("/admin/requests", methods=["GET", "POST"])
@login_required
@admin_required
def requests_inbox():
    status = request.args.get("status", "pending")
    qterm  = (request.args.get("q") or "").strip()

    q = Request.query

    # فلتر الحالة (لو مو "all")
    if status and status != "all":
        q = q.filter(Request.status == status)

    # فلتر البحث بالاسم / رقم الموظف
    if qterm:
        q = (q.join(Employee, Request.employee_id == Employee.id)
               .filter(or_(
                   Employee.emp_number.like(f"%{qterm}%"),
                   Employee.name.ilike(f"%{qterm}%"),
               )))

    rows = q.order_by(Request.created_at.desc()).all()

    # 1) رابط "New" لو الراوت موجود
    request_new_url = None
    if "request_new" in current_app.view_functions:
        request_new_url = url_for("request_new")

    # 2) خرائط روابط ملخص الموظف حسب الراوتات المتاحة في مشروعك
    # جرّب بالترتيب: employee_summary → admin_employee_summary → admin_employee_history
    employee_summary_url_map = {}
    endpoint_candidates = ["employee_summary", "admin_employee_summary", "admin_employee_history"]
    target_endpoint = next((ep for ep in endpoint_candidates if ep in current_app.view_functions), None)

    if target_endpoint:
        for r in rows:
            if r.employee_id:
                try:
                    employee_summary_url_map[r.employee_id] = url_for(target_endpoint, emp_id=r.employee_id)
                except Exception:
                    # لو الراوت يطلب باراميتر باسم مختلف، نتركه بدون رابط
                    pass

    return render_template(
        "requests_inbox.html",
        rows=rows,
        status=status,
        q=qterm,
        request_new_url=request_new_url,
        employee_summary_url_map=employee_summary_url_map,
    )

@app.route("/admin/requests/<int:req_id>/decide", methods=["POST"])
@login_required
@admin_required
def request_decide(req_id):
    req = Request.query.get_or_404(req_id)
    decision = request.form.get("decision")  # "approve" أو "reject"
    comment  = (request.form.get("admin_comment") or "").strip()

    if decision not in ("approve", "reject"):
        flash("Invalid decision.", "danger")
        return redirect(url_for("requests_inbox"))

    # حدّث بيانات الطلب
    req.status = "approved" if decision == "approve" else "rejected"
    req.decided_by = cur_user().id
    req.decided_at = datetime.utcnow()
    req.admin_comment = comment

    # لو Approved و نوعه Leave: طبّقها على الحضور مباشرة (سلوكك الحالي)
    if decision == "approve" and (req.type or "leave") == "leave":
        _apply_leave_attendance_for_request(req)

    # --- الإضافة الجديدة: إنشاء مهمة HR عند الموافقة ---
    if decision == "approve":
        # تضمن وجود سجل واحد فقط لكل طلب
        existing = HRTask.query.filter_by(request_id=req.id).first()
        if not existing:
            try:
                db.session.add(HRTask(
                    request_id=req.id,
                    employee_id=req.employee_id,
                    type=req.type or "leave",     # نفس نوع الطلب
                    status="pending"              # بانتظار تنفيذ HR
                ))
                # لا حاجة لعمل commit منفصل؛ سيُحفظ مع الـ commit النهائي
            except IntegrityError:
                db.session.rollback()  # في حال unique constraint
                # إعادة محاولة قراءة الموجود (تحسبًا لتنافُس)
                pass
    # --- نهاية الإضافة ---

    db.session.commit()
    flash("Request updated.", "success")
    return redirect(url_for("requests_inbox"))


@app.route("/attendance/report", methods=["GET"])
@admin_required
def attendance_report():
    # نطاق التاريخ (اختياري عبر ?from=YYYY-MM-DD&to=YYYY-MM-DD)
    frm = request.args.get("from"); to = request.args.get("to")
    try:
        d_from = parse_date(frm) if frm else date.today().replace(day=1)
    except: d_from = date.today().replace(day=1)
    try:
        d_to = parse_date(to) if to else date.today()
    except: d_to = date.today()

    employees = (db.session.query(Employee, User)
                 .join(User, Employee.user_id == User.id)
                 .filter(Employee.is_active == True)
                 .order_by(User.supervisor_code.asc(), Employee.name.asc())
                 .all())

    rows = []
    for emp, sup in employees:
        q = Attendance.query.filter(Attendance.employee_id==emp.id,
                                    Attendance.date>=d_from,
                                    Attendance.date<=d_to)
        total = q.count()
        present = q.filter_by(status="present").count()
        leave   = q.filter_by(status="leave").count()
        absent  = q.filter_by(status="absent").count()
        pct = (present / total * 100.0) if total else 0.0
        rows.append({
            "emp": emp, "sup": sup,
            "total": total, "present": present,
            "leave": leave, "absent": absent,
            "percent": round(pct,1)
        })

    # KPI إجمالي
    total_days = sum(r["total"] for r in rows)
    total_present = sum(r["present"] for r in rows)
    kpi_attendance = round((total_present/total_days*100.0),1) if total_days else 0.0

    return render_template("attendance_report.html",
                           rows=rows, d_from=d_from, d_to=d_to,
                           kpi_attendance=kpi_attendance)

@app.route("/attendance/print", methods=["GET"])
@admin_required
def attendance_print():
    mode = request.args.get("mode") or "day"

    if mode == "week":
        ws = _safe_date(request.args.get("ws")) or default_week_today()[0]
        we = _safe_date(request.args.get("we")) or (ws + timedelta(days=4))
        ok, msg = validate_week_sun_to_thu(ws, we)
        if not ok:
            flash(msg, "danger")
            ws, we = default_week_today()
    else:
        d = _safe_date(request.args.get("d")) or date.today()

    employees = (db.session.query(Employee, User)
                 .join(User, Employee.user_id == User.id)
                 .filter(Employee.is_active == True)
                 .order_by(User.supervisor_code.asc(), Employee.name.asc())
                 .all())

    if mode == "day":
        atts = Attendance.query.filter_by(date=d).all()
        att_by_emp = {a.employee_id: a for a in atts}
        rows = []
        for emp, sup in employees:
            a = att_by_emp.get(emp.id)
            rows.append({
                "emp": emp, "sup": sup,
                "status": (a.status if a else None),
                "remarks": (a.remarks if a else ""),
                "marked_by": (db.session.get(User, a.supervisor_id) if a else None)
            })
        return render_template("attendance_print.html", mode="day", day_date=d, rows=rows)

    else:
        emp_ids = [emp.id for emp, _ in employees]
        atts = []
        if emp_ids:
            atts = (Attendance.query
                    .filter(Attendance.employee_id.in_(emp_ids),
                            Attendance.date >= ws,
                            Attendance.date <= we).all())
        from collections import defaultdict
        stats = defaultdict(lambda: {"present": 0, "absent": 0, "leave": 0, "total": 0})
        for a in atts:
            stats[a.employee_id]["total"] += 1
            if a.status in ("present", "absent", "leave"):
                stats[a.employee_id][a.status] += 1
        rows = []
        for emp, sup in employees:
            s = stats[emp.id]
            pct = (s["present"]/s["total"]*100.0) if s["total"] else 0.0
            rows.append({
                "emp": emp, "sup": sup,
                "present": s["present"], "absent": s["absent"], "leave": s["leave"],
                "total": s["total"], "percent": round(pct,1)
            })
        return render_template("attendance_print.html", mode="week", ws=ws, we=we, rows=rows)

@app.route("/attendance/pdf", methods=["GET"])
@admin_required
def attendance_pdf():
    frm = request.args.get("from"); to = request.args.get("to")
    try:
        d_from = parse_date(frm) if frm else date.today().replace(day=1)
    except: d_from = date.today().replace(day=1)
    try:
        d_to = parse_date(to) if to else date.today()
    except: d_to = date.today()

    employees = (db.session.query(Employee, User)
                 .join(User, Employee.user_id == User.id)
                 .filter(Employee.is_active == True)
                 .order_by(User.supervisor_code.asc(), Employee.name.asc())
                 .all())

    pdf = FPDF(orientation="L", unit="mm", format="A4")
    pdf.add_page()
    pdf.set_font("Arial", "B", 14)
    pdf.cell(0, 10, f"Attendance Report {d_from} to {d_to}", ln=True, align="C")

    pdf.set_font("Arial", "B", 10)
    pdf.cell(60, 8, "Employee", 1)
    pdf.cell(35, 8, "Supervisor ID", 1)
    pdf.cell(20, 8, "Total", 1)
    pdf.cell(25, 8, "Present", 1)
    pdf.cell(25, 8, "Leave", 1)
    pdf.cell(25, 8, "Absent", 1)
    pdf.cell(25, 8, "Attendance %", 1)
    pdf.ln()

    pdf.set_font("Arial", "", 10)
    for emp, sup in employees:
        q = Attendance.query.filter(Attendance.employee_id==emp.id,
                                    Attendance.date>=d_from,
                                    Attendance.date<=d_to)
        total = q.count()
        present = q.filter_by(status="present").count()
        leave   = q.filter_by(status="leave").count()
        absent  = q.filter_by(status="absent").count()
        pct = (present/total*100.0) if total else 0.0

        pdf.cell(60, 8, emp.name[:28], 1)
        pdf.cell(35, 8, (sup.supervisor_code or "")[:12], 1)
        pdf.cell(20, 8, str(total), 1, align="C")
        pdf.cell(25, 8, str(present), 1, align="C")
        pdf.cell(25, 8, str(leave), 1, align="C")
        pdf.cell(25, 8, str(absent), 1, align="C")
        pdf.cell(25, 8, f"{pct:.1f}%", 1, align="C")
        pdf.ln()

    return Response(pdf.output(dest="S").encode("latin1"),
                    mimetype="application/pdf",
                    headers={"Content-Disposition":"inline; filename=attendance.pdf"})

@app.route("/attendance/mark", methods=["GET", "POST"])
@login_required
def attendance_mark():
    u = cur_user()
    if not u or u.role not in ("supervisor", "admin"):
        flash("Unauthorized", "danger")
        return redirect(url_for("index"))

    # الموظفين للمشرف الحالي
    employees = (Employee.query
                 .filter_by(user_id=u.id, is_active=True)
                 .order_by(Employee.name.asc())
                 .all())

    # هذا اللي نعرضه في الفورم
    today = date.today()

    if request.method == "POST":
        # اقرأ التاريخ اللي جاي من الفورم (name="date" في التمبليت)
        d_raw = request.form.get("date")
        if d_raw:
            # نحلّلها يدوي عشان ما يصير خطأ 500 لو السيرفر قديم
            try:
                y, m, d = map(int, d_raw.split("-"))
                mark_date = date(y, m, d)
            except ValueError:
                mark_date = today
        else:
            mark_date = today

        changed = 0
        for emp in employees:
            status = (request.form.get(f"emp_{emp.id}_status") or "").strip()
            remarks = (request.form.get(f"emp_{emp.id}_remarks") or "").strip()
            if not status:
                continue

            # استخدم التاريخ اللي اختاره المستخدم
            rec = Attendance.query.filter_by(employee_id=emp.id, date=mark_date).first()
            if not rec:
                rec = Attendance(
                    employee_id=emp.id,
                    supervisor_id=u.id,
                    date=mark_date,
                    status=status,
                    remarks=remarks
                )
                db.session.add(rec)
                changed += 1
            else:
                if rec.status != status or rec.remarks != remarks:
                    rec.status = status
                    rec.remarks = remarks
                    changed += 1

        if changed:
            db.session.commit()
            flash("Attendance saved.", "success")
        else:
            flash("No changes.", "info")

        # نرجع لنفس الصفحة زي أول
        return redirect(url_for("attendance_mark"))

    # GET: اعرض حضور اليوم
    saved = {a.employee_id: a for a in Attendance.query.filter_by(date=today).all()}
    return render_template("attendance_mark.html",
                           employees=employees,
                           today=today,
                           saved=saved)

@app.route("/")
def index():
    u = cur_user()
    if not u:
        return redirect(url_for("login"))
    if u.role == "admin":
        return redirect(url_for("admin_kpi"))
    return redirect(url_for("employees"))

# اختيار المشرف والأسبوع لطباعة الحزمة
@app.route("/site/print", methods=["GET", "POST"])
@login_required
def site_print_select():
    u = cur_user()
    if not u or u.role != "site_supervisor":
        abort(403)

    # المشرفين المرتبطين بهذا الـ Site Supervisor
    links = (db.session.query(SiteSupervisorMap, User)
             .join(User, SiteSupervisorMap.supervisor_id == User.id)
             .filter(SiteSupervisorMap.site_sup_id == u.id)
             .order_by(User.supervisor_code.asc())
             .all())
    supervisors = [sup for _, sup in links]
    ws, we = default_week_today()

    if request.method == "POST":
        sup_user_id = int(request.form["sup_user_id"])
        ws = parse_date(request.form["week_start"])
        we = parse_date(request.form["week_end"])
        ok, msg = validate_week_sun_to_thu(ws, we)
        if not ok:
            flash(msg, "danger")
            return redirect(url_for("site_print_select"))
        # نستخدم GET حتى تكون قابلة لإعادة الفتح
        return redirect(url_for("site_print_bundle",
                                sup_user_id=sup_user_id,
                                week_start=ws.isoformat(),
                                week_end=we.isoformat()))
    return render_template("site_print_select.html", supervisors=supervisors, ws=ws, we=we)

@app.route("/admin/kpi", methods=["GET", "POST"])
@admin_required
def admin_kpi():
    if request.method == "POST":
        ws = parse_date(request.form["week_start"])
        we = parse_date(request.form["week_end"])
        ok, msg = validate_week_sun_to_thu(ws, we)
        if not ok:
            flash(msg, "danger")
            return redirect(url_for("admin_kpi"))
        return redirect(url_for("admin_kpi", week_start=ws.isoformat(), week_end=we.isoformat()))

    # أسبوع افتراضي (أو من الاستعلام)
    ws, we = default_week_today()
    if request.args.get("week_start") and request.args.get("week_end"):
        ws = parse_date(request.args["week_start"])
        we = parse_date(request.args["week_end"])
    pws, pwe = previous_week_range(ws)

    # ---------- Supervisor → Employees ----------
    supervisors = (
        User.query.filter_by(role="supervisor", is_active=True)
        .order_by(User.supervisor_code.asc()).all()
    )

    emp_totals_map = dict(
        db.session.query(Employee.user_id, func.count(Employee.id))
        .filter(Employee.is_active == True)
        .group_by(Employee.user_id).all()
    )

    emp_cnt_this = dict(
        db.session.query(Employee.user_id, func.count(Evaluation.id))
        .join(Evaluation, Evaluation.employee_id == Employee.id)
        .filter(Evaluation.week_start == ws, Evaluation.week_end == we)
        .group_by(Employee.user_id).all()
    )

    emp_cnt_prev = dict(
        db.session.query(Employee.user_id, func.count(Evaluation.id))
        .join(Evaluation, Evaluation.employee_id == Employee.id)
        .filter(Evaluation.week_start == pws, Evaluation.week_end == pwe)
        .group_by(Employee.user_id).all()
    )

    sup_rows, sum_target_emp, sum_done_emp = [], 0, 0
    growth_pool_prev, growth_pool_curr = 0, 0

    for sup in supervisors:
        target = emp_totals_map.get(sup.id, 0)
        done_c = emp_cnt_this.get(sup.id, 0)
        done_p = emp_cnt_prev.get(sup.id, 0)
        coverage = (done_c / target * 100.0) if target else None

        sum_target_emp += target
        sum_done_emp += done_c

        if done_c > 0 and done_p > 0:
            growth_pool_prev += done_p
            growth_pool_curr += done_c

        sup_rows.append({
            "id": sup.id,
            "code": sup.supervisor_code,
            "name": sup.name,
            "target": target,
            "done_c": done_c,
            "done_p": done_p,
            "coverage": coverage,
            "delta": (done_c - done_p),
            "trend": ("up" if done_c > done_p else "down" if done_c < done_p else "flat"),
        })

    # ---------- Site Supervisor → Supervisors ----------
    site_sups = (
        User.query.filter_by(role="site_supervisor", is_active=True)
        .order_by(User.supervisor_code.asc()).all()
    )

    assigned_counts = dict(
        db.session.query(
            SiteSupervisorMap.site_sup_id,
            func.count(func.distinct(SiteSupervisorMap.supervisor_id)),
        )
        .group_by(SiteSupervisorMap.site_sup_id).all()
    )

    se_cnt_this = dict(
        db.session.query(SupervisorEvaluation.evaluator_id, func.count(SupervisorEvaluation.id))
        .filter(SupervisorEvaluation.week_start == ws, SupervisorEvaluation.week_end == we)
        .group_by(SupervisorEvaluation.evaluator_id).all()
    )

    se_cnt_prev = dict(
        db.session.query(SupervisorEvaluation.evaluator_id, func.count(SupervisorEvaluation.id))
        .filter(SupervisorEvaluation.week_start == pws, SupervisorEvaluation.week_end == pwe)
        .group_by(SupervisorEvaluation.evaluator_id).all()
    )

    site_rows, sum_target_sup, sum_done_sup = [], 0, 0
    for s in site_sups:
        target = assigned_counts.get(s.id, 0)
        done_c = se_cnt_this.get(s.id, 0)
        done_p = se_cnt_prev.get(s.id, 0)
        coverage = (done_c / target * 100.0) if target else None

        sum_target_sup += target
        sum_done_sup += done_c

        if done_c > 0 and done_p > 0:
            growth_pool_prev += done_p
            growth_pool_curr += done_c

        site_rows.append({
            "id": s.id,
            "code": s.supervisor_code,
            "name": s.name,
            "target": target,
            "done_c": done_c,
            "done_p": done_p,
            "coverage": coverage,
            "delta": (done_c - done_p),
            "trend": ("up" if done_c > done_p else "down" if done_c < done_p else "flat"),
        })

    # ---------- إجماليات ----------
    total_this_week = (
        db.session.query(func.count(Evaluation.id))
        .filter(Evaluation.week_start == ws, Evaluation.week_end == we).scalar()
        +
        db.session.query(func.count(SupervisorEvaluation.id))
        .filter(SupervisorEvaluation.week_start == ws, SupervisorEvaluation.week_end == we).scalar()
    )

    total_prev_week = (
        db.session.query(func.count(Evaluation.id))
        .filter(Evaluation.week_start == pws, Evaluation.week_end == pwe).scalar()
        +
        db.session.query(func.count(SupervisorEvaluation.id))
        .filter(SupervisorEvaluation.week_start == pws, SupervisorEvaluation.week_end == pwe).scalar()
    )

    growth_pct = 0.0
    if growth_pool_prev > 0:
        growth_pct = (growth_pool_curr - growth_pool_prev) / growth_pool_prev * 100.0

    overall_emp_coverage = (sum_done_emp / sum_target_emp * 100.0) if sum_target_emp else None
    overall_sup_coverage = (sum_done_sup / sum_target_sup * 100.0) if sum_target_sup else None

    # ---------- Attendance & Leave Rates (من جميع الفرص) ----------
    # الموظفون النشطون + عدد أيام الأسبوع (Sun→Thu بعد التحقق)
    active_emp_ids = [e.id for e in Employee.query.filter_by(is_active=True).all()]
    active_count = len(active_emp_ids)
    workdays = (we - ws).days + 1  # يفترض Sun..Thu بعد validate_week_sun_to_thu

    total_opportunities = active_count * workdays  # المقام

    # تعداد الحالات المسجلة
    present_count = db.session.query(func.count(Attendance.id)).filter(
        Attendance.date >= ws,
        Attendance.date <= we,
        Attendance.employee_id.in_(active_emp_ids),
        Attendance.status == 'present'
    ).scalar() or 0

    leave_count = db.session.query(func.count(Attendance.id)).filter(
        Attendance.date >= ws,
        Attendance.date <= we,
        Attendance.employee_id.in_(active_emp_ids),
        Attendance.status == 'leave'
    ).scalar() or 0

    # الغياب = الباقي (يشمل الأيام/الموظفين غير المسجلين)
    absent_count = max(total_opportunities - (present_count + leave_count), 0)

    att_rate   = round(present_count / total_opportunities * 100.0, 1) if total_opportunities else None
    leave_rate = round(leave_count   / total_opportunities * 100.0, 1) if total_opportunities else None
    # (اختياري) احسب غياب:
    # absent_rate = round(absent_count / total_opportunities * 100.0, 1) if total_opportunities else None

    return render_template(
        "admin_kpi.html",
        ws=ws, we=we, pws=pws, pwe=pwe,
        total_this_week=total_this_week, total_prev_week=total_prev_week,
        growth_pct=growth_pct,
        overall_emp_cov=overall_emp_coverage,
        overall_sup_cov=overall_sup_coverage,
        att_rate=att_rate,
        leave_rate=leave_rate,
        sup_rows=sup_rows, site_rows=site_rows
    )


@app.route("/admin/supervisor/<int:sup_id>/history")
@admin_required
def admin_supervisor_history(sup_id):
    sup = User.query.filter_by(id=sup_id, role="supervisor").first_or_404()
    evals = (SupervisorEvaluation.query
             .filter_by(supervisor_id=sup.id)
             .order_by(SupervisorEvaluation.week_start.desc())
             .all())
    return render_template("supervisor_history.html", sup=sup, evals=evals)
@app.get("/_health")
def _health():
    return "ok"

# عرض الحزمة الجاهزة للطباعة
@app.get("/site/print/bundle")
@login_required
def site_print_bundle():
    u = cur_user()
    if not u or u.role != "site_supervisor":
        abort(403)

    sup_user_id = int(request.args.get("sup_user_id", "0"))
    week_start = request.args.get("week_start")
    week_end   = request.args.get("week_end")
    if not (sup_user_id and week_start and week_end):
        return redirect(url_for("site_print_select"))

    ws = parse_date(week_start); we = parse_date(week_end)

    # تأكد أن هذا المشرف ضمن قوائم هذا الـ Site Supervisor
    link = SiteSupervisorMap.query.filter_by(site_sup_id=u.id, supervisor_id=sup_user_id).first()
    if not link:
        abort(403)

    supervisor = db.session.get(User, sup_user_id) or abort(404)

    # جميع موظفي هذا المشرف
    employees = Employee.query.filter_by(user_id=sup_user_id, is_active=True).order_by(Employee.name.asc()).all()
    emp_ids = [e.id for e in employees]

    # كل التقييمات لهؤلاء الموظفين في الأسبوع المحدد
    eval_rows = (db.session.query(Evaluation, Employee)
                 .join(Employee, Evaluation.employee_id == Employee.id)
                 .filter(Evaluation.week_start == ws,
                         Evaluation.week_end == we,
                         Employee.id.in_(emp_ids))
                 .order_by(Employee.name.asc())
                 .all())

    # جهّز قائمة مطبوعات: (ev, emp, evaluator_user)
    evals = []
    seen_emp = set()
    for ev, emp in eval_rows:
        evaluator = db.session.get(User, ev.evaluator_id)
        evals.append((ev, emp, evaluator))
        seen_emp.add(emp.id)

    # من لم يتم تقييمهم
    not_evaluated = [emp for emp in employees if emp.id not in seen_emp]

    return render_template(
        "site_print_bundle.html",
        supervisor=supervisor, ws=ws, we=we,
        evals=evals, not_evaluated=not_evaluated
    )

@app.get("/hr/inbox")
@hr_required
def hr_inbox():
    rows = (db.session.query(HRTask)
            .order_by(HRTask.created_at.desc())
            .all())
    return render_template("hr_inbox.html", rows=rows)

@app.post("/hr/task/<int:task_id>/apply")
@hr_required
def hr_task_apply(task_id):
    t = db.session.get(HRTask, task_id)
    if not t:
        abort(404)
    if t.status == "pending":
        t.status = "applied"
        t.applied_at = datetime.utcnow()
        t.applied_by = cur_user().id
        db.session.commit()
    return redirect(url_for("hr_inbox"))

@app.route("/admin")
@admin_required
def admin_home():
    return redirect(url_for("admin_kpi"))

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        code = (request.form.get("code") or request.form.get("sup_code") or "").strip()
        if not code:
            flash("Please enter your Supervisor ID.", "danger")
            return redirect(url_for("login"))

        user = User.query.filter_by(supervisor_code=code, is_active=True).first()
        if not user:
            flash("ID not found or inactive. Contact Admin.", "danger")
            return redirect(url_for("login"))

        session.clear()
        session["user_id"] = user.id
        flash("Signed in successfully.", "success")

        if user.role == "admin":
            return redirect(url_for("admin_kpi"))
        elif user.role == "site_supervisor":
            return redirect(url_for("site_supervisors"))
        elif user.role == "hr":
            return redirect(url_for("hr_inbox"))
        else:
            return redirect(url_for("employees"))

    return render_template("login.html")


@app.route("/logout")
def logout():
    session.clear()
    flash("Signed out.", "info")
    return redirect(url_for("login"))

# ----- Admin: Users -----
@app.route("/admin/users", methods=["GET", "POST"])
@admin_required
def admin_users():
    if request.method == "POST":
        code = (request.form.get("code") or "").strip()
        name = (request.form.get("name") or "").strip()
        role = request.form.get("role") or "supervisor"  # can be site_supervisor
        if not code:
            flash("Supervisor ID is required.", "danger")
        else:
            existing = User.query.filter_by(supervisor_code=code).first()
            if existing:
                flash("This ID already exists.", "warning")
            else:
                u = User(supervisor_code=code, name=name, role=role, is_active=True)
                db.session.add(u)
                db.session.commit()
                flash("User added.", "success")
        return redirect(url_for("admin_users"))
    users = User.query.order_by(User.role.desc(), User.supervisor_code.asc()).all()
    return render_template("admin_users.html", users=users)
# --- Admin: Print hub (select week) ---
@app.route("/admin/print", methods=["GET", "POST"])
@admin_required
def admin_print_select():
    ws, we = default_week_today()
    if request.method == "POST":
        ws = parse_date(request.form["week_start"])
        we = parse_date(request.form["week_end"])
        ok, msg = validate_week_sun_to_thu(ws, we)
        if not ok:
            flash(msg, "danger")
            return redirect(url_for("admin_print_select"))
        return redirect(url_for("admin_print_bundle",
                                week_start=ws.isoformat(),
                                week_end=we.isoformat()))
    return render_template("admin_print_select.html", ws=ws, we=we)


# --- Admin: Print bundle (all reports + blanks for missing) ---
@app.route("/admin/print/bundle")
@admin_required
def admin_print_bundle():
    week_start = request.args.get("week_start")
    week_end   = request.args.get("week_end")
    if not (week_start and week_end):
        return redirect(url_for("admin_print_select"))

    ws = parse_date(week_start); we = parse_date(week_end)

    # كل المشرفين الفعّالين
    supervisors = User.query.filter_by(role="supervisor", is_active=True)\
                            .order_by(User.supervisor_code.asc()).all()
    sup_by_id = {s.id: s for s in supervisors}

    # خريطة (المشرف ← أحد مشرفي السايت المربوطين به إن وجد)
    ssm_rows = SiteSupervisorMap.query.all()
    site_by_sup: dict[int, User | None] = {}
    for row in ssm_rows:
        # اختر أول مشرف سايت فقط للعرض
        if row.supervisor_id not in site_by_sup:
            site_by_sup[row.supervisor_id] = db.session.get(User, row.site_sup_id)

    # تقييمات السايت لهذا الأسبوع
    se_list = SupervisorEvaluation.query.filter_by(week_start=ws, week_end=we).all()
    se_by_sup: dict[int, SupervisorEvaluation] = {se.supervisor_id: se for se in se_list}

    # صفحات تقييم السايت الموجودة
    site_eval_pages = []
    for se in se_list:
        sup = sup_by_id.get(se.supervisor_id)
        if not sup:
            continue
        evaluator = db.session.get(User, se.evaluator_id)
        site_eval_pages.append((se, sup, evaluator))

    # صفحات السايت المفقودة (فارغة)
    site_missing_pages = []
    for sup in supervisors:
        if sup.id not in se_by_sup:
            site_eval_pages_sup = site_by_sup.get(sup.id)  # قد يكون None
            site_missing_pages.append((sup, site_eval_pages_sup))

    # الموظفون لكل مشرف
    employees = Employee.query.filter(Employee.user_id.in_([s.id for s in supervisors]),
                                      Employee.is_active == True)\
                              .order_by(Employee.name.asc()).all()
    emp_ids = [e.id for e in employees]
    emp_by_id = {e.id: e for e in employees}
    sup_id_by_emp_id = {e.id: e.user_id for e in employees}

    # كل تقييمات الموظفين لهذا الأسبوع
    ev_list = Evaluation.query.filter(Evaluation.week_start == ws,
                                      Evaluation.week_end == we,
                                      Evaluation.employee_id.in_(emp_ids)).all()
    ev_by_emp: dict[int, Evaluation] = {ev.employee_id: ev for ev in ev_list}

    # صفحات تقييم الموظفين الموجودة
    emp_eval_pages = []
    for ev in ev_list:
        emp = emp_by_id.get(ev.employee_id)
        if not emp:
            continue
        sup = sup_by_id.get(emp.user_id)
        evaluator = db.session.get(User, ev.evaluator_id)
        emp_eval_pages.append((ev, emp, sup, evaluator))

    # الموظفون غير المُقيّمين
    emp_missing_pages = []
    for emp in employees:
        if emp.id not in ev_by_emp:
            sup = sup_by_id.get(emp.user_id)
            emp_missing_pages.append((emp, sup))

    return render_template(
        "admin_print_bundle.html",
        ws=ws, we=we,
        site_eval_pages=site_eval_pages,
        site_missing_pages=site_missing_pages,
        emp_eval_pages=emp_eval_pages,
        emp_missing_pages=emp_missing_pages
    )

@app.post("/admin/users/<int:user_id>/toggle")
@admin_required
def admin_users_toggle(user_id):
    u = db.session.get(User, user_id) or abort(404)
    if u.role == "admin":
        flash("Cannot deactivate admin.", "warning")
    else:
        u.is_active = not u.is_active
        db.session.commit()
        flash("Status updated.", "success")
    return redirect(url_for("admin_users"))

@app.post("/admin/users/<int:user_id>/role")
@admin_required
def admin_users_set_role(user_id):
    u = db.session.get(User, user_id) or abort(404)
    new_role = (request.form.get("role") or "").strip()

    # لا نسمح بتعديل دور الأدمن من هنا
    if u.role == "admin":
        flash("Cannot change role of admin here.", "warning")
        return redirect(url_for("admin_users"))

    if new_role not in ["supervisor", "site_supervisor"]:
        flash("Invalid role.", "danger")
    else:
        u.role = new_role
        db.session.commit()
        flash("Role updated.", "success")

    return redirect(url_for("admin_users"))



# ----- Supervisor: Employees -----
@app.route("/employees", methods=["GET"])
@login_required
def employees():
    u = cur_user()
    if u.role not in ("supervisor", "admin"):
        abort(403)

    emps = (Employee.query
            .filter_by(user_id=u.id, is_active=True)
            .order_by(Employee.name)
            .all())
    return render_template("employees.html", user=u, employees=emps)



# ----- New Evaluation (employee) -----
@app.route("/evaluate/<int:emp_id>/new", methods=["GET", "POST"])
@login_required
def evaluate_new(emp_id):
    u = cur_user()

    if not u:
        abort(403)

    # admin و site_supervisor يشوفون أي موظف، supervisor العادي موظفيه فقط
    if u.role in ("admin", "site_supervisor"):
        emp = Employee.query.get_or_404(emp_id)
    else:
        emp = Employee.query.filter_by(id=emp_id, user_id=u.id).first_or_404()

    # POST = حفظ (إنشاء أو تعديل)
    if request.method == "POST":
        week_start_raw = request.form.get("week_start")
        week_end_raw   = request.form.get("week_end")

        if not week_start_raw or not week_end_raw:
            flash("Week dates are required.", "danger")
            return redirect(url_for("evaluate_new", emp_id=emp.id))

        ws = parse_date(week_start_raw)
        we = parse_date(week_end_raw)

        # تحقّق أن الأسبوع من الأحد إلى الخميس (نفس ما كنت تستخدم)
        ok, msg = validate_week_sun_to_thu(ws, we)
        if not ok:
            flash(msg, "danger")
            return redirect(url_for("evaluate_new", emp_id=emp.id))

        # 🔴 هنا الفكرة المهمّة:
        # إذا في تقييم لنفس الموظف ونفس الأسبوع → استخدمه وحدثه
        # إذا مافي → أنشئ واحد جديد
        ev = (Evaluation.query
              .filter_by(employee_id=emp.id, week_start=ws, week_end=we)
              .first())

        if ev is None:
            ev = Evaluation(
                employee_id=emp.id,
                evaluator_id=u.id,
                week_start=ws,
                week_end=we,
            )
            db.session.add(ev)
        else:
            # لو حاب تعتبر أن آخر من عدّل هو المقيم الحالي
            ev.evaluator_id = u.id

        # 1) Weekly Targets
        ev.t1_text     = request.form.get("t1_text") or ""
        ev.t2_text     = request.form.get("t2_text") or ""
        ev.t3_text     = request.form.get("t3_text") or ""
        ev.t4_text     = request.form.get("t4_text") or ""

        ev.t1_percent  = request.form.get("t1_percent", type=float)
        ev.t2_percent  = request.form.get("t2_percent", type=float)
        ev.t3_percent  = request.form.get("t3_percent", type=float)
        ev.t4_percent  = request.form.get("t4_percent", type=float)

        ev.t1_remarks  = request.form.get("t1_remarks") or ""
        ev.t2_remarks  = request.form.get("t2_remarks") or ""
        ev.t3_remarks  = request.form.get("t3_remarks") or ""
        ev.t4_remarks  = request.form.get("t4_remarks") or ""

        # 2) Performance ratings
        ev.p_punctuality    = request.form.get("p_punctuality", type=int)
        ev.p_quality        = request.form.get("p_quality", type=int)
        ev.p_productivity   = request.form.get("p_productivity", type=int)
        ev.p_communication  = request.form.get("p_communication", type=int)
        ev.p_problemsolving = request.form.get("p_problemsolving", type=int)
        ev.p_compliance     = request.form.get("p_compliance", type=int)

        # 3) Performance comments
        ev.c_punctuality    = request.form.get("c_punctuality") or ""
        ev.c_quality        = request.form.get("c_quality") or ""
        ev.c_productivity   = request.form.get("c_productivity") or ""
        ev.c_communication  = request.form.get("c_communication") or ""
        ev.c_problemsolving = request.form.get("c_problemsolving") or ""
        ev.c_compliance     = request.form.get("c_compliance") or ""

        # 4) Summary
        ev.strengths        = request.form.get("strengths") or ""
        ev.improvements     = request.form.get("improvements") or ""
        ev.training_needed  = request.form.get("training_needed") or ""

        # إعادة حساب الدرجات (نفس الفنكشن اللي تستخدمه أصلًا)
        compute_scores(ev)

        db.session.commit()
        flash("Weekly evaluation saved.", "success")

        # بعد الحفظ، افتح تقرير الموظف لهذا الأسبوع
        return redirect(url_for(
            "report_employee",
            emp_id=emp.id,
            week_start=ws.isoformat(),
            week_end=we.isoformat()
        ))

    # GET = فتح النموذج لأول مرة
    # نفس منطقك القديم: ws / we يتم حسابها أو أخذها من الكويري
    week_start = request.args.get("week_start")
    week_end   = request.args.get("week_end")

    if week_start and week_end:
        ws = parse_date(week_start)
        we = parse_date(week_end)
    else:
        # لو ما جا شيء، استخدم الأسبوع الحالي (عدّلها لو عندك دالة خاصة)
        today = date.today()
        # مثال بسيط: نخلي ws = الأحد، we = الخميس لنفس الأسبوع
        # weekday(): الاثنين=0 ... الأحد=6
        offset_to_sun = (today.weekday() + 1) % 7  # يخلي الأحد = 0
        ws = today - timedelta(days=offset_to_sun)
        we = ws + timedelta(days=4)

    return render_template(
        "eval_form.html",
        employee=emp,
        ws=ws,
        we=we,
        weights=WEIGHTS,
        ev=None  # مهم: وضع إنشاء جديد
    )


@app.route("/evaluate/<int:ev_id>/edit", methods=["GET", "POST"])
@login_required
def evaluate_edit(ev_id):
    u = cur_user()
    ev = Evaluation.query.get_or_404(ev_id)
    emp = db.session.get(Employee, ev.employee_id)

    if not emp:
        abort(404)

    # نفس منطق الصلاحيات في report_employee
    if u.role != "admin" and emp.user_id != u.id:
        abort(403)

    if request.method == "POST":
        try:
            week_start = parse_date(request.form.get("week_start"))
            week_end   = parse_date(request.form.get("week_end"))

            ok, msg = validate_week_sun_to_thu(week_start, week_end)
            if not ok:
                flash(msg, "danger")
                return redirect(url_for("evaluate_edit", ev_id=ev.id))

            # منع تكرار نفس الأسبوع لنفس الموظف (ما عدا هذا السجل)
            dup = (Evaluation.query
                   .filter(
                       Evaluation.employee_id == emp.id,
                       Evaluation.week_start == week_start,
                       Evaluation.week_end == week_end,
                       Evaluation.id != ev.id
                   )
                   .first())
            if dup:
                flash("An evaluation for this week already exists.", "warning")
                return redirect(url_for(
                    "report_employee",
                    emp_id=emp.id,
                    week_start=week_start.isoformat(),
                    week_end=week_end.isoformat()
                ))

            # تحديث الحقول
            ev.week_start = week_start
            ev.week_end   = week_end

            # 1) Targets
            ev.t1_text     = request.form.get("t1_text") or ""
            ev.t2_text     = request.form.get("t2_text") or ""
            ev.t3_text     = request.form.get("t3_text") or ""
            ev.t4_text     = request.form.get("t4_text") or ""
            ev.t1_percent  = request.form.get("t1_percent", type=float)
            ev.t2_percent  = request.form.get("t2_percent", type=float)
            ev.t3_percent  = request.form.get("t3_percent", type=float)
            ev.t4_percent  = request.form.get("t4_percent", type=float)
            ev.t1_remarks  = request.form.get("t1_remarks") or ""
            ev.t2_remarks  = request.form.get("t2_remarks") or ""
            ev.t3_remarks  = request.form.get("t3_remarks") or ""
            ev.t4_remarks  = request.form.get("t4_remarks") or ""

            # 2) Performance ratings
            ev.p_punctuality   = request.form.get("p_punctuality", type=int)
            ev.p_quality       = request.form.get("p_quality", type=int)
            ev.p_productivity  = request.form.get("p_productivity", type=int)
            ev.p_communication = request.form.get("p_communication", type=int)
            ev.p_problemsolving = request.form.get("p_problemsolving", type=int)
            ev.p_compliance    = request.form.get("p_compliance", type=int)

            # 2) Performance comments
            ev.c_punctuality   = request.form.get("c_punctuality") or ""
            ev.c_quality       = request.form.get("c_quality") or ""
            ev.c_productivity  = request.form.get("c_productivity") or ""
            ev.c_communication = request.form.get("c_communication") or ""
            ev.c_problemsolving = request.form.get("c_problemsolving") or ""
            ev.c_compliance    = request.form.get("c_compliance") or ""

            # 3) Summary
            ev.strengths       = request.form.get("strengths") or ""
            ev.improvements    = request.form.get("improvements") or ""
            ev.training_needed = request.form.get("training_needed") or ""

            # إعادة حساب الدرجات
            compute_scores(ev)
            db.session.commit()

            flash("Evaluation updated.", "success")
            return redirect(url_for(
                "report_employee",
                emp_id=emp.id,
                week_start=week_start.isoformat(),
                week_end=week_end.isoformat()
            ))
        except Exception:
            db.session.rollback()
            flash("Error while updating evaluation.", "danger")
            return redirect(url_for("evaluate_edit", ev_id=ev.id))

    # GET → افتح نفس نموذج التقييم لكن مع تعبئة البيانات
    ws = ev.week_start
    we = ev.week_end
    return render_template("eval_form.html", employee=emp, ws=ws, we=we, weights=WEIGHTS, ev=ev)


# ----- Reports picker (generic) -----
@app.route("/reports")
@login_required
def reports_picker():
    ws, we = default_week_today()
    return render_template("report_picker.html", ws=ws, we=we)

# ----- Employee report (detailed) -----
@app.route("/reports/employee/<int:emp_id>")
@login_required
def report_employee(emp_id):
    u = cur_user()
    # admin can view any employee; supervisor only his own
    if u.role == "admin":
        emp = Employee.query.get_or_404(emp_id)
    else:
        emp = Employee.query.filter_by(id=emp_id, user_id=u.id).first_or_404()

    week_start = request.args.get("week_start")
    week_end = request.args.get("week_end")
    if not week_start or not week_end:
        flash("Missing week dates.", "warning")
        return redirect(url_for("employees"))

    ws = parse_date(week_start); we = parse_date(week_end)
    ev = Evaluation.query.filter_by(employee_id=emp.id, week_start=ws, week_end=we).first_or_404()

    evaluator = db.session.get(User, ev.evaluator_id)
    evaluator_code = evaluator.supervisor_code if evaluator else ""
    evaluator_name = evaluator.name if (evaluator and evaluator.name) else ""

    return render_template(
        "report_employee.html",
        employee=emp,
        ev=ev,
        evaluator_code=evaluator_code,
        evaluator_name=evaluator_name,
    )

# ----- Supervisor reports picker (for supervisors) -----
@app.route("/reports/supervisor/select", methods=["GET", "POST"])
@login_required
def supervisor_report_select():
    u = cur_user()
    employees = Employee.query.filter_by(user_id=u.id, is_active=True).order_by(Employee.name.asc()).all()

    if request.method == "POST":
        emp_id = int(request.form["emp_id"])
        ws = parse_date(request.form["week_start"])
        we = parse_date(request.form["week_end"])
        ok, msg = validate_week_sun_to_thu(ws, we)
        if not ok:
            flash(msg, "danger")
            return redirect(url_for("supervisor_report_select"))
        return redirect(url_for("report_employee",
                                emp_id=emp_id,
                                week_start=ws.isoformat(),
                                week_end=we.isoformat()))
    ws, we = default_week_today()
    return render_template("supervisor_report_picker.html", employees=employees, ws=ws, we=we)

# ----- Admin: Reports picker -----
@app.route("/admin/reports", methods=["GET", "POST"])
@admin_required
def admin_report_picker():
    if request.method == "POST":
        ws = parse_date(request.form["week_start"])
        we = parse_date(request.form["week_end"])
        ok, msg = validate_week_sun_to_thu(ws, we)
        if not ok:
            flash(msg, "danger")
            return redirect(url_for("admin_report_picker"))
        return redirect(url_for("admin_reports_all",
                                week_start=ws.isoformat(),
                                week_end=we.isoformat()))
    ws, we = default_week_today()
    return redirect(url_for("admin_reports_weekly",
                                week_start=ws.isoformat(),
                                week_end=we.isoformat()))

# ----- Admin: consolidated employee reports -----
@app.route("/admin/reports/all")
@admin_required
def admin_reports_all():
    week_start = request.args.get("week_start")
    week_end   = request.args.get("week_end")
    q = (request.args.get("q") or "").strip()

    if not (week_start and week_end):
        return redirect(url_for("admin_report_picker"))

    ws = parse_date(week_start)
    we = parse_date(week_end)

    # حدّد سوبرفايزر من نص البحث (ID أو اسم مطابق تمامًا)
    focus_sup = find_supervisor_from_query(q)

    # الاستعلام الأساسي
    query = (db.session.query(Evaluation, Employee, User)
             .join(Employee, Evaluation.employee_id == Employee.id)
             .join(User, Employee.user_id == User.id)
             .filter(Evaluation.week_start == ws, Evaluation.week_end == we))

    if focus_sup:
        query = query.filter(Employee.user_id == focus_sup.id)

    if q and not focus_sup:
        like = f"%{q}%"
        query = query.filter(or_(
            Employee.name.ilike(like),
            Employee.emp_number.ilike(like),
            Employee.department.ilike(like),
            Employee.site.ilike(like),
            User.supervisor_code.ilike(like),
            Evaluation.overall_band.ilike(like),
        ))

    rows = query.order_by(User.supervisor_code.asc(), Employee.name.asc()).all()

    # ----- KPI + غير المُقيّمين عند تحديد سوبرفايزر -----
    sup_cov_pct = None
    missing_emps = []
    total_emp = 0
    done_emp_count = 0

    if focus_sup:
        emps = (Employee.query
                .filter_by(user_id=focus_sup.id, is_active=True)
                .order_by(Employee.name.asc())
                .all())
        total_emp = len(emps)
        if total_emp > 0:
            emp_ids = [e.id for e in emps]
            done_ids = set(
                r[0] for r in db.session.query(Evaluation.employee_id)
                .filter(Evaluation.week_start == ws,
                        Evaluation.week_end == we,
                        Evaluation.employee_id.in_(emp_ids))
                .all()
            )
            done_emp_count = len(done_ids)
            sup_cov_pct = (done_emp_count / total_emp) * 100.0
            missing_emps = [e for e in emps if e.id not in done_ids]

    # ----- قائمة السوبرفايزر + تفريد المقترحات للـ datalist -----
    supervisors = (User.query
                   .filter_by(role="supervisor", is_active=True)
                   .order_by(User.name.asc(), User.supervisor_code.asc())
                   .all())

    # نحضّر [(value, label)] بدون تكرار (case-insensitive)
    sup_suggestions = []
    seen = set()

    # أولاً: قيم الـID (هي فريدة غالبًا)
    for s in supervisors:
        val = (s.supervisor_code or "").strip()
        if not val:
            continue
        key = val.lower()
        if key in seen:
            continue
        label = f"{s.name or '—'} — ID: {s.supervisor_code}"
        sup_suggestions.append((val, label))
        seen.add(key)

    # ثانيًا: الأسماء (قد تتكرر، لذلك نفردها)
    for s in supervisors:
        nm = (s.name or "").strip()
        if not nm:
            continue
        key = nm.lower()
        if key in seen:
            continue
        label = f"{nm} — ID: {s.supervisor_code}"
        sup_suggestions.append((nm, label))
        seen.add(key)

    return render_template(
        "report_admin_all.html",
        ws=ws, we=we, rows=rows, q=q,
        focus_sup=focus_sup,
        sup_cov_pct=sup_cov_pct,
        total_emp=total_emp,
        done_emp_count=done_emp_count,
        missing_emps=missing_emps,
        supervisors=supervisors,
        sup_suggestions=sup_suggestions,  # ← استخدم هذه في القالب
    )

@app.route("/admin/reports/weekly")
@admin_required
def admin_reports_weekly():
    week_start = request.args.get("week_start")
    week_end   = request.args.get("week_end")
    q = (request.args.get("q") or "").strip()

    # لو ما فيه تاريخ نرجع لصفحة الاختيار
    if not (week_start and week_end):
        return redirect(url_for("admin_report_picker"))

    ws = parse_date(week_start)
    we = parse_date(week_end)

    # نحاول نحدد سوبرفايزر من البحث (ID أو اسم)
    focus_sup = find_supervisor_from_query(q)

    # الاستعلام الأساسي: التقييمات الأسبوعية
    query = (db.session.query(Evaluation, Employee, User)
             .join(Employee, Evaluation.employee_id == Employee.id)
             .join(User, Employee.user_id == User.id)
             .filter(Evaluation.week_start == ws,
                     Evaluation.week_end == we))

    # لو حددنا سوبرفايزر نفلتر عليه
    if focus_sup:
        query = query.filter(Employee.user_id == focus_sup.id)

    # لو فيه بحث عام وما لقينا سوبرفايزر
    if q and not focus_sup:
        like = f"%{q}%"
        query = query.filter(or_(
            Employee.name.ilike(like),
            Employee.emp_number.ilike(like),
            Employee.department.ilike(like),
            Employee.site.ilike(like),
            User.supervisor_code.ilike(like),
            Evaluation.overall_band.ilike(like),
        ))

    rows = query.order_by(User.supervisor_code.asc(), Employee.name.asc()).all()

    # KPI لو كان فيه سوبرفايزر محدد
    sup_cov_pct = None
    missing_emps = []
    total_emp = 0
    done_emp_count = 0

    if focus_sup:
        emps = (Employee.query
                .filter_by(user_id=focus_sup.id, is_active=True)
                .order_by(Employee.name.asc())
                .all())
        total_emp = len(emps)
        if total_emp > 0:
            emp_ids = [e.id for e in emps]
            done_ids = set(
                r[0] for r in db.session.query(Evaluation.employee_id)
                .filter(Evaluation.week_start == ws,
                        Evaluation.week_end == we,
                        Evaluation.employee_id.in_(emp_ids))
                .all()
            )
            done_emp_count = len(done_ids)
            sup_cov_pct = (done_emp_count / total_emp) * 100.0
            missing_emps = [e for e in emps if e.id not in done_ids]

    # نجهز قائمة السوبرفايزر عشان الـ datalist
    supervisors = (User.query
                   .filter_by(role="supervisor", is_active=True)
                   .order_by(User.name.asc(), User.supervisor_code.asc())
                   .all())
    sup_suggestions = []
    seen = set()
    for s in supervisors:
        key = f"ID:{s.supervisor_code}"
        sup_suggestions.append((s.supervisor_code, f"{s.name or '—'} — ID: {s.supervisor_code}"))
        seen.add(key)
    for s in supervisors:
        nm = (s.name or "").strip()
        if not nm:
            continue
        key = nm.lower()
        if key in seen:
            continue
        sup_suggestions.append((nm, f"{nm} — ID: {s.supervisor_code}"))
        seen.add(key)

    return render_template(
        "report_admin_weekly.html",
        ws=ws, we=we,
        rows=rows,
        q=q,
        focus_sup=focus_sup,
        sup_cov_pct=sup_cov_pct,
        total_emp=total_emp,
        done_emp_count=done_emp_count,
        missing_emps=missing_emps,
        sup_suggestions=sup_suggestions,
    )


# ----- Supervisor weekly list (own employees) -----
@app.route("/reports/supervisor")
@login_required
def report_supervisor():
    u = cur_user()
    week_start = request.args.get("week_start"); week_end = request.args.get("week_end")
    if not week_start or not week_end:
        flash("Choose a week (start & end).", "warning")
        return redirect(url_for("employees"))
    ws = parse_date(week_start); we = parse_date(week_end)
    evals = (db.session.query(Evaluation, Employee)
             .join(Employee, Evaluation.employee_id == Employee.id)
             .filter(Employee.user_id == u.id,
                     Evaluation.week_start == ws, Evaluation.week_end == we)
             .order_by(Employee.name.asc()).all())
    return render_template("report_supervisor.html", user=u, ws=ws, we=we, evals=evals)

# ----- Admin: All Employees + search + history -----
@app.route("/admin/employees")
@admin_required
def admin_employees():
    q = (request.args.get("q") or "").strip()

    emp_q = (db.session.query(Employee, User)
             .join(User, Employee.user_id == User.id))
    if q:
        like = f"%{q}%"
        emp_q = emp_q.filter(or_(
            Employee.name.ilike(like),
            Employee.emp_number.ilike(like),
            Employee.department.ilike(like),
            Employee.site.ilike(like),
            User.supervisor_code.ilike(like),
            User.name.ilike(like),
        ))
    emp_rows = emp_q.order_by(User.supervisor_code.asc(), Employee.name.asc()).all()

    users_q = User.query.filter(User.role.in_(["supervisor", "site_supervisor"]))
    if q:
        like = f"%{q}%"
        users_q = users_q.filter(or_(
            User.supervisor_code.ilike(like),
            User.name.ilike(like),
            User.role.ilike(like),
        ))
    users = users_q.order_by(User.supervisor_code.asc()).all()

    return render_template("admin_employees.html", rows=emp_rows, users=users, q=q)

@app.route("/admin/employee/<int:emp_id>/history")
@admin_required
def admin_employee_history(emp_id):
    emp = Employee.query.get_or_404(emp_id)
    evals = (Evaluation.query.filter_by(employee_id=emp.id)
             .order_by(Evaluation.week_start.desc()).all())
    return render_template("employee_history.html", emp=emp, evals=evals)

# ===================== Site Supervisor Features =====================
# Manage assigned supervisors
@app.route("/site/supervisors", methods=["GET", "POST"])
@login_required
def site_supervisors():
    u = cur_user()
    if u.role != "site_supervisor":
        abort(403)

    if request.method == "POST":
        sup_code = (request.form.get("supervisor_code") or "").strip()
        sup_name = (request.form.get("supervisor_name") or "").strip()
        if not sup_code:
            flash("Please enter a Supervisor ID.", "danger")
            return redirect(url_for("site_supervisors"))

        # جرّب نلقى مستخدم بهذا الـID
        sup_user = User.query.filter_by(supervisor_code=sup_code).first()

        # لو ما وُجد: أنشئه كمشرف (Supervisor) مفعَّل
        if not sup_user:
            sup_user = User(
                supervisor_code=sup_code,
                name=sup_name,
                role="supervisor",
                is_active=True
            )
            db.session.add(sup_user)
            db.session.commit()
            flash("Supervisor user created and assigned.", "success")
        else:
            # لو موجود لكنه مو مشرف، ما نسمح بربطه
            if sup_user.role != "supervisor":
                flash("This ID exists but is not a Supervisor role.", "danger")
                return redirect(url_for("site_supervisors"))
            if not sup_user.is_active:
                flash("This Supervisor is inactive. Ask Admin to activate.", "warning")
                return redirect(url_for("site_supervisors"))

        # اربطه إن ما كان مرتبط مسبقًا
        exists = SiteSupervisorMap.query.filter_by(site_sup_id=u.id, supervisor_id=sup_user.id).first()
        if exists:
            flash("This supervisor is already assigned.", "warning")
        else:
            link = SiteSupervisorMap(site_sup_id=u.id, supervisor_id=sup_user.id)
            db.session.add(link)
            db.session.commit()
            flash("Supervisor assigned.", "success")

        return redirect(url_for("site_supervisors"))

    links = (db.session.query(SiteSupervisorMap, User)
             .join(User, SiteSupervisorMap.supervisor_id == User.id)
             .filter(SiteSupervisorMap.site_sup_id == u.id).all())
    return render_template("site_supervisors.html", links=links)

@app.post("/site/supervisors/<int:link_id>/remove")
@login_required
def site_supervisors_remove(link_id):
    u = cur_user()
    if u.role != "site_supervisor":
        abort(403)
    link = SiteSupervisorMap.query.get_or_404(link_id)
    if link.site_sup_id != u.id:
        abort(403)
    db.session.delete(link)
    db.session.commit()
    flash("Removed.", "success")
    return redirect(url_for("site_supervisors"))

# New evaluation for a supervisor
@app.route("/site/evaluate/<int:sup_user_id>/new", methods=["GET", "POST"])
@login_required
def site_evaluate_new(sup_user_id):
    u = cur_user()
    if u.role != "site_supervisor":
        abort(403)

    # تأكد أنه ضمن قائمته
    link = SiteSupervisorMap.query.filter_by(site_sup_id=u.id, supervisor_id=sup_user_id).first()
    if not link:
        abort(403)

    supervisor = User.query.get_or_404(sup_user_id)
    if request.method == "POST":
        ws = parse_date(request.form.get("week_start"))
        we = parse_date(request.form.get("week_end"))
        ok, msg = validate_week_sun_to_thu(ws, we)
        if not ok:
            flash(msg, "danger")
            return redirect(url_for("site_evaluate_new", sup_user_id=sup_user_id))

        if SupervisorEvaluation.query.filter_by(supervisor_id=sup_user_id, week_start=ws, week_end=we).first():
            flash("An evaluation for this supervisor already exists this week.", "warning")
            return redirect(url_for("site_report_supervisor", sup_user_id=sup_user_id,
                                    week_start=ws.isoformat(), week_end=we.isoformat()))

        se = SupervisorEvaluation(
            supervisor_id=sup_user_id, evaluator_id=u.id,
            week_start=ws, week_end=we,

            # Targets
            t1_text=request.form.get("t1_text",""), t1_percent=float(request.form.get("t1_percent") or 0), t1_remarks=request.form.get("t1_remarks",""),
            t2_text=request.form.get("t2_text",""), t2_percent=float(request.form.get("t2_percent") or 0), t2_remarks=request.form.get("t2_remarks",""),
            t3_text=request.form.get("t3_text",""), t3_percent=float(request.form.get("t3_percent") or 0), t3_remarks=request.form.get("t3_remarks",""),
            t4_text=request.form.get("t4_text",""), t4_percent=float(request.form.get("t4_percent") or 0), t4_remarks=request.form.get("t4_remarks",""),

            # Performance
            p_punctuality=int(request.form.get("p_punctuality") or 0), c_punctuality=request.form.get("c_punctuality",""),
            p_quality=int(request.form.get("p_quality") or 0), c_quality=request.form.get("c_quality",""),
            p_productivity=int(request.form.get("p_productivity") or 0), c_productivity=request.form.get("c_productivity",""),
            p_communication=int(request.form.get("p_communication") or 0), c_communication=request.form.get("c_communication",""),
            p_problemsolving=int(request.form.get("p_problemsolving") or 0), c_problemsolving=request.form.get("c_problemsolving",""),
            p_compliance=int(request.form.get("p_compliance") or 0), c_compliance=request.form.get("c_compliance",""),

            strengths=request.form.get("strengths",""),
            improvements=request.form.get("improvements",""),
            training_needed=request.form.get("training_needed",""),
        )

        # نفس المعادلة بالضبط
        compute_scores(se)
        db.session.add(se)
        db.session.commit()
        flash("Supervisor evaluation saved.", "success")
        return redirect(url_for("site_report_supervisor", sup_user_id=sup_user_id,
                                week_start=ws.isoformat(), week_end=we.isoformat()))

    ws, we = default_week_today()
    return render_template("site_eval_form.html", supervisor=supervisor, ws=ws, we=we, weights=WEIGHTS)

# Site supervisor report picker
@app.route("/site/reports/select", methods=["GET", "POST"])
@login_required
def site_report_select():
    u = cur_user()
    if u.role != "site_supervisor":
        abort(403)
    links = (db.session.query(SiteSupervisorMap, User)
             .join(User, SiteSupervisorMap.supervisor_id == User.id)
             .filter(SiteSupervisorMap.site_sup_id == u.id).all())
    supervisors = [su for _, su in links]

    if request.method == "POST":
        sup_user_id = int(request.form["sup_user_id"])
        ws = parse_date(request.form["week_start"])
        we = parse_date(request.form["week_end"])
        ok, msg = validate_week_sun_to_thu(ws, we)
        if not ok:
            flash(msg, "danger")
            return redirect(url_for("site_report_select"))
        return redirect(url_for("site_report_supervisor",
                                sup_user_id=sup_user_id,
                                week_start=ws.isoformat(),
                                week_end=we.isoformat()))
    ws, we = default_week_today()
    return render_template("site_report_picker.html", supervisors=supervisors, ws=ws, we=we)

# Detailed supervisor report
@app.route("/site/reports/supervisor/<int:sup_user_id>")
@login_required
def site_report_supervisor(sup_user_id):
    u = cur_user()
    if u.role not in ["site_supervisor", "admin"]:
        abort(403)
    if u.role == "site_supervisor":
        link = SiteSupervisorMap.query.filter_by(site_sup_id=u.id, supervisor_id=sup_user_id).first()
        if not link:
            abort(403)

    week_start = request.args.get("week_start")
    week_end = request.args.get("week_end")
    if not (week_start and week_end):
        flash("Missing week dates.", "warning")
        return redirect(url_for("site_report_select") if u.role == "site_supervisor" else url_for("admin_site_report_picker"))

    ws = parse_date(week_start); we = parse_date(week_end)
    se = SupervisorEvaluation.query.filter_by(supervisor_id=sup_user_id, week_start=ws, week_end=we).first_or_404()
    supervisor = User.query.get_or_404(sup_user_id)
    evaluator = User.query.get(se.evaluator_id)
    return render_template("site_report_supervisor.html", se=se, supervisor=supervisor, evaluator=evaluator)

@app.route("/site/daily/reports")
@login_required
def site_daily_reports_site():
    u = cur_user()
    if u.role != "site_supervisor":
        abort(403)

    # تاريخ اليوم أو اللي اختاره
    d_s = request.args.get("d")
    if d_s:
        d_val = parse_date(d_s)
    else:
        d_val = date.today()

    # المشرفين اللي تابعين لهذا الـ site supervisor
    links = (db.session.query(SiteSupervisorMap, User)
             .join(User, SiteSupervisorMap.supervisor_id == User.id)
             .filter(SiteSupervisorMap.site_sup_id == u.id)
             .all())
    sup_ids = [su.id for _, su in links]

    # نفس استعلام صفحة /daily/reports لكن مفلتر على اللي فوق
    q = (db.session.query(DailyEvaluation, Employee)
         .join(Employee, DailyEvaluation.employee_id == Employee.id)
         .filter(DailyEvaluation.eval_date == d_val))

    if sup_ids:
        q = q.filter(Employee.user_id.in_(sup_ids))

    rows = (q.order_by(Employee.name.asc()).all())

    # نستخدم نفس التمبليت الجاهز
    return render_template("daily_reports.html", rows=rows, d=d_val)
    
@app.route("/site/attendance")
@login_required
def site_attendance_site():
    u = cur_user()
    if u.role != "site_supervisor":
        abort(403)

    d_s = request.args.get("d")
    if d_s:
        d_val = parse_date(d_s)
    else:
        d_val = date.today()

    # اشوف المشرفين اللي تحت هذا الـ site sup
    links = (db.session.query(SiteSupervisorMap, User)
             .join(User, SiteSupervisorMap.supervisor_id == User.id)
             .filter(SiteSupervisorMap.site_sup_id == u.id)
             .all())
    sup_ids = [su.id for _, su in links]

    # هذا يفترض إن عندك موديل Attendance بنفس شكل admin
    q = (db.session.query(Attendance, Employee, User)
         .join(Employee, Attendance.employee_id == Employee.id)
         .join(User, Employee.user_id == User.id)
         .filter(Attendance.att_date == d_val))

    if sup_ids:
        q = q.filter(Employee.user_id.in_(sup_ids))

    rows = q.order_by(User.name.asc(), Employee.name.asc()).all()

    # نرجّع نفس قالب الحضور اللي عندك
    return render_template("attendance_admin.html", rows=rows, d=d_val)

@app.route("/site/requests")
@login_required
def site_requests_site():
    u = cur_user()
    if u.role != "site_supervisor":
        abort(403)

    # المشرفين اللي تحته
    links = (db.session.query(SiteSupervisorMap, User)
             .join(User, SiteSupervisorMap.supervisor_id == User.id)
             .filter(SiteSupervisorMap.site_sup_id == u.id)
             .all())
    sup_ids = [su.id for _, su in links]

    # نجيب الطلبات اللي أنشأها هؤلاء المشرفون
    req_q = (RequestItem.query
             .filter(RequestItem.created_by.in_(sup_ids))
             .order_by(RequestItem.created_at.desc()))
    items = req_q.all()

    # نستخدم نفس القالب
    return render_template("requests_inbox.html", items=items)

@app.route("/site/daily/report/<int:emp_id>")
@login_required
def site_daily_report_employee(emp_id):
    u = cur_user()
    if u.role != "site_supervisor":
        abort(403)

    d_str = request.args.get("d")
    if not d_str:
        flash("Missing date.", "warning")
        return redirect(url_for("site_daily_reports_site"))
    d_val = parse_date(d_str)

    # الموظف
    emp = Employee.query.get_or_404(emp_id)

    # تأكد أن الموظف يتبع مشرف من مشرفين هذا الـ site supervisor
    link = (db.session.query(SiteSupervisorMap)
            .filter_by(site_sup_id=u.id, supervisor_id=emp.user_id)
            .first())
    if not link:
        abort(403)

    # التقييم اليومي نفسه
    de = (DailyEvaluation.query
          .filter_by(employee_id=emp_id, eval_date=d_val)
          .first_or_404())

    # نستعمل نفس القالب اللي تستعمله للمشرف العادي
    return render_template("daily_report_employee.html",
                           employee=emp,
                           de=de,
                           d=d_val)



# ----- Admin: Site reviews picker & consolidated -----
@app.route("/admin/site/reports", methods=["GET", "POST"])
@admin_required
def admin_site_report_picker():
    if request.method == "POST":
        ws = parse_date(request.form["week_start"])
        we = parse_date(request.form["week_end"])
        ok, msg = validate_week_sun_to_thu(ws, we)
        if not ok:
            flash(msg, "danger")
            return redirect(url_for("admin_site_report_picker"))
        return redirect(url_for("admin_site_reports_all",
                                week_start=ws.isoformat(),
                                week_end=we.isoformat()))
    ws, we = default_week_today()
    return render_template("site_admin_picker.html", ws=ws, we=we)

@app.route("/admin/site/reports/all")
@admin_required
def admin_site_reports_all():
    week_start = request.args.get("week_start")
    week_end   = request.args.get("week_end")
    q_raw = request.args.get("q") or ""
    q = q_raw.strip().lower()

    if not (week_start and week_end):
        return redirect(url_for("admin_site_report_picker"))

    ws = parse_date(week_start); we = parse_date(week_end)

    # اجلب جميع تقييمات الأسبوع واربط الأسماء يدويًا (أضمن من joins متعددة على User)
    rows = []
    se_list = SupervisorEvaluation.query.filter_by(week_start=ws, week_end=we).all()
    for se in se_list:
        sup_user  = db.session.get(User, se.supervisor_id)   # المشرف المُقيَّم
        site_user = db.session.get(User, se.evaluator_id)    # مشرف السايت المُقيِّم

        if q:
            hay = " ".join([
                sup_user.name or "", sup_user.supervisor_code or "",
                site_user.name or "", site_user.supervisor_code or "",
                se.overall_band or ""
            ]).lower()
            if q not in hay:
                continue
        rows.append((se, sup_user, site_user))

    return render_template("site_admin_all.html", ws=ws, we=we, rows=rows, q=q_raw)

import traceback

@app.errorhandler(404)
def _not_found(e):
    app.logger.error("404 path=%s method=%s", request.path, request.method)
    return "Not Found", 404

# ===================== Bootstrapping =====================
# على الاستضافة: Passenger يستورد الملف فقط، لذا ننادي الإنشاء هنا:
ensure_db_and_admin()

# نقطة دخول WSGI لاسم "application"
application = app

# للتشغيل المحلي فقط
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)
