#!/usr/bin/env python

import os
import sys
import optparse
import re

DEFAULT_SVS_DIR = '/data/dgutman/RAW_SLIDE_LINKS'
DEFAULT_PYRAMID_DIR = '/data3/PYRAMIDS/CDSA'
DEFAULT_JPEG_DIR = '/data3/JPEG_CACHE/CDSA'

_verbose = 0

def _listdir_error(error):
	print >>sys.stderr, "Could not traverse/list:", error.filename

def _missing_jpeg(path):
	print "Missing thumbnail:", path

def _missing_pyramid(path):
	print "Missing pyramid:", path

def check_files(svs_dir=DEFAULT_SVS_DIR, pyramid_dir=DEFAULT_PYRAMID_DIR, jpeg_dir=DEFAULT_JPEG_DIR, 
		missing_jpeg=None, missing_pyramid=None):
	"""Checks for slide images and whether pyramid and/or thumbnail files have been created.
		
		Arguments:
		svs_dir -- The base directory to (recursively) search for .svs images.
		pyramid_dir -- The base directory for pyramid images.
		jpeg_dir -- The base directory for JPEG thumbnails.
		missing_jpeg -- Optional callback for missing thumbnails.  Will be called with the full path.  Default is to print to stderr.
		missing_pyramid -- Optional callback for missing pyramid images.  Will be called with the full path.  Default is to print to stderr.

		Returns: counts of found images: (svs, pyramid, jpeg)
	"""

	# sanity checks
	if not os.path.isdir(svs_dir): 
		raise IOError('SVS path is not a directory or is unreadable: ' + str(svs_dir))
	if not os.path.isdir(pyramid_dir): 
		raise IOError('Pyramid path is not a directory or is unreadable: ' + str(pyramid_dir))
	if not os.path.isdir(jpeg_dir):
		raise IOError('JPEG path is not a directory or is unreadable: ' + str(jpeg_dir))

	# get rid of any trailing slashes
	svs_dir = svs_dir.rstrip('/')
	pyramid_dir = pyramid_dir.rstrip('/')
	jpeg_dir = jpeg_dir.rstrip('/')

	# arg handling
	v = _verbose >= 1; vv = _verbose >= 2
	if not callable(missing_jpeg): missing_jpeg = _missing_jpeg
	if not callable(missing_pyramid): missing_pyramid = _missing_pyramid

	svs_prefix_len = len(svs_dir) + 1 # plus 1 for leading '/'
	svs_pat = re.compile(r'.*\.svs$', re.IGNORECASE)
	svs_count = pyramid_count = jpeg_count = 0

	# crawl looking for svs files
	for dirpath, dirnames, filenames in os.walk(svs_dir, followlinks=True, onerror=_listdir_error):
		for fname in filenames:
			# SVS (slide) file?
			if svs_pat.match(fname):
				svs_count += 1
				if v: print >>sys.stderr, "Slide: ", os.path.join(dirpath, fname)

				path_suffix = dirpath[svs_prefix_len:]

				# check for pyramid
				pyramid_name = fname + '.dzi.tif'
				pyramid_path = os.path.join(pyramid_dir, path_suffix, pyramid_name)
				if os.path.isfile(pyramid_path):
					pyramid_count += 1
					if vv: print >>sys.stderr, "Found pyramid:", pyramid_path
				else:
					missing_pyramid(pyramid_path)
				
				# check for jpeg thumbnail
				jpeg_name = pyramid_name + '.thumb.jpg'
				jpeg_path = os.path.join(jpeg_dir, path_suffix, jpeg_name)
				if os.path.isfile(jpeg_path):
					jpeg_count += 1
					if vv: print >>sys.stderr, "Found thumbnail:", jpeg_path
				else:
					missing_jpeg(jpeg_path)

	return (svs_count, pyramid_count, jpeg_count)

def _parser():
	"""Returns the option parser for this program."""
	p = optparse.OptionParser('Usage: %prog [options]')
	p.add_option('-s', '--svs-dir', dest='svs_dir', default=DEFAULT_SVS_DIR, metavar='DIR', 
		help='Look for SVS files in DIR')
	p.add_option('-p', '--pyramid-dir', dest='pyramid_dir', default=DEFAULT_PYRAMID_DIR, metavar='DIR',
		help='Look for pyramid files in DIR')
	p.add_option('-j', '--jpeg-dir', '--jpg-dir', dest='jpeg_dir', default=DEFAULT_JPEG_DIR, metavar='DIR',
		help='Look for JPEG thumbnails in DIR')
	p.add_option('-v', '--verbose', dest='verbose', action='count', default=0,
		help='Increase verbosity.')
	return p

def main(args=None):
	if args is None: args = sys.argv[1:]
	parser = _parser()
	opts, args = parser.parse_args(args)

	global _verbose; _verbose = opts.verbose

	svs_count, pyramid_count, jpeg_count =	\
		check_files(svs_dir=opts.svs_dir, pyramid_dir=opts.pyramid_dir, jpeg_dir=opts.jpeg_dir)

	print "SVS slides:", svs_count
	print "  Pyramids:", pyramid_count
	print "Thumbnails:", jpeg_count

if __name__ == '__main__':
	main()
