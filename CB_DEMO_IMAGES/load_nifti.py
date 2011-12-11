#!/usr/bin/env python

import sys, os
import MySQLdb as db
import nibabel, numpy, optparse
from nibabel import nifti1
import itertools as it

def get_seed_id(project_group, experiment_group, roi_desc, image_path=None, conn=None):
	"""Gets the seed id for a Region of Interest (ROI)

	@param project_group the project group
	@param experiment_group the experiment group
	@param roi_desc a description string for the ROI
	@param image_path the path to the NIFTI file, optional if the seed exists
	@param conn the database connection or None to open and close one locally
	"""
	local_conn = conn is None
	if local_conn:
		conn = _connect()
	try:
		curr = conn.cursor()

		# get current if available
		query = 'SELECT predef_roi_seed_id FROM predef_roi_image_info WHERE ' \
			'project_group=%s AND experiment_group=%s AND roi_description=%s'
		result = curr.execute(query, (project_group, experiment_group, roi_desc))
		if result > 0:
			seed_id = curr.fetchone()[0]
			# update if path has changed
			if image_path:
				query = 'UPDATE predef_roi_image_info SET nifti_image_path=%s WHERE predef_roi_seed_id=%s'
				curr.execute(query, (image_path, seed_id))
			return seed_id

		# otherwise, initial insert
		query = 'INSERT INTO predef_roi_image_info SET project_group=%s, ' \
			'experiment_group=%s, roi_description=%s, nifti_image_path=%s'
		result = curr.execute(query, (project_group, experiment_group, roi_desc, image_path))
		seed_id = curr.lastrowid
		curr.close()
		return seed_id
	finally:
		if local_conn: conn.close()

def process_file(seed_id, nifti_path, conn=None, threshold=0.5, insert_chunks=500, table='predef_roi_raw_data_table'):
	"""Processes a NIFTI file and loads the voxel data into the database.

	@param seed_id: the seed id for this image
	@param nifti_path: the path to the file
	@param conn: a database connection to use, if None a local connection will be opened and closed
	@param threshold: omit voxels below this threshold
	@param insert_chunks: number of records to insert at a time
	@param table: the table to insert into
	"""
	if not os.path.isfile(nifti_path):
		raise Exception('Path does not name a file: ' + nifti_path)
	local_conn = conn is None
	if local_conn:
		conn = _connect()

	try:
		# load the image and get voxels of interest
		img = nifti1.load(nifti_path)
		data = img.get_data()
		coords = numpy.transpose((data > threshold).nonzero())

		# remove old data
		cur = conn.cursor()
		cur.execute('DELETE FROM `' + table + '` WHERE predef_roi_seed_id=%s', (seed_id,))

		insert = 'INSERT DELAYED INTO `' + table + '` (predef_roi_seed_id, x_loc, y_loc, z_loc, intensity) ' \
			'VALUES (%s, %s, %s, %s, %s)'

		# multi-insert in groups of insert_chunks (or remaining in last set)
		db_val_gen = ((seed_id, x, y, z, data[z,y,x]) for z, y, x in coords)
		for vals in _grouper(insert_chunks, db_val_gen):
			if vals[-1] is None:
				vals = filter(bool, vals) # remove None-s from the last group
			cur.executemany(insert, vals)
	finally:
		if local_conn:
			conn.close()

def _connect():
	"""FIXME: Take params by argument or file and delete this..."""
	return db.connect(host='trauma-computernode1.psychiatry.emory.edu', user='brainuser', passwd='z0mbiez!', db='computable_brain')

# from docs.python.org/library/itertools.html recipe
def _grouper(n, iterable, fillvalue=None):
	"grouper(3, 'ABCDEFG', 'x') --> ABC DEF Gxx"
	args = [iter(iterable)] * n
	return it.izip_longest(fillvalue=fillvalue, *args)
	
def main(args=None):
	if args is None: args = sys.argv[1:]
	parser = _parser()
	opts, args = parser.parse_args(args)

	# sanity checks
	if not args:
		parser.error("Need a NIFTI file or directory.")
	if opts.threshold < 0.0:
		parser.error("Threshold cannot be negative, got: " + str(opts.threshold))
	if opts.insert_chunks < 1:
		parser.error("Insert chunks must be a positive integer, got: " + str(opts.insert_chunks))

	# values to reuse in the loop
	ext = '.nii.gz'; ext_len = len(ext)
	proj = opts.project_group; expr = opts.experiment_group
	threshold = opts.threshold; chunks = opts.insert_chunks
	table = opts.table
	realpath = os.path.realpath; basename=os.path.basename

	loaded = 0
	conn = _connect()
	with conn:
		for arg in args:
			if os.path.isfile(arg):
				files = [arg]
			elif os.path.isdir(arg):
				files = [ x for x in os.listdir(arg) if x.lower().endswith(ext) ]
				if not files:
					print >>sys.stderr, "WARN: No", ext, "files in", arg
					continue
			else:
				print >>sys.stderr, "WARN: Not a file, directory, or is unreadable:", arg
				continue

			# process the files
			for nifti_file in files:
				roi_desc = basename(nifti_file)[:-ext_len]
				seed_id = get_seed_id(proj, expr, roi_desc, image_path=realpath(nifti_file), conn=conn)
				process_file(seed_id, nifti_file, conn=conn, threshold=threshold, insert_chunks=chunks)
				loaded += 1

	print "Done, loaded", loaded, "NIFTI images."
	return 0

def _parser():
	"""Creates and returns the option parser"""
	parser = optparse.OptionParser(usage='%prog [OPTIONS] DIR_OR_FILE [DIR_OR_FILE2 ...]')
	parser.add_option('-p', '--project', action='store', type='string',
		dest='project_group', default='DGUTMAN', help='Sets the project group used for the seed id')
	parser.add_option('-e', '--experiment', action='store', type='string',
		dest='experiment_group', default='DG_NEW_PROTOCOL', help='Sets the experiment group used for the seed id')
	parser.add_option('-t', '--threshold', action='store', type='float',
		dest='threshold', default=0.5, help='Only insert voxels with intensity above threshold')
	parser.add_option('-c', '--insert-chunks', action='store', type='int',
		dest='insert_chunks', default=500, help='Insert this number of records into the database at a time.')
	parser.add_option('-b', '--table', action='store',
		dest='table', default='predef_roi_raw_data_table', help='Insert into TABLE [default: predef_roi_raw_data_table]')
	return parser

if __name__ == '__main__':
	result = main()
