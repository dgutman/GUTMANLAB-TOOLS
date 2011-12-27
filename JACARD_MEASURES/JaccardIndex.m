function [ Jindex ] = JaccardIndex( filename1, filename2 )
%function that computes the jaccard Index for 2 volumes
%   Input: filename1,filename2 - nifti files
%
%   Output: Jindex - the Jaccard similarity coefficient 
%                    a value close to 1 means the 2 volumes are almost
%                    identical, a value close to 0 means they are not
%                    similar


A = readnifti(filename1);
B = readnifti(filename2);
if size(A) ~= size(B)
    printf('Error: Volume sizes must match\n');
else
    inter = 0;
    union = 0;

    for i=1:size(A,3)
        
        %union counts the nonzero elemenents in A or B 
        %inter counts the nonzero elements in both A and B
         for j = 1:size(A,1)
            for k = 1:size(A,2)
               if  ( A(j,k,i) ~= 0 && B(j,k,i) ~= 0 )  
                  inter = inter + 1;
               end
               if (A(j,k,i) ~= 0 || B(j,k,i) ~= 0)
                  union = union + 1;
               end
            end

         end
    end
    
    Jindex = inter/union;
    Jindex
end %end if

end

