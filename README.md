# Diabetic Retinopathy Telemedicine Simulation

An end-to-end discrete-event and deep-learning simulation framework for automated Diabetic Retinopathy (DR) screening, multi-tier classification, explainable AI (Grad-CAM), retinal blood vessel segmentation, and tele-ophthalmology consultation workflows in MATLAB & Simulink.

---

## 1. Project Overview

Diabetic Retinopathy (DR) is one of the leading causes of preventable blindness in the working-age population worldwide. Early detection and timely intervention can prevent up to 98% of severe vision loss. However, widespread screening is constrained by a severe global shortage of trained ophthalmologists, particularly in rural and underserved communities.

This project implements a complete **Diabetic Retinopathy Telemedicine Simulation** using **MATLAB & Simulink**. It models both the **computational AI pipeline** (deep learning classifiers, explainable saliency maps, morphological vessel segmentation) and the **operational clinical queueing dynamics** (patient registration, camera throughput, image quality filtering, bandwidth-constrained network transmission, and specialist tele-consultation).

---

## 2. Problem Statement & Purpose

### Problem Statement
Rural healthcare centers often lack on-site eye specialists. Deploying automated AI screening tools requires balancing algorithmic performance with clinical operations:
- How do patient arrival rates and camera capture times impact clinic wait times?
- What happens when poor-quality images require recapture?
- How are referable vs. non-referable cases triaged to remote specialists without overwhelming the network or ophthalmologist queue?

### Purpose of the Simulation
- **Operational Feasibility:** Model patient flow and resource bottlenecks across registration desks, fundus cameras, and tele-consultation queues.
- **Diagnostic Screening:** Evaluate automated binary triage (Referable vs. Non-Referable) and 5-stage International Clinical Diabetic Retinopathy (ICDR) grading.
- **Clinical Explainability:** Provide interpretable visual heatmaps (Grad-CAM) and vascular structure maps (Frangi + Deep Vessel Segmentation) alongside numerical reports to support remote clinician verification.
- **Prescription & Tele-Triage Workflow:** Generate structured patient records and tele-prescriptions for high-risk patients.

---

## 3. Complete End-to-End Workflow

```
[ Patient Arrival ]
       │
       ▼
[ Patient Queue & Resource Management ]
       │
       ▼
[ Fundus Image Acquisition ] ── (Loads raw PNG from SIH_TEST / SIH_data)
       │
       ▼
[ Image Quality Assessment ] ── (Recapture trigger if image fails QA)
       │
       ▼
[ Preprocessing (FOV Crop, LAB CLAHE, Normalization, 224x224 Resize) ]
       │
       ├────────────────────────────────────────┬────────────────────────────────────────┐
       ▼                                        ▼                                        ▼
[ Binary Classifier ]                   [ Multiclass Classifier ]               [ Vessel Segmentation ]
(Referable vs Non-Referable)             (Grades 0, 1, 2, 3, 4)                  (Frangi + CNN Mask)
       │                                        │                                        │
       └───────────────────┬────────────────────┘                                        │
                           ▼                                                             │
                  [ Grad-CAM Generator ]                                                 │
                  (Class Activation Map)                                                 │
                           │                                                             │
                           └────────────────────┬────────────────────────────────────────┘
                                                ▼
                                    [ Patient Result Logger ]
                                    (Writes raw, processed, gradcam,
                                     vessel PNGs & report.txt)
                                                │
                                                ▼
                                    [ Referable Decision ]
                               (Grade >= 2 OR Binary Referable)
                                                │
                                 ┌──────────────┴──────────────┐
                                 ▼                             ▼
                            [ Referable ]              [ Non-Referable ]
                                 │                             │
                                 ▼                             ▼
                     [ Remote Doctor Review ]           [ Routine Care ]
                                 │
                                 ▼
                    [ Prescription Logger ]
                    (Writes prescription.txt)
```

### Stage-by-Stage Breakdown

1. **Patient Arrival & Queue Management:** Simulates patient intake at defined arrival rates, modeling waiting times and clinic throughput.
2. **Fundus Image Acquisition (`ActualFundusImageSource.m`):** Ingests real retinal fundus photographs sequentially from dataset directories (`SIH_TEST/` or `SIH_data/`), normalizing resolution to 1050×1050×3.
3. **Image Quality Assessment & Filtering:** Identifies poor-quality captures and triggers recapture attempts according to clinical thresholds.
4. **Preprocessing (`preprocessFundusImageSim.m`):** Automatically crops the circular Field of View (FOV), transforms RGB to CIE-LAB color space, applies Contrast-Limited Adaptive Histogram Equalization (CLAHE) on the luminance (L) channel, clamps intensities, and resizes to 224×224.
5. **Binary Classification:** High-sensitivity screening layer separating patients into *Non-Referable* (Grade 0–1) and *Referable* (Grade 2–4).
6. **Multiclass Classification:** Categorizes disease severity into 5 ICDR grades:
   - **Grade 0:** No DR
   - **Grade 1:** Mild Non-Proliferative DR (Microaneurysms only)
   - **Grade 2:** Moderate Non-Proliferative DR
   - **Grade 3:** Severe Non-Proliferative DR
   - **Grade 4:** Proliferative Diabetic Retinopathy (PDR)
7. **Grad-CAM Visual Explanations (`GradCAMSystem.m`):** Computes feature activation maps from deep convolutional layers (`x_conv5_Conv`) with respect to the predicted class score via automatic differentiation (`dlgradient`), generating a jet colormap overlay for clinical interpretability.
8. **Vessel Segmentation (`VesselSegmentationSystem.m`):** Extracts retinal blood vessels using multi-scale Frangi vesselness filtering, Black Top-Hat morphological enhancement on the green channel, and deep neural network inference.
9. **Patient Results Logging (`PatientResultLogger.m`):** Saves diagnostic assets to `SimulationResults/Patient_N/` including images and a detailed `report.txt`.
10. **Referable Decision Logic:** Flags patients with Grade $\ge 2$ or positive binary screening for remote physician consultation.
11. **Remote Doctor Review:** Simulates tele-ophthalmologist review time, bandwidth-constrained image transmission, and clinical validation.
12. **Prescription Generation (`PrescriptionLogger.m`):** Automatically generates `prescription.txt` with clinical follow-up recommendations for referable cases.

---

## 4. Repository Structure

```
DR-Telemedicine-Simulation/
│
├── README.md                              # Main project documentation
├── SETUP.md                               # Step-by-step setup and execution guide
├── LICENSE                                # Open-source license (MIT)
├── .gitignore                             # Git ignore rules for MATLAB/Simulink
│
├── DR_Telemedicine_Simulation_Clean.slx  # Main Simulink simulation model
├── DR_parameters.m                        # Global simulation parameters and timings
├── ActualFundusImageSource.m              # System object for sequential fundus image feed
├── preprocessFundusImageSim.m             # Image preprocessing function (CLAHE, FOV, resize)
├── GradCAMSystem.m                        # Explainable AI Grad-CAM System object
├── VesselSegmentationSystem.m             # Retinal vessel segmentation System object
├── PatientResultLogger.m                  # Comprehensive patient output logging System object
├── PrescriptionLogger.m                   # Telemedicine prescription generator System object
│
├── binary.m                               # Workspace initialization: Binary classifier ONNX import
├── multi.m                                # Workspace initialization: Multiclass classifier ONNX import
├── vessel.m / Vessel.m                    # Workspace initialization: Vessel segmentation ONNX import
│
├── models/                                # Trained neural network models & ONNX definitions
│   ├── model_binary.onnx                  # ONNX binary classifier
│   ├── model_multiclass.onnx              # ONNX multiclass classifier
│   ├── model_vessel.onnx                  # ONNX vessel segmentation network
│   ├── binaryNet.mat                      # Pre-imported MATLAB binary network object
│   ├── multiNet.mat                       # Pre-imported MATLAB multiclass network object
│   └── vesselNet.mat                      # Pre-imported MATLAB vessel network object
│
├── +model_vessel/                         # Custom layer package generated during ONNX import
│   ├── Shape_To_ResizeLayer1000.m
│   ├── Shape_To_ResizeLayer1001.m
│   ├── Shape_To_ResizeLayer1002.m
│   ├── Shape_To_ResizeLayer1003.m
│   └── Shape_To_ResizeLayer1004.m
│
├── data/
│   └── README.md                          # Instructions for acquiring and structuring datasets
│
├── docs/
│   ├── ARCHITECTURE.md                    # Detailed block and signal architecture
│   └── REPRODUCIBILITY.md                 # Reproduction guide & verification steps
│
└── output/
    └── README.md                          # Documentation of generated simulation results
```

---

## 5. Software & Toolbox Requirements

### Core Software
- **MATLAB** (R2024b, R2025a, or R2026a recommended)
- **Simulink**

### Required MATLAB Toolboxes
| Toolbox / Add-On | Required For |
| :--- | :--- |
| **Simulink** | Top-level discrete-event and signal simulation |
| **Deep Learning Toolbox** | ONNX network import, `dlnetwork`, `dlfeval`, `dlgradient` |
| **Deep Learning Toolbox Converter for ONNX Model Format** | Importing `.onnx` models (`importNetworkFromONNX`) |
| **Image Processing Toolbox** | CLAHE (`adapthisteq`), morphological filters (`imbothat`, `strel`, `bwareaopen`), color space conversion (`rgb2lab`, `lab2rgb`) |
| **Computer Vision Toolbox** | Image transformations and feature utilities |
| **Medical Imaging Toolbox** | Medical imaging pre-processing routines |
| **Statistics and Machine Learning Toolbox** | Probability calculations and queue distributions |
| **MinGW-w64 C/C++ Compiler** | Simulink Coder / MEX code-generation execution |

---

## 6. Model & Network Resources

The simulation requires three deep learning networks:

1. **Binary Classifier (`binaryNet`):**
   - Source: `models/model_binary.onnx`
   - Initialized by: `binary.m`
   - Cached in: `binaryNet.mat`
2. **Multiclass Classifier (`multiNet`):**
   - Source: `models/model_multiclass.onnx`
   - Initialized by: `multi.m`
   - Cached in: `multiNet.mat`
   - Output: 5-class probability vector (Grades 0 to 4)
3. **Vessel Segmentation Network (`vesselNet`):**
   - Source: `models/model_vessel.onnx`
   - Initialized by: `vessel.m` (or `Vessel.m`)
   - Cached in: `vesselNet.mat`
   - Package dependencies: `+model_vessel/`

---

## 7. Dataset Setup

Place your test dataset inside the `SIH_TEST/` folder (or full dataset in `SIH_data/`) structured by ICDR grade:

```
SIH_TEST/
├── 0/   # Grade 0 (No DR) PNG images
├── 1/   # Grade 1 (Mild DR) PNG images
├── 2/   # Grade 2 (Moderate DR) PNG images
├── 3/   # Grade 3 (Severe DR) PNG images
└── 4/   # Grade 4 (Proliferative DR) PNG images
```

To switch between datasets, open [ActualFundusImageSource.m](file:///ActualFundusImageSource.m) and modify:
```matlab
properties
    DatasetRoot = "SIH_TEST"   % Change to "SIH_data" for full dataset
end
```

See [data/README.md](file:///data/README.md) for full dataset specifications and public dataset references.

---

## 8. Quickstart Guide

### 1. Launch MATLAB & Navigate to Project
Open MATLAB and set the Current Folder to the root directory of this repository:
```matlab
cd 'path/to/DR-Telemedicine-Simulation'
addpath(pwd);
```

### 2. Run Workspace Initializers
Run the three initialization scripts to populate the base workspace variables:
```matlab
binary
multi
vessel
```
Verify the workspace:
```matlab
whos binaryNet multiNet vesselNet
```

### 3. Open and Compile Simulink Model
```matlab
open_system('DR_Telemedicine_Simulation_Clean.slx')
```
Press **`Ctrl + D`** to update and compile the diagram to confirm all blocks, System objects, and data types resolve without error.

### 4. Run the Simulation
Click **Run** in Simulink or execute:
```matlab
sim('DR_Telemedicine_Simulation_Clean.slx')
```

For complete step-by-step guidance, see [SETUP.md](file:///SETUP.md).

---

## 9. Simulation Output & Patient Reports

All outputs are saved to the `SimulationResults/` directory, organized by patient index:

```
SimulationResults/
└── Patient_1/
    ├── raw.png            # Original input fundus photograph (1050x1050)
    ├── processed.png      # FOV cropped, CLAHE enhanced image (224x224)
    ├── gradcam.png        # Grad-CAM attention heatmap overlay
    ├── vessel.png         # Binary retinal blood vessel segmentation mask
    ├── report.txt         # Comprehensive diagnostic summary & probabilities
    └── prescription.txt   # Telemedicine prescription (for referable cases)
```

### Example `report.txt`
```
========================================
          DIABETIC RETINOPATHY REPORT
========================================

Patient ID       : 1
DR Status        : NonReferable
DR Grade         : Grade 1
Binary Confidence: 100.00%
Grade Confidence : 96.62%
Doctor Review    : NO

----------------------------------------
Binary Probabilities
  NonReferable : 1.000000
  Referable    : 0.000000

Multi-class Probabilities
  Grade 0 : 0.033848
  Grade 1 : 0.966152
  Grade 2 : 0.000000
  Grade 3 : 0.000000
  Grade 4 : 0.000000
========================================
```

See [output/README.md](file:///output/README.md) for full details on output formats.

---

## 10. Simulation Parameters

Global parameters are defined in [DR_parameters.m](file:///DR_parameters.m):

| Parameter | Default Value | Description |
| :--- | :--- | :--- |
| `SIMULATION_TIME_HOURS` | `8` hours | Clinical shift duration |
| `PATIENTS_PER_HOUR` | `15` patients/hr | Mean patient arrival rate |
| `REGISTRATION_TIME` | `1.5` minutes | Time per patient registration |
| `CAPTURE_TIME` | `3.0` minutes | Fundus photography acquisition time |
| `POOR_IMAGE_RATE` | `0.15` (15%) | Probability of poor image quality requiring recapture |
| `MAX_RECAPTURE_ATTEMPTS` | `2` | Maximum recapture attempts per patient |
| `REFERABLE_THRESHOLD` | `2` (Grade $\ge 2$) | Clinical threshold for specialist referral |
| `DOCTOR_REVIEW_TIME` | `2.0` minutes | Specialist review time per referable patient |
| `UPLOAD_BANDWIDTH_MBPS` | `2.0` Mbps | Rural clinic upload bandwidth |

---

## 11. Limitations & Future Scope

- **Hardware Acceleration:** Inference speed depends on host CPU/GPU capabilities. Simulink models use MATLAB System blocks with single-threaded or GPU-accelerated deep learning execution.
- **Queue Modeling Assumptions:** Patient arrivals follow exponential inter-arrival distributions; real-world clinical arrival patterns may vary.
- **Image Diversity:** Preprocessing parameters are optimized for standard 45° to 50° fundus fields of view; ultra-widefield (UWF) modalities may require recalibrated FOV masking.

---

## 12. Documentation Index

- [SETUP.md](file:///SETUP.md): Fresh session startup sequence and troubleshooting.
- [docs/ARCHITECTURE.md](file:///docs/ARCHITECTURE.md): Component-level technical architecture and signal interfaces.
- [docs/REPRODUCIBILITY.md](file:///docs/REPRODUCIBILITY.md): Reproduction checklist, environment specifications, and validation steps.
- [data/README.md](file:///data/README.md): Dataset organization, acquisition, and preprocessing instructions.
- [output/README.md](file:///output/README.md): Detailed explanation of output directories and artifacts.

---

## 13. License

This project is licensed under the [MIT License](file:///LICENSE).
