# this script checks for duplicates in the subfolders of BASE_PATH
# if dups are found it moves them in a subdir DUP_TO_FIX within that dir
# written by Alexandra Anghelescu on 6/3/2011
# last updated 6/3/2011


import glob, re, os

BASE_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/RAW_NIFTI_FILES/'

subdirs = []

#get a list of subdirs 
for subdir in glob.glob(BASE_PATH + '*'):
    path = subdir.split('/')
    subdirs.append(path[len(path)-1])
 
#check for duplicates in each subdir
for subdir in subdirs:
    #look at .nii.gz files only 
    files_to_check = glob.glob(BASE_PATH + subdir + '/*.nii.gz')
    for files in files_to_check:
        path = files.split('/')
        files = path[len(path)-1] 
        #extract patient_id
        m = re.search('(TCGA-\d\d-\d\d\d\d)_.*|(HF\d\d\d\d)_.*', files)
    	if m.group(1):
            patient_id = m.group(1)
            #print patient_id, '   ', subdir
        else:
            patient_id = m.group(2)
            #print patient_id, '   ', subdir
        patient_file = glob.glob(BASE_PATH + subdir + '/' + patient_id +'*.nii.gz')
        if len(patient_file) != 1:
            print "this patient has duplicates ", patient_id, ' in ', subdir      
            os.system('mv '+ BASE_PATH + subdir + '/' + patient_id +'_*.nii.gz ' + BASE_PATH + subdir +'/DUP_FILES_TO_FIX/') 
           
            
       
