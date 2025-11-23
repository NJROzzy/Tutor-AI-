from django.db import models
from core.models import ChildProfile   # or wherever ChildProfile lives

class Subject(models.Model):
    key = models.CharField(max_length=100, unique=True)  # e.g. "math_addition"
    name = models.CharField(max_length=255)              # e.g. "Math - Addition"
    category = models.CharField(max_length=50)           # e.g. "math"

    def __str__(self):
        return self.name


class LearningProfile(models.Model):
    child = models.ForeignKey(
        ChildProfile,
        on_delete=models.CASCADE,
        related_name="learning_profiles",
    )
    subject = models.ForeignKey(
        Subject,
        on_delete=models.CASCADE,
        related_name="learning_profiles",
    )

    total_questions_answered = models.IntegerField(default=0)
    total_correct = models.IntegerField(default=0)
    last_activity_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ("child", "subject")

    @property
    def accuracy(self):
        if self.total_questions_answered == 0:
            return 0.0
        return self.total_correct / self.total_questions_answered

    def __str__(self):
        return f"{self.child.name} - {self.subject.name}"