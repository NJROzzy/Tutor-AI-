from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
from django.db import models


class CustomUserManager(BaseUserManager):
    def create_user(self, username, email, first_name, last_name, password=None, phone_number=None, **extra_fields):
        if not username:
            raise ValueError("Username is required")
        if not email:
            raise ValueError("Email is required")
        email = self.normalize_email(email)
        user = self.model(
            username=username,
            email=email,
            first_name=first_name,
            last_name=last_name,
            phone_number=phone_number,
            **extra_fields
        )
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, username, email, first_name, last_name, password=None, **extra_fields):
        extra_fields.setdefault('parent', True)
        extra_fields.setdefault('kid', True)
        return self.create_user(username, email, first_name, last_name, password, **extra_fields)


class CustomUser(AbstractBaseUser, PermissionsMixin):
    username = models.CharField(max_length=150, unique=True, blank=True, null=True)
    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=30)
    last_name = models.CharField(max_length=30)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    country = models.CharField(max_length=50, blank=True, null=True)
    timezone = models.CharField(max_length=50, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    parent = models.BooleanField(default=False)
    kid = models.BooleanField(default=False)

    objects = CustomUserManager()

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email', 'first_name', 'last_name']

    def __str__(self):
        return self.username or self.email

    @property
    def is_staff(self):
        return bool(self.parent)

    @is_staff.setter
    def is_staff(self, value):
        self.parent = bool(value)

    @property
    def is_superuser(self):
        return bool(self.kid)

    @is_superuser.setter
    def is_superuser(self, value):
        self.kid = bool(value)


class ChildProfile(models.Model):
    parent = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='children')
    name = models.CharField(max_length=100)
    date_of_birth = models.DateField()
    grade_level = models.CharField(max_length=20)
    gender = models.CharField(max_length=10, blank=True, null=True)
    learning_focus = models.CharField(max_length=10, choices=[('Math', 'Math'), ('English', 'English'), ('Both', 'Both')])
    lesson_style = models.CharField(max_length=10, choices=[('Voice', 'Voice'), ('Mixed', 'Mixed')])
    session_duration = models.IntegerField(choices=[(10, '10'), (15, '15'), (20, '20')])
    learning_goal = models.TextField(blank=True, null=True)
    purpose = models.CharField(max_length=100, choices=[
        ('Match lessons to age and grade', 'Match lessons to age and grade'),
        ('Choose tone and vocabulary', 'Choose tone and vocabulary'),
        ('Create focused sessions', 'Create focused sessions'),
        ('Personalize time and style', 'Personalize time and style'),
    ])

    def __str__(self):
        return f"{self.name} ({self.grade_level})"