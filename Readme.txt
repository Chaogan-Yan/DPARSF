Data Processing Assistant for Resting-State fMRI (DPARSF) is a convenient plug-in software based on SPM and REST. You just need to arrange your DICOM files, and click a few buttons to set parameters, DPARSF will then give all the preprocessed (slice timing, realign, normalize, smooth) data, FC, ReHo, ALFF and fALFF results. DPARSF can also create a report for excluding subjects with excessive head motion and generate a set of pictures for easily checking the effect of normalization. You can use DPARSF to extract AAL or ROI time courses (or extract Gray Matter Volume of AAL regions, command line only) efficiently if you want to perform small-world analysis. DPARSF basic edition is very easy to use, just click on buttons if you are not sure what it means, popup tips would tell you what you need to do. DPARSF advanced edition (alias: DPARSFA) is much more flexible, you can use it to reorient your images interactively or define regions of interest interactively. You can skip or combine the processing steps in DPARSF advanced edition freely. Please download a MULTIMEDIA COURSE  to know more about how to use this software. 

Add DPARSF's directory to MATLAB's path and enter "DPARSF" or "DPARSFA" in the command window to enjoy DPARSF basic edition or advanced edition.

YAN Chao-Gan
The Nathan Kline Institute for Psychiatric Research, 140 Old Orangeburg Road, Orangeburg, NY 10962; Child Mind Institute, 445 Park Avenue, New York, NY 10022; The Phyllis Green and Randolph Cowen Institute for Pediatric Neuroscience, New York University Child Study Center, New York, NY 10016
State Key Laboratory of Cognitive Neuroscience and Learning, Beijing Normal University, China, 100875
ycg.yan@gmail.com

New features of DPARSF_V2.1_120101:
For DPARSFA (Advanced Edition):
1. Support .nii and .nii.gz 3D or 4D files. For 4D .nii(.gz) functional files, use Checkbox "4D Fun .nii(.gz) to 3D" to convert into 3D files. For T1 3D .nii.gz files, use Checkbox "Unzip T1 .gz" to unzip. Use Checkbox "Crop T1" to Reorient to the nearest orthogonal direction to "canonical space" and remove excess air surrounding the individual as well as parts of the neck below the cerebellum (MRIcroN's dcm2nii).
2. Normalize by DARTEL has been added. Details: (1) "T1 Coreg to Fun": the individual structural T1 image is coregistered to the mean functional image after motion correction. (2) "New Segment + DARTEL": New Segment -- The transformed structural image is then segmented into gray matter, white matter and cerebrospinal fluid by using "New Segment" in SPM8. (3) "New Segment + DARTEL": DARTEL -- Create Template, and DARTEL -- Normalize to MNI space (Many Subjects) for GM, WM, CSF and T1 Images (unmodulated, modulated and smoothed [8 8 8] kernel versions). (4) "Normalize by DARTEL": DARTEL Normalize to MNI space (Few Subjects) for functional images. (5) "Smooth by DARTEL": DARTEL Normalize to MNI space (Few Subjects) for functinal images but with smooth kernel as specified, the smoothing is part of the normalisation to MNI space computes these average intensities from the original data, rather than the warped versions.
3. Reorient functional images and reorient T1 images interactively before coregistration: Checkbox "Reorient Fun*" and Checkbox "Reorient T1*". Interactively reorienting the anatomic images and functional images so that the origin approximated the anterior commissure and the orientation approximated MNI space, this will improve the accuracy in coregistration and segmentation. This step could probably solve the bad normalization problem for some subjects in "normalized by unified segmentation" or "normalized by DARTEL".
4. Multiple functional sessions supported. The directory should be named as FunRaw (or FunImg) for the first session; S2_FunRaw (or S2_FunImg) for the second session; and S3_FunRaw (or S3_FunImg) for the third session... In "Realign", "the sessions are first realigned to each other, by aligning the first scan from each session to the first scan of the first session. Then the images within each session are aligned to the first image of the session." (from SPM Manual).
5. Fixed a bug for calculation error in the second (and 3rd, 4th, ...) subjects in "Calculate in Original Space (Warp by information in unified segmentation)".
6. The calculations of ALFF and fALFF are promoted before filtering. Fixed a previous bug of calculating fALFF after filtering in the previous version of DPARSFA.
7. Mac OS compatible.
8. Template Parameters in DPARSFA:
    8.1. Standard Steps: Normalized by DARTEL
    8.2. Standard Steps: Normalized by DARTEL (Start from .nii.gz files)
    8.3. Standard Steps: Normalized by T1 image unified segmentation
    8.4. Calculate in Original Space (Warp by information in unified segmentation)
    8.5. Intraoperative Processing
    8.6. VBM (New Segment and DARTEL)
    8.7. VBM (unified segmentaition)
    8.8. Blank
   
For DPARSF (Basic Edition)
1. Normalize by DARTEL has been added. By checking "Normalized by using.. DARTEL", the processing details are the same as in DPARSFA: (1) "T1 Coreg to Fun": the individual structural T1 image is coregistered to the mean functional image after motion correction. (2) "New Segment + DARTEL": New Segment -- The transformed structural image is then segmented into gray matter, white matter and cerebrospinal fluid by using "New Segment" in SPM8. (3) "New Segment + DARTEL": DARTEL -- Create Template, and DARTEL -- Normalize to MNI space (Many Subjects) for GM, WM, CSF and T1 Images (unmodulated, modulated and smoothed [8 8 8] kernel versions). (4) "Normalize by DARTEL": DARTEL Normalize to MNI space (Few Subjects) for functional images. (5) "Smooth by DARTEL": DARTEL Normalize to MNI space (Few Subjects) for functinal images but with smooth kernel as specified, the smoothing is part of the normalisation to MNI space computes these average intensities from the original data, rather than the warped versions.

Hope to finish a video course for the new features in soon.

New features of DPARSF_V2.0_110505:
1. Fixed an error in the future MATLAB version in "[pathstr, name, ext, versn] = fileparts...".

New features of DPARSF_V2.0_101025:
1. DPARSF advanced edition (alias: DPARSFA) is added with the following new features:
1.1. The processing steps can be freely skipped or combined.
1.2. The processing can be start with any Starting Directory Name.
1.3. Support ReHo, ALFF/fALFF and Functional Connectivity calculation in individual space.
1.4. The masks or ROI files would be resampled automatically if the dimension mismatched the functional images.
1.5. The masks or ROI files in standard space can be warped into individual space by using the parameters estimated in unified segmentaion.
1.6. Support VBM analysis by checking "Segment" only.
1.7. Support reorientation interactively if the images in a bad orientation.
1.8. Support define regions of interest interactively based on the participant's T1 image in individual space.

2. DPARSF basic edition is preserved with the same operation style with DPARSF V1.0. DPARSF basic edition has the following new features:
2.1. Fixed a bug in copying "*.ps" files.
2.2. Will not check "wra*" prefix in "FunImgNormalized" directory.
2.3. Fixed a bug while regress out head motion parameters only.

The multimedia course for DPARSF advanced edition is estimated to be released in this November, thanks for your patience.

New features of DPARSF_V1.0_100510:
1. Added a right-click menu to delete all the participants' ID.
2. Fixed a bug in converting DICOM files to NIfTI in Windows 7, thanks to Prof. Chris Rorden's new dcm2nii.
3. Now will detect if co* T1 image (T1 image which is reoriented to the nearest orthogonal direction to 'canonical space' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum) exists before normalization by using T1 image unified segmentation. T1 image without 'co' is also allowed in the analysis now.

New features of DPARSF_V1.0_100420:
1. After extracting ROI time courses, not just functional connectivity will be calculated, but also transform the r values to z values by Fisher's z transformation.
2. Fixed a bug in generating pictures for checking normalization when the bounding box is not [-90 -126 -72;90 90 108].

New features of DPARSF_V1.0_100201:
1. Save the configuration parameters automatically.
2. Fixed the bug in converting DICOM files to NIfTI files when DPARSF stored under C:\Program Files\Matlab\Toolbox.
3. Fixed the bug in converting DICOM files to NIfTI files when the filename without extension.

New features of DPARSF_V1.0_091215:
1. Also can regress out other kind of covariates other than head motion parameters, Global mean signal, White matter signal and Cerebrospinal fluid signal.

New features of DPARSF_V1.0_091201:
1. Added an option to choose different Affine Regularisation in Segmentation: East Asian brains (eastern) or European brains (mni). The interpretation of this option from SPM is: ¡°If you can approximately align your images prior to running Segment, then this will increase the robustness of segmentation. Another thing that may help would be to change the regularisation of the initial affine registration, via Segment->Custom->Affine Regularisation. If you set this to "ICBM space template - East Asian brains (or European brains)", then the algorithm will make use of knowledge about the approximate variability to expect among the width/length etc of the brains of the population.¡± ¡°The prior probability distribution for affine registration of East-Asian brains to MNI space was derived from 65 seg_inv_sn.mat files from Singapore. The distribution of affine transforms of European brains was estimated from: Incorporating Prior Knowledge into Image Registration NeuroImage, Volume 6, Issue 4, November 1997, Pages 344-352 J. Ashburner, P. Neelin, D. L. Collins, A. Evans, K. Friston.¡±
2. Added a Utility: change the Prefix of Images since DPARSF need some special prefixes in some cases. For example, if you do not have T1 DICOM files and your T1 NIFTI files are not initiated with ¡°co¡±, then you can use this utility to add the ¡°co¡± prefix to let DPARSF perform normalization based on segmentation of T1 images.
3. Added a popup menu to delete selected subject by right click.
4. Added a checkbox for removing first time points.
5. Added a function to close wait bar when program finished.
 
New features of DPARSF_V1.0Beta_091001:

1. SPM8 compatible.
2. Generate the pictures (output in {Working Directory}\PicturesForChkNormalization\) for checking normalization.

New features of DPARSF_V1.0Beta_090911:
1. Fixed the bug of setting user's defined mask.

New features of DPARSF_V1.0Beta_090901:
1. Fixed the bug of setting FWHM kernel of smooth.
2. Smooth the mReHo results.
3. Remove any number of the first time points.

New features of DPARSF_V1.0Beta_090713:
1. mReHo - 1, mALFF - 1, mfALFF - 1 function.
2. Creating report for excessive head motion subjects excluding.

New features of DPARSF_V1.0Beta_090701:
1. Linux compatible.

DPARSF's standard processing steps:
1. Convert DICOM files to NIFTI images.
2. Remove First 10 (more or less) Time Points.
3. Slice Timing.
4. Realign.
5. Normalize.
6. Smooth (optional).
7. Detrend.
8. Filter.
9. Calculate ReHo, ALFF, fALFF (optional).
10. Regress out the Covariables (optional).
11. Calculate Functional Connectivity (optional).
12. Extract AAL or ROI time courses for further analysis (optional).

-----------------------------------------------------------
Citing Information:
If you think DPARSFA is useful for your work, citing it in your paper would be greatly appreciated.
Something like "... The preprocessing was carried out by using Data Processing Assistant for Resting-State fMRI (DPARSF) (Yan & Zang, 2010, http://www.restfmri.net) which is based on Statistical Parametric Mapping (SPM8) (http://www.fil.ion.ucl.ac.uk/spm) and Resting-State fMRI Data Analysis Toolkit (REST, Song et al., 2011. http://www.restfmri.net)..."
Reference: Yan C and Zang Y (2010) DPARSF: a MATLAB toolbox for "pipeline" data analysis of resting-state fMRI. Front. Syst. Neurosci. 4:13. doi:10.3389/fnsys.2010.00013;     Song, X.W., Dong, Z.Y., Long, X.Y., Li, S.F., Zuo, X.N., Zhu, C.Z., He, Y., Yan, C.G., Zang, Y.F., 2011. REST: A Toolkit for Resting-State Functional Magnetic Resonance Imaging Data Processing. PLoS ONE 6, e25031.

DPARSF is based on MRIcroN' dcm2nii, SPM and REST, if you used the related modules, the following software may need to be cited:
Step 1: MRIcroN software (by Chris Rorden, http://www.mricro.com).
Step 3 - Step 6: Statistical Parametric Mapping (SPM8, http://www.fil.ion.ucl.ac.uk/spm).
Step 7 - Step 11: Resting-State fMRI Data Analysis Toolkit (REST, Song et al., 2011. http://www.restfmri.net)
