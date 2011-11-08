'''
Created on October 18, 2011
This program will search a file and determine project and experiment and determine 
if the patient has been uploaded to XNAT


@author: dgutman
'''

import os,glob,re , sys
from pyxnat import Interface


input_file='/home/dgutman/Dropbox/GIT_ROOT/XNAT_PYTHON_SCRIPTS/aleX_list_to_curate.txt'


fp=open(input_file,'r')

for line in fp:
#    print line
    line = line.rstrip("\n\r")
    if not line.split('/')[-1] == 'SCANS':
	#print line.split('/')[-1]," is the last element"	
        print line
    
sys.exit(1)



PROJECT_ID="CIDAR"

def check_xnat_to_see_if_experiment_id_exists(SUBJECT_ID,EXPERIMENT_ID):
    '''This function will query an XNAT server and see if a project exists '''
    return xnat.select.project(PROJECT_ID).subject(SUBJECT_ID).experiment(EXPERIMENT_ID).exists()

def upload_dicom_directory_to_xnat_using_deech_script(SUBJECT_ID,EXPERIMENT_ID,PROJECT_ID,TARGET_DIRECTORY):
     system_command =  '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/SCRIPTS/dg_python_tools/src/upload-dicom-zipfile-to-prearchive.sh '+PROJECT_ID+" "+SUBJECT_ID+" "+EXPERIMENT_ID+" "+TARGET_DIRECTORY+' \'http://xnat.cci.emory.edu:8080/xnat\' nbia nbia'
#    print system_command,"was the system command"
#     os.system('./upload-dicom-zipfile.sh',PROJECT_ID, SUBJECT_ID, EXPERIMENT_ID,TARGET_DIRECTORY,'\'http://xnat.cci.emory.edu:8080/xnat\' nbia nbia')
     os.system(system_command)
     return


# setup the connection
xnat= Interface(server='http://xnat.cci.emory.edu:8080/xnat',
                user='nbia',password='nbia',
                cachedir=os.path.join(os.path.expanduser('~'),'.store'))
 
 
ROOT_DIRECTORY_TO_CHECK = '/MaybergImaging/IMAGING_DATA/CIDAR_2/dicom/'

FILES_IN_DIRECTORY = glob.glob1(ROOT_DIRECTORY_TO_CHECK,"*CIDARCID*")


DIRECTORIES_ON_HARD_DRIVE = []

#print FILES_IN_DIRECTORY

for individual_directories in FILES_IN_DIRECTORY:
    print individual_directories
    patient_id = re.search(r'(CID\d+)_Scan(\d)',individual_directories) 
    only_id = re.search('(CID\d{2,4})',individual_directories)
    if patient_id and patient_id.group(1):
#       print patient_id.group(1)
        DIRECTORIES_ON_HARD_DRIVE.append(only_id.group(1))
    elif patient_id and patient_id.group(2):
#        print patient_id.group(2) 
        DIRECTORIES_ON_HARD_DRIVE.append(only_id.group(1))
    else:
	 print "No tag found for that patient "
        
print len(DIRECTORIES_ON_HARD_DRIVE),"directories had a CIDAR  tag"

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
    for experiment_id in experiments_for_this_subject:
#        print experiment_id
        found_imaging_data=1
        patients_with_imaging_data.append(current_patient)
        
    total_patients_with_imaging_data += found_imaging_data

print "A total of",total_patients_with_imaging_data,"had imaging data in XNAT for the ",PROJECT_ID,"project"
print len(patients_with_imaging_data)," total experiments associated with this data set"
#patients_with_imaging_data =set(patients_with_imaging_data)

unique_patient_list_in_xnat = set(patients_with_imaging_data)
print len(unique_patient_list_in_xnat),"unique patients are in this set"
 

for patients_on_disk in DIRECTORIES_ON_HARD_DRIVE:
    if patients_on_disk not in unique_patient_list_in_xnat:
#        print "You need to upload",patients_on_disk
        for individual_directories in FILES_IN_DIRECTORY:
            if( individual_directories.find(patients_on_disk) != -1): 
                print individual_directories,"needs to be uploaded for",patients_on_disk
		SUBJECT_ID = re.search('(CID\d{2,4})',individual_directories)
                SUBJECT_ID = SUBJECT_ID.group(1)
                EXPERIMENT_ID=individual_directories
                TARGET_DIRECTORY=ROOT_DIRECTORY_TO_CHECK+individual_directories
                upload_dicom_directory_to_xnat_using_deech_script(SUBJECT_ID,individual_directories,PROJECT_ID,TARGET_DIRECTORY)

                                
                                
                                
