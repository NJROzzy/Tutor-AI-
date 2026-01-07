# 🚀 Tutor AI  "https://tutor-ai-web.vercel.app/" 
Voice-First AI Tutoring Platform for Children (Ages 2–12)

Tutor AI is an AI-powered, voice-based learning platform designed to provide interactive and personalized tutoring for children. The system integrates large language models with speech technologies to enable hands-free, natural learning experiences.

---

## ✨ Features

- Voice-first interaction using speech input and output
- AI-powered tutor with contextual understanding
- Child profiles with adaptive learning
- Parent dashboard with progress tracking
- Subject-wise performance analytics
- Secure authentication and role-based access

---

## 🛠 Tech Stack

### Frontend
- Flutter (Dart)

### Backend
- Django
- Django REST Framework
- PostgreSQL

### AI & Speech
- Ollama (LLM inference)
- Whisper (Speech-to-Text)
- Coqui TTS (Text-to-Speech)

### DevOps & Deployment
- Docker
- AWS EC2
- Vercel

---

## 🧠 Architecture Overview

Flutter App  
→ REST APIs  
→ Django Backend  
→ PostgreSQL  
→ AI Services (Ollama, Whisper, Coqui)

---

## 📊 Core Modules

- Authentication and authorization
- Parent and child profile management
- Subject and learning profiles
- AI tutor chat service
- Speech processing pipeline
- Progress tracking and analytics

---

## ⚙️ Setup Instructions

### Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
