from django.urls import path
from .views import (
    SignupView,
    LoginView,
    ChildProfileListCreateView,
    signup_page,
    login_page,
    TutorChatView,
    TutorTTSView, 
)

urlpatterns = [
    path('signup/', SignupView.as_view(), name='signup'),
    path('login/', LoginView.as_view(), name='login'),
    path('children/', ChildProfileListCreateView.as_view(), name='children'),
    path('signup-ui/', signup_page, name='signup_ui'),
    path('login-ui/', login_page, name='login_ui'),
    path('tutor/chat/', TutorChatView.as_view(), name='tutor_chat'),
    path('tutor/tts/', TutorTTSView.as_view(), name='tutor_tts'),
]