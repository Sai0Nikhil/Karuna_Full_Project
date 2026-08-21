import os
import shutil
from ultralytics import YOLO

def train_skin_classifier():
    dataset_path = 'datasets/archive (4)'
    
    if not os.path.exists(dataset_path):
        print(f"Error: Dataset directory not found at {dataset_path}")
        return
        
    print("Loading pre-trained YOLOv8-Classification model...")
    # Load YOLOv8 Nano classification model
    model = YOLO('yolov8n-cls.pt')
    
    print("Starting training on pet skin disease images (3 epochs, size 128 for speed)...")
    # Train the model
    # We use a smaller image size (128) and fewer epochs (3) to complete training quickly for the hackathon demo
    results = model.train(
        data=dataset_path,
        epochs=3,
        imgsz=128,
        batch=16,
        workers=2,
        project='runs/classify',
        name='skin_disease'
    )
    
    # Locate the best weights
    best_weights_path = 'runs/classify/skin_disease/weights/best.pt'
    target_weights_path = 'backend/ai-service/skin_classifier.pt'
    
    if os.path.exists(best_weights_path):
        print(f"Training completed successfully! Copying {best_weights_path} to {target_weights_path}...")
        # Copy file to ai-service folder
        shutil.copy(best_weights_path, target_weights_path)
        print("Model weights successfully integrated!")
    else:
        print("Error: Could not locate trained weights file.")

if __name__ == '__main__':
    train_skin_classifier()
