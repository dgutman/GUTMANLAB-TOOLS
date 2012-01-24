'''
Created on December 12, 2011
This program will search for all resources and files for the GTP project and make sure I have
all of the data I need for a TBS or VBM analysis

@author: dgutman, aanghel
'''
import os,glob,re , sys, json, urllib, csv
from pyxnat import Interface
import shutil

## so in theory I should be able to pull the scan param I want directly
## but for some reason it's not working so I am going to use the JSON hack I got working a while ago
#search_url = 'http://gtp:gtp@xnat.cci.emory.edu:8080/xnat/REST/search/saved/xs1324168448566/results?format=json&'
search_url =  'http://gtp:gtp@xnat.cci.emory.edu:8080/xnat/REST/search/saved/xs1324168448566/results?format=json&'

search_url = 'http://admin:admin@xnat.cci.emory.edu:8080/xnat/REST/search/saved/xs1325714208248/results?format=json&'

PROJECT_ID="GTP_PROD"

### this sets up the json object to queyr my xnat instance to get the current subject data I need..
result = json.load(urllib.urlopen(search_url))
inner = result['ResultSet']['Result']
#first_entry= result['ResultSet']['Result'][0]
#print first_entry.keys(),"are available keys for this data set...."


GENOTYPE_DATA = {}

### this is the key I need to get
###xnat_subjectdata_field_map_fkbp5_rs1360780


for current_subject_info in inner:
#    print current_subject_info
#   pss_ptsd_dx = current_subject_info['xnat_subjectdata_field_map_pss_based_ptsd_diagnosis']
    genotype = current_subject_info['xnat_subjectdata_field_map_fkbp5_rs1360780']
    current_subject_label = current_subject_info['subject_label']
    if(   genotype == 'CC'):
	print "RESILIENT"
        GENOTYPE_DATA[current_subject_label]='RESILIENT'
    elif( genotype == 'CT' or genotype =='TT' or genotype == 'RISK' ):
	print "RISK"
	GENOTYPE_DATA[current_subject_label]='RISK'
    print genotype," for subject",current_subject_label," i hope the genotype isn't blank"

       
# setup the connection to XNAT and look and see which patients have field of interest
xnat= Interface(server='http://xnat.cci.emory.edu:8080/xnat',
                user='nbia',password='nbia',
                cachedir=os.path.join(os.path.expanduser('~'),'.store'))
 

project_object  = xnat.select.project(PROJECT_ID)

subject_list = project_object.subjects().get()
print len(subject_list)," patients are in XNAT currently..."

subject_label_list = []
subject_ignore_list = [ '9184', '7293','7591', '935' ]



negar_patient_list = [ '6753', '6824', '7373', '7464', '7470', '7618', '7810', '8155', '8178', '8382', '8383', '8453', '8489', '8496', '8518', \
      '8798', '8883' ,'8897', '9035', '9083', '9176', '9185', '9215', '9264', '9292', '9470', '6610', '7555', '7806', '8543', '8595', '8857', \
      '8871', '8940', '9005', '9251' ]


## 8798 was removed as well
## 8940

print len(negar_patient_list),"patients are in negars list... \n"

ROOT_DIRECTORY_TO_CHECK = '/IMAGING_SCRATCH/RESSLER_TRAUMA_IMAGING/'
T1_IMAGE_LIST = glob.glob(ROOT_DIRECTORY_TO_CHECK+"RESIL*/structural_data/T1_flipped.nii.gz")

MANUAL_BET_IMAGE_LIST = glob.glob("/var/www/RESSLER_IMAGING/BET_DATA/BET/*-T1_flipped_bet.nii.gz")

subjects_with_T1_MPRAGE = []
for individual_image in T1_IMAGE_LIST:
    patient_id = re.search(r'Subject_+(\d{2,5})',individual_image)
#   print individual_image,"for",patient_id.group(1)
    subjects_with_T1_MPRAGE.append(patient_id.group(1))

subject_BET_dict_list = {}

subjects_with_BET_IMAGE = []
for individual_image in MANUAL_BET_IMAGE_LIST:
    patient_id = re.search(r'(\d{2,5})-T1_flipped',individual_image)
#   print individual_image,"for",patient_id.group(1)
    subjects_with_BET_IMAGE.append(patient_id.group(1))
    subject_BET_dict_list[patient_id.group(1)]=individual_image


print len(subjects_with_T1_MPRAGE),"subjects had T1 images in processing directory"
print len(subjects_with_BET_IMAGE),"subjects had a manual BET Image in processing directory"


VBM_OUTPUT_DIRECTORY = '/data/dgutman/RESSLER_TRAUMA_IMAGING/DATA_ANALYSIS/nfani_vbm_35subjs/'

if not os.path.exists(VBM_OUTPUT_DIRECTORY):
    os.system("mkdir "+VBM_OUTPUT_DIRECTORY)
### must also make a /struc subdirectory for the VBM pipeline
if not os.path.exists(VBM_OUTPUT_DIRECTORY+"/struc"):
    os.system("mkdir "+VBM_OUTPUT_DIRECTORY+"/struc")




for subject in subject_list:
    subject_label =  project_object.subject(subject).attrs.get('label')
    if(subject_label not in subject_ignore_list and subject_label in negar_patient_list):
#        subject_label_list.append(subject_label) 
## I have the subject and subject_label object...
         print  GENOTYPE_DATA[subject_label],"is the group status for subject labeled as",subject_label        
         print "Should be copying the following file:"+subject_BET_dict_list[subject_label]+"to the vbm directory"
         if(GENOTYPE_DATA[subject_label] == 'RISK'):
	     group_label="RISK"
         elif(GENOTYPE_DATA[subject_label] == 'RESILIENT'):
	     group_label="RESILIENT"
         else:
	     print "No group label found!!!!! fix this for!!"+subject_label
	     continue
	 output_file_name = group_label+"-"+subject_label+"_struc.nii.gz"
	 bet_output_file_name = "struc/"+group_label+"-"+subject_label+"_struc_brain.nii.gz"
	 output_file_name_copy = "struc/"+group_label+"-"+subject_label+"_struc.nii.gz"


	 print VBM_OUTPUT_DIRECTORY+output_file_name
         shutil.copy2(subject_BET_dict_list[subject_label],VBM_OUTPUT_DIRECTORY+output_file_name)
	 shutil.copy2(subject_BET_dict_list[subject_label],VBM_OUTPUT_DIRECTORY+bet_output_file_name)
	 shutil.copy2(subject_BET_dict_list[subject_label],VBM_OUTPUT_DIRECTORY+output_file_name_copy)


sys.exit()

### 
#$statement = " cp T1_flipped.nii.gz " . $VBM_OUTPUT_DIRECTORY  . $GROUP_ID_TAG . "-$2" . ".nii.gz";
#$statement = " cp  T1_flipped.nii.gz " . $VBM_OUTPUT_DIRECTORY ."struc/" . $GROUP_ID_TAG . "-$2" . "_struc.nii.gz";

### ALSO COPY THE BRAIN EXTRACTED IMAGES.... THESE WILL BE RECREAETED IF A structural_data/manual_bet/T1_flipped_bet_mask.nii.gz image exists......

## THIS WILL APPLY FSLMATHS TO THE BET IMAGE AND THEN THE OUTPUT GOES INTO THE FSLVBM DIRECTORY
#$statement = "fslmaths $CURRENT_DIRECTORY". "/structural_data/T1_flipped.nii.gz " . " -mas $CURRENT_DIRECTORY". "/structural_data/manual_bet/T1_flipped_bet_mask.nii.gz " .  $VBM_OUTPUT_DIRECTORY  . "struc/" . $GROUP_ID_TAG . "-$2" . "_struc_brain.nii.gz";nii.gz " .  $VBM_OUTPUT_DIRECTORY  . "struc/" . $GROUP_ID_TAG . "-$2" . "_struc_brain.nii.gz";

## pss_based_ptsd_diagnosis  THIS DOES NOT WORK FOR A QUERY... MUST BE A BUG
selection_field_id = 'xnat:subjectData/fields/field[name=pss_based_ptsd_diagnosis_total]/field'

## there are some patients where the data is corrupted and/or patient wasn't scanned but a dir exists.


#####################3 going to convert the subject_list which has the URI into labels


sys.exit()

