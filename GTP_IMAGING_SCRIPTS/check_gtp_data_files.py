'''
Created on December 12, 2011
This program will search for all resources and files for the GTP project and make sure I have
all of the data I need for a TBS or VBM analysis

@author: dgutman, aanghel
'''
import os,glob,re , sys
from pyxnat import Interface


PROJECT_ID="GTP_PROD"

def check_xnat_to_see_if_experiment_id_exists(SUBJECT_ID,EXPERIMENT_ID):
    '''This function will query an XNAT server and see if a project exists '''
    return xnat.select.project(PROJECT_ID).subject(SUBJECT_ID).experiment(EXPERIMENT_ID).exists()

# setup the connection
xnat= Interface(server='http://xnat.cci.emory.edu:8080/xnat',
                user='nbia',password='nbia',
                cachedir=os.path.join(os.path.expanduser('~'),'.store'))
 

project_object  = xnat.select.project(PROJECT_ID)

subject_list = project_object.subjects().get()
print len(subject_list)," patients are in XNAT currently..."

subject_label_list = []

subject_ignore_list = [ '9184', '7293','7591', '935' ]

dti_subject_ignore_list = [ '8496', '8593','9083','9264', '9295','9465','9647', '9894' ]


## there are some patients where the data is corrupted and/or patient wasn't scanned but a dir exists.



#####################3 going to convert the subject_list which has the URI into labels
for subject in subject_list:
    subject_label =  project_object.subject(subject).attrs.get('label')
    if(subject_label not in subject_ignore_list):
        subject_label_list.append(subject_label) 

### now check the local directory to look for files that have been converted to NIFTI

ROOT_DIRECTORY_TO_CHECK = '/IMAGING_SCRATCH/RESSLER_TRAUMA_IMAGING/'
T1_IMAGE_LIST = glob.glob(ROOT_DIRECTORY_TO_CHECK+"RESIL*/structural_data/T1_flipped.nii.gz")

MANUAL_BET_IMAGE_LIST = glob.glob(ROOT_DIRECTORY_TO_CHECK+"RESIL*/structural_data/manual_bet/T1_flipped_bet.nii.gz")
MANUAL_BET_MASK_IMAGE_LIST = glob.glob(ROOT_DIRECTORY_TO_CHECK+"RESIL*/structural_data/manual_bet/T1_flipped_bet_mask.nii.gz")
DTI_FA_IMAGE_LIST = glob.glob(ROOT_DIRECTORY_TO_CHECK+"RESIL*/dti_data/data_FA.nii.gz")


subjects_with_T1_MPRAGE = []
for individual_image in T1_IMAGE_LIST:
    patient_id = re.search(r'Subject_+(\d{2,5})',individual_image)
#   print individual_image,"for",patient_id.group(1)
    subjects_with_T1_MPRAGE.append(patient_id.group(1))

subjects_with_BET_IMAGE = []
for individual_image in MANUAL_BET_IMAGE_LIST:
    patient_id = re.search(r'Subject_+(\d{2,5})',individual_image)
#   print individual_image,"for",patient_id.group(1)
    subjects_with_BET_IMAGE.append(patient_id.group(1))

subjects_with_BET_MASK_IMAGE = []
for individual_image in MANUAL_BET_MASK_IMAGE_LIST:
    patient_id = re.search(r'Subject_+(\d{2,5})',individual_image)
#   print individual_image,"for",patient_id.group(1)
    subjects_with_BET_MASK_IMAGE.append(patient_id.group(1))

subjects_with_DTI_IMAGE = []
for individual_image in DTI_FA_IMAGE_LIST:
    patient_id = re.search(r'Subject_+(\d{2,5})',individual_image)
#   print individual_image,"for",patient_id.group(1)
    subjects_with_DTI_IMAGE.append(patient_id.group(1))


print len(subjects_with_T1_MPRAGE),"subjects had T1 images in processing directory"

### now figure out which patients have T1 MPRAGE images in the processing directory

for subject in subject_label_list:
    if(subject not in subjects_with_T1_MPRAGE):
	print "Patient",subject,"still needs a T1 MPRAGE image ";
    if(subject not in subjects_with_BET_MASK_IMAGE):
	print "Patient",subject,"still needs a T1 MASK IMAGE ";
    if(subject not in subjects_with_BET_IMAGE):
	print "Patient",subject,"still needs a BET image ";
    if(subject not in subjects_with_DTI_IMAGE and subject not in dti_subject_ignore_list):
	print "Patient",subject,"still needs a DTI image ";


print "There were a total of",len(subjects_with_DTI_IMAGE),"subjects with DTI images"
print "There were a total of",len(subjects_with_T1_MPRAGE),"subjects with a T1 MPRAGE"

sys.exit()

for subject in subject_list:
   subject_label =  project_object.subject(subject).attrs.get('label')
# I also want to see what resources are available for this subject...
# so am going to iterate through each experiment for each subject... 
   experiment_id_list_for_patient = project_object.subject(subject).experiments().get()
   print len(experiment_id_list_for_patient),"experiments were found for patient",subject,subject_label
   if ( not len(experiment_id_list_for_patient) == 1 ):
        print "This patient had more than one experiment and needs cleanup.."
   else:
#       print experiment_id_list_for_patient[0],"was the found experiment id"
#       print "Will now determine if a T1_MPRAGE alraedy exists for this experiment ID..... ",experiment_id_list_for_patient[0],subject
        expt_obj = project_object.subject(subject).experiment(experiment_id_list_for_patient[0])
        # nw I need to see if the resource NIFTI_GZ and the folder STRUCTURAL_IMAGES exists...
	print expt_obj.resources().files().get()
        t1_file_name = subject_label+"_T1_flipped.nii.gz"
        if( expt_obj.resource('NIFTI_GZ').file(t1_file_name).exists()):
	    print "found T1 image"

sys.exit()

ROOT_DIRECTORY_TO_CHECK = '/SGE_RAID/RESSLER_TRAUMA_IMAGING/'
T1_IMAGE_LIST = glob.glob(ROOT_DIRECTORY_TO_CHECK+"RESIL*/structural_data/T1_flipped.nii.gz")


for individual_image in T1_IMAGE_LIST:
    print individual_image
    patient_id = re.search(r'Subject_(\d{2,5})',individual_image)
#   print patient_id.group(1)
# I now need to determine the experiment ID for this subject
    experiment_id_list_for_patient = project_object.subject(patient_id.group(1)).experiments().get()
    print len(experiment_id_list_for_patient)," experiments were found for patient ",patient_id.group(1)
    if ( not len(experiment_id_list_for_patient) == 1 ):
	print "This patient had more than one experiment and needs cleanup.."
    else:
#       print experiment_id_list_for_patient[0],"was the found experiment id"
#	print "Will now determine if a T1_MPRAGE alraedy exists for this experiment ID..... ",experiment_id_list_for_patient[0],patient_id.group(1)
	expt_obj = project_object.subject(patient_id.group(1)).experiment(experiment_id_list_for_patient[0])
#	print expt_obj.get()
#	print experiment_id_list_for_patient[0]
	# nw I need to see if the resource NIFTI_GZ and the folder STRUCTURAL_IMAGES exists...
	print individual_image
	t1_file_name = patient_id.group(1)+"_T1_flipped.nii.gz"
	if( expt_obj.resource('NIFTI_GZ').file(t1_file_name).exists()):
	    print "Image",t1_file_name,"already exists for this subject"
	else:
	    expt_obj.resource('NIFTI_GZ').file(t1_file_name).put(individual_image,content='T1_STRUCT_FLIPPED',format='NIFTI_GZ',tags='T1_MPRAGE')	

#	scan_list_for_experiment = project_object.experiment(experiment_id_list_for_patient[0]).scans(constraints={'xnat:mrScanData/type':'t1_mprage_sag'}).get()
#	print scan_list_for_experiment


project_object  = xnat.select.project(PROJECT_ID)
subject_list_for_project = project_object.subjects().get('label')
print len(subject_list_for_project),"patients are in the ",PROJECT_ID," set"


# first iterate through subjects
#for current_patient in subject_list_for_project:
#    print current_patient
# now iterate through subjects with associated experiemnts
#    experiments_for_this_subject = project_object.subject(current_patient).experiments().get()
                               
