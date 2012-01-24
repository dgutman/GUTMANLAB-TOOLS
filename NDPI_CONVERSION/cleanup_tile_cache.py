''' 
Created on 1/12/2012
This is a simple python script to basically find "bigtiff" converted images and clean up a
tile cache directory I created...
'''
import os,glob,re , sys
import subprocess as sp



TILE_CACHE_DIR = '/home/dgutman/TILE_CACHE/'
BIG_TIFF_OUTPUT_DIR = '/var/www/ADRC/BIG_TIFF_IMAGES/'
rootdir = TILE_CACHE_DIR


TILED_FILES  = [ f for f in glob.glob1(rootdir, '*') if os.path.isdir(os.path.join(rootdir, f)) ]
#print subj_dirs
print len(TILED_FILES)," are tiled ..."

for tiledir in TILED_FILES:
    print tiledir,
    CONVERTED_TIFF=BIG_TIFF_OUTPUT_DIR+tiledir+'.tif'
    print CONVERTED_TIFF
    if os.path.isfile(CONVERTED_TIFF):
	print "Big tiff file at least exists... now checking for valid big tiff file "
	proc = sp.Popen(('tiffinfo', CONVERTED_TIFF), stdout=sp.PIPE, stderr=sp.PIPE)
	stdout, stderr = proc.communicate()
#	print stdout
	for line in stdout.splitlines():
	    if 'Image Width' in line:
	       theline = line
	       print theline
	       break
    else:
	  print "File was not convetred to tiff... don't nuke it!!"



pyramid_root_dir = '/var/www/ADRC/ZOOMIFY_FULL_PYRAMIDS/TRAINING_SLIDES/'
spillover_root_dir = '/TRAUMA_RAID6/ADRC/TRAININGBATCH1/'


PYRAMID_FILES  = [ f for f in glob.glob1(pyramid_root_dir, '*.dzi.tif') if os.path.isfile(os.path.join(pyramid_root_dir, f)) ]
#print subj_dirs
print len(PYRAMID_FILES)," are pyramid files in the base directory ..."

for pyramidfile in PYRAMID_FILES:
    dup_file =  spillover_root_dir+pyramidfile
    print dup_file
    if os.path.isfile(dup_file):
	print pyramidfile+"exists in 2 places!!!"


