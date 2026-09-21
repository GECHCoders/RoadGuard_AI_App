# RoadGuard AI 🚧

### AI-Powered Road Hazard Detection & Mapping

RoadGuard AI is a mobile application designed to detect road hazards such as potholes and road cracks using on-device computer vision. It combines AI-based image analysis, GPS location data, and OpenStreetMap to support road hazard identification and visualization.

## 🚀 Project Overview

Road damage can create safety risks for drivers, cyclists, and pedestrians. RoadGuard AI aims to make road hazard reporting more accessible by using a smartphone to identify potential road damage and associate it with geographic coordinates.

## ✨ Key Features

* **AI-Based Detection:** Uses a YOLO-based TensorFlow Lite model to identify potholes and road cracks.
* **On-Device Inference:** Runs the trained model locally in the mobile app.
* **GPS Location:** Retrieves device location for mapping detected hazards.
* **Interactive Map:** Uses OpenStreetMap to visualize geographic locations.
* **Camera Integration:** Supports road scanning through the smartphone camera.
* **Mobile Dashboard:** Displays road-safety information in a dedicated interface.

## 🛠️ Tech Stack

| Component            | Technology                 |
| -------------------- | -------------------------- |
| Mobile App           | Flutter, Dart              |
| AI / Computer Vision | YOLO, TensorFlow Lite      |
| Mapping              | OpenStreetMap, flutter_map |
| Location             | Geolocator                 |
| Model Format         | TensorFlow Lite            |

## 🧠 Detection Categories

The current model is trained to recognize:

* Pothole
* Longitudinal Crack
* Crocodile Crack

## 🔄 Application Workflow

1. Start a road scan.
2. Access the smartphone camera.
3. Analyze camera frames using the AI model.
4. Retrieve GPS coordinates.
5. Visualize road-safety information on the map.

## 📱 Current Prototype Status

The current prototype includes a Flutter dashboard, camera integration, GPS functionality, OpenStreetMap integration, and loading of the TensorFlow Lite model.

**Note:** Real-world detection accuracy, performance on physical devices, and end-to-end hazard reporting still require further testing and validation.

## 🔮 Future Scope

* Improve model accuracy with a larger and more diverse dataset.
* Add road hazard severity classification.
* Enable hazard reporting and backend storage.
* Reduce duplicate reports of the same road hazard.
* Develop risk analysis and road-safety insights.
* Validate performance under real-world driving conditions.

## 🎯 Project Goal

To explore how AI, mobile computing, and location-based technology can help identify road hazards and support safer roads.

## 👨‍💻 Developer

**Manoj**
GitHub: [@manoj720](https://github.com/manoj720)

---

*RoadGuard AI — Towards smarter and safer roads.*
