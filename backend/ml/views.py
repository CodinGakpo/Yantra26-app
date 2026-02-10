# backend/ml/views.py
# Django REST Framework view for ML model prediction

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.views.decorators.csrf import csrf_exempt
import tensorflow as tf
import numpy as np
from PIL import Image
import io
import base64
import json
import os
from pathlib import Path

# Get the base directory for the ML folder
BASE_DIR = Path(__file__).resolve().parent

# Paths to model files
MODEL_PATH = BASE_DIR / "model" / "civic_issue_imgmodel (1).keras"
CLASS_INDICES_PATH = BASE_DIR / "model" / "class_indices.json"
CONFIDENCE_THRESHOLD = 0.45

# Global variables to store the loaded model
_model = None
_index_to_department = {}

def load_model():
    """
    Load the ML model and class indices.
    This is called once when Django starts.
    """
    global _model, _index_to_department
    
    if _model is not None:
        return  # Already loaded
    
    try:
        # Load the Keras model
        _model = tf.keras.models.load_model(str(MODEL_PATH))
        print(f"✓ ML Model loaded successfully from {MODEL_PATH}")
        
        # Load class indices
        with open(CLASS_INDICES_PATH, 'r') as f:
            class_indices = json.load(f)
        
        # Reverse the mapping to get index -> department
        _index_to_department = {v: k for k, v in class_indices.items()}
        print(f"✓ Class indices loaded: {class_indices}")
        
    except Exception as e:
        print(f"✗ Error loading ML model: {e}")
        _model = None
        _index_to_department = {}

# Load model when module is imported
load_model()


def preprocess_image(image_base64):
    """
    Preprocess the base64 image for model prediction.
    
    Args:
        image_base64: Base64 encoded image string
        
    Returns:
        Preprocessed image array ready for model input
        
    Raises:
        ValueError: If image preprocessing fails
    """
    try:
        # Remove data URL prefix if present (e.g., "data:image/jpeg;base64,")
        if ',' in image_base64:
            image_base64 = image_base64.split(',')[1]
        
        # Decode base64 to bytes
        image_bytes = base64.b64decode(image_base64)
        
        # Open image using PIL
        image = Image.open(io.BytesIO(image_bytes))
        
        # Convert to RGB if necessary (handles RGBA, grayscale, etc.)
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Resize to model's expected input size (224x224 for most CNNs)
        image = image.resize((224, 224))
        
        # Convert to numpy array
        image_array = np.array(image)
        
        # Normalize pixel values to [0, 1]
        image_array = image_array.astype('float32') / 255.0
        
        # Add batch dimension
        image_array = np.expand_dims(image_array, axis=0)
        
        return image_array
        
    except Exception as e:
        raise ValueError(f"Error preprocessing image: {str(e)}")


@api_view(['POST'])
@permission_classes([IsAuthenticated])  # Remove this if you don't need authentication
def predict_department(request):
    """
    API endpoint to predict the department responsible for a civic issue.
    
    Request body:
        {
            "image_base64": "base64_encoded_image_string"
        }
    
    Response:
        {
            "department": "Public Works Department",
            "confidence": 0.95,
            "is_valid": true,
            "reason": null,
            "all_probabilities": {
                "Public Works Department": 0.95,
                "Water Board Department": 0.03,
                ...
            }
        }
    """
    # Check if model is loaded
    if _model is None:
        return Response(
            {
                "error": "ML model not loaded",
                "detail": "The ML model failed to load. Please contact the administrator."
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
    # Get image_base64 from request
    image_base64 = request.data.get('image_base64')
    
    if not image_base64:
        return Response(
            {
                "error": "Missing image_base64",
                "detail": "Please provide 'image_base64' in the request body."
            },
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        print("🟢 Starting image classification...")
        
        # Preprocess the image
        processed_image = preprocess_image(image_base64)
        print("🟢 Image preprocessed successfully")
        
        # Make prediction
        predictions = _model.predict(processed_image, verbose=0)
        print("🟢 Prediction completed")
        
        # Get the predicted class index
        predicted_index = np.argmax(predictions[0])
        confidence = float(predictions[0][predicted_index])
        
        # Print confidence score to terminal
        print(f"🟢 Confidence Score: {confidence:.4f} ({confidence*100:.2f}%)")
        print(f"🟢 Predicted Index: {predicted_index}")
        
        # Get the department name
        predicted_department = _index_to_department.get(
            predicted_index,
            "Manual"
        )
        
        # Check if prediction is valid based on confidence threshold
        is_valid = confidence >= CONFIDENCE_THRESHOLD
        
        if not is_valid:
            print(f"⚠️  Low confidence ({confidence:.4f}) - below threshold ({CONFIDENCE_THRESHOLD})")
            predicted_department = "Manual"
        else:
            print(f"✓ Valid prediction: {predicted_department}")
        
        # Create probability dictionary for all departments
        all_probabilities = {
            _index_to_department.get(i, f"Unknown_{i}"): float(predictions[0][i])
            for i in range(len(predictions[0]))
        }
        
        # Print top 3 predictions
        sorted_probs = sorted(all_probabilities.items(), key=lambda x: x[1], reverse=True)[:3]
        print("🟢 Top 3 Predictions:")
        for dept, prob in sorted_probs:
            print(f"   - {dept}: {prob:.4f} ({prob*100:.2f}%)")

        response_data = {
            "department": predicted_department,
            "confidence": confidence,
            "all_probabilities": all_probabilities,
            "is_valid": is_valid,
            "reason": None if is_valid else "LOW_CONFIDENCE"
        }
        
        print(f"🟢 Response: department={predicted_department}, is_valid={is_valid}")
        print("-" * 60)
        
        return Response(
            response_data,
            status=status.HTTP_200_OK
        )
    
    except ValueError as ve:
        print(f"❌ ValueError: {ve}")
        return Response(
            {
                "error": "Invalid image",
                "detail": str(ve)
            },
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        print(f"❌ Prediction error: {e}")
        import traceback
        traceback.print_exc()
        return Response(
            {
                "error": "Prediction failed",
                "detail": str(e)
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# Optional: Health check endpoint for the ML service
@api_view(['GET'])
def ml_health_check(request):
    """
    Check if the ML model is loaded and ready.
    """
    return Response(
        {
            "status": "healthy" if _model is not None else "unhealthy",
            "model_loaded": _model is not None,
            "departments_count": len(_index_to_department)
        },
        status=status.HTTP_200_OK
    )