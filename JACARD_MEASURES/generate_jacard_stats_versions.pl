#!/usr/bin/perl


$BASE_IMAGE[0]= 'composite_image_thrP.000001_s1.nii';
$BASE_IMAGE[1]= 'composite_image_thrP0.0001_s0.5.nii';
$BASE_IMAGE[2] = 'composite_image_thrP.1_s1.nii';

$p_value_image = 'pval_image_masked_for_brain_only.nii';


foreach $BASE ( @BASE_IMAGE)
  {
  print $BASE . "\n";
  `fslmaths $BASE -thr 7 -bin filename1`;

  `fslmaths $p_value_image -thr 0.95 -bin filename2` ;
   `gunzip -f filename1.nii.gz`;
    `gunzip -f filename2.nii.gz`;
  $matlab_statement =  "matlab -nodesktop -nosplash -r \"filename1=\'filename1.nii\';filename2=\'filename2.nii\';JaccardIndex(filename1,filename2);exit;\"";
  print $matlab_statement . "\n";

@jacard_value =   `$matlab_statement`;

print $jacard_value[($#jacard_value-2)];
  

  }
