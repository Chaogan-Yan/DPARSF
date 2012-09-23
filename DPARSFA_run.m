function [Error]=DPARSFA_run(AutoDataProcessParameter)
% FORMAT [Error]=DPARSFA_run(AutoDataProcessParameter)
% Input:
%   AutoDataProcessParameter - the parameters for auto data processing
% Output:
%   The processed data that you want.
%___________________________________________________________________________
% Written by YAN Chao-Gan 090306.
% State Key Laboratory of Cognitive Neuroscience and Learning, Beijing Normal University, China, 100875
% The Nathan Kline Institute for Psychiatric Research, 140 Old Orangeburg Road, Orangeburg, NY 10962; Child Mind Institute, 445 Park Avenue, New York, NY 10022; The Phyllis Green and Randolph Cowen Institute for Pediatric Neuroscience, New York University Child Study Center, New York, NY 10016
% ycg.yan@gmail.com
% Modified by YAN Chao-Gan 090712, added the function of mReHo - 1, mALFF - 1, mfALFF -1.
% Modified by YAN Chao-Gan 090901, added the function of smReHo, remove variable first time points.
% Modified by YAN Chao-Gan, 090925, SPM8 compatible.
% Modified by YAN Chao-Gan 091001, Generate the pictures for checking normalization.
% Modified by YAN Chao-Gan 091111. 1. Use different Affine Regularisation in Segmentation: East Asian brains (eastern) or European brains (mni). 2. Added a checkbox for removing first time points. 3.Added popup menu to delete selected subject by right click. 4. Close wait bar when program finished.
% Modified by YAN Chao-Gan 091212. Also can regress out other covariates.
% Modified by YAN Chao-Gan 100201. Fixed the bug in converting DICOM files to NIfTI files when DPARSF stored under C:\Program Files\Matlab\Toolbox.
% Modified by YAN Chao-Gan, 100420. Release the memory occupied by "hdr" after converting one participant's Functional DICOM files to NIFTI images in linux. Make compatible with missing parameters. Fixed a bug in generating the pictures for checking normalizationdisplaying when overlay with different bounding box from those of underlay in according to rest_sliceviewer.m.
% Modified by YAN Chao-Gan, 100510. Fixed a bug in converting DICOM files to NIfTI in Windows 7, thanks to Prof. Chris Rorden's new dcm2nii. Now will detect if co* T1 image is exist before normalization by using T1 image unified segmentation.
% Modified by YAN Chao-Gan, 101025. Changed for Data Processing Assistant for Resting-State fMRI (DPARSF) Advanced Edition (alias: DPARSFA).
% Last Modified by YAN Chao-Gan, 120101. DARTEL, multiplse sessions, reorient, .nii.gz files and so on added.

if ischar(AutoDataProcessParameter)  %If inputed a .mat file name. (Cfg inside)
    load(AutoDataProcessParameter);
    AutoDataProcessParameter=Cfg;
end

[ProgramPath, fileN, extn] = fileparts(which('DPARSFA_run.m'));
AutoDataProcessParameter.SubjectNum=length(AutoDataProcessParameter.SubjectID);
Error=[];
addpath([ProgramPath,filesep,'Subfunctions']);

[SPMversion,c]=spm('Ver');
SPMversion=str2double(SPMversion(end));


%Make compatible with missing parameters. YAN Chao-Gan, 100420.
if ~isfield(AutoDataProcessParameter,'DataProcessDir')
    AutoDataProcessParameter.DataProcessDir=AutoDataProcessParameter.WorkingDir;
end
% if isfield(AutoDataProcessParameter,'TR')
%     AutoDataProcessParameter.SliceTiming.TR=AutoDataProcessParameter.TR;
%     AutoDataProcessParameter.SliceTiming.TA=AutoDataProcessParameter.SliceTiming.TR-(AutoDataProcessParameter.SliceTiming.TR/AutoDataProcessParameter.SliceTiming.SliceNumber);
%     AutoDataProcessParameter.Filter.ASamplePeriod=AutoDataProcessParameter.TR;
%     AutoDataProcessParameter.CalALFF.ASamplePeriod=AutoDataProcessParameter.TR;
%     AutoDataProcessParameter.CalfALFF.ASamplePeriod=AutoDataProcessParameter.TR;
% end
if ~isfield(AutoDataProcessParameter,'FunctionalSessionNumber')
    AutoDataProcessParameter.FunctionalSessionNumber=1; 
end
if ~isfield(AutoDataProcessParameter,'IsNeedConvertFunDCM2IMG')
    AutoDataProcessParameter.IsNeedConvertFunDCM2IMG=0; 
end
% if ~isfield(AutoDataProcessParameter,'IsNeedConvert4DFunInto3DImg')
%     AutoDataProcessParameter.IsNeedConvert4DFunInto3DImg=0; 
% end
if ~isfield(AutoDataProcessParameter,'RemoveFirstTimePoints')
    AutoDataProcessParameter.RemoveFirstTimePoints=0; 
end
if ~isfield(AutoDataProcessParameter,'IsSliceTiming')
    AutoDataProcessParameter.IsSliceTiming=0; 
end
if ~isfield(AutoDataProcessParameter,'IsRealign')
    AutoDataProcessParameter.IsRealign=0; 
end
if ~isfield(AutoDataProcessParameter,'IsCalVoxelSpecificHeadMotion')
    AutoDataProcessParameter.IsCalVoxelSpecificHeadMotion=0; 
end
if ~isfield(AutoDataProcessParameter,'IsNeedReorientFunImgInteractively')
    AutoDataProcessParameter.IsNeedReorientFunImgInteractively=0; 
end
if ~isfield(AutoDataProcessParameter,'IsNeedConvertT1DCM2IMG')
    AutoDataProcessParameter.IsNeedConvertT1DCM2IMG=0; 
end
% if ~isfield(AutoDataProcessParameter,'IsNeedUnzipT1IntoT1Img')
%     AutoDataProcessParameter.IsNeedUnzipT1IntoT1Img=0; 
% end
if ~isfield(AutoDataProcessParameter,'IsNeedReorientCropT1Img')
    AutoDataProcessParameter.IsNeedReorientCropT1Img=0; 
end
if ~isfield(AutoDataProcessParameter,'IsNeedReorientT1ImgInteractively')
    AutoDataProcessParameter.IsNeedReorientT1ImgInteractively=0; 
end
if ~isfield(AutoDataProcessParameter,'IsNeedT1CoregisterToFun')
    AutoDataProcessParameter.IsNeedT1CoregisterToFun=0; 
end
if ~isfield(AutoDataProcessParameter,'IsNeedReorientInteractivelyAfterCoreg')
    AutoDataProcessParameter.IsNeedReorientInteractivelyAfterCoreg=0; 
end
if ~isfield(AutoDataProcessParameter,'IsSegment')  %1: Segment; 2: New Segment
    AutoDataProcessParameter.IsSegment=0; 
end
if ~isfield(AutoDataProcessParameter,'IsDARTEL')
    AutoDataProcessParameter.IsDARTEL=0; 
end
if ~isfield(AutoDataProcessParameter,'IsCovremove')
    AutoDataProcessParameter.IsCovremove=0; 
end
if ~isfield(AutoDataProcessParameter,'IsFilter')
    AutoDataProcessParameter.IsFilter=0; 
end
if ~isfield(AutoDataProcessParameter,'IsNormalize')  %1: Normalization by using the EPI template directly; 2: Normalization by using the T1 image segment information (T1 images stored in 'DataProcessDir\T1Img' and initiated with 'co*'); 3: Normalized by DARTEL
    AutoDataProcessParameter.IsNormalize=0; 
end
% if ~isfield(AutoDataProcessParameter,'IsDelFilesBeforeNormalize')
%     AutoDataProcessParameter.IsDelFilesBeforeNormalize=0; 
% end
if ~isfield(AutoDataProcessParameter,'IsSmooth')  %1: Smooth module in SPM; 2: Smooth by DARTEL
    AutoDataProcessParameter.IsSmooth=0; 
end
if ~isfield(AutoDataProcessParameter,'MaskFile')
    AutoDataProcessParameter.MaskFile ='Default';
end
if ~isfield(AutoDataProcessParameter,'IsWarpMasksIntoIndividualSpace')
    AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace=0; 
end
if ~isfield(AutoDataProcessParameter,'IsDetrend')
    AutoDataProcessParameter.IsDetrend=0; 
end
% if ~isfield(AutoDataProcessParameter,'IsDelDetrendedFiles')
%     AutoDataProcessParameter.IsDelDetrendedFiles=0; 
% end
if ~isfield(AutoDataProcessParameter,'IsCalALFF')
    AutoDataProcessParameter.IsCalALFF=0; 
end
% if ~isfield(AutoDataProcessParameter,'IsCalfALFF')
%     AutoDataProcessParameter.IsCalfALFF=0; 
% end
if ~isfield(AutoDataProcessParameter,'IsScrubbing')
    AutoDataProcessParameter.IsScrubbing=0; 
end
if ~isfield(AutoDataProcessParameter,'IsCalReHo')
    AutoDataProcessParameter.IsCalReHo=0; 
end
if ~isfield(AutoDataProcessParameter,'IsCalDegreeCentrality')
    AutoDataProcessParameter.IsCalDegreeCentrality=0; 
end
if ~isfield(AutoDataProcessParameter,'IsCalFC')
    AutoDataProcessParameter.IsCalFC=0; 
end
if ~isfield(AutoDataProcessParameter,'CalFC')
    AutoDataProcessParameter.CalFC.ROIDef = {};
elseif ~isfield(AutoDataProcessParameter.CalFC,'ROIDef')
    AutoDataProcessParameter.CalFC.ROIDef = {};
end
if ~isfield(AutoDataProcessParameter,'IsExtractROISignals')
    AutoDataProcessParameter.IsExtractROISignals=0; 
end
if ~isfield(AutoDataProcessParameter,'IsDefineROIInteractively')
    AutoDataProcessParameter.IsDefineROIInteractively=0; 
end
if ~isfield(AutoDataProcessParameter,'IsExtractAALTC')
    AutoDataProcessParameter.IsExtractAALTC=0; 
end
if ~isfield(AutoDataProcessParameter,'IsCalVMHC')
    AutoDataProcessParameter.IsCalVMHC=0; 
end
if ~isfield(AutoDataProcessParameter,'IsCWAS')
    AutoDataProcessParameter.IsCWAS=0; 
end








% Multiple Sessions Processing 
% YAN Chao-Gan, 111215 added.
FunSessionPrefixSet={''}; %The first session doesn't need a prefix. From the second session, need a prefix such as 'S2_';
for iFunSession=2:AutoDataProcessParameter.FunctionalSessionNumber
    FunSessionPrefixSet=[FunSessionPrefixSet;{['S',num2str(iFunSession),'_']}];
end


%Convert Functional DICOM files to NIFTI images
if (AutoDataProcessParameter.IsNeedConvertFunDCM2IMG==1)
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'FunRaw']);
        parfor i=1:AutoDataProcessParameter.SubjectNum
            OutputDir=[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'FunImg',filesep,AutoDataProcessParameter.SubjectID{i}];
            mkdir(OutputDir);
            DirDCM=dir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'FunRaw',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*']); %Revised by YAN Chao-Gan 100130. %DirDCM=dir([AutoDataProcessParameter.DataProcessDir,filesep,'FunRaw',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.*']);
            if strcmpi(DirDCM(3).name,'.DS_Store')  %110908 YAN Chao-Gan, for MAC OS compatablie
                StartIndex=4;
            else
                StartIndex=3;
            end
            InputFilename=[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'FunRaw',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirDCM(StartIndex).name];

            %YAN Chao-Gan 120817.
            y_Call_dcm2nii(InputFilename, OutputDir, 'DefaultINI');

            fprintf(['Converting Functional Images:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
    end
    AutoDataProcessParameter.StartingDirName='FunImg';   %Now start with FunImg directory. 101010
end


%Convert T1 DICOM files to NIFTI images
if (AutoDataProcessParameter.IsNeedConvertT1DCM2IMG==1)
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1Raw']);
    parfor i=1:AutoDataProcessParameter.SubjectNum
        OutputDir=[AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i}];
        mkdir(OutputDir);
        DirDCM=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1Raw',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*']); %Revised by YAN Chao-Gan 100130. %DirDCM=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1Raw',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.*']);
        if strcmpi(DirDCM(3).name,'.DS_Store')  %110908 YAN Chao-Gan, for MAC OS compatablie
            StartIndex=4;
        else
            StartIndex=3;
        end
        InputFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1Raw',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirDCM(StartIndex).name];
        
        %YAN Chao-Gan 120817.
        y_Call_dcm2nii(InputFilename, OutputDir, 'DefaultINI');
        
        fprintf(['Converting T1 Images:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
end




%Reorient and Crop T1Img by using Chris Rorden's dcm2nii
% YAN Chao-Gan, 111121
if (AutoDataProcessParameter.IsNeedReorientCropT1Img==1)
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img']);
    parfor i=1:AutoDataProcessParameter.SubjectNum
        OutputDir=[AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i}];
        DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii.gz']);
        if isempty(DirImg)
            DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii']);
        end
        if isempty(DirImg)
            DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.img']);
        end
        
        InputFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name];
        
        %YAN Chao-Gan 120817.
        y_Call_dcm2nii(InputFilename, OutputDir, '-g N -m N -n Y -r Y -v N -x Y');
        
        fprintf(['Reorienting and Cropping Images:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
end






%****************************************************************Processing of fMRI BOLD images*****************
%Check TR
if isfield(AutoDataProcessParameter,'TR')
    if AutoDataProcessParameter.TR==0  % Need to retrieve the TR information from the NIfTI images
        TRSet = zeros(AutoDataProcessParameter.FunctionalSessionNumber,AutoDataProcessParameter.SubjectNum);
        for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
            parfor i=1:AutoDataProcessParameter.SubjectNum
                cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}]);
                DirImg=dir('*.img');
                if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files. % Either in .nii.gz or in .nii
                    DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                    if length(DirImg)==1
                        gunzip(DirImg(1).name);
                        delete(DirImg(1).name);
                    end
                    DirImg=dir('*.nii');
                end
                Nii  = nifti(DirImg(1).name);
                if (~isfield(Nii.timing,'tspace'))
                    error('Can NOT retrieve the TR information from the NIfTI images');
                end
                TRSet(iFunSession,i) = Nii.timing.tspace;
            end
        end
        AutoDataProcessParameter.TRSet = TRSet;
    end
end

%Remove First Time Points
if (AutoDataProcessParameter.RemoveFirstTimePoints>0)
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName]);
        parfor i=1:AutoDataProcessParameter.SubjectNum
            cd(AutoDataProcessParameter.SubjectID{i});
            DirImg=dir('*.img');
            if ~isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files.
                if AutoDataProcessParameter.TimePoints>0 && length(DirImg)~=AutoDataProcessParameter.TimePoints % Will not check if TimePoints set to 0. YAN Chao-Gan 120806.
                    Error=[Error;{['Error in Removing First ',num2str(AutoDataProcessParameter.RemoveFirstTimePoints),'Time Points: ',AutoDataProcessParameter.SubjectID{i}]}];
                end
                for j=1:AutoDataProcessParameter.RemoveFirstTimePoints
                    delete(DirImg(j).name);
                    delete([DirImg(j).name(1:end-4),'.hdr']);
                end
            else % either in .nii.gz or in .nii
                DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirImg)==1
                    gunzip(DirImg(1).name);
                    delete(DirImg(1).name);
                end
                
                DirImg=dir('*.nii');
                
                if length(DirImg)>1  %3D .nii images.
                    if AutoDataProcessParameter.TimePoints>0 && length(DirImg)~=AutoDataProcessParameter.TimePoints % Will not check if TimePoints set to 0. YAN Chao-Gan 120806.
                        Error=[Error;{['Error in Removing First ',num2str(AutoDataProcessParameter.RemoveFirstTimePoints),'Time Points: ',AutoDataProcessParameter.SubjectID{i}]}];
                    end
                    for j=1:AutoDataProcessParameter.RemoveFirstTimePoints
                        delete(DirImg(j).name);
                    end
                else %4D .nii images
                    Nii  = nifti(DirImg(1).name);
                    if AutoDataProcessParameter.TimePoints>0 && size(Nii.dat,4)~=AutoDataProcessParameter.TimePoints % Will not check if TimePoints set to 0. YAN Chao-Gan 120806.
                        Error=[Error;{['Error in Removing First ',num2str(AutoDataProcessParameter.RemoveFirstTimePoints),'Time Points: ',AutoDataProcessParameter.SubjectID{i}]}];
                    end
                    y_Write4DNIfTI(Nii.dat(:,:,:,AutoDataProcessParameter.RemoveFirstTimePoints+1:end),Nii,DirImg(1).name);
                end
                
            end
            cd('..');
            fprintf(['Removing First ',num2str(AutoDataProcessParameter.RemoveFirstTimePoints),' Time Points: ',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
    end
    AutoDataProcessParameter.TimePoints=AutoDataProcessParameter.TimePoints-AutoDataProcessParameter.RemoveFirstTimePoints;
end
if ~isempty(Error)
    disp(Error);
    return;
end


%Slice Timing
if (AutoDataProcessParameter.IsSliceTiming==1)
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber

        parfor i=1:AutoDataProcessParameter.SubjectNum
            SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'SliceTiming.mat']);
            
            cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}]);
            DirImg=dir('*.img');
            
            if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files. % Either in .nii.gz or in .nii
                DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirImg)==1
                    gunzip(DirImg(1).name);
                    delete(DirImg(1).name);
                end
                DirImg=dir('*.nii');
            end
            
            if length(DirImg)>1  %3D .img or .nii images.
                if AutoDataProcessParameter.TimePoints>0 && length(DirImg)~=AutoDataProcessParameter.TimePoints % Will not check if TimePoints set to 0. YAN Chao-Gan 120806.
                    Error=[Error;{['Error in Slice Timing, time point number doesn''t match: ',AutoDataProcessParameter.SubjectID{i}]}];
                end
                FileList=[];
                for j=1:length(DirImg)
                    FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(j).name]}];
                end
            else %4D .nii images
                Nii  = nifti(DirImg(1).name);
                if AutoDataProcessParameter.TimePoints>0 && size(Nii.dat,4)~=AutoDataProcessParameter.TimePoints % Will not check if TimePoints set to 0. YAN Chao-Gan 120806.
                    Error=[Error;{['Error in Slice Timing, time point number doesn''t match: ',AutoDataProcessParameter.SubjectID{i}]}];
                end
                FileList=[];
                for j=1:size(Nii.dat,4)
                    FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name,',',num2str(j)]}];
                end
            end

            
            SPMJOB.jobs{1,1}.temporal{1,1}.st.scans{1}=FileList;
            

            if AutoDataProcessParameter.SliceTiming.SliceNumber==0 %If SliceNumber is set to 0, then retrieve the slice number from the NIfTI images. The slice order is then assumed as interleaved scanning: [1:2:SliceNumber,2:2:SliceNumber]. The reference slice is set to the slice acquired at the middle time point, i.e., SliceOrder(ceil(SliceNumber/2)). SHOULD BE EXTREMELY CAUTIOUS!!!
                Nii=nifti(FileList{1});
                SliceNumber = size(Nii.dat,3);
                SPMJOB.jobs{1,1}.temporal{1,1}.st.nslices = SliceNumber;
                SPMJOB.jobs{1,1}.temporal{1,1}.st.so = [1:2:SliceNumber,2:2:SliceNumber];
                SPMJOB.jobs{1,1}.temporal{1,1}.st.refslice = SPMJOB.jobs{1,1}.temporal{1,1}.st.so(ceil(SliceNumber/2));
            else
                SliceNumber = AutoDataProcessParameter.SliceTiming.SliceNumber;
                SPMJOB.jobs{1,1}.temporal{1,1}.st.nslices = SliceNumber;
                SPMJOB.jobs{1,1}.temporal{1,1}.st.so = AutoDataProcessParameter.SliceTiming.SliceOrder;
                SPMJOB.jobs{1,1}.temporal{1,1}.st.refslice = AutoDataProcessParameter.SliceTiming.ReferenceSlice;     
            end
            
            if AutoDataProcessParameter.TR==0  %If TR is set to 0, then Need to retrieve the TR information from the NIfTI images
                SPMJOB.jobs{1,1}.temporal{1,1}.st.tr = AutoDataProcessParameter.TRSet(iFunSession,i);
                SPMJOB.jobs{1,1}.temporal{1,1}.st.ta = AutoDataProcessParameter.TRSet(iFunSession,i) - (AutoDataProcessParameter.TRSet(iFunSession,i)/SliceNumber);
            else
                SPMJOB.jobs{1,1}.temporal{1,1}.st.tr = AutoDataProcessParameter.TR;
                SPMJOB.jobs{1,1}.temporal{1,1}.st.ta = AutoDataProcessParameter.TR - (AutoDataProcessParameter.TR/SliceNumber);
            end
            
            
            fprintf(['Slice Timing Setup:',AutoDataProcessParameter.SubjectID{i},' OK\n']);
            if SPMversion==5
                spm_jobman('run',SPMJOB.jobs);
            elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
                SPMJOB.jobs = spm_jobman('spm5tospm8',{SPMJOB.jobs});
                spm_jobman('run',SPMJOB.jobs{1});
            else
                uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
                Error=[Error;{['Error in Slice Timing: The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.']}];
            end
        end

        %Copy the Slice Timing Corrected files to DataProcessDir\{AutoDataProcessParameter.StartingDirName}+A
        parfor i=1:AutoDataProcessParameter.SubjectNum
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'A',filesep,AutoDataProcessParameter.SubjectID{i}])
            movefile([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'a*'],[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'A',filesep,AutoDataProcessParameter.SubjectID{i}])
            fprintf(['Moving Slice Timing Corrected Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
        
    end
    AutoDataProcessParameter.StartingDirName=[AutoDataProcessParameter.StartingDirName,'A']; %Now StartingDirName is with new suffix 'A'
end
if ~isempty(Error)
    disp(Error);
    return;
end


%Realign
if (AutoDataProcessParameter.IsRealign==1)
    parfor i=1:AutoDataProcessParameter.SubjectNum
        SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Realign.mat']);

        for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
            cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}]);
            DirImg=dir('*.img');
            
            
            if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files. % Either in .nii.gz or in .nii
                DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirImg)==1
                    gunzip(DirImg(1).name);
                    delete(DirImg(1).name);
                end
                DirImg=dir('*.nii');
            end
            
            if length(DirImg)>1  %3D .img or .nii images.
                if AutoDataProcessParameter.TimePoints>0 && length(DirImg)~=AutoDataProcessParameter.TimePoints % Will not check if TimePoints set to 0. YAN Chao-Gan 120806.
                    Error=[Error;{['Error in Realign, time point number doesn''t match: ',AutoDataProcessParameter.SubjectID{i}]}];
                end
                FileList=[];
                for j=1:length(DirImg)
                    FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(j).name]}];
                end
            else %4D .nii images
                Nii  = nifti(DirImg(1).name);
                if AutoDataProcessParameter.TimePoints>0 && size(Nii.dat,4)~=AutoDataProcessParameter.TimePoints % Will not check if TimePoints set to 0. YAN Chao-Gan 120806.
                    Error=[Error;{['Error in Realign, time point number doesn''t match: ',AutoDataProcessParameter.SubjectID{i}]}];
                end
                FileList=[];
                for j=1:size(Nii.dat,4)
                    FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name,',',num2str(j)]}];
                end
            end
            
            
            SPMJOB.jobs{1,1}.spatial{1,1}.realign{1,1}.estwrite.data{1,iFunSession}=FileList;
        end

        fprintf(['Realign Setup:',AutoDataProcessParameter.SubjectID{i},' OK\n']);
        if SPMversion==5
            spm_jobman('run',SPMJOB.jobs);
        elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
            SPMJOB.jobs = spm_jobman('spm5tospm8',{SPMJOB.jobs});
            spm_jobman('run',SPMJOB.jobs{1});
        else
            uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
            Error=[Error;{['Error in Realign: The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.']}];
        end
    end

    %Copy the Realign Parameters
    mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter']);
    if ~isempty(dir('*.ps'))
        copyfile('*.ps',[AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter']);
    end
    parfor i=1:AutoDataProcessParameter.SubjectNum
        cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{1},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}]);
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i}]);
        movefile('mean*',[AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i}]);
        movefile('rp*.txt',[AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i}]);
        for iFunSession=2:AutoDataProcessParameter.FunctionalSessionNumber
            cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}]);
            DirRP=dir('rp*.txt');
            [PathTemp, fileN, extn] = fileparts(DirRP.name);
            copyfile([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirRP.name],[AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,FunSessionPrefixSet{iFunSession},fileN, extn]);
        end
    end

    %Copy the Head Motion Corrected files to DataProcessDir\{AutoDataProcessParameter.StartingDirName}+R
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName]);
        parfor i=1:AutoDataProcessParameter.SubjectNum
            cd(AutoDataProcessParameter.SubjectID{i});
            mkdir(['..',filesep,'..',filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'R',filesep,AutoDataProcessParameter.SubjectID{i}])
            DirImg=dir('*.img');
            if ~isempty(DirImg)  %YAN Chao-Gan, 111114
                movefile('r*.img',['..',filesep,'..',filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'R',filesep,AutoDataProcessParameter.SubjectID{i}])
                movefile('r*.hdr',['..',filesep,'..',filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'R',filesep,AutoDataProcessParameter.SubjectID{i}])
            else
                movefile('r*.nii',['..',filesep,'..',filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'R',filesep,AutoDataProcessParameter.SubjectID{i}])
            end
            cd('..');
            fprintf(['Moving Head Motion Corrected Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
    end
    fprintf('\n');
    AutoDataProcessParameter.StartingDirName=[AutoDataProcessParameter.StartingDirName,'R']; %Now StartingDirName is with new suffix 'R'
    
    %Check Head Motion
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter']);
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        
        HeadMotion = zeros(AutoDataProcessParameter.SubjectNum,19);
        % max(abs(Tx)), max(abs(Ty)), max(abs(Tz)), max(abs(Rx)), max(abs(Ry)), max(abs(Rz)),
        % mean(abs(Tx)), mean(abs(Ty)), mean(abs(Tz)), mean(abs(Rx)), mean(abs(Ry)), mean(abs(Rz)),
        % mean RMS, mean relative RMS (mean FD_VanDijk), 
        % mean FD_Power, Number of FD_Power>0.5, Percent of FD_Power>0.5, Number of FD_Power>0.2, Percent of FD_Power>0.2

        for i=1:AutoDataProcessParameter.SubjectNum
            cd([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i}]);
           
            rpname=dir([FunSessionPrefixSet{iFunSession},'rp*']);
            
            RP=load(rpname.name);
            
            MaxRP = max(abs(RP));
            MaxRP(4:6) = MaxRP(4:6)*180/pi;
            
            MeanRP = mean(abs(RP));
            MeanRP(4:6) = MeanRP(4:6)*180/pi;
            
            %Calculate FD Van Dijk (Van Dijk, K.R., Sabuncu, M.R., Buckner, R.L., 2012. The influence of head motion on intrinsic functional connectivity MRI. Neuroimage 59, 431-438.)
            RPRMS = sqrt(sum(RP(:,1:3).^2,2));
            MeanRMS = mean(RPRMS);
            
            FD_VanDijk = abs(diff(RPRMS));
            FD_VanDijk = [0;FD_VanDijk];
            save([FunSessionPrefixSet{iFunSession},'FD_VanDijk_',AutoDataProcessParameter.SubjectID{i},'.txt'], 'FD_VanDijk', '-ASCII', '-DOUBLE','-TABS');
            MeanFD_VanDijk = mean(FD_VanDijk);
            
            %Calculate FD Power (Power, J.D., Barnes, K.A., Snyder, A.Z., Schlaggar, B.L., Petersen, S.E., 2012. Spurious but systematic correlations in functional connectivity MRI networks arise from subject motion. Neuroimage 59, 2142-2154.) 
            RPDiff=diff(RP);
            RPDiff=[zeros(1,6);RPDiff];
            RPDiffSphere=RPDiff;
            RPDiffSphere(:,4:6)=RPDiffSphere(:,4:6)*50;
            FD_Power=sum(abs(RPDiffSphere),2);
            save([FunSessionPrefixSet{iFunSession},'FD_Power_',AutoDataProcessParameter.SubjectID{i},'.txt'], 'FD_Power', '-ASCII', '-DOUBLE','-TABS');
            MeanFD_Power = mean(FD_Power);
            
            NumberFD_Power_05 = length(find(FD_Power>0.5));
            PercentFD_Power_05 = length(find(FD_Power>0.5)) / length(FD_Power);
            NumberFD_Power_02 = length(find(FD_Power>0.2));
            PercentFD_Power_02 = length(find(FD_Power>0.2)) / length(FD_Power);

            HeadMotion(i,:) = [MaxRP,MeanRP,MeanRMS,MeanFD_VanDijk,MeanFD_Power,NumberFD_Power_05,PercentFD_Power_05,NumberFD_Power_02,PercentFD_Power_02];

        end
        save([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,FunSessionPrefixSet{iFunSession},'HeadMotion.mat'],'HeadMotion');

        %Write the Head Motion as .csv
        fid = fopen([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,FunSessionPrefixSet{iFunSession},'HeadMotion.csv'],'w');
        fprintf(fid,'Subject ID\tmax(abs(Tx))\tmax(abs(Ty))\tmax(abs(Tz))\tmax(abs(Rx))\tmax(abs(Ry))\tmax(abs(Rz))\tmean(abs(Tx))\tmean(abs(Ty))\tmean(abs(Tz))\tmean(abs(Rx))\tmean(abs(Ry))\tmean(abs(Rz))\tmean RMS\tmean relative RMS (mean FD_VanDijk)\tmean FD_Power\tNumber of FD_Power>0.5\tPercent of FD_Power>0.5\tNumber of FD_Power>0.2\tPercent of FD_Power>0.2\n');
        for i=1:AutoDataProcessParameter.SubjectNum
            fprintf(fid,'%s\t',AutoDataProcessParameter.SubjectID{i});
            fprintf(fid,'%e\t',HeadMotion(i,:));
            fprintf(fid,'\n');
        end
        fclose(fid);

        
        ExcludeSub_Text=[];
        for ExcludingCriteria=3:-0.5:0.5
            BigHeadMotion=find(HeadMotion(:,1:6)>ExcludingCriteria);
            if ~isempty(BigHeadMotion)
                [II JJ]=ind2sub([AutoDataProcessParameter.SubjectNum,6],BigHeadMotion);
                ExcludeSub=unique(II);
                ExcludeSub_ID=AutoDataProcessParameter.SubjectID(ExcludeSub);
                TempText='';
                for iExcludeSub=1:length(ExcludeSub_ID)
                    TempText=sprintf('%s%s\n',TempText,ExcludeSub_ID{iExcludeSub});
                end
            else
                TempText='None';
            end
            ExcludeSub_Text=sprintf('%s\nExcluding Criteria: %2.1fmm and %2.1f degree in max head motion\n%s\n\n\n',ExcludeSub_Text,ExcludingCriteria,ExcludingCriteria,TempText);
        end
        fid = fopen([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,FunSessionPrefixSet{iFunSession},'ExcludeSubjectsAccordingToMaxHeadMotion.txt'],'at+');
        fprintf(fid,'%s',ExcludeSub_Text);
        fclose(fid);
    end

end
if ~isempty(Error)
    disp(Error);
    return;
end


%Calculate the voxel-specific head motion translation in x, y, z and TDvox, FDvox
%YAN Chao-Gan, 120819
if (AutoDataProcessParameter.IsCalVoxelSpecificHeadMotion==1)
    parfor i=1:AutoDataProcessParameter.SubjectNum
        if 7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i}],'dir')
            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.img']);
            if isempty(DirMean)  %YAN Chao-Gan, 111114. Also support .nii files.
                DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.nii']);
            end
            if ~isempty(DirMean)
                RefFile=[AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirMean(1).name];
            end
            
        end
        
        for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
            
            OutputDir=[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'VoxelSpecificHeadMotion',filesep,AutoDataProcessParameter.SubjectID{i}];
            mkdir(OutputDir);

            DirRP=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,FunSessionPrefixSet{iFunSession},'rp*']);
            RPFile=[AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirRP.name];
            
            [MeanTDvox, MeanFDvox, Header_Out] = y_VoxelSpecificHeadMotion(RPFile,RefFile,OutputDir,0);
            %[MeanTDvox, MeanFDvox, Header_Out] = y_VoxelSpecificHeadMotion(RealignmentParameterFile,ReferenceImage,OutputDir,GZFlag)
            
            % Save the mean TDvox and mean FDvox to folder of "MeanVoxelSpecificHeadMotion"

            if ~(7==exist([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'MeanVoxelSpecificHeadMotion_MeanTDvox'],'dir'))
                mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'MeanVoxelSpecificHeadMotion_MeanTDvox']);
            end
            y_Write4DNIfTI(MeanTDvox,Header_Out,[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'MeanVoxelSpecificHeadMotion_MeanTDvox',filesep,'MeanTDvox_',AutoDataProcessParameter.SubjectID{i},'.nii']);
           
            if ~(7==exist([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'MeanVoxelSpecificHeadMotion_MeanFDvox'],'dir'))
                mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'MeanVoxelSpecificHeadMotion_MeanFDvox']);
            end
            y_Write4DNIfTI(MeanFDvox,Header_Out,[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'MeanVoxelSpecificHeadMotion_MeanFDvox',filesep,'MeanFDvox_',AutoDataProcessParameter.SubjectID{i},'.nii']);

            
            fprintf(['\nGenerate voxel specific head motion: ',AutoDataProcessParameter.SubjectID{i},' ',FunSessionPrefixSet{iFunSession},' OK.\n']);
            
        end
    end
    
end



%Reorient T1 Image Interactively
%Do not need parfor
if (AutoDataProcessParameter.IsNeedReorientT1ImgInteractively==1)
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{1}]);
    DirCo=dir('c*.img');
    if isempty(DirCo)
        DirCo=dir('c*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
        if length(DirCo)==1
            gunzip(DirCo(1).name);
            delete(DirCo(1).name);
        end
        DirCo=dir('c*.nii');  %YAN Chao-Gan, 111114. Also support .nii files.
    end
    if isempty(DirCo)
        DirImg=dir('*.img');
        if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files.
            DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
            if length(DirImg)>=1
                for j=1:length(DirImg)
                    gunzip(DirImg(j).name);
                    delete(DirImg(j).name);
                end
            end
            DirImg=dir('*.nii');
        end
        if length(DirImg)==1
            button = questdlg(['No co* T1 image (T1 image which is reoriented to the nearest orthogonal direction to ''canonical space'' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum) is found. Do you want to use the T1 image without co? Such as: ',DirImg(1).name,'?'],'No co* T1 image is found','Yes','No','Yes');
            if strcmpi(button,'Yes')
                UseNoCoT1Image=1;
            else
                return;
            end
        elseif length(DirImg)==0
            errordlg(['No T1 image has been found.'],'No T1 image has been found');
            return;
        else
            errordlg(['No co* T1 image (T1 image which is reoriented to the nearest orthogonal direction to ''canonical space'' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum) is found. And there are too many T1 images detected in T1Img directory. Please determine which T1 image you want to use and delete the others from the T1Img directory, then re-run the analysis.'],'No co* T1 image is found');
            return;
        end
    else
        UseNoCoT1Image=0;
    end
    cd('..');

    if ~(7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats'],'dir'))
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats']);
    end
    %Reorient
    for i=1:AutoDataProcessParameter.SubjectNum
        if UseNoCoT1Image==0
            DirT1Img=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'c*.img']);
            if isempty(DirT1Img)
                DirT1Img=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'c*.nii.gz']);% Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirT1Img)==1
                    gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirT1Img(1).name]);
                    delete([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirT1Img(1).name]);
                end
                DirT1Img=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'c*.nii']);
            end
        else
            DirT1Img=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.img']);
            if isempty(DirT1Img)
                DirT1Img=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii.gz']);% Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirT1Img)==1
                    gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirT1Img(1).name]);
                    delete([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirT1Img(1).name]);
                end
                DirT1Img=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii']);
            end
        end
        FileList=[{[AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirT1Img(1).name,',1']}];
        fprintf('Reorienting T1 Image Interactively for %s: \n',AutoDataProcessParameter.SubjectID{i});
        global DPARSFA_spm_image_Parameters
        DPARSFA_spm_image_Parameters.ReorientFileList=FileList;
        uiwait(DPARSFA_spm_image('init',[AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirT1Img(1).name]));
        mat=DPARSFA_spm_image_Parameters.ReorientMat;
        save([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats',filesep,AutoDataProcessParameter.SubjectID{i},'_ReorientT1ImgMat.mat'],'mat')
        clear global DPARSFA_spm_image_Parameters
        fprintf('Reorienting T1 Image Interactively for %s: OK\n',AutoDataProcessParameter.SubjectID{i});
    end
end
if ~isempty(Error)
    disp(Error);
    return;
end


%Reorient Functional Images Interactively
%Do not need parfor
if (AutoDataProcessParameter.IsNeedReorientFunImgInteractively==1)
    % Check if mean* image generated in Head Motion Correction exist. Added by YAN Chao-Gan 101010.
    if 7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1}],'dir')
        DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'mean*.img']);
        if isempty(DirMean)  %YAN Chao-Gan, 111114. Also support .nii files.
            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'mean*.nii.gz']);% Search .nii.gz and unzip; YAN Chao-Gan, 120806.
            if length(DirMean)==1
                gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                delete([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
            end
            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'mean*.nii']);
        end
    else
        DirMean=[];
    end
    if isempty(DirMean)
        % Generate mean image. ONLY FOR situation with ONE SESSION.
        cd([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName]);
        for i=1:AutoDataProcessParameter.SubjectNum
            fprintf('\nCalculate mean functional brain (%s) for "%s" since there is no mean* image generated in Head Motion Correction exist.\n',AutoDataProcessParameter.StartingDirName, AutoDataProcessParameter.SubjectID{i});
            cd(AutoDataProcessParameter.SubjectID{i});
            DirImg=dir('*.img');
            if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files.
                DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirImg)==1
                    gunzip(DirImg(1).name);
                    delete(DirImg(1).name);
                end
                DirImg=dir('*.nii');
            end

            if length(DirImg)>1  %3D .img or .nii images.
                [Data, Header] = rest_ReadNiftiImage(DirImg(1).name);
                AllVolume =repmat(Data, [1,1,1, length(DirImg)]);
                for j=2:length(DirImg)
                    [Data, Header] = rest_ReadNiftiImage(DirImg(j).name);
                    AllVolume(:,:,:,j) = Data;
                    if ~mod(j,5)
                        fprintf('.');
                    end
                end
            else %4D .nii images
                [Data, Header] = rest_ReadNiftiImage(DirImg(1).name);
            end
            
            AllVolume=mean(AllVolume,4);
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i}]);
            Header.pinfo = [1;0;0];
            Header.dt    =[16,0];
            rest_WriteNiftiImage(AllVolume,Header,[AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean',AutoDataProcessParameter.SubjectID{i},'img']);
            fprintf('\nMean functional brain (%s) for "%s" saved as: %s\n',AutoDataProcessParameter.StartingDirName, AutoDataProcessParameter.SubjectID{i}, [AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean',AutoDataProcessParameter.SubjectID{i},'img']);
            cd('..');
        end
    end

    if ~(7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats'],'dir'))
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats']);
    end
    %Reorient
    cd([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName]);
    for i=1:AutoDataProcessParameter.SubjectNum
        FileList=[];
        
        % Find the mean* functional image.
        if 7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i}],'dir')
            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.img']);
            if isempty(DirMean)  %YAN Chao-Gan, 111114. Also support .nii files.
                DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.nii']);
            end
            if ~isempty(DirMean)
                FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirMean(1).name,',1']}];
            end
        end

        fprintf('Reorienting Functional Images Interactively for %s: \n',AutoDataProcessParameter.SubjectID{i});
        global DPARSFA_spm_image_Parameters
        DPARSFA_spm_image_Parameters.ReorientFileList=FileList;
        uiwait(DPARSFA_spm_image('init',[AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirMean(1).name,',1']));
        mat=DPARSFA_spm_image_Parameters.ReorientMat;
        save([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats',filesep,AutoDataProcessParameter.SubjectID{i},'_ReorientFunImgMat.mat'],'mat')
        clear global DPARSFA_spm_image_Parameters
        fprintf('Reorienting Functional Images Interactively for %s: OK\n',AutoDataProcessParameter.SubjectID{i});
    end

    % Apply Reorient Mats to functional images and/or the voxel-specific head motion files
    parfor i=1:AutoDataProcessParameter.SubjectNum
        % In case there exist reorient matrix (interactive reorient after head motion correction and before T1-Fun coregistration)
        ReorientMat=eye(4);
        if exist([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats'])==7
            if exist([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats',filesep,AutoDataProcessParameter.SubjectID{i},'_ReorientFunImgMat.mat'])==2
                ReorientMat_Interactively = load([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats',filesep,AutoDataProcessParameter.SubjectID{i},'_ReorientFunImgMat.mat']);
                ReorientMat=ReorientMat_Interactively.mat*ReorientMat;
            end
        end

        if ~all(all(ReorientMat==eye(4)))
            for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
                %Apply to the functional images
                cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}]);
                DirImg=dir('*.img');
                if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files.
                    DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                    if length(DirImg)==1
                        gunzip(DirImg(1).name);
                        delete(DirImg(1).name);
                    end
                    DirImg=dir('*.nii');
                end

                for j=1:length(DirImg)
                    OldMat = spm_get_space(DirImg(j).name);
                    spm_get_space(DirImg(j).name,ReorientMat*OldMat);
                end
                if length(DirImg)==1 % delete the .mat file generated by spm_get_space for 4D nii images
                    if exist([DirImg(j).name(1:end-4),'.mat'])==2
                        delete([DirImg(j).name(1:end-4),'.mat']);
                    end
                end
                
                %Apply to voxel-specific head motion files
                if (7==exist([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'VoxelSpecificHeadMotion',filesep,AutoDataProcessParameter.SubjectID{i}],'dir'))
                    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'VoxelSpecificHeadMotion',filesep,AutoDataProcessParameter.SubjectID{i}]);
                    DirImg=dir('*.nii');
                    
                    for j=1:length(DirImg)
                        OldMat = spm_get_space(DirImg(j).name);
                        spm_get_space(DirImg(j).name,ReorientMat*OldMat);
                        if exist([DirImg(j).name(1:end-4),'.mat'])==2
                            delete([DirImg(j).name(1:end-4),'.mat']);
                        end
                    end
                end
                FileNameTemp = [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'MeanVoxelSpecificHeadMotion_MeanTDvox',filesep,'MeanTDvox_',AutoDataProcessParameter.SubjectID{i},'.nii'];
                if exist(FileNameTemp)==2
                    OldMat = spm_get_space(FileNameTemp);
                    spm_get_space(FileNameTemp,ReorientMat*OldMat);
                end
                FileNameTemp = [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'MeanVoxelSpecificHeadMotion_MeanFDvox',filesep,'MeanFDvox_',AutoDataProcessParameter.SubjectID{i},'.nii'];
                if exist(FileNameTemp)==2
                    OldMat = spm_get_space(FileNameTemp);
                    spm_get_space(FileNameTemp,ReorientMat*OldMat);
                end
                
            end
        end
        
        fprintf('Apply Reorient Mats to functional images for %s: OK\n',AutoDataProcessParameter.SubjectID{i});
    end   
end
if ~isempty(Error)
    disp(Error);
    return;
end


%Coregister T1 Image to Functional space
if (AutoDataProcessParameter.IsNeedT1CoregisterToFun==1)
    %Backup the T1 images to T1ImgCoreg
    % Check if co* image exist. Added by YAN Chao-Gan 100510.
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{1}]);
    DirCo=dir('c*.img');
    if isempty(DirCo)
        DirCo=dir('c*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
        if length(DirCo)==1
            gunzip(DirCo(1).name);
            delete(DirCo(1).name);
        end
        DirCo=dir('c*.nii');  %YAN Chao-Gan, 111114. Also support .nii files.
    end
    if isempty(DirCo)
        DirImg=dir('*.img');
        if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files.
            DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
            if length(DirImg)>=1
                for j=1:length(DirImg)
                    gunzip(DirImg(j).name);
                    delete(DirImg(j).name);
                end
            end
            DirImg=dir('*.nii');
        end
        if length(DirImg)==1
            button = questdlg(['No co* T1 image (T1 image which is reoriented to the nearest orthogonal direction to ''canonical space'' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum) is found. Do you want to use the T1 image without co? Such as: ',DirImg(1).name,'?'],'No co* T1 image is found','Yes','No','Yes');
            if strcmpi(button,'Yes')
                UseNoCoT1Image=1;
            else
                return;
            end
        elseif length(DirImg)==0
            errordlg(['No T1 image has been found.'],'No T1 image has been found');
            return;
        else
            errordlg(['No co* T1 image (T1 image which is reoriented to the nearest orthogonal direction to ''canonical space'' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum) is found. And there are too many T1 images detected in T1Img directory. Please determine which T1 image you want to use and delete the others from the T1Img directory, then re-run the analysis.'],'No co* T1 image is found');
            return;
        end
    else
        UseNoCoT1Image=0;
    end
    
    parfor i=1:AutoDataProcessParameter.SubjectNum
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i}]);
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i}])
        % Check in co* image exist. Added by YAN Chao-Gan 100510.
        if UseNoCoT1Image==0
            DirImg=dir('c*.img');
            if ~isempty(DirImg)  %YAN Chao-Gan, 111114
                copyfile('c*.hdr',[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i}])
                copyfile('c*.img',[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i}])
            else
                DirImg=dir('c*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirImg)==1
                    gunzip(DirImg(1).name);
                    delete(DirImg(1).name);
                end
                copyfile('c*.nii',[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i}])
            end
        else
            DirImg=dir('*.img');
            if ~isempty(DirImg)  %YAN Chao-Gan, 111114
                copyfile('*.hdr',[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i}])
                copyfile('*.img',[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i}])
            else
                DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirImg)>=1
                    for j=1:length(DirImg)
                        gunzip(DirImg(j).name);
                        delete(DirImg(j).name);
                    end
                end
                copyfile('*.nii',[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i}])
            end
        end
        fprintf(['Copying T1 image Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
    
    % Check if mean* image generated in Head Motion Correction exist. Added by YAN Chao-Gan 101010.
    if 7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1}],'dir')
        DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'mean*.img']);
        if isempty(DirMean)  %YAN Chao-Gan, 111114. Also support .nii files.
            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'mean*.nii.gz']);% Search .nii.gz and unzip; YAN Chao-Gan, 120806.
            if length(DirMean)==1
                gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                delete([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
            end
            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'mean*.nii']);
        end
    else
        DirMean=[];
    end
    if isempty(DirMean)
        % Generate mean image. ONLY FOR situation with ONE SESSION.
        cd([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName]);
        for i=1:AutoDataProcessParameter.SubjectNum
            fprintf('\nCalculate mean functional brain (%s) for "%s" since there is no mean* image generated in Head Motion Correction exist.\n',AutoDataProcessParameter.StartingDirName, AutoDataProcessParameter.SubjectID{i});
            cd(AutoDataProcessParameter.SubjectID{i});
            DirImg=dir('*.img');
            if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files.
                DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirImg)==1
                    gunzip(DirImg(1).name);
                    delete(DirImg(1).name);
                end
                DirImg=dir('*.nii');
            end
            
            if length(DirImg)>1  %3D .img or .nii images.
                [Data, Header] = rest_ReadNiftiImage(DirImg(1).name);
                AllVolume =repmat(Data, [1,1,1, length(DirImg)]);
                for j=2:length(DirImg)
                    [Data, Header] = rest_ReadNiftiImage(DirImg(j).name);
                    AllVolume(:,:,:,j) = Data;
                    if ~mod(j,5)
                        fprintf('.');
                    end
                end
            else %4D .nii images
                [Data, Header] = rest_ReadNiftiImage(DirImg(1).name);
            end
            
            AllVolume=mean(AllVolume,4);
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i}]);
            Header.pinfo = [1;0;0];
            Header.dt    =[16,0];
            rest_WriteNiftiImage(AllVolume,Header,[AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean',AutoDataProcessParameter.SubjectID{i},'img']);
            fprintf('\nMean functional brain (%s) for "%s" saved as: %s\n',AutoDataProcessParameter.StartingDirName, AutoDataProcessParameter.SubjectID{i}, [AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean',AutoDataProcessParameter.SubjectID{i},'img']);
            cd('..');
        end
    end

    
    parfor i=1:AutoDataProcessParameter.SubjectNum
        SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Coregister.mat']);
        
        RefDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.img']);
        if isempty(RefDir)  %YAN Chao-Gan, 111114. Also support .nii files.
            RefDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.nii']);
        end
        RefFile=[AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,RefDir(1).name,',1'];
        SourceDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.img']);
        if isempty(SourceDir)  %YAN Chao-Gan, 111114. Also support .nii files.
           SourceDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii']); 
        end
        SourceFile=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,SourceDir(1).name];

        SPMJOB.jobs{1,1}.spatial{1,1}.coreg{1,1}.estimate.ref={RefFile};
        SPMJOB.jobs{1,1}.spatial{1,1}.coreg{1,1}.estimate.source={SourceFile};
        fprintf(['Coregister Setup:',AutoDataProcessParameter.SubjectID{i},' OK\n']);
        if SPMversion==5
            spm_jobman('run',SPMJOB.jobs);
        elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
            SPMJOB.jobs = spm_jobman('spm5tospm8',{SPMJOB.jobs});
            spm_jobman('run',SPMJOB.jobs{1});
        else
            uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
            Error=[Error;{['Error in Coregister T1 Image to Functional space: The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.']}];
        end
    end
end


%Reorient Interactively After Coregistration for better orientation in Segmentation
%Do not need parfor
if (AutoDataProcessParameter.IsNeedReorientInteractivelyAfterCoreg==1)
    
    if ~(7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats'],'dir'))
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats']);
    end
    %Reorient
    cd([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName]);
    for i=1:AutoDataProcessParameter.SubjectNum
        FileList=[];

        DirT1ImgCoreg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.img']);
        if isempty(DirT1ImgCoreg)  %YAN Chao-Gan, 111114. Also support .nii files.
            DirT1ImgCoreg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii.gz']);
            if length(DirT1ImgCoreg)==1
                gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]);
                delete([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]);
            end
            DirT1ImgCoreg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii']);
        end
        FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirT1ImgCoreg(1).name,',1']}];

        % if the mean* functional image exist, then also reorient it.
        if 7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i}],'dir')
            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.img']);
            if isempty(DirMean)  %YAN Chao-Gan, 111114. Also support .nii files.
                DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'mean*.nii.gz']);% Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirMean)==1
                    gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                    delete([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                end
                DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.nii']);
            end
            if ~isempty(DirMean)
                FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirMean(1).name,',1']}];
            end
        end

        fprintf('Reorienting Interactively After Coregistration for %s: \n',AutoDataProcessParameter.SubjectID{i});
        global DPARSFA_spm_image_Parameters
        DPARSFA_spm_image_Parameters.ReorientFileList=FileList;
        uiwait(DPARSFA_spm_image('init',[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirT1ImgCoreg(1).name]));
        mat=DPARSFA_spm_image_Parameters.ReorientMat;
        save([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats',filesep,AutoDataProcessParameter.SubjectID{i},'_ReorientT1FunAfterCoregMat.mat'],'mat')
        clear global DPARSFA_spm_image_Parameters
        fprintf('Reorienting Interactively After Coregistration for %s: OK\n',AutoDataProcessParameter.SubjectID{i});
        cd('..');
    end

    % Apply Reorient Mats (after T1-Fun coregistration) to functional images and/or the voxel-specific head motion files
    parfor i=1:AutoDataProcessParameter.SubjectNum
        % In case there exist reorient matrix (interactive reorient after T1-Fun coregistration)
        ReorientMat=eye(4);
        if exist([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats'])==7
            if exist([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats',filesep,AutoDataProcessParameter.SubjectID{i},'_ReorientT1FunAfterCoregMat.mat'])==2
                ReorientMat_Interactively = load([AutoDataProcessParameter.DataProcessDir,filesep,'ReorientMats',filesep,AutoDataProcessParameter.SubjectID{i},'_ReorientT1FunAfterCoregMat.mat']);
                ReorientMat=ReorientMat_Interactively.mat*ReorientMat;
            end
        end
           
        if ~all(all(ReorientMat==eye(4)))
            for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
                %Apply to the functional images
                cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}]);
                DirImg=dir('*.img');
                if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files.
                    DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                    if length(DirImg)==1
                        gunzip(DirImg(1).name);
                        delete(DirImg(1).name);
                    end
                    DirImg=dir('*.nii');
                end
                
                for j=1:length(DirImg)
                    OldMat = spm_get_space(DirImg(j).name);
                    spm_get_space(DirImg(j).name,ReorientMat*OldMat);
                end
                if length(DirImg)==1 % delete the .mat file generated by spm_get_space for 4D nii images
                    if exist([DirImg(j).name(1:end-4),'.mat'])==2
                        delete([DirImg(j).name(1:end-4),'.mat']);
                    end
                end
                
                %Apply to voxel-specific head motion files
                if (7==exist([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'VoxelSpecificHeadMotion',filesep,AutoDataProcessParameter.SubjectID{i}],'dir'))
                    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'VoxelSpecificHeadMotion',filesep,AutoDataProcessParameter.SubjectID{i}]);
                    DirImg=dir('*.nii');
                    
                    for j=1:length(DirImg)
                        OldMat = spm_get_space(DirImg(j).name);
                        spm_get_space(DirImg(j).name,ReorientMat*OldMat);
                        if exist([DirImg(j).name(1:end-4),'.mat'])==2
                            delete([DirImg(j).name(1:end-4),'.mat']);
                        end
                    end
                end
                FileNameTemp = [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'MeanVoxelSpecificHeadMotion_MeanTDvox',filesep,'MeanTDvox_',AutoDataProcessParameter.SubjectID{i},'.nii'];
                if exist(FileNameTemp)==2
                    OldMat = spm_get_space(FileNameTemp);
                    spm_get_space(FileNameTemp,ReorientMat*OldMat);
                end
                FileNameTemp = [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'MeanVoxelSpecificHeadMotion_MeanFDvox',filesep,'MeanFDvox_',AutoDataProcessParameter.SubjectID{i},'.nii'];
                if exist(FileNameTemp)==2
                    OldMat = spm_get_space(FileNameTemp);
                    spm_get_space(FileNameTemp,ReorientMat*OldMat);
                end
                
            end
        end

        fprintf('Apply Reorient Mats (after T1-Fun coregistration) to functional images for %s: OK\n',AutoDataProcessParameter.SubjectID{i});
    end

end
if ~isempty(Error)
    disp(Error);
    return;
end




% Segmentation
if (AutoDataProcessParameter.IsSegment>=1)
    if AutoDataProcessParameter.IsSegment==1
        T1ImgSegmentDirectoryName = 'T1ImgSegment';
    elseif AutoDataProcessParameter.IsSegment==2
        T1ImgSegmentDirectoryName = 'T1ImgNewSegment';
    end
    if 7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{1}],'dir')
        DirT1ImgCoreg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'*.img']);
        if isempty(DirT1ImgCoreg)  %YAN Chao-Gan, 111114. Also support .nii files.
            DirT1ImgCoreg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'*.nii.gz']);
            if length(DirT1ImgCoreg)==1
                gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirImg(1).name]);
                delete([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirImg(1).name]);
            end
            DirT1ImgCoreg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'*.nii']);
        end
    else
        DirT1ImgCoreg=[];
    end
    if isempty(DirT1ImgCoreg)
        
        %Backup the T1 images to T1ImgSegment or T1ImgNewSegment
        % Check if co* image exist. Added by YAN Chao-Gan 100510.
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{1}]);
        DirCo=dir('c*.img');
        if isempty(DirCo)
            DirCo=dir('c*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
            if length(DirCo)==1
                gunzip(DirCo(1).name);
                delete(DirCo(1).name);
            end
            DirCo=dir('c*.nii');  %YAN Chao-Gan, 111114. Also support .nii files.
        end
        if isempty(DirCo)
            DirImg=dir('*.img');
            if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files.
                DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirImg)>=1
                    for j=1:length(DirImg)
                        gunzip(DirImg(j).name);
                        delete(DirImg(j).name);
                    end
                end
                DirImg=dir('*.nii');
            end
            if length(DirImg)==1
                button = questdlg(['No co* T1 image (T1 image which is reoriented to the nearest orthogonal direction to ''canonical space'' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum) is found. Do you want to use the T1 image without co? Such as: ',DirImg(1).name,'?'],'No co* T1 image is found','Yes','No','Yes');
                if strcmpi(button,'Yes')
                    UseNoCoT1Image=1;
                else
                    return;
                end
            elseif length(DirImg)==0
                errordlg(['No T1 image has been found.'],'No T1 image has been found');
                return;
            else
                errordlg(['No co* T1 image (T1 image which is reoriented to the nearest orthogonal direction to ''canonical space'' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum) is found. And there are too many T1 images detected in T1Img directory. Please determine which T1 image you want to use and delete the others from the T1Img directory, then re-run the analysis.'],'No co* T1 image is found');
                return;
            end
        else
            UseNoCoT1Image=0;
        end
        
        parfor i=1:AutoDataProcessParameter.SubjectNum
            cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img',filesep,AutoDataProcessParameter.SubjectID{i}]);
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i}])
            % Check in co* image exist. Added by YAN Chao-Gan 100510.
            if UseNoCoT1Image==0
                DirImg=dir('c*.img');
                if ~isempty(DirImg)  %YAN Chao-Gan, 111114
                    copyfile('c*.hdr',[AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i}])
                    copyfile('c*.img',[AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i}])
                else
                    DirImg=dir('c*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                    if length(DirImg)==1
                        gunzip(DirImg(1).name);
                        delete(DirImg(1).name);
                    end
                    copyfile('c*.nii',[AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i}])
                end
            else
                DirImg=dir('*.img');
                if ~isempty(DirImg)  %YAN Chao-Gan, 111114
                    copyfile('*.hdr',[AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i}])
                    copyfile('*.img',[AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i}])
                else
                    DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                    if length(DirImg)>=1
                        for j=1:length(DirImg)
                            gunzip(DirImg(j).name);
                            delete(DirImg(j).name);
                        end
                    end
                    copyfile('*.nii',[AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i}])
                end
            end
            fprintf(['Copying T1 image Files from "T1Img" to',T1ImgSegmentDirectoryName,': ',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
        
        
    else  % T1ImgCoreg exists
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg']);
        parfor i=1:AutoDataProcessParameter.SubjectNum
            cd(AutoDataProcessParameter.SubjectID{i});
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i}])
            DirImg=dir('*.img');
            if ~isempty(DirImg)  %YAN Chao-Gan, 111114
                copyfile('*.hdr',[AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i}])
                copyfile('*.img',[AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i}])
            else
                DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirImg)>=1
                    for j=1:length(DirImg)
                        gunzip(DirImg(j).name);
                        delete(DirImg(j).name);
                    end
                end
                copyfile('*.nii',[AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i}])
            end
            cd('..');
            fprintf(['Copying coregistered T1 image Files from "T1ImgCoreg":',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
    end

    if AutoDataProcessParameter.IsSegment==1  %Segment
        cd([AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName]);
        parfor i=1:AutoDataProcessParameter.SubjectNum
            SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Segment.mat']);
            SourceDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.img']);
            if isempty(SourceDir)  %YAN Chao-Gan, 111114. Also support .nii files.
                SourceDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii']);
            end
            SourceFile=[AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,SourceDir(1).name];
            [SPMPath, fileN, extn] = fileparts(which('spm.m'));
            SPMJOB.jobs{1,1}.spatial{1,1}.preproc.opts.tpm={[SPMPath,filesep,'tpm',filesep,'grey.nii'];[SPMPath,filesep,'tpm',filesep,'white.nii'];[SPMPath,filesep,'tpm',filesep,'csf.nii']};
            SPMJOB.jobs{1,1}.spatial{1,1}.preproc.data={SourceFile};
            if strcmpi(AutoDataProcessParameter.Segment.AffineRegularisationInSegmentation,'mni')   %Added by YAN Chao-Gan 091110. Use different Affine Regularisation in Segmentation: East Asian brains (eastern) or European brains (mni).
                SPMJOB.jobs{1,1}.spatial{1,1}.preproc.opts.regtype='mni';
            else
                SPMJOB.jobs{1,1}.spatial{1,1}.preproc.opts.regtype='eastern';
            end
            fprintf(['Segment Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
            
            fprintf('\n');
            if SPMversion==5
                spm_jobman('run',SPMJOB.jobs);
            elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
                SPMJOB.jobs = spm_jobman('spm5tospm8',{SPMJOB.jobs});
                spm_jobman('run',SPMJOB.jobs{1});
            else
                uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
                Error=[Error;{['Error in Segment: The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.']}];
            end
            
        end

    elseif AutoDataProcessParameter.IsSegment==2  %New Segment in SPM8 %YAN Chao-Gan, 111111.

        T1SourceFileSet = cell(AutoDataProcessParameter.SubjectNum,1); % Save to use in the step of DARTEL normalize to MNI
        cd([AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName]);
        parfor i=1:AutoDataProcessParameter.SubjectNum
            
            SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'NewSegment.mat']);
            [SPMPath, fileN, extn] = fileparts(which('spm.m'));
            for T1ImgSegmentDirectoryNameue=1:6
                SPMJOB.matlabbatch{1,1}.spm.tools.preproc8.tissue(1,T1ImgSegmentDirectoryNameue).tpm{1,1}=[SPMPath,filesep,'toolbox',filesep,'Seg',filesep,'TPM.nii',',',num2str(T1ImgSegmentDirectoryNameue)];
                SPMJOB.matlabbatch{1,1}.spm.tools.preproc8.tissue(1,T1ImgSegmentDirectoryNameue).warped = [0 0]; % Do not need warped results. Warp by DARTEL
            end
            if strcmpi(AutoDataProcessParameter.Segment.AffineRegularisationInSegmentation,'mni')   %Added by YAN Chao-Gan 091110. Use different Affine Regularisation in Segmentation: East Asian brains (eastern) or European brains (mni).
                SPMJOB.matlabbatch{1,1}.spm.tools.preproc8.warp.affreg='mni';
            else
                SPMJOB.matlabbatch{1,1}.spm.tools.preproc8.warp.affreg='eastern';
            end

            SourceDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.img']);
            if isempty(SourceDir)  %YAN Chao-Gan, 111114. Also support .nii files.
                SourceDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii']);
            end
            SourceFile=[AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,SourceDir(1).name];

            SPMJOB.matlabbatch{1,1}.spm.tools.preproc8.channel.vols={SourceFile};
            T1SourceFileSet{i} = SourceFile;
            fprintf(['Segment Setup:',AutoDataProcessParameter.SubjectID{i},' OK\n']);
            spm_jobman('run',SPMJOB.matlabbatch);
        end
        
    end
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DARTEL and Normalize VBM results. %YAN Chao-Gan, 111111.
%Do Not Need Parfor
if (AutoDataProcessParameter.IsDARTEL==1)
    %DARTEL: Create Template
    SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Dartel_CreateTemplate.mat']);
    %Look for rc1* and rc2* images.
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment']);
    rc1FileList=[];
    rc2FileList=[];
    for i=1:AutoDataProcessParameter.SubjectNum
        cd(AutoDataProcessParameter.SubjectID{i});
        DirImg=dir('rc1*');
        rc1FileList=[rc1FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]}];
        DirImg=dir('rc2*');
        rc2FileList=[rc2FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]}];
        cd('..');
    end
    SPMJOB.matlabbatch{1,1}.spm.tools.dartel.warp.images{1,1}=rc1FileList;
    SPMJOB.matlabbatch{1,1}.spm.tools.dartel.warp.images{1,2}=rc2FileList;
    fprintf(['Running DARTEL: Create Template.\n']);
    spm_jobman('run',SPMJOB.matlabbatch);
    
    % DARTEL: Normalize to MNI space - GM, WM, CSF and T1 Images.
    SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Dartel_NormaliseToMNI_ManySubjects.mat']);
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment']);
    FlowFieldFileList=[];
    GMFileList=[];
    WMFileList=[];
    CSFFileList=[];
    for i=1:AutoDataProcessParameter.SubjectNum
        cd(AutoDataProcessParameter.SubjectID{i});
        DirImg=dir('u_*');
        FlowFieldFileList=[FlowFieldFileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]}];
        DirImg=dir('c1*');
        GMFileList=[GMFileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]}];
        DirImg=dir('c2*');
        WMFileList=[WMFileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]}];
        DirImg=dir('c3*');
        CSFFileList=[CSFFileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]}];

        if i==1
            DirImg=dir('Template_6.*');
            TemplateFile={[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]};
        end
        cd('..');
    end
    
    SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.template=TemplateFile;
    SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subjs.flowfields=FlowFieldFileList;
    
    SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subjs.images{1,1}=GMFileList;
    SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subjs.images{1,2}=WMFileList;
    SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subjs.images{1,3}=CSFFileList;
    
    fprintf(['Running DARTEL: Normalize to MNI space for VBM. Modulated version With smooth kernel [8 8 8].\n']);
    spm_jobman('run',SPMJOB.matlabbatch);
    
    SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.fwhm=[0 0 0]; % Do not want to perform smooth
    fprintf(['Running DARTEL: Normalize to MNI space for VBM. Modulated version.\n']);
    spm_jobman('run',SPMJOB.matlabbatch);
    
    SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.preserve = 0;
    if exist('T1SourceFileSet','var')
        SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subjs.images{1,4}=T1SourceFileSet;
    end
    fprintf(['Running DARTEL: Normalize to MNI space for VBM. Unmodulated version.\n']);
    spm_jobman('run',SPMJOB.matlabbatch);
    
end




%%%%%%%%
% Warp the common-used masks into original space
% YAN Chao-Gan, 120822.

if (AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==1) || ((AutoDataProcessParameter.IsCovremove==1) && (strcmpi(AutoDataProcessParameter.Covremove.Timing,'AfterRealign')))
    if ~(2==exist([AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,AutoDataProcessParameter.SubjectID{1},'_','BrainMask_05_91x109x91','.nii'],'file'))
        % If have not warped by previous analysis.
        
        MasksName{1,1}=[ProgramPath,filesep,'Templates',filesep,'BrainMask_05_91x109x91.img'];
        MasksName{2,1}=[ProgramPath,filesep,'Templates',filesep,'CsfMask_07_91x109x91.img'];
        MasksName{3,1}=[ProgramPath,filesep,'Templates',filesep,'WhiteMask_09_91x109x91.img'];
        MasksName{4,1}=[ProgramPath,filesep,'Templates',filesep,'GreyMask_02_91x109x91.img'];
        
        if (isfield(AutoDataProcessParameter,'MaskFile')) && (~isempty(AutoDataProcessParameter.MaskFile)) && (~isequal(AutoDataProcessParameter.MaskFile, 'Default'))
            MasksName{5,1}=AutoDataProcessParameter.MaskFile;
        end
        
        if ~(7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'Masks'],'dir'))
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'Masks']);
        end
        
        if (7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1}],'dir')) 
            % If is processed by New Segment and DARTEL
            
            TemplateDir_SubID=AutoDataProcessParameter.SubjectID{1};
            
            DARTELTemplateFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,TemplateDir_SubID,filesep,'Template_6.nii'];
            DARTELTemplateMatFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,TemplateDir_SubID,filesep,'Template_6_2mni.mat'];
            
            Interp=0;
            
            parfor i=1:AutoDataProcessParameter.SubjectNum
                
                DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'u_*']);
                FlowFieldFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name];

                % Set the reference image
                DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.img']);
                if isempty(DirMean)  %YAN Chao-Gan, 111114. Also support .nii files.
                    DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'mean*.nii.gz']);% Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                    if length(DirMean)==1
                        gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                        delete([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                    end
                    DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.nii']);
                end
                RefFile = [AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirMean(1).name];
                
                OutFile=[];
                for iMask=1:length(MasksName)
                    AMaskFilename = MasksName{iMask};
                    fprintf('\nWarp Masks (%s) for "%s" to individual space using DARTEL flow field (in T1ImgNewSegment) genereated by DARTEL.\n',AMaskFilename, AutoDataProcessParameter.SubjectID{i});
                    [pathstr, name, ext] = fileparts(AMaskFilename);
                    OutFile{iMask,1}=[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,AutoDataProcessParameter.SubjectID{i},'_',name,'.nii'];
                end
                
                y_WarpBackByDARTEL(MasksName,OutFile,RefFile,DARTELTemplateFilename,DARTELTemplateMatFilename,FlowFieldFilename,Interp);
                
            end
            
            
        elseif (7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{1}],'dir'))
            % If is processed by unified segmentation
            
            parfor i=1:AutoDataProcessParameter.SubjectNum
                
                % Set the reference image
                DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.img']);
                if isempty(DirMean)  %YAN Chao-Gan, 111114. Also support .nii files.
                    DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'mean*.nii.gz']);% Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                    if length(DirMean)==1
                        gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                        delete([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                    end
                    DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.nii']);
                end
                RefFile = [AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirMean(1).name];
                
                MatFileDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*seg_inv_sn.mat']);
                MatFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,MatFileDir(1).name];
                
                for iMask=1:length(MasksName)
                    AMaskFilename = MasksName{iMask};
                    fprintf('\nWarp Masks (%s) for "%s" to individual space using *seg_inv_sn.mat (in T1ImgSegment) genereated by T1 image segmentation.\n',AMaskFilename, AutoDataProcessParameter.SubjectID{i});
                    
                    [pathstr, name, ext] = fileparts(AMaskFilename);
                    
                    WarpedMaskName=[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,AutoDataProcessParameter.SubjectID{i},'_',name,'.nii'];
                    
                    y_NormalizeWrite(AMaskFilename,WarpedMaskName,RefFile,MatFilename,0);
                    AMaskFilename=WarpedMaskName;
                    
                end
                
            end
            
        end
        
    end
end



%Deal with the other covariables mask: warp into original space
if (AutoDataProcessParameter.IsCovremove==1) && ((strcmpi(AutoDataProcessParameter.Covremove.Timing,'AfterRealign'))||(AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==1))
    
    if ~isempty(AutoDataProcessParameter.Covremove.OtherCovariatesROI)
        
        if ~(7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'Masks'],'dir'))
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'Masks']);
        end
        
        % Check if masks appropriate %This can be used as a function!!! % ONLY WARP!!!
        OtherCovariatesROIForEachSubject=cell(AutoDataProcessParameter.SubjectNum,1);
        parfor i=1:AutoDataProcessParameter.SubjectNum
            Suffix='OtherCovariateROI_'; %%!!! Change as in Function
            SubjectROI=AutoDataProcessParameter.Covremove.OtherCovariatesROI;%%!!! Change as in Fuction

            % Set the reference image
            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.img']);
            if isempty(DirMean)  %YAN Chao-Gan, 111114. Also support .nii files.
                DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'mean*.nii.gz']);% Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirMean)==1
                    gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                    delete([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                end
                DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.nii']);
            end
            RefFile = [AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirMean(1).name];

            % Ball to mask
            for iROI=1:length(SubjectROI)
                if rest_SphereROI( 'IsBallDefinition', SubjectROI{iROI})
                    ROIMaskName=[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,Suffix,num2str(iROI),'_',AutoDataProcessParameter.SubjectID{i},'.nii'];
                    [MNIData MNIVox MNIHeader]=rest_readfile([ProgramPath,filesep,'Templates',filesep,'aal.nii']);
                    rest_Y_SphereROI( 'BallDefinition2Mask' , SubjectROI{iROI}, size(MNIData), MNIVox, MNIHeader, ROIMaskName);
                    SubjectROI{iROI}=[ROIMaskName];
                end
            end

            %Need to warp masks
            % Check if have .txt file. Note: the txt files should be put the last of the ROI definition
            NeedWarpMaskNameSet=[];
            WarpedMaskNameSet=[];
            for iROI=1:length(SubjectROI)
                if exist(SubjectROI{iROI},'file')==2
                    [pathstr, name, ext] = fileparts(SubjectROI{iROI});
                    if (~strcmpi(ext, '.txt'))
                        NeedWarpMaskNameSet=[NeedWarpMaskNameSet;{SubjectROI{iROI}}];
                        WarpedMaskNameSet=[WarpedMaskNameSet;{[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,Suffix,num2str(iROI),'_',AutoDataProcessParameter.SubjectID{i},'.nii']}];
                        
                        SubjectROI{iROI}=[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,Suffix,num2str(iROI),'_',AutoDataProcessParameter.SubjectID{i},'.nii'];
                    end
                end
            end

            if (7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1}],'dir'))
                % If is processed by New Segment and DARTEL
                
                TemplateDir_SubID=AutoDataProcessParameter.SubjectID{1};
                
                DARTELTemplateFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,TemplateDir_SubID,filesep,'Template_6.nii'];
                DARTELTemplateMatFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,TemplateDir_SubID,filesep,'Template_6_2mni.mat'];
                
                DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'u_*']);
                FlowFieldFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name];
                
                
                y_WarpBackByDARTEL(NeedWarpMaskNameSet,WarpedMaskNameSet,RefFile,DARTELTemplateFilename,DARTELTemplateMatFilename,FlowFieldFilename,0);
                
                for iROI=1:length(NeedWarpMaskNameSet)
                    fprintf('\nWarp %s Mask (%s) for "%s" to individual space using DARTEL flow field (in T1ImgNewSegment) genereated by DARTEL.\n',Suffix,NeedWarpMaskNameSet{iROI}, AutoDataProcessParameter.SubjectID{i});
                end
                
            elseif (7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{1}],'dir'))
                % If is processed by unified segmentation
                
                MatFileDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*seg_inv_sn.mat']);
                MatFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,MatFileDir(1).name];
                
                for iROI=1:length(NeedWarpMaskNameSet)
                    y_NormalizeWrite(NeedWarpMaskNameSet{iROI},WarpedMaskNameSet{iROI},RefFile,MatFilename,0);
                    fprintf('\nWarp %s Mask (%s) for "%s" to individual space using *seg_inv_sn.mat (in T1ImgSegment) genereated by T1 image segmentation.\n',Suffix,NeedWarpMaskNameSet{iROI}, AutoDataProcessParameter.SubjectID{i});
                end
                
            end
            
            
            % Check if the text file is a definition for multiple subjects. i.e., the first line is 'Covariables_List:', then get the corresponded covariables file
            for iROI=1:length(SubjectROI)
                if (ischar(SubjectROI{iROI})) && (exist(SubjectROI{iROI},'file')==2)
                    [pathstr, name, ext] = fileparts(SubjectROI{iROI});
                    if (strcmpi(ext, '.txt'))
                        fid = fopen(SubjectROI{iROI});
                        SeedTimeCourseList=textscan(fid,'%s','\n');
                        fclose(fid);
                        if strcmpi(SeedTimeCourseList{1}{1},'Covariables_List:')
                            SubjectROI{iROI}=SeedTimeCourseList{1}{i+1};
                        end
                    end
                end
                
            end
            
            OtherCovariatesROIForEachSubject{i}=SubjectROI; %%!!! Change as in Fuction

        end
        
        AutoDataProcessParameter.Covremove.OtherCovariatesROIForEachSubject = OtherCovariatesROIForEachSubject;
    end
end


%Remove the nuisance Covaribles
if (AutoDataProcessParameter.IsCovremove==1) && (strcmpi(AutoDataProcessParameter.Covremove.Timing,'AfterRealign'))
    
    %Remove the Covariables
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor i=1:AutoDataProcessParameter.SubjectNum
            
            CovariablesDef=[];
            
            %Polynomial trends
            %0: constant
            %1: constant + linear trend
            %2: constant + linear trend + quadratic trend.
            %3: constant + linear trend + quadratic trend + cubic trend.   ...
            
            CovariablesDef.polort = AutoDataProcessParameter.Covremove.PolynomialTrend;

            %Head Motion Regressors
            ImgCovModel = 1; %Default
            CovariablesDef.CovMat=[];
            if (AutoDataProcessParameter.Covremove.HeadMotion==1) %1: Use the current time point of rigid-body 6 realign parameters. e.g., Txi, Tyi, Tzi...
                DirRP=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,FunSessionPrefixSet{iFunSession},'rp*']);
                Q1=load([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirRP.name]);
                CovariablesDef.CovMat = Q1;
            elseif (AutoDataProcessParameter.Covremove.HeadMotion==2) %2: Use the current time point and the previous time point of rigid-body 6 realign parameters. e.g., Txi, Tyi, Tzi,..., Txi-1, Tyi-1, Tzi-1...
                DirRP=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,FunSessionPrefixSet{iFunSession},'rp*']);
                Q1=load([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirRP.name]);
                CovariablesDef.CovMat = [Q1, [zeros(1,size(Q1,2));Q1(1:end-1,:)]];
            elseif (AutoDataProcessParameter.Covremove.HeadMotion==3) %3: Use the current time point and their squares of rigid-body 6 realign parameters. e.g., Txi, Tyi, Tzi,..., Txi^2, Tyi^2, Tzi^2...
                DirRP=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,FunSessionPrefixSet{iFunSession},'rp*']);
                Q1=load([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirRP.name]);
                CovariablesDef.CovMat = [Q1,  Q1.^2];
            elseif (AutoDataProcessParameter.Covremove.HeadMotion==4) %4: Use the Friston 24-parameter model: current time point, the previous time point and their squares of rigid-body 6 realign parameters. e.g., Txi, Tyi, Tzi, ..., Txi-1, Tyi-1, Tzi-1,... and their squares (total 24 items). Friston autoregressive model (Friston, K.J., Williams, S., Howard, R., Frackowiak, R.S., Turner, R., 1996. Movement-related effects in fMRI time-series. Magn Reson Med 35, 346-355.)
                DirRP=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,FunSessionPrefixSet{iFunSession},'rp*']);
                Q1=load([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirRP.name]);
                CovariablesDef.CovMat = [Q1, [zeros(1,size(Q1,2));Q1(1:end-1,:)], Q1.^2, [zeros(1,size(Q1,2));Q1(1:end-1,:)].^2];
            elseif (AutoDataProcessParameter.Covremove.HeadMotion>=11) %11-14: Use the voxel-specific models. 14 is the voxel-specific 12 model.
                
                HMvoxDir=[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'VoxelSpecificHeadMotion',filesep,AutoDataProcessParameter.SubjectID{i}];
                
                CovariablesDef.CovImgDir = {[HMvoxDir,filesep,'HMvox_X_4DVolume.nii'];[HMvoxDir,filesep,'HMvox_Y_4DVolume.nii'];[HMvoxDir,filesep,'HMvox_Z_4DVolume.nii']};
                
                ImgCovModel = AutoDataProcessParameter.Covremove.HeadMotion - 10;
                
            end
            
            
            %Head Motion "Scrubbing" Regressors: each bad time point is a separate regressor
            if (AutoDataProcessParameter.Covremove.IsHeadMotionScrubbingRegressors==1)

                % Use FD Power
                FD = load([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,FunSessionPrefixSet{iFunSession},'FD_Power_',AutoDataProcessParameter.SubjectID{i},'.txt']);
                
                TemporalMask=ones(length(FD),1);
                Index=find(FD > AutoDataProcessParameter.Covremove.HeadMotionScrubbingRegressors.FDThreshold);
                TemporalMask(Index)=0;
                IndexPrevious=Index;
                for iP=1:AutoDataProcessParameter.Covremove.HeadMotionScrubbingRegressors.PreviousPoints
                    IndexPrevious=IndexPrevious-1;
                    IndexPrevious=IndexPrevious(IndexPrevious>=1);
                    TemporalMask(IndexPrevious)=0;
                end
                IndexNext=Index;
                for iN=1:AutoDataProcessParameter.Covremove.HeadMotionScrubbingRegressors.LaterPoints
                    IndexNext=IndexNext+1;
                    IndexNext=IndexNext(IndexNext<=length(FD));
                    TemporalMask(IndexNext)=0;
                end
                
                BadTimePointsIndex = find(TemporalMask==0);
                BadTimePointsRegressor = zeros(length(FD),length(BadTimePointsIndex));
                for iBadTimePoints = 1:length(BadTimePointsIndex)
                    BadTimePointsRegressor(BadTimePointsIndex(iBadTimePoints),iBadTimePoints) = 1;
                end
                
                CovariablesDef.CovMat = [CovariablesDef.CovMat, BadTimePointsRegressor];
            end

            
            %Mask covariates
            SubjectCovariatesROI=[];
            if (AutoDataProcessParameter.Covremove.WholeBrain==1)
                SubjectCovariatesROI=[SubjectCovariatesROI;{[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,AutoDataProcessParameter.SubjectID{i},'_BrainMask_05_91x109x91.nii']}];
            end
            if (AutoDataProcessParameter.Covremove.CSF==1)
                SubjectCovariatesROI=[SubjectCovariatesROI;{[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,AutoDataProcessParameter.SubjectID{i},'_CsfMask_07_91x109x91.nii']}];
            end
            if (AutoDataProcessParameter.Covremove.WhiteMatter==1)
                SubjectCovariatesROI=[SubjectCovariatesROI;{[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,AutoDataProcessParameter.SubjectID{i},'_WhiteMask_09_91x109x91.nii']}];
            end

            % Add the other Covariate ROIs
            if ~isempty(AutoDataProcessParameter.Covremove.OtherCovariatesROI)
                SubjectCovariatesROI=[SubjectCovariatesROI;AutoDataProcessParameter.Covremove.OtherCovariatesROIForEachSubject{i}];
            end
            
            %Extract Time course for the Mask covariates
            if ~isempty(SubjectCovariatesROI)
                if ~(7==exist([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'Covs'],'dir'))
                    mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'Covs']);
                end

                y_ExtractROISignal([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}], SubjectCovariatesROI, [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'Covs',filesep,AutoDataProcessParameter.SubjectID{i}], '', 1);             
                
                CovariablesDef.ort_file=[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'Covs',filesep,'ROISignals_',AutoDataProcessParameter.SubjectID{i},'.txt'];
            end
            
            
            %Regressing out the covariates
            fprintf('\nRegressing out covariates for subject %s %s.\n',AutoDataProcessParameter.SubjectID{i},FunSessionPrefixSet{iFunSession});
            y_RegressOutImgCovariates([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}],CovariablesDef,'_Covremoved','', ImgCovModel);
            
        end
        fprintf('\n');
    end
    
    
    %Copy the Covariates Removed files to DataProcessDir\{AutoDataProcessParameter.StartingDirName}+C
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor i=1:AutoDataProcessParameter.SubjectNum
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'C',filesep,AutoDataProcessParameter.SubjectID{i}])
            movefile([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}, '_Covremoved',filesep,'*'],[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'C',filesep,AutoDataProcessParameter.SubjectID{i}])

            rmdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}, '_Covremoved']);
            fprintf(['Moving Coviables Removed Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
    end
    AutoDataProcessParameter.StartingDirName=[AutoDataProcessParameter.StartingDirName,'C']; %Now StartingDirName is with new suffix 'C'
    
end


%Filter
if (AutoDataProcessParameter.IsFilter==1) && (strcmpi(AutoDataProcessParameter.Filter.Timing,'BeforeNormalize'))
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor i=1:AutoDataProcessParameter.SubjectNum

            if AutoDataProcessParameter.TR==0  % Need to retrieve the TR information from the NIfTI images
                TR = AutoDataProcessParameter.TRSet(iFunSession,i)
            else
                TR = AutoDataProcessParameter.TR;
            end
            
            
            y_bandpass([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}], ...
                TR, ...  
                AutoDataProcessParameter.Filter.ALowPass_HighCutoff, ...
                AutoDataProcessParameter.Filter.AHighPass_LowCutoff, ...
                AutoDataProcessParameter.Filter.AAddMeanBack, ...   %Revised by YAN Chao-Gan,100420. In according to the change of rest_bandpass.m. %AutoDataProcessParameter.Filter.ARetrend, ...
                ''); % Just don't use mask in filtering. %AutoDataProcessParameter.Filter.AMaskFilename);
        end
    end
    
    %Copy the Filtered files to DataProcessDir\{AutoDataProcessParameter.StartingDirName}+F
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor i=1:AutoDataProcessParameter.SubjectNum
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'F',filesep,AutoDataProcessParameter.SubjectID{i}])
            movefile([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}, '_filtered',filesep,'*'],[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'F',filesep,AutoDataProcessParameter.SubjectID{i}])

            rmdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}, '_filtered']);
            fprintf(['Moving Filtered Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
    end
    AutoDataProcessParameter.StartingDirName=[AutoDataProcessParameter.StartingDirName,'F']; %Now StartingDirName is with new suffix 'F'
    
end
    


%Normalize on functional data
if (AutoDataProcessParameter.IsNormalize>0) && strcmpi(AutoDataProcessParameter.Normalize.Timing,'OnFunctionalData')
    parfor i=1:AutoDataProcessParameter.SubjectNum
        FileList=[];
        for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
            cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}]);
            DirImg=dir('*.img');
            if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files. % Either in .nii.gz or in .nii
                DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirImg)==1
                    gunzip(DirImg(1).name);
                    delete(DirImg(1).name);
                end
                DirImg=dir('*.nii');
            end
            
            if length(DirImg)>1  %3D .img or .nii images.
                if AutoDataProcessParameter.TimePoints>0 && length(DirImg)~=AutoDataProcessParameter.TimePoints % Will not check if TimePoints set to 0. YAN Chao-Gan 120806.
                    Error=[Error;{['Error in Normalize, time point number doesn''t match: ',AutoDataProcessParameter.SubjectID{i}]}];
                end
                FileList=[];
                for j=1:length(DirImg)
                    FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(j).name]}];
                end
            else %4D .nii images
                Nii  = nifti(DirImg(1).name);
                if AutoDataProcessParameter.TimePoints>0 && size(Nii.dat,4)~=AutoDataProcessParameter.TimePoints % Will not check if TimePoints set to 0. YAN Chao-Gan 120806.
                    Error=[Error;{['Error in Normalize, time point number doesn''t match: ',AutoDataProcessParameter.SubjectID{i}]}];
                end
                FileList={[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]};
            end
        end
        
        % Set the mean functional image % YAN Chao-Gan, 120826
        DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.img']);
        if isempty(DirMean)  %YAN Chao-Gan, 111114. Also support .nii files.
            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'mean*.nii.gz']);% Search .nii.gz and unzip; YAN Chao-Gan, 120806.
            if length(DirMean)==1
                gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                delete([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
            end
            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.nii']);
        end
        MeanFilename = [AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirMean(1).name];
        
        FileList=[FileList;{MeanFilename}]; %YAN Chao-Gan, 120826. Also normalize the mean functional image.
        
    
        if (AutoDataProcessParameter.IsNormalize==1) %Normalization by using the EPI template directly
            
            SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Normalize.mat']);
            
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.subj(1,1).source={MeanFilename};
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.subj(1,1).resample=FileList;
            
            [SPMPath, fileN, extn] = fileparts(which('spm.m'));
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.eoptions.template={[SPMPath,filesep,'templates',filesep,'EPI.nii,1']};
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.roptions.bb=AutoDataProcessParameter.Normalize.BoundingBox;
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.roptions.vox=AutoDataProcessParameter.Normalize.VoxSize;
            
            fprintf(['Normalize:',AutoDataProcessParameter.SubjectID{i},' OK\n']);
            if SPMversion==5
                spm_jobman('run',SPMJOB.jobs);
            elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
                SPMJOB.jobs = spm_jobman('spm5tospm8',{SPMJOB.jobs});
                spm_jobman('run',SPMJOB.jobs{1});
            else
                uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
                Error=[Error;{['Error in Normalize: The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.']}];
            end
            
        end
        
        if (AutoDataProcessParameter.IsNormalize==2) %Normalization by using the T1 image segment information
            %Normalize-Write: Using the segment information
            SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Normalize_Write.mat']);
            
            MatFileDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*seg_sn.mat']);
            MatFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,MatFileDir(1).name];
            
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.write.subj.matname={MatFilename};
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.write.subj.resample=FileList;
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.write.roptions.bb=AutoDataProcessParameter.Normalize.BoundingBox;
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.write.roptions.vox=AutoDataProcessParameter.Normalize.VoxSize;
            fprintf(['Normalize-Write:',AutoDataProcessParameter.SubjectID{i},' OK\n']);
            
            if SPMversion==5
                spm_jobman('run',SPMJOB.jobs);
            elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
                SPMJOB.jobs = spm_jobman('spm5tospm8',{SPMJOB.jobs});
                spm_jobman('run',SPMJOB.jobs{1});
            else
                uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
                Error=[Error;{['Error in Normalize: The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.']}];
            end
        end
        
        if (AutoDataProcessParameter.IsNormalize==3) %Normalization by using DARTEL %YAN Chao-Gan, 111111.
            
            SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Dartel_NormaliseToMNI_FewSubjects.mat']);
            
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.fwhm=[0 0 0];
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.preserve=0;
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.bb=AutoDataProcessParameter.Normalize.BoundingBox;
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.vox=AutoDataProcessParameter.Normalize.VoxSize;
            
            DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'Template_6.*']);
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.template={[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirImg(1).name]};
            
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subj(1,1).images=FileList;
            
            DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'u_*']);
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subj(1,1).flowfield={[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]};
            
            spm_jobman('run',SPMJOB.matlabbatch);
            fprintf(['Normalization by using DARTEL:',AutoDataProcessParameter.SubjectID{i},' OK\n']);
        end
    end
    
    %Copy the Normalized files to DataProcessDir\{AutoDataProcessParameter.StartingDirName}+W
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor i=1:AutoDataProcessParameter.SubjectNum
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'W',filesep,AutoDataProcessParameter.SubjectID{i}])
            movefile([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'w*'],[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'W',filesep,AutoDataProcessParameter.SubjectID{i}])
            fprintf(['Moving Normalized Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
    end
    AutoDataProcessParameter.StartingDirName=[AutoDataProcessParameter.StartingDirName,'W']; %Now StartingDirName is with new suffix 'W'
    
    
    % Don't do this (Delete files before normalization) anymore: YAN Chao-Gan, 120826
%     %Delete files before normalization
%     if AutoDataProcessParameter.IsDelFilesBeforeNormalize==1
%         for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
%             cd(AutoDataProcessParameter.DataProcessDir);
%             if (AutoDataProcessParameter.IsSliceTiming==1) || (AutoDataProcessParameter.IsRealign==1)
%                 rmdir([FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName(1:end-1)],'s')
%                 if (AutoDataProcessParameter.IsSliceTiming==1) && (AutoDataProcessParameter.IsRealign==1)
%                     rmdir([FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName(1:end-2)],'s')
%                 end
%             end
%         end
%     end
    

    %Generate the pictures for checking normalization %YAN Chao-Gan, 091001
    mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'PicturesForChkNormalization']);
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'PicturesForChkNormalization']);
    if license('test','image_toolbox') % Added by YAN Chao-Gan, 100420.
        global DPARSF_rest_sliceviewer_Cfg;
        h=DPARSF_rest_sliceviewer;
        [RESTPath, fileN, extn] = fileparts(which('rest.m'));
        Ch2Filename=[RESTPath,filesep,'Template',filesep,'ch2.nii'];
        set(DPARSF_rest_sliceviewer_Cfg.Config(1).hOverlayFile, 'String', Ch2Filename);
        DPARSF_rest_sliceviewer_Cfg.Config(1).Overlay.Opacity=0.2;
        DPARSF_rest_sliceviewer('ChangeOverlay', h);
        
        for i=1:AutoDataProcessParameter.SubjectNum
            
            %                 Dir=dir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.img']);
            %                 if isempty(Dir)  %YAN Chao-Gan, 111114. Also support .nii files.
            %                     Dir=dir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii']);
            %                 end
            %                 Filename=[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,Dir(1).name];
            
            % Set the normalized mean functional image instead of the first normalized volume to get pictures % YAN Chao-Gan, 120826
            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'wmean*.img']);
            if isempty(DirMean)  %YAN Chao-Gan, 111114. Also support .nii files.
                DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'wmean*.nii.gz']);% Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirMean)==1
                    gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                    delete([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                end
                DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'wmean*.nii']);
            end
            Filename = [AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirMean(1).name];
            
            % Revised by YAN Chao-Gan, 100420. Fixed a bug in displaying overlay with different bounding box from those of underlay in according to rest_sliceviewer.m
            DPARSF_Normalized_TempImage =fullfile(tempdir,['DPARSF_Normalized_TempImage','_',rest_misc('GetCurrentUser'),'.img']);
            y_Reslice(Filename,DPARSF_Normalized_TempImage,[1 1 1],0);
            set(DPARSF_rest_sliceviewer_Cfg.Config(1).hUnderlayFile, 'String', DPARSF_Normalized_TempImage);
            set(DPARSF_rest_sliceviewer_Cfg.Config(1).hMagnify ,'Value',2);
            %             set(DPARSF_rest_sliceviewer_Cfg.Config(1).hUnderlayFile, 'String', Filename);
            %             set(DPARSF_rest_sliceviewer_Cfg.Config(1).hMagnify ,'Value',4);
            DPARSF_rest_sliceviewer('ChangeUnderlay', h);
            eval(['print(''-dtiff'',''-r100'',''',FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.SubjectID{i},'.tif'',h);']);
            fprintf(['Generating the pictures for checking normalization: ',AutoDataProcessParameter.SubjectID{i},' OK']);
        end

        close(h);
        fprintf('\n');
    else  % Added by YAN Chao-Gan, 100420.
        fprintf('Since Image Processing Toolbox of MATLAB is not valid, the pictures for checking normalization will not be generated.\n');
        fid = fopen('Warning.txt','at+');
        fprintf(fid,'%s','Since Image Processing Toolbox of MATLAB is not valid, the pictures for checking normalization will not be generated.\n');
        fclose(fid);
    end
end
if ~isempty(Error)
    disp(Error);
    return;
end



%Smooth on functional data
if (AutoDataProcessParameter.IsSmooth>=1) && strcmpi(AutoDataProcessParameter.Smooth.Timing,'OnFunctionalData')
    if (AutoDataProcessParameter.IsSmooth==1)
        parfor i=1:AutoDataProcessParameter.SubjectNum

            FileList=[];
            for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
                cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}]);
                DirImg=dir('*.img');
                if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files. % Either in .nii.gz or in .nii
                    DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                    if length(DirImg)==1
                        gunzip(DirImg(1).name);
                        delete(DirImg(1).name);
                    end
                    DirImg=dir('*.nii');
                end
                
                if length(DirImg)>1  %3D .img or .nii images.
                    if AutoDataProcessParameter.TimePoints>0 && length(DirImg)~=AutoDataProcessParameter.TimePoints % Will not check if TimePoints set to 0. YAN Chao-Gan 120806.
                        Error=[Error;{['Error in Normalize: ',AutoDataProcessParameter.SubjectID{i}]}];
                    end
                    FileList=[];
                    for j=1:length(DirImg)
                        FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(j).name]}];
                    end
                else %4D .nii images
                    Nii  = nifti(DirImg(1).name);
                    if AutoDataProcessParameter.TimePoints>0 && size(Nii.dat,4)~=AutoDataProcessParameter.TimePoints % Will not check if TimePoints set to 0. YAN Chao-Gan 120806.
                        Error=[Error;{['Error in Normalize: ',AutoDataProcessParameter.SubjectID{i}]}];
                    end
                    FileList={[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]};
                end
            end

            SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Smooth.mat']);
            SPMJOB.jobs{1,1}.spatial{1,1}.smooth.data = FileList;
            SPMJOB.jobs{1,1}.spatial{1,1}.smooth.fwhm = AutoDataProcessParameter.Smooth.FWHM;
            if SPMversion==5
                spm_jobman('run',SPMJOB.jobs);
            elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
                SPMJOB.jobs = spm_jobman('spm5tospm8',{SPMJOB.jobs});
                spm_jobman('run',SPMJOB.jobs{1});
            else
                uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
            end

            fprintf(['Smooth:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        
    elseif (AutoDataProcessParameter.IsSmooth==2)   %YAN Chao-Gan, 111111. Smooth by DARTEL. The smoothing that is a part of the normalization to MNI space computes these average intensities from the original data, rather than the warped versions. When the data are warped, some voxels will grow and others will shrink. This will change the regional averages, with more weighting towards those voxels that have grows.

        parfor i=1:AutoDataProcessParameter.SubjectNum
            SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Dartel_NormaliseToMNI_FewSubjects.mat']);
            
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.fwhm=AutoDataProcessParameter.Smooth.FWHM;
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.preserve=0;
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.bb=AutoDataProcessParameter.Normalize.BoundingBox;
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.vox=AutoDataProcessParameter.Normalize.VoxSize;
            
            DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'Template_6.*']);
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.template={[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirImg(1).name]};
            
            
            FileList=[];
            for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
                cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName(1:end-1),filesep,AutoDataProcessParameter.SubjectID{i}]);
                DirImg=dir('*.img');
                if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files. % Either in .nii.gz or in .nii
                    DirImg=dir('*.nii.gz');  % Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                    if length(DirImg)==1
                        gunzip(DirImg(1).name);
                        delete(DirImg(1).name);
                    end
                    DirImg=dir('*.nii');
                end
                
                if length(DirImg)>1  %3D .img or .nii images.
                    if AutoDataProcessParameter.TimePoints>0 && length(DirImg)~=AutoDataProcessParameter.TimePoints % Will not check if TimePoints set to 0. YAN Chao-Gan 120806.
                        Error=[Error;{['Error in Normalize: ',AutoDataProcessParameter.SubjectID{i}]}];
                    end
                    FileList=[];
                    for j=1:length(DirImg)
                        FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName(1:end-1),filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(j).name]}];
                    end
                else %4D .nii images
                    Nii  = nifti(DirImg(1).name);
                    if AutoDataProcessParameter.TimePoints>0 && size(Nii.dat,4)~=AutoDataProcessParameter.TimePoints % Will not check if TimePoints set to 0. YAN Chao-Gan 120806.
                        Error=[Error;{['Error in Normalize: ',AutoDataProcessParameter.SubjectID{i}]}];
                    end
                    FileList={[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName(1:end-1),filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]};
                end
            end

            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subj(1,1).images=FileList;
            
            DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'u_*']);
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subj(1,1).flowfield={[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]};
            
            spm_jobman('run',SPMJOB.matlabbatch);
            fprintf(['Smooth by using DARTEL:',AutoDataProcessParameter.SubjectID{i},' OK\n']);
        end

    end

    %Copy the Smoothed files to DataProcessDir\{AutoDataProcessParameter.StartingDirName}+S
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor i=1:AutoDataProcessParameter.SubjectNum
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'S',filesep,AutoDataProcessParameter.SubjectID{i}])
            
            if (AutoDataProcessParameter.IsSmooth==1)
                movefile([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'s*'],[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'S',filesep,AutoDataProcessParameter.SubjectID{i}])
            elseif (AutoDataProcessParameter.IsSmooth==2) % If smoothed by DARTEL, then the smoothed files still under realign directory.
                movefile([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName(1:end-1),filesep,AutoDataProcessParameter.SubjectID{i},filesep,'s*'],[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'S',filesep,AutoDataProcessParameter.SubjectID{i}])
            end
            fprintf(['Moving Smoothed Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
    end
    
    AutoDataProcessParameter.StartingDirName=[AutoDataProcessParameter.StartingDirName,'S']; %Now StartingDirName is with new suffix 'S'
end
if ~isempty(Error)
    disp(Error);
    return;
end


%Detrend
%YAN Chao-Gan 120826: detrend is no longer needed if linear trend is included in nuisance regression. Keeping this function is for back compatibility
if (AutoDataProcessParameter.IsDetrend==1)
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor i=1:AutoDataProcessParameter.SubjectNum
            rest_detrend([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}], '_detrend');
        end
    end
    
    %Copy the Detrended files to DataProcessDir\{AutoDataProcessParameter.StartingDirName}+D
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor i=1:AutoDataProcessParameter.SubjectNum
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'D',filesep,AutoDataProcessParameter.SubjectID{i}])
            movefile([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}, '_detrend',filesep,'*'],[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'D',filesep,AutoDataProcessParameter.SubjectID{i}])

            rmdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}, '_detrend']);
            fprintf(['Moving Dtrended Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
    end
    AutoDataProcessParameter.StartingDirName=[AutoDataProcessParameter.StartingDirName,'D']; %Now StartingDirName is with new suffix 'D'
end



%%%%%%%%
% If don't need to Warp into original space, then check if the masks are appropriate and resample if not.
% YAN Chao-Gan, 120827.

if (AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==0)
    
    MasksName{1,1}=[ProgramPath,filesep,'Templates',filesep,'BrainMask_05_91x109x91.img'];
    MasksName{2,1}=[ProgramPath,filesep,'Templates',filesep,'CsfMask_07_91x109x91.img'];
    MasksName{3,1}=[ProgramPath,filesep,'Templates',filesep,'WhiteMask_09_91x109x91.img'];
    MasksName{4,1}=[ProgramPath,filesep,'Templates',filesep,'GreyMask_02_91x109x91.img'];
    
    if (isfield(AutoDataProcessParameter,'MaskFile')) && (~isempty(AutoDataProcessParameter.MaskFile)) && (~isequal(AutoDataProcessParameter.MaskFile, 'Default'))
        MasksName{5,1}=AutoDataProcessParameter.MaskFile;
    end
    
    if ~(7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'Masks'],'dir'))
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'Masks']);
    end
    
    RefFile=dir([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{1},filesep,'*.img']);
    if isempty(RefFile)  %YAN Chao-Gan, 120827. Also support .nii.gz files.
        RefFile=dir([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{1},filesep,'*.nii.gz']);
    end
    if isempty(RefFile)  %YAN Chao-Gan, 111114. Also support .nii files.
        RefFile=dir([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{1},filesep,'*.nii']);
    end
    RefFile=[AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{1},filesep,RefFile(1).name];
    [RefData,RefVox,RefHeader]=rest_readfile(RefFile,1);

    for iMask=1:length(MasksName)
        AMaskFilename = MasksName{iMask};
        fprintf('\nResample Masks (%s) to the resolution of functional images.\n',AMaskFilename);
        
        [pathstr, name, ext] = fileparts(AMaskFilename);
        ReslicedMaskName=[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,'AllResampled_',name,'.nii'];
        
        y_Reslice(AMaskFilename,ReslicedMaskName,RefVox,0, RefFile);
        
    end
end


%Calculate ALFF and fALFF  %YAN Chao-Gan, 120827
if (AutoDataProcessParameter.IsCalALFF==1)
    
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'ALFF']);
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'fALFF']);
        
        parfor i=1:AutoDataProcessParameter.SubjectNum
            % Get the appropriate mask
            if ~isempty(AutoDataProcessParameter.MaskFile)
                if (isequal(AutoDataProcessParameter.MaskFile, 'Default'))
                    MaskNameString = 'BrainMask_05_91x109x91';
                else
                    [pathstr, name, ext] = fileparts(AutoDataProcessParameter.MaskFile);
                    MaskNameString = name;
                end
                if (AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==1)
                    MaskPrefix = AutoDataProcessParameter.SubjectID{i};
                else
                    MaskPrefix = 'AllResampled';
                end
                AMaskFilename = [AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,MaskPrefix,'_',MaskNameString,'.nii'];
            else
                AMaskFilename='';
            end
            
            if AutoDataProcessParameter.TR==0  % Need to retrieve the TR information from the NIfTI images
                TR = AutoDataProcessParameter.TRSet(iFunSession,i)
            else
                TR = AutoDataProcessParameter.TR;
            end
            
            
            % ALFF and fALFF calculation
            [ALFFBrain, fALFFBrain, Header] = y_alff_falff([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}], ...
                TR, ...  
                AutoDataProcessParameter.CalALFF.ALowPass_HighCutoff, ...
                AutoDataProcessParameter.CalALFF.AHighPass_LowCutoff, ...
                AMaskFilename, ...
                {[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'ALFF',filesep,'ALFFMap_',AutoDataProcessParameter.SubjectID{i},'.nii'];[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'fALFF',filesep,'fALFFMap_',AutoDataProcessParameter.SubjectID{i},'.nii']});

            % Get the m* files: divided by the mean within the mask
            % and the z* files: substract by the mean and then divided by the std within the mask
            BrainMaskData=rest_readfile(AMaskFilename);
            
            Temp = (ALFFBrain ./ mean(ALFFBrain(find(BrainMaskData)))) .* (BrainMaskData~=0);
            rest_WriteNiftiImage(Temp,Header,[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'ALFF',filesep,'mALFFMap_',AutoDataProcessParameter.SubjectID{i},'.nii']);
            
            Temp = ((ALFFBrain - mean(ALFFBrain(find(BrainMaskData)))) ./ std(ALFFBrain(find(BrainMaskData)))) .* (BrainMaskData~=0);
            rest_WriteNiftiImage(Temp,Header,[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'ALFF',filesep,'zALFFMap_',AutoDataProcessParameter.SubjectID{i},'.nii']);
            
            
            Temp = (fALFFBrain ./ mean(fALFFBrain(find(BrainMaskData)))) .* (BrainMaskData~=0);
            rest_WriteNiftiImage(Temp,Header,[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'fALFF',filesep,'mfALFFMap_',AutoDataProcessParameter.SubjectID{i},'.nii']);
            
            Temp = ((fALFFBrain - mean(fALFFBrain(find(BrainMaskData)))) ./ std(fALFFBrain(find(BrainMaskData)))) .* (BrainMaskData~=0);
            rest_WriteNiftiImage(Temp,Header,[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'fALFF',filesep,'zfALFFMap_',AutoDataProcessParameter.SubjectID{i},'.nii']);
            
        end
    end
end






%Filter ('AfterNormalize')
if (AutoDataProcessParameter.IsFilter==1) && (strcmpi(AutoDataProcessParameter.Filter.Timing,'AfterNormalize'))
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor i=1:AutoDataProcessParameter.SubjectNum

            if AutoDataProcessParameter.TR==0  % Need to retrieve the TR information from the NIfTI images
                TR = AutoDataProcessParameter.TRSet(iFunSession,i)
            else
                TR = AutoDataProcessParameter.TR;
            end

            y_bandpass([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}], ...
                TR, ...
                AutoDataProcessParameter.Filter.ALowPass_HighCutoff, ...
                AutoDataProcessParameter.Filter.AHighPass_LowCutoff, ...
                AutoDataProcessParameter.Filter.AAddMeanBack, ...   %Revised by YAN Chao-Gan,100420. In according to the change of rest_bandpass.m. %AutoDataProcessParameter.Filter.ARetrend, ...
                ''); % Just don't use mask in filtering. %AutoDataProcessParameter.Filter.AMaskFilename);
        end
    end
    
    %Copy the Filtered files to DataProcessDir\{AutoDataProcessParameter.StartingDirName}+F
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor i=1:AutoDataProcessParameter.SubjectNum
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'F',filesep,AutoDataProcessParameter.SubjectID{i}])
            movefile([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}, '_filtered',filesep,'*'],[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'F',filesep,AutoDataProcessParameter.SubjectID{i}])

            rmdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}, '_filtered']);
            fprintf(['Moving Filtered Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
    end
    AutoDataProcessParameter.StartingDirName=[AutoDataProcessParameter.StartingDirName,'F']; %Now StartingDirName is with new suffix 'F'
    
end
    


%If don't need to Warp into original space, then resample the other covariables mask
if (AutoDataProcessParameter.IsCovremove==1) && ((strcmpi(AutoDataProcessParameter.Covremove.Timing,'AfterNormalizeFiltering'))&&(AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==0))
    
    if ~isempty(AutoDataProcessParameter.Covremove.OtherCovariatesROI)
        
        if ~(7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'Masks'],'dir'))
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'Masks']);
        end
        
        % Check if masks appropriate %This can be used as a function!!! ONLY FOR RESAMPLE
        OtherCovariatesROIForEachSubject=cell(AutoDataProcessParameter.SubjectNum,1);
        parfor i=1:AutoDataProcessParameter.SubjectNum
            Suffix='OtherCovariateROI_'; %%!!! Change as in Function
            SubjectROI=AutoDataProcessParameter.Covremove.OtherCovariatesROI;%%!!! Change as in Fuction
            
            % Set the reference image
            RefFile=dir([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{1},filesep,'*.img']);
            if isempty(RefFile)  %YAN Chao-Gan, 120827. Also support .nii.gz files.
                RefFile=dir([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{1},filesep,'*.nii.gz']);
            end
            if isempty(RefFile)  %YAN Chao-Gan, 111114. Also support .nii files.
                RefFile=dir([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{1},filesep,'*.nii']);
            end
            RefFile=[AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{1},filesep,RefFile(1).name];
            [RefData,RefVox,RefHeader]=rest_readfile(RefFile,1);
            
            % Ball to mask
            for iROI=1:length(SubjectROI)
                if rest_SphereROI( 'IsBallDefinition', SubjectROI{iROI})
                    
                    ROIMaskName=[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,Suffix,num2str(iROI),'_',AutoDataProcessParameter.SubjectID{i},'.nii'];
                    
                    rest_Y_SphereROI( 'BallDefinition2Mask' , SubjectROI{iROI}, size(RefData), RefVox, RefHeader, ROIMaskName);
                    
                    SubjectROI{iROI}=[ROIMaskName];
                end
            end
            
            % Check if the ROI mask is appropriate
            for iROI=1:length(SubjectROI)
                AMaskFilename=SubjectROI{iROI};
                if exist(SubjectROI{iROI},'file')==2
                    [pathstr, name, ext] = fileparts(SubjectROI{iROI});
                    if (~strcmpi(ext, '.txt'))
                        [MaskData,MaskVox,MaskHeader]=rest_readfile(AMaskFilename);
                        if ~isequal(size(MaskData), size(RefData))
                            fprintf('\nReslice %s Mask (%s) for "%s" since the dimension of mask mismatched the dimension of the functional data.\n',Suffix,AMaskFilename, AutoDataProcessParameter.SubjectID{i});
                            
                            ReslicedMaskName=[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,Suffix,num2str(iROI),'_',AutoDataProcessParameter.SubjectID{i},'.nii'];
                            y_Reslice(AMaskFilename,ReslicedMaskName,RefVox,0, RefFile);
                            SubjectROI{iROI}=ReslicedMaskName;
                        end
                    end
                end
            end
            
            % Check if the text file is a definition for multiple subjects. i.e., the first line is 'Covariables_List:', then get the corresponded covariables file
            for iROI=1:length(SubjectROI)
                if (ischar(SubjectROI{iROI})) && (exist(SubjectROI{iROI},'file')==2)
                    [pathstr, name, ext] = fileparts(SubjectROI{iROI});
                    if (strcmpi(ext, '.txt'))
                        fid = fopen(SubjectROI{iROI});
                        SeedTimeCourseList=textscan(fid,'%s','\n');
                        fclose(fid);
                        if strcmpi(SeedTimeCourseList{1}{1},'Covariables_List:')
                            SubjectROI{iROI}=SeedTimeCourseList{1}{i+1};
                        end
                    end
                end
                
            end
            
            OtherCovariatesROIForEachSubject{i}=SubjectROI; %%!!! Change as in Fuction
        end
        
        AutoDataProcessParameter.Covremove.OtherCovariatesROIForEachSubject = OtherCovariatesROIForEachSubject;
    end
end


%Remove the nuisance Covaribles ('AfterNormalizeFiltering')
if (AutoDataProcessParameter.IsCovremove==1) && (strcmpi(AutoDataProcessParameter.Covremove.Timing,'AfterNormalizeFiltering'))
    
    %Remove the Covariables
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor i=1:AutoDataProcessParameter.SubjectNum
            
            CovariablesDef=[];
            
            %Polynomial trends
            %0: constant
            %1: constant + linear trend
            %2: constant + linear trend + quadratic trend.
            %3: constant + linear trend + quadratic trend + cubic trend.   ...
            
            CovariablesDef.polort = AutoDataProcessParameter.Covremove.PolynomialTrend;

            
            %Head Motion
            ImgCovModel = 1; %Default
            if (AutoDataProcessParameter.Covremove.HeadMotion==1) %1: Use the current time point of rigid-body 6 realign parameters. e.g., Txi, Tyi, Tzi...
                DirRP=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,FunSessionPrefixSet{iFunSession},'rp*']);
                Q1=load([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirRP.name]);
                CovariablesDef.CovMat = Q1;
            elseif (AutoDataProcessParameter.Covremove.HeadMotion==2) %2: Use the current time point and the previous time point of rigid-body 6 realign parameters. e.g., Txi, Tyi, Tzi,..., Txi-1, Tyi-1, Tzi-1...
                DirRP=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,FunSessionPrefixSet{iFunSession},'rp*']);
                Q1=load([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirRP.name]);
                CovariablesDef.CovMat = [Q1, [zeros(1,size(Q1,2));Q1(1:end-1,:)]];
            elseif (AutoDataProcessParameter.Covremove.HeadMotion==3) %3: Use the current time point and their squares of rigid-body 6 realign parameters. e.g., Txi, Tyi, Tzi,..., Txi^2, Tyi^2, Tzi^2...
                DirRP=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,FunSessionPrefixSet{iFunSession},'rp*']);
                Q1=load([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirRP.name]);
                CovariablesDef.CovMat = [Q1,  Q1.^2];
            elseif (AutoDataProcessParameter.Covremove.HeadMotion==4) %4: Use the Friston 24-parameter model: current time point, the previous time point and their squares of rigid-body 6 realign parameters. e.g., Txi, Tyi, Tzi, ..., Txi-1, Tyi-1, Tzi-1,... and their squares (total 24 items). Friston autoregressive model (Friston, K.J., Williams, S., Howard, R., Frackowiak, R.S., Turner, R., 1996. Movement-related effects in fMRI time-series. Magn Reson Med 35, 346-355.)
                DirRP=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,FunSessionPrefixSet{iFunSession},'rp*']);
                Q1=load([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirRP.name]);
                CovariablesDef.CovMat = [Q1, [zeros(1,size(Q1,2));Q1(1:end-1,:)], Q1.^2, [zeros(1,size(Q1,2));Q1(1:end-1,:)].^2];
            elseif (AutoDataProcessParameter.Covremove.HeadMotion>=11) %11-14: Use the voxel-specific models. 14 is the voxel-specific 12 model.
                
                if AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==1
                    %Use the voxel-specific head motion in original space. 
                    
                    HMvoxDir=[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'VoxelSpecificHeadMotion',filesep,AutoDataProcessParameter.SubjectID{i}];
                    
                    CovariablesDef.CovImgDir = {[HMvoxDir,filesep,'HMvox_X_4DVolume.nii'];[HMvoxDir,filesep,'HMvox_Y_4DVolume.nii'];[HMvoxDir,filesep,'HMvox_Z_4DVolume.nii']};

                else
                    %Use the voxel-specific head motion in MNI space, need to normalize first.
                    TemplateDir_SubID = AutoDataProcessParameter.SubjectID{1};
                    SubjectID_Temp = AutoDataProcessParameter.SubjectID{i};
                    SourceDir_Temp = [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'VoxelSpecificHeadMotion'];
                    OutpurDir_Temp = [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'VoxelSpecificHeadMotion','W'];
                    T1ImgNewSegmentDir = [AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment'];
                    DARTELTemplateFile = [AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,TemplateDir_SubID,filesep,'Template_6.nii'];
                    IsSubDirectory = 1;
                    BoundingBox=AutoDataProcessParameter.Normalize.BoundingBox;
                    VoxSize=AutoDataProcessParameter.Normalize.VoxSize;
                    y_Normalize_WriteToMNI_DARTEL(SubjectID_Temp,SourceDir_Temp,OutpurDir_Temp,T1ImgNewSegmentDir,DARTELTemplateFile,IsSubDirectory,BoundingBox,VoxSize)
                    
                    % Set the normalized voxel-specific head motion
                    HMvoxDir=[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'VoxelSpecificHeadMotionW',filesep,AutoDataProcessParameter.SubjectID{i}];

                    CovariablesDef.CovImgDir = {[HMvoxDir,filesep,'wHMvox_X_4DVolume.nii'];[HMvoxDir,filesep,'wHMvox_Y_4DVolume.nii'];[HMvoxDir,filesep,'wHMvox_Z_4DVolume.nii']};

                end
                
                ImgCovModel = AutoDataProcessParameter.Covremove.HeadMotion - 10;
            end
            

            %Head Motion "Scrubbing" Regressors: each bad time point is a separate regressor
            if (AutoDataProcessParameter.Covremove.IsHeadMotionScrubbingRegressors==1)
                
                % Use FD Power
                FD = load([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,FunSessionPrefixSet{iFunSession},'FD_Power_',AutoDataProcessParameter.SubjectID{i},'.txt']);
                
                TemporalMask=ones(length(FD),1);
                Index=find(FD > AutoDataProcessParameter.Covremove.HeadMotionScrubbingRegressors.FDThreshold);
                TemporalMask(Index)=0;
                IndexPrevious=Index;
                for iP=1:AutoDataProcessParameter.Covremove.HeadMotionScrubbingRegressors.PreviousPoints
                    IndexPrevious=IndexPrevious-1;
                    IndexPrevious=IndexPrevious(IndexPrevious>=1);
                    TemporalMask(IndexPrevious)=0;
                end
                IndexNext=Index;
                for iN=1:AutoDataProcessParameter.Covremove.HeadMotionScrubbingRegressors.LaterPoints
                    IndexNext=IndexNext+1;
                    IndexNext=IndexNext(IndexNext<=length(FD));
                    TemporalMask(IndexNext)=0;
                end
                
                BadTimePointsIndex = find(TemporalMask==0);
                BadTimePointsRegressor = zeros(length(FD),length(BadTimePointsIndex));
                for iBadTimePoints = 1:length(BadTimePointsIndex)
                    BadTimePointsRegressor(BadTimePointsIndex(iBadTimePoints),iBadTimePoints) = 1;
                end
                
                CovariablesDef.CovMat = [CovariablesDef.CovMat, BadTimePointsRegressor];
            end

            
            %Mask covariates
            if (AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==1)
                MaskPrefix = AutoDataProcessParameter.SubjectID{i};
            else
                MaskPrefix = 'AllResampled';
            end
            
            SubjectCovariatesROI=[];
            if (AutoDataProcessParameter.Covremove.WholeBrain==1)
                SubjectCovariatesROI=[SubjectCovariatesROI;{[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,MaskPrefix,'_BrainMask_05_91x109x91.nii']}];
            end
            if (AutoDataProcessParameter.Covremove.CSF==1)
                SubjectCovariatesROI=[SubjectCovariatesROI;{[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,MaskPrefix,'_CsfMask_07_91x109x91.nii']}];
            end
            if (AutoDataProcessParameter.Covremove.WhiteMatter==1)
                SubjectCovariatesROI=[SubjectCovariatesROI;{[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,MaskPrefix,'_WhiteMask_09_91x109x91.nii']}];
            end
            
            % Add the other Covariate ROIs
            if ~isempty(AutoDataProcessParameter.Covremove.OtherCovariatesROI)
                SubjectCovariatesROI=[SubjectCovariatesROI;AutoDataProcessParameter.Covremove.OtherCovariatesROIForEachSubject{i}];
            end
            
            
            %Extract Time course for the Mask covariates
            if ~isempty(SubjectCovariatesROI)
                if ~(7==exist([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'Covs'],'dir'))
                    mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'Covs']);
                end
                
                y_ExtractROISignal([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}], SubjectCovariatesROI, [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'Covs',filesep,AutoDataProcessParameter.SubjectID{i}], '', 1);
                
                CovariablesDef.ort_file=[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'Covs',filesep,'ROISignals_',AutoDataProcessParameter.SubjectID{i},'.txt'];
            end
            
            
            %Regressing out the covariates
            fprintf('\nRegressing out covariates for subject %s %s.\n',AutoDataProcessParameter.SubjectID{i},FunSessionPrefixSet{iFunSession});
            y_RegressOutImgCovariates([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}],CovariablesDef,'_Covremoved','', ImgCovModel);
            
        end
        fprintf('\n');
    end
    
    
    %Copy the Covariates Removed files to DataProcessDir\{AutoDataProcessParameter.StartingDirName}+C
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor i=1:AutoDataProcessParameter.SubjectNum
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'C',filesep,AutoDataProcessParameter.SubjectID{i}])
            movefile([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}, '_Covremoved',filesep,'*'],[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'C',filesep,AutoDataProcessParameter.SubjectID{i}])

            rmdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}, '_Covremoved']);
            fprintf(['Moving Coviables Removed Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
    end
    AutoDataProcessParameter.StartingDirName=[AutoDataProcessParameter.StartingDirName,'C']; %Now StartingDirName is with new suffix 'C'
    
end



%Scrubbing
if (AutoDataProcessParameter.IsScrubbing==1) && (strcmpi(AutoDataProcessParameter.Scrubbing.Timing,'AfterPreprocessing'))
    
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor i=1:AutoDataProcessParameter.SubjectNum
            
            % Use FD Power
            FD = load([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,FunSessionPrefixSet{iFunSession},'FD_Power_',AutoDataProcessParameter.SubjectID{i},'.txt']);
            
            TemporalMask=ones(length(FD),1);
            Index=find(FD > AutoDataProcessParameter.Scrubbing.FDThreshold);
            TemporalMask(Index)=0;
            IndexPrevious=Index;
            for iP=1:AutoDataProcessParameter.Scrubbing.PreviousPoints
                IndexPrevious=IndexPrevious-1;
                IndexPrevious=IndexPrevious(IndexPrevious>=1);
                TemporalMask(IndexPrevious)=0;
            end
            IndexNext=Index;
            for iN=1:AutoDataProcessParameter.Scrubbing.LaterPoints
                IndexNext=IndexNext+1;
                IndexNext=IndexNext(IndexNext<=length(FD));
                TemporalMask(IndexNext)=0;
            end
            
            %'B' stands for scrubbing
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'B',filesep,AutoDataProcessParameter.SubjectID{i}]);
            y_Scrubbing([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}], ...
                [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'B',filesep,AutoDataProcessParameter.SubjectID{i},filesep,AutoDataProcessParameter.SubjectID{i},'_4DVolume.nii'],...
                '', ... %Don't need to use brain mask
                TemporalMask, AutoDataProcessParameter.Scrubbing.ScrubbingMethod, '');

        end
    end
    
    AutoDataProcessParameter.StartingDirName=[AutoDataProcessParameter.StartingDirName,'B']; %Now StartingDirName is with new suffix 'B': scrubbing
    
end
  



%Calculate ReHo
if (AutoDataProcessParameter.IsCalReHo==1)
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'ReHo']);
        
        parfor i=1:AutoDataProcessParameter.SubjectNum

            % Get the appropriate mask
            if ~isempty(AutoDataProcessParameter.MaskFile)
                if (isequal(AutoDataProcessParameter.MaskFile, 'Default'))
                    MaskNameString = 'BrainMask_05_91x109x91';
                else
                    [pathstr, name, ext] = fileparts(AutoDataProcessParameter.MaskFile);
                    MaskNameString = name;
                end
                if (AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==1)
                    MaskPrefix = AutoDataProcessParameter.SubjectID{i};
                else
                    MaskPrefix = 'AllResampled';
                end
                AMaskFilename = [AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,MaskPrefix,'_',MaskNameString,'.nii'];
            else
                AMaskFilename='';
            end

            % ReHo Calculation
            [ReHoBrain, Header] = y_reho([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}], ...
                AutoDataProcessParameter.CalReHo.ClusterNVoxel, ...
                AMaskFilename, ...
                [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'ReHo',filesep,'ReHoMap_',AutoDataProcessParameter.SubjectID{i},'.nii']);

            % Get the m* files: divided by the mean within the mask
            % and the z* files: substract by the mean and then divided by the std within the mask
            BrainMaskData=rest_readfile(AMaskFilename);
            
            Temp = (ReHoBrain ./ mean(ReHoBrain(find(BrainMaskData)))) .* (BrainMaskData~=0);
            rest_WriteNiftiImage(Temp,Header,[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'ReHo',filesep,'mReHoMap_',AutoDataProcessParameter.SubjectID{i},'.nii']);
            
            Temp = ((ReHoBrain - mean(ReHoBrain(find(BrainMaskData)))) ./ std(ReHoBrain(find(BrainMaskData)))) .* (BrainMaskData~=0);
            rest_WriteNiftiImage(Temp,Header,[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'ReHo',filesep,'zReHoMap_',AutoDataProcessParameter.SubjectID{i},'.nii']);
        
        end
    end
end



%Calculate Degree Centrality
if (AutoDataProcessParameter.IsCalDegreeCentrality==1)
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'DegreeCentrality']);
        
        parfor i=1:AutoDataProcessParameter.SubjectNum

            % Get the appropriate mask
            if ~isempty(AutoDataProcessParameter.MaskFile)
                if (isequal(AutoDataProcessParameter.MaskFile, 'Default'))
                    MaskNameString = 'BrainMask_05_91x109x91';
                else
                    [pathstr, name, ext] = fileparts(AutoDataProcessParameter.MaskFile);
                    MaskNameString = name;
                end
                if (AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==1)
                    MaskPrefix = AutoDataProcessParameter.SubjectID{i};
                else
                    MaskPrefix = 'AllResampled';
                end
                AMaskFilename = [AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,MaskPrefix,'_',MaskNameString,'.nii'];
            else
                AMaskFilename='';
            end
            

            % Degree Centrality Calculation
            [DegreeCentrality_PositiveWeightedSumBrain, DegreeCentrality_PositiveBinarizedSumBrain, Header] = y_DegreeCentrality([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}], ...
                AutoDataProcessParameter.CalDegreeCentrality.rThreshold, ...
                {[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'DegreeCentrality',filesep,'DegreeCentrality_PositiveWeightedSumBrainMap_',AutoDataProcessParameter.SubjectID{i},'.nii'];[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'DegreeCentrality',filesep,'DegreeCentrality_PositiveBinarizedSumBrainMap_',AutoDataProcessParameter.SubjectID{i},'.nii']}, ...
                AMaskFilename);

            
            % Get the m* files: divided by the mean within the mask
            % and the z* files: substract by the mean and then divided by the std within the mask
            BrainMaskData=rest_readfile(AMaskFilename);
            
            Temp = (DegreeCentrality_PositiveWeightedSumBrain ./ mean(DegreeCentrality_PositiveWeightedSumBrain(find(BrainMaskData)))) .* (BrainMaskData~=0);
            rest_WriteNiftiImage(Temp,Header,[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'DegreeCentrality',filesep,'mDegreeCentrality_PositiveWeightedSumBrainMap_',AutoDataProcessParameter.SubjectID{i},'.nii']);
            
            Temp = ((DegreeCentrality_PositiveWeightedSumBrain - mean(DegreeCentrality_PositiveWeightedSumBrain(find(BrainMaskData)))) ./ std(DegreeCentrality_PositiveWeightedSumBrain(find(BrainMaskData)))) .* (BrainMaskData~=0);
            rest_WriteNiftiImage(Temp,Header,[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'DegreeCentrality',filesep,'zDegreeCentrality_PositiveWeightedSumBrainMap_',AutoDataProcessParameter.SubjectID{i},'.nii']);

            
            Temp = (DegreeCentrality_PositiveBinarizedSumBrain ./ mean(DegreeCentrality_PositiveBinarizedSumBrain(find(BrainMaskData)))) .* (BrainMaskData~=0);
            rest_WriteNiftiImage(Temp,Header,[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'DegreeCentrality',filesep,'mDegreeCentrality_PositiveBinarizedSumBrainMap_',AutoDataProcessParameter.SubjectID{i},'.nii']);
            
            Temp = ((DegreeCentrality_PositiveBinarizedSumBrain - mean(DegreeCentrality_PositiveBinarizedSumBrain(find(BrainMaskData)))) ./ std(DegreeCentrality_PositiveBinarizedSumBrain(find(BrainMaskData)))) .* (BrainMaskData~=0);
            rest_WriteNiftiImage(Temp,Header,[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'DegreeCentrality',filesep,'zDegreeCentrality_PositiveBinarizedSumBrainMap_',AutoDataProcessParameter.SubjectID{i},'.nii']);

        end
    end
end





% Define ROI Interactively
if (AutoDataProcessParameter.IsDefineROIInteractively==1)
    prompt ={'How many ROIs do you want to define interactively?', 'ROI Radius (mm. "0" means define for each ROI seperately): '};
    def	={	'1', ...
        '0', ...
        };
    options.Resize='on';
    options.WindowStyle='modal';
    options.Interpreter='tex';
    answer =inputdlg(prompt, 'Define ROI Interactively', 1, def,options);
    if numel(answer)==2,
        ROINumber_DefinedInteractively =abs(round(str2num(answer{1})));
        ROIRadius_DefinedInteractively =abs(round(str2num(answer{2})));
    end
    ROIRadius_DefinedInteractively=ROIRadius_DefinedInteractively*ones(AutoDataProcessParameter.SubjectNum,ROINumber_DefinedInteractively);
%     ROICenter_DefinedInteractively=zeros(AutoDataProcessParameter.SubjectNum,ROINumber_DefinedInteractively);
    for i=1:AutoDataProcessParameter.SubjectNum
        DirT1ImgCoreg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.img']);
        if isempty(DirT1ImgCoreg)  %YAN Chao-Gan, 111114. Also support .nii files.
            DirT1ImgCoreg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii']);
        end
        for iROI=1:ROINumber_DefinedInteractively
            fprintf('Define ROI %d interactively for %s: \n',iROI,AutoDataProcessParameter.SubjectID{i});
            global DPARSFA_spm_image_Parameters
            uiwait(DPARSFA_spm_image('init',[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgCoreg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirT1ImgCoreg(1).name]));
            ROICenter_DefinedInteractively{i,iROI}=DPARSFA_spm_image_Parameters.pos;
            clear global DPARSFA_spm_image_Parameters
            if ROIRadius_DefinedInteractively(i,iROI)==0
                answer =inputdlg(sprintf('ROI Radius (mm) for ROI %d with %s: \n',iROI,AutoDataProcessParameter.SubjectID{i}), 'Define ROI Interactively', 1, {'0'},options);
                ROIRadius_DefinedInteractively(i,iROI) =abs(round(str2num(answer{1})));
            end
        end
    end
    AutoDataProcessParameter.ROICenter_DefinedInteractively=ROICenter_DefinedInteractively;
    AutoDataProcessParameter.ROIRadius_DefinedInteractively=ROIRadius_DefinedInteractively;
    AutoDataProcessParameter.ROINumber_DefinedInteractively=ROINumber_DefinedInteractively;
end




% Generate the appropriate ROI masks
if (~isempty(AutoDataProcessParameter.CalFC.ROIDef)) || (AutoDataProcessParameter.IsDefineROIInteractively==1)
    if ~isfield(AutoDataProcessParameter,'ROINumber_DefinedInteractively')
        AutoDataProcessParameter.ROINumber_DefinedInteractively=0;
    end
    
    if ~(7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'Masks'],'dir'))
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'Masks']);
    end
    
    % Check if masks appropriate %This can be used as a function!!!
    ROIDefForEachSubject=cell(AutoDataProcessParameter.SubjectNum,1);
    parfor i=1:AutoDataProcessParameter.SubjectNum
        Suffix='FCROI_'; %%!!! Change as in Function
        SubjectROI=AutoDataProcessParameter.CalFC.ROIDef;%%!!! Change as in Fuction
        RefFile=dir([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.img']);
        if isempty(RefFile)  %YAN Chao-Gan, 111114. Also support .nii files.
            RefFile=dir([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii']);
        end
        if isempty(RefFile)  %YAN Chao-Gan, 120827. Also support .nii files.
            RefFile=dir([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii.gz']);
        end
        RefFile=[AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,RefFile(1).name];
        [RefData,RefVox,RefHeader]=rest_readfile(RefFile,1);
        % Ball to mask
        for iROI=1:length(SubjectROI)
            if rest_SphereROI( 'IsBallDefinition', SubjectROI{iROI})
                
                ROIMaskName=[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,Suffix,num2str(iROI),'_',AutoDataProcessParameter.SubjectID{i},'.nii'];
                
                if (AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==0)
                    rest_Y_SphereROI( 'BallDefinition2Mask' , SubjectROI{iROI}, size(RefData), RefVox, RefHeader, ROIMaskName);
                else
                    [MNIData MNIVox MNIHeader]=rest_readfile([ProgramPath,filesep,'Templates',filesep,'aal.nii']);
                    rest_Y_SphereROI( 'BallDefinition2Mask' , SubjectROI{iROI}, size(MNIData), MNIVox, MNIHeader, ROIMaskName);
                end

                SubjectROI{iROI}=[ROIMaskName];
            end
        end
        
        
        if AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==1
            %Need to warp masks
            
            % Check if have .txt file. Note: the txt files should be put the last of the ROI definition
            NeedWarpMaskNameSet=[];
            WarpedMaskNameSet=[];
            for iROI=1:length(SubjectROI)
                if exist(SubjectROI{iROI},'file')==2
                    [pathstr, name, ext] = fileparts(SubjectROI{iROI});
                    if (~strcmpi(ext, '.txt'))
                        NeedWarpMaskNameSet=[NeedWarpMaskNameSet;{SubjectROI{iROI}}];
                        WarpedMaskNameSet=[WarpedMaskNameSet;{[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,Suffix,num2str(iROI),'_',AutoDataProcessParameter.SubjectID{i},'.nii']}];
                        
                        SubjectROI{iROI}=[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,Suffix,num2str(iROI),'_',AutoDataProcessParameter.SubjectID{i},'.nii'];
                    end
                end
            end
            
            
            if (7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1}],'dir'))
                % If is processed by New Segment and DARTEL
                
                TemplateDir_SubID=AutoDataProcessParameter.SubjectID{1};
                
                DARTELTemplateFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,TemplateDir_SubID,filesep,'Template_6.nii'];
                DARTELTemplateMatFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,TemplateDir_SubID,filesep,'Template_6_2mni.mat'];
                
                DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'u_*']);
                FlowFieldFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name];
                
                
                y_WarpBackByDARTEL(NeedWarpMaskNameSet,WarpedMaskNameSet,RefFile,DARTELTemplateFilename,DARTELTemplateMatFilename,FlowFieldFilename,0);
                
                for iROI=1:length(NeedWarpMaskNameSet)
                    fprintf('\nWarp %s Mask (%s) for "%s" to individual space using DARTEL flow field (in T1ImgNewSegment) genereated by DARTEL.\n',Suffix,NeedWarpMaskNameSet{iROI}, AutoDataProcessParameter.SubjectID{i});
                end
                
            elseif (7==exist([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{1}],'dir'))
                % If is processed by unified segmentation
                
                MatFileDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*seg_inv_sn.mat']);
                MatFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,MatFileDir(1).name];
                
                for iROI=1:length(NeedWarpMaskNameSet)
                    y_NormalizeWrite(NeedWarpMaskNameSet{iROI},WarpedMaskNameSet{iROI},RefFile,MatFilename,0);
                    fprintf('\nWarp %s Mask (%s) for "%s" to individual space using *seg_inv_sn.mat (in T1ImgSegment) genereated by T1 image segmentation.\n',Suffix,NeedWarpMaskNameSet{iROI}, AutoDataProcessParameter.SubjectID{i});
                end
                
            end
            
        else %Do not need to warp masks but may need to resample
            
            % Check if the ROI mask is appropriate
            for iROI=1:length(SubjectROI)
                AMaskFilename=SubjectROI{iROI};
                if exist(SubjectROI{iROI},'file')==2
                    [pathstr, name, ext] = fileparts(SubjectROI{iROI});
                    if (~strcmpi(ext, '.txt'))
                        [MaskData,MaskVox,MaskHeader]=rest_readfile(AMaskFilename);
                        if ~isequal(size(MaskData), size(RefData))
                            fprintf('\nReslice %s Mask (%s) for "%s" since the dimension of mask mismatched the dimension of the functional data.\n',Suffix,AMaskFilename, AutoDataProcessParameter.SubjectID{i});
                            
                            ReslicedMaskName=[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,Suffix,num2str(iROI),'_',AutoDataProcessParameter.SubjectID{i},'.nii'];
                            y_Reslice(AMaskFilename,ReslicedMaskName,RefVox,0, RefFile);
                            SubjectROI{iROI}=ReslicedMaskName;
                        end
                    end
                end
            end
            
        end
        
        % Check if the text file is a definition for multiple subjects. i.e., the first line is 'Seed_Time_Course_List:', then get the corresponded seed series file
        for iROI=1:length(SubjectROI)
            if (ischar(SubjectROI{iROI})) && (exist(SubjectROI{iROI},'file')==2)
                [pathstr, name, ext] = fileparts(SubjectROI{iROI});
                if (strcmpi(ext, '.txt'))
                    fid = fopen(SubjectROI{iROI});
                    SeedTimeCourseList=textscan(fid,'%s','\n');
                    fclose(fid);
                    if strcmpi(SeedTimeCourseList{1}{1},'Seed_Time_Course_List:')
                        SubjectROI{iROI}=SeedTimeCourseList{1}{i+1};
                    end
                end
            end
            
        end
        
        ROIDefForEachSubject{i}=SubjectROI; %%!!! Change as in Fuction
        
        % Process ROIs defined interactively
        % These files don't need to warp, cause they are defined in original space and mask was created in original space.
        Suffix='ROIDefinedInteractively_';
        for iROI=1:AutoDataProcessParameter.ROINumber_DefinedInteractively
            SubjectROI=rest_Y_SphereROI('ROIBall2Str', AutoDataProcessParameter.ROICenter_DefinedInteractively{i,iROI}, AutoDataProcessParameter.ROIRadius_DefinedInteractively(i,iROI));
            
            ROIMaskName=[AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,Suffix,num2str(iROI),'_',AutoDataProcessParameter.SubjectID{i},'.nii'];
            rest_Y_SphereROI( 'BallDefinition2Mask' , SubjectROI, size(RefData), RefVox, RefHeader, ROIMaskName);

            ROIDefForEachSubject{i}{length(AutoDataProcessParameter.CalFC.ROIDef)+iROI}=[ROIMaskName];
        end

    end
    
    AutoDataProcessParameter.CalFC.ROIDefForEachSubject = ROIDefForEachSubject;
end




%Functional Connectivity Calculation (by Seed based Correlation Anlyasis)
if (AutoDataProcessParameter.IsCalFC==1)
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'FC']);
        
        parfor i=1:AutoDataProcessParameter.SubjectNum

            % Get the appropriate mask
            if ~isempty(AutoDataProcessParameter.MaskFile)
                if (isequal(AutoDataProcessParameter.MaskFile, 'Default'))
                    MaskNameString = 'BrainMask_05_91x109x91';
                else
                    [pathstr, name, ext] = fileparts(AutoDataProcessParameter.MaskFile);
                    MaskNameString = name;
                end
                if (AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==1)
                    MaskPrefix = AutoDataProcessParameter.SubjectID{i};
                else
                    MaskPrefix = 'AllResampled';
                end
                AMaskFilename = [AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,MaskPrefix,'_',MaskNameString,'.nii'];
            else
                AMaskFilename='';
            end

            
            % Calculate Functional Connectivity by Seed based Correlation Anlyasis

            y_SCA([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}], ...
                AutoDataProcessParameter.CalFC.ROIDefForEachSubject{i}, ...
                [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'FC',filesep,'FCMap_',AutoDataProcessParameter.SubjectID{i}], ...
                AMaskFilename, ...
                AutoDataProcessParameter.CalFC.IsMultipleLabel);
            
            % Fisher's r to z transformation has been performed inside y_SCA
            
        end
    end
end




%Extract ROI Signals
if (AutoDataProcessParameter.IsExtractROISignals==1)
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'_ROISignals']);
        
        %Extract the ROI time courses
        parfor i=1:AutoDataProcessParameter.SubjectNum
            
            y_ExtractROISignal([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}], ...
                AutoDataProcessParameter.CalFC.ROIDefForEachSubject{i}, ...
                [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'_ROISignals',filesep,AutoDataProcessParameter.SubjectID{i}], ...
                '', ... % Will not restrict into the brain mask in extracting ROI signals
                AutoDataProcessParameter.CalFC.IsMultipleLabel);
            
        end
    end
end









%Calculate VMHC: This usually performed in MNI Space
if (AutoDataProcessParameter.IsCalVMHC==1)
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'VMHC']);
        
        parfor i=1:AutoDataProcessParameter.SubjectNum

            % Get the appropriate mask
            if ~isempty(AutoDataProcessParameter.MaskFile)
                if (isequal(AutoDataProcessParameter.MaskFile, 'Default'))
                    MaskNameString = 'BrainMask_05_91x109x91';
                else
                    [pathstr, name, ext] = fileparts(AutoDataProcessParameter.MaskFile);
                    MaskNameString = name;
                end
                if (AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==1)
                    MaskPrefix = AutoDataProcessParameter.SubjectID{i};
                else
                    MaskPrefix = 'AllResampled';
                end
                AMaskFilename = [AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,MaskPrefix,'_',MaskNameString,'.nii'];
            else
                AMaskFilename='';
            end
            

            % VMHC Calculation
            [VMHCBrain, Header] = y_VMHC([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,AutoDataProcessParameter.SubjectID{i}], ...
                [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'VMHC',filesep,'VMHCMap_',AutoDataProcessParameter.SubjectID{i},'.nii'], ...
                AMaskFilename);

            
            % Get the z* files: Fisher's r to z transformation
                  
            zVMHCBrain = (0.5 * log((1 + VMHCBrain)./(1 - VMHCBrain)));

            rest_WriteNiftiImage(zVMHCBrain,Header,[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'VMHC',filesep,'zVMHCMap_',AutoDataProcessParameter.SubjectID{i},'.nii']);

        end
    end
end


%Calculate CWAS: This should be performed in MNI Space (4*4*4) and only one session!
if (AutoDataProcessParameter.IsCWAS==1)
    for iFunSession=1:1
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'CWAS']);

        % Get the appropriate mask
        if ~isempty(AutoDataProcessParameter.MaskFile)
            if (isequal(AutoDataProcessParameter.MaskFile, 'Default'))
                MaskNameString = 'BrainMask_05_91x109x91';
            else
                [pathstr, name, ext] = fileparts(AutoDataProcessParameter.MaskFile);
                MaskNameString = name;
            end
            if (AutoDataProcessParameter.IsWarpMasksIntoIndividualSpace==1)
                MaskPrefix = AutoDataProcessParameter.SubjectID{i};
            else
                MaskPrefix = 'AllResampled';
            end
            AMaskFilename = [AutoDataProcessParameter.DataProcessDir,filesep,'Masks',filesep,MaskPrefix,'_',MaskNameString,'.nii'];
        else
            AMaskFilename='';
        end
        
        
        % CWAS Calculation
        [p_Brain, F_Brain, Header] = y_CWAS([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName], ...
            AutoDataProcessParameter.SubjectID, ...
            [AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},'Results',filesep,'CWAS',filesep,'CWAS.nii'], ...
            AutoDataProcessParameter.CWAS.Regressors, ...
            AutoDataProcessParameter.CWAS.iter);
        
    end
end







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%***Normalize and/or Smooth the results***%%%%%%%%%%%%%%%%

AutoDataProcessParameter.StartingDirName = 'Results';

%Normalize on Results
if (AutoDataProcessParameter.IsNormalize>0) && strcmpi(AutoDataProcessParameter.Normalize.Timing,'OnResults')

    %Check the measures need to be normalized
    DirMeasure = dir([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName]);
    if strcmpi(DirMeasure(3).name,'.DS_Store')  %110908 YAN Chao-Gan, for MAC OS compatablie
        StartIndex=4;
    else
        StartIndex=3;
    end
    MeasureSet=[];
    for iDir=StartIndex:length(DirMeasure)
        if DirMeasure(iDir).isdir
            if ~(strcmpi(DirMeasure(iDir).name,'VMHC') || (length(DirMeasure(iDir).name)>10 && strcmpi(DirMeasure(iDir).name(end-10:end),'_ROISignals')))
                MeasureSet = [MeasureSet;{DirMeasure(iDir).name}];
            end
        end
        
    end
    
    fprintf(['Normalizing the resutls into MNI space...\n']);

    
    parfor i=1:AutoDataProcessParameter.SubjectNum
        
        FileList=[];
        for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
            for iMeasure=1:length(MeasureSet)
                cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,MeasureSet{iMeasure}]);
                DirImg=dir(['*',AutoDataProcessParameter.SubjectID{i},'*.img']);
                for j=1:length(DirImg)
                    FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,MeasureSet{iMeasure},filesep,DirImg(j).name]}];
                end
                
                DirImg=dir(['*',AutoDataProcessParameter.SubjectID{i},'*.nii']);
                for j=1:length(DirImg)
                    FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,MeasureSet{iMeasure},filesep,DirImg(j).name]}];
                end
            end
            
        end
        
        % Set the mean functional image % YAN Chao-Gan, 120826
        DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.img']);
        if isempty(DirMean)  %YAN Chao-Gan, 111114. Also support .nii files.
            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'mean*.nii.gz']);% Search .nii.gz and unzip; YAN Chao-Gan, 120806.
            if length(DirMean)==1
                gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                delete([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
            end
            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.nii']);
        end
        MeanFilename = [AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirMean(1).name];
        
        FileList=[FileList;{MeanFilename}]; %YAN Chao-Gan, 120826. Also normalize the mean functional image.
        

        if (AutoDataProcessParameter.IsNormalize==1) %Normalization by using the EPI template directly
            
            SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Normalize.mat']);
            
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.subj(1,1).source={MeanFilename};
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.subj(1,1).resample=FileList;
            
            [SPMPath, fileN, extn] = fileparts(which('spm.m'));
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.eoptions.template={[SPMPath,filesep,'templates',filesep,'EPI.nii,1']};
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.roptions.bb=AutoDataProcessParameter.Normalize.BoundingBox;
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.roptions.vox=AutoDataProcessParameter.Normalize.VoxSize;

            if SPMversion==5
                spm_jobman('run',SPMJOB.jobs);
            elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
                SPMJOB.jobs = spm_jobman('spm5tospm8',{SPMJOB.jobs});
                spm_jobman('run',SPMJOB.jobs{1});
            else
                uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
                Error=[Error;{['Error in Normalize: The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.']}];
            end
        end
        
        if (AutoDataProcessParameter.IsNormalize==2) %Normalization by using the T1 image segment information
            %Normalize-Write: Using the segment information
            SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Normalize_Write.mat']);
            
            MatFileDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*seg_sn.mat']);
            MatFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,MatFileDir(1).name];
            
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.write.subj.matname={MatFilename};
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.write.subj.resample=FileList;
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.write.roptions.bb=AutoDataProcessParameter.Normalize.BoundingBox;
            SPMJOB.jobs{1,1}.spatial{1,1}.normalise{1,1}.write.roptions.vox=AutoDataProcessParameter.Normalize.VoxSize;
            
            if SPMversion==5
                spm_jobman('run',SPMJOB.jobs);
            elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
                SPMJOB.jobs = spm_jobman('spm5tospm8',{SPMJOB.jobs});
                spm_jobman('run',SPMJOB.jobs{1});
            else
                uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
                Error=[Error;{['Error in Normalize: The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.']}];
            end
            
        end
        
        if (AutoDataProcessParameter.IsNormalize==3) %Normalization by using DARTEL %YAN Chao-Gan, 111111.
            
            SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Dartel_NormaliseToMNI_FewSubjects.mat']);
            
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.fwhm=[0 0 0];
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.preserve=0;
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.bb=AutoDataProcessParameter.Normalize.BoundingBox;
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.vox=AutoDataProcessParameter.Normalize.VoxSize;
            
            DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'Template_6.*']);
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.template={[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirImg(1).name]};
            
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subj(1,1).images=FileList;
            
            DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'u_*']);
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subj(1,1).flowfield={[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]};

            spm_jobman('run',SPMJOB.matlabbatch);
        end
    end
    

    %Copy the Normalized results to ResultsW
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor iMeasure=1:length(MeasureSet)
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'W',filesep,MeasureSet{iMeasure}])
            movefile([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,MeasureSet{iMeasure},filesep,'w*'],[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'W',filesep,MeasureSet{iMeasure}])
            fprintf(['Moving Normalized Files:',MeasureSet{iMeasure},' OK']);
        end
        fprintf('\n');
    end
    AutoDataProcessParameter.StartingDirName=[AutoDataProcessParameter.StartingDirName,'W']; %Now StartingDirName is with new suffix 'W'
    

    %Generate the pictures for checking normalization %YAN Chao-Gan, 091001
    mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'PicturesForChkNormalization']);
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'PicturesForChkNormalization']);
    if license('test','image_toolbox') % Added by YAN Chao-Gan, 100420.
        global DPARSF_rest_sliceviewer_Cfg;
        h=DPARSF_rest_sliceviewer;
        [RESTPath, fileN, extn] = fileparts(which('rest.m'));
        Ch2Filename=[RESTPath,filesep,'Template',filesep,'ch2.nii'];
        set(DPARSF_rest_sliceviewer_Cfg.Config(1).hOverlayFile, 'String', Ch2Filename);
        DPARSF_rest_sliceviewer_Cfg.Config(1).Overlay.Opacity=0.2;
        DPARSF_rest_sliceviewer('ChangeOverlay', h);
        
        for i=1:AutoDataProcessParameter.SubjectNum

            DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'wmean*.img']);
            if isempty(DirMean)  %YAN Chao-Gan, 111114. Also support .nii files.
                DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'wmean*.nii.gz']);% Search .nii.gz and unzip; YAN Chao-Gan, 120806.
                if length(DirMean)==1
                    gunzip([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                    delete([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirMean(1).name]);
                end
                DirMean=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'wmean*.nii']);
            end
            Filename = [AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirMean(1).name];
            
            % Revised by YAN Chao-Gan, 100420. Fixed a bug in displaying overlay with different bounding box from those of underlay in according to rest_sliceviewer.m
            DPARSF_Normalized_TempImage =fullfile(tempdir,['DPARSF_Normalized_TempImage','_',rest_misc('GetCurrentUser'),'.img']);
            y_Reslice(Filename,DPARSF_Normalized_TempImage,[1 1 1],0);
            set(DPARSF_rest_sliceviewer_Cfg.Config(1).hUnderlayFile, 'String', DPARSF_Normalized_TempImage);
            set(DPARSF_rest_sliceviewer_Cfg.Config(1).hMagnify ,'Value',2);
            %             set(DPARSF_rest_sliceviewer_Cfg.Config(1).hUnderlayFile, 'String', Filename);
            %             set(DPARSF_rest_sliceviewer_Cfg.Config(1).hMagnify ,'Value',4);
            DPARSF_rest_sliceviewer('ChangeUnderlay', h);
            eval(['print(''-dtiff'',''-r100'',''',FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.SubjectID{i},'.tif'',h);']);
            fprintf(['Generating the pictures for checking normalization: ',AutoDataProcessParameter.SubjectID{i},' OK']);
        end

        close(h);
        fprintf('\n');
    else  % Added by YAN Chao-Gan, 100420.
        fprintf('Since Image Processing Toolbox of MATLAB is not valid, the pictures for checking normalization will not be generated.\n');
        fid = fopen('Warning.txt','at+');
        fprintf(fid,'%s','Since Image Processing Toolbox of MATLAB is not valid, the pictures for checking normalization will not be generated.\n');
        fclose(fid);
    end
    
end
if ~isempty(Error)
    disp(Error);
    return;
end



%Smooth on Results
if (AutoDataProcessParameter.IsSmooth>=1) && strcmpi(AutoDataProcessParameter.Smooth.Timing,'OnResults')

    %Check the measures need to be normalized
    DirMeasure = dir([AutoDataProcessParameter.DataProcessDir,filesep,AutoDataProcessParameter.StartingDirName]);
    if strcmpi(DirMeasure(3).name,'.DS_Store')  %110908 YAN Chao-Gan, for MAC OS compatablie
        StartIndex=4;
    else
        StartIndex=3;
    end
    MeasureSet=[];
    for iDir=StartIndex:length(DirMeasure)
        if DirMeasure(iDir).isdir
            if ~((length(DirMeasure(iDir).name)>10 && strcmpi(DirMeasure(iDir).name(end-10:end),'_ROISignals')))
                MeasureSet = [MeasureSet;{DirMeasure(iDir).name}];
            end
        end
        
    end
    
    fprintf(['Smoothing the resutls...\n']);

    
    if (AutoDataProcessParameter.IsSmooth==1)
        parfor i=1:AutoDataProcessParameter.SubjectNum

            FileList=[];
            for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
                for iMeasure=1:length(MeasureSet)
                    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,MeasureSet{iMeasure}]);
                    DirImg=dir(['*',AutoDataProcessParameter.SubjectID{i},'*.img']);
                    for j=1:length(DirImg)
                        FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,MeasureSet{iMeasure},filesep,DirImg(j).name]}];
                    end
                    
                    DirImg=dir(['*',AutoDataProcessParameter.SubjectID{i},'*.nii']);
                    for j=1:length(DirImg)
                        FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,MeasureSet{iMeasure},filesep,DirImg(j).name]}];
                    end
                end
                
            end

            SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Smooth.mat']);
            SPMJOB.jobs{1,1}.spatial{1,1}.smooth.data = FileList;
            SPMJOB.jobs{1,1}.spatial{1,1}.smooth.fwhm = AutoDataProcessParameter.Smooth.FWHM;
            if SPMversion==5
                spm_jobman('run',SPMJOB.jobs);
            elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
                SPMJOB.jobs = spm_jobman('spm5tospm8',{SPMJOB.jobs});
                spm_jobman('run',SPMJOB.jobs{1});
            else
                uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
            end

        end
        
    elseif (AutoDataProcessParameter.IsSmooth==2)   %YAN Chao-Gan, 111111. Smooth by DARTEL. The smoothing that is a part of the normalization to MNI space computes these average intensities from the original data, rather than the warped versions. When the data are warped, some voxels will grow and others will shrink. This will change the regional averages, with more weighting towards those voxels that have grows.

        parfor i=1:AutoDataProcessParameter.SubjectNum

            SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Dartel_NormaliseToMNI_FewSubjects.mat']);
            
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.fwhm=AutoDataProcessParameter.Smooth.FWHM;
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.preserve=0;
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.bb=AutoDataProcessParameter.Normalize.BoundingBox;
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.vox=AutoDataProcessParameter.Normalize.VoxSize;
            
            DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'Template_6.*']);
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.template={[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirImg(1).name]};
            
            FileList=[];
            for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
                for iMeasure=1:length(MeasureSet)
                    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName(1:end-1),filesep,MeasureSet{iMeasure}]);
                    DirImg=dir(['*',AutoDataProcessParameter.SubjectID{i},'*.img']);
                    for j=1:length(DirImg)
                        FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName(1:end-1),filesep,MeasureSet{iMeasure},filesep,DirImg(j).name]}];
                    end
                    
                    DirImg=dir(['*',AutoDataProcessParameter.SubjectID{i},'*.nii']);
                    for j=1:length(DirImg)
                        FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName(1:end-1),filesep,MeasureSet{iMeasure},filesep,DirImg(j).name]}];
                    end
                end
                
            end
            
            
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subj(1,1).images=FileList;
            
            DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'u_*']);
            SPMJOB.matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subj(1,1).flowfield={[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]};
            
            spm_jobman('run',SPMJOB.matlabbatch);
            fprintf(['Smooth by using DARTEL:',AutoDataProcessParameter.SubjectID{i},' OK\n']);
        end

    end

    
    %Copy the Smoothed files to ResultsWS or ResultsS
    for iFunSession=1:AutoDataProcessParameter.FunctionalSessionNumber
        parfor iMeasure=1:length(MeasureSet)
            mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'S',filesep,MeasureSet{iMeasure}])
            if (AutoDataProcessParameter.IsSmooth==1)
                movefile([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,filesep,MeasureSet{iMeasure},filesep,'s*'],[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'S',filesep,MeasureSet{iMeasure}])
            elseif (AutoDataProcessParameter.IsSmooth==2) % If smoothed by DARTEL, then the smoothed files still under realign directory.
                movefile([AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName(1:end-1),filesep,MeasureSet{iMeasure},filesep,'s*'],[AutoDataProcessParameter.DataProcessDir,filesep,FunSessionPrefixSet{iFunSession},AutoDataProcessParameter.StartingDirName,'S',filesep,MeasureSet{iMeasure}])
            end
            fprintf(['Moving Smoothed Files:',MeasureSet{iMeasure},' OK']);
        end
        fprintf('\n');
    end
    
    AutoDataProcessParameter.StartingDirName=[AutoDataProcessParameter.StartingDirName,'S']; %Now StartingDirName is with new suffix 'S'
    
end
if ~isempty(Error)
    disp(Error);
    return;
end





rest_waitbar;  %Added by YAN Chao-Gan 091110. Close the rest waitbar after all the calculation.



