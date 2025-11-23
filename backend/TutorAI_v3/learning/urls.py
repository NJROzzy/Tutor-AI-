from django.urls import path
from .views import parent_dashboard_view, record_answer_view

urlpatterns = [
    path("parents/me/dashboard/", parent_dashboard_view),
    path("record-answer/", record_answer_view),
]