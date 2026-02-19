#!/usr/bin/env python3
"""
Download a pre-trained traffic sign detection model for SteerMate.

This script downloads a YOLOv8n model (from Ultralytics assets)
that you can fine-tune on traffic sign datasets (e.g., GTSRB/GTSDB),
and stores it under backend/ml/models.

Usage:
    cd backend
    python -m ml.scripts.download_sign_model
"""

import sys
import urllib.request
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent
# backend/ml/scripts -> backend
BACKEND_DIR = SCRIPT_DIR.parent.parent
ML_MODELS_DIR = BACKEND_DIR / "ml" / "models"

# Pre-trained model URLs (publicly available)
PRETRAINED_MODELS = {
    # YOLOv8n base model from Ultralytics (can be fine-tuned on traffic signs)
    "yolov8n": "https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8n.pt",
    # Placeholder for a GTSRB classifier TFLite (MobileNet-based)
    # You can swap this URL for your own trained classifier if desired.
    "gtsrb_classifier": "https://storage.googleapis.com/download.tensorflow.org/models/tflite/traffic_sign_classifier/traffic_sign_classifier.tflite",
}


def download_file(url: str, dest_path: Path) -> bool:
    """Download a file from URL to destination path."""
    try:
        print(f"Downloading {url}...")
        print(f"  -> {dest_path}")

        # Create parent directories
        dest_path.parent.mkdir(parents=True, exist_ok=True)

        # Download with progress
        def reporthook(count, block_size, total_size):
            if total_size > 0:
                percent = int(count * block_size * 100 / total_size)
            else:
                percent = 0
            sys.stdout.write(f"\r  Progress: {percent}%")
            sys.stdout.flush()

        urllib.request.urlretrieve(url, dest_path, reporthook)
        print("\n  Done!")
        return True

    except Exception as e:
        print(f"\n  Error downloading {url}: {e}")
        return False


def main() -> int:
    """Download pre-trained models for traffic sign detection."""
    print("=" * 60)
    print("SteerMate - Traffic Sign Model Downloader")
    print("=" * 60)
    print()

    # Ensure ML models directory exists
    ML_MODELS_DIR.mkdir(parents=True, exist_ok=True)

    # Download YOLOv8n base model
    yolo_path = ML_MODELS_DIR / "yolov8n.pt"
    if not yolo_path.exists():
        print("Downloading YOLOv8n base model...")
        if not download_file(PRETRAINED_MODELS["yolov8n"], yolo_path):
            print("Failed to download YOLOv8n. Please check your network and try again.")
            return 1
    else:
        print(f"YOLOv8n already exists: {yolo_path}")

    print()
    print("=" * 60)
    print("NEXT STEPS:")
    print("=" * 60)
    print()
    print("1. For a quick demo, you can use the base YOLOv8n model for general object detection.")
    print("2. For proper traffic sign detection, fine-tune YOLOv8n on traffic sign datasets (GTSRB/GTSDB).")
    print("3. After training, export to TFLite (e.g., using Ultralytics export tools) and")
    print("   place the resulting .tflite file into:")
    print("      mobile/assets/models/traffic_sign_model.tflite")
    print()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

