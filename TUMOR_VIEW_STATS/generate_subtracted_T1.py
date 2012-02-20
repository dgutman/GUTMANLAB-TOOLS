#! /usr/bin/env python

# run check_for_duplicates_raw_nifti.py first to ensure the files are unique
# this script generates a set of files that are obtained from subtracting a raw T1-PRE-GD from a T1-POST-GD 
# image (the T1-PRE-GD must be registered to the T1-POST-GD first)
# written by Alexandra Anghelescu on 6/3/2011
# last update 6/6/2011

import glob, re, os

T1_PRE_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/RAW_NIFTI_FILES/AXIAL-T1-PRE-GD/'
T1_POST_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/RAW_NIFTI_FILES/AXIAL-T1-POST-GD/'
SUB_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/SUBTRACTED_T1_FILES/'
REG_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/FLIRT_T1_FILES/'

post_gd_files = []

#make a list of all POST-GD nii.gz files
for file_path in glob.glob(T1_POST_PATH + '*.nii.gz'):
    path = file_path.split('/')
    post_gd_files.append(path[len(path)-1])

for files in post_gd_files:
    m = re.search('(TCGA-\d\d-\d\d\d\d)_.*|(HF\d\d\d\d)_.*', files)
    if m.group(1):
        patient_id = m.group(1)
    else:
        patient_id = m.group(2)
 
    #search for the corresponding PRE-GD file
    pre_gd_files = glob.glob(T1_PRE_PATH + patient_id +'*.nii.gz')
   
    #make sure the pre_gd_file exists and it is unique   
    if len(pre_gd_files) == 1:
        REG_FILE_NAME = REG_PATH + patient_id + '_REG-T1-PRE-TO_POST.nii.gz'
        SUB_FILE_NAME = SUB_PATH + patient_id + '_T1-POST-SUB-PRE.nii.gz'
	print "Files to process include...",REG_FILE_NAME,SUB_FILE_NAME
        if not os.path.exists(REG_FILE_NAME):
            # register images  
	    print "Trying to register images",pre_gd_files[0], T1_POST_PATH,files, REG_FILE_NAME
            os.system('fsl4.1-flirt -in '+ pre_gd_files[0] + ' -ref '+ T1_POST_PATH + files + ' -out '+ REG_FILE_NAME)
        if (not os.path.exists(SUB_FILE_NAME)) and os.path.exists(REG_FILE_NAME):
            # subtract images 
            os.system('fsl4.1-fslmaths '+ T1_POST_PATH + files +' -sub '+ REG_PATH + patient_id + '_REG- T1-PRE-TO_POST.nii.gz -thr 0 ' + SUB_FILE_NAME)
        
   

         
