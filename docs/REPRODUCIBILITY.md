# Reproducibility Guide

This guide describes how to reproduce the **Diabetic Retinopathy Telemedicine Simulation** results deterministically across different host machines.

---

## 1. System Requirements & Environment

### Hardware Specifications
- **CPU:** 64-bit Intel / AMD processor (Quad-core or higher recommended).
- **RAM:** Minimum 8 GB (16 GB or higher recommended for neural network inference and Grad-CAM computation).
- **GPU (Optional):** NVIDIA GPU with CUDA compute capability 6.0+ supported by MATLAB Deep Learning Toolbox.
- **Disk Space:** ~3 GB for MATLAB model resources, plus space for dataset images.

### Software Environment
- **Operating System:** Windows 10/11, macOS, or Linux.
- **MATLAB Version:** MATLAB R2024b, R2025a, or R2026a.
- **Required Add-Ons:**
  - Simulink
  - Deep Learning Toolbox
  - Deep Learning Toolbox Converter for ONNX Model Format
  - Image Processing Toolbox
  - Computer Vision Toolbox
  - Medical Imaging Toolbox
  - Statistics and Machine Learning Toolbox
  - MinGW-w64 C/C++ Compiler (for Simulink Coder / MEX support)

---

## 2. Step-by-Step Reproduction Checklist

### Phase 1: Environment Preparation
1. Clone or download the repository into your local workspace.
2. Launch MATLAB.
3. In MATLAB, navigate to the repository directory:
   ```matlab
   cd 'path/to/DR-Telemedicine-Simulation'
   addpath(pwd);
   ```

### Phase 2: Network Object Instantiation
Run the ONNX import scripts to populate the base workspace and ensure `.mat` caches are up-to-date:
```matlab
binary
multi
vessel
```
Validate that the three variables exist in the base workspace:
```matlab
whos binaryNet multiNet vesselNet
```

### Phase 3: Dataset Verification
Verify that test fundus images are present under `SIH_TEST/`:
```matlab
for g = 0:4
    n = numel(dir(fullfile("SIH_TEST", string(g), "*.png")));
    fprintf("Grade %d images found: %d\n", g, n);
end
```
Ensure each grade folder has at least one valid `.png` fundus image.

### Phase 4: Model Compilation & Execution
1. Open the primary model:
   ```matlab
   open_system('DR_Telemedicine_Simulation_Clean.slx')
   ```
2. Press **`Ctrl + D`** to perform an initial compilation.
3. Run the simulation for the default 8-hour shift duration (or adjust `SIMULATION_TIME` in `DR_parameters.m` for shorter test runs):
   ```matlab
   sim('DR_Telemedicine_Simulation_Clean.slx')
   ```

---

## 3. Output Validation & Sanity Checks

### Expected Output Directory Structure
Upon completion, the `SimulationResults/` folder will be populated with indexed patient directories:

```
SimulationResults/
├── Patient_1/
│   ├── raw.png
│   ├── processed.png
│   ├── gradcam.png
│   ├── vessel.png
│   ├── report.txt
│   └── prescription.txt (if Referable)
├── Patient_2/
...
```

### Validation Points
1. **`raw.png`:** Matches the first image read from `SIH_TEST/` resized to $1050 \times 1050 \times 3$.
2. **`processed.png`:** Has dimension $224 \times 224 \times 3$ with contrast enhancement in the retinal vascular bed.
3. **`gradcam.png`:** Shows color activation (warm red/yellow highlights) over pathological features.
4. **`vessel.png`:** Has dimension $512 \times 512 \times 3$ with white retinal vasculature on a black background.
5. **`report.txt`:** Sum of `Multi-class Probabilities` across Grade 0 to Grade 4 equals $1.000000 \pm 10^{-5}$.
6. **`prescription.txt`:** Is created **only** when `DR Status == Referable` (Grade $\ge 2$ or Binary Referable).

---

## 4. Deterministic Behavior & Random Seeds

- **Image Feed:** `ActualFundusImageSource.m` iterates through images deterministically in alphabetical order sorted by folder (`0` $\rightarrow$ `1` $\rightarrow$ `2` $\rightarrow$ `3` $\rightarrow$ `4`).
- **Simulink Event Timing:** To make patient arrival times and service delays deterministic across runs, set a fixed random seed in the Simulink block parameters for the arrival generator (`Uniform/Exponential Random Number` blocks).
