# System Architecture

This document provides a comprehensive technical breakdown of each functional block, MATLAB function, and System object within the **Diabetic Retinopathy Telemedicine Simulation**.

---

## 1. High-Level Architecture Overview

The simulation integrates continuous and discrete-event modeling in **Simulink** with deep learning inference, image processing routines, and explainability algorithms in **MATLAB System blocks**.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               SIMULINK MAIN MODEL GRAPH                                │
│                         (DR_Telemedicine_Simulation_Clean.slx)                         │
│                                                                                        │
│  ┌───────────────────────┐       ┌────────────────────────┐       ┌─────────────────┐  │
│  │   Patient Arrival     │ ───>  │  Registration & Queue  │ ───>  │  Fundus Camera  │  │
│  │   (Poisson/Exp Gen)   │       │      (Server S-1)      │       │   Acquisition   │  │
│  └───────────────────────┘       └────────────────────────┘       └────────┬────────┘  │
│                                                                            │           │
│                                                                            ▼           │
│  ┌───────────────────────┐       ┌────────────────────────┐       ┌─────────────────┐  │
│  │   Image QA Check      │ <──── │      Preprocessing     │ <──── │  Raw Image Feed │  │
│  │  (Recapture Trigger)  │       │ (preprocessFundusImage)│       │(FundusImageSrc) │  │
│  └───────────┬───────────┘       └───────────┬────────────┘       └─────────────────┘  │
│              │                               │                                         │
│              ▼                               ├─────────────────────────────┐           │
│  ┌───────────────────────┐                   ▼                             ▼           │
│  │  Binary Classifier    │       ┌────────────────────────┐   ┌─────────────────────┐  │
│  │ (Referable / Non-Ref) │       │ Multiclass Classifier  │   │ Vessel Segmentation │  │
│  └───────────┬───────────┘       │    (Grades 0 to 4)     │   │ (Frangi + Deep CNN) │  │
│              │                   └───────────┬────────────┘   └──────────┬──────────┘  │
│              │                               │                           │             │
│              │                               ▼                           │             │
│              │                   ┌────────────────────────┐              │             │
│              │                   │    Grad-CAM System     │              │             │
│              │                   │ (Feature Saliency Map) │              │             │
│              │                   └───────────┬────────────┘              │             │
│              │                               │                           │             │
│              ▼                               ▼                           ▼             │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐  │
│  │                          Patient Result Logger                                   │  │
│  │             (Consolidates signals, writes patient files & report.txt)            │  │
│  └───────────────────────────────────────────┬──────────────────────────────────────┘  │
│                                              │                                         │
│                                              ▼                                         │
│                                  ┌────────────────────────┐                            │
│                                  │   Referral Decision    │                            │
│                                  │ (Grade >= 2 / Refer.)  │                            │
│                                  └───────────┬────────────┘                            │
│                                              │                                         │
│                                              ▼                                         │
│                                  ┌────────────────────────┐                            │
│                                  │  Remote Doctor Review  │                            │
│                                  │  & Tele-Prescription   │                            │
│                                  │  (PrescriptionLogger)  │                            │
│                                  └────────────────────────┘                            │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Component Specifications

### 2.1. Global Parameters (`DR_parameters.m`)
Defines simulation constants, queueing distributions, hardware latency approximations, and clinical thresholds:
- **Simulation Time:** `SIMULATION_TIME = 480` minutes (8-hour clinical shift).
- **Patient Intake:** `PATIENTS_PER_HOUR = 15` (mean inter-arrival time `4.0` minutes).
- **Registration Service:** `REGISTRATION_TIME = 1.5` minutes per patient.
- **Fundus Acquisition:** `CAPTURE_TIME = 3.0` minutes per examination.
- **QA Rejection Rate:** `POOR_IMAGE_RATE = 0.15` (15% rate requiring re-take, max 2 attempts).
- **Network Transmission:** `IMAGE_SIZE_MB = 6`, `UPLOAD_BANDWIDTH_MBPS = 2`.
- **Specialist Consultation:** `DOCTOR_REVIEW_TIME = 2.0` minutes for referable patients.
- **Referral Criteria:** `REFERABLE_THRESHOLD = 2` (Grade $\ge 2$ triggers referral).

---

### 2.2. Fundus Image Source (`ActualFundusImageSource.m`)
A `matlab.System` block responsible for streaming actual retinal fundus photographs from disk into the Simulink execution graph.

- **Class:** `ActualFundusImageSource < matlab.System`
- **Configurable Property:** `DatasetRoot` (default: `"SIH_TEST"`, alternative: `"SIH_data"`).
- **Input:**
  - `captureRequest` (Boolean): Rising edge trigger from the camera queue indicating a new patient capture.
- **Outputs:**
  - `rawImage` (`uint8`, `[1050, 1050, 3]`): Fixed-dimension RGB fundus image.
  - `imageNumber` (`double`, scalar): Sequential patient/image index.
- **Internal Logic:**
  - Recursively scans `DatasetRoot/0` through `DatasetRoot/4` for `.png` files during `setupImpl`.
  - Converts grayscale images to 3-channel RGB (`cat(3, I, I, I)`).
  - Strips alpha channels if present (`img(:,:,1:3)`).
  - Standardizes spatial resolution to $1050 \times 1050 \times 3$ uint8.
  - Loops back to index 1 if dataset exhaustion occurs.

---

### 2.3. Preprocessing (`preprocessFundusImageSim.m`)
A high-performance MATLAB function block applying standardized ophthalmological image enhancement.

- **Signature:** `Y = preprocessFundusImageSim(u)`
- **Codegen Compatibility:** Decorated with `%#codegen`.
- **Input:**
  - `u` (`uint8` or `single/double`, `[1050, 1050, 3]`): Raw fundus image.
- **Output:**
  - `Y` (`single/double`, `[224, 224, 3]`): Standardized network-ready tensor.
- **Processing Steps:**
  1. **FOV Auto-Cropping:** Converts to grayscale, identifies circular aperture mask (`find(gray > 15)`), and crops bounding box to eliminate redundant black background margins.
  2. **CIE-LAB Color Space Transformation:** Converts RGB to CIE-LAB via `rgb2lab`.
  3. **Contrast-Limited Adaptive Histogram Equalization (CLAHE):** Applied strictly to the Luminance ($L$) channel (`adapthisteq(L, 'ClipLimit', 0.02, 'NumTiles', [8 8])`) to enhance microvascular contrast without distorting color balance.
  4. **Reconversion & Clamping:** Converts back to RGB via `lab2rgb`, clamps intensities to $[0, 1]$.
  5. **Spatial Resizing:** Interpolates enhanced image to $224 \times 224 \times 3$.

---

### 2.4. Binary & Multiclass Classification Networks
- **Binary Classifier (`models/model_binary.onnx`):**
  - Evaluates preprocessed image tensor ($224 \times 224 \times 3$).
  - Produces a 2-element softmax vector: `[P(Non-Referable), P(Referable)]`.
- **Multiclass Classifier (`models/model_multiclass.onnx`):**
  - Evaluates preprocessed image tensor ($224 \times 224 \times 3$).
  - Produces a 5-element softmax probability distribution corresponding to ICDR Grades 0 through 4:
    - Index 1 $\rightarrow$ Grade 0 (No DR)
    - Index 2 $\rightarrow$ Grade 1 (Mild DR)
    - Index 3 $\rightarrow$ Grade 2 (Moderate DR)
    - Index 4 $\rightarrow$ Grade 3 (Severe DR)
    - Index 5 $\rightarrow$ Grade 4 (Proliferative DR)

---

### 2.5. Grad-CAM Explainable AI (`GradCAMSystem.m`)
A `matlab.System` block generating Class Activation Maps to visually highlight retinal lesions contributing to the classification.

- **Class:** `GradCAMSystem < matlab.System`
- **Inputs:**
  - `X` (`single`, `[224, 224, 3]`): Preprocessed fundus image tensor.
  - `runFlag` (Boolean): Execution trigger pulse when classification output is valid.
- **Output:**
  - `gradcamImage` (`single`, `[224, 224, 3]`): RGB image with overlaid Jet heatmap.
- **Internal Mathematical Pipeline:**
  1. **Forward Pass:** Extracts activations $A^k$ from target convolutional layer `x_conv5_Conv` and class score logits $S_c$ via `forward`.
  2. **Gradient Computation:** Evaluates automatic gradients $\frac{\partial S_c}{\partial A^k}$ using `dlfeval` and `dlgradient`.
  3. **Global Average Pooling:** Computes importance weights:
     $$\alpha_k^c = \frac{1}{Z} \sum_i \sum_j \frac{\partial S_c}{\partial A_{i,j}^k}$$
  4. **Linear Combination & ReLU:**
     $$L_{\text{Grad-CAM}}^c = \text{ReLU}\left(\sum_k \alpha_k^c A^k\right)$$
  5. **Normalization & Colormap:** Normalizes activation to $[0, 1]$, applies Jet colormap, and blends with de-normalized fundus image with opacity factor $\alpha = 0.45$.

---

### 2.6. Retinal Vessel Segmentation (`VesselSegmentationSystem.m`)
A hybrid morphological and deep learning `matlab.System` block for vascular tree extraction.

- **Class:** `VesselSegmentationSystem < matlab.System`
- **Input:**
  - `rawImage` (`uint8`, `[1050, 1050, 3]`): Raw fundus input.
- **Output:**
  - `vesselMask` (`uint8`, `[512, 512, 3]`): Binary vessel segmentation mask formatted as RGB uint8 (0 or 255).
- **Pipeline:**
  1. **Preprocessing:** Resizes raw image to $512 \times 512$, isolates green channel $G$ (highest contrast for blood vessels).
  2. **CLAHE & Black Top-Hat:** Enhances narrow dark linear structures via `imbothat(Gc, strel('disk', 7))`.
  3. **Multi-Scale Frangi Vesselness Filter:** Evaluates Hessian matrix eigenvalues $(\lambda_1, \lambda_2)$ across scales $\sigma \in \{1, 2, 3, 4, 5\}$:
     $$V(\sigma) = \exp\left(-\frac{R_b^2}{2\beta^2}\right) \left(1 - \exp\left(-\frac{S^2}{2\gamma^2}\right)\right)$$
  4. **Multi-Channel CNN Input:** Constructs a 3-channel composite tensor:
     - Channel 1: Normalized green channel $G_n$
     - Channel 2: Frangi vesselness map $F$
     - Channel 3: Top-Hat morphological response $T$
  5. **Network Inference & Post-Processing:** Predicts logits via `vesselNet`, applies sigmoid activation, thresholds at $P \ge 0.7$, and removes isolated artifacts via `bwareaopen(mask, 50)`.

---

### 2.7. Patient Result Logger (`PatientResultLogger.m`)
A centralized recording system object that consolidates multi-modal data streams for each patient.

- **Inputs (9 total):**
  1. `imageReady` (Boolean): Trigger indicating classification completion.
  2. `captureRequest` (Boolean): Trigger on initial image capture.
  3. `imageNumber` (`double`): Patient index.
  4. `processedImage`: Enhanced $224 \times 224$ image.
  5. `gradcamImage`: Saliency overlay $224 \times 224$.
  6. `rawImage`: Original $1050 \times 1050$ image.
  7. `vesselMask`: Segmented vessel mask $512 \times 512$.
  8. `binaryProbabilities`: Vector of binary class probabilities.
  9. `gradeProbabilities`: Vector of 5-class severity probabilities.
- **File Outputs:**
  - Creates folder `SimulationResults/Patient_<ID>/`.
  - Writes `raw.png`, `processed.png`, `gradcam.png`, `vessel.png`.
  - Writes formatted `report.txt` with patient status, grade, and full probability distribution.

---

### 2.8. Telemedicine Prescription Logger (`PrescriptionLogger.m`)
Manages automated prescription generation following remote ophthalmologist review.

- **Inputs:**
  1. `patientID`: Patient identifier.
  2. `referable` (Boolean): Flag indicating Grade $\ge 2$ or positive binary triage.
  3. `doctorDone` (Boolean): Pulse indicating completion of specialist tele-review.
  4. `prescription` (String): Standardized therapeutic or follow-up recommendation text.
- **File Output:**
  - Writes `SimulationResults/Patient_<ID>/prescription.txt`.
