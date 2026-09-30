# Setup & Execution Guide

This document provides a precise, step-by-step guide for configuring and running the **Diabetic Retinopathy Telemedicine Simulation** from a clean MATLAB session.

---

## 1. Prerequisites & Environment Setup

### Required Software
- **MATLAB** (R2024b, R2025a, or R2026a recommended)
- **Simulink**

### Required MATLAB Add-Ons & Toolboxes
Confirm that the following toolboxes are installed in MATLAB (`Home` > `Add-Ons` > `Manage Add-Ons`):
1. **Simulink**
2. **Deep Learning Toolbox**
3. **Deep Learning Toolbox Converter for ONNX Model Format**
4. **Image Processing Toolbox**
5. **Computer Vision Toolbox**
6. **Medical Imaging Toolbox**
7. **Statistics and Machine Learning Toolbox**
8. **MinGW-w64 C/C++ Compiler** (or compatible C/C++ compiler for MEX generation)

---

## 2. Startup Sequence (From a Fresh MATLAB Session)

Whenever you launch MATLAB or restart your session, follow this exact sequence:

```
[ Step 1: Open MATLAB ]
          │
          ▼
[ Step 2: Set Current Folder to Repository Root ]
          │
          ▼
[ Step 3: Add Repository Root & Subfolders to Path ]
          │
          ▼
[ Step 4: Run `binary.m` ] ──> Imports Binary Classifier ONNX -> creates `binaryNet`
          │
          ▼
[ Step 5: Run `multi.m` ]  ──> Imports Multiclass Classifier ONNX -> creates `multiNet`
          │
          ▼
[ Step 6: Run `vessel.m` ] ──> Imports Vessel Segmentation ONNX -> creates `vesselNet`
          │
          ▼
[ Step 7: Verify Workspace Variables ] (`whos binaryNet multiNet vesselNet`)
          │
          ▼
[ Step 8: Verify Dataset Placement ] (`SIH_TEST/0...4` or `SIH_data/0...4`)
          │
          ▼
[ Step 9: Open `DR_Telemedicine_Simulation_Clean.slx` ]
          │
          ▼
[ Step 10: Press Ctrl + D (Compile Diagram) ]
          │
          ▼
[ Step 11: Run Simulation ]
          │
          ▼
[ Step 12: Inspect Results in `SimulationResults/` ]
```

---

## 3. Detailed Step-by-Step Instructions

### Step 1: Set Current Folder & Path
In the MATLAB Command Window, navigate to the repository root directory:
```matlab
cd 'C:\path\to\DR-Telemedicine-Simulation'
addpath(pwd);
```
Ensure that `models/` and `+model_vessel/` are accessible in the directory structure.

### Step 2: Run Workspace Initializers
The deep neural networks are supplied as ONNX models (`model_binary.onnx`, `model_multiclass.onnx`, `model_vessel.onnx`) inside `models/`. The initialization scripts import these networks into MATLAB `dlnetwork` / DAG objects and save cached `.mat` representations.

Execute these commands in order in the MATLAB Command Window:

```matlab
% 1. Initialize Binary Classifier (Referable vs Non-Referable)
binary

% 2. Initialize Multiclass Classifier (Grade 0 - 4)
multi

% 3. Initialize Retinal Blood Vessel Segmentation Network
vessel
```

> **Why are these scripts required?**
> The Simulink model and MATLAB System blocks (`GradCAMSystem.m`, `VesselSegmentationSystem.m`) load `binaryNet.mat`, `multiNet.mat`, and `vesselNet.mat` or expect their corresponding network structures in the workspace. Running these scripts generates the `.mat` files and populates the workspace. **These scripts must be rerun whenever you start a new MATLAB session.**

### Step 3: Verify Workspace Variables
Confirm that all three network objects are loaded in your base workspace:
```matlab
whos binaryNet multiNet vesselNet
```
You should see:
- `binaryNet`: `dlnetwork` or `DAGNetwork` object
- `multiNet`: `dlnetwork` or `DAGNetwork` object
- `vesselNet`: `dlnetwork` or `DAGNetwork` object

### Step 4: Configure Dataset Source
Check [ActualFundusImageSource.m](file:///ActualFundusImageSource.m):
```matlab
properties
    DatasetRoot = "SIH_TEST"  % Default test dataset
end
```
- For rapid testing, use `"SIH_TEST"`.
- For full-scale dataset screening, ensure your full dataset is in `"SIH_data"` and update `DatasetRoot = "SIH_data"`.

Make sure the target dataset directory contains subfolders `0`, `1`, `2`, `3`, and `4` populated with `.png` fundus images.

### Step 5: Open and Compile the Simulink Model
Open the primary simulation model:
```matlab
open_system('DR_Telemedicine_Simulation_Clean.slx')
```

Before pressing Run:
1. In the Simulink window, press **`Ctrl + D`** (or go to `Simulation` > `Update Diagram`).
2. Simulink will validate all block connections, signal dimensions, MATLAB Function blocks, and MATLAB System blocks.
3. If any compilation warning or error appears, resolve it before running the simulation (see Troubleshooting below).

### Step 6: Run the Simulation
Click the **Run** button in Simulink, or run from the MATLAB command prompt:
```matlab
sim('DR_Telemedicine_Simulation_Clean.slx')
```

### Step 7: Inspect Generated Patient Results
After simulation completion, open the output directory:
```matlab
cd SimulationResults
dir
```
Inspect individual patient folders (e.g., `Patient_1/`):
- `raw.png`: Captured fundus image
- `processed.png`: Preprocessed image (FOV cropped, CLAHE enhanced, 224×224)
- `gradcam.png`: Visual explainability heatmap
- `vessel.png`: Retinal blood vessel segmentation mask
- `report.txt`: Complete diagnostic report with class probabilities
- `prescription.txt`: Telemedicine prescription (for referable patients)

---

## 4. Troubleshooting & Common Issues

### Issue 1: `importNetworkFromONNX` not found
**Cause:** The Deep Learning Toolbox Converter for ONNX Model Format is not installed.  
**Fix:** In MATLAB, go to `Home` > `Add-Ons` > `Get Add-Ons`, search for `Deep Learning Toolbox Converter for ONNX Model Format`, and install it.

### Issue 2: `Cannot find +model_vessel package` or undefined custom layers
**Cause:** MATLAB cannot find the `+model_vessel` package folder when loading `vesselNet`.  
**Fix:** Ensure the Current Folder is set to the repository root where `+model_vessel/` resides. Run `rehash toolboxcache` and re-run `vessel`.

### Issue 3: `ActualFundusImageSource:NoImages` error
**Cause:** The dataset folder (`SIH_TEST` or `SIH_data`) is empty or missing subfolders `0` through `4`.  
**Fix:** Ensure `SIH_TEST/0`, `SIH_TEST/1`, `SIH_TEST/2`, `SIH_TEST/3`, and `SIH_TEST/4` contain `.png` images.

### Issue 4: Out of Memory during Grad-CAM or Vessel Segmentation
**Fix:** Reduce batch processing or ensure your system meets minimum RAM requirements (16 GB recommended).
