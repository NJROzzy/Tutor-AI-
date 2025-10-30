from django.urls import path
from . import views  # import the module, not the names

urlpatterns = [
    path('signup/', views.SignupView.as_view(), name='signup'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('signup-ui/', views.signup_page, name='signup_ui'),
    path('login-ui/', views.login_page, name='login_ui'),
]