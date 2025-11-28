
CREATE DATABASE attendance_app;
USE attendance_app;
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    role ENUM('student', 'staff') NOT NULL
);
CREATE TABLE attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    date DATE NOT NULL,
    status ENUM('Present','Absent') NOT NULL,
    FOREIGN KEY (student_id) REFERENCES users(id),
    UNIQUE(student_id, date)   -- prevents double marking same day
);
INSERT INTO users (name, email, password, role)
VALUES
('Ajay', 'ajay@student.com', '1234', 'student'),
('Staff One', 'staff@college.com', 'abcd', 'staff');
SELECT * FROM users;
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    password VARCHAR(100),
    role VARCHAR(20)  -- staff / student
);

CREATE TABLE attendance (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT,
    date DATE,
    status VARCHAR(20),
    UNIQUE(student_id, date)
);
DESCRIBE users;
SELECT * FROM users;






