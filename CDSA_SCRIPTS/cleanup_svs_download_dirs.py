'''
David A Gutman 
Emory University
January 21, 2012
This very simple script takes an input file that I am using to "pull" whole slide images
which have the format http://some.directory/ which are the locations of the raw SVS files
on the TCGA FTP site
I have at times downloaded both the .tar.gz file as well as the individual files in the directory
At this point.. there's really no reason to keep both... assuming I have all of the files already
untarred... so I am going to walk through my list and first identify the .tar.gz files I have download
'''


import os, glob, re


input_svs_list = 'svs_sites.txt'
root_file_path = '/data2/TCGA_MIRROR/'

f = open(input_svs_list,"r")
totaltarsize = 0
for line in f.readlines():
    line = line[7:]
    line = line.rstrip('\r\n')
    print line
## I need to do two transformations.. one is strip off the CR/LF at the end
## and two is replace the http:// with /data2/TCGA_MIRROR/
    TAR_GZ_LIST_FOR_DIR = glob.glob(root_file_path+line+"*.tar.gz")   
    print TAR_GZ_LIST_FOR_DIR
    print len(TAR_GZ_LIST_FOR_DIR),"files are in the tarball"
    for tarfile in TAR_GZ_LIST_FOR_DIR:
        tarballsize = os.path.getsize(tarfile)
        print tarballsize
        totaltarsize = tarballsize + totaltarsize 
print totaltarsize,"bytes in all the files"
