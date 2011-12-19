'''
Created on October 18, 2011
This program will search a file and determine project and experiment and determine 
if the patient has been uploaded to XNAT
This program will attempt to sync the ressler dat aarchive from the BITC with 
@author: dgutman and aanghehel
'''

import os,glob,re , sys
from pyxnat import Interface

PROJECT_ID="GTP_PROD"
# setup the connection
xnat= Interface(server='http://xnat.cci.emory.edu:8080/xnat',
                user='nbia',password='nbia',
                cachedir=os.path.join(os.path.expanduser('~'),'.store'))

## this directory gets rsynced with the BITC server every week to get latest imaging cases...
ROOT_DIRECTORY_TO_CHECK = '/drobo/BITC_MIRROR/RESSLER_DATA/ressler/PSYCHIATRY-RESSLERRESILIENCEandVULNERABILITY/'

rootdir = ROOT_DIRECTORY_TO_CHECK
subj_dirs = [ f for f in glob.glob1(rootdir, '*Subject*') if os.path.isdir(os.path.join(rootdir, f)) ]
#print subj_dirs
print len(subj_dirs),"directories had a RESSLER  tag"

#print subj_dirs

DIRECTORIES_ON_HARD_DRIVE = []


for individual_directories in subj_dirs:
#    print individual_directories
    patient_id = re.search(r'(Subject\d+)_(\d+)',individual_directories) 
    only_id = re.search(r'Subject(\d{2,5})',individual_directories)
    if patient_id and patient_id.group(1):
#       print patient_id.group(1)
        DIRECTORIES_ON_HARD_DRIVE.append(only_id.group(1))
#    elif patient_id and patient_id.group(2):
#        print patient_id.group(2) 
#        DIRECTORIES_ON_HARD_DRIVE.append(only_id.group(1))
    else:
	 print "No tag found for that patient ",individual_directories

myset = set()
for x in DIRECTORIES_ON_HARD_DRIVE:
 if x in myset:
   print "x is duplicate",x
 else:
   myset.add(x)

        
print len(DIRECTORIES_ON_HARD_DRIVE),"directories had a RESSLER  tag"
DIRECTORIES_ON_HARD_DRIVE = set(DIRECTORIES_ON_HARD_DRIVE) #unique patient list              
print len(DIRECTORIES_ON_HARD_DRIVE),"were unique patients"        


### NOW QUERY XNAT TO FIND PATIENTS TO STILL UPLOAD

project_object  = xnat.select.project(PROJECT_ID)
subject_list_for_project = project_object.subjects().get('label')

print len(subject_list_for_project),"patients are in the ",PROJECT_ID," set"
total_patients_with_imaging_data=0
patients_with_imaging_data = []


# first iterate through subjects
for current_patient in subject_list_for_project:
#    print current_patient
# now iterate through subjects with associated experiemnts
    experiments_for_this_subject = project_object.subject(current_patient).experiments().get()
    found_imaging_data=0

#for current_exp in project_object.subject(current_patient).experiments().get():
#    scans_for_this_subject = project_object.subject(current_patient).experiment(current_exp).scans().get()
#    if len(scans_for_this_subject) == 0:
        #this is exp has no scans
    for experiment_id in experiments_for_this_subject:
#       print experiment_id
        scans_for_this_subject = project_object.subject(current_patient).experiment(experiment_id).scans().get()
        if len(scans_for_this_subject) > 0:
            found_imaging_data=1
            patients_with_imaging_data.append(current_patient)
            total_patients_with_imaging_data += found_imaging_data

print "A total of",total_patients_with_imaging_data,"had imaging data in XNAT for the ",PROJECT_ID,"project"
print len(patients_with_imaging_data)," total experiments associated with this data set"
#patients_with_imaging_data =set(patients_with_imaging_data)
unique_patient_list_in_xnat = set(patients_with_imaging_data)
print len(unique_patient_list_in_xnat),"unique patients are in this set"


def check_xnat_to_see_if_experiment_id_exists(SUBJECT_ID,EXPERIMENT_ID):
    '''This function will query an XNAT server and see if a project exists '''
    return xnat.select.project(PROJECT_ID).subject(SUBJECT_ID).experiment(EXPERIMENT_ID).exists()

def upload_dicom_zipdirectory_to_xnat_using_deech_script(SUBJECT_ID,EXPERIMENT_ID,PROJECT_ID,TARGET_ZIP):
     system_command =  '/home/dgutman/Dropbox/GIT_ROOT/XNAT_PYTHON_SCRIPTS/upload-dicom-zipfile.sh '+PROJECT_ID+" "+SUBJECT_ID+" "+EXPERIMENT_ID+" "+TARGET_ZIP+' \'http://xnat.cci.emory.edu:8080/xnat\' nbia nbia'
     print system_command,"was the system command"
     os.system(system_command)
     return

def create_dicom_directory_zipfile(BASE_DIRECTORY,TARGET_ZIP_FILE_NAME):
     system_command =  '/home/dgutman/Dropbox/GIT_ROOT/XNAT_PYTHON_SCRIPTS/zip_up_a_dicom_dir.pl '+BASE_DIRECTORY+' '+TARGET_ZIP_FILE_NAME+' '
     print system_command,"was the system command"
     os.system(system_command)
     return
#    os.path.exists()   will check if a path exist

                                     
## now that I have the list of patients on my hard drive and the list of patients that are in XNAT
## I can find the ones I need to upload... and upload em

for patients_on_disk in DIRECTORIES_ON_HARD_DRIVE:
    if patients_on_disk not in unique_patient_list_in_xnat:
        print "You need to upload",patients_on_disk
        for individual_directories in subj_dirs:
            if( individual_directories.find(patients_on_disk) != -1): 
                print individual_directories,"needs to be uploaded for",patients_on_disk
		SUBJECT_ID = re.search('Subject(\d{2,5})',individual_directories)
                SUBJECT_ID = SUBJECT_ID.group(1)
                EXPERIMENT_ID=individual_directories
                TARGET_DIRECTORY=ROOT_DIRECTORY_TO_CHECK+individual_directories
		TARGET_ZIP_FILE = TARGET_DIRECTORY+".zip"
		print TARGET_ZIP_FILE," is the target zip file"
		if(os.path.exists(TARGET_ZIP_FILE)):
		    print TARGET_ZIP_FILE+"was already created"
	            upload_dicom_zipdirectory_to_xnat_using_deech_script(SUBJECT_ID,individual_directories,PROJECT_ID,TARGET_ZIP_FILE)
		else:
		    print "Creating",TARGET_ZIP_FILE," right now"
		    create_dicom_directory_zipfile(individual_directories,TARGET_ZIP_FILE)
	            upload_dicom_zipdirectory_to_xnat_using_deech_script(SUBJECT_ID,individual_directories,PROJECT_ID,TARGET_ZIP_FILE)
		
