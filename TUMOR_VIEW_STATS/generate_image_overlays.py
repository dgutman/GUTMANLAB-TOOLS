#!/usr/bin/python
import glob, os, re, sys, string
import subprocess as sp
import nibabel as nib
import MySQLdb as mdb



#I cerated a pruned directory where I start removing problematics/blank files..
#PLASTIMATCH_MASK_EXPORT_DIR = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/PLASTIMATCH_MASK_EXPORT/'
PLASTIMATCH_MASK_EXPORT_DIR = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/TCGA_DATA/PLASTIMATCH_MASK_EXPORT/'
HTML_EXPORT_BASE_DIR = '/var/www/TUMORVIEW/'


## for now I am not going to do the subtraction-- I am going to use the "raw" tumor and try and segment that...
# this holds the segemtntaiton results of the TUMOR_ONLY volume from the post-GD image...
SEG_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/WORKING_FILES/TUMOR_VOLUMES/SEGMENTED_VOLUMES/'

### this contains the TUMOR VOLUME MASK... which is basically the input postGD image masked to only include the area containg tumor volume
TUMOR_VOL_PATH = '/IMAGING_SCRATCH/TCGA_DICOM_CACHE/WORKING_FILES/TUMOR_VOLUMES/'

### Establish MYSQL CONNECTION

con = None
try:
    con = mdb.connect('cerebro.cci.emory.edu', 'gliomaview','viewgliomas','GLIOMAVIEW');
    cur = con.cursor()
    cur.execute("SELECT VERSION()")
    data = cur.fetchone()
    print "Database version : %s " % data
    
except mdb.Error, e:
      print "Error %d: %s" % (e.args[0],e.args[1])


# This script will check an output directory and make overlays so I can do quick QA/QC checks

def do_segmentation_of_post_gd_image(post_gd_nifti_file,post_gd_mask):
	TUMOR_VOL_FILE = TUMOR_VOL_PATH + patient_id+'_TUMOR-VOL_'+ author +'.nii.gz'
       
        if not os.path.exists(TUMOR_VOL_FILE):
            #apply mask and get the tumor volume 
            os.system('fslmaths ' + subtracted_T1[0] +' -mas ' + MASK_PATH + patient_id + '_POST-GD-MASK_'+author+'.nii.gz '+ TUMOR_VOL_FILE)
       
        if (not os.path.exists(SEG_PATH + patient_id +'_TUMOR-VOL_'+ author +'_pve_0.nii.gz')) and os.path.exists(TUMOR_VOL_FILE):
            #run fast on the tumor volume
            os.system('fast -n 2 -t 2 ' + TUMOR_VOL_FILE)
            os.system('mv '+ TUMOR_VOL_PATH + patient_id + '_TUMOR-VOL_' + author + '_* '+ SEG_PATH) 
        
        # use fslstats to get the volume info for ROI 
        # white region vol is accurate - fast will output it as class 0 (pve_0)
        # dark region vol = whole_tumor - white_reg (pve_1 from fast is not accurate due to artifacts
        ## generated from subtracting the T1 images)
        print patient_id, ' (mask author - ', author ,') :'
        #os.system('fslstats ' + subtracted_T1[0] +' -k '+ MASK_PATH + patient_id + '_POST-GD-MASK_'+ author +'.nii.gz -v | awk \'{ print " vol of tumor is ", $2  }\'' ) 
	#os.system('fslstats ' + subtracted_T1[0] +' -k '+ SEG_PATH + patient_id + '_TUMOR-VOL_'+ author +'_pve_0.nii.gz -v | awk \'{ print " vol of bright region is  ", $2  }\'' )
        handle = sp.Popen(['fslstats', subtracted_T1[0], '-k', MASK_PATH + patient_id + '_POST-GD-MASK_'+ author +'.nii.gz', '-v'], stdout=sp.PIPE, stderr=sp.PIPE)
	stdout, stderr = handle.communicate()
        vol = stdout.split(' ')[1]
        handle = sp.Popen(['fslstats', subtracted_T1[0], '-k', SEG_PATH + patient_id + '_TUMOR-VOL_'+ author +'_pve_0.nii.gz', '-v'], stdout=sp.PIPE, stderr=sp.PIPE)
	stdout, stderr = handle.communicate()
        bright_vol = stdout.split(' ')[1]









def get_header_information(nifti_file):
    print nifti_file
    img = nib.load(nifti_file)
    img_shape =  img.get_shape()
    img_header = img.get_header()['pixdim'][1:4]
    dimension_string = str(img_shape[0]) + "," + str(img_shape[1]) + "," + str(img_shape[2]) + "," + \
    str(img_header[0]) + "," + str(img_header[2]) + "," + str(img_header[2])
    return dimension_string


def make_medcon_stack(maskfile, mask_full_base_name, subject_id ):
     medcon_output_dir = HTML_EXPORT_BASE_DIR+subject_id+"/MEDCON/"
     print maskfile,medcon_output_dir,subject_id
### I am going to look for a single image in the medcon directory and assume if it exists, they were all created properly..		
     if not os.path.exists(medcon_output_dir):
		os.makedirs(medcon_output_dir)	
     medcon_base_statement = "medcon -f " + maskfile + " -w -fv -noprefix -o " + medcon_output_dir + mask_full_base_name + "_axial -c png "
     os.system(medcon_base_statement)	
     print medcon_base_statement

     medcon_base_statement = "medcon -f " + maskfile + " -w -rs -noprefix -o " + medcon_output_dir + mask_full_base_name + "_coronal -cor -c png "
     os.system(medcon_base_statement)	

     medcon_base_statement = "medcon -f " + maskfile + " -w -fv -noprefix -o " + medcon_output_dir + mask_full_base_name + "_sagittal -sag -c png "
     os.system(medcon_base_statement)	

     return

def get_masks_statistics(nifti_mask_name):
	print nifti_mask_name	
	handle = sp.Popen(['fsl4.1-fslstats', nifti_mask_name, '-V'], stdout=sp.PIPE, stderr=sp.PIPE)
	stdout, stderr = handle.communicate()
	mask_volume_mm = stdout.split(' ')[1]
	mask_volume_pixels = stdout.split(' ')[0]
			
	print 'Mask volume in mm is',mask_volume_mm
	print 'Mask volume in pixels is',mask_volume_pixels
        
        return mask_volume_mm, mask_volume_pixels

#handle = sp.Popen(['fslstats', subtracted_T1[0], '-k', SEG_PATH + patient_id + '_TUMOR-VOL_'+ author +'_pve_0.nii.gz', '-v'], stdout=sp.PIPE, stderr=sp.PIPE)
#	stdout, stderr = handle.communicate()
#        bright_vol = stdout.split(' ')[1]#
#
#        print 'Volume of the tumor is ', vol
#        print 'Bright region vol: ', bright_vol
#        print 'Dark region vol: ', float(vol) - float(bright_vol), '\n' 



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
	print maskfile
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

	background_file_base_name = subject_id+"_"+scan_type+"_"+rt_file_name+'_'+"background"
	make_medcon_stack(background_image, background_file_base_name, subject_id)

	

	html_image_output_dir = HTML_EXPORT_BASE_DIR+subject_id
	output_three_slice_image = html_image_output_dir+'/'+subject_id+"_"+scan_type+"_"+rt_file_name+"_"+mask_file_name+'_masked.png'
	mask_volume = full_mask_file_base_name = subject_id+"_"+scan_type+"_"+rt_file_name+'_'+mask_file_name
        print "Three slice image should be....",output_three_slice_image
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
### I also need code do to the medcon images for visualization as well

	make_medcon_stack(maskfile, full_mask_file_base_name, subject_id)
	sys.exit()
	mask_dimension_info = get_header_information(maskfile)
	mask_info = get_masks_statistics(maskfile)


	image_string = string.replace(output_three_slice_image,'/var/www/TUMORVIEW/','')
	html_output_string = '<tr><td>'+subject_id+'</td><td>'+scan_type+'</td><td>'+rt_file_name+'</td><td>'+mask_file_name\
	+'</td><td><img src='+image_string+'></td><td>'+mask_volume+'</td></tr>'
#	print html_output_string
	f_index_ptr.write(html_output_string)
	replace_stmt = "replace  into `GLIOMAVIEW`.`NIFTI_PNG_IMAGE_INFO`  (dim_x,dim_y,dim_z,pix_dim_x,pix_dim_y,pix_dim_z,NIFTI_IMAGE_PATH, \
	PATIENT_ID,IMAGE_TYPE,PNG_BASE_PATH, mask_volume_pixels,mask_volume_mm ) Values (" + mask_dimension_info + ",\'" + maskfile  + "\',\'" +subject_id+ \
	"\',\'" + scan_type  + "\',\'" + image_string + "\',\'" + mask_info[0] + "\',\'" + mask_info[1] + "\')"
        cur.execute(replace_stmt)


print len(rt_mask_file_list),"mask files were found.... "



#	stdout, stderr = handle.communicate()
#        bright_vol = stdout.split(' ')[1]#
#        print 'Volume of the tumor is ', vol
#        print 'Bright region vol: ', bright_vol
#        print 'Dark region vol: ', float(vol) - float(bright_vol), '\n' 

# -a outputs all the midsagital/coronal/etc  otherwise -A 1600 outputs a 1600/1200 image

sys.exit()
'''
print "Generating overlay for $patient_id for mask file $file ... \n";
### NOW LOOK FOR MATCHING OVERLAY FILE...
$TARGET_POST_GD_FILE = $AXIAL_T1_POST_GD_DIR . $patient_id . "_AXIAL-T1-POST-GD_*";
 @matching_files = glob($TARGET_POST_GD_FILE);
if( $#matching_files == 0 ) { print "Target file is $matching_files[0] \n";   

$overlay_command = "overlay 1 1 $matching_files[0] -a $TCGA_MASK 0 1 /tmp/tmp_image.nii.gz";
$command = "slicer -L  /tmp/tmp_image.nii.gz -A 1600 ${OUTPUT_DIRECTORY}${patient_id}-axial-postgdimages-with-mask.png ";

exit;
'''
