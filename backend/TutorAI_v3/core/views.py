from django.shortcuts import render
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from django.http import HttpResponse

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework.authtoken.models import Token
from rest_framework.authentication import TokenAuthentication

from django.contrib.auth import get_user_model

from .serializers import SignupSerializer, LoginSerializer, ChildProfileSerializer
from .models import ChildProfile

import requests
import io
import numpy as np
from scipy.io.wavfile import write as wav_write
import tempfile
import os
import whisper 

_WHISPER_MODEL = whisper.load_model("base")

from TTS.api import TTS

try:
    import whisper
    _WHISPER_MODEL = whisper.load_model("base")
except Exception:
    _WHISPER_MODEL = None

# ---------- AUTH VIEWS ----------

@method_decorator(csrf_exempt, name='dispatch')
class SignupView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = SignupSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token, _ = Token.objects.get_or_create(user=user)
            return Response({
                'message': 'Signup successful',
                'token': token.key,
                'user': {
                    'id': user.id,
                    'email': user.email,
                    'username': user.username,
                    'full_name': f"{user.first_name} {user.last_name}",
                }
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@method_decorator(csrf_exempt, name='dispatch')
class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email'].strip().lower()
        password = serializer.validated_data['password']

        User = get_user_model()
        try:
            user = User.objects.get(email__iexact=email)
        except User.DoesNotExist:
            return Response({'detail': 'Invalid credentials'},
                            status=status.HTTP_401_UNAUTHORIZED)

        if not user.check_password(password):
            return Response({'detail': 'Invalid credentials'},
                            status=status.HTTP_401_UNAUTHORIZED)

        token, _ = Token.objects.get_or_create(user=user)
        return Response({'token': token.key}, status=status.HTTP_200_OK)


# ---------- CHILD PROFILE VIEWS ----------

class ChildProfileListCreateView(APIView):
    """
    GET  /api/children/   -> list children for the logged-in parent
    POST /api/children/   -> create a child for the logged-in parent
    """
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        children = ChildProfile.objects.filter(parent=request.user)
        serializer = ChildProfileSerializer(children, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = ChildProfileSerializer(data=request.data)
        if serializer.is_valid():
            child = serializer.save(parent=request.user)
            out = ChildProfileSerializer(child).data
            return Response(out, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ---------- SIMPLE HTML PAGES ----------

def signup_page(request):
    return render(request, 'core/signup.html')


def login_page(request):
    return render(request, 'core/login.html')


# ---------- LLaMA (Ollama) CHAT ----------

OLLAMA_URL = "http://127.0.0.1:11434/api/chat"
OLLAMA_MODEL = "llama3.2:3b"  # small local model

@method_decorator(csrf_exempt, name='dispatch')
class TutorChatView(APIView):
    """
    POST /api/auth/tutor/chat/
    Body: { "subject": "math"|"english", "message": "..." }
    """

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        subject = (request.data.get('subject') or 'math').lower()
        user_message = request.data.get('message') or ''

        if not user_message.strip():
            return Response(
                {"detail": "Message is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if subject == 'math':
            system_prompt = (
                "You are a very friendly math tutor for kids aged 2-12. "
                "Explain concepts with very simple words, short sentences, and fun examples. "
                "Speak like you are talking directly to the child."
            )
        else:
            system_prompt = (
                "You are a very friendly English tutor for kids aged 2-12. "
                "Help with reading, simple grammar, vocabulary, and speaking practice. "
                "Use very simple words and short sentences."
            )

        payload = {
            "model": OLLAMA_MODEL,
            "stream": False,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message},
            ],
        }

        try:
            r = requests.post(OLLAMA_URL, json=payload, timeout=120)
        except requests.RequestException as e:
            return Response(
                {"detail": "Failed to reach Ollama", "error": str(e)},
                status=status.HTTP_502_BAD_GATEWAY,
            )

        if r.status_code != 200:
            return Response(
                {
                    "detail": "Ollama returned an error",
                    "status": r.status_code,
                    "body": r.text,
                },
                status=status.HTTP_502_BAD_GATEWAY,
            )

        data = r.json()
        reply = (
            data.get("message", {}).get("content")
            or data.get("choices", [{}])[0]
                .get("message", {})
                .get("content", "")
        )

        if not reply:
            return Response(
                {"detail": "No content from model", "raw": data},
                status=status.HTTP_502_BAD_GATEWAY,
            )

        return Response({"reply": reply}, status=status.HTTP_200_OK)


# ---------- Coqui TTS (audio/wav) ----------

_TTS_ENGINE = None

def get_tts_engine():
    """
    Lazily load the Coqui TTS model once per process.
    """
    global _TTS_ENGINE
    if _TTS_ENGINE is None:
        _TTS_ENGINE = TTS(
            model_name="tts_models/en/vctk/vits",
            progress_bar=False,
            gpu=False,  # CPU-only for now
        )
    return _TTS_ENGINE


@method_decorator(csrf_exempt, name='dispatch')
class TutorTTSView(APIView):
    """
    POST /api/auth/tutor/tts/
    Body: { "text": "...", "speaker": "p335" (optional) }
    Returns: raw WAV bytes (audio/wav).
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        text = (request.data.get('text') or '').strip()
        if not text:
            return Response(
                {'detail': 'Field "text" is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 👇 allow client to override, otherwise default to a "teacher" voice
        speaker_id = request.data.get('speaker') or "p335"

        tts = get_tts_engine()

        # 1) synthesize to numpy array (float)
        wav = tts.tts(
            text=text,
            speaker=speaker_id,
            language=None,  # English default
        )

        # 2) get sample rate (or default)
        try:
            sample_rate = tts.synthesizer.output_sample_rate
        except Exception:
            sample_rate = 22050

        # 3) encode WAV to bytes in-memory as 16-bit PCM
        buf = io.BytesIO()
        wav_np = np.array(wav, dtype=np.float32)

        wav_clipped = np.clip(wav_np, -1.0, 1.0)
        wav_int16 = (wav_clipped * 32767).astype(np.int16)

        wav_write(buf, int(sample_rate), wav_int16)
        buf.seek(0)

        # 4) return as audio/wav
        resp = HttpResponse(buf.read(), content_type='audio/wav')
        resp['Content-Disposition'] = 'inline; filename="tutor_tts.wav"'
        return resp


@method_decorator(csrf_exempt, name="dispatch")
class TutorSTTView(APIView):
    """
    POST /api/auth/tutor/stt/
    Body: raw audio bytes from the browser (audio/wav).
    Returns: { "text": "transcribed text" }
    """

    permission_classes = []  # AllowAny

    def post(self, request, *args, **kwargs):
        audio_bytes = request.body
        if not audio_bytes:
            return Response(
                {"detail": "No audio received"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Save bytes to a temporary .wav file
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            tmp.write(audio_bytes)
            tmp_path = tmp.name

        try:
            # Use Whisper to transcribe
            result = _WHISPER_MODEL.transcribe(tmp_path, language="en")
            text = (result.get("text") or "").strip()
        finally:
            try:
                os.remove(tmp_path)
            except OSError:
                pass

        if not text:
            text = "(No words recognized)"

        return Response({"text": text}, status=status.HTTP_200_OK)
