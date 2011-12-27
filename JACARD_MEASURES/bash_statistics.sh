SINGLE_HEMI_MASK='single_hemisphere_mask.nii.gz'
OTHER_HEMI_MASK='other_hemisphere_mask.nii.gz'
echo  -n "$SINGLE_HEMI_MASK; has the following number of voxels;"
fslstats $SINGLE_HEMI_MASK -V | awk '{print $1}'

echo -n "$OTHER_HEMI_MASK; for the OTHER has the following number of voxels--- this is the one I am acutally interested in";
fslstats $OTHER_HEMI_MASK -V | awk '{print $1}'



for i in 0.95 0.99 0.995 0.999 0.9999
do
echo -n "Total # of voxels surviving threshold;"
fslstats pval_image_masked_for_brain_only.nii -l $i   -V | awk '{print $1 }'


echo "Right  hemisphere count:;"
fslstats pval_image_masked_for_brain_only.nii -l $i -k $SINGLE_HEMI_MASK  -V | awk '{print $1 }'

echo "LEFT  hemisphere count:;"
fslstats pval_image_masked_for_brain_only.nii -l $i -k $OTHER_HEMI_MASK  -V | awk '{print $1 }'


#echo -n "MEMRI Reference image p val is: ;$i; and only counting right hemisphere images  ;"
#fslstats pval_image_masked_for_brain_only.nii -l $i  -k $SINGLE_HEMI_MASK -V | awk '{print $1 }'
#echo -n "MEMRI Reference image p val is: ;$i; and only counting left  hemisphere images  ;"
#fslstats pval_image_masked_for_brain_only.nii -l $i  -k $OTHER_HEMI_MASK -V | awk '{print $1 }'


for k in ob_tractography_binned_5.9_of_10.nii.gz ob_tractography_binned_6.9_of_10.nii.gz ob_tractography_binned_7.9_of_10.nii.gz ob_tractography_binned_8.9_of_10.nii.gz
do
 echo -n "MEMRI Reference image p val is:;$i;and using;$k; as the base ;"
fslstats pval_image_masked_for_brain_only.nii -l $i -k $k  -V | awk '{print $1 }'

echo -n "MEMRI Reference image p val is: ;$i; and using ;$k; as the base and masking the RIGHT hemisphere ;"

fslstats pval_image_masked_for_brain_only.nii -l $i  -k $SINGLE_HEMI_MASK -k $k -V | awk '{print $1 }'

echo -n "MEMRI Reference image p val is: ;$i; and using ;$k; as the base and masking the LEFT  hemisphere ;"
fslstats pval_image_masked_for_brain_only.nii -l $i  -k $OTHER_HEMI_MASK -k $k -V | awk '{print $1 }'

	done


done


