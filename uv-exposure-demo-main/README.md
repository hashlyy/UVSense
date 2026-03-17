# UV Sense — Adaptive UV Exposure Monitoring System

## Overview

**UV Sense** is a wearable-assisted mobile application that helps users monitor and manage their **personal UV exposure risk** in real time.

The system combines:

* **Real-time UV sensing**
* **Bluetooth Low Energy communication**
* **Adaptive machine learning**
* **Explainable AI feedback**
* **Safety alerts and notifications**

to create a **personalized sun exposure monitoring system**.

Unlike conventional UV index apps that rely only on regional weather data, UV Sense uses a **wearable UV sensor node** to measure actual environmental UV radiation and adapt to the **user’s individual sun tolerance over time**.

---

# System Architecture

```
GUVA-S12SD UV Sensor
        ↓
ESP32 Wearable Node
        ↓ BLE
Flutter Mobile App
        ↓
UV Exposure Tracking
        ↓
Adaptive Threshold Learning (ML)
        ↓
Explainable AI Feedback
        ↓
Alerts + Safety Notifications
```

The wearable device continuously measures UV intensity and sends readings to the mobile application every **5 seconds**.

---

# Hardware Components

### ESP32-WROOM-32

The ESP32 acts as the wearable microcontroller responsible for:

* reading UV sensor data
* computing UV index
* broadcasting readings via BLE

---

### GUVA-S12SD UV Sensor

The GUVA-S12SD sensor detects ultraviolet radiation in the **240–370 nm range** and outputs an analog voltage proportional to UV intensity.

---

### Power System

The wearable device is powered using:

* **3.7V LiPo battery**
* **CA-033M charging module**

This allows the ESP32 sensor node to operate as a **portable wearable device**.

---

# Mobile Application

The mobile application is developed using **Flutter**.

The app performs the following tasks:

* receives UV data via BLE
* tracks cumulative UV exposure
* calculates personalized exposure limits
* provides alerts when exposure becomes unsafe
* collects user feedback
* updates safe thresholds using adaptive learning

---

# Machine Learning Approach

The system uses a **lightweight online adaptive learning model** to personalize UV exposure limits.

Initial safe thresholds are estimated using the **Fitzpatrick skin type questionnaire**.

The threshold then evolves based on daily feedback from the user.

### Feedback categories

* None
* Mild
* Moderate
* Severe

### Adaptive update rule

```
If feedback = None
    threshold = threshold + 5

If feedback = Mild
    threshold = threshold - 5

If feedback = Moderate
    threshold = threshold - 10

If feedback = Severe
    threshold = threshold - 20
```

The threshold is constrained between safe limits to prevent unrealistic values.

The updated threshold is then sent back to the ESP32 via BLE.

---

# Explainable AI (XAI)

To ensure transparency, the system provides **human-readable explanations** for alerts and exposure decisions.

Example explanation:

> Your cumulative UV exposure today exceeded your personalized safe threshold.
> Current exposure: 120
> Safe threshold: 100
> High UV conditions detected during midday hours.

This improves user understanding and trust in the system.

---

# UV Safety Alerts

The app implements **WHO UV index safety guidelines**.

### UV risk levels

| UV Index | Risk Level |
| -------- | ---------- |
| 0 – 2    | Low        |
| 3 – 5    | Moderate   |
| 6 – 7    | High       |
| 8 – 10   | Very High  |
| 11+      | Extreme    |

When UV levels become dangerous the system triggers:

* visual warning banners
* push notifications
* vibration alerts

---

# BLE Communication

The wearable communicates with the app using **Bluetooth Low Energy (BLE)**.

### Device name

```
UV_Monitor
```

### BLE Service

```
12345678-1234-1234-1234-123456789abc
```

### Characteristics

| UUID | Purpose                   |
| ---- | ------------------------- |
| abcd | UV index transmission     |
| efgh | Adaptive threshold update |

---

# Key Features

* Real-time UV sensing
* Wearable hardware integration
* Personalized UV exposure limits
* Feedback-driven learning
* Explainable safety recommendations
* Push alerts and vibration warnings
* BLE communication with ESP32

---

# Technologies Used

### Hardware

* ESP32-WROOM-32
* GUVA-S12SD UV sensor
* LiPo battery
* CA-033M charging module

### Software

* Flutter
* Dart
* Arduino IDE
* BLE (Bluetooth Low Energy)

### Libraries

* flutter_blue_plus
* shared_preferences
* flutter_local_notifications
* vibration

---

# How the System Works

1. The UV sensor measures environmental UV radiation.
2. ESP32 reads the sensor value and computes the UV index.
3. The ESP32 sends UV readings to the mobile app every **5 seconds**.
4. The app accumulates daily UV exposure.
5. When exposure exceeds safe levels, alerts are triggered.
6. The user provides end-of-day feedback.
7. The machine learning model updates the personalized threshold.
8. The updated threshold is sent back to the wearable device.

This creates a **closed adaptive learning loop**.

---

# Future Improvements

* automatic BLE reconnection
* wearable vibration alerts
* UV exposure prediction models
* cloud-based exposure analytics
* dermatological risk prediction

---

# Authors

Developed as part of an academic project on **adaptive UV exposure monitoring using wearable sensing and explainable AI**.
