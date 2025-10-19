from django.urls import path
from .views import SignupView, LoginView, signup_page, login_page

urlpatterns = [
    path('signup/', SignupView.as_view(), name='signup'),
    path('login/', LoginView.as_view(), name='login'),
    path('signup-ui/', signup_page, name='signup_ui'),
    path('login-ui/', login_page, name='login_ui'),
]