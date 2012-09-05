function [flag] = y_Write4DNIfTI(Data,Head,imageOUT)
% Write 4D NIfTI file Based on SPM's nifti
% %------------------------------------------------------------------------
% Write data (Data) with a specified header (Head) into a image file with format 
% of Nifti 1.1. The data (Data) should be 3D matrix, the header (Head) should 
% be a structure the same as SPM5. If the filename (imageOUT) is with 
% extra name as '.img', then it will generate two files (header and
% data seperately), or else, '.nii', it will generate single file with
% header 
% and data together.
%
% Usage: [flag] = y_Write4DNIfTI(Data,Head,imageOUT)
%
% Input:
% 1. Data -  Data of 4D matrix to write
% 2. Head - a structure containing image volume information, the structure
%    is the same with a structure have read
%    The elements in the structure are:
%       Head.fname - the filename of the image. If the filename is not set, 
%                    just use the parameter.
%       Head.dt    - A 1x2 array.  First element is datatype (see spm_type).
%                 The second is 1 or 0 depending on the endian-ness.
%       Head.mat   - a 4x4 affine transformation matrix mapping from
%                 voxel coordinates to real world coordinates.
%       Head.pinfo - plane info for each plane of the volume.
%              Head.pinfo(1,:) - scale for each plane
%              Head.pinfo(2,:) - offset for each plane
%                 The true voxel intensities of the jth image are given
%                 by: val*Head.pinfo(1,j) + Head.pinfo(2,j)
%              Head.pinfo(3,:) - offset into image (in bytes).
%                 If the size of pinfo is 3x1, then the volume is assumed
%                 to be contiguous and each plane has the same scalefactor
%                 and offset.
%              The scale and intercept will be changed according to the
%              data to write
% 3. imageOUT - the path and filename of image file to output [path\*.img or *.nii]
% Output:
% 1. flag - a flag for all done, 1: successful, 0: fail
% ------------------------------------------------------------------------
% Written by YAN Chao-Gan 120301. Based on SPM's nifti.
% The Nathan Kline Institute for Psychiatric Research, 140 Old Orangeburg Road, Orangeburg, NY 10962, USA
% Child Mind Institute, 445 Park Avenue, New York, NY 10022, USA
% The Phyllis Green and Randolph Cowen Institute for Pediatric Neuroscience, New York University Child Study Center, New York, NY 10016, USA
% ycg.yan@gmail.com


dat = file_array;
dat.fname = imageOUT;
dat.dim   = size(Data);
if isfield(Head,'dt')
    dat.dtype  = Head.dt(1);
else % If data type is defined by the nifti command
    dat.dtype  = Head.dat.dtype;
end

dat.offset  = ceil(348/8)*8;

NIfTIObject = nifti;
NIfTIObject.dat=dat;
NIfTIObject.mat=Head.mat;
NIfTIObject.mat0 = Head.mat;
NIfTIObject.descrip = Head.descrip;

create(NIfTIObject);
dat(:,:,:,:)=Data;
