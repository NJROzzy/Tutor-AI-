from rest_framework.decorators import (
    api_view, permission_classes, authentication_classes
)
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication
from rest_framework.response import Response

from core.models import ChildProfile
from learning.models import LearningProfile, Subject

@api_view(["GET"])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def parent_dashboard_view(request):
    """
    Returns all children for this parent + per-subject progress.
    {
      "children": [
        {
          "id": 1,
          "name": "Mira",
          "age": 6,
          "grade_level": "K",
          "subjects": [
            {
              "subject": {"name": "Math - Addition"},
              "total_questions_answered": 10,
              "total_correct": 8,
              "accuracy": 0.8
            }
          ]
        },
        ...
      ]
    }
    """
    children = ChildProfile.objects.filter(parent=request.user)

    out = []

    for child in children:
      profiles = child.learning_profiles.select_related("subject")

      subjects_out = []
      for p in profiles:
          subjects_out.append({
              "subject": {
                  "name": p.subject.name,
              },
              "total_questions_answered": p.total_questions_answered,
              "total_correct": p.total_correct,
              "accuracy": p.accuracy,
          })

      out.append({
          "id": child.id,
          "name": child.name,
          "age": child.age,
          "grade_level": child.grade_level,
          "subjects": subjects_out,
      })

    return Response({"children": out})

# -------------------------------------------------------------------------
# Record answer endpoint
# -------------------------------------------------------------------------
@api_view(["POST"])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def record_answer_view(request):
    """
    Body:
    {
        "child_id": 3,
        "subject_key": "math_addition",
        "is_correct": true
    }
    """

    child_id = request.data.get("child_id")
    subject_key = request.data.get("subject_key")
    is_correct = request.data.get("is_correct")

    # Validate inputs
    if child_id is None or subject_key is None or is_correct is None:
        return Response(
            {"detail": "child_id, subject_key, is_correct are required"},
            status=400,
        )

    # Ensure this child belongs to the authenticated parent
    try:
        child = ChildProfile.objects.get(id=child_id, parent=request.user)
    except ChildProfile.DoesNotExist:
        return Response({"detail": "Child does not exist"}, status=404)

    # Get subject
    try:
        subject = Subject.objects.get(key=subject_key)
    except Subject.DoesNotExist:
        return Response({"detail": "Subject not found"}, status=404)

    # Get or create learning profile
    lp, _ = LearningProfile.objects.get_or_create(
        child=child,
        subject=subject,
    )

    # Update stats
    lp.total_questions_answered += 1
    if is_correct:
        lp.total_correct += 1

    lp.save()

    return Response(
        {
            "message": "Recorded",
            "total_questions": lp.total_questions_answered,
            "total_correct": lp.total_correct,
            "accuracy": lp.accuracy,
        },
        status=200,
    )