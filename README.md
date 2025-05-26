# CodeGuardian 🛡️  
*A lightweight, security-aware compiler enhancement for C/C++ code.*

## 🔍 Overview

**CodeGuardian** is a real-time, static analysis tool designed to detect and prevent unsafe coding practices in C/C++ programs during the compilation phase. Unlike traditional security tools that run post-development, CodeGuardian integrates directly into the compiler pipeline, providing **context-aware security feedback as code is written**.

By embedding security checks in the development lifecycle, it helps developers identify vulnerabilities like buffer overflows, use of unsafe functions, uninitialized variables, and more — **before code reaches production**.

---

## 🚀 Features

- ✅ **Buffer Overflow Detection** via array bounds checking  
- ✅ **Use of Uninitialized Variables**  
- ✅ **Detection of Unsafe Functions** (e.g., `gets()`, `strcpy()`)  
- ✅ **Use of Undeclared Variables**  
- ✅ **Developer-Friendly Warnings** with educational insights  
- ✅ **Lightweight & Fast** – Designed to be part of daily development workflows  
- ✅ **Web Interface + API** for easy access and integration  

---

## 🔧 Architecture

**CodeGuardian** follows a modular, layered architecture:

### 📦 Components
- **Frontend:**  
  - HTML/JS interface for file uploads  
  - Sends C/C++ source files to the backend via HTTP POST

- **Backend:**  
  - Python Flask API (`/upload` endpoint)  
  - Receives and validates uploaded files  
  - Executes static analysis via `run_all.sh` script  
  - Returns structured JSON output or detailed error messages

- **Compiler Engine:**  
  - Built using **Lex** (`lexer.l`) and **Yacc** (`parser.y`)  
  - Integrates custom **C/C++ analysis modules**  
  - Performs lexical, syntactic, and semantic checks  
  - Modules:
    - `comment_remover.l`: Removes comments pre-analysis  
    - `lexer.l`: Tokenizes input code  
    - `parser.y`: Parses tokens and triggers security warnings  

---

## 🧪 Testing & Validation

- Uploaded known-vulnerable files to validate detection accuracy  
- Tested error handling with malformed and incomplete inputs  
- Verified timeout mechanism to prevent long-running processes  
- Validated JSON report format for consistency and clarity  

---

## 🌐 Deployment

- Backend runs on a **local Flask server** (e.g., WSL or native Python env)  
- Frontend connects to backend via **HTTP**  
- Modular system supports future deployment on cloud or production-grade servers  

---

## 🎓 Why CodeGuardian?

- 📘 Perfect for **students and educators** to teach secure C/C++ programming  
- 🧪 Valuable for **researchers** analyzing unsafe coding patterns  
- 🛠️ Useful for **engineering teams** maintaining legacy or embedded C/C++ systems  
- 🔄 Ideal for **CI/CD pipelines** to enforce secure development practices  

---

## 📚 Tech Stack

- **Frontend:** HTML, JavaScript  
- **Backend:** Python Flask  
- **Compiler Engine:** Lex, Yacc, C++  
- **Shell Script:** `run_all.sh` for pipeline coordination  

---

## 📈 Future Scope

- CI/CD integration for automated vulnerability scanning  
- Syntax-aware highlighting in the frontend  
- Cloud-based deployment for scalability  
- Enhanced static analysis coverage (e.g., use-after-free, race conditions)

---

## 👥 Contributors

- **Akansha Rawat** – akansharawat8230@gmail.com  
- **Khushi Kukreti** – khushikukreti0104@gmail.com   
- **Mansi Mehara** – mansimehara27@gmail.com
- **Sneha Yadav** – sneha2503yadav@gmail.com  

> _For questions, feedback, or collaboration inquiries, feel free to reach out!_
