function [Error]=DPARSF_run(AutoDataProcessParameter)
% FORMAT [Error]=DPARSF_run(AutoDataProcessParameter)
% Input:
%   AutoDataProcessParameter - the parameters for auto data processing
%Example:
% AutoDataProcessParameter.DataProcessDir='K:\ADHD_Jia\Processing'; %The unprocessed NIFTI data should put in the 'DataProcessDir\FunImg' file folder.
% cd ([AutoDataProcessParameter.DataProcessDir,'\FunRaw'])
% AutoDataProcessParameter.SubjectID=[];
% Dir=dir;
% for i=3:length(Dir)
%     AutoDataProcessParameter.SubjectID=[AutoDataProcessParameter.SubjectID;{Dir(i).name}];
% end
% AutoDataProcessParameter.TimePoints=240;
% 
% AutoDataProcessParameter.IsNeedConvertFunDCM2IMG=1; %Functional DICOM images put in the 'DataProcessDir\FunRaw'
% AutoDataProcessParameter.IsNeedConvertT1DCM2IMG=1; %T1 DICOM images put in the 'DataProcessDir\T1Raw'
% 
% %********Processing of fMRI BOLD images********
% AutoDataProcessParameter.RemoveFirstTimePoints=10;
% 
% AutoDataProcessParameter.IsSliceTiming=1;
% AutoDataProcessParameter.SliceTiming.SliceNumber=25;
% AutoDataProcessParameter.SliceTiming.TR=2;
% AutoDataProcessParameter.SliceTiming.TA=AutoDataProcessParameter.SliceTiming.TR-(AutoDataProcessParameter.SliceTiming.TR/AutoDataProcessParameter.SliceTiming.SliceNumber);
% AutoDataProcessParameter.SliceTiming.SliceOrder=[1:2:25,2:2:24];
% AutoDataProcessParameter.SliceTiming.ReferenceSlice=25;
% 
% AutoDataProcessParameter.IsRealign=1;
% 
% AutoDataProcessParameter.IsNormalize=1; % 1: Normalization by using the EPI template directly; 2: Normalization by using the T1 image segment information (T1 images stored in 'DataProcessDir\T1Img' and initiated with 'co*')
% AutoDataProcessParameter.Normalize.BoundingBox=[-90 -126 -72;90 90 108];
% AutoDataProcessParameter.Normalize.VoxSize=[3 3 3];
% AutoDataProcessParameter.Normalize.AffineRegularisationInSegmentation='eastern';
% AutoDataProcessParameter.IsDelFilesBeforeNormalize=1;
% 
% AutoDataProcessParameter.IsSmooth=1; %The Normalized data should put in 'DataProcessDir\FunImgNormalized'
% AutoDataProcessParameter.Smooth.FWHM=[4 4 4];
% 
% AutoDataProcessParameter.DataIsSmoothed=1; %Record the information that whether the data was smoothed. This will influence the following steps.
% 
% AutoDataProcessParameter.IsDetrend=1; %The Normalized data should put in 'DataProcessDir\FunImgNormalized' or 'DataProcessDir\FunImgNormalizedSmoothed'
% AutoDataProcessParameter.IsFilter=1;
% AutoDataProcessParameter.Filter.ASamplePeriod=2;
% AutoDataProcessParameter.Filter.AHighPass_LowCutoff=0.01;
% AutoDataProcessParameter.Filter.ALowPass_HighCutoff=0.08;
% AutoDataProcessParameter.Filter.AMaskFilename='';
% AutoDataProcessParameter.Filter.AAddMeanBack='Yes';
% AutoDataProcessParameter.IsDelDetrendedFiles=1;
% 
% AutoDataProcessParameter.IsCalReHo=1;
% AutoDataProcessParameter.CalReHo.ClusterNVoxel=27;
% AutoDataProcessParameter.CalReHo.AMaskFilename='Default';
% AutoDataProcessParameter.CalReHo.smReHo=1;
% AutoDataProcessParameter.CalReHo.mReHo_1=1;
% 
% AutoDataProcessParameter.IsCalALFF=1;
% AutoDataProcessParameter.CalALFF.ASamplePeriod=2;
% AutoDataProcessParameter.CalALFF.AHighPass_LowCutoff=0.01;
% AutoDataProcessParameter.CalALFF.ALowPass_HighCutoff=0.08;
% AutoDataProcessParameter.CalALFF.AMaskFilename='Default';
% AutoDataProcessParameter.CalALFF.mALFF_1=1;
% 
% AutoDataProcessParameter.IsCalfALFF=1;
% AutoDataProcessParameter.CalfALFF.ASamplePeriod=2;
% AutoDataProcessParameter.CalfALFF.AHighPass_LowCutoff=0.01;
% AutoDataProcessParameter.CalfALFF.ALowPass_HighCutoff=0.08;
% AutoDataProcessParameter.CalfALFF.AMaskFilename='Default';
% AutoDataProcessParameter.CalfALFF.mfALFF_1=1;
% 
% AutoDataProcessParameter.IsCovremove=0;
% AutoDataProcessParameter.Covremove.HeadMotion=1;
% AutoDataProcessParameter.Covremove.WholeBrain=1;
% AutoDataProcessParameter.Covremove.CSF=0;
% AutoDataProcessParameter.Covremove.WhiteMatter=0;
% AutoDataProcessParameter.Covremove.OtherCovariatesROI=[];
% 
% AutoDataProcessParameter.IsExtractAALTC=0;
% 
% AutoDataProcessParameter.IsExtractROITC=0;
% AutoDataProcessParameter.ExtractROITC.IsTalCoordinates=1;
% AutoDataProcessParameter.ExtractROITC.ROICenter=[];%ROICenter;
% AutoDataProcessParameter.ExtractROITC.ROIRadius=6;
% 
% AutoDataProcessParameter.IsExtractRESTdefinedROITC=0;
% AutoDataProcessParameter.IsCalFC=0;
% AutoDataProcessParameter.CalFC.ROIDef=[];
% AutoDataProcessParameter.CalFC.AMaskFilename='Default';
% 
% %*******Processing of T1(MPRAGE) images********
% AutoDataProcessParameter.IsResliceT1To1x1x1=0; % T1 images stored in 'DataProcessDir\T1Img'
% 
% AutoDataProcessParameter.IsT1Segment=0; % T1 images stored in 'DataProcessDir\T1Img'
% 
% AutoDataProcessParameter.IsWrapAALToNative=0; % T1 images stored in 'DataProcessDir\T1Img'
% 
% AutoDataProcessParameter.IsExtractAALGMVolume=0;

% Output:
%   The processed data that you want.
%___________________________________________________________________________
% Written by YAN Chao-Gan 090306.
% State Key Laboratory of Cognitive Neuroscience and Learning, Beijing Normal University, China, 100875
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
% Modified by YAN Chao-Gan, 101025. Fixed a bug in copying *.ps files.
% Last Modified by YAN Chao-Gan, 120101. Nomralize by DARTEL added.


if ischar(AutoDataProcessParameter)  %If inputed a .mat file name. (Cfg inside)
    load(AutoDataProcessParameter);
    AutoDataProcessParameter=Cfg;
end

[ProgramPath, fileN, extn] = fileparts(which('DPARSF_run.m'));
AutoDataProcessParameter.SubjectNum=length(AutoDataProcessParameter.SubjectID);
Error=[];
addpath([ProgramPath,filesep,'Subfunctions']);

[SPMversion,c]=spm('Ver');
SPMversion=str2double(SPMversion(end));

%Make parameters compitalbe with DPARSF_V1.0_100201. YAN Chao-Gan, 100420.
if isfield(AutoDataProcessParameter,'Filter')
    if ~isfield(AutoDataProcessParameter.Filter,'AAddMeanBack')
        if isfield(AutoDataProcessParameter.Filter,'ARetrend')
            AutoDataProcessParameter.Filter.AAddMeanBack=AutoDataProcessParameter.Filter.ARetrend;
        else
            AutoDataProcessParameter.Filter.AAddMeanBack='Yes';
        end
    end
end

%Make compatible with missing parameters. YAN Chao-Gan, 100420.
if ~isfield(AutoDataProcessParameter,'DataProcessDir')
    AutoDataProcessParameter.DataProcessDir=AutoDataProcessParameter.WorkingDir;
end
if isfield(AutoDataProcessParameter,'TR')
    AutoDataProcessParameter.SliceTiming.TR=AutoDataProcessParameter.TR;
    AutoDataProcessParameter.SliceTiming.TA=AutoDataProcessParameter.SliceTiming.TR-(AutoDataProcessParameter.SliceTiming.TR/AutoDataProcessParameter.SliceTiming.SliceNumber);
    AutoDataProcessParameter.Filter.ASamplePeriod=AutoDataProcessParameter.TR;
    AutoDataProcessParameter.CalALFF.ASamplePeriod=AutoDataProcessParameter.TR;
    AutoDataProcessParameter.CalfALFF.ASamplePeriod=AutoDataProcessParameter.TR;
end
if ~isfield(AutoDataProcessParameter,'IsNeedConvertFunDCM2IMG')
    AutoDataProcessParameter.IsNeedConvertFunDCM2IMG=0; 
end
if ~isfield(AutoDataProcessParameter,'IsNeedConvertT1DCM2IMG')
    AutoDataProcessParameter.IsNeedConvertT1DCM2IMG=0; 
end
if ~isfield(AutoDataProcessParameter,'RemoveFirstTimePoints')
    AutoDataProcessParameter.RemoveFirstTimePoints=0; 
end
if ~isfield(AutoDataProcessParameter,'IsSliceTiming')
    AutoDataProcessParameter.IsSliceTiming=0; 
end
if ~isfield(AutoDataProcessParameter,'IsRealign')
    AutoDataProcessParameter.IsRealign=0; 
end
if ~isfield(AutoDataProcessParameter,'IsNormalize')
    AutoDataProcessParameter.IsNormalize=0; 
end
if ~isfield(AutoDataProcessParameter,'IsDelFilesBeforeNormalize')
    AutoDataProcessParameter.IsDelFilesBeforeNormalize=0; 
end
if ~isfield(AutoDataProcessParameter,'IsSmooth')
    AutoDataProcessParameter.IsSmooth=0; 
end
if ~isfield(AutoDataProcessParameter,'DataIsSmoothed')
    AutoDataProcessParameter.DataIsSmoothed=0; 
end
if ~isfield(AutoDataProcessParameter,'IsDetrend')
    AutoDataProcessParameter.IsDetrend=0; 
end
if ~isfield(AutoDataProcessParameter,'IsFilter')
    AutoDataProcessParameter.IsFilter=0; 
end
if ~isfield(AutoDataProcessParameter,'IsDelDetrendedFiles')
    AutoDataProcessParameter.IsDelDetrendedFiles=0; 
end
if isfield(AutoDataProcessParameter,'MaskFile')
    AutoDataProcessParameter.CalReHo.AMaskFilename=AutoDataProcessParameter.MaskFile;
    AutoDataProcessParameter.CalALFF.AMaskFilename=AutoDataProcessParameter.MaskFile;
    AutoDataProcessParameter.CalfALFF.AMaskFilename=AutoDataProcessParameter.MaskFile;
    AutoDataProcessParameter.CalFC.AMaskFilename=AutoDataProcessParameter.MaskFile;
end
if ~isfield(AutoDataProcessParameter,'IsCalReHo')
    AutoDataProcessParameter.IsCalReHo=0; 
end
if ~isfield(AutoDataProcessParameter,'IsCalALFF')
    AutoDataProcessParameter.IsCalALFF=0; 
end
if ~isfield(AutoDataProcessParameter,'IsCalfALFF')
    AutoDataProcessParameter.IsCalfALFF=0; 
end
if ~isfield(AutoDataProcessParameter,'IsCovremove')
    AutoDataProcessParameter.IsCovremove=0; 
end
if ~isfield(AutoDataProcessParameter,'IsExtractAALTC')
    AutoDataProcessParameter.IsExtractAALTC=0; 
end
if ~isfield(AutoDataProcessParameter,'IsExtractROITC')
    AutoDataProcessParameter.IsExtractROITC=0; 
end
if ~isfield(AutoDataProcessParameter,'IsExtractRESTdefinedROITC')
    AutoDataProcessParameter.IsExtractRESTdefinedROITC=0; 
end
if ~isfield(AutoDataProcessParameter,'IsCalFC')
    AutoDataProcessParameter.IsCalFC=0; 
end
if ~isfield(AutoDataProcessParameter,'IsResliceT1To1x1x1')
    AutoDataProcessParameter.IsResliceT1To1x1x1=0; 
end
if ~isfield(AutoDataProcessParameter,'IsT1Segment')
    AutoDataProcessParameter.IsT1Segment=0; 
end
if ~isfield(AutoDataProcessParameter,'IsWrapAALToNative')
    AutoDataProcessParameter.IsWrapAALToNative=0; 
end
if ~isfield(AutoDataProcessParameter,'IsExtractAALGMVolume')
    AutoDataProcessParameter.IsExtractAALGMVolume=0; 
end

AutoDataProcessParameter.SliceTiming.TR=AutoDataProcessParameter.TR;
AutoDataProcessParameter.SliceTiming.TA=AutoDataProcessParameter.SliceTiming.TR-(AutoDataProcessParameter.SliceTiming.TR/AutoDataProcessParameter.SliceTiming.SliceNumber);
AutoDataProcessParameter.Filter.ASamplePeriod=AutoDataProcessParameter.TR;
AutoDataProcessParameter.CalALFF.ASamplePeriod=AutoDataProcessParameter.TR;
AutoDataProcessParameter.CalfALFF.ASamplePeriod=AutoDataProcessParameter.TR;


% Only One Session can be processed in Basic Edition. For Multiple Sessions
% Processing, please go to DPARSFA.
AutoDataProcessParameter.FunctionalSessionNumber=1;
FunSessionPrefixSet={''}; 
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



%****************************************************************Processing of fMRI BOLD images*****************
%Remove First Time Points
if (AutoDataProcessParameter.RemoveFirstTimePoints>0)
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg']);
    for i=1:AutoDataProcessParameter.SubjectNum
        cd(AutoDataProcessParameter.SubjectID{i});
        DirImg=dir('*.img');
        if length(DirImg)~=AutoDataProcessParameter.TimePoints
            Error=[Error;{['Error in Removing First ',num2str(AutoDataProcessParameter.RemoveFirstTimePoints),'Time Points: ',AutoDataProcessParameter.SubjectID{i}]}];
        end
        for j=1:AutoDataProcessParameter.RemoveFirstTimePoints
            delete(DirImg(j).name);
            delete([DirImg(j).name(1:end-4),'.hdr']);
        end
        cd('..');
        fprintf(['Removing First ',num2str(AutoDataProcessParameter.RemoveFirstTimePoints),'Time Points:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
    AutoDataProcessParameter.TimePoints=AutoDataProcessParameter.TimePoints-AutoDataProcessParameter.RemoveFirstTimePoints;
end
if ~isempty(Error)
    disp(Error);
    return;
end

%Slice Timing
if (AutoDataProcessParameter.IsSliceTiming==1)
    load([ProgramPath,filesep,'Jobmats',filesep,'SliceTiming.mat']);
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg']);
    for i=1:AutoDataProcessParameter.SubjectNum
        cd(AutoDataProcessParameter.SubjectID{i});
        DirImg=dir('*.img');
        if length(DirImg)~=AutoDataProcessParameter.TimePoints
            Error=[Error;{['Error in SliceTiming: ',AutoDataProcessParameter.SubjectID{i}]}];
        end
        FileList=[];
        for j=1:length(DirImg)
            FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'FunImg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(j).name,',1']}];
        end
        jobs{1,1}.temporal{1,1}.st.scans{i}=FileList;
        cd('..');
        fprintf(['Slice Timing Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
    jobs{1,1}.temporal{1,1}.st.nslices=AutoDataProcessParameter.SliceTiming.SliceNumber;
    jobs{1,1}.temporal{1,1}.st.tr=AutoDataProcessParameter.SliceTiming.TR;
    jobs{1,1}.temporal{1,1}.st.ta=AutoDataProcessParameter.SliceTiming.TA;
    jobs{1,1}.temporal{1,1}.st.so=AutoDataProcessParameter.SliceTiming.SliceOrder;
    jobs{1,1}.temporal{1,1}.st.refslice=AutoDataProcessParameter.SliceTiming.ReferenceSlice;
    if SPMversion==5
        spm_jobman('run',jobs);
    elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
        jobs = spm_jobman('spm5tospm8',{jobs});
        spm_jobman('run',jobs{1});
    else
        uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
        return
    end
end
if ~isempty(Error)
    disp(Error);
    return;
end

%Realign
if (AutoDataProcessParameter.IsRealign==1)
    load([ProgramPath,filesep,'Jobmats',filesep,'Realign.mat']);
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg']);
    for i=1:AutoDataProcessParameter.SubjectNum
        cd(AutoDataProcessParameter.SubjectID{i});
        DirImg=dir('a*.img');
        if length(DirImg)~=AutoDataProcessParameter.TimePoints
            Error=[Error;{['Error in Realign: ',AutoDataProcessParameter.SubjectID{i}]}];
        end
        FileList=[];
        for j=1:length(DirImg)
            FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'FunImg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(j).name,',1']}];
        end
        if i~=1
            jobs{1,1}.spatial{1,1}.realign=[jobs{1,1}.spatial{1,1}.realign,{jobs{1,1}.spatial{1,1}.realign{1,1}}];
        end
        jobs{1,1}.spatial{1,1}.realign{1,i}.estwrite.data{1,1}=FileList;
        cd('..');
        fprintf(['Realign Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
    if SPMversion==5
        spm_jobman('run',jobs);
    elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
        jobs = spm_jobman('spm5tospm8',{jobs});
        spm_jobman('run',jobs{1});
    else
        uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
        return
    end
        
    %YAN Chao-Gan, 101018. Check Head motion moved right after realign
    %Copy the Realign Parameters to DataProcessDir\RealignParameter
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg']);
    for i=1:AutoDataProcessParameter.SubjectNum
        cd(AutoDataProcessParameter.SubjectID{i});
        mkdir(['..',filesep,'..',filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i}]);
        copyfile('mean*',['..',filesep,'..',filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i}]);
        copyfile('rp*',['..',filesep,'..',filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i}]);
        cd('..');
        fprintf(['Moving Realign Parameters:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    if ~isempty(dir('*.ps'))
        copyfile('*.ps',['..',filesep,'RealignParameter',filesep]);
    end
    fprintf('\n');
    
    %Check Head Motion
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter']);
    HeadMotion=[];
    for i=1:AutoDataProcessParameter.SubjectNum
        cd(AutoDataProcessParameter.SubjectID{i});
        rpname=dir('rp*');
        b=load(rpname.name);
        c=max(abs(b));
        c(4:6)=c(4:6)*180/pi;
        HeadMotion=[HeadMotion;c];
        cd('..');
    end
    save('HeadMotion.mat','HeadMotion');
    
    ExcludeSub_Text=[];
    for ExcludingCriteria=3:-0.5:0.5
        BigHeadMotion=find(HeadMotion>ExcludingCriteria);
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
        ExcludeSub_Text=sprintf('%s\nExcluding Criteria: %2.1fmm and %2.1f degree\n%s\n\n\n',ExcludeSub_Text,ExcludingCriteria,ExcludingCriteria,TempText);
    end
    fid = fopen('ExcludeSubjects.txt','at+');
    fprintf(fid,'%s',ExcludeSub_Text);
    fclose(fid);
end
if ~isempty(Error)
    disp(Error);
    return;
end

%Normalize
if (AutoDataProcessParameter.IsNormalize>0)
    if (AutoDataProcessParameter.IsNormalize==1) %Normalization by using the EPI template directly
        load([ProgramPath,filesep,'Jobmats',filesep,'Normalize.mat']);
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg']);
        for i=1:AutoDataProcessParameter.SubjectNum
            cd(AutoDataProcessParameter.SubjectID{i});
            DirImg=dir('ra*.img');
            if length(DirImg)~=AutoDataProcessParameter.TimePoints
                Error=[Error;{['Error in Normalize: ',AutoDataProcessParameter.SubjectID{i}]}];
            end
            FileList=[];
            for j=1:length(DirImg)
                FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'FunImg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(j).name,',1']}];
            end
            MeanFilename=dir('mean*.img');
            MeanFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'FunImg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,MeanFilename.name,',1'];
            if i~=1
                jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.subj=[jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.subj,jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.subj(1,1)];
            end
            jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.subj(1,i).source={MeanFilename};
            jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.subj(1,i).resample=FileList;
            cd('..');
            fprintf(['Normalize Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
        [SPMPath, fileN, extn] = fileparts(which('spm.m'));
        jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.eoptions.template={[SPMPath,filesep,'templates',filesep,'EPI.nii,1']};
        jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.roptions.bb=AutoDataProcessParameter.Normalize.BoundingBox;
        jobs{1,1}.spatial{1,1}.normalise{1,1}.estwrite.roptions.vox=AutoDataProcessParameter.Normalize.VoxSize;
        if SPMversion==5
            spm_jobman('run',jobs);
        elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
            jobs = spm_jobman('spm5tospm8',{jobs});
            spm_jobman('run',jobs{1});
        else
            uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
            return
        end
    end
    
    if (AutoDataProcessParameter.IsNormalize==2) %Normalization by using the T1 image segment information
        %Backup the T1 images to T1ImgSegment
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img']);
        
        % Check in co* image exist. Added by YAN Chao-Gan 100510.
        cd(AutoDataProcessParameter.SubjectID{1});
        DirCo=dir('co*.img');
        if isempty(DirCo)
            DirImg=dir('*.img');
            if length(DirImg)==1
                button = questdlg(['No co* T1 image (T1 image which is reoriented to the nearest orthogonal direction to ''canonical space'' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum) is found. Do you want to use the T1 image without co? Such as: ',DirImg(1).name,'? Note: this image will be added a prefix ''co'' in the following analysis.'],'No co* T1 image is found','Yes','No','Yes');
                if strcmpi(button,'Yes')
                    UseNoCoT1Image=1;
                else
                    return;
                end
            else
                errordlg(['No co* T1 image (T1 image which is reoriented to the nearest orthogonal direction to ''canonical space'' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum) is found. And there are too many T1 images detected in T1Img directory. Please determine which T1 image you want to use in unified segmentation and delete the others from the T1Img directory, then re-run the analysis.'],'No co* T1 image is found');
                return;
            end
        else
            UseNoCoT1Image=0;
        end
        cd('..');
        
        for i=1:AutoDataProcessParameter.SubjectNum
            cd(AutoDataProcessParameter.SubjectID{i});
            mkdir(['..',filesep,'..',filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i}])
            % Check in co* image exist. Added by YAN Chao-Gan 100510.
            if UseNoCoT1Image==0
                copyfile('co*',['..',filesep,'..',filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i}])
            else
                DirHdr=dir('*.hdr');
                DirImg=dir('*.img');
                copyfile(DirHdr(1).name,['..',filesep,'..',filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'co',DirHdr(1).name]);
                copyfile(DirImg(1).name,['..',filesep,'..',filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'co',DirImg(1).name]);
            end
            cd('..');
            fprintf(['Copying T1 image Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
        %Coregister
        load([ProgramPath,filesep,'Jobmats',filesep,'Coregister.mat']);
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg']);
        for i=1:AutoDataProcessParameter.SubjectNum
            RefDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.img']);
            RefFile=[AutoDataProcessParameter.DataProcessDir,filesep,'FunImg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,RefDir(1).name,',1'];
            SourceDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'co*.img']);
            SourceFile=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,SourceDir(1).name];
            if i~=1
                jobs=[jobs,{jobs{1,1}}];
            end
            jobs{1,i}.spatial{1,1}.coreg{1,1}.estimate.ref={RefFile};
            jobs{1,i}.spatial{1,1}.coreg{1,1}.estimate.source={SourceFile};
            fprintf(['Normalize-Coregister Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
        if SPMversion==5
            spm_jobman('run',jobs);
        elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
            jobs = spm_jobman('spm5tospm8',{jobs});
            spm_jobman('run',jobs{1});
        else
            uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
            return
        end
        %Segment
        load([ProgramPath,filesep,'Jobmats',filesep,'Segment.mat']);
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment']);
        for i=1:AutoDataProcessParameter.SubjectNum
            SourceDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'co*.img']);
            SourceFile=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,SourceDir(1).name];
            if i~=1
                jobs=[jobs,{jobs{1,1}}];
            end
            [SPMPath, fileN, extn] = fileparts(which('spm.m'));
            jobs{1,i}.spatial{1,1}.preproc.opts.tpm={[SPMPath,filesep,'tpm',filesep,'grey.nii'];[SPMPath,filesep,'tpm',filesep,'white.nii'];[SPMPath,filesep,'tpm',filesep,'csf.nii']};
            jobs{1,i}.spatial{1,1}.preproc.data={SourceFile};
            if strcmpi(AutoDataProcessParameter.Normalize.AffineRegularisationInSegmentation,'mni')   %Added by YAN Chao-Gan 091110. Use different Affine Regularisation in Segmentation: East Asian brains (eastern) or European brains (mni).
                jobs{1,i}.spatial{1,1}.preproc.opts.regtype='mni';
            else
                jobs{1,i}.spatial{1,1}.preproc.opts.regtype='eastern';
            end
            fprintf(['Normalize-Segment Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
        if SPMversion==5
            spm_jobman('run',jobs);
        elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
            jobs = spm_jobman('spm5tospm8',{jobs});
            spm_jobman('run',jobs{1});
        else
            uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
            return
        end
        %Normalize-Write: Using the segment information
        load([ProgramPath,filesep,'Jobmats',filesep,'Normalize_Write.mat']);
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg']);
        for i=1:AutoDataProcessParameter.SubjectNum
            cd(AutoDataProcessParameter.SubjectID{i});
            DirImg=dir('ra*.img');
            if length(DirImg)~=AutoDataProcessParameter.TimePoints
                Error=[Error;{['Error in Normalize: ',AutoDataProcessParameter.SubjectID{i}]}];
            end
            FileList=[];
            for j=1:length(DirImg)
                FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'FunImg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(j).name,',1']}];
            end
            MatFileDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*seg_sn.mat']);
            MatFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,MatFileDir(1).name];
            if i~=1
                jobs=[jobs,{jobs{1,1}}];
            end
            jobs{1,i}.spatial{1,1}.normalise{1,1}.write.subj.matname={MatFilename};
            jobs{1,i}.spatial{1,1}.normalise{1,1}.write.subj.resample=FileList;
            jobs{1,i}.spatial{1,1}.normalise{1,1}.write.roptions.bb=AutoDataProcessParameter.Normalize.BoundingBox;
            jobs{1,i}.spatial{1,1}.normalise{1,1}.write.roptions.vox=AutoDataProcessParameter.Normalize.VoxSize;
            cd('..');
            fprintf(['Normalize-Write Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
        if SPMversion==5
            spm_jobman('run',jobs);
        elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
            jobs = spm_jobman('spm5tospm8',{jobs});
            spm_jobman('run',jobs{1});
        else
            uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
            return
        end
    end
    
    
    if (AutoDataProcessParameter.IsNormalize==3) %Normalization by using DARTEL. YAN Chao-Gan, 111130.
        %Backup the T1 images to T1ImgNewSegment
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img']);
        
        % Check in co* image exist. Added by YAN Chao-Gan 100510.
        cd(AutoDataProcessParameter.SubjectID{1});
        DirCo=dir('co*.img');
        if isempty(DirCo)
            DirImg=dir('*.img');
            if length(DirImg)==1
                button = questdlg(['No co* T1 image (T1 image which is reoriented to the nearest orthogonal direction to ''canonical space'' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum) is found. Do you want to use the T1 image without co? Such as: ',DirImg(1).name,'? Note: this image will be added a prefix ''co'' in the following analysis.'],'No co* T1 image is found','Yes','No','Yes');
                if strcmpi(button,'Yes')
                    UseNoCoT1Image=1;
                else
                    return;
                end
            else
                errordlg(['No co* T1 image (T1 image which is reoriented to the nearest orthogonal direction to ''canonical space'' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum) is found. And there are too many T1 images detected in T1Img directory. Please determine which T1 image you want to use in unified segmentation and delete the others from the T1Img directory, then re-run the analysis.'],'No co* T1 image is found');
                return;
            end
        else
            UseNoCoT1Image=0;
        end
        cd('..');
        
        for i=1:AutoDataProcessParameter.SubjectNum
            cd(AutoDataProcessParameter.SubjectID{i});
            mkdir(['..',filesep,'..',filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i}])
            % Check in co* image exist. Added by YAN Chao-Gan 100510.
            if UseNoCoT1Image==0
                copyfile('co*',['..',filesep,'..',filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i}])
            else
                DirHdr=dir('*.hdr');
                DirImg=dir('*.img');
                copyfile(DirHdr(1).name,['..',filesep,'..',filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'co',DirHdr(1).name]);
                copyfile(DirImg(1).name,['..',filesep,'..',filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'co',DirImg(1).name]);
            end
            cd('..');
            fprintf(['Copying T1 image Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
        
        %Coregister
        load([ProgramPath,filesep,'Jobmats',filesep,'Coregister.mat']);
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg']);
        for i=1:AutoDataProcessParameter.SubjectNum
            RefDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'mean*.img']);
            RefFile=[AutoDataProcessParameter.DataProcessDir,filesep,'FunImg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,RefDir(1).name,',1'];
            SourceDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'co*.img']);
            SourceFile=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,SourceDir(1).name];
            if i~=1
                jobs=[jobs,{jobs{1,1}}];
            end
            jobs{1,i}.spatial{1,1}.coreg{1,1}.estimate.ref={RefFile};
            jobs{1,i}.spatial{1,1}.coreg{1,1}.estimate.source={SourceFile};
            fprintf(['Normalize-Coregister Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
        if SPMversion==5
            spm_jobman('run',jobs);
        elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
            jobs = spm_jobman('spm5tospm8',{jobs});
            spm_jobman('run',jobs{1});
        else
            uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
            return
        end
        
        %New Segment
        T1ImgSegmentDirectoryName = 'T1ImgNewSegment';
        load([ProgramPath,filesep,'Jobmats',filesep,'NewSegment.mat']);
        [SPMPath, fileN, extn] = fileparts(which('spm.m'));
        for T1ImgSegmentDirectoryNameue=1:6
            matlabbatch{1,1}.spm.tools.preproc8.tissue(1,T1ImgSegmentDirectoryNameue).tpm{1,1}=[SPMPath,filesep,'toolbox',filesep,'Seg',filesep,'TPM.nii',',',num2str(T1ImgSegmentDirectoryNameue)];
            matlabbatch{1,1}.spm.tools.preproc8.tissue(1,T1ImgSegmentDirectoryNameue).warped = [0 0]; % Do not need warped results. Warp by DARTEL
        end
        if strcmpi(AutoDataProcessParameter.Normalize.AffineRegularisationInSegmentation,'mni')
            matlabbatch{1,1}.spm.tools.preproc8.warp.affreg='mni';
        else
            matlabbatch{1,1}.spm.tools.preproc8.warp.affreg='eastern';
        end
        
        T1SourceFileSet=[]; % Save to use in the step of DARTEL normalize to MNI
        cd([AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName]);
        for i=1:AutoDataProcessParameter.SubjectNum
            SourceDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.img']);
            if isempty(SourceDir)  %YAN Chao-Gan, 111114. Also support .nii files.
                SourceDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.nii']);
            end
            SourceFile=[AutoDataProcessParameter.DataProcessDir,filesep,T1ImgSegmentDirectoryName,filesep,AutoDataProcessParameter.SubjectID{i},filesep,SourceDir(1).name];
            if i~=1
                matlabbatch=[matlabbatch,{matlabbatch{1,1}}];
            end
            matlabbatch{1,i}.spm.tools.preproc8.channel.vols={SourceFile};
            T1SourceFileSet=[T1SourceFileSet;{SourceFile}];
            fprintf(['Normalize-Segment Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
        spm_jobman('run',matlabbatch);

        
        %DARTEL: Create Template
        load([ProgramPath,filesep,'Jobmats',filesep,'Dartel_CreateTemplate.mat']);
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
        matlabbatch{1,1}.spm.tools.dartel.warp.images{1,1}=rc1FileList;
        matlabbatch{1,1}.spm.tools.dartel.warp.images{1,2}=rc2FileList;
        fprintf(['Running DARTEL: Create Template.\n']);
        spm_jobman('run',matlabbatch);
        
        % DARTEL: Normalize to MNI space - GM, WM, CSF and T1 Images.
        load([ProgramPath,filesep,'Jobmats',filesep,'Dartel_NormaliseToMNI_ManySubjects.mat']);
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
        
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.template=TemplateFile;
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subjs.flowfields=FlowFieldFileList;
        
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subjs.images{1,1}=GMFileList;
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subjs.images{1,2}=WMFileList;
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subjs.images{1,3}=CSFFileList;
        
        fprintf(['Running DARTEL: Normalize to MNI space for VBM. Modulated version With smooth kernel [8 8 8].\n']);
        spm_jobman('run',matlabbatch);
        
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.fwhm=[0 0 0]; % Do not want to perform smooth
        fprintf(['Running DARTEL: Normalize to MNI space for VBM. Modulated version.\n']);
        spm_jobman('run',matlabbatch);
        
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.preserve = 0;
        if exist('T1SourceFileSet','var')
            matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subjs.images{1,4}=T1SourceFileSet;
        end
        fprintf(['Running DARTEL: Normalize to MNI space for VBM. Unmodulated version.\n']);
        spm_jobman('run',matlabbatch);

        % DARTEL: Normalize to MNI space - Functional Images.
        load([ProgramPath,filesep,'Jobmats',filesep,'Dartel_NormaliseToMNI_FewSubjects.mat']);
        
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.fwhm=[0 0 0];
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.preserve=0;
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.bb=AutoDataProcessParameter.Normalize.BoundingBox;
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.vox=AutoDataProcessParameter.Normalize.VoxSize;
        
        DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'Template_6.*']);
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.template={[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirImg(1).name]};
        
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg']);
        for i=1:AutoDataProcessParameter.SubjectNum
            cd(AutoDataProcessParameter.SubjectID{i});
            DirImg=dir('ra*.img');
            if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files.
                DirImg=dir('ra*.nii');
            end
            if length(DirImg)~=AutoDataProcessParameter.TimePoints
                Error=[Error;{['Error in Normalize: ',AutoDataProcessParameter.SubjectID{i}]}];
            end
            FileList=[];
            for j=1:length(DirImg)
                FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'FunImg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(j).name]}];
            end
            
            matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subj(1,i).images=FileList;
            
            DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'u_*']);
            matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subj(1,i).flowfield={[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]};
            
            cd('..');
            fprintf(['Normalization by using DARTEL Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
        spm_jobman('run',matlabbatch);
        
    end
       
        
    %Copy the normalized files to DataProcessDir\FunImgNormalized %YAN Chao-Gan, 101018. Check Head motion moved right after realign
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg']);
    for i=1:AutoDataProcessParameter.SubjectNum
        cd(AutoDataProcessParameter.SubjectID{i});
        mkdir(['..',filesep,'..',filesep,'FunImgNormalized',filesep,AutoDataProcessParameter.SubjectID{i}])
        movefile('wra*',['..',filesep,'..',filesep,'FunImgNormalized',filesep,AutoDataProcessParameter.SubjectID{i}])
        cd('..');
        fprintf(['Moving Normalized Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
    
    cd(AutoDataProcessParameter.DataProcessDir);
    if AutoDataProcessParameter.IsDelFilesBeforeNormalize==1
        rmdir('FunImg','s')
    end
   
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
            Dir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'FunImgNormalized',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*.img']);
            Filename=[AutoDataProcessParameter.DataProcessDir,filesep,'FunImgNormalized',filesep,AutoDataProcessParameter.SubjectID{i},filesep,Dir(1).name];
            % Revised by YAN Chao-Gan, 100420. Fixed a bug in displaying overlay with different bounding box from those of underlay in according to rest_sliceviewer.m
            DPARSF_Normalized_TempImage =fullfile(tempdir,['DPARSF_Normalized_TempImage','_',rest_misc('GetCurrentUser'),'.img']);
            y_Reslice(Filename,DPARSF_Normalized_TempImage,[1 1 1],0);
            set(DPARSF_rest_sliceviewer_Cfg.Config(1).hUnderlayFile, 'String', DPARSF_Normalized_TempImage);
            set(DPARSF_rest_sliceviewer_Cfg.Config(1).hMagnify ,'Value',2);
%             set(DPARSF_rest_sliceviewer_Cfg.Config(1).hUnderlayFile, 'String', Filename);
%             set(DPARSF_rest_sliceviewer_Cfg.Config(1).hMagnify ,'Value',4);
            DPARSF_rest_sliceviewer('ChangeUnderlay', h);
            eval(['print(''-dtiff'',''-r100'',''',AutoDataProcessParameter.SubjectID{i},'.tif'',h);']);
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

%Smooth
if (AutoDataProcessParameter.IsSmooth==1)
    if (AutoDataProcessParameter.IsNormalize~=3) %Nomral Smooth other than DARTEL.
        load([ProgramPath,filesep,'Jobmats',filesep,'Smooth.mat']);
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImgNormalized']);
        for i=1:AutoDataProcessParameter.SubjectNum
            cd(AutoDataProcessParameter.SubjectID{i});
            DirImg=dir('*.img');
            if length(DirImg)~=AutoDataProcessParameter.TimePoints
                Error=[Error;{['Error in Smooth: ',AutoDataProcessParameter.SubjectID{i}]}];
            end
            FileList=[];
            for j=1:length(DirImg)
                FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'FunImgNormalized',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(j).name,',1']}];
            end
            jobs{1,1}.spatial{1,1}.smooth.data=[jobs{1,1}.spatial{1,1}.smooth.data;FileList];
            cd('..');
            fprintf(['Smooth Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
        jobs{1,1}.spatial{1,1}.smooth.fwhm=AutoDataProcessParameter.Smooth.FWHM;
        if SPMversion==5
            spm_jobman('run',jobs);
        elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
            jobs = spm_jobman('spm5tospm8',{jobs});
            spm_jobman('run',jobs{1});
        else
            uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
            return
        end
    else %YAN Chao-Gan, 111130. Smooth by DARTEL. The smoothing that is a part of the normalization to MNI space computes these average intensities from the original data, rather than the warped versions. When the data are warped, some voxels will grow and others will shrink. This will change the regional averages, with more weighting towards those voxels that have grows.

        load([ProgramPath,filesep,'Jobmats',filesep,'Dartel_NormaliseToMNI_FewSubjects.mat']);
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.fwhm=AutoDataProcessParameter.Smooth.FWHM;
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.preserve=0;
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.bb=AutoDataProcessParameter.Normalize.BoundingBox;
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.vox=AutoDataProcessParameter.Normalize.VoxSize;
        DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1},filesep,'Template_6.*']);
        matlabbatch{1,1}.spm.tools.dartel.mni_norm.template={[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{1},filesep,DirImg(1).name]};
        
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg']); % If smoothed by DARTEL, then the files still under realign directory.
        for i=1:AutoDataProcessParameter.SubjectNum
            cd(AutoDataProcessParameter.SubjectID{i});
            DirImg=dir('ra*.img');
            if isempty(DirImg)  %YAN Chao-Gan, 111114. Also support .nii files.
                DirImg=dir('ra*.nii');
            end
            if length(DirImg)~=AutoDataProcessParameter.TimePoints
                Error=[Error;{['Error in Smooth: ',AutoDataProcessParameter.SubjectID{i}]}];
            end
            FileList=[];
            for j=1:length(DirImg)
                FileList=[FileList;{[AutoDataProcessParameter.DataProcessDir,filesep,'FunImg',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(j).name]}];
            end
            matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subj(1,i).images=FileList;
            DirImg=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'u_*']);
            matlabbatch{1,1}.spm.tools.dartel.mni_norm.data.subj(1,i).flowfield={[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgNewSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirImg(1).name]};
            cd('..');
            fprintf(['Smooth by using DARTEL Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
        end
        fprintf('\n');
        spm_jobman('run',matlabbatch);
    end
    
    %Copy the smoothed files to DataProcessDir\FunImgNormalizedSmoothed
    if (AutoDataProcessParameter.IsNormalize~=3)
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImgNormalized']);
    elseif (AutoDataProcessParameter.IsNormalize==3) % If smoothed by DARTEL, then the smoothed files still under realign directory.
        cd([AutoDataProcessParameter.DataProcessDir,filesep,'FunImg']);
    end
    for i=1:AutoDataProcessParameter.SubjectNum
        cd(AutoDataProcessParameter.SubjectID{i});
        mkdir(['..',filesep,'..',filesep,'FunImgNormalizedSmoothed',filesep,AutoDataProcessParameter.SubjectID{i}])
        movefile('s*',['..',filesep,'..',filesep,'FunImgNormalizedSmoothed',filesep,AutoDataProcessParameter.SubjectID{i}])
        cd('..');
        fprintf(['Moving Smoothed Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
end
if ~isempty(Error)
    disp(Error);
    return;
end

%Detrend
if (AutoDataProcessParameter.IsDetrend==1)
    if (AutoDataProcessParameter.DataIsSmoothed==1)
        FunImgDir='FunImgNormalizedSmoothed';
    else
        FunImgDir='FunImgNormalized';
    end
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir]);
    for i=1:AutoDataProcessParameter.SubjectNum
        rest_detrend([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,filesep,AutoDataProcessParameter.SubjectID{i}], '_detrend');
    end
    
    %Copy the detrended files to DataProcessDir\FunImgNormalizedDetrended or DataProcessDir\FunImgNormalizedSmoothedDetrended
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir]);
    for i=1:AutoDataProcessParameter.SubjectNum
        cd([AutoDataProcessParameter.SubjectID{i}, '_detrend']);
        mkdir(['..',filesep,'..',filesep,FunImgDir,'Detrended',filesep,AutoDataProcessParameter.SubjectID{i}])
        movefile('*',['..',filesep,'..',filesep,FunImgDir,'Detrended',filesep,AutoDataProcessParameter.SubjectID{i}])
        cd('..');
        rmdir([AutoDataProcessParameter.SubjectID{i}, '_detrend']);
        fprintf(['Moving Dtrended Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
end

%Filter
if (AutoDataProcessParameter.IsFilter==1)
    if (AutoDataProcessParameter.DataIsSmoothed==1)
        FunImgDir='FunImgNormalizedSmoothedDetrended';
    else
        FunImgDir='FunImgNormalizedDetrended';
    end
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir]);
    for i=1:AutoDataProcessParameter.SubjectNum
        rest_bandpass([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,filesep,AutoDataProcessParameter.SubjectID{i}], ...
					  AutoDataProcessParameter.Filter.ASamplePeriod, ...								  
					  AutoDataProcessParameter.Filter.ALowPass_HighCutoff, ...
					  AutoDataProcessParameter.Filter.AHighPass_LowCutoff, ...
					  AutoDataProcessParameter.Filter.AAddMeanBack, ...   %Revised by YAN Chao-Gan,100420. In according to the change of rest_bandpass.m. %AutoDataProcessParameter.Filter.ARetrend, ...
					  AutoDataProcessParameter.Filter.AMaskFilename);
    end
    
    %Copy the detrended files to DataProcessDir\FunImgNormalizedDetrendedFiltered or DataProcessDir\FunImgNormalizedSmoothedDetrendedFiltered
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir]);
    for i=1:AutoDataProcessParameter.SubjectNum
        cd([AutoDataProcessParameter.SubjectID{i}, '_filtered']);
        mkdir(['..',filesep,'..',filesep,FunImgDir,'Filtered',filesep,AutoDataProcessParameter.SubjectID{i}])
        movefile('*',['..',filesep,'..',filesep,FunImgDir,'Filtered',filesep,AutoDataProcessParameter.SubjectID{i}])
        cd('..');
        rmdir([AutoDataProcessParameter.SubjectID{i}, '_filtered']);
        fprintf(['Moving Filtered Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
    
    if AutoDataProcessParameter.IsDelDetrendedFiles==1
        cd(AutoDataProcessParameter.DataProcessDir);
        rmdir(FunImgDir,'s')
    end
end

%Calculate ReHo
if (AutoDataProcessParameter.IsCalReHo==1)
    if (AutoDataProcessParameter.DataIsSmoothed==1)
        FunImgDir='FunImgNormalizedSmoothedDetrendedFiltered';
    else
        FunImgDir='FunImgNormalizedDetrendedFiltered';
    end
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir]);
    mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ReHo']);
    for i=1:AutoDataProcessParameter.SubjectNum
        reho(         [AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,filesep,AutoDataProcessParameter.SubjectID{i}], ...
					  AutoDataProcessParameter.CalReHo.ClusterNVoxel, ...								  
					  AutoDataProcessParameter.CalReHo.AMaskFilename, ...
					  [AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ReHo',filesep,'ReHoMap_',AutoDataProcessParameter.SubjectID{i}]);
        rest_DivideMeanWithinMask([AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ReHo',filesep,'ReHoMap_',AutoDataProcessParameter.SubjectID{i}], ...
                                  [AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ReHo',filesep,'mReHoMap_',AutoDataProcessParameter.SubjectID{i}], ...
                                  AutoDataProcessParameter.CalReHo.AMaskFilename);
                              
        if AutoDataProcessParameter.CalReHo.smReHo == 1
            load([ProgramPath,filesep,'Jobmats',filesep,'Smooth.mat']);
            FileList=[{[AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ReHo',filesep,'mReHoMap_',AutoDataProcessParameter.SubjectID{i},'.img,1']}];
            jobs{1,1}.spatial{1,1}.smooth.data=[jobs{1,1}.spatial{1,1}.smooth.data;FileList];
            jobs{1,1}.spatial{1,1}.smooth.fwhm=AutoDataProcessParameter.Smooth.FWHM;
            if SPMversion==5
                spm_jobman('run',jobs);
            elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
                jobs = spm_jobman('spm5tospm8',{jobs});
                spm_jobman('run',jobs{1});
            else
                uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
                return
            end
        end                   
        if AutoDataProcessParameter.CalReHo.mReHo_1 == 1
            if AutoDataProcessParameter.CalReHo.smReHo == 1
                [Data Vox Head]=rest_readfile([AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ReHo',filesep,'smReHoMap_',AutoDataProcessParameter.SubjectID{i}]);
                Data=Data - 1;
                rest_WriteNiftiImage(Data,Head,[AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ReHo',filesep,'smReHo-1_Map_',AutoDataProcessParameter.SubjectID{i}]);
            else
                [Data Vox Head]=rest_readfile([AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ReHo',filesep,'mReHoMap_',AutoDataProcessParameter.SubjectID{i}]);
                Data=Data - 1;
                rest_WriteNiftiImage(Data,Head,[AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ReHo',filesep,'mReHo-1_Map_',AutoDataProcessParameter.SubjectID{i}]);
            end
        end
    end
end

%Calculate ALFF
if (AutoDataProcessParameter.IsCalALFF==1)
    if (AutoDataProcessParameter.DataIsSmoothed==1)
        FunImgDir='FunImgNormalizedSmoothedDetrendedFiltered';
    else
        FunImgDir='FunImgNormalizedDetrendedFiltered';
    end
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir]);
    mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ALFF']);
    for i=1:AutoDataProcessParameter.SubjectNum
        alff(         [AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,filesep,AutoDataProcessParameter.SubjectID{i}], ...
					  AutoDataProcessParameter.CalALFF.ASamplePeriod, ...								  
					  AutoDataProcessParameter.CalALFF.ALowPass_HighCutoff, ...
					  AutoDataProcessParameter.CalALFF.AHighPass_LowCutoff, ...
					  AutoDataProcessParameter.CalALFF.AMaskFilename, ...
					  [AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ALFF',filesep,'ALFFMap_',AutoDataProcessParameter.SubjectID{i}]);
        rest_DivideMeanWithinMask([AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ALFF',filesep,'ALFFMap_',AutoDataProcessParameter.SubjectID{i}], ...
                                  [AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ALFF',filesep,'mALFFMap_',AutoDataProcessParameter.SubjectID{i}], ...
                                  AutoDataProcessParameter.CalALFF.AMaskFilename);
        if AutoDataProcessParameter.CalALFF.mALFF_1 == 1
            [Data Vox Head]=rest_readfile([AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ALFF',filesep,'mALFFMap_',AutoDataProcessParameter.SubjectID{i}]);
            Data=Data - 1;
            rest_WriteNiftiImage(Data,Head,[AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'ALFF',filesep,'mALFF-1_Map_',AutoDataProcessParameter.SubjectID{i}]);
        end
    end
end

%Calculate fALFF
if (AutoDataProcessParameter.IsCalfALFF==1)
    if (AutoDataProcessParameter.DataIsSmoothed==1)
        FunImgDir='FunImgNormalizedSmoothedDetrended';
    else
        FunImgDir='FunImgNormalizedDetrended';
    end
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir]);
    mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'fALFF']);
    for i=1:AutoDataProcessParameter.SubjectNum
        f_alff(       [AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,filesep,AutoDataProcessParameter.SubjectID{i}], ...
					  AutoDataProcessParameter.CalfALFF.ASamplePeriod, ...								  
					  AutoDataProcessParameter.CalfALFF.ALowPass_HighCutoff, ...
					  AutoDataProcessParameter.CalfALFF.AHighPass_LowCutoff, ...
					  AutoDataProcessParameter.CalfALFF.AMaskFilename, ...
					  [AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'fALFF',filesep,'fALFFMap_',AutoDataProcessParameter.SubjectID{i}]);
        rest_DivideMeanWithinMask([AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'fALFF',filesep,'fALFFMap_',AutoDataProcessParameter.SubjectID{i}], ...
                                  [AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'fALFF',filesep,'mfALFFMap_',AutoDataProcessParameter.SubjectID{i}], ...
                                  AutoDataProcessParameter.CalfALFF.AMaskFilename);
        if AutoDataProcessParameter.CalfALFF.mfALFF_1 == 1
            [Data Vox Head]=rest_readfile([AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'fALFF',filesep,'mfALFFMap_',AutoDataProcessParameter.SubjectID{i}]);
            Data=Data - 1;
            rest_WriteNiftiImage(Data,Head,[AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'fALFF',filesep,'mfALFF-1_Map_',AutoDataProcessParameter.SubjectID{i}]);
        end
    end
end

%Remove Covaribles 
if (AutoDataProcessParameter.IsCovremove==1)
    if (AutoDataProcessParameter.DataIsSmoothed==1)
        FunImgDir='FunImgNormalizedSmoothedDetrendedFiltered';
    else
        FunImgDir='FunImgNormalizedDetrendedFiltered';
    end
    %Extract the Covaribles
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir]);
    mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,'Covs',filesep])
    %YAN Chao-Gan 091212.
    CovariatesROI=[];
    if (AutoDataProcessParameter.Covremove.WholeBrain==1)
        CovariatesROI=[CovariatesROI;{[ProgramPath,filesep,'Templates',filesep,'BrainMask_05_61x73x61.img']}];
    end
    if (AutoDataProcessParameter.Covremove.CSF==1)
        CovariatesROI=[CovariatesROI;{[ProgramPath,filesep,'Templates',filesep,'CsfMask_07_61x73x61.img']}];
    end
    if (AutoDataProcessParameter.Covremove.WhiteMatter==1)
        CovariatesROI=[CovariatesROI;{[ProgramPath,filesep,'Templates',filesep,'WhiteMask_09_61x73x61.img']}];
    end
    CovariatesROI=[CovariatesROI;AutoDataProcessParameter.Covremove.OtherCovariatesROI];
    for i=1:AutoDataProcessParameter.SubjectNum
        y_ExtractROISignal([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,filesep,AutoDataProcessParameter.SubjectID{i}], CovariatesROI, [AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,'Covs',filesep,AutoDataProcessParameter.SubjectID{i}], '', 1);
    end


    %Remove the Covariables
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir]);
    for i=1:AutoDataProcessParameter.SubjectNum
        if (AutoDataProcessParameter.Covremove.HeadMotion==1)
            DirRP=dir([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'rp*']);
            Covariables=load([AutoDataProcessParameter.DataProcessDir,filesep,'RealignParameter',filesep,AutoDataProcessParameter.SubjectID{i},filesep,DirRP.name]);
        else
            Covariables=[];
        end
        % YAN Chao-Gan, 101018
        if ~isempty(CovariatesROI)
            CovTC=load([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,'Covs',filesep,'ROISignals_',AutoDataProcessParameter.SubjectID{i},'.txt']);
            Covariables=[Covariables,CovTC];
        end

        save([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,'Covs',filesep,AutoDataProcessParameter.SubjectID{i},'_Covariables.txt'], 'Covariables', '-ASCII', '-DOUBLE','-TABS');
        ACovariablesDef.ort_file=[AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,'Covs',filesep,AutoDataProcessParameter.SubjectID{i},'_Covariables.txt'];
        ACovariablesDef.polort=0;    % YAN Chao-Gan, 101025. Will not remove linear trend in regressing out covariables step. %ACovariablesDef.polort=1;
        y_RegressOutImgCovariates([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,filesep,AutoDataProcessParameter.SubjectID{i}],ACovariablesDef,'_Covremoved','');
    end
    fprintf('\n');
    %Copy the Coviables Removed files to DataProcessDir\FunImgNormalizedDetrendedFilteredCovremoved or DataProcessDir\FunImgNormalizedSmoothedDetrendedFilteredCovremoved
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir]);
    for i=1:AutoDataProcessParameter.SubjectNum
        cd([AutoDataProcessParameter.SubjectID{i}, '_Covremoved']);
        mkdir(['..',filesep,'..',filesep,FunImgDir,'Covremoved',filesep,AutoDataProcessParameter.SubjectID{i}])
        movefile('*',['..',filesep,'..',filesep,FunImgDir,'Covremoved',filesep,AutoDataProcessParameter.SubjectID{i}])
        cd('..');
        rmdir([AutoDataProcessParameter.SubjectID{i}, '_Covremoved']);
        fprintf(['Moving Coviables Removed Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
end

%Extract AAL Time Cources (90 areas)
if (AutoDataProcessParameter.IsExtractAALTC==1)
    if (AutoDataProcessParameter.DataIsSmoothed==1)
        FunImgDir='FunImgNormalizedSmoothedDetrendedFilteredCovremoved';
    else
        FunImgDir='FunImgNormalizedDetrendedFilteredCovremoved';
    end
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir]);
    mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,'_AALTC',filesep])
    [AALData, Vox, Head] = rest_readfile([ProgramPath,filesep,'Templates',filesep,'AAL_61x73x61_YCG.nii']);
    for iAAL=1:90
        AreaName=['0',num2str(iAAL)];
        AreaName=AreaName(end-1:end);
        eval(['AAL',AreaName,'Index=find(AALData==',num2str(iAAL),');']);
    end
    for i=1:AutoDataProcessParameter.SubjectNum
        
        for iAAL=1:90
            AreaName=['0',num2str(iAAL)];
            AreaName=AreaName(end-1:end);
            eval(['AAL',AreaName,'TC=[];']);
        end
        
        [AllVolume,VoxelSize,theImgFileList, Header,nVolumn] =rest_to4d([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,filesep,AutoDataProcessParameter.SubjectID{i}]);
        [nDim1,nDim2,nDim3,nDim4]=size(AllVolume);
        
        AllVolume=reshape(AllVolume,[],nDim4);
        
        for iAAL=1:90
            AreaName=['0',num2str(iAAL)];
            AreaName=AreaName(end-1:end);
            eval(['Temp=mean(AllVolume(AAL',AreaName,'Index,:))'';']);
            eval(['AAL',AreaName,'TC=[AAL',AreaName,'TC;Temp];']);
        end
        
        save([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,'_AALTC',filesep,AutoDataProcessParameter.SubjectID{i},'_AALTC.mat'],'-regexp', 'AAL\w\wTC');
        fprintf(['Extract AAL Time Cources: ',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
end

%Extract ROI Time Cources
if (AutoDataProcessParameter.IsExtractROITC==1)
    if (AutoDataProcessParameter.DataIsSmoothed==1)
        FunImgDir='FunImgNormalizedSmoothedDetrendedFilteredCovremoved';
    else
        FunImgDir='FunImgNormalizedDetrendedFilteredCovremoved';
    end
    if (AutoDataProcessParameter.ExtractROITC.IsTalCoordinates==1)
        AutoDataProcessParameter.ExtractROITC.ROICenter=tal2icbm_spm(AutoDataProcessParameter.ExtractROITC.ROICenter);
    end
    ROIDef=[];
    for i=1:size(AutoDataProcessParameter.ExtractROITC.ROICenter,1)
        ROIDef=[ROIDef;{rest_SphereROI('ROIBall2Str', AutoDataProcessParameter.ExtractROITC.ROICenter(i,:), AutoDataProcessParameter.ExtractROITC.ROIRadius)}];
    end
    mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,'_ROITC',filesep])
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,'_ROITC',filesep]);
    %Extract the ROI time courses
    for i=1:AutoDataProcessParameter.SubjectNum
        y_ExtractROISignal([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,filesep,AutoDataProcessParameter.SubjectID{i}], ...
            ROIDef, ...
            [AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,'_ROITC',filesep,AutoDataProcessParameter.SubjectID{i}], ...
            '', ... % Will not restrict into the brain mask in extracting ROI signals
            0);
    end
end

%Extract REST defined ROI Time Cources
if (AutoDataProcessParameter.IsExtractRESTdefinedROITC==1)
    if (AutoDataProcessParameter.DataIsSmoothed==1)
        FunImgDir='FunImgNormalizedSmoothedDetrendedFilteredCovremoved';
    else
        FunImgDir='FunImgNormalizedDetrendedFilteredCovremoved';
    end
    mkdir([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,'_RESTdefinedROITC',filesep])
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,'_RESTdefinedROITC',filesep]);
    %Extract the ROI time courses
    for i=1:AutoDataProcessParameter.SubjectNum
        
        y_ExtractROISignal([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,filesep,AutoDataProcessParameter.SubjectID{i}], ...
            AutoDataProcessParameter.CalFC.ROIDef, ...
            [AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,'_RESTdefinedROITC',filesep,AutoDataProcessParameter.SubjectID{i}], ...
            '', ... % Will not restrict into the brain mask in extracting ROI signals
            0);
        
    end
end

%Functional Connectivity Calculation
if (AutoDataProcessParameter.IsCalFC==1)
    if (AutoDataProcessParameter.DataIsSmoothed==1)
        FunImgDir='FunImgNormalizedSmoothedDetrendedFilteredCovremoved';
    else
        FunImgDir='FunImgNormalizedDetrendedFilteredCovremoved';
    end
    cd([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir]);
    mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'FC']);
    for i=1:AutoDataProcessParameter.SubjectNum

        y_SCA([AutoDataProcessParameter.DataProcessDir,filesep,FunImgDir,filesep,AutoDataProcessParameter.SubjectID{i}], ...
            AutoDataProcessParameter.CalFC.ROIDef, ...
            [AutoDataProcessParameter.DataProcessDir,filesep,'Results',filesep,'FC',filesep,'FCMap_',AutoDataProcessParameter.SubjectID{i}], ...
            AutoDataProcessParameter.CalFC.AMaskFilename, ...
            0);
        
        % Fisher's r to z transformation has been performed inside y_SCA

    end
end


%****************************************************************Processing of T1 images*****************
%Reslice to 1x1x1
if (AutoDataProcessParameter.IsResliceT1To1x1x1==1)
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img']);
    for i=1:AutoDataProcessParameter.SubjectNum
        cd(AutoDataProcessParameter.SubjectID{i});
        T1ImgFile=dir('co*.img');
        y_Reslice(T1ImgFile.name,[T1ImgFile.name(1:end-4),'_1x1x1.img'],[1 1 1]);
        cd('..');
        fprintf(['Reslicing T1 image to 1x1x1:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
end

%Segment T1 images
if (AutoDataProcessParameter.IsT1Segment==1)
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1Img']);
    for i=1:AutoDataProcessParameter.SubjectNum
        cd(AutoDataProcessParameter.SubjectID{i});
        mkdir(['..',filesep,'..',filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i}]);
        if (AutoDataProcessParameter.IsResliceT1To1x1x1==1)
            copyfile('co*_1x1x1*',['..',filesep,'..',filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i}])
        else
            copyfile('co*',['..',filesep,'..',filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i}])
        end
        cd('..');
        fprintf(['Copying T1 image Files:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
    %Segment
    load([ProgramPath,filesep,'Jobmats',filesep,'Segment.mat']);
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment']);
    for i=1:AutoDataProcessParameter.SubjectNum
        SourceDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'co*.img']);
        SourceFile=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,SourceDir(1).name];
        if i~=1
            jobs=[jobs,{jobs{1,1}}];
        end
        [SPMPath, fileN, extn] = fileparts(which('spm.m'));
        jobs{1,i}.spatial{1,1}.preproc.opts.tpm={[SPMPath,filesep,'tpm',filesep,'grey.nii'];[SPMPath,filesep,'tpm',filesep,'white.nii'];[SPMPath,filesep,'tpm',filesep,'csf.nii']};
        jobs{1,i}.spatial{1,1}.preproc.data={SourceFile};
        fprintf(['Normalize-Segment Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
    if SPMversion==5
        spm_jobman('run',jobs);
    elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
        jobs = spm_jobman('spm5tospm8',{jobs});
        spm_jobman('run',jobs{1});
    else
        uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
        return
    end
end

%Wrap AAL image to native space
if (AutoDataProcessParameter.IsWrapAALToNative==1)
    cd([AutoDataProcessParameter.DataProcessDir]);
    for i=1:AutoDataProcessParameter.SubjectNum
        mkdir([AutoDataProcessParameter.DataProcessDir,filesep,'AAL',filesep,AutoDataProcessParameter.SubjectID{i}]);
        copyfile([ProgramPath,filesep,'Templates',filesep,'aal.nii'],[AutoDataProcessParameter.DataProcessDir,filesep,'AAL',filesep,AutoDataProcessParameter.SubjectID{i}]);
    end
    %Normalize-Write: Using the segment information
    load([ProgramPath,filesep,'Jobmats',filesep,'Normalize_Write.mat']);
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'AAL']);
    for i=1:AutoDataProcessParameter.SubjectNum
        cd(AutoDataProcessParameter.SubjectID{i});
        GMDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'c1co*.img']);
        GMFile=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,GMDir(1).name];
        [mn, mx, voxsize]= y_GetBoundingBox(GMFile);
        AALFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'AAL',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'aal.nii,1'];
        MatFileDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'*seg_inv_sn.mat']);
        MatFilename=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,MatFileDir(1).name];
        if i~=1
            jobs=[jobs,{jobs{1,1}}];
        end
        jobs{1,i}.spatial{1,1}.normalise{1,1}.write.subj.matname={MatFilename};
        jobs{1,i}.spatial{1,1}.normalise{1,1}.write.subj.resample={AALFilename};
        jobs{1,i}.spatial{1,1}.normalise{1,1}.write.roptions.bb=[mn;mx];
        jobs{1,i}.spatial{1,1}.normalise{1,1}.write.roptions.vox=voxsize;
        cd('..');
        fprintf(['Normalize-Write Setup:',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    fprintf('\n');
    if SPMversion==5
        spm_jobman('run',jobs);
    elseif SPMversion==8  %YAN Chao-Gan, 090925. SPM8 compatible.
        jobs = spm_jobman('spm5tospm8',{jobs});
        spm_jobman('run',jobs{1});
    else
        uiwait(msgbox('The current SPM version is not supported by DPARSF. Please install SPM5 or SPM8 first.','Invalid SPM Version.'));
        return
    end
    %Rename the wrapped AAL image
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'AAL']);
    for i=1:AutoDataProcessParameter.SubjectNum
        cd(AutoDataProcessParameter.SubjectID{i});
        eval(['!rename waal.nii T1s_',AutoDataProcessParameter.SubjectID{i},'_AAL.nii']);
        cd('..');
    end
end

%Extract AAL gray matter volume (90 areas)
if (AutoDataProcessParameter.IsExtractAALGMVolume==1)
    cd([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment']);
    for i=1:AutoDataProcessParameter.SubjectNum
        GMDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'c1co*.img']);
        GMFile=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,GMDir(1).name];
        WMDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'c2co*.img']);
        WMFile=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,WMDir(1).name];
        CSFDir=dir([AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'c3co*.img']);
        CSFFile=[AutoDataProcessParameter.DataProcessDir,filesep,'T1ImgSegment',filesep,AutoDataProcessParameter.SubjectID{i},filesep,CSFDir(1).name];
        [GMData,GMVox,GMHead]   = rest_readfile(GMFile);
        [WMData,WMVox,WMHead]   = rest_readfile(WMFile);
        [CSFData,CSFVox,CSFHead]   = rest_readfile(CSFFile);
        GroupGM(i,1)=sum(sum(sum(GMData))); GroupWM(i,1)=sum(sum(sum(WMData))); GroupCSF(i,1)=sum(sum(sum(CSFData)));
        ExcludeWmCsf_Logic=(WMData<0.5) & (CSFData<0.5);
        GroupGM_ExcludeWmCsf(i,1)=sum(GMData(find(ExcludeWmCsf_Logic>0)));
        [AALData, Vox, Head] = rest_readfile([AutoDataProcessParameter.DataProcessDir,filesep,'AAL',filesep,AutoDataProcessParameter.SubjectID{i},filesep,'T1s_',AutoDataProcessParameter.SubjectID{i},'_AAL.nii']);
        GroupGM_AAL(i,1)=sum(GMData(find(AALData>0)));
        AALData_ExcludeWmCsf=AALData.*ExcludeWmCsf_Logic;
        GroupGM_AAL_ExcludeWmCsf(i,1)=sum(GMData(find(AALData_ExcludeWmCsf>0)));
        for iAAL=1:90
            GroupAAL_MeanGM_ExcludeWmCsf(i,iAAL)=mean(GMData(find(AALData_ExcludeWmCsf==iAAL)));
            GroupAAL_MeanGM(i,iAAL)=mean(GMData(find(AALData==iAAL)));
            GroupAAL_SumGM_ExcludeWmCsf(i,iAAL)=sum(sum(sum(GMData(find(AALData_ExcludeWmCsf==iAAL)))));
            GroupAAL_SumGM(i,iAAL)=sum(sum(sum(GMData(find(AALData==iAAL)))));
        end
        fprintf(['Extract AAL GM volume: ',AutoDataProcessParameter.SubjectID{i},' OK']);
    end
    GroupBrainSize=GroupGM+GroupWM+GroupCSF;
    fprintf('\n');
    cd(AutoDataProcessParameter.DataProcessDir);
    save('AALGMVolume.mat','GroupGM','GroupWM','GroupCSF','GroupBrainSize','GroupGM_ExcludeWmCsf','GroupGM_AAL','GroupGM_AAL_ExcludeWmCsf','GroupAAL_MeanGM','GroupAAL_SumGM','GroupAAL_MeanGM_ExcludeWmCsf','GroupAAL_SumGM_ExcludeWmCsf');
end


rest_waitbar;  %Added by YAN Chao-Gan 091110. Close the rest waitbar after all the calculation.