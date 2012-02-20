# Written by Alexandra Anghelescu on 6/2/2011
# this script segments and labels the tumors (masks in MASK_PATH) in 2 classes using FAST
## and outputs the volume of the 2 classes 
# last updated 6/9/2011
# outputs statistics to stdout

import glob, re, os, sys
import subprocess as sp


### OLD VALUES FROM ALEX.. DEPREACTED
#The path to the tumor masks 
#MASK_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/NIFTI_MASKS/POST_GD_MASKS/'
#Path to the tumor volumes (subtracted T1 images with tumor mask) 
#TUMOR_VOL_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/SUBTRACTED_T1_FILES/TUMOR_VOLUMES/'
#Path to the subtracted T1 images
#SUB_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/SUBTRACTED_T1_FILES/'
#Path to tumor classes
#SEG_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/SUBTRACTED_T1_FILES/TUMOR_VOLUMES/SEGMENTED_VOLUMES/'



SEG_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/WORKING_FILES/TUMOR_VOLUMES/SEGMENTED_VOLUMES/'

### this contains the TUMOR VOLUME MASK... which is basically the input postGD image masked to only include the area containg tumor volume
TUMOR_VOL_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/WORKING_FILES/TUMOR_VOLUMES/'

#MASK_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/PLASTIMATCH_MASK_EXPORT_PRUNED/'
MASK_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/PLASTIMATCH_MASK_EXPORT/'

 
masks = []
patients_to_check = []

#make a list of all nii.gz masks 
for file_path in glob.glob(MASK_PATH + '*POST*'):
    path = file_path.split('/')
    if path[len(path)-1].endswith('.nii.gz'):
        masks.append(path[len(path)-1])

print len(masks),"masks were foudn to segment.... "


for mask in masks:
    #extract patient id and mask author
    m = re.search('(TCGA-\d\d-\d\d\d\d)_(.*).nii.gz|(HF\d\d\d\d)_(.*).nii.gz', mask)
    if m.group(1):
        patient_id = m.group(1)
        author = m.group(2)
    else:
        patient_id = m.group(3)
        author = m.group(4)
    print 'id is ', patient_id, 'author is ', author  



    (dir, file) = os.path.split(mask)
#    print "file is",file,"and dir is",dir
    file_name_elements = file[:-7].split('_')
    if len(file_name_elements)==4:
		subject_id=file_name_elements[0]
		scan_type=file_name_elements[1]
		rt_file_name=file_name_elements[2]
		mask_file_name=file_name_elements[3]
		print subject_id,scan_type,rt_file_name,mask_file_name	
    else:
	    print "FILE NAME ERROR FOR ",file	
    background_image = MASK_PATH+'BACKGROUNDS/'+subject_id+"_"+scan_type+"_"+rt_file_name+'_BACKGROUND.nii.gz'
    if os.path.exists(background_image):
#	print "Found background iamge!! woo hoo"
        pass
    else:
	print "Can't find",background_image

    #find the corresponding subtracted T1 image
#    subtracted_T1 = glob.glob(SUB_PATH + patient_id + '_T1-POST-SUB-PRE.nii.gz')
   
    TUMOR_ONLY_VOL_FILE = TUMOR_VOL_PATH + subject_id+"_"+scan_type+"_"+rt_file_name+"_"+mask_file_name+'_TUMOR-VOL'
    print "looking for "+TUMOR_ONLY_VOL_FILE
    if not os.path.exists(TUMOR_ONLY_VOL_FILE+'.nii.gz'):
            #apply mask and get the tumor volume 
        os.system('fsl4.1-fslmaths ' + background_image +' -mas ' + MASK_PATH + mask + '.nii.gz '+ TUMOR_ONLY_VOL_FILE)
        print "running fslmaths "
    if (not os.path.exists(SEG_PATH + subject_id+"_"+scan_type+"_"+rt_file_name+"_"+mask_file_name+'_TUMOR-VOL' +'_pve_0.nii.gz')) and os.path.exists(TUMOR_ONLY_VOL_FILE+'.nii.gz'):
            #run fast on the tumor volume
	    print "I am in this loop...for",TUMOR_ONLY_VOL_FILE
	    print "Should be looking for",SEG_PATH + TUMOR_ONLY_VOL_FILE +'_pve_0.nii.gz'
            os.system('fsl4.1-fast -n 2 -t 2 ' + TUMOR_ONLY_VOL_FILE)
	    os.system('mv '+ TUMOR_VOL_PATH + subject_id+"_"+scan_type+"_"+rt_file_name+"_"+mask_file_name+'_TUMOR-VOL_'  + '* '+ SEG_PATH) 
        # use fslstats to get the volume info for ROI 
        # white region vol is accurate - fast will output it as class 0 (pve_0)
        # dark region vol = whole_tumor - white_reg (pve_1 from fast is not accurate due to artifacts
        ## generated from subtracting the T1 images)
        #os.system('fslstats ' + subtracted_T1[0] +' -k '+ MASK_PATH + patient_id + '_POST-GD-MASK_'+ author +'.nii.gz -v | awk \'{ print " vol of tumor is ", $2  }\'' ) 
	#os.system('fslstats ' + subtracted_T1[0] +' -k '+ SEG_PATH + patient_id + '_TUMOR-VOL_'+ author +'_pve_0.nii.gz -v | awk \'{ print " vol of bright region is  ", $2  }\'' )
    print background_image ," is the background image"
    handle = sp.Popen(['fsl4.1-fslstats', background_image , '-k', TUMOR_ONLY_VOL_FILE +'.nii.gz', '-v'], stdout=sp.PIPE, stderr=sp.PIPE)
    stdout, stderr = handle.communicate()
    vol = stdout.split(' ')[1]
    print vol,"is the volume of the tumor"
    handle = sp.Popen(['fsl4.1-fslstats', background_image , '-k', SEG_PATH +  subject_id+"_"+scan_type+"_"+rt_file_name+"_"+mask_file_name+'_TUMOR-VOL' +'_pve_0.nii.gz', '-v'], stdout=sp.PIPE, stderr=sp.PIPE)
    stdout, stderr = handle.communicate()
    bright_vol = stdout.split(' ')[1]

    print 'Volume of the tumor is ', vol
    print 'Bright region vol: ', bright_vol
    print 'Dark region vol: ', float(vol) - float(bright_vol), '\n' 
    	
    #else:
        # sub_file missing probably bc t1-pre-gd file was missing, so sub_file was not generated
        # masks are drawn on a t1-post-gd so, theoretically, that file should exist 
     #   patients_to_check.append(patient_id)     


print '\n list of patients to check: \n', patients_to_check







   

