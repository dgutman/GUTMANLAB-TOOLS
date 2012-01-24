#!/usr/bin/python
import glob, os, re, sys
import subprocess as sp


#date: 11/17/2011, author:aanghelescu
#this script searches dicom rt masks and converts them to nii files using plastimatch 
#this script is rewritten in python from a perl script
CONVERSION_OUTPUT_DIR = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/PLASTIMATCH_MASK_EXPORT/"

def process_dicom_rt_header_file(input_dicom_rt_file, converted_file_name):

    #print input_dicom_rt_file
    #(0010,0010) PN [226427^]                                #   8, 1 PatientsName
    #(0010,0020) LO [TCGA-06-0162]                           #  12, 1 PatientID
    #(0010,0030) DA (no value available)                     #   0, 0 PatientsBirthDate
    ##(0010,0040) CS (no value available)                     #   0, 0 PatientsSex
    #(0018,1000) LO [0]                                      #   2, 1 DeviceSerialNumber
    ##(0018,1020) LO [2.7.0]                                  #   6, 1 SoftwareVersions
    ##0020,000d) UI [1.3.6.1.4.1.9328.50.45.68017139859310765805049054903251069055] #  62, 1 StudyInstanceUID
    #(0020,000e) UI [1.2.276.0.7230010.3.1.4.1014192915.6324.1312394934.28] #  54, 1 SeriesInstanceUID
    
    found_structure_set = 0

    handle = sp.Popen(['dcmdump', input_dicom_rt_file], stdout=sp.PIPE, stderr=sp.PIPE) 
    stdout, stderr = handle.communicate()
    stdout = stdout.split('\n')
    for each_line in stdout:
        m1 = re.search('\(0008,0060\) CS \[RTSTRUCT\]', each_line)
        if not m1 == None:
            found_structure_set = 1

        m2 = re.search('\(0010,0020\) LO \[(.*)\]', each_line)
        if not m2 == None:
            subject_id = m2.group(1) 
            #print 'subject id should be ' + m2.group(1) 

        m3 = re.search('\(0020,000d\) UI \[(.*)\]', each_line)
        if not m3 == None:
            study_uid = m3.group(1) 
            #print 'study instance UID should be ' + m3.group(1) 

        m4 = re.search('\(0020,000e\) UI \[(.*)\]', each_line)
        if not m4 == None:
            series_uid = m4.group(1) 
            #print 'series instance UID should be ' + m4.group(1) 

    
    if found_structure_set:
        base_dir = os.path.split(input_dicom_rt_file)
        series_uid_dir = base_dir[0] +'/'+ series_uid
        if os.path.exists(series_uid_dir):
            print "Series id output dir exists" 
	     
            command = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/SCRIPTS/plastimatch/build/plm/plastimatch convert --input '+input_dicom_rt_file+' --output-ss-img '+CONVERSION_OUTPUT_DIR+converted_file_name+' --output-ss-list argo_test.txt --fixed '+ series_uid_dir
            print command
	 #   os.system(command)        
	else:
            print "have not exported series id directory or can't find it"
            print  subject_id + ' for ' +each
    else:
        print each + ' is not a valid dicom RT file '



file_types = ['AXIAL_T2_FLAIR','AXIAL_T1_POST_GD']

DICOM_RT_MASK_EXPORT_DIR = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/MASK_EXPORT/'

dcm_rt_file_list = glob.glob(DICOM_RT_MASK_EXPORT_DIR + '*/*/*.dcm')

#print dcm_rt_file_list

for each in dcm_rt_file_list:
    file_name = each.split('/')[-1]
    file_type = each.split('/')[-2]
    subject_id = each.split('/')[-3]
    converted_file_name = subject_id+'-'+file_type+'-'+file_name[:-3]+'nii'
    if file_type in file_types:
        #print subject_id + ' has ' + file_type + ' mask ' + file_name
        print converted_file_name
        process_dicom_rt_header_file(each, converted_file_name)
    else:
        pass
        #print 'no match for '+ each
