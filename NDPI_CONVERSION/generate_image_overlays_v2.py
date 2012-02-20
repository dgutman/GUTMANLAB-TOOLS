#!/usr/bin/python
import glob, os, re, sys, string
import subprocess as sp
import nibabel as nib

import MySQLdb as mdb

con = None
try:
    con = mdb.connect('cerebro.cci.emory.edu', 'gliomaview','viewgliomas','GLIOMAVIEW');
    cur = con.cursor()
    cur.execute("SELECT VERSION()")

    data = cur.fetchone()
    
    print "Database version : %s " % data
    
except mdb.Error, e:
  
    print "Error %d: %s" % (e.args[0],e.args[1])
    sys.exit(1)
#finally:    
#    if con:    
#        con.close()
# This script will check an output directory and make overlays so I can do quick QA/QC checks

PLASTIMATCH_MASK_EXPORT_DIR = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/PLASTIMATCH_MASK_EXPORT/'
HTML_EXPORT_BASE_DIR = '/var/www/TUMORVIEW/'


def get_header_information(nifti_file):
    print nifti_file
    img = nib.load(nifti_file)
    img_shape =  img.get_shape()
    img_header = img.get_header()['pixdim'][1:4]
    dimension_string = str(img_shape[0]) + "," + str(img_shape[1]) + "," + str(img_shape[2]) + "," + \
    str(img_header[0]) + "," + str(img_header[2]) + "," + str(img_header[2])
    return dimension_string
#$OUTPUT_DIRECTORY = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/PNG_WEB_DEPOT/";


def make_medcon_stack(maskfile, medcon_output_dir, subject_id):
     print maskfile,medcon_output_dir,subject_id
     medcon_output_dir = HTML_EXPORT_BASE_DIR+subject_id+"/MEDCON/"
### I am going to look for a single image in the medcon directory and assume if it exists, they were all created properly..		
     if not os.path.exists(medcon_output_dir):
		os.makedirs(medcon_output_dir)	
     medcon_base_statement = "medcon -f " + maskfile + " -w -fv -noprefix -o " + medcon_output_dir + subject_id + "_axial -c png "
     print medcon_base_statement
     return



### set up html index page

f_index_ptr = open(HTML_EXPORT_BASE_DIR+'index.html','w')
index_html_header = '''<head>\n\
<title>TCGA Image viewer </title>q
</head>
<body>
<table border=2 align=center>
'''

f_index_ptr.write(index_html_header)
rt_mask_file_list = glob.glob(PLASTIMATCH_MASK_EXPORT_DIR + '*.nii.gz')

for maskfile in rt_mask_file_list:
#	print maskfile
	(dir, file) = os.path.split(maskfile)
#	print "file is",file,"and dir is",dir
	file_name_elements = file[:-7].split('_')
	if len(file_name_elements)==4:
		subject_id=file_name_elements[0]
		scan_type=file_name_elements[1]
		rt_file_name=file_name_elements[2]
		mask_file_name=file_name_elements[3]
		print subject_id,scan_type,rt_file_name,mask_file_name	
	else:
	    print "FILE NAME ERROR FOR ",file	
	background_image = dir+'/BACKGROUNDS/'+subject_id+"_"+scan_type+"_"+rt_file_name+'_BACKGROUND.nii.gz'
	if os.path.exists(background_image):
#	    print "Found background iamge!! woo hoo"
	    pass
	else:
	    print "Can't find",background_image

	mask_dimension_info = get_header_information(maskfile)
	

	html_image_output_dir = HTML_EXPORT_BASE_DIR+subject_id
	output_three_slice_image = html_image_output_dir+'/'+subject_id+"_"+scan_type+"_"+rt_file_name+"_"+mask_file_name+'_masked.png'
	
	if not os.path.exists(output_three_slice_image):
	        command_output = 'fsl4.1-overlay 1 1 '+background_image+' -a '+maskfile+' 0.1 1 /tmp/tmp_image.nii.gz'
        	print command_output
	        os.system(command_output) 
		html_image_output_dir = HTML_EXPORT_BASE_DIR+subject_id
		if not os.path.exists(html_image_output_dir):
		    os.makedirs(html_image_output_dir)	
        	slicer_command = 'fsl4.1-slicer -L /tmp/tmp_image.nii.gz -a '+html_image_output_dir+'/'+subject_id+"_"+scan_type+"_"+\
		rt_file_name+'_'+mask_file_name+'_masked.png'
		os.system(slicer_command)
### I also need code do to the medcon images for visualization as well....	
        medcon_output_dir = HTML_EXPORT_BASE_DIR+subject_id+"/MEDCON/"

	make_medcon_stack(maskfile, medcon_output_dir, subject_id)

###f_index_ptr.write(index_html_header)
#$statement = "medcon -f  $INPUT_NIFTI_IMAGE -w -fv -noprefix -o
#$OUTPUT_JPG_ROOT_DIR" . $UNDERLAY_ID ."_axial -c png "  .
#$ADDL_COMMANDS;
#print "Generating coronal images for $ANALYSIS_KEY_ROOT $UNDERLAY_ID \n";
#$statement = "medcon -f  $INPUT_NIFTI_IMAGE -w -rs  -noprefix -o
#$OUTPUT_JPG_ROOT_DIR" . $UNDERLAY_ID ."_coronal -cor -c png "  .
#$ADDL_COMMANDS;;


	image_string = string.replace(output_three_slice_image,'/var/www/TUMORVIEW/','')
	html_output_string = '<tr><td>'+subject_id+'</td><td>'+scan_type+'</td><td>'+rt_file_name+'</td><td>'+mask_file_name\
	+'</td><td><img src='+image_string+'></td></tr>'
#	print html_output_string
	f_index_ptr.write(html_output_string)
	replace_stmt = "replace  into `GLIOMAVIEW`.`NIFTI_PNG_IMAGE_INFO`  (dim_x,dim_y,dim_z,pix_dim_x,pix_dim_y,pix_dim_z,NIFTI_IMAGE_PATH, \
	PATIENT_ID,IMAGE_TYPE,PNG_BASE_PATH ) Values (" + mask_dimension_info + ",\'" + maskfile  + "\',\'" +subject_id+ \
	"\',\'" + scan_type  + "\',\'" + image_string + "\')"
#	+"','"+masks)"
#,'"+patient_id+"','"+scan_type+"','"+subject_id+"')";
#	print replace_stmt
        cur.execute(replace_stmt)
print len(rt_mask_file_list),"mask files were found.... "


# -a outputs all the midsagital/coronal/etc  otherwise -A 1600 outputs a 1600/1200 image

sys.exit()
'''
print "Generating overlay for $patient_id for mask file $file ... \n";
### NOW LOOK FOR MATCHING OVERLAY FILE...
$TARGET_POST_GD_FILE = $AXIAL_T1_POST_GD_DIR . $patient_id . "_AXIAL-T1-POST-GD_*";
 @matching_files = glob($TARGET_POST_GD_FILE);
if( $#matching_files == 0 ) { print "Target file is $matching_files[0] \n";   

$overlay_command = "overlay 1 1 $matching_files[0] -a $TCGA_MASK 0 1 /tmp/tmp_image.nii.gz";
print $overlay_command . "\n";
`$overlay_command`;
$command = "slicer -L  /tmp/tmp_image.nii.gz -A 1600 ${OUTPUT_DIRECTORY}${patient_id}-axial-postgdimages-with-mask.png ";

$AXIAL_T1_POST_GD_DIR = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/RAW_NIFTI_FILES/AXIAL-T1-POST-GD/";
$OUTPUT_DIRECTORY = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/PNG_WEB_DEPOT/";
#`$statement`;
### NOW LOOK FOR MATCHING OVERLAY FILE...
$TARGET_POST_GD_FILE = $AXIAL_T1_POST_GD_DIR . $patient_id . "_AXIAL-T1-POST-GD_*";
 @matching_files = glob($TARGET_POST_GD_FILE);
if( $#matching_files == 0 ) { print "Target file is $matching_files[0] \n";   

$overlay_command = "overlay 1 1 $matching_files[0] -a $TCGA_MASK 0 1 /tmp/tmp_image.nii.gz";
print $overlay_command . "\n";
`$overlay_command`;
$command = "slicer -L  /tmp/tmp_image.nii.gz -A 1600 ${OUTPUT_DIRECTORY}${patient_id}-axial-postgdimages-with-mask.png ";
print $command;
`$command`;

#$UNDERLAY_IMAGE_DEMO = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/NIFTI_MASKS/POST_GD_MASKS/TCGA-06-0166_POST-GD-MASK_DJ.nii";

##$POST_GD_IMAGE = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/RAW_NIFTI_FILES/AXIAL-T1-POST-GD/TCGA-06-0166_AXIAL-T1-POST-GD_SCANNUM_7.nii.gz ";
$AXIAL_T1_POST_GD_DIR = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/RAW_NIFTI_FILES/AXIAL-T1-POST-GD/";


$OUTPUT_DIRECTORY = "/IMAGING_SCRATCH/TCGA_DICOM_CACHE/DASHBOARD_IMAGES/";
@TCGA_MASKS_ON_POST_GD_LIST = glob("/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/NIFTI_FILES/NIFTI_MASKS/POST_GD_MASKS/TCGA*POST-GD-MASK*.nii.gz");

### I need to figure out the correspond mask for this patient... eventually this will all be done in a database... but for now I can just use regex
print $TCGA_MASK;

### NOW LOOK FOR MATCHING OVERLAY FILE...
$TARGET_POST_GD_FILE = $AXIAL_T1_POST_GD_DIR . $patient_id . "_AXIAL-T1-POST-GD_*";
 @matching_files = glob($TARGET_POST_GD_FILE);
if( $#matching_files == 0 ) { print "Target file is $matching_files[0] \n";   

$overlay_command = "overlay 1 1 $matching_files[0] -a $TCGA_MASK 0 1 /tmp/tmp_image.nii.gz";
print $overlay_command . "\n";
$command = "slicer -L  /tmp/tmp_image.nii.gz -A 1600 ${OUTPUT_DIRECTORY}${patient_id}-axial-postgdimages-with-mask.png ";

exit;
'''
