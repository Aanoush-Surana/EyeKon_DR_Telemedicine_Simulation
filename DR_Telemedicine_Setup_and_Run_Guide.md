# DR Telemedicine Simulation --- Setup & Run Guide

This guide explains how to prepare the MATLAB/Simulink environment,
place the required files, install the required add-ons, and run the
`DR_Telemedicine_Simulation_Clean` simulation.

------------------------------------------------------------------------

# 1. Software Required

Install:

-   MATLAB **R2026a (26.1)** or the MATLAB version used to develop the
    project.
-   Simulink.

The project was developed/tested with MATLAB R2026a.

------------------------------------------------------------------------

# 2. Required MATLAB Add-Ons / Toolboxes

The project uses the following MATLAB toolboxes:

  -----------------------------------------------------------------------
  Add-On / Toolbox                    Used for
  ----------------------------------- -----------------------------------
  **Simulink**                        Main simulation model

  **Computer Vision Toolbox**         Computer-vision/image-processing
                                      operations

  **Deep Learning Toolbox**           DR classification, Grad-CAM and
                                      neural networks

  **Image Processing Toolbox**        Fundus image preprocessing, CLAHE,
                                      resizing, image operations

  **Medical Imaging Toolbox**         Medical-image processing
                                      functionality used by the project

  **Statistics and Machine Learning   Machine-learning functionality used
  Toolbox**                           by the project

  **MinGW-w64**                       C/C++ compiler used for MEX-functionality
  -----------------------------------------------------------------------

These were available in the development environment.

------------------------------------------------------------------------

# 3. Project Folder Structure

Create one main project folder, for example:

``` text
DR_Telemedicine_Simulation_Clean/
```

Place the required files/folders inside it:

``` text
DR_Telemedicine_Simulation_Clean/
│
├── DR_Telemedicine_Simulation_EyeKon.slx
│
├── ActualFundusImageSource.m
├── PatientResultLogger.m
├── PrescriptionLogger.m
├── GradCAMSystem.m
├── VesselSegmentationSystem.m
│
├── DR_parameters.m
├── preprocessFundusImageSim.m
│
├── binary.mat / binary
├── multi.mat / multi
├── vessel.mat / vessel
├── binaryNet.mat / binaryNet
├── multiNet.mat / multiNet
├── vesselNet.mat / vesselNet
│
├── models/
├── +model_vessel/
│
├── SIH_TEST/
│
└── SimulationResults/
```

Use the actual filenames/extensions supplied with the project.

Do not rename model files unless the corresponding MATLAB code is also
changed.

------------------------------------------------------------------------

# 4. MATLAB Code Files --- Where to Place Them

The MATLAB code files should be in the **same project root folder as the
Simulink model**.

Place:

``` text
ActualFundusImageSource.m
PatientResultLogger.m
PrescriptionLogger.m
GradCAMSystem.m
VesselSegmentationSystem.m
DR_parameters.m
preprocessFundusImageSim.m
```

in:

``` text
DR_Telemedicine_Simulation_Clean/
```

This allows the MATLAB System blocks and MATLAB Function-related code to
find them directly.

------------------------------------------------------------------------

# 5. Input Dataset Placement

## Test dataset

Place the  testing dataset here:

``` text
DR_Telemedicine_Simulation_Clean/
└── SIH_TEST/
    ├── 0/
    ├── 1/
    ├── 2/
    ├── 3/
    └── 4/
```

------------------------------------------------------------------------

# 6. Configure the Image Dataset

Open:

``` text
ActualFundusImageSource.m
```

Check:

``` matlab
DatasetRoot = "SIH_TEST";
```

The folder must exist relative to the MATLAB project/current folder, or
the code must be changed to use an absolute path.

------------------------------------------------------------------------

# 7. Model Files

Keep the trained networks and model resources in the locations expected
by the project.

Important model resources include:

``` text
binaryNet
multiNet
vesselNet
```

and the associated model/resource files:

``` text
binary
multi
vessel
models/
+model_vessel/
```

Do not delete these even if they are not directly visible as Simulink
blocks.

The vessel segmentation component also requires its vessel model
resources.

------------------------------------------------------------------------

# 8. Before Running the Simulation

Perform these steps in order.

## Step 1 --- Open MATLAB

Start MATLAB.

## Step 2 --- Set the Current Folder

Set MATLAB's Current Folder to the project root:

``` text
DR_Telemedicine_Simulation_Clean/
```

The folder should contain the `.slx` file and the required `.m` files.

------------------------------------------------------------------------

## Step 3 --- Add the Project Folder to the MATLAB Path

If required, add the project folder and required subfolders to the
MATLAB path.

At minimum, MATLAB must be able to find:

``` text
ActualFundusImageSource.m
PatientResultLogger.m
PrescriptionLogger.m
GradCAMSystem.m
VesselSegmentationSystem.m
DR_parameters.m
preprocessFundusImageSim.m
```

The `+model_vessel` package should remain in the project directory
structure.

------------------------------------------------------------------------

## Step 4 --- Check the Dataset

Before opening the simulation, confirm:

``` text
SIH_TEST/0
SIH_TEST/1
SIH_TEST/2
SIH_TEST/3
SIH_TEST/4
```

contain `.png` fundus images.

If using the main dataset, check the equivalent `SIH_data` folders.

------------------------------------------------------------------------

## Step 5 --- Check the Models

Confirm that the required classifier and vessel model files are present.

In particular:

``` text
binaryNet
multiNet
vesselNet
```

must be available to the blocks that load them.

------------------------------------------------------------------------

# 9. What Needs to Be Run Before the Main Model?

There is **no separate simulation model that needs to be run first**.

The required preparation is:

``` text
MATLAB
  ↓
Set Current Folder
  ↓
Make project files/models available on MATLAB path
  ↓
Check SIH_TEST or SIH_data
  ↓
Check model files
  ↓
Open DR_Telemedicine_Simulation_Clean
  ↓
Update/Compile
  ↓
Run
```

Do not run old backup models or experimental models before starting the
main model.

------------------------------------------------------------------------

# 10. Open the Main Model

Open:

``` text
DR_Telemedicine_Simulation_Clean.slx
```

The main model contains the complete workflow:

``` text
Patient Arrival
      ↓
Patient Queue & Resource Management
      ↓
Fundus Image Acquisition
      ↓
Image Quality & Preprocessing
      ↓
Binary Classification
      ↓
Multiclass Classification
      ↓
Grad-CAM
      ↓
Vessel Segmentation
      ↓
Patient Result
      ↓
Referable Decision
      ↓
Remote Doctor Review
      ↓
Prescription
```

------------------------------------------------------------------------

# 11. Compile / Update the Model Before Running

After opening the model:

### Press:

``` text
Ctrl + D
```

This updates/compiles the Simulink diagram.

------------------------------------------------------------------------

# 12. Where the Results Appear

The main result directory is:

``` text
SimulationResults/
```

The logger creates patient-specific folders:

``` text
SimulationResults/
├── Patient_1/
├── Patient_2/
├── Patient_3/
└── ...
```

A completed patient folder can contain:

``` text
Patient_1/
├── raw.png
├── processed.png
├── gradcam.png
├── vessel.png
├── report.txt
└── prescription.txt
```

------------------------------------------------------------------------

# 15. Meaning of the Result Files

### `raw.png`

The actual fundus image supplied to the simulation for that patient.

### `processed.png`

The image after the image-quality/preprocessing stage.

### `gradcam.png`

The Grad-CAM explanation generated by the model.

### `vessel.png`

The retinal blood-vessel segmentation result.

### `report.txt`

Contains the patient's classification information, including the DR
result and model probabilities.

### `prescription.txt`

Generated after the case is classified as referable and the simulated
remote doctor review is completed.

------------------------------------------------------------------------

# 13. Recommended First Test

For the first run on a new computer:

``` text
1. Open MATLAB
2. Set Current Folder to the project root
3. Check SIH_TEST/0...4
4. Check model files
5. Open DR_Telemedicine_Simulation_Clean.slx
6. Press Ctrl + D
7. Fix any compile errors
8. Run a short simulation
9. Open SimulationResults/
10. Check Patient_1, Patient_2, ...
```

Only after this works should the full dataset and longer timings be
used.

------------------------------------------------------------------------

# 14. Important: Do Not Delete These Folders

Keep:

``` text
SIH_TEST/
models/
+model_vessel/
```

These contain input data or model resources required by the simulation.

The output folders:

``` text
SimulationResults/
```

can be cleared between tests if old results are no longer needed.

------------------------------------------------------------------------


# 15. Complete Execution Flow

``` text
INSTALL MATLAB + REQUIRED TOOLBOXES
                ↓
COPY PROJECT FOLDER
                ↓
PLACE DATASETS
(SIH_TEST)
                ↓
PLACE MODELS + MATLAB FILES
                ↓
SET MATLAB CURRENT FOLDER
                ↓
CHECK DatasetRoot
                ↓
OPEN DR_Telemedicine_Simulation_Clean
                ↓
PRESS Ctrl + D
                ↓
NO COMPILE ERRORS?
       ↓                 ↓
      YES                NO
       ↓                 ↓
     RUN          FIX ERROR FIRST
       ↓
PATIENTS PROCESSED
       ↓
SimulationResults/
       ↓
Patient_1, Patient_2, ...
       ↓
raw / processed / Grad-CAM /
vessel / report / prescription
```
