from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import mysql.connector

app = FastAPI()

# ---------- CORS MIDDLEWARE (Allows Flutter access) ----------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------- DATABASE CONNECTION ----------
def get_conn():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="Mandiajay#2003",    # your MySQL password
        database="attendance_app",
        port=3307                     # MySQL port
    )

# ---------- MODELS ----------
class LoginModel(BaseModel):
    email: str
    password: str

class AttendanceModel(BaseModel):
    student_id: int
    date: str
    status: str

class AddStudentModel(BaseModel):
    name: str
    email: str
    password: str

class ChangePasswordModel(BaseModel):
    user_id: int
    old_password: str
    new_password: str


# ------------------------------------------------------------
#                       LOGIN
# ------------------------------------------------------------
@app.post("/login")
def login(data: LoginModel):
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        "SELECT * FROM users WHERE email=%s AND password=%s",
        (data.email, data.password)
    )
    user = cursor.fetchone()
    conn.close()

    if not user:
        raise HTTPException(401, "Invalid email or password")

    return {
        "id": user["id"],
        "name": user["name"],
        "role": user["role"]
    }


# ------------------------------------------------------------
#              STAFF — ADD NEW STUDENT
# ------------------------------------------------------------
@app.post("/students/add")
def add_student(s: AddStudentModel):
    conn = get_conn()
    cursor = conn.cursor()

    # Check for duplicate email
    cursor.execute("SELECT id FROM users WHERE email=%s", (s.email,))
    existing = cursor.fetchone()

    if existing:
        conn.close()
        raise HTTPException(400, "Email already exists")

    cursor.execute("""
        INSERT INTO users (name, email, password, role)
        VALUES (%s, %s, %s, 'student')
    """, (s.name, s.email, s.password))

    conn.commit()
    conn.close()

    return {"message": "Student Added Successfully"}


# ------------------------------------------------------------
#           STAFF — GET LIST OF ALL STUDENTS
# ------------------------------------------------------------
@app.get("/students")
def get_students():
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT * FROM users WHERE role='student'")
    data = cursor.fetchall()

    conn.close()
    return data


# ------------------------------------------------------------
#     STAFF — MARK OR UPDATE ATTENDANCE
# ------------------------------------------------------------
@app.post("/attendance/set")
def set_attendance(a: AttendanceModel):
    conn = get_conn()
    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO attendance (student_id, date, status)
        VALUES (%s, %s, %s)
        ON DUPLICATE KEY UPDATE status=%s
    """, (a.student_id, a.date, a.status, a.status))

    conn.commit()
    conn.close()
    return {"message": "Attendance Saved"}


# ------------------------------------------------------------
#           STUDENT — VIEW OWN ATTENDANCE
# ------------------------------------------------------------
@app.get("/attendance/student/{student_id}")
def get_attendance(student_id: int):
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT date, status 
        FROM attendance 
        WHERE student_id=%s 
        ORDER BY date DESC
    """, (student_id,))
    
    data = cursor.fetchall()
    conn.close()

    return data


# ------------------------------------------------------------
#           STUDENT — CHANGE PASSWORD
# ------------------------------------------------------------
@app.post("/change-password")
def change_password(data: ChangePasswordModel):
    conn = get_conn()
    cursor = conn.cursor(dictionary=True)

    # Check old password
    cursor.execute(
        "SELECT * FROM users WHERE id=%s AND password=%s",
        (data.user_id, data.old_password)
    )
    user = cursor.fetchone()

    if not user:
        conn.close()
        raise HTTPException(400, "Old password is incorrect")

    # Update new password
    cursor.execute(
        "UPDATE users SET password=%s WHERE id=%s",
        (data.new_password, data.user_id)
    )
    conn.commit()
    conn.close()

    return {"message": "Password updated successfully"}
