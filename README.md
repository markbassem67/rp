# 📱 Face Recognition-Based Attendance System (Graduation Project)

A hybrid mobile attendance tracking app built using Flutter and integrated with a backend face recognition system powered by Python and Dlib’s ResNet model. This project enables seamless, automated attendance recording with real-time logging and intuitive visualisation on mobile.

## 🚀 Features
🎥 Live Face Recognition

1- Uses the device camera for real-time face detection and recognition.

2- Frames are captured periodically and sent to the backend for processing.

3-Recognized faces are displayed on-screen in real time with an overlay box and the user's name.

4-Authentication sound is played for each new detected person.

🖼️ Image-Based Recognition

1-Allows users to capture a new image or choose one from the gallery.

2-Sends the image to the backend and displays recognition results in a dialog.


🕓 History and Session Tracking

1-All recognized individuals are recorded with a timestamp.

2-A dedicated History screen lists all previous recognitions.

3-Option to start a new session that clears the recorded data.

🔊 Feedback and Interaction

1-Authentication sound plays on successful recognition.

2-Overlay boxes around detected faces improve clarity

## 🛠️ Tech Stack

| Component  | Tech Used |
| ------------- | ------------- |
|Mobile UI	|Flutter, Dart|
|Camera Feed	|camera package|
|API Communication	|http package|
|Image Preprocessing	|image package|
|Audio Playback	|audioplayers package|
|Navigation	|bottom_nav_bar|
|Backend API	|Python Flask + face_recognition library|


## 📷 Screenshots
![Image](https://github.com/user-attachments/assets/5a97973e-1859-4f0f-b885-72e2e0e04ab3)


![Image](https://github.com/user-attachments/assets/8d2c87e7-7b30-480b-9b43-5f391ac6d6c2)


![Image](https://github.com/user-attachments/assets/20db122c-408f-48a5-8f0e-21f292df0ddd)


## 📌 Notes

The app assumes portrait mode operation for all recognition logic.

It is recommended to keep the Flutter app and server on the same local Wi-Fi during testing.

## 🤝 Contributions

Contributions are welcome — especially improvements in model performance and UI/UX enhancements, and addition of useful features.

