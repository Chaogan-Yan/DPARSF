function [b_OLS_brain, t_OLS_brain, TF_ForContrast_brain, r_OLS_brain, Header] = y_GroupAnalysis_Image(DependentVolume,Predictor,OutputName,MaskFile,Contrast,TF_Flag,IsOutputResidual,Header)
% function y_GroupAnalysis_Image(DependentDir,Predictor,OutputName,MaskFile)
% Perform regression analysis 
% Input:
% 	DependentVolume		-	4D data matrix (DimX*DimY*DimZ*DimTimePoints) or the directory of 3D image data file or the filename of one 4D data file
%   Predictor - the Predictors M (subjects) by N (traits). SHOULD INCLUDE the CONSTANT column if needed. The program will not add constant column automatically.
%   OutputName - the output name. (should not have extention such as .img,.nii)
%   MaskFile - the mask file.
%   Contrast [optional] - Contrast for T-test for F-test. 1*ncolX matrix.
%   TF_Flag [optional] - 'T' or 'F'. Specify if T-test or F-test need to be performed for the contrast
%   IsOutputResidual - 1: output the 4D residuals. 
%                    - 0: don't output the 4D residuals
%   Header [optional] - If DependentVolume is given as a 4D Brain matrix, then Header should be designated.

% Output:
%   OutputName_b.nii, OutputName_T.nii     - beta and t value files results
%   OutputName_Residual.nii (optional)     - Residual files
%___________________________________________________________________________
% Written by YAN Chao-Gan 120823.
% The Nathan Kline Institute for Psychiatric Research, 140 Old Orangeburg Road, Orangeburg, NY 10962, USA
% Child Mind Institute, 445 Park Avenue, New York, NY 10022, USA
% The Phyllis Green and Randolph Cowen Institute for Pediatric Neuroscience, New York University Child Study Center, New York, NY 10016, USA
% ycg.yan@gmail.com

if ~exist('MaskFile','var')
    MaskFile = '';
end


if ~isnumeric(DependentVolume)
    [DependentVolume,VoxelSize,theImgFileList, Header] =rest_to4d(DependentVolume);
    fprintf('\n\tImage Files in the Group:\n');
    for itheImgFileList=1:length(theImgFileList)
        fprintf('\t%s%s\n',theImgFileList{itheImgFileList});
    end
end




[nDim1,nDim2,nDim3,nDim4]=size(DependentVolume);

if ~isempty(MaskFile)
    [MaskData,MaskVox,MaskHead]=rest_readfile(MaskFile);
else
    MaskData=ones(nDim1,nDim2,nDim3);
end

MaskData = any(DependentVolume,4) .* MaskData; % skip the voxels with all zeros


b_OLS_brain=zeros(nDim1,nDim2,nDim3,size(Predictor,2));
t_OLS_brain=zeros(nDim1,nDim2,nDim3,size(Predictor,2));

TF_ForContrast_brain=zeros(nDim1,nDim2,nDim3);

%YAN Chao-Gan, 130227
if exist('IsOutputResidual','var') && (IsOutputResidual==1)
    r_OLS_brain=zeros(nDim1,nDim2,nDim3,nDim4);
end

fprintf('\n\tRegression Calculating...\n');
for i=1:nDim1
    fprintf('.');
    for j=1:nDim2
        for k=1:nDim3
            if MaskData(i,j,k)

                DependentVariable=squeeze(DependentVolume(i,j,k,:));
                
                
                
                if exist('Contrast','var') && ~isempty(Contrast)
                    
                    [b,r,SSE,SSR, T, TF_ForContrast] = y_regress_ss(DependentVariable,Predictor,Contrast,TF_Flag);
                    
                    b_OLS_brain(i,j,k,:)=b;
                    t_OLS_brain(i,j,k,:)=T;
                    TF_ForContrast_brain(i,j,k)=TF_ForContrast;
                    
                else
                    [b,r,SSE,SSR,T] = y_regress_ss(DependentVariable,Predictor);
                    
                    b_OLS_brain(i,j,k,:)=b;
                    t_OLS_brain(i,j,k,:)=T;
                    
                end
                
                %YAN Chao-Gan, 130227
                if exist('IsOutputResidual','var') && (IsOutputResidual==1)
                    r_OLS_brain(i,j,k,:)=r;
                end
                
            end
        end
    end
end
b_OLS_brain(isnan(b_OLS_brain))=0;
t_OLS_brain(isnan(t_OLS_brain))=0;
TF_ForContrast_brain(isnan(TF_ForContrast_brain))=0;

Header.pinfo = [1;0;0];
Header.dt    =[16,0];

DOF = nDim4 - size(Predictor,2);
HeaderTWithDOF=Header;
HeaderTWithDOF.descrip=sprintf('REST{T_[%.1f]}',DOF);

for ii=1:size(b_OLS_brain,4)
    
    rest_WriteNiftiImage(squeeze(b_OLS_brain(:,:,:,ii)),Header,[OutputName,'_b',num2str(ii),'.nii']);
    rest_WriteNiftiImage(squeeze(t_OLS_brain(:,:,:,ii)),HeaderTWithDOF,[OutputName,'_T',num2str(ii),'.nii']);
    
end


if exist('Contrast','var') && ~isempty(Contrast)

    Df_Group = length(find(Contrast));
    Df_E = nDim4 - size(Predictor,2);
    HeaderTWithDOF=Header;
    HeaderTWithDOF.descrip=sprintf('REST{F_[%.1f,%.1f]}',Df_Group,Df_E);
    
    rest_WriteNiftiImage(TF_ForContrast_brain,HeaderTWithDOF,[OutputName,'_',TF_Flag,'_ForContrast','.nii']);
  
end

%YAN Chao-Gan, 130227
if exist('IsOutputResidual','var') && (IsOutputResidual==1)
    y_Write4DNIfTI(r_OLS_brain,Header,[OutputName,'_Residual','.nii']);
end


fprintf('\n\tRegression Calculation finished.\n');
