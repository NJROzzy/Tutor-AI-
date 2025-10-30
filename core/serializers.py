from rest_framework import serializers
from .models import CustomUser, ChildProfile


class ChildProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChildProfile
        fields = [
            'name', 'date_of_birth', 'grade_level', 'gender',
            'learning_focus', 'lesson_style', 'session_duration',
            'learning_goal', 'purpose'
        ]


class SignupSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    children = ChildProfileSerializer(many=True)
    country = serializers.CharField(required=False, allow_blank=True)
    timezone = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = CustomUser
        fields = [
            'first_name', 'last_name', 'email', 'phone_number',
            'username', 'password', 'country', 'timezone', 'children'
        ]

    def create(self, validated_data):
        children_data = validated_data.pop('children')
        password = validated_data.pop('password')
        user = CustomUser.objects.create_user(password=password, **validated_data)
        for child in children_data:
            ChildProfile.objects.create(parent=user, **child)
        return user
    
class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)