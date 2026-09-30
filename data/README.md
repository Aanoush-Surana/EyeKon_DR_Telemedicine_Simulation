# Dataset Specifications & Organization

This directory documentation outlines the dataset organization, formatting standards, and acquisition procedures for the **Diabetic Retinopathy Telemedicine Simulation**.

---

## 1. Expected Directory Structure

The image ingestion block (`ActualFundusImageSource.m`) expects fundus photographs organized by International Clinical Diabetic Retinopathy (ICDR) disease severity grades:

```
<DatasetRoot>/
├── 0/   # Grade 0: No Diabetic Retinopathy (Normal)
├── 1/   # Grade 1: Mild Non-Proliferative DR (Microaneurysms only)
├── 2/   # Grade 2: Moderate Non-Proliferative DR
├── 3/   # Grade 3: Severe Non-Proliferative DR
└── 4/   # Grade 4: Proliferative Diabetic Retinopathy (PDR)
```

The simulation supports two dataset configurations via the `DatasetRoot` property in `ActualFundusImageSource.m`:
1. **`SIH_TEST` (Default):** A lightweight test folder containing a representative subset of fundus images across all grades for quick simulation validation.
2. **`SIH_data`:** A comprehensive clinical dataset for full-shift epidemiological and throughput simulations.

---

## 2. Image Specifications

- **File Format:** `.png` (Standard PNG image files).
- **Color Channels:** 3-channel RGB (grayscale images are automatically converted to 3-channel; alpha channels are stripped).
- **Resolution:** Native resolution (automatically resized to $1050 \times 1050$ uint8 on ingestion).
- **Field of View:** Standard $45^\circ$ to $50^\circ$ macula-centered or optic-disc-centered fundus photographs.

---

## 3. Public Dataset Sources & Acquisition

If you do not have a pre-existing dataset, you can construct `SIH_TEST` or `SIH_data` using standardized public benchmarks:

1. **APTOS 2019 Blindness Detection:**  
   [Kaggle APTOS 2019 Dataset](https://www.kaggle.com/c/aptos2019-blindness-detection)  
   Contains 3,662 labeled fundus images categorized into Grades 0 to 4.
2. **EyePACS Diabetic Retinopathy Detection:**  
   [Kaggle Diabetic Retinopathy Detection](https://www.kaggle.com/c/diabetic-retinopathy-detection)  
   Large-scale screening dataset with clinical grade annotations.
3. **Messidor & Messidor-2:**  
   [Messidor Database](https://www.adcis.net/en/third-party/messidor/)  
   Standard benchmark for referable DR evaluation.
4. **Indian Diabetic Retinopathy Image Dataset (IDRiD):**  
   [IEEE DataPort IDRiD](https://ieee-dataport.org/open-access/indian-diabetic-retinopathy-image-dataset-idrid)  
   High-resolution fundus images with grading and pixel-level lesion annotations.

---

## 4. Data Privacy & Redistribution Notice

> [!IMPORTANT]
> Raw clinical fundus photography datasets are **not distributed directly via this Git repository** due to:
> 1. Repository file size constraints (large image collections exceed standard Git limits).
> 2. Data licensing and patient privacy stipulations governing medical research datasets.
>
> Users should download benchmark datasets directly from the verified providers listed above and organize them into the `SIH_TEST/` or `SIH_data/` directory structure.
