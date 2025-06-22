import face_recognition as fr
import cv2
import os
import numpy as np
import time
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
from flask import Flask, request, jsonify

# Initialize Flask app
app = Flask(__name__)

# Paths for dataset
#lfw_path = r"C:\Users\PC1\Desktop\lfw - Copy\lfw-deepfunneled\lfw-deepfunneled"
lfw_path = r"C:\Users\PC1\Desktop\train sample"
output_path = r"C:\Users\PC1\Desktop\output_imagesduplicated"
excel_path = r"C:\Users\PC1\Desktop\recognition_reportduplicated.xlsx"

# Global variables for face encodings
known_encodings = []
known_names = []
train_labels = []  # Added to store training labels globally

def load_and_train_model():
    """Load dataset and train the face recognition model"""
    global known_encodings, known_names, train_labels
    
    # Ensure output directory exists
    if not os.path.exists(output_path):
        os.makedirs(output_path)

    start_time = time.time()

    # Load dataset
    all_images = []
    all_labels = []

    for person_name in os.listdir(lfw_path):
        person_folder = os.path.join(lfw_path, person_name)
        if os.path.isdir(person_folder):
            images = [os.path.join(person_folder, img) for img in os.listdir(person_folder)]
            if len(images) >= 2:  # Only include people with at least 2 images
                all_images.extend(images)
                all_labels.extend([person_name] * len(images))

    # Calculate appropriate test size
    n_classes = len(set(all_labels))
    n_samples = len(all_images)
    min_test_size = n_classes  # Need at least one sample per class in test set

    if n_samples < 2 * n_classes:
        raise ValueError(f"Not enough samples ({n_samples}) for {n_classes} classes. Need at least 2 samples per class.")

    # Use 20% test size but ensure it's at least equal to number of classes
    test_size = max(0.2, n_classes / n_samples)

    # Split dataset with adjusted test size
    train_images, test_images, train_labels, test_labels = train_test_split(
        all_images, all_labels, 
        test_size=test_size, 
        stratify=all_labels, 
        random_state=42
    )

    print(f"Dataset statistics:")
    print(f"Total images: {n_samples}")
    print(f"Unique people: {n_classes}")
    print(f"Training set size: {len(train_images)}")
    print(f"Test set size: {len(test_images)}")
    print(f"Test size percentage: {len(test_images)/n_samples:.2%}")

    # Encode known faces
    known_encodings = []
    known_names = []

    for img_path, label in zip(train_images, train_labels):
        image = fr.load_image_file(img_path)
        encoding = fr.face_encodings(image)
        if encoding:
            known_encodings.append(encoding[0])
            known_names.append(label)

    print(f"Training complete. {len(known_encodings)} encodings stored.")
    return test_images, test_labels, train_labels  # Now returning train_labels too

def evaluate_model(test_images, test_labels, train_labels):  # Added train_labels parameter
    """Evaluate model performance on test set"""
    report_data = []
    correct_predictions = 0
    predictions = []
    true_labels = []

    for img_path, true_label in zip(test_images, test_labels):
        image = cv2.imread(img_path)
        rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        face_locations = fr.face_locations(rgb_image)
        face_encodings = fr.face_encodings(rgb_image, face_locations)

        if not face_encodings:  # Skip images with no faces detected
            continue

        for (top, right, bottom, left), face_encoding in zip(face_locations, face_encodings):
            predicted_name = classify_face(face_encoding)
            predictions.append(predicted_name)
            true_labels.append(true_label)

            if predicted_name == true_label:
                correct_predictions += 1

            report_data.append({
                "Test Image": os.path.basename(img_path),
                "True Name": true_label,
                "Predicted Name": predicted_name,
                "Match Found": "Yes" if predicted_name == true_label else "No"
            })

            color = (0, 255, 0) if predicted_name == true_label else (0, 0, 255)
            cv2.rectangle(image, (left, top), (right, bottom), color, 2)
            cv2.putText(image, predicted_name, (left, top - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)

        output_img_path = os.path.join(output_path, f"output_{os.path.basename(img_path)}")
        cv2.imwrite(output_img_path, image)

    # Generate evaluation report
    accuracy = accuracy_score(true_labels, predictions)
    missing_labels = set(test_labels) - set(predictions)
    
    report_data.append({
        "Test Image": "Summary",
        "True Name": "Overall Accuracy",
        "Predicted Name": f"{accuracy * 100:.2f}%",
        "Match Found": f"Train Dataset: {len(set(train_labels))} identities, Test Dataset: {len(set(test_labels))} identities"
    })

    df = pd.DataFrame(report_data)
    df.to_excel(excel_path, index=False)

    print(f"Excel report saved to: {excel_path}")
    print(f"Accuracy: {accuracy * 100:.2f}%")
    print(classification_report(true_labels, predictions, zero_division=0))

def classify_face(encoding):
    """Returns the best-matching name for a given face encoding."""
    matches = fr.compare_faces(known_encodings, encoding, tolerance=0.6)
    distances = fr.face_distance(known_encodings, encoding)
    
    if matches and len(distances) > 0:
        best_match = np.argmin(distances)
        return known_names[best_match] if matches[best_match] else "Unknown"
    
    return "Unknown"

@app.route('/recognise', methods=['POST'])
def recognise():
    """Flask endpoint for face recognition"""
    try:
        file = request.files.get('image')
        if not file:
            return jsonify({"error": "No image file received"}), 400

        # Save temporary image
        temp_path = "temp_recognition_image.jpg"
        file.save(temp_path)

        # Process image
        image = cv2.imread(temp_path)
        original_height, original_width = image.shape[:2]

        # Resize if needed
        resized = False
        if original_width > 500 or original_height > 500:
            image_small = cv2.resize(image, (500, 500))
            resized = True
        else:
            image_small = image.copy()

        rgb_image = cv2.cvtColor(image_small, cv2.COLOR_BGR2RGB)
        face_locations = fr.face_locations(rgb_image)
        face_encodings = fr.face_encodings(rgb_image, face_locations)

        if not face_encodings:
            return jsonify({"faces": []})

        # Calculate scaling factors
        scale_x = original_width / 500 if resized else 1
        scale_y = original_height / 500 if resized else 1

        faces = []
        for (top, right, bottom, left), face_encoding in zip(face_locations, face_encodings):
            name = classify_face(face_encoding)
            
            faces.append({
                "name": name,
                "coordinates": {
                    "top": int(top * scale_y),
                    "right": int(right * scale_x),
                    "bottom": int(bottom * scale_y),
                    "left": int(left * scale_x)
                }
            })

        # Clean up
        os.remove(temp_path)
        
        return jsonify({"faces": faces})

    except Exception as e:
        print(f"Error during recognition: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # First train and evaluate the model
    test_images, test_labels, train_labels = load_and_train_model()  # Now getting train_labels
    evaluate_model(test_images, test_labels, train_labels)  # Passing train_labels
    
    # Then start the Flask server
    print("Starting Flask server...")
    app.run(host='0.0.0.0', port=5000, debug=True)
