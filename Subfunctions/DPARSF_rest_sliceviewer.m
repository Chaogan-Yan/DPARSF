function [varargout]=DPARSF_rest_sliceviewer(AOperation, varargin)
% Show a brain's slice. "DPARSF_rest_sliceviewer" can be opened more than one instance like MRIcro, and supports multi-slice, overlay and so on. by Xiao-Wei Song
%Usage: hFig =DPARSF_rest_sliceviewer('ShowImage', AFilename, CallBack);
%           DPARSF_rest_sliceviewer('Delete', AFigHandle);
%Detailed usage is the code file "DPARSF_rest_sliceviewer.m"
%------------------------------------------------------------------------------------------------------------------------------
%	Copyright(c) 2007~2010
%	State Key Laboratory of Cognitive Neuroscience and Learning, Beijing Normal University
%	Written by Xiao-Wei Song 
%	http://www.restfmri.net
% 	Mail to Authors:  <a href="Dawnwei.Song@gmail.com">SONG Xiao-Wei</a>; <a href="ycg.yan@gmail.com">YAN Chao-Gan</a>; <a href="dongzy08@gmail.com">DONG Zhang-Ye</a> 
%	Version=1.4;
%	Release=20100420;
%   Modified by SONG Xiao-Wei 20071101: change Position 
%   Modified by YAN Chao-Gan 080808: also support NIFTI (.img/.hdr) images.
%   Modified by YAN Chao-Gan 080903: also support NIFTI (.nii) images.
%   Modified by YAN Chao-Gan 090101: added "save image as" function; change the display mode of transverse multislices as similar to AFNI; fixed the bug of cluster size threshold.
%   Modified by YAN Chao-Gan 090401: added "Correction Thresholds by AlphaSim" (under Misc menu); Fixed the bug of 'Set Overlay's Color bar' in Matlab R2007a or latter version which caused by the revision of imresize funtion in Matlab R2007a.
%   Modified by YAN Chao-Gan 090601: added color bar similar as AFNI.
%   Modified by YAN Chao-Gan and DONG Zhang-Ye 090808: make the Cluster Connectivity Criterion could be chosen among 6 voxels (surface), 18 voxels (edge) or 26 voxels (corner) according to rmm value.
%   Modified by YAN Chao-Gan, DONG Zhang-Ye and ZHU Wei-Xuan 091105: added P<->T, P<->F, P<->Z, P<->R; reading df from SPM statistical images; only+; save thrd; cluster report functions; fixed the bugs of color, montage and resize.
%   Modified by YAN Chao-Gan and DONG Zhang-Ye 100201: Added False Discovery Rate (FDR) Correction.
%   Modified by DONG Zhang-Ye and YAN Chao-Gan 100420: Fixed a bug in displaying overlay with different bounding box from those of underlay.
%   Modified by YAN Chao-Gan 090919: For DPARSF's special use, printing normalize pictures.
%   Modified by YAN Chao-Gan 100420: updated for DPARSF's special use, printing normalize pictures.
%------------------------------------------------------------------------------------------------------------------------------

if nargin<1, %No param Launch, 20070918
	%help(mfilename); %YAN Chao-Gan 090919
	if nargout>=1,
		varargout{1}=DPARSF_rest_sliceviewer('ShowImage','');	%by Default, I show a black brain image
	else
		DPARSF_rest_sliceviewer('ShowImage','');	%by Default, I show a black brain image
	end
	return; 
end

%Initializitation
global DPARSF_rest_sliceviewer_Cfg; %YAN Chao-Gan, 090919. %persistent REST_SliceViewer_Cfg; % run-time persistent config
%if isempty(DPARSF_rest_sliceviewer_Cfg), disp('ko'); end
if ~mislocked(mfilename),mlock; end
%For further Debug, 20070915, to make sure the Config variable exist
% if isempty(DPARSF_rest_sliceviewer_Cfg), 
	% DPARSF_rest_sliceviewer_Cfg =getappdata(0, 'DPARSF_rest_sliceviewer_Cfg');
% else
	% setappdata(0, 'DPARSF_rest_sliceviewer_Cfg', DPARSF_rest_sliceviewer_Cfg);
% end

try
	switch upper(AOperation),
	case 'SHOWIMAGE',	%ShowImage
		if nargin==2,
			%DPARSF_rest_sliceviewer('ShowImage', theBrainMap); %reho_gui.m 989
			AFilename =varargin{1};
			ACallback ='';		
	    elseif nargin==3,
			%DPARSF_rest_sliceviewer('ShowImage', theBrainMap, [theCallback cmdClearVar], 'Power Spectrum');%reho_gui.m 1010
			AFilename =varargin{1};
			ACallback =varargin{2};		
		else
			error(sprintf('Usage: hFig =DPARSF_rest_sliceviewer(''ShowImage'', AFilename); \n\t hFig =DPARSF_rest_sliceviewer(''ShowImage'', AFilename, ACallback);')); 
		end
	    
		%Let current handle of the figure be a GUID for the current SliceViewer
		% theFig =ExistDisplayFigure(DPARSF_rest_sliceviewer_Cfg, AFilename);
		% isExistFig =rest_misc( 'ForceCheckExistFigure' , theFig);	%Force check whether the figure exist
		% if ~isExistFig
			%the specific image didn't exist, so I create one
			DPARSF_rest_sliceviewer_Cfg.Config(1+GetDisplayCount(DPARSF_rest_sliceviewer_Cfg)) =InitControls(AFilename, ACallback);
			%To Force display following the end of this if-clause
			theFig =DPARSF_rest_sliceviewer_Cfg.Config(GetDisplayCount(DPARSF_rest_sliceviewer_Cfg)).hFig;
			
			%I don't display the information defaultly
			ToggleInfoDisplay(DPARSF_rest_sliceviewer_Cfg.Config(GetDisplayCount(DPARSF_rest_sliceviewer_Cfg)));
		% end
		figure(theFig);	
		varargout{1} =theFig;
			
	case 'UPDATECALLBACK', 		%UpdateCallback
		if nargin==2, 
			AFigHandle =varargin{1};
			ACallback ='';	
			ACallbackCaption='';
		elseif nargin==3, 
			AFigHandle =varargin{1};
			ACallback =varargin{2};	
			ACallbackCaption='';
		elseif nargin==4, 
			AFigHandle =varargin{1};
			ACallback =varargin{2};	
			ACallbackCaption=varargin{3};	
		else
			error('Usage: DPARSF_rest_sliceviewer(''UpdateCallback'', AFigureHandle, ACallback, ACallbackCaption);'); 
		end
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =UpdateCallback(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal), ACallback, ACallbackCaption);
			ResizeFigure(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
		end
		
		
	case 'DELETE', % Delete specific figure
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''Delete'', AFigHandle);'); end
		AFigHandle =varargin{1};
		DPARSF_rest_sliceviewer_Cfg =DeleteFigure(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		
		if ~GetDisplayCount(DPARSF_rest_sliceviewer_Cfg),
			DPARSF_rest_sliceviewer('QuitAllSliceViewer');
		end
		
	case {'CLICKPOSITION', 'SETPOSITION'},		%ClickPosition	%SetPosition
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''ClickPosition'', AFigHandle); or DPARSF_rest_sliceviewer(''SetPosition'', AFigHandle);'); end
		AFigHandle =varargin{1};
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0
			if strcmpi(AOperation, 'ClickPosition'),	% for Mouse click
				if strcmpi(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).ViewMode, 'Orthogonal'),
					DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =ClickPositionCrossHair(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));		
				elseif strcmpi(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).ViewMode, 'Sagittal'),
					DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =ClickPositionInSagittalMode(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
				elseif strcmpi(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).ViewMode, 'Coronal'),
					DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =ClickPositionInCoronalMode(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
				elseif strcmpi(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).ViewMode, 'Transverse'),
					DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =ClickPositionInTransverseMode(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
				end
			elseif strcmpi(AOperation, 'SetPosition'), % for [x y z] manual input
				DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetPositionCrossHair(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
			end		
					
			
			%If yoke, then update all yoked image
			isSelfYoked =get(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hYoke, 'Value');
			if isSelfYoked ,
				theDistanceFromOrigin =(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).LastPosition -DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Origin) .* DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).VoxelSize;
				%Dawnsong 20071102 Revise to make sure the left image/Right brain is +
				theDistanceFromOrigin =[-1, 1, 1].* theDistanceFromOrigin;
				
				for x=1:GetDisplayCount(DPARSF_rest_sliceviewer_Cfg), 
					if x~=theCardinal ,
						isYoked =get(DPARSF_rest_sliceviewer_Cfg.Config(x).hYoke, 'Value');
						if isYoked, 							
							DPARSF_rest_sliceviewer('SetPhysicalPosition', DPARSF_rest_sliceviewer_Cfg.Config(x).hFig, theDistanceFromOrigin);
						end
					end
				end
			end	
			
			%Execute the Callback
			DPARSF_rest_sliceviewer('RunCallback', AFigHandle);			
		end
		
	case 'SETPHYSICALPOSITION',		%SetPhysicalPosition, for Yoke, the physical position(mm) from the origin
		if nargin~=3, error('Usage: DPARSF_rest_sliceviewer(''SetPhysicalPosition'', AFigHandle, ADistanceFromOrigin);'); end
		AFigHandle =varargin{1};
		ADistanceFromOrigin =varargin{2};
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			%Dawnsong 20071102 Revise to make sure the left image/Right brain is +
			ADistanceFromOrigin =[-1, 1, 1].* ADistanceFromOrigin;

			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetDistanceFromOrigin(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal), ADistanceFromOrigin);
			
			%Execute the Callback
			DPARSF_rest_sliceviewer('RunCallback', AFigHandle);	
		end		
	case 'RUNCALLBACK', 			%RunCallback	, 20070625
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''RunCallback'', AFigHandle);'); end
		AFigHandle =varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0		
			% Run the Callback
			if ~isempty(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Callback) 
				if ischar(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Callback),
					eval(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Callback); %run callback for caller
				elseif isa(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Callback, 'function_handle')
					%I give 2 parameters, 20070624
					%1) position: X, Y , Z, 
					%2) and 3-dim: XSize, YSize, ZSize
					thePos =DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).LastPosition;
					theSize=size(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Volume);
					DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Callback(thePos, theSize);
				end
			end		
		end
		
		
	case 'GETPOSITION', 		%GetPosition, return Absolute	position where current cross-hair stay
		if nargin~=2, error('Usage: Position =DPARSF_rest_sliceviewer(''GetPosition'', AFigHandle);'); end
		AFigHandle =varargin{1};
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0
			varargout{1}=DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).LastPosition;	 
		end
		
	case 'GETPHYSICALPOSITION', 		%GetPhysicalPosition return Coordinate .* VoxelSize	(mm)
		if nargin~=2, error('Usage: DistanceFromOrigin =DPARSF_rest_sliceviewer(''GetPhysicalPosition'', AFigHandle);'); end
		AFigHandle =varargin{1};
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0
			thePosition =DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).LastPosition;	 
			theOrigin  	=DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Origin;
			theVoxelSize=DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).VoxelSize;
			varargout{1} =(thePosition - theOrigin) * theVoxelSize;
		end	

	case 'SETMESSAGE',			%SetMessage, update the Message, I don't contain the Copyright any more , 20070915
		if nargin~=3, error('Usage: DPARSF_rest_sliceviewer(''SetMessage'', AFigHandle, AMessage);'); end
		AFigHandle 	=varargin{1};
		AMessage	=varargin{2};
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Message =AMessage;
			SetMessage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
			ResizeFigure(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
		end	
		
	case 'MAGNIFY', 		%Magnify, x0.5 -x1 -x2 -x3 -x4 -x5 -x6
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''Magnify'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));			
		end	
		
	case 'QUITALLSLICEVIEWER',		%QuitAllSliceViewer
		if nargin~=1, error('Usage: DPARSF_rest_sliceviewer(''QuitAllSliceViewer'');'); end
		for x=GetDisplayCount(DPARSF_rest_sliceviewer_Cfg):-1:1, % DawnSong, revised 20070625
			DPARSF_rest_sliceviewer('DELETE', DPARSF_rest_sliceviewer_Cfg.Config(x).Filename);
		end
		if mislocked(mfilename),munlock; end
		clear DPARSF_rest_sliceviewer_Cfg;
		
	case 'MONTAGE', 		%Montage	
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''Montage'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			prompt ={'Across: (i.e. the number of columns)', 'Down: (i.e. the number of rows)', 'Spacing(voxels): ', 'Whether to show coordinate''s label: (1=yes and 0=no.)'};
			def	={	int2str(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Montage.Across), ...
					int2str(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Montage.Down), ...
					int2str(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Montage.Spacing), ...
					int2str(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Montage.WantLabel)};
			answer =inputdlg(prompt, 'Montage Set', 1, def);
			if numel(answer)==4,
				theVal =abs(round(str2num(answer{1})));
				if theVal==0, theVal=1; end
				DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Montage.Across = theVal;
				theVal =abs(round(str2num(answer{2})));
				if theVal==0, theVal=1; end
				DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Montage.Down =theVal;
				DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Montage.Spacing = abs(round(str2num(answer{3})));
				DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Montage.WantLabel = abs(round(str2num(answer{4})));
				%Update Image Display
				DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
			end
		end;
     case 'DF'
         if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''Montage'', AFigHandle);'); end
         AFigHandle 	=varargin{1};
         theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
         if theCardinal>0,
             if isfield(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.Header,'descrip')
                 headinfo=DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.Header.descrip; %dong 090921AConfig.Df.Ttest=0;
                 if ~isempty(strfind(headinfo,'{T_['))% dong 100331 begin
                     testFlag='T';
                     Tstart=strfind(headinfo,'{T_[')+length('{T_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 elseif ~isempty(strfind(headinfo,'{F_['))
                     testFlag='F';
                     Tstart=strfind(headinfo,'{F_[')+length('{F_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 elseif ~isempty(strfind(headinfo,'{R_['))
                     testFlag='R';
                     Tstart=strfind(headinfo,'{R_[')+length('{R_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 elseif ~isempty(strfind(headinfo,'{Z_['))
                     testFlag='Z';
                     Tstart=strfind(headinfo,'{Z_[')+length('{Z_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 end
                 if exist('testFlag')
                     if ~isempty(testFlag)
                         if exist('testDf')
                             if testFlag == 'T'
                                 DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Ttest=testDf;
                             elseif testFlag == 'F'
                                 DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Ftest=testDf;
                             elseif testFlag == 'R'
                                 DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Rtest=testDf;
                             elseif testFlag == 'Z'
                                 DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Ztest=testDf;
                             end
                         end % dong 100331 end
                     end
                 end
             end
             prompt ={'T-test (1 df) (two-tailed). For one sample T-test or paired T-test: df=n-1; for two sample T-test: df=n1+n2-2. (0 means not T-test).', 'F-test (2 df) (one-tailed). For one-way ANOVA (with s levels and n subjects): df1=s-1, df2=n-s. (0 means not F-test).','Z-test (two-tailed). 1 means Z-test. (0 means not Z-test)','R-test (1 df) (two-tailed). For Pearson''s Correlation Coefficient (with n samples): df=n-2. (0 means not R-test)'};
             def	={	int2str(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Ttest), ...
                 int2str(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Ftest), ...
                 int2str(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Ztest), ...
                 int2str(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Rtest), ...
                 };
             options.Resize='on';
             options.WindowStyle='modal';
             options.Interpreter='tex';
             answer =inputdlg(prompt, 'Input DF manually ', 1, def,options);
             if numel(answer)==4,
                 theVal =abs(round(str2num(answer{1})));
                 DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Ttest = theVal;
                 theVal =abs(round(str2num(answer{2})));
                 DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Ftest = theVal;
                 theVal =abs(round(str2num(answer{3})));
                 DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Ztest = theVal;
                 theVal =abs(round(str2num(answer{4})));
                 DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Rtest = theVal;
                 SetMessage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
             end
         end;
	case 'ORTHOGONALVIEW', 		%OrthogonalView
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''OrthogonalView'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).ViewMode ='Orthogonal';
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
		end;	
		
	case 'TRANSVERSEVIEW', 		%TransverseView
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''TransverseView'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).ViewMode ='Transverse';
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
		end;
			
	case 'SAGITTALVIEW', 		%SagittalView
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''SagittalView'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).ViewMode ='Sagittal';
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
		end;

	case 'CORONALVIEW', 		%CoronalView
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''CoronalView'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).ViewMode ='Coronal';
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
		end;

	case 'REPAINT',		%Repaint	
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''Repaint'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,		
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
		end;
	case 'MNI/TALAIRACH',		%MNI/Talairach
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''Repaint'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,		
			Transforming_MNI_Talairach(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
			DPARSF_rest_sliceviewer('SetPosition', AFigHandle);
		end;
		
	case 'CHANGEUNDERLAY', 		%ChangeUnderlay
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''ChangeUnderlay'', AFigHandle);'); end
		AFigHandle 	=varargin{1};
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			%Get the changed Underlay file
			theNewUnderlay =get(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hUnderlayFile, 'String');
			% if exist(theNewUnderlay,'file')==2,
			% if ~all(isspace(theNewUnderlay)),	%20070918
				%Set the current underlay
				DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Filename =theNewUnderlay;
				DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =InitUnderlay(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
                % YAN Chao-Gan and DONG Zhang-Ye, 100401.
                if all(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).VoxelSize~=[1 1 1])
                    msgbox('The voxel size of the underlay is not 1x1x1. If you want to add functional overlay to this structural underlay, the location may be not correct, please be careful!','Warning!')
                end
                if isfield(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Header,'mat')
                    matinfo=DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Header.mat;
                    if ~(matinfo(1,2)==0&&matinfo(1,3)==0&&matinfo(2,1)==0&&matinfo(2,3)==0&&matinfo(3,1)==0&&matinfo(3,2)==0&&matinfo(4,1)==0&&matinfo(4,2)==0&&matinfo(4,3)==0);
                        msgbox('This NIfTI image includes an rotation transformation. You should reslice this data before attempting to underlay the image.','Warning!')
                    end
                end
                
                DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
                set(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hUnderlayFile, 'String', theNewUnderlay, 'TooltipString', theNewUnderlay);
			% end
		end;
		
	case 'UNDERLAYSELECTION', 		%UnderlaySelection	
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''UnderlaySelection'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,			
			[filename, pathname] = uigetfile({'*.img', 'ANALYZE or NIFTI files (*.img)';'*.nii','NIFTI files (*.nii)'}, ...
															'Pick one brain map');
			if any(filename~=0) && ischar(filename) && length(filename)>4 ,	% not canceled and legal			
				if ~strcmpi(pathname(end), filesep)%revise pathname to add \ or /
					pathname = [pathname filesep];
				end
				theBrainMap =[pathname filename];
				set(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hUnderlayFile, 'String', theBrainMap);
				DPARSF_rest_sliceviewer('ChangeUnderlay', AFigHandle);
			end			
		end;
	case 'CLICKRECENTUNDERLAY', 	%ClickRecentUnderlay
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''ClickRecentUnderlay'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,			
			theIndex =get(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hUnderlayRecent, 'Value');
			if theIndex>1,
				theBrainMap =DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Recent.Underlay{theIndex-1};
				set(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hUnderlayFile, 'String', theBrainMap);
				set(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hUnderlayRecent, 'Value', 1);
				DPARSF_rest_sliceviewer('ChangeUnderlay', AFigHandle);				
			end
		end;
		
	case 'CHANGEOVERLAY', 		%ChangeOverlay
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''ChangeOverlay'', AFigHandle);'); end
		AFigHandle 	=varargin{1};
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			%Get the changed Overlay file
			theNewOverlay =get(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hOverlayFile, 'String');
			% if exist(theNewOverlay,'file')==2,
			% if ~all(isspace(theNewOverlay)),
				%Set the current Overlay
                DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =LoadOverlay(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal), theNewOverlay);
                % YAN Chao-Gan and DONG Zhang-Ye, 100401.
                if isfield(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.Header,'mat')
                    matinfo=DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.Header.mat;
                    if ~(matinfo(1,2)==0&&matinfo(1,3)==0&&matinfo(2,1)==0&&matinfo(2,3)==0&&matinfo(3,1)==0&&matinfo(3,2)==0&&matinfo(4,1)==0&&matinfo(4,2)==0&&matinfo(4,3)==0);
                        msgbox('This NIfTI image includes an rotation transformation. You should reslice this data before attempting to overlay the image.','Warning!')
                    end
                end
                set(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hSeeOverlay, 'Value', 1);
				DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
				set(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hOverlayFile, 'String', theNewOverlay, 'TooltipString', theNewOverlay);
			% end
		end;
		
	case 'OVERLAYSELECTION', 		%OverlaySelection	
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''UnderlaySelection'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,		
			[filename, pathname] = uigetfile({'*.img', 'ANALYZE or NIFTI files (*.img)';'*.nii','NIFTI files (*.nii)'}, ...
															'Pick one brain map');
			if any(filename~=0) && ischar(filename) && length(filename)>4 ,	% not canceled and legal			
				if ~strcmpi(pathname(end), filesep)%revise pathname to add \ or /
					pathname = [pathname filesep];
				end
				theBrainMap =[pathname filename];
				set(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hOverlayFile, 'String', theBrainMap);
                set(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hEdtPValue, 'String', '1');  %DONG 100118 change the init P value
				DPARSF_rest_sliceviewer('ChangeOverlay', AFigHandle);
                if isfield(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.Header,'descrip')   %DONG 100118 to read the DF when overlay selected.
                headinfo=DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.Header.descrip; %dong 090921AConfig.Df.Ttest=0;
               if isfield(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.Header,'descrip')
                 headinfo=DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.Header.descrip; %dong 090921AConfig.Df.Ttest=0;
                 if ~isempty(strfind(headinfo,'{T_['))% dong 100331 begin
                     testFlag='T';
                     Tstart=strfind(headinfo,'{T_[')+length('{T_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 elseif ~isempty(strfind(headinfo,'{F_['))
                     testFlag='F';
                     Tstart=strfind(headinfo,'{F_[')+length('{F_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 elseif ~isempty(strfind(headinfo,'{R_['))
                     testFlag='R';
                     Tstart=strfind(headinfo,'{R_[')+length('{R_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 elseif ~isempty(strfind(headinfo,'{Z_['))
                     testFlag='Z';
                     Tstart=strfind(headinfo,'{Z_[')+length('{Z_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 end
                 if exist('testFlag')
                     if ~isempty(testFlag)
                         if exist('testDf')
                             if testFlag == 'T'
                                 DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Ttest=testDf;
                             elseif testFlag == 'F'
                                 DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Ftest=testDf;
                             elseif testFlag == 'R'
                                 DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Rtest=testDf;
                             elseif testFlag == 'Z'
                                 DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Df.Ztest=testDf;
                             end
                         end % dong 100331 end
                     end
                 end
               end
                end
            end
        end
	case 'CLICKRECENTOVERLAY', 	%ClickRecentOverlay
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''ClickRecentOverlay'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,			
			theIndex =get(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hOverlayRecent, 'Value');
			if theIndex>1,
				theBrainMap =DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Recent.Overlay{theIndex-1};
				set(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hOverlayFile, 'String', theBrainMap);
				set(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hOverlayRecent, 'Value', 1);
				DPARSF_rest_sliceviewer('ChangeOverlay', AFigHandle);
			end
		end;
		
	case 'OVERLAY_SETTHRDABSVALUE',		%Overlay_SetThrdAbsValue, %Change from the Absolute value Edit control
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''Overlay_SetThrdAbsValue'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.ValueThrdAbsolute =SetThrdAbsValue(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =ThresholdOverlayVolume(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));			
		end	
	case 'OVERLAY_SETTHRDCLUSTERSIZE', 		%Overlay_SetThrdClusterSize
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''Overlay_SetThrdClusterSize'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
		 DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.PNflag=0;
			theConfig =DPARSF_rest_sliceviewer_Cfg.Config(theCardinal);
			prompt ={'Set Cluster Size(voxel) must be GREATER than: ', 'Set Volume (mm^3) must be GREATER than: (this value would be transformed to Cluster Size according to the Overlay''s size and its voxel''s size)','!!!Set rmm value as Connectivity Criterion. If your voxel size is 3*3*3, then rmm=4 means 6 voxels (surface connected), rmm=5 means 18 voxels (edge connected, SPM use this criterion), and rmm=6 means 26 voxels (corner connected). You also can type ''SPM_Criterion'' if you want to use SPM''s criterion (18 voxels, edge connected). Note: just suitable for cube voxels currently.'};
			def	={num2str(theConfig.Overlay.ClusterSizeThrd) ,...
				  num2str(theConfig.Overlay.ClusterSizeThrd*(theConfig.Overlay.VoxelSize(1)*theConfig.Overlay.VoxelSize(2)*theConfig.Overlay.VoxelSize(3))) ,...
                  num2str(theConfig.Overlay.ClusterConnectivityCriterionRMM)}; %Added Cluster Connectivity Criterion option by YAN Chao-Gan 090711.
			answer =inputdlg(prompt, 'Threshold by cluster size ', 1, def);
			if numel(answer)==3,
				theVal =abs(str2num(answer{1}));
                if theVal~=theConfig.Overlay.ClusterSizeThrd
                    theConfig.Overlay.ClusterSizeThrd =round(theVal);
                else
                    theVal =abs(str2num(answer{2}));
                    theConfig.Overlay.ClusterSizeThrd =round(theVal/(theConfig.Overlay.VoxelSize(1)*theConfig.Overlay.VoxelSize(2)*theConfig.Overlay.VoxelSize(3)));
                end
				
                theVal =abs(str2num(answer{3}));
                if isempty (theVal)
                    theConfig.Overlay.ClusterConnectivityCriterionRMM='SPM_Criterion';
                    theConfig.Overlay.ClusterConnectivityCriterion=18;
                else
                    theConfig.Overlay.ClusterConnectivityCriterionRMM=theVal;
                    if theVal < theConfig.Overlay.VoxelSize(1)
                        theConfig.Overlay.ClusterConnectivityCriterion = 0;
                    elseif theVal < theConfig.Overlay.VoxelSize(1)*sqrt(2)
                        theConfig.Overlay.ClusterConnectivityCriterion = 6;
                    elseif theVal < theConfig.Overlay.VoxelSize(1)*sqrt(3)
                        theConfig.Overlay.ClusterConnectivityCriterion = 18;
                    else
                        theConfig.Overlay.ClusterConnectivityCriterion = 26;
                    end
                    if theConfig.Overlay.ClusterConnectivityCriterion==0
                        uiwait(msgbox('The Connectivity Criterion has been set to 0, no voxels would be considered as connected, thus no cluster can be found.','Warning for Cluster Connectivity Criterion','warn'));
                    end
                end
               
				DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =theConfig;
				DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =ThresholdOverlayVolume(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
				DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
			end			
		end	
	case 'OVERLAY_MISC', 		%Overlay_Misc
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''Overlay_Misc'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =Overlay_Misc(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
			DPARSF_rest_sliceviewer('Repaint', AFigHandle);
		end	
	case 'OPEN_TEMPLATE', 		%Open_Template
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''Overlay_Misc'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =Open_Template(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));			
			DPARSF_rest_sliceviewer('Repaint', AFigHandle);	
        end	
    case 'CLUSTERSREPORT'
        if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''Clusters Report'', AFigHandle);'); end
        
        AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
       if theCardinal>0,
           theConfig =DPARSF_rest_sliceviewer_Cfg.Config(theCardinal);
           if theConfig.Overlay.ClusterConnectivityCriterion==0  % Revised by YAN Chao-Gan 091126. Check if rmm is not zero.
               uiwait(msgbox({'Please set Cluster Connectivity Criterion (rmm value or SPM_Criterion) by clicking Cluser Size button first.';...
                   },'Set Cluster Connectivity Criterion first!'));
               return;
           end
          if ~isempty(find(theConfig.Overlay.VolumeThrd))
                 rest_report( theConfig.Overlay.VolumeThrd,theConfig.Overlay.Header,theConfig.Overlay.ClusterConnectivityCriterion);
          else 
              disp('There is no Cluster !');
          end
       end
	case 'CURRENTTHRD2MASK',	%dong save thrd2mask 2009-09-09
        if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''CurrentThrd2Mask'', AFigHandle);'); end
        AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
       if theCardinal>0,
			theConfig =DPARSF_rest_sliceviewer_Cfg.Config(theCardinal);
            theConfig.Overlay.VolumeThrd(theConfig.Overlay.VolumeThrd<0.0002)=0;
            if theConfig.Overlay.ClusterConnectivityCriterion==0  % Revised by YAN Chao-Gan 091126. Check if rmm is not zero.
                uiwait(msgbox({'Please set Cluster Connectivity Criterion (rmm value or SPM_Criterion) by clicking Cluser Size button first.';...
                    },'Set Cluster Connectivity Criterion first!'));
                return;
            end
			theMask =CurrentThrd2Mask(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
			if ~isempty(theMask),
				[filename, pathname] = uiputfile('*.img','Save all the survived clusters: ');
				if isequal(filename,0) || isequal(pathname,0),
				else
					if length(filename)>4,						
						if strcmpi(filename(end-3:end), '.img')
						  filename = filename(1:end-4);
						end
					end
					theMaskFile =fullfile(pathname, filename);	
                    theConfig.Overlay.Header.Origin=theConfig.Overlay.Origin; %%Yan 080610
					rest_writefile(theMask, theMaskFile, size(theConfig.Overlay.Volume), ...
								theConfig.Overlay.VoxelSize, theConfig.Overlay.Header,'double');%'int16'); %%Yan 080610
					theConfig.LastSavedMask =[theMaskFile ,'.img'];
					if ~isempty(theConfig.Callback.Save2Mask),
						eval(theConfig.Callback.Save2Mask);
					end
				end				
				DPARSF_rest_sliceviewer('Repaint', AFigHandle);
            else
				errordlg(sprintf('No cluster found at (%s)', ...
					num2str(Pos_Underlay2Overlay(theConfig, theConfig.LastPosition) -theConfig.Overlay.Origin)));
            end	
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =theConfig;
		end	
	case 'CURRENTCLUSTER2MASK',			%CurrentCluster2Mask
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''CurrentCluster2Mask'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			theConfig =DPARSF_rest_sliceviewer_Cfg.Config(theCardinal);
             if theConfig.Overlay.ClusterConnectivityCriterion==0  % Revised by YAN Chao-Gan 091126. Check if rmm is not zero.
                uiwait(msgbox({'Please set Cluster Connectivity Criterion (rmm value or SPM_Criterion) by clicking Cluser Size button first.';...
                    },'Set Cluster Connectivity Criterion first!'));
                return;
            end
			theMask =CurrentCluster2Mask(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
			if ~isempty(theMask),
				[filename, pathname] = uiputfile('*.img','Save current point''s cluster: ');
				if isequal(filename,0) | isequal(pathname,0),
				else
					if length(filename)>4,						
						if strcmpi(filename(end-3:end), '.img')
						  filename = filename(1:end-4);
						end
					end
					theMaskFile =fullfile(pathname, filename);	
                    theConfig.Overlay.Header.Origin=theConfig.Overlay.Origin; %%Yan 080610
					 rest_writefile(theMask, theMaskFile, size(theConfig.Overlay.Volume), ...
                        theConfig.Overlay.VoxelSize, theConfig.Overlay.Header,'double');%int16 %%Yan 080610
                    %Added by YAN Chao-Gan 091127. Also save binary mask. 
                    theBinaryMaskFile=fullfile(pathname, ['BinaryMask_',filename]);
                    rest_writefile(theMask~=0, theBinaryMaskFile, size(theConfig.Overlay.Volume), ...
                        theConfig.Overlay.VoxelSize, theConfig.Overlay.Header,'double');
                    theConfig.LastSavedMask =[theMaskFile ,'.img'];
					if ~isempty(theConfig.Callback.Save2Mask),
						eval(theConfig.Callback.Save2Mask);
					end
				end				
				DPARSF_rest_sliceviewer('Repaint', AFigHandle);
			else
				errordlg(sprintf('No cluster found at (%s)', ...
					num2str(Pos_Underlay2Overlay(theConfig, theConfig.LastPosition) -theConfig.Overlay.Origin)));
			end
			
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =theConfig;
		end	
	
	case 'SAVERECENT',		%SaveRecent		
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''SaveRecent'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			SaveRecent(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal), 'RecentOverlay');
			SaveRecent(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal), 'RecentUnderlay');
		end
		
	case 'CHANGECOLORELEMENT', 		%ChangeColorElement
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''ChangeColorElement'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetColorElements(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
		end
		
	case 'TOGGLEINFODISPLAY', 		%ToggleInfoDisplay
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''ToggleInfoDisplay'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			ToggleInfoDisplay(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
		end
	
	case 'UPDATECALLBACK_SAVE2MASK',	%UpdateCallback_Save2Mask
		if nargin~=3, error('Usage: DPARSF_rest_sliceviewer(''UpdateCallback_Save2Mask'', AFigHandle, ACallback);'); end
		AFigHandle 	=varargin{1};	
		ACallback   =varargin{2};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Callback.Save2Mask =ACallback;			
		end
	case 'GETSAVEDMASKFILENAME',		%GetSavedMaskFilename
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''GetSavedMaskFilename'', AFigHandle);'); end
		AFigHandle 	=varargin{1};			
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			varargout{1} =DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).LastSavedMask;
		else
			varargout{1} ='';
		end
		
	case 'SHOWOVERLAY',	%ShowOverlay
		if nargin>3, error('Usage: DPARSF_rest_sliceviewer(''ShowOverlay'', AOverlay); or DPARSF_rest_sliceviewer(''ShowOverlay'', AFigHandle, AOverlay);'); end
		AFigHandle 	=varargin{1};
		if ~ischar(AFigHandle),
			AOverlay    =varargin{2};
			theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
			if theCardinal>0,
				set(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).hOverlayFile, 'String', AOverlay);
				DPARSF_rest_sliceviewer('ChangeOverlay', AFigHandle);
			end
		else	%I will create a new slice-viewer
			AOverlay    =varargin{1};
			theFig = DPARSF_rest_sliceviewer; %I can't write "()" considering Matlab 6.5 compatiable
			DPARSF_rest_sliceviewer('ShowOverlay', theFig, AOverlay);
			varargout{1} =theFig;
		end
	
	case 'ONKEYPRESS',		%OnKeyPress
		if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''OnKeyPress'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =OnKeyPress(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
			%For Updating
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));
			%For Yoke
			DPARSF_rest_sliceviewer('SetPosition', AFigHandle);
        end
     case 'ONLYPOSITIVE',	%dong 2009-09-09
        if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''Overlay_SetThrdAbsValue'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
            %dong 100327 beging
            if DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.PNflag==0
                DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeForFlag=DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeThrd;
                DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.PNflag=1;
            end
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeThrd(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeForFlag<0)=0;
            DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeThrd(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeForFlag>DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.ValueThrdAbsolute)=DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeForFlag(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeForFlag>DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.ValueThrdAbsolute);
            %dong 100327 end
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));			
        end	
     case 'ONLYNEGATIVE',	%dong 2009-09-09
        if nargin~=2, error('Usage: DPARSF_rest_sliceviewer(''Overlay_SetThrdAbsValue'', AFigHandle);'); end
		AFigHandle 	=varargin{1};	
		theCardinal =ExistViewer(DPARSF_rest_sliceviewer_Cfg, AFigHandle);
		if theCardinal>0,
			%dong 100327 begin
            if DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.PNflag==0
                DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeForFlag=DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeThrd;
                DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.PNflag=1;
            end
            DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeThrd(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeForFlag>0)=0;
            DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeThrd(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeForFlag<-DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.ValueThrdAbsolute)=DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeForFlag(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.VolumeForFlag<-DPARSF_rest_sliceviewer_Cfg.Config(theCardinal).Overlay.ValueThrdAbsolute);
           %dong 100327 end
			DPARSF_rest_sliceviewer_Cfg.Config(theCardinal) =SetImage(DPARSF_rest_sliceviewer_Cfg.Config(theCardinal));			
        end			
	otherwise
	end
catch
	rest_misc( 'DisplayLastException');
end	

function Result =InitControls(AFilename, ACallback)	
	%Initialization 20070525
	theFig =figure('Units', 'pixel', 'Toolbar', 'none', 'MenuBar', 'none', ...
				'NumberTitle', 'off', 'Name', AFilename, 'DoubleBuffer', 'on');
	set(theFig, 'DeleteFcn', sprintf('DPARSF_rest_sliceviewer(''Delete'', %g);', theFig)  );
	set(theFig, 'KeyPressFcn', sprintf('DPARSF_rest_sliceviewer(''OnKeyPress'', %g);', theFig)  );
	
	MarginX =10; MarginY =10;
	OffsetX =MarginX;
	OffsetY =MarginY +245;%OffsetY =MarginY +200;	dong		
	
	%Create Slice View options
	%Create uicontrols to config Yoke or [X Y Z] position to set current cross-hair to locate the voxel
	theLeft =OffsetX; theBottom =OffsetY;
	hFrameSetPos=uicontrol(theFig, 'Style','Frame', 'Visible','off', 'Units','pixels', ...
							'BackgroundColor', get(theFig,'Color'), ...
							'Position', [theLeft,theBottom,150,180]);	
	%YAN Chao-Gan, 090919. Set the uicontrols visible off
	uicontrol(theFig, 'Style','pushbutton','Visible','off', 'Units','pixels', ...
			'String', 'Slice Viewer', ... %'BackgroundColor', get(theFig,'Color'), ...
			'Callback', 'DPARSF_rest_sliceviewer', ...
			'Position', [theLeft+35,theBottom+172,80,18]);	
	
	theLeft =OffsetX+MarginX; theBottom =OffsetY+MarginY+20 +20+MarginY/2 +10 +MarginY;
	hYoke =uicontrol(theFig, 'Style','checkbox', 'Visible','off','Units','pixels', ...
					'String', 'Yoke', ...
					'BackgroundColor', get(theFig,'Color'), ...
					'Position',[theLeft, theBottom+75, 80,15]);
	theLeft =OffsetX+MarginX+56+MarginX; theBottom =OffsetY+MarginY+20 +20+MarginY/2 +10 +MarginY;	
	hCrosshair =uicontrol(theFig, 'Style','checkbox', 'Visible','off','Units','pixels', ...
					'String', 'Crosshair', 'Value', 1,...
					'Callback', sprintf('DPARSF_rest_sliceviewer(''Repaint'', %g);',theFig) , ...
					'BackgroundColor', get(theFig,'Color'), ...
					'Position',[theLeft, theBottom+75, 70,15]);
	
	
	theEditCallbackFcn =sprintf('DPARSF_rest_sliceviewer(''SetPosition'', %g);', theFig);
	theLeft =OffsetX+MarginX-5; theBottom =OffsetY+MarginY+35+MarginY/2;
	uicontrol(theFig, 'Style','text', 'Visible','off','Units','pixels', ...
			  'String', 'X(mm)', ...
			  'BackgroundColor', get(theFig,'Color'), ...			  
			  'Position',[theLeft, theBottom+85, 46,15]);
	theLeft =OffsetX+MarginX-5; theBottom =OffsetY+MarginY+20;		  
	hEditPositionX =uicontrol(theFig, 'Style','edit', 'Visible','off','Units','pixels', ...
							  'String', '0', ...
							  'BackgroundColor', 'white', ...
							  'Callback', theEditCallbackFcn, ...
							  'Position',[theLeft, theBottom+85, 46,20]);
		  
	theLeft =OffsetX+MarginX+36+MarginX-5; theBottom =OffsetY+MarginY+35+MarginY/2;					  
	uicontrol(theFig, 'Style','text', 'Visible','off','Units','pixels', ...
			  'String', 'Y(mm)', ...
			  'BackgroundColor', get(theFig,'Color'), ...
			  'Position',[theLeft, theBottom+85, 46,15]);
	theLeft =OffsetX+MarginX+36+MarginX-5; theBottom =OffsetY+MarginY+20;			  
	hEditPositionY =uicontrol(theFig, 'Style','edit', 'Visible','off','Units','pixels', ...
							  'String', '0', ...
							  'BackgroundColor', 'white', ...
							  'Callback', theEditCallbackFcn, ...
							  'Position',[theLeft, theBottom+85, 46,20]);
			
	theLeft =OffsetX+MarginX+36+MarginX+36+MarginX-5; theBottom =OffsetY+MarginY+35+MarginY/2;		
	uicontrol(theFig, 'Style','text', 'Visible','off','Units','pixels', ...
			  'String', 'Z(mm)', ...
			  'BackgroundColor', get(theFig,'Color'), ...
			  'Position',[theLeft, theBottom+85, 46,15]);
	theLeft =OffsetX+MarginX+36+MarginX+36+MarginX-5; theBottom =OffsetY+MarginY+20;		  
	hEditPositionZ =uicontrol(theFig, 'Style','edit', 'Visible','off','Units','pixels', ...
							  'String', '0', ...
							  'BackgroundColor', 'white', ...
							  'Callback', theEditCallbackFcn, ...
							  'Position',[theLeft, theBottom+85, 46,20]);
	
	theLeft =OffsetX+MarginX-5; theBottom =OffsetY+MarginY+20;
	hMagnify =uicontrol(theFig, 'Style','popupmenu', 'Visible','off','Units','pixels', ...
						'String', {'x0.5', 'x1', 'x2', 'x3'}, ...
						'Value', 2, ...
						'BackgroundColor', get(theFig,'Color'), ...
						'Enable', 'off', ...
						'Callback', sprintf('DPARSF_rest_sliceviewer(''Magnify'', %g);',theFig), ...
						'Position',[theLeft, theBottom+70, 70,10]);
	if license('test','image_toolbox')
		set(hMagnify, 'Enable', 'on');
	else
		warning('image_toolbox not valid');
	end
	
	theLeft =OffsetX+MarginX+60+MarginX-5; theBottom =OffsetY+MarginY+20;
	hMniTal =uicontrol(theFig, 'Style','popupmenu', 'Visible','off','Units','pixels', ...
						'String', {'MNI/Talairach Coordinates', 'From Talairach to MNI', 'From MNI to Talairach'}, ...
						'Value', 1, ...
						'BackgroundColor', get(theFig,'Color'), ...
						'Enable', 'on', ...
						'Callback', sprintf('DPARSF_rest_sliceviewer(''MNI/Talairach'', %g);',theFig), ...
						'Position',[theLeft, theBottom+70, 68,10]);
	
	
	%OffsetY =OffsetY +30;%20070911, for complete information display	
	theLeft =OffsetX+MarginX; theBottom =OffsetY+MarginY;
	hVoxelIntensity=uicontrol(theFig, 'Style','text', 'Visible','off','Units','pixels', ...
						  'String', '', 'TooltipString', 'Intensity of the current point', ...
						  'BackgroundColor', get(theFig,'Color'), ...
						  'HorizontalAlignment', 'left', ...  % 'Visible', 'off', ...						  
						  'Position',[theLeft-5, theBottom+42, 110,32]);
			  
	%Create a Message label to display some specific message, dawnsong 20070526
	theLeft =OffsetX+MarginX; theBottom =OffsetY +100 +MarginY;
	hMsgLabel =uicontrol(theFig, 'Style','text', 'Visible','off','Units','pixels', ...
			  'String', sprintf('Dawnwei.Song Copyright 2007-2010, all rights reserved'), ...
			  'BackgroundColor', get(theFig,'Color'), ...
			  'HorizontalAlignment', 'left', 'Enable', 'inactive',...
			  'ButtonDownFcn', sprintf('DPARSF_rest_sliceviewer(''ToggleInfoDisplay'', %g);',theFig), ...
			  'Position',[theLeft, theBottom, 130,10]);	
			  
	% Create a Callback Button to do sth.
	theLeft =OffsetX+MarginX; theBottom =OffsetY +100 +MarginY +10;
	% hDoCallbackBtn =-1;
	% if ~isempty(ACallback) && ischar(ACallback)
		% hDoCallbackBtn =uicontrol(theFig, 'Style','pushbutton',  ...
							  % 'Units','pixels', 'String', 'Do sth.', ...
							  % 'Callback', ACallback, ...
							  % 'Position',[theLeft, theBottom, 130,10]);
	% end
	%View Buttons
	theLeft =OffsetX+MarginX-4; theBottom =OffsetY +MarginY-2;
	theIcon =imread(fullfile(rest_misc( 'WhereIsREST'), 'icoTransverse.jpg'));
	hViewTransverse =uicontrol(theFig, 'Style','pushbutton',  ...
							  'Visible','off','Units','pixels', ...
							  'Callback', sprintf('DPARSF_rest_sliceviewer(''TransverseView'', %g);',theFig) , ...
							  'CData', theIcon,...
							  'Position',[theLeft, theBottom, 34,36]);
	theLeft =OffsetX+MarginX+30; theBottom =OffsetY +MarginY-2;
	theIcon =imread(fullfile(rest_misc( 'WhereIsREST'), 'icoSagittal.jpg'));
	hViewSagittal =uicontrol(theFig, 'Style','pushbutton',  ...
							  'Visible','off','Units','pixels', ...
							  'Callback', sprintf('DPARSF_rest_sliceviewer(''SagittalView'', %g);',theFig) , ...
							  'CData', theIcon,...
							  'Position',[theLeft, theBottom, 34,36]);
	theLeft =OffsetX+MarginX+34+30; theBottom =OffsetY +MarginY-2;
	theIcon =imread(fullfile(rest_misc( 'WhereIsREST'), 'icoCoronal.jpg'));
	hViewCoronal =uicontrol(theFig, 'Style','pushbutton',  ...
							  'Visible','off','Units','pixels', ...
							  'Callback', sprintf('DPARSF_rest_sliceviewer(''CoronalView'', %g);',theFig) , ...
							  'CData', theIcon,...
							  'Position',[theLeft, theBottom, 34,36]);
	theLeft =OffsetX+MarginX+34+34+30; theBottom =OffsetY +MarginY-2;
	theIcon =imread(fullfile(rest_misc( 'WhereIsREST'), 'icoOrthogonal.jpg'));
	hViewOrthogonal =uicontrol(theFig, 'Style','pushbutton',  ...
							  'Visible','off','Units','pixels', ...
							  'Callback', sprintf('DPARSF_rest_sliceviewer(''OrthogonalView'', %g);',theFig) , ...
							  'CData', theIcon,...
							  'Position',[theLeft, theBottom, 34,36]);
	theLeft =OffsetX+MarginX+34+30; theBottom =OffsetY +MarginY+34;	
	hViewMontage =uicontrol(theFig, 'Style','pushbutton',  ...
							  'Visible','off','Units','pixels', ...
							  'Callback', sprintf('DPARSF_rest_sliceviewer(''Montage'', %g);',theFig) , ...
							  'String', 'Montage','TooltipString', 'Montage: Multislice',...
							  'Position',[theLeft, theBottom, 68,24]);
							  
	
	
	%Add Underlay file selection directly
	theLeft =OffsetX; theBottom =MarginY+225;%theBottom =MarginY+180; dong +100
	hUnderlayRecent =uicontrol(theFig, 'Style','popupmenu', 'Visible','off','Units','pixels', ...
			  'String', {'Underlay: '}, 'Value', 1, ...
			  'Callback', sprintf('DPARSF_rest_sliceviewer(''ClickRecentUnderlay'', %g);',theFig), ...
			  'BackgroundColor', get(theFig,'Color'), ...			  
			  'Position',[theLeft, theBottom, 75,20]);	 
	theLeft =OffsetX; theBottom =MarginY+205;
	hUnderlayFile =uicontrol(theFig, 'Style','edit', 'Visible','off','Units','pixels', ...
							  'String', '', ...
							  'BackgroundColor', 'white', ...
							  'Callback', sprintf('DPARSF_rest_sliceviewer(''ChangeUnderlay'', %g);',theFig), ...
							  'Position',[theLeft, theBottom, 150,20]);
	theLeft =OffsetX+116; theBottom =MarginY+225;
	uicontrol(theFig, 'Style','pushbutton', 'Visible','off','Units','pixels', ...
		  'Callback', sprintf('DPARSF_rest_sliceviewer(''UnderlaySelection'', %g);',theFig) , ...
		  'String', '...', 'FontWeight', 'bold', ...
		  'Position',[theLeft, theBottom, 34,15]);
	%Add Overlay file selection directly
	theLeft =OffsetX; theBottom =MarginY+185;
	hOverlayRecent =uicontrol(theFig, 'Style','popupmenu', 'Visible','off','Units','pixels', ...
			  'String', {'Overlay: '}, 'Value', 1, ...
			  'Callback', sprintf('DPARSF_rest_sliceviewer(''ClickRecentOverlay'', %g);',theFig), ...
			  'BackgroundColor', get(theFig,'Color'), ...			  
			  'Position',[theLeft, theBottom, 75,20]);	 
	theLeft =OffsetX; theBottom =MarginY+165;
	hOverlayFile =uicontrol(theFig, 'Style','edit', 'Visible','off','Units','pixels', ...
					  'String', '', ...					  
					  'BackgroundColor', 'white', ...
					  'Callback', sprintf('DPARSF_rest_sliceviewer(''ChangeOverlay'', %g);',theFig), ...
					  'Position',[theLeft, theBottom, 150,20]);
	theLeft =OffsetX+116; theBottom =MarginY+185;
	uicontrol(theFig, 'Style','pushbutton', 'Visible','off','Units','pixels', ...
		  'Callback', sprintf('DPARSF_rest_sliceviewer(''OverlaySelection'', %g);',theFig) , ...
		  'String', '...','FontWeight', 'bold', ...
		  'Position',[theLeft, theBottom, 34,15]); 
	%Add Overlay  Options, 20070913
	theLeft =OffsetX; theBottom =MarginY;
	hFrameOverlay=uicontrol(theFig, 'Style','Frame', 'Visible','off','Units','pixels', ...
							'BackgroundColor', get(theFig,'Color'), ...
							'Position', [theLeft,theBottom,150,145]); %dong	
	hSeeOverlay =uicontrol(theFig, 'Style','checkbox', 'Visible','off','Units','pixels', ...
					'String', 'See Overlay', ...
					'Callback', sprintf('DPARSF_rest_sliceviewer(''Repaint'', %g);',theFig), ...
					'BackgroundColor', get(theFig,'Color'), ...
					'Position',[theLeft+35, theBottom+140, 80,15]);
	uicontrol(theFig, 'Style','text', 'Visible','off','Units','pixels', ...
			'String', 'Threshold', ...								
			 'BackgroundColor', get(theFig,'Color'), ...
			'Position',[theLeft+5, theBottom+120, 50,18]);
	hEdtThrdValue =uicontrol(theFig, 'Style','edit', 'Visible','off','Units','pixels', ...
					'String', '', ...					
					'Callback', sprintf('DPARSF_rest_sliceviewer(''Overlay_SetThrdAbsValue'', %g);',theFig), ...	
					 'BackgroundColor', 'white', ...
					'Position',[theLeft+75, theBottom+120, 70,18]);	
	
	hSliderThrdValue =uicontrol(theFig, 'Style','slider', 'Visible','off','Units','pixels', ...
					'TooltipString', 'Absolute Value for thresholding the overlay', ...
					'Callback', sprintf('DPARSF_rest_sliceviewer(''Overlay_SetThrdAbsValue'', %g);',theFig), ...
					'BackgroundColor', get(theFig,'Color'), ...
					'Position',[theLeft+5, theBottom+101, 140,15]);	
                
                
   uicontrol(theFig, 'Style','text', 'Visible','off','Units','pixels', ...%dong
			'String', 'P', ...								
			 'BackgroundColor', get(theFig,'Color'), ...
			'Position',[theLeft+5, theBottom+78, 10,18]); 
   hEdtPValue =uicontrol(theFig, 'Style','edit', 'Visible','off','Units','pixels', ...%P-value need improve dong
					'String', '1', ...					
					'Callback', sprintf('DPARSF_rest_sliceviewer(''Overlay_SetThrdAbsValue'', %g);',theFig), ...	
					 'BackgroundColor', 'w', ...
					'Position',[theLeft+15, theBottom+80, 35,18]);	
    hdf =uicontrol(theFig, 'Style','pushbutton',  ... %add df dong 090921
							  'Visible','off','Units','pixels', ...
							  'Callback', sprintf('DPARSF_rest_sliceviewer(''DF'', %g);',theFig),...	
							  'String', 'df', ...
                              'Position',[theLeft+55, theBottom+80, 30,18]);
uicontrol(theFig, 'Style','text', 'Visible','off','Units','pixels', ...%dong
			'String', 'Only', ...								
			 'BackgroundColor', get(theFig,'Color'), ...
			'Position',[theLeft+85, theBottom+78, 30,18]); 
     uicontrol(theFig, 'Style','pushbutton', 'Visible','off','Units','pixels', ...  %only + dong 090921
			'String', '+', ...
			'Callback', sprintf('DPARSF_rest_sliceviewer(''OnlyPositive'', %g);',theFig),...			
			'Position',[theLeft+112, theBottom+80, 15,18]);
     uicontrol(theFig, 'Style','pushbutton', 'Visible','off','Units','pixels', ...  %only + dong 090921
			'String', '-', ...
			'Callback', sprintf('DPARSF_rest_sliceviewer(''OnlyNegative'', %g);',theFig),...			
			'Position',[theLeft+129, theBottom+80, 15,18]);
        
	uicontrol(theFig, 'Style','pushbutton', 'Visible','off','Units','pixels', ...
			'String', 'Cluster Size', ...
			'Callback', sprintf('DPARSF_rest_sliceviewer(''Overlay_SetThrdClusterSize'', %g);',theFig),...		%here dong	
			'Position',[theLeft+5, theBottom+30, 70,24]);
	hOverlayMisc =uicontrol(theFig, 'Style','popupmenu', 'Visible','off','Units','pixels', ...
					'String', {'Misc', 'Set Overlay''s Opacity', ...
					'Set Range of Threshold', 'Set Label Color', 'Set Overlay''s Color bar','Save Image As','Correction Thresholds by AlphaSim',...%YAN Chao-Gan 081223: add "save image as" function %YAN CHao-Gan 090401: add "Correction Thresholds by AlphaSim"
                    'False Discovery Rate (FDR) Correction'}, ... %Dong 100115 add False discovery rate(FDR) control, a statistical method used in multiple hypothesis testing to correct for multiple comparisons
					'Value', 1, ...
					'BackgroundColor', get(theFig,'Color'), ...
					'Enable', 'on', ...
					'Callback', sprintf('DPARSF_rest_sliceviewer(''Overlay_Misc'', %g);',theFig), ...
					'Position',[theLeft+5, theBottom+55, 70,24]);
	hTemplate =uicontrol(theFig, 'Style','popupmenu', 'Visible','off','Units','pixels', ...
					'String', {'Template', 'Open AAL', 'Open Brodmann','Open Ch2','Open Ch2 Bet'}, ...
					'Value', 1, ...
					'BackgroundColor', get(theFig,'Color'), ...
					'Enable', 'on', ...
					'Callback', sprintf('DPARSF_rest_sliceviewer(''Open_Template'', %g);',theFig), ...
					'Position',[theLeft+75, theBottom+55, 70,24]);
	uicontrol(theFig, 'Style','pushbutton', 'Visible','off','Units','pixels', ...
			'String', 'Save Cluster', ...
			'Callback', sprintf('DPARSF_rest_sliceviewer(''CurrentCluster2Mask'', %g);',theFig),...			
			'Position',[theLeft+75, theBottom+30, 70,24]);
   uicontrol(theFig, 'Style','pushbutton', 'Visible','off','Units','pixels', ...%dong 090920
			'String', 'Save Clusters', ...
			'Callback', sprintf('DPARSF_rest_sliceviewer(''CurrentThrd2Mask'', %g);',theFig),...			
			'Position',[theLeft+5, theBottom+5, 70,24]);
    uicontrol(theFig, 'Style','pushbutton', 'Visible','off','Units','pixels', ...%dong 090920
			'String', 'Cl. Report', ...
           'Callback', sprintf('DPARSF_rest_sliceviewer(''ClustersReport'', %g);',theFig),...				
			'Position',[theLeft+75, theBottom+5, 70,24]);
	% uicontrol(theFig, 'Style','pushbutton', 'Units','pixels', ...
	%		 'String', 'Thrd2Mask', ...
	%		 'Callback', sprintf('DPARSF_rest_sliceviewer(''Overlay_SetThrdClusterSize'', %g);',theFig),...			
	%		 'Position',[theLeft+75, theBottom+5, 70,24]);
			
	%Colorbar for overlay, do as AFNI, 20070921
	theAxesButtonDownFcn =sprintf('DPARSF_rest_sliceviewer(''ChangeColorElement'', %g);',theFig);
	hAxesColorbar =axes('Parent', theFig, 'Box', 'on', ...
				  'Units', 'pixel', 'DrawMode','fast', 'Visible', 'off', ...
				  'Position', [1 1 1 1], ...
				  'YDir','normal', 'XTickLabel',[],'XTick',[], ...
				  'YTickLabel',[],'YTick',[], ...
				  'ButtonDownFcn', theAxesButtonDownFcn);
	hImageColorbar =image('Tag','OverlayColorbar',  'Parent', hAxesColorbar);
    hImageCover=uicontrol(theFig, 'Style','text', 'Units','pixels', ...%dong 1130
			'String', '', 'Visible','off',...								
			 'BackgroundColor', get(theFig,'Color'), ...
			'Position',[theLeft+500, theBottom+578, 20,18]); 
	set(hAxesColorbar,'YDir','normal','ButtonDownFcn', theAxesButtonDownFcn, 'XTickLabel',[],'XTick',[], 'YTickLabel',[],'YTick',[]);
	
	clear theLeft theBottom;% dong 2009-09-09 end GUI
		
	%Save to config
	AConfig.hFig			=theFig;			%handle of the config
	
	%Save parameters handles
	AConfig.hFrameSetPos   =hFrameSetPos;
	AConfig.hYoke 		   =hYoke;
	AConfig.hCrosshair	   =hCrosshair;
	AConfig.hMagnify	   =hMagnify;
	AConfig.hMniTal		   =hMniTal;	
	AConfig.hEditPositionX =hEditPositionX;
	AConfig.hEditPositionY =hEditPositionY;
	AConfig.hEditPositionZ =hEditPositionZ;
	%Save Voxel intensity label handle
	AConfig.hVoxelIntensity=hVoxelIntensity;
	%Save message handle
	AConfig.hMsgLabel =hMsgLabel;
	AConfig.Message	 ='';
	%Save Do Callback button's handle
	% AConfig.hDoCallbackBtn =hDoCallbackBtn;
			
	%Save important variables
	AConfig.Filename =AFilename;	%Default for underlay
	%AConfig.Callback =ACallback;	%Default for click callback	
	%Callback define series, 20070924
	AConfig.Callback.ChangingPosition =ACallback;
	AConfig.Callback.Save2Mask ='';
	
	%View Mode, 20070911
	AConfig.ViewMode ='Orthogonal';	%Default View mode
	AConfig.ViewSeries =[];			%Default no any view series
	AConfig.Montage.Across =1;
	AConfig.Montage.Down   =1;
	AConfig.Montage.Spacing=3;
	AConfig.Montage.WantLabel=1;
    %P_value
    AConfig.Df.Ttest=0;
    AConfig.Df.Ftest=[0,0];
    AConfig.Df.Ztest=0;
    AConfig.Df.Rtest=0;
	AConfig.Overlay.Header='';
	%Underlay and Overlay, handles
	AConfig.hUnderlayFile =hUnderlayFile;
	AConfig.hUnderlayRecent =hUnderlayRecent;
	AConfig.hOverlayFile  =hOverlayFile;
	AConfig.hOverlayRecent =hOverlayRecent;
	
	AConfig.hSeeOverlay =hSeeOverlay;
	AConfig.hSliderThrdValue =hSliderThrdValue;
	AConfig.hEdtThrdValue =hEdtThrdValue;	
    AConfig.hEdtPValue=hEdtPValue; %dong 2009-09-09
	AConfig.hOverlayMisc =hOverlayMisc;
	AConfig.hTemplate =hTemplate;	
	AConfig.hFrameOverlay  =hFrameOverlay;
	
	AConfig.hAxesColorbar  =hAxesColorbar;
	AConfig.hImageColorbar =hImageColorbar;	
     AConfig.hImageCover=hImageCover;
	%Overlay Configuration
	%Data for Overlay
	AConfig.Overlay.Filename ='';
	AConfig.Overlay.Volume	 =zeros(61, 73, 61);
	
	 AConfig.Overlay.PNflag =0;
	AConfig.Overlay.VolumeThrd =AConfig.Overlay.Volume;%Volume Thresholded by Cluster Size	
	AConfig.Overlay.VolumeForFlag=AConfig.Overlay.Volume;
	AConfig.Overlay.VoxelSize=[3 3 3];
	AConfig.Overlay.Origin	 =[31 43 25];
	%Overlay's Info - statistics
	Result.Overlay.MinNegative =-Inf;
	Result.Overlay.MaxNegative =0;
	Result.Overlay.MinPositive =0;
	Result.Overlay.MaxPositive =Inf;
	Result.Overlay.AbsMin =0;
	Result.Overlay.AbsMax =Inf;
	%Options for Overlay	
	AConfig.Overlay.Colormap	=jet(64);
	AConfig.Overlay.ColorbarCmd	='jet(64)';
	%[0 0 1;1 0 0];	%Pure Blue and Pure Red
	%[0 0 0.5625;0 0 0.875;0 0 1;1 0 0;0.875 0 0;0.5 0 0];	
	AConfig.Overlay.Opacity  =1;	%Default, 50% Opacity	
	AConfig.Overlay.LabelColor ='white';
    AConfig.Overlay.ValueP =1;  %P value dong 2009-09-09
	AConfig.Overlay.ValueThrdAbsolute =0; %Default, show all
	AConfig.Overlay.ValueThrdMin = -Inf; %Default, show all, not absolute, may be negative
	AConfig.Overlay.ValueThrdMax = Inf; %Default, show all, not absolute , may be negative, this allows me to set a range such as showing negative values only or positives only
	AConfig.Overlay.ValueThrdSeries = NaN; %Default, show all
	AConfig.Overlay.ClusterSizeThrd =0; %Default, 0 voxels, for not confining cluster-size
	AConfig.Overlay.ClusterRadiusThrd =0; %Default radius(mm) for Cluster size definition
    AConfig.Overlay.ClusterConnectivityCriterion =0; %Default Connectivity Criterionradius: 0.
    AConfig.Overlay.ClusterConnectivityCriterionRMM=0;
	AConfig.Overlay.InfoAal='None';	%AAL descriptions
		
    
    
    AConfig.Overlay.Qvalue=0.05;%For FDR
    AConfig.Overlay.Qmaskname='';
    AConfig.Overlay.Conproc=1;
    AConfig.Overlay.Tchoose=2; % YAN Chao-Gan, 100201
	%Load Recent Images/brains
	AConfig =InitRecent(AConfig);
	
	%Save Axes's handles
	AConfig.hAxesSagittal 	=-1;
	AConfig.hAxesCoronal 	=-1;
	AConfig.hAxesTransverse =-1;
	%Save Images' handles
	AConfig.hImageSagittal	 =-1;
	AConfig.hImageCoronal 	 =-1;
	AConfig.hImageTransverse =-1;
	%Save Lines' handles
	AConfig.hXLineSagittal   =-1;		%x
	AConfig.hYLineSagittal   =-1;		%y
	AConfig.hXLineCoronal	 =-1;		%x
	AConfig.hYLineCoronal	 =-1;		%y
	AConfig.hXLineTransverse =-1;		%x
	AConfig.hYLineTransverse =-1;		%y
	AConfig.LastPosition =[90 126 72];	%Default
	AConfig.LastAxes	 ='Transverse';	%For slice previous/next by pressing up/down left/right j/k ... on keyboard
	AConfig.LastSavedMask ='';			%For ROI define callback
	
	AConfig =InitUnderlay(AConfig);
  
	
	
	%Move Auto-Balance out of initialization just for speeding up for starting this slice-viewer
	%Save Maping Image parameters, Auto balance 20070911 revised
	% theSatMin=0; theSatMax =0; nBins=2^16;	%Satuation Min/Max
	% theMaxVal=max(AConfig.Volume(:));	
	% if theMaxVal<257, 
		% nBins =256; 
	% else
		% nBins =theMaxVal; 
	% end
	% theSum =histc(AConfig.Volume(:), [1:nBins]);
	% theSum =cumsum(theSum);
	% theCdf =theSum/theSum(end);
	% if rest_misc('GetMatlabVersion')>=7.3
		% idxSatMin =find(theCdf>0.01, 1, 'first');
		% idxSatMax =find(theCdf>=0.99, 1, 'first');
	% else
		% idxSatMin =find(theCdf>0.01);
		% idxSatMin =idxSatMin(1);
		% idxSatMax =find(theCdf>=0.99);
		% idxSatMax =idxSatMax(1);		
	% end
	% idxSatMin =find(theCdf>0.01, 1, 'first');
	% idxSatMax =find(theCdf>=0.99, 1, 'first');
	% theSatMin =(idxSatMin-1)/(nBins-1) *theMaxVal;
	% theSatMax =(idxSatMax-1)/(nBins-1) *theMaxVal;	
	% AConfig.Contrast.GrayDepth =256;
	% AConfig.Contrast.SatMax =theSatMax;
	% AConfig.Contrast.SatMin =theSatMin;
	%20070911, AutoBalance for contrast
	% AConfig.Contrast.WindowWidth =theSatMax -theSatMin;
	% AConfig.Contrast.WindowCenter=(theSatMax +theSatMin)/2;
	%For debugging, 20070911
	% disp(AConfig.Contrast);
	
    	
	%%Update the figure, the follow function called order shouldn't change
	%Display Images
	AConfig =SetImage(AConfig);
	
	Result =AConfig;	
	return;

function Result =DeleteFigure(AGlobalConfig, AFigHandle)
	x =ExistViewer(AGlobalConfig, AFigHandle);
	if x>0,			
		theDisplayCount =GetDisplayCount(AGlobalConfig);
		isExistFig =rest_misc( 'ForceCheckExistFigure' , AGlobalConfig.Config(x).hFig);
		if isExistFig,
			%Save the recent menu
			DPARSF_rest_sliceviewer('SaveRecent', AFigHandle);
			
			%Delete the figure and rearrange the queue
			delete(AGlobalConfig.Config(x).hFig);
			if theDisplayCount>x
				for y=x:theDisplayCount-1
					AGlobalConfig.Config(x) =AGlobalConfig.Config(x+1);
                end
            end	
            AGlobalConfig.Config(theDisplayCount)=[];
		end	
	end
	Result =AGlobalConfig;
	
function Result =GetDisplayCount(AGlobalConfig)
%Get the Count of display, this program allow multi-view of brain like MRIcro
	if isempty(AGlobalConfig) || isempty(AGlobalConfig.Config),
		Result =0;		
	else
		Result =length(AGlobalConfig.Config);
	end
	return;
	
function Result =ListViewerFigure(AGlobalConfig, AFilename)
    Result =[];
	if (isstruct(AGlobalConfig) && isstruct(AGlobalConfig.Config))
		for x=1:length(AGlobalConfig.Config)
			if strcmpi( AGlobalConfig.Config(x).Filename, AFilename)
				Result =[Result; AGlobalConfig.Config(x).hFig];
            end
        end        
	else
		return;
	end	
	
function Result =ExistViewer(AGlobalConfig, AFigureHandle)
	Result =0;
	if (isstruct(AGlobalConfig) && isstruct(AGlobalConfig.Config))
		for x=1:length(AGlobalConfig.Config)
			if AGlobalConfig.Config(x).hFig==AFigureHandle,
				Result =x;
				return;
            end
        end        
	else				
		return;
	end	

function Result =SetImage(AConfig)
	if strcmpi(AConfig.ViewMode, 'Orthogonal'),
		Result =SetView_Orthogonal(AConfig);
	elseif strcmpi(AConfig.ViewMode, 'Transverse'),
		Result =SetView_Transverse(AConfig);
	elseif strcmpi(AConfig.ViewMode, 'Sagittal'),
		Result =SetView_Sagittal(AConfig);
	elseif strcmpi(AConfig.ViewMode, 'Coronal'),
		Result =SetView_Coronal(AConfig);
    end
	%Draw the color bar
	Result =DrawColorbar(Result);
	
	set(AConfig.hFig, 'Name', sprintf('REST Slice Viewer -- For DPARSF''s special use')); %YAN Chao-Gan, 090919.
	%Display Underlay Filename
	set(AConfig.hUnderlayFile, 'String', sprintf('%s', AConfig.Filename));
	%Display Overlay Filename	
	set(AConfig.hOverlayFile, 'String', sprintf('%s', AConfig.Overlay.Filename));
	
	%Show Voxel's position [x y z]
	ShowPositionInEdit(AConfig);	
	%Update the message
	SetMessage(AConfig);	
	%Resize figure width and height
	ResizeFigure(AConfig);
	
	
function Result =SetView_Orthogonal(AConfig)	
	%Underlay Image manuplication, 20070913
	theSagittalImg =GetGrayImage('Sagittal', AConfig.Volume, AConfig.LastPosition(1));	%x
	theCoronalImg =GetGrayImage('Coronal', AConfig.Volume, AConfig.LastPosition(2));		%y	
	theTransverseImg =GetGrayImage('Transverse', AConfig.Volume, AConfig.LastPosition(3));%z
	
	%Auto balance	
	theSagittalImg =SaturateContrast(theSagittalImg, AConfig.Contrast.SatMin, AConfig.Contrast.SatMax);
	theCoronalImg =SaturateContrast(theCoronalImg, AConfig.Contrast.SatMin, AConfig.Contrast.SatMax);
	theTransverseImg =SaturateContrast(theTransverseImg, AConfig.Contrast.SatMin, AConfig.Contrast.SatMax);
	
	%Calculate the Result Image after Magnifying
	theMagnifyCoefficient =GetMagnifyCoefficient(AConfig);
	if license('test','image_toolbox')==1 && theMagnifyCoefficient~=1, 
        if rest_misc('GetMatlabVersion')>=7.4   %YAN Chao-Gan 090401: The imresize function has been completely rewritten in Matlab R2007a. Fixed the bug of 'Set Overlay's Color bar' in Matlab R2007a or latter version.
            theSagittalImg	=imresize_old(theSagittalImg, theMagnifyCoefficient);
            theCoronalImg	=imresize_old(theCoronalImg, theMagnifyCoefficient);
            theTransverseImg=imresize_old(theTransverseImg, theMagnifyCoefficient);
        else
            theSagittalImg	=imresize(theSagittalImg, theMagnifyCoefficient);
            theCoronalImg	=imresize(theCoronalImg, theMagnifyCoefficient);
            theTransverseImg=imresize(theTransverseImg, theMagnifyCoefficient);
        end
	end	
	
	% Revise the Axes position to make it comfort to Magnify
	theFramePosParamSet =get(AConfig.hFrameSetPos, 'Position');
	theLeft 	=theFramePosParamSet(1) +theFramePosParamSet(3) +5;
	theBottom 	=10; %theFramePosParamSet(2);
	theLeftTransverse =theLeft;
	theLeftCoronal 	  =theLeftTransverse;
	theLeftSagittal   =theLeftCoronal  +size(theCoronalImg,2)+	2;
	theBottomTransverse =theBottom;
	theBottomCoronal	=theBottomTransverse +size(theTransverseImg,1) +2;
	theBottomSagittal	=theBottomCoronal;
	
	thePosTransverse 	=[theLeftTransverse, theBottomTransverse, size(theTransverseImg,2), size(theTransverseImg,1)];
	thePosCoronal		=[theLeftCoronal, theBottomCoronal, size(theCoronalImg,2), size(theCoronalImg,1)];
	thePosSagittal		=[theLeftSagittal, theBottomSagittal, size(theSagittalImg,2), size(theSagittalImg,1)];
	clear theFramePosParamSet theLeft theBottom 
	clear theLeftTransverse theLeftCoronal theLeftSagittal
	clear theBottomTransverse theBottomCoronal theBottomSagittal
	
	% Show Images
	%Clear Text labels first
	ClearTextLabels(AConfig);	
	
	%Set Default color map for only Underlay
	%colormap(gray(AConfig.Contrast.GrayDepth));	
	%Map images to true color
	theSagittalImg =repmat(theSagittalImg, [1 1 3]);
	theCoronalImg =repmat(theCoronalImg, [1 1 3]);
	theTransverseImg =repmat(theTransverseImg, [1 1 3]);
	
	%Add Overlay Images
	if SeeOverlay(AConfig),
        %dong 100331 begin
		theSagittalImg =AddOverlay('Sagittal' ,AConfig, theSagittalImg,theMagnifyCoefficient);
		theCoronalImg =AddOverlay('Coronal', AConfig, theCoronalImg,theMagnifyCoefficient);
		theTransverseImg =AddOverlay('Transverse', AConfig, theTransverseImg,theMagnifyCoefficient);
        %dong 100331 end
	end
	
	%Sagittal	
	set(AConfig.hImageSagittal, 'CData', (theSagittalImg), 'HitTest', 'off','Visible', 'on');	
	set(AConfig.hAxesSagittal,'Visible', 'on', ...
		'XLim', [1 size(theSagittalImg,2)], ...
		'YLim', [1 size(theSagittalImg,1)] , ...
		'Position', thePosSagittal);
	set(AConfig.hXLineSagittal, 'HitTest','off','Visible', IsCrosshairChecked(AConfig), ...		
		'XData', [1 size(theSagittalImg,2)] , ...
		'YData', [1 1]*AConfig.LastPosition(3) * theMagnifyCoefficient);%Parallel to X-axis
	set(AConfig.hYLineSagittal, 'HitTest','off','Visible', IsCrosshairChecked(AConfig), ...		
		'XData', [1 1]*AConfig.LastPosition(2) * theMagnifyCoefficient, ...
		'YData', [1 size(theSagittalImg,1)] );%Parallel to Y-axis
	
	%Coronal		 
	set(AConfig.hImageCoronal, 'CData', (theCoronalImg), 'HitTest', 'off','Visible', 'on');
	%colormap(gray(AConfig.Contrast.GrayDepth));	
	set(AConfig.hAxesCoronal, 'Visible', 'on',...
		'XLim', [1 size(theCoronalImg,1)], ...
		'YLim', [1 size(theCoronalImg,2)], ...
		'Position', thePosCoronal);
	set(AConfig.hXLineCoronal, 'HitTest','off','Visible', IsCrosshairChecked(AConfig), ...		
		'XData', [1 size(theCoronalImg,2)] , ...
		'YData', [1 1]*AConfig.LastPosition(3) * theMagnifyCoefficient );%Parallel to X-axis
	set(AConfig.hYLineCoronal, 'HitTest','off','Visible', IsCrosshairChecked(AConfig), ...		
		'XData', [1 1]*AConfig.LastPosition(1) * theMagnifyCoefficient , ...
		'YData', [1 size(theCoronalImg,1)] );%Parallel to Y-axis
	
	%Transverse		 
	set(AConfig.hImageTransverse, 'CData', (theTransverseImg), 'HitTest', 'off','Visible', 'on');
	% colormap(gray(AConfig.Contrast.GrayDepth));	
	set(AConfig.hAxesTransverse,'Visible', 'on', ...
		'XLim', [1 size(theTransverseImg,2)], ...
		'YLim', [1 size(theTransverseImg,1)], ...
		'Position', thePosTransverse);
	set(AConfig.hXLineTransverse, 'HitTest','off','Visible', IsCrosshairChecked(AConfig), ...		
		'XData', [1 size(theTransverseImg,2)] , ...
		'YData', [1 1]*AConfig.LastPosition(2) * theMagnifyCoefficient );%Parallel to X-axis
	set(AConfig.hYLineTransverse, 'HitTest','off','Visible', IsCrosshairChecked(AConfig), ...		
		'XData', [1 1]*AConfig.LastPosition(1) * theMagnifyCoefficient , ...
		'YData', [1 size(theTransverseImg,1)] );%Parallel to Y-axis
	
	%Reset View Series
	AConfig.ViewSeries =[];
	Result =AConfig;

function Result =SetView_Transverse(AConfig)
	[nDim1 nDim2 nDim3] =size(AConfig.Volume);
	theCenterZ =AConfig.LastPosition(3);
	theCount   =AConfig.Montage.Across *AConfig.Montage.Down ;
	
	theZSeries =theCenterZ -([(floor(theCount/2)) : -1 :(ceil(-theCount/2))]) *AConfig.Montage.Spacing;
	while ~isempty(find(theZSeries<=0)),
		theZSeries(find(theZSeries<=0)) = theZSeries(find(theZSeries<=0)) +nDim3;
	end
	while ~isempty(find(theZSeries>nDim3)),
		theZSeries(find(theZSeries>nDim3)) = theZSeries(find(theZSeries>nDim3)) -nDim3;
	end
	
	theTransverseImg = zeros(nDim2 * AConfig.Montage.Down, nDim1 *AConfig.Montage.Across);
	for theRow=AConfig.Montage.Down:-1:1,
		for theCol=1:AConfig.Montage.Across,
			%I don't draw the last image because it is used to indicate the positions				
			theZIndex = theZSeries((AConfig.Montage.Down-theRow)*AConfig.Montage.Across +theCol); %DONG Zhang-Ye 090721 %
			theTransverseImg((theRow-1)*nDim2 +(1:nDim2), (theCol-1)*nDim1+(1:nDim1)) =GetGrayImage('Transverse', AConfig.Volume, theZIndex);%DONG Zhang-Ye 090721 %
			%YAN Chao-Gan 081229 theTransverseImg((theRow-1)*nDim2 +(1:nDim2), (theCol-1)*nDim1+(1:nDim1)) =GetGrayImage('Transverse', AConfig.Volume, theZIndex);
            %Write the Z Coordinates to the left-down corner
			%I have to move this code to the end of Setting Axis by using TEXT function
			
			%Save the Center image's Row and Col for CrossHair-line displaying
			if theZIndex==theCenterZ,
				theCenterZ_Row =theRow;
				theCenterZ_Col =theCol;
			end
		end
	end		

	%Save View Series
	AConfig.ViewSeries = theZSeries;
	%Auto balance	
	theTransverseImg =SaturateContrast(theTransverseImg, AConfig.Contrast.SatMin, AConfig.Contrast.SatMax);
	
	%Calculate the Result Image after Magnifying
	theMagnifyCoefficient =GetMagnifyCoefficient(AConfig);
	if license('test','image_toolbox')==1 && theMagnifyCoefficient~=1, 		
        if rest_misc('GetMatlabVersion')>=7.4   %YAN Chao-Gan 090401: The imresize function has been completely rewritten in Matlab R2007a. Fixed the bug of 'Set Overlay's Color bar' in Matlab R2007a or latter version.
            sizetheTI=size(theTransverseImg);%Dong 091026
            if theMagnifyCoefficient<1
                sizeTI=[floor(sizetheTI(1)*theMagnifyCoefficient),floor(sizetheTI(2)*theMagnifyCoefficient/10)*10];%Dong 091026
            else
                sizeTI=[floor(sizetheTI(1)*theMagnifyCoefficient),floor(sizetheTI(2)*theMagnifyCoefficient)];%Dong 091026
            end
         
            theTransverseImg=imresize_old(theTransverseImg,sizeTI);
        else
            sizetheTI=size(theTransverseImg);%Dong 091026
            if theMagnifyCoefficient<1
                sizeTI=[floor(sizetheTI(1)*theMagnifyCoefficient),floor(sizetheTI(2)*theMagnifyCoefficient/10)*10];%Dong 091026
            else
                sizeTI=[floor(sizetheTI(1)*theMagnifyCoefficient),floor(sizetheTI(2)*theMagnifyCoefficient)];%Dong 091026
            end
            theTransverseImg=imresize(theTransverseImg,sizeTI);%theMagnifyCoefficient);%Dong 091026
        end
	end
	
	% Revise the Axes position to make it comfort to Magnify
	theFramePosParamSet =get(AConfig.hFrameSetPos, 'Position');
	theLeft 	=theFramePosParamSet(1) +theFramePosParamSet(3) +5;
	theBottom 	=10; %theFramePosParamSet(2);	
	thePosTransverse 	=[theLeft, theBottom, size(theTransverseImg,2), size(theTransverseImg,1)];
	
	%Map images to true color	
	theTransverseImg =repmat(theTransverseImg, [1 1 3]);
	
	%Add overlay
	if SeeOverlay(AConfig),
		theTransverseImg =AddOverlaySeries(AConfig, theTransverseImg,theMagnifyCoefficient);
	end
	
	% Show Images
	%Sagittal		
	set(AConfig.hAxesSagittal, 'Visible','off');
	set(AConfig.hImageSagittal,'Visible','off');
	set(AConfig.hXLineSagittal, 'Visible','off');
	set(AConfig.hYLineSagittal, 'Visible','off');	
	%Coronal		 
	set(AConfig.hAxesCoronal, 'Visible','off');
	set(AConfig.hImageCoronal,'Visible','off');
	set(AConfig.hXLineCoronal, 'Visible','off');
	set(AConfig.hYLineCoronal, 'Visible','off');	
	
	%Transverse
	%theTransverseImg =repmat(theTransverseImg, [1, 1, 3])/AConfig.Contrast.GrayDepth; % For true color display
	set(AConfig.hImageTransverse, 'CData', (theTransverseImg), 'HitTest', 'off', 'Visible','on');
	%colormap(gray(AConfig.Contrast.GrayDepth));	
	set(AConfig.hAxesTransverse, 'Visible','on', ...
		'XLim', [1 size(theTransverseImg,2)], ...
		'YLim', [1 size(theTransverseImg,1)], ...
		'Position', thePosTransverse);	
	set(AConfig.hXLineTransverse, 'HitTest','off','Visible', IsCrosshairChecked(AConfig), ...		
		'XData', ([1 nDim1] +(theCenterZ_Col-1)*nDim1 )* theMagnifyCoefficient, ...
		'YData', ([1 1]*AConfig.LastPosition(2) + (theCenterZ_Row-1)*nDim2) *theMagnifyCoefficient);%Parallel to X-axis
	set(AConfig.hYLineTransverse, 'HitTest','off','Visible', IsCrosshairChecked(AConfig), ...		
		'XData', ([1 1]*AConfig.LastPosition(1)+(theCenterZ_Col-1)*nDim1) * theMagnifyCoefficient , ...
		'YData', ([1 nDim2]+(theCenterZ_Row-1)*nDim2)* theMagnifyCoefficient );%Parallel to Y-axis
	
	
	%Clear Text labels first
	ClearTextLabels(AConfig);
	
	%Write text label to indicate the Z value
	if AConfig.Montage.WantLabel,
		for theRow=AConfig.Montage.Down:-1:1,
			for theCol=1:AConfig.Montage.Across,
				%I don't draw the last image because it is used to indicate the positions				
				theZIndex = theZSeries((AConfig.Montage.Down-theRow)*AConfig.Montage.Across +theCol);% DONG Zhang-Ye 090721 %
				theZIndex = theZIndex -AConfig.Origin(3);
												
				%Transform to Physical distance 20071102
				theZIndex = AConfig.VoxelSize(3) *theZIndex;
						
				theY =theRow*nDim2* theMagnifyCoefficient;
				%DONG Zhang-Ye 090721 %theY
				%=(AConfig.Montage.Down-theRow+1)*nDim2* theMagnifyCoefficient;
                %YAN Chao-Gan 081229 theY =(theRow)*nDim2* theMagnifyCoefficient;
				theX =(theCol-1)*nDim1* theMagnifyCoefficient;
				
				text( theX,theY,sprintf('%+gmm',theZIndex), 'Parent', AConfig.hAxesTransverse, 'Color', AConfig.Overlay.LabelColor, 'HitTest', 'off', 'VerticalAlignment', 'top', 'Units', 'pixels');			
			end
		end	
	end
	
	Result =AConfig;
	
function Result =SetView_Sagittal(AConfig)
	[nDim1 nDim2 nDim3] =size(AConfig.Volume);
	theCenterX =AConfig.LastPosition(1);
	theCount   =AConfig.Montage.Across *AConfig.Montage.Down ;
	
	theXSeries =theCenterX -([floor(theCount/2) : -1 :ceil(-theCount/2)]) *AConfig.Montage.Spacing;	
	while ~isempty(find(theXSeries<=0)),
		theXSeries(find(theXSeries<=0)) = theXSeries(find(theXSeries<=0)) +nDim1;
	end
	while ~isempty(find(theXSeries>nDim1)),
		theXSeries(find(theXSeries>nDim1)) = theXSeries(find(theXSeries>nDim1)) -nDim1;
	end
	
	theSagittalImg = zeros(nDim3 * AConfig.Montage.Down, nDim2 *AConfig.Montage.Across);
	for theRow=AConfig.Montage.Down:-1:1,
		for theCol=1:AConfig.Montage.Across,
			%I don't draw the last image because it is used to indicate the positions				
			%DONG Zhang-Ye 090721 %theXIndex = theXSeries((theRow-1)*AConfig.Montage.Across +theCol);
      theXIndex = theXSeries((AConfig.Montage.Down-theRow)*AConfig.Montage.Across +theCol);
			theSagittalImg((theRow-1)*nDim3 +(1:nDim3), (theCol-1)*nDim2+(1:nDim2)) =GetGrayImage('Sagittal', AConfig.Volume, theXIndex);
			%Write the X Coordinates to the left-down corner
			%I have to move this code to the end of Setting Axis by using TEXT function
			
			%Save the Center image's Row and Col for CrossHair-line displaying
			if theXIndex==theCenterX,
				theCenterX_Row =theRow;
				theCenterX_Col =theCol;
			end
		end
	end		
	%Save View Series
	AConfig.ViewSeries = theXSeries;
	%Auto balance	
	theSagittalImg =SaturateContrast(theSagittalImg, AConfig.Contrast.SatMin, AConfig.Contrast.SatMax);
	
	%Calculate the Result Image after Magnifying
	theMagnifyCoefficient =GetMagnifyCoefficient(AConfig);
	if license('test','image_toolbox')==1 && theMagnifyCoefficient~=1, 		
        if rest_misc('GetMatlabVersion')>=7.4   %YAN Chao-Gan 090401: The imresize function has been completely rewritten in Matlab R2007a. Fixed the bug of 'Set Overlay's Color bar' in Matlab R2007a or latter version.
            sizetheTI=size(theSagittalImg);%Dong 091026
            if theMagnifyCoefficient<0.1
                sizeTI=[floor(sizetheTI(1)*theMagnifyCoefficient),floor(sizetheTI(2)*theMagnifyCoefficient/10)*10];%Dong 091026
            else
                sizeTI=[floor(sizetheTI(1)*theMagnifyCoefficient),floor(sizetheTI(2)*theMagnifyCoefficient)];%Dong 091026
            end
             theSagittalImg=imresize_old( theSagittalImg,sizeTI);
        else
           sizetheTI=size(theSagittalImg);%Dong 091026
            if theMagnifyCoefficient<0.1
                sizeTI=[floor(sizetheTI(1)*theMagnifyCoefficient),floor(sizetheTI(2)*theMagnifyCoefficient/10)*10];%Dong 091026
            else
                sizeTI=[floor(sizetheTI(1)*theMagnifyCoefficient),floor(sizetheTI(2)*theMagnifyCoefficient)];%Dong 091026
            end
            theSagittalImg=imresize( theSagittalImg,sizeTI);%Dong 091026
        end
	end
	
	% Revise the Axes position to make it comfort to Magnify
	theFramePosParamSet =get(AConfig.hFrameSetPos, 'Position');
	theLeft 	=theFramePosParamSet(1) +theFramePosParamSet(3) +5;
	theBottom 	=10; %theFramePosParamSet(2);	
	thePosSagittal 	=[theLeft, theBottom, size(theSagittalImg,2), size(theSagittalImg,1)];
	
	%Map images to true color	 
	theSagittalImg =repmat(theSagittalImg, [1 1 3]);
	
	%Add overlay
	if SeeOverlay(AConfig),
		theSagittalImg =AddOverlaySeries(AConfig, theSagittalImg,theMagnifyCoefficient);	
	end
	
	% Show Images
	%Transverse			
	set(AConfig.hAxesTransverse, 'Visible','off');
	set(AConfig.hImageTransverse,'Visible','off');
	set(AConfig.hXLineTransverse, 'Visible','off');
	set(AConfig.hYLineTransverse, 'Visible','off');
	%Coronal		 
	set(AConfig.hAxesCoronal, 'Visible','off');
	set(AConfig.hImageCoronal,'Visible','off');
	set(AConfig.hXLineCoronal, 'Visible','off');
	set(AConfig.hYLineCoronal, 'Visible','off');	
	
	%Transverse
	%theTransverseImg =repmat(theTransverseImg, [1, 1, 3])/AConfig.Contrast.GrayDepth; % For true color display
	set(AConfig.hImageSagittal, 'CData', (theSagittalImg), 'HitTest', 'off', 'Visible','on');
	%colormap(gray(AConfig.Contrast.GrayDepth));	
	set(AConfig.hAxesSagittal, 'Visible','on', ...
		'XLim', [1 size(theSagittalImg,2)], ...
		'YLim', [1 size(theSagittalImg,1)], ...
		'Position', thePosSagittal);	
	set(AConfig.hXLineSagittal, 'HitTest','off','Visible', IsCrosshairChecked(AConfig), ...		
		'XData', ([1 nDim2] +(theCenterX_Col-1)*nDim2 )* theMagnifyCoefficient, ...
		'YData', ([1 1]*AConfig.LastPosition(3) + (theCenterX_Row-1)*nDim3) *theMagnifyCoefficient);%Parallel to X-axis
	set(AConfig.hYLineSagittal, 'HitTest','off','Visible', IsCrosshairChecked(AConfig), ...		
		'XData', ([1 1]*AConfig.LastPosition(2)+(theCenterX_Col-1)*nDim2) * theMagnifyCoefficient , ...
		'YData', ([1 nDim3]+(theCenterX_Row-1)*nDim3)* theMagnifyCoefficient );%Parallel to Y-axis
		
	%Clear Text labels first
	ClearTextLabels(AConfig);	
	%Write text label to indicate the Z value
	if AConfig.Montage.WantLabel,
		for theRow=AConfig.Montage.Down:-1:1,
			for theCol=1:AConfig.Montage.Across,
        theXIndex = theXSeries((AConfig.Montage.Down-theRow)*AConfig.Montage.Across +theCol);
				%DONG Zhang-Ye 090721 %theXIndex = theXSeries((theRow-1)*AConfig.Montage.Across +theCol);
				theXIndex = theXIndex -AConfig.Origin(1);
				
				%Transform to Physical distance 20071102
				theXIndex = AConfig.VoxelSize(1) *theXIndex;
				%Dawnsong 20071102 Revise to make sure the left image/Right brain is +
				theXIndex =(-1) *theXIndex;
							
				theY =(theRow)*nDim3*theMagnifyCoefficient;
				%DONG Zhang-Ye 090721 %theY =(AConfig.Montage.Down-theRow+1)*nDim3* theMagnifyCoefficient;
                % YAN Chao-Gan 090715, theY =(theRow)*nDim3*theMagnifyCoefficient;
				theX =(theCol-1)*nDim2* theMagnifyCoefficient;
				text( theX,theY,sprintf('%+gmm',theXIndex), 'Parent', AConfig.hAxesSagittal, 'Color', AConfig.Overlay.LabelColor, 'HitTest', 'off', 'VerticalAlignment', 'top', 'Units', 'pixels');			
			end
		end	
	end
			
	Result =AConfig;
	
function Result =SetView_Coronal(AConfig)
	[nDim1 nDim2 nDim3] =size(AConfig.Volume);
	theCenterY =AConfig.LastPosition(2);
	theCount   =AConfig.Montage.Across *AConfig.Montage.Down ;
	
	theYSeries =theCenterY -([floor(theCount/2) : -1 :ceil(-theCount/2)]) *AConfig.Montage.Spacing;	
	while ~isempty(find(theYSeries<=0)),
		theYSeries(find(theYSeries<=0)) = theYSeries(find(theYSeries<=0)) +nDim2;
	end
	while ~isempty(find(theYSeries>nDim2)),
		theYSeries(find(theYSeries>nDim2)) = theYSeries(find(theYSeries>nDim2)) -nDim2;
	end
	
	theCoronalImg = zeros(nDim3 * AConfig.Montage.Down, nDim1 *AConfig.Montage.Across);
	for theRow=AConfig.Montage.Down:-1:1,
		for theCol=1:AConfig.Montage.Across,
			%I don't draw the last image because it is used to indicate the positions	AConfig.Montage.Down-theRow		
      theYIndex = theYSeries((AConfig.Montage.Down-theRow)*AConfig.Montage.Across +theCol);
      %DONG Zhang-Ye 090721 %theYIndex = theYSeries((theRow-1)*AConfig.Montage.Across +theCol);
      theCoronalImg((theRow-1)*nDim3 +(1:nDim3), (theCol-1)*nDim1+(1:nDim1)) =GetGrayImage('Coronal', AConfig.Volume, theYIndex);
			%DONG Zhang-Ye 090721 %theCoronalImg((AConfig.Montage.Down-theRow)*nDim3 +(1:nDim3), (theCol-1)*nDim1+(1:nDim1)) =GetGrayImage('Coronal', AConfig.Volume, theYIndex);
		
			%Write the Z Coordinates to the left-down corner
			%I have to move this code to the end of Setting Axis by using TEXT function
			
			%Save the Center image's Row and Col for CrossHair-line displaying
			if theYIndex==theCenterY,
				theCenterY_Row =theRow;
				theCenterY_Col =theCol;
			end
		end
	end			
	%Save View Series
	AConfig.ViewSeries = theYSeries;
	%Auto balance
	theCoronalImg =SaturateContrast(theCoronalImg, AConfig.Contrast.SatMin, AConfig.Contrast.SatMax);
	
	%Calculate the Result Image after Magnifying
	theMagnifyCoefficient =GetMagnifyCoefficient(AConfig);
	if license('test','image_toolbox')==1 && theMagnifyCoefficient~=1, 		
        if rest_misc('GetMatlabVersion')>=7.4   %YAN Chao-Gan 090401: The imresize function has been completely rewritten in Matlab R2007a. Fixed the bug of 'Set Overlay's Color bar' in Matlab R2007a or latter version.
            sizetheTI=size(theCoronalImg);%Dong 091026
            if theMagnifyCoefficient<1
                sizeTI=[floor(sizetheTI(1)*theMagnifyCoefficient),floor(sizetheTI(2)*theMagnifyCoefficient/10)*10];%Dong 091026
            else
                sizeTI=[floor(sizetheTI(1)*theMagnifyCoefficient),floor(sizetheTI(2)*theMagnifyCoefficient)];%Dong 091026
            end
            theCoronalImg=imresize_old(theCoronalImg,sizeTI);
        else
            sizetheTI=size(theCoronalImg);%Dong 091026
            if theMagnifyCoefficient<1
                sizeTI=[floor(sizetheTI(1)*theMagnifyCoefficient),floor(sizetheTI(2)*theMagnifyCoefficient/10)*10];%Dong 091026
            else
                sizeTI=[floor(sizetheTI(1)*theMagnifyCoefficient),floor(sizetheTI(2)*theMagnifyCoefficient)];%Dong 091026
            end
            theCoronalImg=imresize(theCoronalImg,sizeTI);%theMagnifyCoefficient);%Dong 091026
        end
	end
	
	% Revise the Axes position to make it comfort to Magnify
	theFramePosParamSet =get(AConfig.hFrameSetPos, 'Position');
	theLeft 	=theFramePosParamSet(1) +theFramePosParamSet(3) +5;
	theBottom 	=10; %theFramePosParamSet(2);	
	thePosCoronal 	=[theLeft, theBottom, size(theCoronalImg,2), size(theCoronalImg,1)];
	
	%Map images to true color	
	theCoronalImg =repmat(theCoronalImg, [1 1 3]);
	
	%Add overlay
	if SeeOverlay(AConfig),
		theCoronalImg =AddOverlaySeries(AConfig, theCoronalImg,theMagnifyCoefficient);	
	end
	
	% Show Images
	%Transverse			
	set(AConfig.hAxesTransverse, 'Visible','off');
	set(AConfig.hImageTransverse,'Visible','off');
	set(AConfig.hXLineTransverse, 'Visible','off');
	set(AConfig.hYLineTransverse, 'Visible','off');
	%Sagittal
	set(AConfig.hAxesSagittal, 'Visible','off');
	set(AConfig.hImageSagittal,'Visible','off');
	set(AConfig.hXLineSagittal, 'Visible','off');
	set(AConfig.hYLineSagittal, 'Visible','off');
		
	%Transverse
	%theTransverseImg =repmat(theTransverseImg, [1, 1, 3])/AConfig.Contrast.GrayDepth; % For true color display
	set(AConfig.hImageCoronal, 'CData', (theCoronalImg), 'HitTest', 'off', 'Visible','on');
	%colormap(gray(AConfig.Contrast.GrayDepth));	
	set(AConfig.hAxesCoronal, 'Visible','on', ...
		'XLim', [1 size(theCoronalImg,2)], ...
		'YLim', [1 size(theCoronalImg,1)], ...
		'Position', thePosCoronal);	
	
	set(AConfig.hXLineCoronal, 'HitTest','off','Visible', IsCrosshairChecked(AConfig), ...		
		'XData', ([1 nDim1] +(theCenterY_Col-1)*nDim1 )* theMagnifyCoefficient, ...
		'YData', ([1 1]*AConfig.LastPosition(3) + (theCenterY_Row-1)*nDim3) *theMagnifyCoefficient);%Parallel to X-axis
	set(AConfig.hYLineCoronal, 'HitTest','off','Visible', IsCrosshairChecked(AConfig), ...		
		'XData', ([1 1]*AConfig.LastPosition(1)+(theCenterY_Col-1)*nDim1) * theMagnifyCoefficient , ...
		'YData', ([1 nDim3]+(theCenterY_Row-1)*nDim3)* theMagnifyCoefficient );%Parallel to Y-axis
		
	%Clear Text labels first
	ClearTextLabels(AConfig);	
	%Write text label to indicate the Z value
	if AConfig.Montage.WantLabel,
		for theRow=AConfig.Montage.Down:-1:1,
			for theCol=1:AConfig.Montage.Across,
				%I don't draw the last image because it is used to indicate the positions				
				theYIndex = theYSeries((theRow-1)*AConfig.Montage.Across +theCol);
				theYIndex = theYIndex -AConfig.Origin(2);
								
				%Transform to Physical distance 20071102
				theYIndex = AConfig.VoxelSize(2) *theYIndex;
				
				theY =(AConfig.Montage.Down-theRow+1)*nDim3* theMagnifyCoefficient;
                % YAN Chao-Gan, 090715 %theY =theRow*nDim3* theMagnifyCoefficient;
				theX =(theCol-1)*nDim1* theMagnifyCoefficient;
				text( theX,theY,sprintf('%+gmm',theYIndex), 'Parent', AConfig.hAxesCoronal, 'Color', AConfig.Overlay.LabelColor, 'HitTest', 'off', 'VerticalAlignment', 'top', 'Units', 'pixels');			
			end
		end	
	end
	Result =AConfig;
	
function Result =GetGrayImage(AType, AVolume, APosition)
%Return raw image data at specific position in the Volume
	if nargin~=3, error('Result =GetGrayImage(AVolume, AType)'); end
	switch lower(AType)
	case 'sagittal',
		Result =squeeze(AVolume(APosition, :, :));
	case 'coronal',
		Result =squeeze(AVolume(:,APosition, :));
	case 'transverse',
		Result =squeeze(AVolume(:, :, APosition));
	otherwise
	end
	Result =Result';
	
function Result =ClickPositionCrossHair(AConfig)
	theFig 			=AConfig.hFig;
	hAxesSagittal 	=AConfig.hAxesSagittal;
	hAxesCoronal 	=AConfig.hAxesCoronal;
	hAxesTransverse =AConfig.hAxesTransverse;
	theAxes			=get(theFig, 'CurrentObject');
	%Check legal click point in the axes
	thePoint		=get(theAxes,'CurrentPoint');
	thePoint 		=thePoint(1, 1:2);
    theXLim =get(theAxes, 'XLim');
    theYLim =get(theAxes, 'YLim');	
	if thePoint(1)<theXLim(1) || thePoint(1)>theXLim(2) ...
	   || thePoint(2)<theYLim(1) || thePoint(2)>theYLim(2) ,
		Result =AConfig;
		return;
	end	
	
	thePosition		=AConfig.LastPosition; 
	theMagnifyCoefficient =GetMagnifyCoefficient(AConfig);	
	switch theAxes,
	case hAxesSagittal,
		thePosition(2) =round(thePoint(1));% x is Y
		thePosition(3) =round(thePoint(2));%y is Z		
		%Calculate the Result Position after Magnifying
		if license('test','image_toolbox')==1 && theMagnifyCoefficient~=1, 
			thePosition(2) =round(thePosition(2) / theMagnifyCoefficient);		
			thePosition(3) =round(thePosition(3) / theMagnifyCoefficient);		
		end
	case hAxesCoronal,
		thePosition(1) =round(thePoint(1));%x is X
		thePosition(3) =round(thePoint(2));%x is Z
		%Calculate the Result Position after Magnifying
		if license('test','image_toolbox')==1 && theMagnifyCoefficient~=1, 
			thePosition(1) =round(thePosition(1) / theMagnifyCoefficient);		
			thePosition(3) =round(thePosition(3) / theMagnifyCoefficient);		
		end
	case hAxesTransverse,
		thePosition(1) =round(thePoint(1));%x is  X
		thePosition(2) =round(thePoint(2));%y is Y
		%Calculate the Result Position after Magnifying
		if license('test','image_toolbox')==1 && theMagnifyCoefficient~=1, 
			thePosition(1) =round(thePosition(1) / theMagnifyCoefficient);		
			thePosition(2) =round(thePosition(2) / theMagnifyCoefficient);		
		end
	otherwise
		error(sprintf('Error call: It must be called by Axes''s ButtonDownFcn\nWhy did this occur?\nThere must be something wrong.\nrun "clear all" or re-start MATLAB to avoid this error.\n Dawnwei.song 20070526'));
	end
	
	% AConfig.LastPosition =thePosition;
	AConfig =UpdatePosition(AConfig, thePosition);
	%Display Images
	AConfig =SetImage(AConfig);
	
	Result =AConfig;
	
function Result =ClickPositionInSagittalMode(AConfig)
	theFig 			=AConfig.hFig;
	[nDim1 nDim2 nDim3] =size(AConfig.Volume);
	theAxes			=get(theFig, 'CurrentObject');
	%Check legal click point in the axes
	thePoint		=get(theAxes,'CurrentPoint');
	thePoint 		=round(thePoint(1, 1:2));
    theXLim =get(theAxes, 'XLim');
    theYLim =get(theAxes, 'YLim');	
	if thePoint(1)<theXLim(1) || thePoint(1)>theXLim(2) ...
	   || thePoint(2)<theYLim(1) || thePoint(2)>theYLim(2) ,
		Result =AConfig;
		return;
	end	
	
	theMagnifyCoefficient =GetMagnifyCoefficient(AConfig);
	thePosition		=AConfig.LastPosition; 
	thePosition(2)  =mod(thePoint(1), nDim2* theMagnifyCoefficient);% x is Y
	thePosition(3)  =mod(thePoint(2), nDim3* theMagnifyCoefficient);%y is Z		
		
	theSeries_RowId =ceil(thePoint(2)/ (theYLim(2)/AConfig.Montage.Down));
	theSeries_ColId =ceil(thePoint(1)/ (theXLim(2)/AConfig.Montage.Across));
	thePointId_inSeries =(theSeries_RowId -1)*AConfig.Montage.Across +theSeries_ColId;
	
	%Calculate the Result Position after Magnifying
	if license('test','image_toolbox')==1 && theMagnifyCoefficient~=1, 
		thePosition(2) =round(thePosition(2) / theMagnifyCoefficient);		
		thePosition(3) =round(thePosition(3) / theMagnifyCoefficient);		
		theXLim 	   =round(theXLim /theMagnifyCoefficient);
		theYLim 	   =round(theYLim /theMagnifyCoefficient);
	end		
	
	%Set the real position
	thePosition(1) = AConfig.ViewSeries(thePointId_inSeries);	
	% AConfig.LastPosition =thePosition;
	AConfig =UpdatePosition(AConfig, thePosition);
	
	%Display Images
	AConfig =SetImage(AConfig);	
	
	Result =AConfig;
	
function Result =ClickPositionInCoronalMode(AConfig)
	theFig 			=AConfig.hFig;
	[nDim1 nDim2 nDim3] =size(AConfig.Volume);
	theAxes			=get(theFig, 'CurrentObject');
	%Check legal click point in the axes
	thePoint		=get(theAxes,'CurrentPoint');
	thePoint 		=round(thePoint(1, 1:2));
    theXLim =get(theAxes, 'XLim');
    theYLim =get(theAxes, 'YLim');	
	if thePoint(1)<theXLim(1) || thePoint(1)>theXLim(2) ...
	   || thePoint(2)<theYLim(1) || thePoint(2)>theYLim(2) ,
		Result =AConfig;
		return;
	end	
	
	theMagnifyCoefficient =GetMagnifyCoefficient(AConfig);
	thePosition		=AConfig.LastPosition; 
	thePosition(1)  =mod(thePoint(1), nDim1* theMagnifyCoefficient);% x is Y
	thePosition(3)  =mod(thePoint(2), nDim3* theMagnifyCoefficient);%y is Z		
	
	
	theSeries_RowId =ceil(thePoint(2)/ (theYLim(2)/AConfig.Montage.Down));
	theSeries_ColId =ceil(thePoint(1)/ (theXLim(2)/AConfig.Montage.Across));
	thePointId_inSeries =(theSeries_RowId -1)*AConfig.Montage.Across +theSeries_ColId;
	
	%Calculate the Result Position after Magnifying
	if license('test','image_toolbox')==1 && theMagnifyCoefficient~=1, 
		thePosition(1) =round(thePosition(1) / theMagnifyCoefficient);		
		thePosition(3) =round(thePosition(3) / theMagnifyCoefficient);		
		theXLim 	   =round(theXLim /theMagnifyCoefficient);
		theYLim 	   =round(theYLim /theMagnifyCoefficient);
	end		
	
	%Set the real position
	thePosition(2) = AConfig.ViewSeries(thePointId_inSeries);	
	% AConfig.LastPosition =thePosition;
	AConfig =UpdatePosition(AConfig, thePosition);
	
	%Display Images
	AConfig =SetImage(AConfig);	
	
	Result =AConfig;	
	
function Result =ClickPositionInTransverseMode(AConfig)
	theFig 			=AConfig.hFig;
	[nDim1 nDim2 nDim3] =size(AConfig.Volume);
	theAxes			=get(theFig, 'CurrentObject');
	%Check legal click point in the axes
	thePoint		=get(theAxes,'CurrentPoint');
	thePoint 		=round(thePoint(1, 1:2));
    theXLim =get(theAxes, 'XLim');
    theYLim =get(theAxes, 'YLim');	
	if thePoint(1)<theXLim(1) || thePoint(1)>theXLim(2) ...
	   || thePoint(2)<theYLim(1) || thePoint(2)>theYLim(2) ,
		Result =AConfig;
		return;
	end	
	
	theMagnifyCoefficient =GetMagnifyCoefficient(AConfig);
	thePosition		=AConfig.LastPosition; 
	thePosition(1)  =mod(thePoint(1), nDim1* theMagnifyCoefficient);% x is Y
	thePosition(2)  =mod(thePoint(2), nDim2* theMagnifyCoefficient);%y is Z		
				
	theSeries_RowId =ceil((theYLim(2)-thePoint(2))/ (theYLim(2)/AConfig.Montage.Down));
    %YAN Chao-Gan 081229 theSeries_RowId =ceil(thePoint(2)/ (theYLim(2)/AConfig.Montage.Down));
	theSeries_ColId =ceil(thePoint(1)/ (theXLim(2)/AConfig.Montage.Across));
	thePointId_inSeries =(theSeries_RowId -1)*AConfig.Montage.Across +theSeries_ColId;
	
	%Calculate the Result Position after Magnifying
	if license('test','image_toolbox')==1 && theMagnifyCoefficient~=1, 
		thePosition(1) =round(thePosition(1) / theMagnifyCoefficient);		
		thePosition(2) =round(thePosition(2) / theMagnifyCoefficient);		
		theXLim 	   =round(theXLim /theMagnifyCoefficient);
		theYLim 	   =round(theYLim /theMagnifyCoefficient);
	end		
	
	%Set the real position
	thePosition(3) = AConfig.ViewSeries(thePointId_inSeries);	
	% AConfig.LastPosition =thePosition;
	AConfig =UpdatePosition(AConfig, thePosition);
	
	%Display Images
	AConfig =SetImage(AConfig);	
	
	Result =AConfig;

function Result =SetPositionCrossHair(AConfig)		
	% theCurrentControl =gco;
	% uicontrol(AConfig.hYoke);
	%I must change the current focus to force the callback of the edit to run at once to make sure 'get' can return current string/value instead of old value
	% when I use KeyPressFcn. And KeyPressFcn didn't exist for uicontrol before Matlab 7. In Matlab 6.5, there is only KeyPressFcn for figure;
	
	thePosition =AConfig.LastPosition;	
	theXLim =[1, size(AConfig.Volume, 1)];
	theYLim =[1, size(AConfig.Volume, 2)];
	theZLim =[1, size(AConfig.Volume, 3)];
	theX =str2num(get(AConfig.hEditPositionX, 'String'));
	theY =str2num(get(AConfig.hEditPositionY, 'String'));
	theZ =str2num(get(AConfig.hEditPositionZ, 'String'));
	
	%Revise Direction , dawnsong20071101
	theX = theX * (-1);
	
	
	theX =round(theX/AConfig.VoxelSize(1) +AConfig.Origin(1));
	theY =round(theY/AConfig.VoxelSize(2) +AConfig.Origin(2));
	theZ =round(theZ/AConfig.VoxelSize(3) +AConfig.Origin(3));
	
	
	
	% uicontrol(theCurrentControl);
	
	if ~isempty(theX) && theX>=theXLim(1) ...
		&& ~isempty(theY) && theY>=theYLim(1) ...
		&& ~isempty(theZ) && theZ>=theZLim(1) ...
		&& any(thePosition ~= [theX theY theZ]) ,
		
		if theX >theXLim(2), theX =theXLim(2); end
		if theY >theYLim(2), theY =theYLim(2); end
		if theZ >theZLim(2), theZ =theZLim(2); end
		
		thePosition =[theX theY theZ];		
		% AConfig.LastPosition =thePosition;
		AConfig =UpdatePosition(AConfig, thePosition);
	end		
	
	%Display Images
	AConfig =SetImage(AConfig);
	%Save LastPosition
	Result =AConfig;
	
function Result =SetDistanceFromOrigin(AConfig, ADistanceFromOrigin);
% Set current cross-hair position according to the Proportion Position among many size-not-equal brain images			
	thePosition = ADistanceFromOrigin ./ AConfig.VoxelSize + AConfig.Origin;
	thePosition =round(thePosition);
	if any(thePosition ~= AConfig.LastPosition) ...
		&& thePosition(1)>=1 && thePosition(1)<=size(AConfig.Volume,1) ...
		&& thePosition(2)>=1 && thePosition(2)<=size(AConfig.Volume,2) ...
		&&  thePosition(3)>=1 && thePosition(3)<=size(AConfig.Volume,3) , ...
		% AConfig.LastPosition =thePosition;
		AConfig =UpdatePosition(AConfig, thePosition);
	elseif any(thePosition ~= AConfig.LastPosition),
		for x=1:3,
			while thePosition(x)<1,
				thePosition(x) =thePosition(x) +size(AConfig.Volume,x);
			end
			while thePosition(x)>size(AConfig.Volume,x),
				thePosition(x) =thePosition(x) -size(AConfig.Volume,x);
			end
		end
	end
	
	%Display Images
	AConfig =SetImage(AConfig);	
	%Save LastPosition
	Result =AConfig;
	
function ShowPositionInEdit(AConfig)
	thePosition =AConfig.LastPosition;
	set(AConfig.hEditPositionX, 'String', num2str((thePosition(1)-AConfig.Origin(1))*AConfig.VoxelSize(1) *(-1) ));	%Make sure Left is Right like BA, and Left-image is + or Right-Brain is +
	set(AConfig.hEditPositionY, 'String', num2str((thePosition(2)-AConfig.Origin(2) )*AConfig.VoxelSize(2) ));	%Make sure Fore is +
	set(AConfig.hEditPositionZ, 'String', num2str((thePosition(3)-AConfig.Origin(3) )*AConfig.VoxelSize(3) ));	%Make sure Top is +
	
function SetMessage(AConfig)
	%Detect if I should hide the big information area
	theTitle ='Click to Toggle Hdr info';
	theOldMsg =get(AConfig.hMsgLabel, 'String');
	
	if SeeOverlay(AConfig),
		%Compute the cooresponding position according to physical distance(mm) from origin
		thePhysicalPos = (AConfig.LastPosition -AConfig.Origin) .* AConfig.VoxelSize;
		theOverlayPos  = thePhysicalPos ./ AConfig.Overlay.VoxelSize +AConfig.Overlay.Origin;
		theOverlayPos =round(theOverlayPos);
		if all(theOverlayPos<=size(AConfig.Overlay.Volume)) ...
			&& all(theOverlayPos >=[1 1 1]),
			%Legal
		else%Illegal data
			warning(sprintf('Illegal Overlay Position: (%s)\nI will revise the underlay''s position to its origin.', num2str(theOverlayPos)));
			%Revise the LastPosition on the underlay to the origin
			AConfig.LastPosition =AConfig.Origin;	%This line will not work because This fun didn't save the Global variable AConfig
			DPARSF_rest_sliceviewer('SetPhysicalPosition', AConfig.hFig, [0 0 0]);
			DPARSF_rest_sliceviewer('Repaint', AConfig.hFig);
			return;
		end
		
		theUnderlayIntensity =AConfig.Volume(AConfig.LastPosition(1),AConfig.LastPosition(2),AConfig.LastPosition(3));
		 
		theOverlayIntensity  =AConfig.Overlay.Volume(theOverlayPos(1),theOverlayPos(2),theOverlayPos(3));
		if  prod(size(AConfig.Overlay.InfoAal))==116 ...
			&& theOverlayIntensity>0,	%AAL template description
			theIntensity =sprintf('%s\n%g / %g', AConfig.Overlay.InfoAal{theOverlayIntensity},theUnderlayIntensity, theOverlayIntensity);
		else	%Default
			%Show the voxel's intensity for underlay and overlay
			theIntensity =sprintf('\n%g / %g', theUnderlayIntensity, theOverlayIntensity);
		end
		
		set(AConfig.hVoxelIntensity, 'String', theIntensity, 'TooltipString', ['Value: Underlay/Overlay = ', theIntensity]);
		
		theUnderlayInfo =sprintf('Dimension: %dx%dx%d\nVoxel(mm): %gx%gx%g\nOrigin(vxl): %d,%d,%d',size(AConfig.Volume,1), size(AConfig.Volume, 2), size(AConfig.Volume, 3), AConfig.VoxelSize(1), AConfig.VoxelSize(2),AConfig.VoxelSize(3), AConfig.Origin(1), AConfig.Origin(2), AConfig.Origin(3));
		theUnderlayInfo =sprintf('Underlay:\n%s\n\n', theUnderlayInfo);
		theOverlayInfo =sprintf('Dimension: %dx%dx%d\nVoxel(mm): %gx%gx%g\nOrigin(vxl): %d,%d,%d',size(AConfig.Overlay.Volume,1), size(AConfig.Overlay.Volume, 2), size(AConfig.Overlay.Volume, 3), AConfig.Overlay.VoxelSize(1), AConfig.Overlay.VoxelSize(2),AConfig.Overlay.VoxelSize(3), AConfig.Overlay.Origin(1), AConfig.Overlay.Origin(2), AConfig.Overlay.Origin(3));
		theOverlayInfo =sprintf('Overlay: (%s)\n%s', num2str((Pos_Underlay2Overlay(AConfig, AConfig.LastPosition) -AConfig.Overlay.Origin).*AConfig.Overlay.VoxelSize .* [-1, 1, 1]),theOverlayInfo);
		if isfield(AConfig.Overlay.Header,'mat')
            theOverlayInfo =sprintf('%s\nNIfTI Image: Displayed in Radiology Convention',theOverlayInfo);
        end
		theInfo =[theUnderlayInfo theOverlayInfo];
		%set(AConfig.hMsgLabel, 'String', theInfo);
	else	%Don't see Overlay
		theIntensity =sprintf('\n%g',AConfig.Volume(AConfig.LastPosition(1),AConfig.LastPosition(2),AConfig.LastPosition(3)));
		set(AConfig.hVoxelIntensity, 'String', theIntensity, 'TooltipString', ['Value: Underlay ', theIntensity]);
		
		theInfo =sprintf('Dimension: %dx%dx%d\nVoxel(mm): %gx%gx%g\nOrigin(vxl): %d,%d,%d',size(AConfig.Volume,1), size(AConfig.Volume, 2), size(AConfig.Volume, 3), AConfig.VoxelSize(1), AConfig.VoxelSize(2),AConfig.VoxelSize(3), AConfig.Origin(1), AConfig.Origin(2), AConfig.Origin(3));
		%set(AConfig.hMsgLabel, 'String', theInfo);
	end	
	
	if ~isempty(AConfig.Message) && ~all(isspace(AConfig.Message)),
		theInfo =sprintf('%s\n\n%s', theInfo, AConfig.Message);
	end
	
	if strcmpi(theTitle, theOldMsg),
		%Hide the Information as the old
		%set(AConfig.hMsgLabel, 'String', theInfo);
		set(AConfig.hMsgLabel, 'TooltipString', theInfo);
	else	%Normally showing the Hdr info
		set(AConfig.hMsgLabel, 'String', theInfo,'TooltipString', '');
    end
	%Threshhold value display
	set(AConfig.hEdtThrdValue, 'String', num2str(AConfig.Overlay.ValueThrdAbsolute));
    %hflag=AConfig.Overlay.Header;
   % if ExistViewer(AConfig.Overlay.Header.descrip)
   %AConfig.Overlay.ValueP=ThrdtoP(AConfig.Overlay.ValueThrdAbsolute,AConfig);
    %set(AConfig.hEdtPValue, 'String', sprintf('%.5f',AConfig.Overlay.ValueP)); % dong 090921 
	return;
		
function ResizeFigure(AConfig)
	MarginX =10; MarginY =10;	
	[nDim1, nDim2, nDim3] =size(AConfig.Volume);
	if strcmpi(get(AConfig.hFrameSetPos, 'Visible'), 'on'),
		theFramePos =get(AConfig.hFrameSetPos, 'Position');	
	else
		theFramePos =[0 0 0 0];
	end
	theMagnifyCoefficient =GetMagnifyCoefficient(AConfig); % Considering Magnifying result
	nDim1 =nDim1 *theMagnifyCoefficient;
	nDim2 =nDim2 *theMagnifyCoefficient;
	nDim3 =nDim3 *theMagnifyCoefficient;
	if strcmpi(AConfig.ViewMode, 'Orthogonal'),
		FigWidth  =theFramePos(1) +theFramePos(3) +MarginX + nDim1 +2 +nDim2 + MarginX;
		FigHeight =10 + nDim2 +2 +nDim3 + MarginY;		
	elseif strcmpi(AConfig.ViewMode, 'Transverse'),
		FigWidth  =theFramePos(1) +theFramePos(3) +MarginX + nDim1 * AConfig.Montage.Across + MarginX;
		FigHeight =MarginY + nDim2 * AConfig.Montage.Down + MarginY;		
	elseif strcmpi(AConfig.ViewMode, 'Sagittal'),
		FigWidth  =theFramePos(1) +theFramePos(3) +MarginX + nDim2 * AConfig.Montage.Across + MarginX;
		FigHeight =MarginY + nDim3 * AConfig.Montage.Down + MarginY;		
	elseif strcmpi(AConfig.ViewMode, 'Coronal'),
		FigWidth  =theFramePos(1) +theFramePos(3) +MarginX + nDim1 * AConfig.Montage.Across + MarginX;
		FigHeight =MarginY + nDim3 * AConfig.Montage.Down + MarginY;		
	end
	%Resize figure's width according to colorbar's visiblity
	if SeeOverlay(AConfig),
		theColorBarPos=get(AConfig.hAxesColorbar, 'Position');
		FigWidth = FigWidth +MarginX +theColorBarPos(3) +1.5*MarginX +MarginX;
	end
	%FigHeight =theFramePos(2) + nDim2 +2 +nDim3 + MarginY;
		
	
	% Revise the Intensity position	
	% theMsgPos =get(AConfig.hVoxelIntensity, 'Position');
	% theMsgPos(1) =theFramePos(1) +theFramePos(3) +MarginX + nDim1 +5;
	% theMsgPos(2) =theFramePos(2);
	% theMsgPos(3) = FigWidth -theMsgPos(1) -MarginX;
	% set(AConfig.hVoxelIntensity, 'Position', theMsgPos); %Set first
	
	% theIntensity =get(AConfig.hVoxelIntensity, 'String');
	% [newMsg,newMsgPos]=textwrap(AConfig.hVoxelIntensity, {theIntensity});
	% set(AConfig.hVoxelIntensity, 'Position', newMsgPos);
	
	%Revise the Message's position
	if strcmpi(get(AConfig.hMsgLabel,'Visible'), 'on'),
		theMsgPos =get(AConfig.hMsgLabel, 'Position');
		theMsgPos(1) =theFramePos(1);
		theMsgPos(2) =theFramePos(2) +theFramePos(4) +MarginY;
		theMsgPos(3) =theFramePos(3);
		theMsgPos(4) =1;
		set(AConfig.hMsgLabel, 'Position', theMsgPos); %Set default position first
		
		theMsg =get(AConfig.hMsgLabel, 'String');
		[theMsg, theMsgPos] =textwrap(AConfig.hMsgLabel, cellstr(theMsg));
		set(AConfig.hMsgLabel, 'String', theMsg, 'Position', theMsgPos);
	end
	% Revise the Do Callback Button's position
	% if AConfig.hDoCallbackBtn>0
		% thePos =get(AConfig.hDoCallbackBtn, 'Position');
		% thePos(1) =theMsgPos(1);
		% thePos(2) =theMsgPos(2) +theMsgPos(4) +MarginY;
		% thePos(3) =theMsgPos(3);
		% thePos(4) =25;
		% set(AConfig.hDoCallbackBtn, 'Position', thePos);
	% end
	
	% Revise the figure's position according to the Brain Image's width and height	
	thePos 		=get(AConfig.hFig, 'Position');
	theScrPos	=get(0, 'ScreenSize');	
	% if AConfig.hDoCallbackBtn>0
		% theBtnPos =get(AConfig.hDoCallbackBtn, 'Position');
		% if FigHeight< (theBtnPos(2) +theBtnPos(4) +MarginY)
			% FigHeight =theBtnPos(2) +theBtnPos(4) +MarginY;
		% end
	% else end
	if strcmpi(get(AConfig.hMsgLabel,'Visible'), 'on'),
		theMsgPos =get(AConfig.hMsgLabel, 'Position');
		if FigHeight< (theMsgPos(2) +theMsgPos(4) +MarginY)
			FigHeight =theMsgPos(2) +theMsgPos(4) +MarginY;
		end
	end
	if (thePos(2) +FigHeight +60) > theScrPos(4)
		thePos(2) = theScrPos(4) -FigHeight -60;
	end
	if thePos(3) <FigWidth
		thePos(3) =FigWidth;
	elseif	thePos(3) >1.5*FigWidth
		thePos(3) =FigWidth;
	end
	thePos(4) =FigHeight;
	set(AConfig.hFig, 'Position', thePos);
	
	%Resize figure position according to the Message height
	if strcmpi(get(AConfig.hMsgLabel,'Visible'), 'on'),
		theMsgPos =get(AConfig.hMsgLabel, 'Position');
		if ( theMsgPos(2)+theMsgPos(4) )> thePos(4), 
			thePos(3) =FigWidth;
			thePos(4) =theMsgPos(2)+theMsgPos(4) +MarginY;
			set(AConfig.hFig, 'Position', thePos);
		end
	end	

function Result =GetMagnifyCoefficient(AConfig)	
	if license('test','image_toolbox')~=1 ,
		Result =1;
		return;
	end

	theStr =get(AConfig.hMagnify ,'String');
	theIdx =get(AConfig.hMagnify ,'Value');
	Result =1;
	switch upper(theStr{theIdx}),
	case 'X0.5',
		Result =0.5;
	case 'X1',
		Result =1;
	case 'X2',
		Result =2;
	case 'X3',
		Result =3;
	otherwise
		rest_misc( 'ComplainWhyThisOccur');
	end

function Result =UpdateCallback(AConfig, ACallback, ACallbackCaption)
	Result =AConfig;
	Result.Callback =ACallback;
	% if ~isempty(ACallbackCaption) && ischar(ACallbackCaption)
		% theBtnCaption =ACallbackCaption;
	% else
		% theBtnCaption ='Do sth.';
	% end
	
	% if Result.hDoCallbackBtn>0
		% I have created the Button to respond to the click event
		% if ~isempty(ACallback) && ischar(ACallback) ,			
			% set(Result.hDoCallbackBtn, 'Callback', ACallback, 'String', theBtnCaption);
		% else
			% Remove the button because the Callback is illegal or empty
			% delete(Result.hDoCallbackBtn);
			% Result.hDoCallbackBtn =-1;
			% Result.Callback ='';
		% end
	% else
		% Create a Button responding the click event
		% if ~isempty(ACallback) && (ischar(ACallback) || isa(ACallback, 'function_handle')),
			% theCallback =sprintf('DPARSF_rest_sliceviewer(''RunCallback'', ''%s'');',AConfig.Filename);
			% Result.hDoCallbackBtn =uicontrol(Result.hFig, 'Style','pushbutton',  ...
							  % 'Units','pixels','String', theBtnCaption, ...
							  % 'Callback', theCallback);							  
		% end
	% end	
	
function ClearTextLabels(AConfig)	
	%Clear Text labels first for multislice mode
	theLabels =findobj(AConfig.hAxesSagittal, 'Type', 'text');
	for theX=1:length(theLabels), delete(theLabels(theX)); end
	theLabels =findobj(AConfig.hAxesCoronal, 'Type', 'text');
	for theX=1:length(theLabels), delete(theLabels(theX)); end
	theLabels =findobj(AConfig.hAxesTransverse, 'Type', 'text');
	for theX=1:length(theLabels), delete(theLabels(theX)); end
	
function Result =AutoBalance(AConfig)
	Result =AConfig;
	%Save Maping Image parameters, Auto balance 20070911 revised, 20070914 revised for Statistical map which has negative values	
	%Revise first
	Result.Volume(isnan(Result.Volume)) =0;
	Result.Volume(isinf(Result.Volume)) =0;
	%Begin computation, the following two lines are time-consuming up to 4.6 seconds!!!
	%But after replacing AConfig with Result, then their speed rocketed to 0.2 seconds!!!
	%Attention!!! Dawnwei.Song, 20070914
	theMaxVal=max(Result.Volume(:));
	theMinVal=min(Result.Volume(:));
	if theMaxVal>theMinVal,
		nBins=255;
		%Special processing just for very common images! 20071212
		if (theMaxVal<257) && (theMinVal>=0) && (theMaxVal-theMinVal>100), %not statistic map
			theSum =histc(Result.Volume(:), 1:ceil(theMaxVal));		
		else
			theSum =histc(Result.Volume(:), theMinVal:(theMaxVal-theMinVal)/254:theMaxVal);		
		end
		theSum =cumsum(theSum);
		theCdf =theSum/theSum(end);
		if rest_misc('GetMatlabVersion')>=7.3
			idxSatMin =find(theCdf>0.01, 1, 'first');
			idxSatMax =find(theCdf>=0.99, 1, 'first');			
		else
			idxSatMin =find(theCdf>0.01);
			idxSatMin =idxSatMin(1);
			idxSatMax =find(theCdf>=0.99);
			idxSatMax =idxSatMax(1);
		end	
		if idxSatMin==idxSatMax, idxSatMin =1; end	%20070919, For mask file's display
		theSatMin =(idxSatMin-1)/(nBins-1) *(theMaxVal-theMinVal) +theMinVal;
		theSatMax =(idxSatMax-1)/(nBins-1) *(theMaxVal-theMinVal) +theMinVal;	
	elseif theMaxVal==theMinVal,
		theSatMin =theMaxVal;
		theSatMax =theMaxVal;
	else
	end
	Result.Contrast.GrayDepth =255;
	Result.Contrast.SatMin =theSatMin;
	Result.Contrast.SatMax =theSatMax;
	%20070911, AutoBalance for contrast
	Result.Contrast.WindowWidth =theSatMax -theSatMin;
	Result.Contrast.WindowCenter=(theSatMax +theSatMin)/2;

	%For debug display
	% disp(Result.Contrast);
	
	
	
function Result =IsCrosshairChecked(AConfig)
	Result ='off';
	if get(AConfig.hCrosshair, 'Value'),
		Result ='on';
	end

function Transforming_MNI_Talairach(AConfig)
	isNeedUpdate =false;
	switch get(AConfig.hMniTal, 'Value'),
	case 1,	%'MNI/Talairach Coordinates'
		%Do nothing
	case 2, %'From Talairach to MNI'
		% AConfig.LastPosition 
		thePosition =round(rest_tal2mni(AConfig.LastPosition -AConfig.Origin) +AConfig.Origin);
		AConfig =UpdatePosition(AConfig, thePosition);
		isNeedUpdate =true;
	case 3, %'From MNI to Talairach'
		% AConfig.LastPosition 
		thePosition=round(rest_mni2tal(AConfig.LastPosition -AConfig.Origin) +AConfig.Origin);
		AConfig =UpdatePosition(AConfig, thePosition);
		isNeedUpdate =true;
	otherwise
	end
	% disp(AConfig.LastPosition);
	% return;
	
	if isNeedUpdate,
		ShowPositionInEdit(AConfig);
		SetMessage(AConfig);
		DPARSF_rest_sliceviewer('SetPosition', AConfig.Filename);
	end
	%Reset position in Choice selection
	set(AConfig.hMniTal, 'Value', 1);
	

function Result =SaturateContrast(AImage, ASatMin, ASatMax)	
	Result =AImage;
	if ASatMin<ASatMax,
		Result(find(Result<ASatMin)) =ASatMin;
		Result(find(Result>ASatMax)) =ASatMax;
		Result =(Result -ASatMin)/(ASatMax - ASatMin);
	elseif ASatMin==ASatMax,
		Result(:) =0.01;
	else
		error('ASatMin>ASatMax ???');
	end
	
	%Map a indexed 2D image to a 2D * 3 image which is true color image and range is in [0 , 1]
	% Result =repmat(Result, [1 1 3]) /AGrayDepth;

function Result =InitUnderlay(AConfig)	
%Input: Need AConfig.Filename specified	
	try
		[theVolume,theVoxelSize, Header] =rest_readfile(AConfig.Filename);  %%Yan 080610
        [pathstr, name, ext] = fileparts(AConfig.Filename);  %YAN Chao-Gan 100420 added. Change the first voxel of ch2bet.nii since it can not be displayed in a right way.
        if strcmpi(name,'ch2bet')
            theVolume(1,1,1)=254;
        end %YAN Chao-Gan 100420 added.
        theOrigin=Header.Origin; %%Yan 080610
		AConfig =AddRecentUnderlay(AConfig, AConfig.Filename);		
        AConfig.Header=Header; %%Yan 080610
	catch
		if ~(exist(AConfig.Filename, 'file')==2) ...			
			&& ( ~all(isspace(AConfig.Filename)) && ~isempty(isspace(AConfig.Filename))),
			warning(sprintf('Please check whether Img/Hdr file "%s" exist!', AConfig.Filename));
			warndlg(sprintf('Please check whether Img/Hdr file "%s" exist!', AConfig.Filename));
		end
		theVolume =255*zeros(181,217,181);	%theVolume(:) =round([1:prod(size(theVolume))]/2^16);
		theVoxelSize =[1 1 1];
		theOrigin =[90 126 72];
	end
	[nDim1, nDim2, nDim3] =size(theVolume);
		
	% Displaying Orthogonal images 	
	theFramePos =get(AConfig.hFrameSetPos, 'Position');	
	MarginY =10; MarginX =10;
	OffsetX =theFramePos(1) +theFramePos(3) +MarginX;
	OffsetY =MarginY;	
	
	%Delete old handles if exists any
	if ishandle(AConfig.hAxesSagittal), delete(AConfig.hAxesSagittal); end
	if ishandle(AConfig.hAxesCoronal), delete(AConfig.hAxesCoronal); end
	if ishandle(AConfig.hAxesTransverse), delete(AConfig.hAxesTransverse); end	
	%Save Images' handles
	if ishandle(AConfig.hImageSagittal), delete(AConfig.hImageSagittal); end	
	if ishandle(AConfig.hImageCoronal), delete(AConfig.hImageCoronal); end	
	if ishandle(AConfig.hImageTransverse), delete(AConfig.hImageTransverse); end		
	%Save Lines' handles
	if ishandle(AConfig.hXLineSagittal), delete(AConfig.hXLineSagittal); end		%x
	if ishandle(AConfig.hYLineSagittal), delete(AConfig.hYLineSagittal); end		%y
	if ishandle(AConfig.hXLineCoronal), delete(AConfig.hXLineCoronal); end		%x
	if ishandle(AConfig.hYLineCoronal), delete(AConfig.hYLineCoronal); end		%y
	if ishandle(AConfig.hXLineTransverse), delete(AConfig.hXLineTransverse); end	%x	
	if ishandle(AConfig.hYLineTransverse), delete(AConfig.hYLineTransverse); end	%y	
	
	
	%Create Axes and lines and images
	theAxesButtonDownFcn =sprintf('DPARSF_rest_sliceviewer(''ClickPosition'', %g);', AConfig.hFig);
	hAxesTransverse	=axes('Parent', AConfig.hFig, 'Box', 'on', ...
						  'Units', 'pixel', 'DrawMode','fast', ...
						  'Position', [OffsetX OffsetY nDim1 nDim2], ...
						  'YDir','normal', 'XTickLabel',[],'XTick',[], ...
						  'YTickLabel',[],'YTick',[], 'DataAspectRatio',[1 1 1],...
						  'ButtonDownFcn', theAxesButtonDownFcn);
	hImageTransverse =image('Tag','BrainImageTransverse', 'Parent', hAxesTransverse);
	set(hAxesTransverse,'YDir','normal','ButtonDownFcn', theAxesButtonDownFcn, 'XTickLabel',[],'XTick',[], ...
						  'YTickLabel',[],'YTick',[]);
	hXLineTransverse =line(0, 0, 'Parent', hAxesTransverse, 'Color', 'red');
	hYLineTransverse =line(0, 0, 'Parent', hAxesTransverse, 'Color', 'red');	
		
	hAxesCoronal 	=axes('Parent', AConfig.hFig, 'Box', 'on', ...
						  'Units', 'pixel', 'DrawMode','fast', ...
						  'Position', [OffsetX OffsetY+nDim2+2 nDim1 nDim3], ...
						  'YDir','normal', 'XTickLabel',[],'XTick',[], ...
						  'YTickLabel',[],'YTick',[], ...
						  'ButtonDownFcn', theAxesButtonDownFcn);
	hImageCoronal =image('Tag','BrainImageCoronal', 'Parent', hAxesCoronal);
	set(hAxesCoronal,'YDir','normal','ButtonDownFcn', theAxesButtonDownFcn, 'XTickLabel',[],'XTick',[], ...
						  'YTickLabel',[],'YTick',[]);
	hXLineCoronal =line(0, 0, 'Parent', hAxesCoronal, 'Color', 'red');
	hYLineCoronal =line(0, 0, 'Parent', hAxesCoronal, 'Color', 'red');
	
	hAxesSagittal 	=axes('Parent', AConfig.hFig, 'Box', 'on', ...
						  'Units', 'pixel', 'DrawMode','fast', ...
						  'Position', [OffsetX+nDim1+2 OffsetY+nDim2+2 nDim2 nDim3], ...
						  'YDir','normal', 'XTickLabel',[],'XTick',[], ...
						  'YTickLabel',[],'YTick',[], ...
						  'ButtonDownFcn', theAxesButtonDownFcn);
	hImageSagittal =image('Tag','BrainImageSagittal',  'Parent', hAxesSagittal);
	set(hAxesSagittal,'YDir','normal','ButtonDownFcn', theAxesButtonDownFcn, 'XTickLabel',[],'XTick',[], ...
						  'YTickLabel',[],'YTick',[]);
	hXLineSagittal =line(0, 0, 'Parent', hAxesSagittal, 'Color', 'red');
	hYLineSagittal =line(0, 0, 'Parent', hAxesSagittal, 'Color', 'red');		
	
	
	%Save Axes's handles
	AConfig.hAxesSagittal 	=hAxesSagittal;
	AConfig.hAxesCoronal 	=hAxesCoronal;
	AConfig.hAxesTransverse =hAxesTransverse;
	%Save Images' handles
	AConfig.hImageSagittal	 =hImageSagittal;
	AConfig.hImageCoronal 	 =hImageCoronal;
	AConfig.hImageTransverse =hImageTransverse;
	%Save Lines' handles
	AConfig.hXLineSagittal   =hXLineSagittal;		%x
	AConfig.hYLineSagittal   =hYLineSagittal;		%y
	AConfig.hXLineCoronal	 =hXLineCoronal;		%x
	AConfig.hYLineCoronal	 =hYLineCoronal;		%y
	AConfig.hXLineTransverse =hXLineTransverse;		%x
	AConfig.hYLineTransverse =hYLineTransverse;		%y
	
	AConfig.Volume =theVolume;	
	AConfig.VoxelSize =reshape(theVoxelSize, [1 3]);
	
	AConfig.Origin =reshape(theOrigin, [1 3]);
    AConfig.Header.Origin=AConfig.Origin;
	if any(AConfig.Origin==[0 0 0]),
		%Auto-Revise the Origin to the half of the size of the brain
		theMsg =sprintf('Illegal origin: (%s)\n\nI presume the origin is (%s)',num2str(AConfig.Origin), num2str(round(size(AConfig.Volume)/2)));
		warning(theMsg);
		warndlg(theMsg);
		AConfig.Origin =round(size(AConfig.Volume)/2);
	end	
	if (norm(theOrigin)==0 || (any(round(theOrigin)~=theOrigin)) || (any(theOrigin<0)))   %YAN Chao-Gan 090401: If the origin of the image was not positive integer, then jump to the image center.
		AConfig.LastPosition =round([nDim1 nDim2 nDim3]/2);		%[x y z] the position in Volume corresponding to the cross-hair position 
	else
		if ~all(AConfig.LastPosition < size(theVolume)),	%If legal
			AConfig.LastPosition =reshape(AConfig.Origin, [1 3]);
		end		
	end
		
	%Auto balance
	AConfig=AutoBalance(AConfig);
	
	Result =AConfig;
	

	
function Result =SeeOverlay(AConfig)
	Result =get(AConfig.hSeeOverlay, 'Value');
	
function Result =GetOverlayImg(AType, AConfig, AUnderlayPosition)
%Return raw overlay image data by computing the real physical distance(mm) from the origin	 % AUnderlayPosition is a scalar, result is a slice according to AType and AUnderlayPosition	
	theVolume =AConfig.Overlay.VolumeThrd;
	switch lower(AType)
	case 'sagittal',
		thePhysicalPosition =(AUnderlayPosition -AConfig.Origin(1)) *AConfig.VoxelSize(1);
		thePhysicalPosition =thePhysicalPosition/AConfig.Overlay.VoxelSize(1) +AConfig.Overlay.Origin(1);
		if thePhysicalPosition>size(theVolume, 1),
			thePhysicalPosition =size(theVolume, 1);
		elseif thePhysicalPosition<1,
			thePhysicalPosition =1;
		end
		%Result =theVolume(round(thePhysicalPosition), :, :);
		Result =squeeze(theVolume(round(thePhysicalPosition), :, :)); 
		%dong 090918
	case 'coronal',		
		thePhysicalPosition =(AUnderlayPosition -AConfig.Origin(2)) *AConfig.VoxelSize(2);
		thePhysicalPosition =thePhysicalPosition/AConfig.Overlay.VoxelSize(2) +AConfig.Overlay.Origin(2);
		if thePhysicalPosition>size(theVolume, 2),
			thePhysicalPosition =size(theVolume, 2);
		elseif thePhysicalPosition<1,
			thePhysicalPosition =1;
		end
		Result =squeeze(theVolume(:, round(thePhysicalPosition), :));
        %Result =theVolume(:, round(thePhysicalPosition), :);
		
	case 'transverse',
		thePhysicalPosition =(AUnderlayPosition -AConfig.Origin(3)) *AConfig.VoxelSize(3);
		thePhysicalPosition =thePhysicalPosition/AConfig.Overlay.VoxelSize(3) +AConfig.Overlay.Origin(3);
		if thePhysicalPosition>size(theVolume, 3),
			thePhysicalPosition =size(theVolume, 3);
		elseif thePhysicalPosition<1,
			thePhysicalPosition =1;
		end
		Result =squeeze(theVolume(:, :, round(thePhysicalPosition)));
       % Result =theVolume(:, :, round(thePhysicalPosition));
	otherwise
	end
	Result =Result';	
	
function Result =Pos_Underlay2Overlay(AConfig, AUnderlayPosition)
% AUnderlayPosition is a 1by3 vector, result is the same
	Result =(AUnderlayPosition -AConfig.Origin) .*AConfig.VoxelSize;
	Result =Result./AConfig.Overlay.VoxelSize +AConfig.Overlay.Origin;
	Result =round(Result);
	
function Result =SetThrdAbsValue(AConfig)	
%By default, I only set the Min absolute value to be the threshold, and renturn the Min, 20070918
    AConfig=CheckDf(AConfig);
	theObject =get(AConfig.hFig, 'CurrentObject');
	if strcmpi(get(theObject, 'Style'), 'edit'), %dong 090921 add p value input
        edtPosition=get(theObject, 'Position');
        if edtPosition(1) ==85 
            Result =str2num(get(AConfig.hEdtThrdValue, 'String'));
            Pvalue=ThrdtoP(Result,AConfig);
        else
            Pvalue =str2num(get(AConfig.hEdtPValue, 'String'));
            Result =PtoThrd(Pvalue,AConfig);
        end
    elseif strcmpi(get(theObject, 'Style'), 'slider'),
		Result =get(AConfig.hSliderThrdValue, 'Value');
        Pvalue=ThrdtoP(Result,AConfig);
	else
		Result =-Inf;
        Pvalue = 1;
		return;
	end	
	
	theMin =get(AConfig.hSliderThrdValue, 'Min');
	theMax =get(AConfig.hSliderThrdValue, 'Max');
	if Result<theMin,
		Result =theMin;
         Pvalue=ThrdtoP(theMin,AConfig);
	elseif Result>theMax,
		Result =theMax;
         Pvalue=1;
    end

	set(AConfig.hSliderThrdValue, 'Value', Result);
	set(AConfig.hEdtThrdValue, 'String', num2str(Result));	
	set(AConfig.hEdtPValue, 'String', num2str(Pvalue)); %dong 090921
    
    
function Result =ThrdOverlayAbsoluteValueAbove(AOverlayImg, AAbsoluteValueMin)
%Threshold for Absolute value above the Min
	Result =AOverlayImg;	
	tmp = abs(AOverlayImg)>=abs(AAbsoluteValueMin);	
	Result(~tmp)=0;
	
function Result =ThrdOverlayAbsoluteValueBelow(AOverlayImg, AAbsoluteValueMax)
%Threshold for Absolute value above the Min
	Result =AOverlayImg;	
	tmp = abs(AOverlayImg)<=abs(AAbsoluteValueMax);	
	Result(~tmp)=0;
function Result =ThrdOverlayValueAbove(AOverlayImg, AValueMin)
%Threshold for Absolute value above the Min
	Result =AOverlayImg;	
	tmp = (AOverlayImg)>=(AValueMin);	
	Result(~tmp)=0;
	
function Result =ThrdOverlayValueBelow(AOverlayImg, AValueMax)
%Threshold for Absolute value above the Min
	Result =AOverlayImg;	
	tmp = (AOverlayImg)<=(AValueMax);	
	Result(~tmp)=0;	
	
function Result =ThrdOverlayValueIn(AOverlayImg, AValueSeries)
%Threshold for a seiry of values
	Result =AOverlayImg;
	tmp =false(size(AOverlayImg));
	for x=1:length(AValueSeries),
		tmp = tmp | ((AOverlayImg)==(AValueSeries(x)) );
	end	
	Result(~tmp)=0;	
	
	
	
	
function Result =ThrdOverlayCluster(AConfig, AVolume)	
%Threshold for Cluster Size or calculated cluster size from cluster-Raidus %This function must be called after thresholding the Value already!		
	%"AConfig.Overlay.VolumeThrd" must be thresholded before this function is called!
	Result =AVolume;
	%Raidus has Priority
	if AConfig.Overlay.ClusterRadiusThrd~=0, %Raidus(mm) 
		%Calcute the cluster size according to the Raidus(mm) 
		AConfig.Overlay.Header.Origin=AConfig.Overlay.Origin; %%Yan 080610
        maskROI =rest_SphereROI( 'BallDefinition2Mask' , sprintf('ROI Center(mm)=(0, 0, 0); Radius=%g mm.', AConfig.Overlay.ClusterRadiusThrd), size(AConfig.Overlay.Volume), AConfig.Overlay.VoxelSize, AConfig.Overlay.Header);  %%Yan 080610 and 081223
		AConfig.Overlay.ClusterSizeThrd =length(find(maskROI));
		AConfig.Overlay.ClusterRadiusThrd =0;
	end
	if AConfig.Overlay.ClusterSizeThrd==0, return; end
	[theObjMask, theObjNum]=bwlabeln(Result,AConfig.Overlay.ClusterConnectivityCriterion); %DONG Zhang-Ye and YAN Chao-Gan 090711, make the Cluster Connectivity Criterion flexible.	%[theObjMask, theObjNum]=bwlabeln(Result);
	for x=1:theObjNum,
		theCurrentCluster = theObjMask==x;
		if length(find(theCurrentCluster))<AConfig.Overlay.ClusterSizeThrd,
			Result(logical(theCurrentCluster))=0;			%YAN Chao-Gan 081223, Original "Result(~logical(theCurrentCluster))=0;" was an error			
		end
	end	
	
	
function Result =ThresholdOverlayVolume(AConfig)
	AConfig.Overlay.VolumeThrd =AConfig.Overlay.Volume;
	%First, thresholding by a range set by Min,Max
	if ~isinf(AConfig.Overlay.ValueThrdMin),
		AConfig.Overlay.VolumeThrd =ThrdOverlayValueAbove(AConfig.Overlay.VolumeThrd, AConfig.Overlay.ValueThrdMin);		
	end
	if ~isinf(AConfig.Overlay.ValueThrdMax),
		AConfig.Overlay.VolumeThrd =ThrdOverlayValueBelow(AConfig.Overlay.VolumeThrd, AConfig.Overlay.ValueThrdMax);		
	end
	
	%Absolute value thresholding without priority!
	%Threshold the Overlay	by the Value or Range or Series
	if AConfig.Overlay.ValueThrdAbsolute>0,
		AConfig.Overlay.VolumeThrd =ThrdOverlayAbsoluteValueAbove(AConfig.Overlay.VolumeThrd, AConfig.Overlay.ValueThrdAbsolute);	
	end
		
	if ~isnan(AConfig.Overlay.ValueThrdSeries), 
		AConfig.Overlay.VolumeThrd =ThrdOverlayValueIn(AConfig.Overlay.VolumeThrd, AConfig.Overlay.ValueThrdSeries);
	end	
	AConfig.Overlay.VolumeThrd =ThrdOverlayCluster(AConfig, AConfig.Overlay.VolumeThrd);	
    Result =AConfig;
	
function Result =ScaleOverlay2TrueColor(AConfig, AOverlayImg, AColorMap)
	[pathstr, name, ext] = fileparts(AConfig.Overlay.Filename);
	if strcmpi(name,'aal') ||  strcmpi(name,'brodmann'),
		Result =ScaleTemplate2TrueColor(AConfig, AOverlayImg);
    else
        VolumeMax=max(AConfig.Overlay.VolumeThrd(:));%090919 dong ,revise the max and min color
        VolumeMin=min(AConfig.Overlay.VolumeThrd(:));
		Result =Overlay2TrueColor(AOverlayImg, AColorMap,VolumeMax,VolumeMin,AConfig.Overlay.ValueThrdAbsolute); %dong 091128
    end
    DrawColorbar(AConfig);
    
function Result =Overlay2TrueColor(AOverlayImg, AColorMap,VolumeMax,VolumeMin,ValueThrdAbsolute)	%090919 dong ,revise the max color
	Result =AOverlayImg;
	nColorLen =size(AColorMap, 1);
	%Attention:
	%Keep zero as zero always! 20070915
	
	%Mapping the Negative values	
	ResultNegative =Result;
	ResultNegative(Result>0) =0;
	
	theNonZeroPos =find(ResultNegative~=0);
	theMax =-ValueThrdAbsolute;
	%YAN Chao-Gan and DONG Zhang-Ye, 090717 %theMax =max(ResultNegative(theNonZeroPos));
	theMin =VolumeMin;%min(ResultNegative(theNonZeroPos));
	if theMax>theMin,
		ResultNegative(theNonZeroPos) = (ResultNegative(theNonZeroPos)-theMin)/(theMax - theMin) *(nColorLen/2) +1;	%YAN Chao-Gan 091201. %ResultNegative(theNonZeroPos) = (ResultNegative(theNonZeroPos)-theMin)/(theMax - theMin) *(nColorLen/2-1) +1;%Add one to make sure theMin be mapped not zero(i.e. to 1) and could be mapped to the first element in colormap 
		ResultNegative =overlay_ind2rgb(floor(ResultNegative), AColorMap(1:nColorLen/2, :));
	else
		if theMax~=0,
			ResultNegative(theNonZeroPos) =1;
			ResultNegative =overlay_ind2rgb(floor(ResultNegative), AColorMap(1, :));
		else
			ResultNegative =zeros([size(Result), 3]);
		end
	end
	
	%Mapping the Positive values	
	ResultPositive =Result;
	ResultPositive(Result<0) =0;
	
	theNonZeroPos =find(ResultPositive~=0);
	theMax =VolumeMax;
	theMin =ValueThrdAbsolute;	
	if theMax>theMin,		
		ResultPositive(theNonZeroPos) = (ResultPositive(theNonZeroPos)-theMin)/(theMax - theMin) *(nColorLen/2) +1; %YAN Chao-Gan 091201. %ResultPositive(theNonZeroPos) = (ResultPositive(theNonZeroPos)-theMin)/(theMax - theMin) *(nColorLen/2-1) +1;
		ResultPositive =overlay_ind2rgb(floor(ResultPositive), AColorMap(nColorLen/2+1:end, :)); %YAN Chao-Gan 091201 %ceil
	else
		if theMax~=0,
			ResultPositive(theNonZeroPos) =1;
			ResultPositive =overlay_ind2rgb(floor(ResultPositive), AColorMap(end, :));
		else
			ResultPositive =zeros([size(Result), 3]);
		end		 
	end
	
	Result =ResultNegative +ResultPositive;
	
function Result =ScaleTemplate2TrueColor(AConfig, AOverlayImg)	
%Such as AAL, BRODMANN ...	
	Result =AOverlayImg;
	[pathstr, name, ext] = fileparts(AConfig.Overlay.Filename);
	if strcmpi(name, 'aal'),		
		AColorMap =rest_ReadLutColorScheme(fullfile(rest_misc( 'WhereIsREST'),'Template', 'aal.nii.lut'));	%YAN Chao-Gan 081223: use the NIFTI image information from the MRIcroN	 
		theBlackPos=sum(AColorMap, 2)==0;
		AColorMap(theBlackPos, :) =1; %Black to White for I use black always as the background
		Result =overlay_ind2rgb(1+floor(Result), AColorMap);%Overpass the first color which may be backgound color
	elseif strcmpi(name, 'brodmann'),		
		AColorMap =rest_ReadLutColorScheme(fullfile(rest_misc( 'WhereIsREST'),'Template', 'brodmann.nii.lut'));		%YAN Chao-Gan 081223: use the NIFTI image information from the MRIcroN	  
		theBlackPos=sum(AColorMap, 2)==0;
		AColorMap(theBlackPos, :) =1; %Black to White for I use black always as the background
		Result =overlay_ind2rgb(1+floor(Result), AColorMap);%Overpass the first color which may be backgound color	
	end
	
	
function Result =AddOverlay(AType, AConfig, ATrueColorUnderlay,theMagnifyCoefficient)	
    
	switch lower(AType)
	case 'sagittal',
		AUnderlayPosition =AConfig.LastPosition(1);
	case 'coronal',		
		AUnderlayPosition =AConfig.LastPosition(2);
	case 'transverse',
		AUnderlayPosition =AConfig.LastPosition(3);
	otherwise
	end
	
	Result =ATrueColorUnderlay;
	if isempty(AConfig.Overlay.Filename),		
		return;
	else	%Add Overlay Image			
		theOverlay =GetOverlayImg(AType, AConfig, AUnderlayPosition);
		%100325 dong begin
		Xvol=AConfig.Overlay.VoxelSize(1);
        Yvol=AConfig.Overlay.VoxelSize(2);
        Zvol=AConfig.Overlay.VoxelSize(3);
        %100325 dong end
		%Resize image to the same size with the Anatomical image
		if license('test','image_toolbox')==1,
            if rest_misc('GetMatlabVersion')>=7.4   %YAN Chao-Gan 090401: The imresize function has been completely rewritten in Matlab R2007a. Fixed the bug of 'Set Overlay's Color bar' in Matlab R2007a or latter version.
                 switch lower(AType)
                    case 'sagittal',
                        theOverlay =imresize_old(theOverlay, floor([(size(theOverlay, 1)-1)*Xvol+1, (size(theOverlay, 2)-1)*Xvol+1]*theMagnifyCoefficient));
                    case 'coronal',
                        theOverlay =imresize_old(theOverlay, floor([(size(theOverlay, 1)-1)*Yvol+1, (size(theOverlay, 2)-1)*Yvol+1]*theMagnifyCoefficient));
                    case 'transverse',
                        theOverlay =imresize_old(theOverlay, floor([(size(theOverlay, 1)-1)*Zvol+1, (size(theOverlay, 2)-1)*Zvol+1]*theMagnifyCoefficient));
                    otherwise
                end
            else
                switch lower(AType)
                    case 'sagittal',
                        theOverlay =imresize(theOverlay, floor([(size(theOverlay, 1)-1)*Xvol+1, (size(theOverlay, 2)-1)*Xvol+1]*theMagnifyCoefficient));
                    case 'coronal',
                        theOverlay =imresize(theOverlay, floor([(size(theOverlay, 1)-1)*Yvol+1, (size(theOverlay, 2)-1)*Yvol+1]*theMagnifyCoefficient));
                    case 'transverse',
                        theOverlay =imresize(theOverlay, floor([(size(theOverlay, 1)-1)*Zvol+1, (size(theOverlay, 2)-1)*Zvol+1]*theMagnifyCoefficient));
                    otherwise
                end
            end
		else,
			error('You must install image_toolbox first!');
        end
        %100325 dong begin
        newOverlay=zeros(size(ATrueColorUnderlay,1),size(ATrueColorUnderlay,2));
        Xset=AConfig.Origin(1)-(AConfig.Overlay.Origin(1)-1)*Xvol;
        Yset=AConfig.Origin(2)-(AConfig.Overlay.Origin(2)-1)*Yvol; 
        Zset=AConfig.Origin(3)-(AConfig.Overlay.Origin(3)-1)*Zvol;
        switch lower(AType)
            case 'sagittal',
                setFlag=0;%100421 dong changed setFlag
                while setFlag == 0
                    D1st = min(size(newOverlay,1),size(theOverlay,1))+abs(floor(Zset*theMagnifyCoefficient));
                    D2nd = min(size(newOverlay,2),size(theOverlay,2))+abs(floor(Yset*theMagnifyCoefficient));
                    setFlag=1;
                    if D1st>size(ATrueColorUnderlay,1)
                        Zset=Zset-1;
                        setFlag=0;
                    end
                    if D2nd>size(ATrueColorUnderlay,2)
                        Yset=Yset-1;
                        setFlag=0;
                    end
                end
            case 'coronal',
                setFlag=0;
                while setFlag == 0
                    D1st = min(size(newOverlay,1),size(theOverlay,1))+abs(floor(Zset*theMagnifyCoefficient));
                    D2nd = min(size(newOverlay,2),size(theOverlay,2))+abs(floor(Xset*theMagnifyCoefficient));
                    setFlag=1;
                    if  D1st>size(ATrueColorUnderlay,1)
                        Zset=Zset-1;
                        setFlag=0;
                    end
                    if D2nd>size(ATrueColorUnderlay,2)
                        Xset=Xset-1;
                        setFlag=0;
                    end
                end
            case 'transverse',
                setFlag=0;
                while setFlag == 0
                    D1st = min(size(newOverlay,1),size(theOverlay,1))+abs(floor(Yset*theMagnifyCoefficient));
                    D2nd = min(size(newOverlay,2),size(theOverlay,2))+abs(floor(Xset*theMagnifyCoefficient));
                    setFlag=1;
                    if  D1st>size(ATrueColorUnderlay,1)
                        Yset=Yset-1;
                        setFlag=0;
                    end
                    if D2nd>size(ATrueColorUnderlay,2)
                        Xset=Xset-1;
                        setFlag=0;
                    end
                end
            otherwise
        end
         switch lower(AType)
            case 'sagittal',
                for i=1:min(size(newOverlay,1),size(theOverlay,1))
                    for j=1:min(size(newOverlay,2),size(theOverlay,2))
                        if Zset>=0&&Yset>=0
                            newOverlay(i+floor(Zset*theMagnifyCoefficient),j+floor(Yset*theMagnifyCoefficient))=theOverlay(i,j);
                        else
                            newOverlay(i,j)=theOverlay(i+abs(floor(Zset*theMagnifyCoefficient)),j+abs(floor(Yset*theMagnifyCoefficient)));
                        end
                    end
                end
            case 'coronal',
                for i=1:min(size(newOverlay,1),size(theOverlay,1))
                    for j=1:min(size(newOverlay,2),size(theOverlay,2))
                        if Zset>=0&&Xset>=0
                            newOverlay(i+floor(Zset*theMagnifyCoefficient),j+floor(Xset*theMagnifyCoefficient))=theOverlay(i,j);
                        else
                            newOverlay(i,j)=theOverlay(i+abs(floor(Zset*theMagnifyCoefficient)),j+abs(floor(Xset*theMagnifyCoefficient)));
                        end
                    end
                end
            case 'transverse',
                for i=1:min(size(newOverlay,1),size(theOverlay,1))
                    for j=1:min(size(newOverlay,2),size(theOverlay,2))
                        if Yset>=0&&Xset>=0
                            newOverlay(i+floor(Yset*theMagnifyCoefficient),j+floor(Xset*theMagnifyCoefficient))=theOverlay(i,j);
                        else
                            newOverlay(i,j)=theOverlay(i+abs(floor(Yset*theMagnifyCoefficient)),j+abs(floor(Xset*theMagnifyCoefficient)));
                        end
                    end
                end
            otherwise
        end
        nonZeroPos =newOverlay~=0;
        newOverlay =ScaleOverlay2TrueColor(AConfig, newOverlay, AConfig.Overlay.Colormap);
        Result =AddRGBInMask(newOverlay, ATrueColorUnderlay,nonZeroPos,AConfig.Overlay.Opacity);
        %100325 dong end
        SetMessage(AConfig);
		%Result =theOverlay *AConfig.Overlay.Opacity + ATrueColorUnderlay*(1-AConfig.Overlay.Opacity);
	end

function Result =AddOverlaySeries(AConfig, ATrueColorUnderlay,theMagnifyCoefficient)
	%Get the Magnified Brain Size
	%Make sure there will be no any fractional value   if GetMagnifyCoefficient(AConfig)<1
	theSize= floor(GetMagnifyCoefficient(AConfig) * (size(AConfig.Volume)));
	nDim1=theSize(1); nDim2=theSize(2); nDim3=theSize(3);
	Result =ATrueColorUnderlay;	
	if isempty(AConfig.Overlay.Filename),
		return;
	else	%Add Overlay Image
    %100325 dong begin
        Xvol=AConfig.Overlay.VoxelSize(1);
        Yvol=AConfig.Overlay.VoxelSize(2);
        Zvol=AConfig.Overlay.VoxelSize(3);
        %100325 dong end
		for theRow=AConfig.Montage.Down:-1:1,
			for theCol=1:AConfig.Montage.Across,
				%Retrieve the underlay
				switch lower(AConfig.ViewMode)
				case 'sagittal',
					theUnderlay =Result((theRow-1)*nDim3 +(1:nDim3), (theCol-1)*nDim2+(1:nDim2), :);
				case 'coronal',		
					theUnderlay =Result((theRow-1)*nDim3 +(1:nDim3), (theCol-1)*nDim1+(1:nDim1), :);
				case 'transverse',
					theUnderlay =Result((theRow-1)*nDim2 +(1:nDim2), (theCol-1)*nDim1+(1:nDim1), :);
				otherwise
				end
				%Get the overlay
				theIndex = AConfig.ViewSeries((AConfig.Montage.Down-theRow)*AConfig.Montage.Across +theCol);
                %YAN Chao-Gan 081229 theIndex = AConfig.ViewSeries((theRow-1)*AConfig.Montage.Across +theCol);
				theOverlay =GetOverlayImg(AConfig.ViewMode, AConfig, theIndex);
								
				if license('test','image_toolbox')==1,
                    if rest_misc('GetMatlabVersion')>=7.4   %YAN Chao-Gan 090401: The imresize function has been completely rewritten in Matlab R2007a. Fixed the bug of 'Set Overlay's Color bar' in Matlab R2007a or latter version.
                         switch lower(AConfig.ViewMode)
                            case 'sagittal',
                                theOverlay =imresize_old(theOverlay, floor([(size(theOverlay, 1)-1)*Xvol+1, (size(theOverlay, 2)-1)*Xvol+1]*theMagnifyCoefficient));
                            case 'coronal',
                                theOverlay =imresize_old(theOverlay, floor([(size(theOverlay, 1)-1)*Yvol+1, (size(theOverlay, 2)-1)*Yvol+1]*theMagnifyCoefficient));
                            case 'transverse',
                                theOverlay =imresize_old(theOverlay, floor([(size(theOverlay, 1)-1)*Zvol+1, (size(theOverlay, 2)-1)*Zvol+1]*theMagnifyCoefficient));
                            otherwise
                        end
                    else
                        switch lower(AConfig.ViewMode)
                            case 'sagittal',
                                theOverlay =imresize(theOverlay, floor([(size(theOverlay, 1)-1)*Xvol+1, (size(theOverlay, 2)-1)*Xvol+1]*theMagnifyCoefficient));
                            case 'coronal',
                                theOverlay =imresize(theOverlay, floor([(size(theOverlay, 1)-1)*Yvol+1, (size(theOverlay, 2)-1)*Yvol+1]*theMagnifyCoefficient));
                            case 'transverse',
                                theOverlay =imresize(theOverlay, floor([(size(theOverlay, 1)-1)*Zvol+1, (size(theOverlay, 2)-1)*Zvol+1]*theMagnifyCoefficient));
                            otherwise
                        end
                    end%100325 dong end
				else
					error('You must install image_toolbox first!');
				end
				 %100325 dong begin
                newOverlay=zeros(size(theUnderlay,1),size(theUnderlay,2));
                Xset=AConfig.Origin(1)-(AConfig.Overlay.Origin(1)-1)*Xvol;
                if Xset ==1
                    Xset=0;
                end
                if Xset ==13
                    Xset=12;
                end
                Yset=AConfig.Origin(2)-(AConfig.Overlay.Origin(2)-1)*Yvol;
                if Yset ==1
                    Yset=0;
                end
                if Yset ==14
                    Yset=13;
                end
                Zset=AConfig.Origin(3)-(AConfig.Overlay.Origin(3)-1)*Zvol;
                if Zset ==1
                    Zset=0;
                end
                if Yset ==22
                    Yset=21;
                end
                switch lower(AConfig.ViewMode)
                    case 'sagittal',
                        for i=1:min(size(newOverlay,1),size(theOverlay,1))
                            for j=1:min(size(newOverlay,2),size(theOverlay,2))
                                if Zset>=0&&Yset>=0
                                    newOverlay(i+floor(Zset*theMagnifyCoefficient),j+floor(Yset*theMagnifyCoefficient))=theOverlay(i,j);
                                else
                                    newOverlay(i,j)=theOverlay(i+abs(floor(Zset*theMagnifyCoefficient)),j+abs(floor(Yset*theMagnifyCoefficient)));
                                end
                            end
                        end
                    case 'coronal',
                        for i=1:min(size(newOverlay,1),size(theOverlay,1))
                            for j=1:min(size(newOverlay,2),size(theOverlay,2))
                                if Zset>=0&&Xset>=0
                                    newOverlay(i+floor(Zset*theMagnifyCoefficient),j+floor(Xset*theMagnifyCoefficient))=theOverlay(i,j);
                                else
                                    newOverlay(i,j)=theOverlay(i+abs(floor(Zset*theMagnifyCoefficient)),j+abs(floor(Xset*theMagnifyCoefficient)));
                                end
                            end
                        end
                    case 'transverse',
                        for i=1:min(size(newOverlay,1),size(theOverlay,1))
                            for j=1:min(size(newOverlay,2),size(theOverlay,2))
                                if Yset>=0&&Xset>=0
                                    newOverlay(i+floor(Yset*theMagnifyCoefficient),j+floor(Xset*theMagnifyCoefficient))=theOverlay(i,j);
                                else
                                    newOverlay(i,j)=theOverlay(i+abs(floor(Yset*theMagnifyCoefficient)),j+abs(floor(Xset*theMagnifyCoefficient)));
                                end
                            end
                        end
                    otherwise
                end
                nonZeroPos =newOverlay~=0;
                newOverlay =ScaleOverlay2TrueColor(AConfig, newOverlay, AConfig.Overlay.Colormap);
                %         nonZeroPos = theOverlay~=0;
                %         theOverlay =ScaleOverlay2TrueColor(AConfig, theOverlay, AConfig.Overlay.Colormap);
           
				%Add r g b colors with mask
                theUnderlay =AddRGBInMask(newOverlay, theUnderlay, nonZeroPos, AConfig.Overlay.Opacity);
				%theUnderlay =AddRGBInMask(theOverlay, theUnderlay, nonZeroPos, AConfig.Overlay.Opacity);
                %100325 dong end
				
				%Save underlay to big series' map
				switch lower(AConfig.ViewMode)
				case 'sagittal',
					Result((theRow-1)*nDim3 +(1:nDim3), (theCol-1)*nDim2+(1:nDim2), :) =theUnderlay;
				case 'coronal',		
					Result((theRow-1)*nDim3 +(1:nDim3), (theCol-1)*nDim1+(1:nDim1), :) =theUnderlay;
				case 'transverse',
					Result((theRow-1)*nDim2 +(1:nDim2), (theCol-1)*nDim1+(1:nDim1), :) =theUnderlay;
				otherwise
				end
			end %end for-loop theCol
		end	%end for-loop theRow	
	end	%end if
	
function Result =LoadOverlay(AConfig, AFilename)
    AConfig.Df.Ttest=0;
    AConfig.Df.Ftest=[0,0];
    AConfig.Df.Ztest=0;
    AConfig.Df.Rtest=0;
	Result =AConfig;
	try
		[theVolume,theVoxelSize, Header] =rest_readfile(AFilename); %%Yan 080610
        theOrigin=Header.Origin; %%Yan 080610
		Result =AddRecentOverlay(AConfig, AFilename);
	catch
		if ~(exist(AFilename, 'file')==2) ...			
			&& ( ~all(isspace(AFilename)) && ~isempty(isspace(AFilename))),
			warning(sprintf('Please check whether Img/Hdr file "%s" exist!', AConfig.Filename));
			warndlg(sprintf('Please check whether Img/Hdr file "%s" exist!', AConfig.Filename));
		end
		
		theVolume	 =zeros(61, 73, 61); theVolume(33,33,33)=0.1;
		theVoxelSize=[3 3 3];
		theOrigin	 =[31 43 25];
	end
	Result.Overlay.Filename =AFilename;
	Result.Overlay.Volume =theVolume;
	Result.Overlay.VolumeThrd =theVolume;%Volume Thresholded as cache
	Result.Overlay.VoxelSize =reshape(theVoxelSize, [1 3]);
	Result.Overlay.Origin =reshape(theOrigin, [1 3]);
    Result.Overlay.Header=Header; %%Yan 080610
	if any(Result.Overlay.Origin==[0 0 0]),
		%Auto-Revise the Origin to the half of the size of the brain
		theMsg =sprintf('Illegal origin: (%s)\n\nI presume the origin is (%s)',num2str(Result.Overlay.Origin), num2str(round(size(Result.Overlay.Volume)/2)));
		warning(theMsg);
		warndlg(theMsg);		
		Result.Overlay.Origin =round(size(Result.Overlay.Volume)/2);
	end
	
	%Calcute the min and max both in positive & negative field
	tmpVolume =theVolume(find(theVolume));
	theMinNegative = min(tmpVolume(tmpVolume<0));
	theMaxNegative = max(tmpVolume(tmpVolume<0));
	theMinPositive = min(tmpVolume(tmpVolume>0));
	theMaxPositive = max(tmpVolume(tmpVolume>0));
	clear tmpVolume;	
	if isempty(theMinNegative), theMinNegative =0; end	%Just For always zero map
	if isempty(theMaxNegative), theMaxNegative =0; end  %Just For always zero map
	if isempty(theMinPositive), theMinPositive =0; end	%Just For always zero map
	if isempty(theMaxPositive), theMaxPositive =0; end  %Just For always zero map
	
	theAbsMax =max(abs([theMinNegative, theMaxPositive]));
	theAbsMin =min(abs([theMaxNegative, theMinPositive]));
	% theAbsVolume =abs(theVolume);
	% theAbsMax =max(theAbsVolume(find(theAbsVolume)));
	% theAbsMin =min(theAbsVolume(find(theAbsVolume)));
	% clear theAbsVolume;
	if theAbsMax<=theAbsMin, theAbsMax =theAbsMin+1; end
	set(AConfig.hSliderThrdValue, 'Max',theAbsMax,'Min',theAbsMin, 'Value',theAbsMin, 'SliderStep',[0.01, 0.05]);
	
	
	Result.Overlay.MinNegative =theMinNegative;%-10
	Result.Overlay.MaxNegative =theMaxNegative;%-1
	Result.Overlay.MinPositive =theMinPositive;			%1
	Result.Overlay.MaxPositive =theMaxPositive;			%10
	Result.Overlay.AbsMin =theAbsMin;
	Result.Overlay.AbsMax =theAbsMax;
		
	Result.Overlay.ValueThrdAbsolute =theAbsMin; %Default, show all
	Result.Overlay.ValueThrdMin =theMinNegative; %Default, show all
	Result.Overlay.ValueThrdMax =theMaxPositive; %Default, show all
	Result.Overlay.ClusterThrd =0; %Default, don't confine cluster size
	Result.Overlay.ClusterRadius =0; %Default radius(mm) for Cluster size definition
	
    
  
	[pathstr, name, ext] = fileparts(Result.Overlay.Filename);
	if strcmpi(name, 'aal'),		
		theInfoTxt =fullfile(rest_misc( 'WhereIsREST'),'Template', 'aal.nii.txt'); %YAN Chao-Gan 081223: use the NIFTI image information from the MRIcroN	 
		[x,Result.Overlay.InfoAal,y] =textread(theInfoTxt,'%d %s %d');
	else
		Result.Overlay.InfoAal='None';
	end
	
	
function [rout,g,b] = overlay_ind2rgb(a,cm)
	theImage =a;
	% Make sure A is in the range from 0 to size(cm,1)
	theImage = max(0,min(theImage,size(cm,1)));
	%Exclude any zero values, following is the Revision 
	theColormap =[[-1 -1 -1]; cm];
	theImage =theImage+1;%Make any zero to one
	
	% Extract r,g,b components
	r = zeros(size(theImage)); r(:) = theColormap(theImage,1);
	g = zeros(size(theImage)); g(:) = theColormap(theImage,2);
	b = zeros(size(theImage)); b(:) = theColormap(theImage,3);

	if nargout==3,
	  rout = r;
	else
	  rout = zeros([size(r),3]);
	  rout(:,:,1) = r;
	  rout(:,:,2) = g;
	  rout(:,:,3) = b;
	end
	%Revision finally
	rout(rout==-1) =0;
	
function Result =GetDefaultColormap()
	theNegative =winter(128);
	thePositive =hot(128);
	thePositive =thePositive(128:-1:1, :);
	Result =[theNegative; thePositive];
	
function Result =AddRGBInMask(AMapO, AMapU, AMask, AOpacityX)
	if ~isequal(size(AMapO),size(AMapU)),	
		error('Non-same size are the two true-color maps');
	end	
	if AOpacityX<0 || AOpacityX>1,	
		error('Non legal AOpacity value');
	end	
	AMask = AMask~=0;
			
	rx =AMapO(:, :, 1);
	ry =AMapU(:, :, 1);
	r  =zeros(size(rx));
	r(AMask) =rx(AMask)*AOpacityX +ry(AMask)*(1-AOpacityX);
	r(~AMask)=ry(~AMask);
	
	gx =AMapO(:, :, 2);
	gy =AMapU(:, :, 2);
	g  =zeros(size(rx));
	g(AMask) =gx(AMask)*AOpacityX +gy(AMask)*(1-AOpacityX);
	g(~AMask)=gy(~AMask);
	
	bx =AMapO(:, :, 3);
	by =AMapU(:, :, 3);
	b  =zeros(size(rx));
	b(AMask) =bx(AMask)*AOpacityX +by(AMask)*(1-AOpacityX);
	b(~AMask)=by(~AMask);
	
	Result= zeros(size(AMapO));
	Result(:, :, 1)=r;
	Result(:, :, 2)=g;
	Result(:, :, 3)=b;
	
function Result =Overlay_Misc(AConfig)	
	isNeedUpdate =false;
	% if SeeOverlay(AConfig),
		switch get(AConfig.hOverlayMisc, 'Value'),
		case 1,	%Overlay Misc
			%Do nothing
		case 2, %'Set Overlay Opacity'	
			prompt ={'Overlay''s Opacity: (1=opaque, 0=transparent and restricted in [0, 1])'};
			def	={	num2str(AConfig.Overlay.Opacity) };
			answer =inputdlg(prompt, 'Overlay Opacity', 1, def);
			if numel(answer)==1,
				theVal =abs(str2num(answer{1}));
				if theVal>1, theVal=1; end
				AConfig.Overlay.Opacity = theVal;			
			end
		case 3, %Set Range of Threshold
			prompt ={'Threshold Value''s Range: Min, Max( Default=-Inf,Inf.)', sprintf('\nSet Threshold Value''s Series, such as 25,1,7,31 for only showing Brodmann''s area BA25, BA1, BA7, BA31 when overlay is BA template. This also works for AAL template. This supports MATLAB array defination syntax. NaN means not confined in any series.')};
			def	={sprintf('%d, %d',AConfig.Overlay.ValueThrdMin,AConfig.Overlay.ValueThrdMax) ,...
				  num2str(AConfig.Overlay.ValueThrdSeries)};
			answer =inputdlg(prompt, 'Set a range for thresholding', 2, def);
			if numel(answer)==2,
				theVal =(str2num(answer{1}));
				if length(theVal)==2, 
					if theVal(1)>theVal(2), theVal=theVal([2,1]); end
					
					if theVal(1)<AConfig.Overlay.MinNegative, 
						theVal(1) =AConfig.Overlay.MinNegative;
					end
					if theVal(2)>AConfig.Overlay.MaxPositive, 
						theVal(2) =AConfig.Overlay.MaxPositive;
					end
					
					AConfig.Overlay.ValueThrdMin =theVal(1);
					AConfig.Overlay.ValueThrdMax =theVal(2);
				end
				theVal =(str2num(answer{2}));
				if ~isempty(theVal), 
					AConfig.Overlay.ValueThrdSeries =theVal;
				else
					AConfig.Overlay.ValueThrdSeries =NaN;
				end
				AConfig =ThresholdOverlayVolume(AConfig);
			end
		case 4, %Set AConfig.Overlay.LabelColor
			theColor =uisetcolor;
			if numel(theColor)==1 && theColor==0,	
				%User canceled the color selection
			else
				AConfig.Overlay.LabelColor =theColor;
			end
		case 5, %Set Color map parameters			
			prompt ={sprintf('Overlay''s Color command: ( i.e. about how to generate the color map for overlay.)\n\n1. You can input 2 or 4 or 6...16 or 18 or 20... and so on. This way would generate a N-elements colorbar similar as AFNI''s colorbar.\n2. "jet(64)" or other MATLAB command(such as "Winter(20)" and so on) would generate a smooth colorbar.\n3. ** means using default colormap that''s generated by command jet(64).)')};
			def	={	AConfig.Overlay.ColorbarCmd };
			answer =inputdlg(prompt, 'Set color bar definition', 1, def);
			if numel(answer)==1,				
				AConfig =DefineColorMap(AConfig, answer{1});				
            end
        case 6, %Save Image 
			%YAN Chao-Gan 081223: add "save image as" function
            [filename, pathname] = uiputfile({'*.tiff';'*.jpeg';'*.png';'*.bmp'}, 'Save Image As');
            if filename~=0,%dong 090919
                [tempPath, fileN, extn] = fileparts(filename);
                while isempty(strmatch(extn, strvcat('.tiff', '.jpeg', '.png','.bmp'),'exact'))
                    [filename, pathname] = uiputfile({'*.tiff';'*.jpeg';'*.png';'*.bmp'}, 'Save Image As');
                    [tempPath, fileN, extn] = fileparts(filename);
                end
                theFilename =fullfile(pathname,filename);
             set(gcf,'PaperPositionMode','auto')
                eval(['print -r600 -dtiff -noui ''',theFilename,''';']);
           end
        case 7, %Correction Thresholds by AlphaSim
            %YAN Chao-Gan 090401: add "Correction Thresholds by AlphaSim"
%             msgbox({'The Correction Thresholds correspond to a corrected P < 0.05 determined by the Monte Carlo simulations with the program AlphaSim in AFNI.';...
%                 '';...
%                 'Mask File: BrainMask_05_61x73x61.img (70831 voxels, under /mask directory)';...
%                 '';...
%                 'Gaussian kernel of spatially smooth: 4mm';...
%                 '    p on individual voxel    Cluster size (voxels)';...
%                 '             0.05                            54';...
%                 '             0.01                            16';...
%                 '            0.005                           11';...
%                 '            0.001                            6';...
%                 '';...
%                 'Gaussian kernel of spatially smooth: 6mm';...
%                 '    p on individual voxel    Cluster size (voxels)';...
%                 '             0.05                           165';...
%                 '             0.01                            39';...
%                 '            0.005                           27';...
%                 '            0.001                           13';...
%                 '';...
%                 'Gaussian kernel of spatially smooth: 8mm';...
%                 '    p on individual voxel    Cluster size (voxels)';...
%                 '             0.05                           324';...
%                 '             0.01                            71';...
%                 '            0.005                           48';...
%                 '            0.001                           22';...
%                 '';...
%                 'Gaussian kernel of spatially smooth: 10mm';...
%                 '    p on individual voxel    Cluster size (voxels)';...
%                 '             0.05                           524';...
%                 '             0.01                           119';...
%                 '            0.005                           78';...
%                 '            0.001                           34';...
%                 },'Correction Thresholds by AlphaSim');
            rest_CorrectionThresholdsByAlphaSim;     %Revised by YAN Chao-Gan 091108: add situation in rmm=5 and rmm=6
        case 8 % DONG FDR 100118
            [AConfig.Overlay.Qvalue,AConfig.Overlay.Qmaskname,AConfig.Overlay.Conproc,AConfig.Overlay.Tchoose]=rest_FDR_gui(AConfig.Overlay.Qvalue,AConfig.Overlay.Qmaskname,AConfig.Overlay.Conproc,AConfig.Overlay.Tchoose);

            if AConfig.Overlay.Tchoose == 2 % Two-tailed % YAN Chao-Gan, 100201
                if AConfig.Df.Ttest~=0 ,
                    ValueP=2*(1-tcdf(abs(AConfig.Overlay.Volume),AConfig.Df.Ttest)); %DONG AConfig.Overlay.Volume can change to AConfig.Overlay.VolumeThrd, if needed 100118
                elseif numel(find(AConfig.Df.Ftest))~=0 ,
                    ValueP =2*(1-fcdf(abs(AConfig.Overlay.Volume),AConfig.Df.Ftest(1),AConfig.Df.Ftest(2)));
                elseif AConfig.Df.Ztest~=0 ,
                    ValueP=2*(1-normcdf(abs(AConfig.Overlay.Volume)));
                elseif AConfig.Df.Rtest ~= 0 ,
                    ValueP=2*(1-tcdf(abs(AConfig.Overlay.Volume).*sqrt((AConfig.Df.Rtest)./(1-AConfig.Overlay.Volume.*AConfig.Overlay.Volume)),AConfig.Df.Rtest));
                else
                    msgbox('FDR only take effects on the statistical map!');
                    Result =AConfig;
                    return;
                end
            else % One-Tailed
                if AConfig.Df.Ttest~=0 ,
                    ValueP=(1-tcdf(AConfig.Overlay.Volume,AConfig.Df.Ttest)); %DONG AConfig.Overlay.Volume can change to AConfig.Overlay.VolumeThrd, if needed 100118
                elseif numel(find(AConfig.Df.Ftest))~=0 ,
                    ValueP =(1-fcdf(AConfig.Overlay.Volume,AConfig.Df.Ftest(1),AConfig.Df.Ftest(2)));
                elseif AConfig.Df.Ztest~=0 ,
                    ValueP=(1-normcdf(AConfig.Overlay.Volume));
                elseif AConfig.Df.Rtest ~= 0,
                    ValueP=(1-tcdf(AConfig.Overlay.Volume.*sqrt((AConfig.Df.Rtest)./(1-AConfig.Overlay.Volume.*AConfig.Overlay.Volume)),AConfig.Df.Rtest));
                else
                    msgbox('FDR only take effects on the statistical map!');
                    Result =AConfig;
                    return;
                end
            end

            if ~isempty(AConfig.Overlay.Qmaskname)
                [MaskData MaskVox MaskHead]=rest_readfile(AConfig.Overlay.Qmaskname);
                [pID,pN] = rest_FDR(ValueP(find(MaskData)),AConfig.Overlay.Qvalue);
            else
                [pID,pN] = rest_FDR(ValueP,AConfig.Overlay.Qvalue);
            end
            if AConfig.Overlay.Conproc == 1
                AConfig.Overlay.ValueP =pID;
            else
                AConfig.Overlay.ValueP =pN;
            end
            if isempty(AConfig.Overlay.ValueP)
                AConfig.Overlay.ValueP = 0;
            end
            if  AConfig.Overlay.ValueP == 0
                msgbox('No voxel exists after FDR !');
            end
            AConfig.Overlay.ValueThrdAbsolute =SetThrdAbsValueFDR(AConfig);
            AConfig =ThresholdOverlayVolume(AConfig);
            AConfig=SetImage(AConfig);	 %DONGFDR 100118
            case 99, %Save current map,
                %Todo, 20070916
                [filename, pathname] = uiputfile('*.jpg','Save current view: ');
                if isequal(filename,0) | isequal(pathname,0)
                else
                    theFilename =fullfile(pathname,filename);
                    SaveCurrentView(AConfig, AFilename);
                end
            otherwise
        end
        % else
        % warndlg('Please Check on "SeeOverlay" before changing Overlay options!');
	% end%end if SeeOverlay(AConfig)
	%Reset position in Choice selection
	set(AConfig.hOverlayMisc, 'Value', 1);
	Result =AConfig;
function Result =Open_Template(AConfig)	
	isNeedUpdate =false;
	switch get(AConfig.hTemplate, 'Value'),
	case 1,	%Overlay Misc
		%Do nothing		
	case 2, %'Open Template AAL'
		rest_misc( 'CheckTemplate');
		theNewOverlay =fullfile(rest_misc( 'WhereIsREST'), 'Template', 'aal.nii'); %YAN Chao-Gan 081223: use the NIFTI image information from the MRIcroN	 
		set(AConfig.hOverlayFile, 'String', theNewOverlay);
		% DPARSF_rest_sliceviewer('ChangeOverlay', AConfig.hFig);
		AConfig =LoadOverlay(AConfig, theNewOverlay);
		set(AConfig.hSeeOverlay, 'Value', 1);
	case 3, %'Open Template Brodmann'
		rest_misc( 'CheckTemplate');
		theNewOverlay =fullfile(rest_misc( 'WhereIsREST'), 'Template', 'brodmann.nii'); %YAN Chao-Gan 081223: use the NIFTI image information from the MRIcroN	 
		set(AConfig.hOverlayFile, 'String', theNewOverlay);
		% DPARSF_rest_sliceviewer('ChangeOverlay', AConfig.hFig);			
		AConfig =LoadOverlay(AConfig, theNewOverlay);
		set(AConfig.hSeeOverlay, 'Value', 1);
	case 4, %'Open Template Ch2'
		rest_misc( 'CheckTemplate');
		theNewUnderlay =fullfile(rest_misc( 'WhereIsREST'), 'Template', 'ch2.nii'); %YAN Chao-Gan 100403: use the ch2 bet image information from the MRIcroN	 
		set(AConfig.hUnderlayFile, 'String', theNewUnderlay);
		% DPARSF_rest_sliceviewer('ChangeOverlay', AConfig.hFig);	
		AConfig.Filename =theNewUnderlay;
		AConfig =InitUnderlay(AConfig);		
	case 5, %'Open Template Ch2'
		rest_misc( 'CheckTemplate');
		theNewUnderlay =fullfile(rest_misc( 'WhereIsREST'), 'Template', 'ch2bet.nii'); %YAN Chao-Gan 100403: use the ch2 bet image information from the MRIcroN	 
		set(AConfig.hUnderlayFile, 'String', theNewUnderlay);
		% DPARSF_rest_sliceviewer('ChangeOverlay', AConfig.hFig);	
		AConfig.Filename =theNewUnderlay;
		AConfig =InitUnderlay(AConfig);			
	otherwise
	end
	set(AConfig.hTemplate, 'Value', 1);
	Result =AConfig;
function Result =CurrentThrd2Mask(AConfig)%dong 2009-09-09
    Result =AConfig.Overlay.VolumeThrd;
	
function Result =CurrentCluster2Mask(AConfig)
%Retrieve the cluster containing current point!
	% Result =ThresholdOverlayVolume(AConfig); %ThrdOverlayValue(AConfig, AConfig.Overlay.Volume);
	Result =AConfig.Overlay.VolumeThrd;
	[theCluster, theCount] =bwlabeln(Result, AConfig.Overlay.ClusterConnectivityCriterion); %DONG Zhang-Ye and YAN Chao-Gan 090711, make the Cluster Connectivity Criterion flexible.  %[theCluster, theCount] =bwlabeln(Result);
    %Get the current point's position
	thePosition =Pos_Underlay2Overlay(AConfig, AConfig.LastPosition);
	if Result(thePosition(1),thePosition(2),thePosition(3))~=0, %Current point is valid and must reside in some cluster
		[pathstr, name, ext] = fileparts(AConfig.Overlay.Filename);
		%if strcmpi(name, 'aal') || strcmpi(name, 'brodmann'),
		%	theCurrentCluster = Result==Result(thePosition(1),thePosition(2),thePosition(3));
		%	Result(~theCurrentCluster)=0;
		%	return;
		%else %BwlabelN not work for AAL or Brodmann whose clusters are adjacent			
			%Get the current point's cluster's label and return the current cluster			
			theCurrentCluster = theCluster==theCluster(thePosition(1),thePosition(2),thePosition(3));
			theCluster(~theCurrentCluster)=0;
			%transform the Result to a binary mask				
			Result(~logical(theCluster))=0;
			%Result =ceil(abs(Result));	%Revise for t-map just for not rounding to zero!
			return;
		%end
	else
		Result =[];
	end	
	
%Todo, 20070919
function SaveCurrentView(AConfig, AFilename)
	%Hide most components and save the result 
	theObjects =allchild(AConfig.hFig);
	for x=1:length(AConfig.hFig),
		if strcmpi(get(theObjects,'Type'), 'axes'),
		end
	end
		   
	saveas(AConfig.hFig,theFilename);
	
function Result =InitRecent(AConfig)
	Result =AConfig;	 
	theRecentCfg =fullfile(tempdir,['RecentUnderlay','_',rest_misc('GetCurrentUser'),'.txt']); %YAN Chao-Gan, 100420.  %theRecentCfg =fullfile(rest_misc( 'WhereIsREST'), 'RecentUnderlay.txt');
	if  exist(theRecentCfg, 'file')==2,
		[Result.Recent.Underlay] =textread(theRecentCfg,'%s', 'delimiter','\n');
	else
		Result.Recent.Underlay={};
    end
	theRecentCfg =fullfile(tempdir,['RecentOverlay','_',rest_misc('GetCurrentUser'),'.txt']);  %YAN Chao-Gan, 100420. %theRecentCfg =fullfile(rest_misc( 'WhereIsREST'), 'RecentOverlay.txt');
	if  exist(theRecentCfg, 'file')==2,
		[Result.Recent.Overlay] =textread(theRecentCfg,'%s', 'delimiter','\n');
	else
		Result.Recent.Overlay={};
	end	
	set(AConfig.hUnderlayRecent, 'String', [{'Underlay: '}; Result.Recent.Underlay], 'Value',1);
	set(AConfig.hOverlayRecent, 'String', [{'Overlay: '}; Result.Recent.Overlay], 'Value',1);
	
function Result =AddRecentUnderlay(AConfig, AFilename)
	Result =AConfig;
	
	%20071102
	%Check whether there is space in the AFilename to prevent from problem TextRead not-function when space contained !
	if any(isspace(AFilename)),	return;	end;
	
	%check whether the same menu item exist
	theIndex =strmatch(lower(AFilename), lower(Result.Recent.Underlay), 'exact');
	if ~isempty(theIndex),
		%Move the item to the first
		for x=theIndex-1:-1:1,
			Result.Recent.Underlay{x+1} =Result.Recent.Underlay{x};
		end
	else		
		%Add
		if length(Result.Recent.Underlay)<6,%few	
			Result.Recent.Underlay =[Result.Recent.Underlay; {''}];
		end
		for x=length(Result.Recent.Underlay):-1:2,
			Result.Recent.Underlay{x} =Result.Recent.Underlay{x-1};
		end
	end	
	Result.Recent.Underlay{1} =AFilename;		
	set(AConfig.hUnderlayRecent, 'String', [{'Underlay: '}; Result.Recent.Underlay], 'Value',1);	
	
function Result =AddRecentOverlay(AConfig, AFilename)
	Result =AConfig;
	%20071102
	%Check whether there is space in the AFilename to prevent from problem TextRead not-function when space contained !
	if any(isspace(AFilename)),	return;	end;
	
	
	%check whether the same menu item exist
	theIndex =strmatch(lower(AFilename), lower(Result.Recent.Overlay), 'exact' );
	if ~isempty(theIndex),
		%Move the item to the first
		for x=theIndex-1:-1:1,
			Result.Recent.Overlay{x+1} =Result.Recent.Overlay{x};
		end
	else		
		%Add
		if length(Result.Recent.Overlay)<6,%few	
			Result.Recent.Overlay =[Result.Recent.Overlay; {''}];
		end
		for x=length(Result.Recent.Overlay):-1:2,
			Result.Recent.Overlay{x} =Result.Recent.Overlay{x-1};
		end
	end		
	Result.Recent.Overlay{1} =AFilename;
	set(AConfig.hOverlayRecent, 'String', [{'Overlay: '}; Result.Recent.Overlay], 'Value',1);	
	
function SaveRecent(AConfig, AType)
%AType = RecentUnderlay.txt or RecentOverlay.txt
	theRecentCfg =fullfile(tempdir,[AType,'_',rest_misc('GetCurrentUser'),'.txt']);  % YAN Chao-Gan, 100420. %theRecentCfg =fullfile(rest_misc( 'WhereIsREST'), [AType, '.txt']);
	if strcmpi(AType, 'RecentUnderlay'),
		theList =AConfig.Recent.Underlay;
	elseif strcmpi(AType, 'RecentOverlay'),
		theList =AConfig.Recent.Overlay;
	end
	hFile =fopen(theRecentCfg, 'w');
	if hFile>0,					
		for x=1:length(theList),
			fprintf(hFile, '%s\r\n', theList{x});
		end		
		fclose(hFile);
	else 
		error(sprintf('Can''t write config file: %s', theRecentCfg));
	end		
	
%20070921, Colorbar definition/regeneratioin	
function Result =DefineColorMap(AConfig, AColorDefCmd)	
	Result =AConfig;
	try
		theNumberCmd =str2double(AColorDefCmd);
		if ~isnan(theNumberCmd), %2,4,6...20 and is even!
			if mod(theNumberCmd,2)==1 || theNumberCmd>20,
				errordlg(sprintf('The number must be even because there must be even numbers of colors in the colormap.\n\n And the Number must be less than 20. \n\nIllegal for your input: %d.', theNumberCmd), rest_misc( 'GetRestVersion'));				
				return;
			else
				if theNumberCmd<2, theNumberCmd =2; AColorDefCmd='2'; end %for not zero encountered!
				theColormap =AFNI_ColorMap(theNumberCmd);  %Changed to AFNI color map, YAN Chao-Gan, 090601 %theColormap =jet(theNumberCmd);
			end			
		else	%It is an USER DEFINED MATLAB command to generate the color map
			if strcmpi(AColorDefCmd, '**'), %Use default color map
				theColormap =jet(64);
			else	%Evaluate the user's command in MATLAB
				theColormap=eval(AColorDefCmd);
			end
		end
		%Save the color-bar's definition
		AConfig.Overlay.ColorbarCmd =AColorDefCmd;
		AConfig.Overlay.Colormap 	=theColormap;
		Result =DrawColorbar(AConfig);
	catch		
		rest_misc( 'DisplayLastException');
		errordlg('Error occured! Input may be illegal!');
	end	
	
function Result =DrawColorbar(AConfig)
	Result =AConfig;
	%Set whether to show the color bar	
	[pathstr, name, ext] = fileparts(AConfig.Overlay.Filename);
	if SeeOverlay(AConfig) && ~strcmpi(name,'aal') && ~strcmpi(name,'brodmann'),
		set(AConfig.hAxesColorbar, 'Visible', 'on');
		set(AConfig.hImageColorbar,'Visible', 'on');
        set(AConfig.hImageCover,'Visible', 'on'); 
	
	else
		set(AConfig.hAxesColorbar, 'Visible', 'off');
		set(AConfig.hImageColorbar,'Visible', 'off');
        set(AConfig.hImageCover,'Visible', 'off');
		%Clear old labels
		theLabels =findobj(AConfig.hAxesColorbar, 'Type', 'text');
		for theX=1:length(theLabels), delete(theLabels(theX)); end
		return;
	end
	
	
	theColorbarWidth =20;
	%Set the colorbar's position according to the figure's height
	MarginX =10; MarginY =10;
	thePos =get(AConfig.hFig, 'Position');
	if strcmpi(AConfig.ViewMode, 'Orthogonal'),
		theAxesPosTop  =get(AConfig.hAxesSagittal, 'Position');
		theAxesPosDown =get(AConfig.hAxesTransverse, 'Position');
		theLeft 	=theAxesPosTop(1) +theAxesPosTop(3) +MarginX;
		theHeight	=theAxesPosTop(4) +theAxesPosDown(4);
		theColorBarPos =[theLeft, MarginY, theColorbarWidth, theHeight];
	elseif strcmpi(AConfig.ViewMode, 'Sagittal'),
		theAxesPos  =get(AConfig.hAxesSagittal, 'Position');		
		theLeft 	=theAxesPos(1) +theAxesPos(3) +MarginX;
		theHeight	=theAxesPos(4);
		theColorBarPos =[theLeft, MarginY, theColorbarWidth, theHeight];
	elseif strcmpi(AConfig.ViewMode, 'Transverse'),
		theAxesPos  =get(AConfig.hAxesTransverse, 'Position');		
		theLeft 	=theAxesPos(1) +theAxesPos(3) +MarginX;
		theHeight	=theAxesPos(4);
		theColorBarPos =[theLeft, MarginY, theColorbarWidth, theHeight];
	elseif strcmpi(AConfig.ViewMode, 'Coronal'),
		theAxesPos  =get(AConfig.hAxesCoronal, 'Position');		
		theLeft 	=theAxesPos(1) +theAxesPos(3) +MarginX;
		theHeight	=theAxesPos(4);
		theColorBarPos =[theLeft, MarginY, theColorbarWidth, theHeight];
	end
	set(AConfig.hAxesColorbar, 'Position', theColorBarPos);
    theColorBarPosCover=[theLeft,MarginY + theHeight/2,theColorbarWidth+5,3];
    set(AConfig.hImageCover, 'Position', theColorBarPosCover,'Visible','on') %dong 1130
		
	
	theNumberCmd =str2double(AConfig.Overlay.ColorbarCmd);
	if ~isnan(theNumberCmd), %2,4,6...20 and is even!		
		%Draw a element-divided colorbar, each element-color is defined by the coordesponding color in jet(theNumberColorElements)
		theColormap =reshape(AConfig.Overlay.Colormap, [size(AConfig.Overlay.Colormap,1), 1, size(AConfig.Overlay.Colormap,2)]);
		theColormap =repmat(theColormap, [1 theColorbarWidth 1]);
        if rest_misc('GetMatlabVersion')>=7.4   %YAN Chao-Gan 090401: The imresize function has been completely rewritten in Matlab R2007a. Fixed the bug of 'Set Overlay's Color bar' in Matlab R2007a or latter version.
            theColormap =imresize_old(theColormap, [theColorBarPos(4), theColorbarWidth]);
        else
            theColormap =imresize(theColormap, [theColorBarPos(4), theColorbarWidth]);
        end
		theDivideLine =reshape(get(AConfig.hFig, 'Color'), [1 1 3]);
		theDivideLine =repmat(theDivideLine, [3, theColorbarWidth, 1]);
		for x=1:theNumberCmd, % YAN Chao-Gan, 091201. %theNumberCmd-1,
			theGrayLinePos = floor(x*(theColorBarPos(4)/theNumberCmd) +[-1 0 1]);
			theColormap(theGrayLinePos, :, :) = theDivideLine;			
        end
        set(AConfig.hImageColorbar, 'CData', (theColormap), 'HitTest', 'off','Visible', 'on');
        set(AConfig.hAxesColorbar,'Visible', 'on', 'XLim', [1 size(theColormap,2)], ...
		'YLim', [1 size(theColormap,1)]);
	else	%Evaluate the user's command in MATLAB  and %Draw a smooth colorbar
		%Build the image to show
		theColormap =reshape(AConfig.Overlay.Colormap, [size(AConfig.Overlay.Colormap,1), 1, size(AConfig.Overlay.Colormap,2)]);
		theColormap =repmat(theColormap, [1 theColorbarWidth 1]);
 
        theColormaptmp=theColormap;
        
        set(AConfig.hImageColorbar, 'CData', (theColormaptmp), 'HitTest', 'off','Visible', 'on');
        set(AConfig.hAxesColorbar,'Visible', 'on', 'XLim', [1 size(theColormap,2)], ...
		'YLim', [1 size(theColormap,1)]);
    end
	
	
	%Clear old labels
	theLabels =findobj(AConfig.hAxesColorbar, 'Type', 'text');
	for theX=1:length(theLabels), delete(theLabels(theX)); end
	%Add new labels
	if ~isnan(theNumberCmd), %2,4,6...20 and is even!
		%Draw a element-divided colorbar, each element-color is defined by the coordesponding color in jet(theNumberColorElements)		
		%		for x=1:(theNumberCmd+1),
		%Draw negative lables
		for x=1:theNumberCmd/2+1, %YAN Chao-Gan 091201. %x=1:theNumberCmd/2
			theGrayLinePos  = floor((x-1)*(theColorBarPos(4)/theNumberCmd))-8; %YAN Chao-Gan 091201. Move the negative labels down 8 pixels. %theGrayLinePos  = floor((x-1)*(theColorBarPos(4)/theNumberCmd));
			if x==theNumberCmd/2+1
                theGrayLinePos=theGrayLinePos-8;
            end%YAN Chao-Gan 091201. Move the negative labels down 8 pixels.
% 			if theNumberCmd/2 >1, % YAN Chao-Gan 091201.
                if AConfig.Overlay.ValueThrdAbsolute<abs(AConfig.Overlay.MinNegative)
                    thePercentValue = AConfig.Overlay.MinNegative +(-AConfig.Overlay.ValueThrdAbsolute -AConfig.Overlay.MinNegative) /(theNumberCmd/2)  * (x-1); %YAN Chao-Gan 091201. %AConfig.Overlay.MinNegative +(-AConfig.Overlay.ValueThrdAbsolute -AConfig.Overlay.MinNegative) /(theNumberCmd/2-1)  * (x-1);
                else
                    thePercentValue = AConfig.Overlay.MinNegative;
               end
				%thePercentValue = AConfig.Overlay.MinNegative +(AConfig.Overlay.MaxNegative -AConfig.Overlay.MinNegative) /(theNumberCmd/2 -1)  * (x-1);
% 			elseif theNumberCmd/2 ==1,
% 				thePercentValue = AConfig.Overlay.MinNegative;
% 			end
			
			text( 1.5* theColorbarWidth, theGrayLinePos, sprintf('%.2f',thePercentValue), 'Parent', AConfig.hAxesColorbar, 'Color', 'black', 'HitTest', 'off', 'Units', 'pixels', 'VerticalAlignment', 'bottom', 'FontName','FixedWidth', 'FontSize', 10);
		end
		%Draw positive lables
		for x=(theNumberCmd/2):theNumberCmd, %YAN Chao-Gan 091201, %x=(theNumberCmd/2+1):theNumberCmd
			theGrayLinePos  = floor((x)*(theColorBarPos(4)/theNumberCmd)); %YAN Chao-Gan %theGrayLinePos  = floor((x-1+1)*(theColorBarPos(4)/theNumberCmd));
			
% 			if theNumberCmd/2 >1, % YAN Chao-Gan 091201.
                if AConfig.Overlay.ValueThrdAbsolute<abs(AConfig.Overlay.MaxPositive)
                    %thePercentValue = AConfig.Overlay.MinPositive +(AConfig.Overlay.MaxPositive -AConfig.Overlay.MinPositive) /(theNumberCmd -1 -theNumberCmd/2)  * (x-1 -theNumberCmd/2);
                    thePercentValue = AConfig.Overlay.ValueThrdAbsolute +(AConfig.Overlay.MaxPositive -AConfig.Overlay.ValueThrdAbsolute) /(theNumberCmd/2)  * (x -theNumberCmd/2); % YAN Chao-Gan 091201. %thePercentValue = AConfig.Overlay.ValueThrdAbsolute +(AConfig.Overlay.MaxPositive -AConfig.Overlay.ValueThrdAbsolute) /(theNumberCmd -1 -theNumberCmd/2)  * (x-1 -theNumberCmd/2);
                else
                    thePercentValue = AConfig.Overlay.MaxPositive;
                end
% 			elseif theNumberCmd/2 ==1,
% 				thePercentValue = AConfig.Overlay.MaxPositive;
% 			end
			
			text( 1.5* theColorbarWidth, theGrayLinePos, sprintf('%.2f',thePercentValue), 'Parent', AConfig.hAxesColorbar, 'Color', 'black', 'HitTest', 'off', 'Units', 'pixels', 'VerticalAlignment', 'bottom', 'FontName','FixedWidth', 'FontSize', 10);
		end
	else		%Draw labels for smooth display
        %dong did for the color bar  091128 ValueThrdAbsolute
        % 		%Draw negative lables
        if AConfig.Overlay.ValueThrdAbsolute<abs(AConfig.Overlay.MinNegative)
            text( 1.5* theColorbarWidth, 0, sprintf('%.2f',AConfig.Overlay.MinNegative), 'Parent', AConfig.hAxesColorbar, 'Color', 'black', 'HitTest', 'off', 'Units', 'pixels', 'VerticalAlignment', 'bottom');
            text( 1.5* theColorbarWidth, floor(theColorBarPos(4)/2)-10, sprintf('-%.2f',AConfig.Overlay.ValueThrdAbsolute), 'Parent', AConfig.hAxesColorbar, 'Color', 'black', 'HitTest', 'off', 'Units', 'pixels', 'VerticalAlignment', 'bottom');
        else
            text( 1.5* theColorbarWidth, 0, sprintf('%.2f',AConfig.Overlay.MinNegative), 'Parent', AConfig.hAxesColorbar, 'Color', 'black', 'HitTest', 'off', 'Units', 'pixels', 'VerticalAlignment', 'bottom');
        end
		%Draw positive lables
		text( 1.5* theColorbarWidth, ceil(theColorBarPos(4)/2)+10, sprintf('%.2f',AConfig.Overlay.ValueThrdAbsolute), 'Parent', AConfig.hAxesColorbar, 'Color', 'black', 'HitTest', 'off', 'Units', 'pixels', 'VerticalAlignment', 'bottom');
		text( 1.5* theColorbarWidth, theColorBarPos(4),...
		sprintf('%.2f',AConfig.Overlay.MaxPositive), 'Parent', AConfig.hAxesColorbar, 'Color', 'black', 'HitTest', 'off', 'Units', 'pixels', 'VerticalAlignment', 'bottom');
        
% 		%Draw negative lables
% 		text( 1.5* theColorbarWidth, 0, sprintf('%.2f',AConfig.Overlay.MinNegative), 'Parent', AConfig.hAxesColorbar, 'Color', 'black', 'HitTest', 'off', 'Units', 'pixels', 'VerticalAlignment', 'bottom');
% 		text( 1.5* theColorbarWidth, floor(theColorBarPos(4)/2)-10, sprintf('%.2f',AConfig.Overlay.MaxNegative), 'Parent', AConfig.hAxesColorbar, 'Color', 'black', 'HitTest', 'off', 'Units', 'pixels', 'VerticalAlignment', 'bottom');
% 		%Draw positive lables
% 		text( 1.5* theColorbarWidth, ceil(theColorBarPos(4)/2)+10, sprintf('%.2f',AConfig.Overlay.MinPositive), 'Parent', AConfig.hAxesColorbar, 'Color', 'black', 'HitTest', 'off', 'Units', 'pixels', 'VerticalAlignment', 'bottom');
% 		text( 1.5* theColorbarWidth, theColorBarPos(4), sprintf('%.2f',AConfig.Overlay.MaxPositive), 'Parent', AConfig.hAxesColorbar, 'Color', 'black', 'HitTest', 'off', 'Units', 'pixels', 'VerticalAlignment', 'bottom');
	end	
	
	ResizeFigure(AConfig);
	
function Result =SetColorElements(AConfig)	
%Callback by clicking the color element on the color bar
	%1. Detect which element was clicked
	%2. Change the color and save
	
	theAxes			=get(AConfig.hFig, 'CurrentObject');
	%Check legal click point in the axes
	thePoint		=get(theAxes,'CurrentPoint');
	thePoint 		=round(thePoint(1, 1:2));
    theXLim =get(theAxes, 'XLim');
    theYLim =get(theAxes, 'YLim');	
	if thePoint(1)<theXLim(1) || thePoint(1)>theXLim(2) ...
	   || thePoint(2)<theYLim(1) || thePoint(2)>theYLim(2) ,
		Result =AConfig;
		return;
	end
	
	theColorBarPos =get(AConfig.hAxesColorbar, 'Position');
	theNumberCmd =str2double(AConfig.Overlay.ColorbarCmd);
	if ~isnan(theNumberCmd), %2,4,6...20 and is even!
		% theColorbar =get(AConfig.hImageColorbar, 'CData');		
		% uisetcolor(theColorbar(thePoint(2), 1, :));
		theColorIndex =1+ floor(thePoint(2)/(theColorBarPos(4)/theNumberCmd));
		theColor =uisetcolor(AConfig.Overlay.Colormap(theColorIndex, :));
		if numel(theColor==3),%User defined a color, didn't clicked Cancel btn
			AConfig.Overlay.Colormap(theColorIndex, :) =theColor;
		end
	end
	Result =AConfig;
	return;
	
	

function ToggleInfoDisplay(AConfig);
	theTitle ='Click to Toggle Hdr info';
	theOldMsg =get(AConfig.hMsgLabel, 'String');
	if strcmpi(theTitle, theOldMsg),
		set(AConfig.hMsgLabel, 'String', 'Anything not same with theTitle');
	else
		set(AConfig.hMsgLabel, 'String', theTitle);
	end
	SetMessage(AConfig);
	ResizeFigure(AConfig);
	


		

	
function Result =OnKeyPress(AConfig)
%Processing up/down left/right J/K F1/F2... to responding previous slice or next slice
	%left=0x1C, right=0x1D, up=0x1E, down=0x1F
	%j =0x6A, k=0x6B; 
	%J=0x4A, K=0x4B
	%F1, F2 not known! MATLAB not responding!
	%disp(sprintf('%x',(get(AConfig.hFig, 'CurrentCharacter'))));
	Result =AConfig;
	theKey =get(AConfig.hFig, 'CurrentCharacter');
	if isempty(theKey), return; end
    % Revised by DONG Zhang-Ye 090721, adding new corresponding fuctions to key pressing
	if any(theKey==hex2dec(['6a';'4a';])),   %if any(theKey==hex2dec(['1c';'1f';'6a';'4a';])),
		Result =Slice2Previous(AConfig);
	elseif any(theKey==hex2dec(['6b';'4b';'20';])),  %elseif any(theKey==hex2dec(['1d';'1e';'6b';'4b';])),
		Result =Slice2Next(AConfig);
    elseif any(theKey==hex2dec(['1c';])),
        Result =Slice2Left(AConfig);
    elseif any(theKey==hex2dec(['1d';])),
        Result =Slice2Right(AConfig);
    elseif any(theKey==hex2dec(['1f';])),
        Result =Slice2Down(AConfig);
    elseif any(theKey==hex2dec(['1e';])),
        Result =Slice2Up(AConfig);
	end
	
function Result =Slice2Previous(AConfig)
	Result =AConfig;
	switch lower(AConfig.LastAxes),
	case 'transverse',
		AConfig.LastPosition(1) =AConfig.LastPosition(1)-1;
		while AConfig.LastPosition(1) <1,
			AConfig.LastPosition(1) = AConfig.LastPosition(1) +size(AConfig.Volume, 1);
		end
	case 'coronal',
		AConfig.LastPosition(2) =AConfig.LastPosition(2)-1;
		while AConfig.LastPosition(2) <1,
			AConfig.LastPosition(2) = AConfig.LastPosition(2) +size(AConfig.Volume, 2);
		end
	case 'sagittal',
		AConfig.LastPosition(3) =AConfig.LastPosition(3)-1;
		while AConfig.LastPosition(3) <1,
			AConfig.LastPosition(3) = AConfig.LastPosition(3) +size(AConfig.Volume, 3);
		end
	end
	Result =AConfig;
	
function Result =Slice2Next(AConfig)
	Result =AConfig;
	switch lower(AConfig.LastAxes),
	case 'transverse',
		AConfig.LastPosition(1) =AConfig.LastPosition(1)+1;
		while AConfig.LastPosition(1) >size(AConfig.Volume, 1),
			AConfig.LastPosition(1) = AConfig.LastPosition(1) -size(AConfig.Volume, 1);
		end
	case 'coronal',
		AConfig.LastPosition(2) =AConfig.LastPosition(2)+1;
		while AConfig.LastPosition(2) >size(AConfig.Volume, 2),
			AConfig.LastPosition(2) = AConfig.LastPosition(2) -size(AConfig.Volume, 2);
		end
	case 'sagittal',
		AConfig.LastPosition(3) =AConfig.LastPosition(3)+1;
		while AConfig.LastPosition(3) >size(AConfig.Volume, 3),
			AConfig.LastPosition(3) = AConfig.LastPosition(3) -size(AConfig.Volume, 3);
		end
	end
	Result =AConfig;

function Result =Slice2Left(AConfig)
% Added by DONG Zhang-Ye 090721, adding new corresponding fuctions to key pressing
	Result =AConfig;
	switch lower(AConfig.LastAxes),
	case 'transverse',
		AConfig.LastPosition(2) =AConfig.LastPosition(2)-1;
		while AConfig.LastPosition(2) <1,
			AConfig.LastPosition(2) = AConfig.LastPosition(2) +size(AConfig.Volume, 1);
		end
	case 'coronal',
		AConfig.LastPosition(1) =AConfig.LastPosition(1)-1;
		while AConfig.LastPosition(1) <1,
			AConfig.LastPosition(1) = AConfig.LastPosition(1) +size(AConfig.Volume, 2);
		end
	case 'sagittal',
		AConfig.LastPosition(1) =AConfig.LastPosition(1)-1;
		while AConfig.LastPosition(1) <1,
			AConfig.LastPosition(1) = AConfig.LastPosition(1) +size(AConfig.Volume, 3);
		end
	end
	Result =AConfig;
	
function Result =Slice2Right(AConfig)
% Added by DONG Zhang-Ye 090721, adding new corresponding fuctions to key pressing
	Result =AConfig;
	switch lower(AConfig.LastAxes),
	case 'transverse',
		AConfig.LastPosition(2) =AConfig.LastPosition(2)+1;
		while AConfig.LastPosition(2) >size(AConfig.Volume, 1),
			AConfig.LastPosition(2) = AConfig.LastPosition(2) -size(AConfig.Volume, 1);
		end
	case 'coronal',
		AConfig.LastPosition(1) =AConfig.LastPosition(1)+1;
		while AConfig.LastPosition(1) >size(AConfig.Volume, 2),
			AConfig.LastPosition(1) = AConfig.LastPosition(1) -size(AConfig.Volume, 2);
		end
	case 'sagittal',
		AConfig.LastPosition(1) =AConfig.LastPosition(1)+1;
		while AConfig.LastPosition(1) >size(AConfig.Volume, 3),
			AConfig.LastPosition(1) = AConfig.LastPosition(1) -size(AConfig.Volume, 3);
		end
	end
	Result =AConfig;
function Result =Slice2Down(AConfig)
% Added by DONG Zhang-Ye 090721, adding new corresponding fuctions to key pressing
	Result =AConfig;
	switch lower(AConfig.LastAxes),
	case 'transverse',
		AConfig.LastPosition(3) =AConfig.LastPosition(3)-1;
		while AConfig.LastPosition(3) <1,
			AConfig.LastPosition(3) = AConfig.LastPosition(3) +size(AConfig.Volume, 1);
		end
	case 'coronal',
		AConfig.LastPosition(3) =AConfig.LastPosition(3)-1;
		while AConfig.LastPosition(3) <1,
			AConfig.LastPosition(3) = AConfig.LastPosition(3) +size(AConfig.Volume, 2);
		end
	case 'sagittal',
		AConfig.LastPosition(2) =AConfig.LastPosition(2)-1;
		while AConfig.LastPosition(2) <1,
			AConfig.LastPosition(2) = AConfig.LastPosition(2) +size(AConfig.Volume, 3);
		end
	end
	Result =AConfig;
function Result =Slice2Up(AConfig)
% Added by DONG Zhang-Ye 090721, adding new corresponding fuctions to key pressing
	Result =AConfig;
		switch lower(AConfig.LastAxes),
	case 'transverse',
		AConfig.LastPosition(3) =AConfig.LastPosition(3)+1;
		while AConfig.LastPosition(3) >size(AConfig.Volume, 1),
			AConfig.LastPosition(3) = AConfig.LastPosition(3) -size(AConfig.Volume, 1);
		end
	case 'coronal',
		AConfig.LastPosition(3) =AConfig.LastPosition(3)+1;
		while AConfig.LastPosition(3) >size(AConfig.Volume, 2),
			AConfig.LastPosition(3) = AConfig.LastPosition(3) -size(AConfig.Volume, 2);
		end
	case 'sagittal',
		AConfig.LastPosition(2) =AConfig.LastPosition(2)+1;
		while AConfig.LastPosition(2) >size(AConfig.Volume, 3),
			AConfig.LastPosition(2) = AConfig.LastPosition(2) -size(AConfig.Volume, 3);
		end
	end
	Result =AConfig;	
   
function Result =UpdatePosition(AConfig, ACurrentPosition)
	%Set the last axes by comparing the last position's value change
	theV =sum(AConfig.LastPosition==ACurrentPosition);
	if theV==1,		
		%Clicking one image/axes
		switch find(AConfig.LastPosition==ACurrentPosition),
		case 1,
			AConfig.LastAxes ='Transverse';
		case 2,
			AConfig.LastAxes ='Coronal';
		case 3,
			AConfig.LastAxes ='Sagittal';
		end
	elseif theV==2,
		%Directly Setting the value in the edit control
		switch find(AConfig.LastPosition~=ACurrentPosition),
		case 1,
			AConfig.LastAxes ='Transverse';
		case 2,
			AConfig.LastAxes ='Coronal';
		case 3,
			AConfig.LastAxes ='Sagittal';
		end
	end
	AConfig.LastPosition =ACurrentPosition;
	Result =AConfig;
	
    
function ColorMap =AFNI_ColorMap(SegmentNum)
	% Generate the color map like AFNI. Written by YAN Chao-Gan, 090601
    % Input: SegmentNum - the number of segments. it should be 2,4,6,8,9,10,11,12,13,14,15,16,17,18,19,20 or 256
    % Output: ColorMap - the generated color map, an x by 3 matrix.
    switch SegmentNum
        case 2,
            ColorMap=[1,1,0;0,0.8,1;];
        case 4,
            ColorMap=[1,1,0;1,0.4118,0;0,0.2667,1;0,0.8,1;];
        case 6,
            ColorMap=[1,1,0;1,0.6,0;1,0.2667,0;0,0,1;0,0.4118,1;0,0.8,1;];
        case 8,
            ColorMap=[1,1,0;1,0.8,0;1,0.4118,0;1,0.2667,0;0,0.2667,1;0,0.4118,1;0,0.6,1;0,0.8,1;];
        case 9,
            ColorMap=[1,1,0;1,0.8,0;1,0.4118,0;1,0.2667,0;0,0.2667,1;0,0.4118,1;0,0.6,1;0,0.8,1;];
        case 10,
            ColorMap=[1,1,0;1,0.8,0;1,0.6,0;1,0.4118,0;1,0.2667,0;0,0,1;0,0.2667,1;0,0.4118,1;0,0.6,1;0,0.8,1;];
        case 11,
            ColorMap=[1,1,0;1,0.8,0;1,0.6,0;1,0.4118,0;1,0.2667,0;1,0,0;0,0,1;0,0.2667,1;0,0.4118,1;0,0.6,1;0,0.8,1;];
        case 12,
            ColorMap=[1,1,0;1,0.8,0;1,0.6,0;1,0.4118,0;1,0.2667,0;1,0,0;0,0,1;0,0.2667,1;0,0.4118,1;0,0.6,1;0,0.8,1;0,1,1;];
        case 13,
            ColorMap=[1,1,0;1,0.8,0;1,0.6,0;1,0.4118,0;1,0.2667,0;1,0,0;0,0,1;0,0.2667,1;0,0.4118,1;0,0.6,1;0,0.8,1;0,1,1;0,1,0;];
        case 14,
            ColorMap=[1,1,0;1,0.8,0;1,0.6,0;1,0.4118,0;1,0.2667,0;1,0,0;0,0,1;0,0.2667,1;0,0.4118,1;0,0.6,1;0,0.8,1;0,1,1;0,1,0;0.1961,0.8039,0.1961;];
        case 15,
            ColorMap=[1,1,0;1,0.8,0;1,0.6,0;1,0.4118,0;1,0.2667,0;1,0,0;0,0,1;0,0.2667,1;0,0.4118,1;0,0.6,1;0,0.8,1;0,1,1;0,1,0;0.1961,0.8039,0.1961;0.3098,0.1843,0.3098;];
        case 16,
            ColorMap=[1,1,0;1,0.8,0;1,0.6,0;1,0.4118,0;1,0.2667,0;1,0,0;0,0,1;0,0.2667,1;0,0.4118,1;0,0.6,1;0,0.8,1;0,1,1;0,1,0;0.1961,0.8039,0.1961;0.3098,0.1843,0.3098;1,0.4118,0.7059;];
        case 17,
            ColorMap=[1,1,0;1,0.8,0;1,0.6,0;1,0.4118,0;1,0.2667,0;1,0,0;0,0,1;0,0.2667,1;0,0.4118,1;0,0.6,1;0,0.8,1;0,1,1;0,1,0;0.1961,0.8039,0.1961;0.3098,0.1843,0.3098;1,0.4118,0.7059;1,1,1;];
        case 18,
            ColorMap=[1,1,0;1,0.8,0;1,0.6,0;1,0.4118,0;1,0.2667,0;1,0,0;0,0,1;0,0.2667,1;0,0.4118,1;0,0.6,1;0,0.8,1;0,1,1;0,1,0;0.1961,0.8039,0.1961;0.3098,0.1843,0.3098;1,0.4118,0.7059;1,1,1;0.8667,0.8667,0.8667;];
        case 19,
            ColorMap=[1,1,0;1,0.8,0;1,0.6,0;1,0.4118,0;1,0.2667,0;1,0,0;0,0,1;0,0.2667,1;0,0.4118,1;0,0.6,1;0,0.8,1;0,1,1;0,1,0;0.1961,0.8039,0.1961;0.3098,0.1843,0.3098;1,0.4118,0.7059;1,1,1;0.8667,0.8667,0.8667;0.7333,0.7333,0.7333;];
        case 20,
            ColorMap=[0.8,0.0627,0.2;0.6,0.1255,0.4;0.4,0.1922,0.6;0.2,0.2549,0.8;0,0.3176,1;0,0.4549,0.8;0,0.5922,0.6;0,0.7255,0.4;0,0.8627,0.2;0,1,0;0.2,1,0;0.4,1,0;0.6,1,0;0.8,1,0;1,1,0;1,0.8,0;1,0.6,0;1,0.4,0;1,0.2,0;1,0,0;];
        otherwise,
            ColorMap=[1,0,0.1373;1,0,0.1176;1,0,0.0941;1,0,0.0706;1,0,0.0471;1,0.0667,0;1,0.0902,0;1,0.1137,0;1,0.1333,0;1,0.1569,0;1,0.1765,0;1,0.1961,0;1,0.2118,0;1,0.2314,0;1,0.251,0;1,0.2667,0;1,0.2863,0;1,0.302,0;1,0.3176,0;1,0.3373,0;1,0.3529,0;1,0.3686,0;1,0.3843,0;1,0.4,0;1,0.4157,0;1,0.4314,0;1,0.4471,0;1,0.4627,0;1,0.4784,0;1,0.4941,0;1,0.5098,0;1,0.5255,0;1,0.5412,0;1,0.5529,0;1,0.5686,0;1,0.5843,0;1,0.6,0;1,0.6118,0;1,0.6275,0;1,0.6431,0;1,0.6549,0;1,0.6706,0;1,0.6824,0;1,0.698,0;1,0.7098,0;1,0.7255,0;1,0.7373,0;1,0.7529,0;1,0.7647,0;1,0.7804,0;1,0.7922,0;1,0.8078,0;1,0.8196,0;1,0.8353,0;1,0.8471,0;1,0.8588,0;1,0.8745,0;1,0.8863,0;1,0.898,0;1,0.9137,0;1,0.9255,0;1,0.9373,0;1,0.9529,0;1,0.9647,0;1,0.9765,0;1,0.9882,0;0.9961,1,0;0.9843,1,0;0.9725,1,0;0.9608,1,0;0.9451,1,0;0.9333,1,0;0.9216,1,0;0.9059,1,0;0.8941,1,0;0.8824,1,0;0.8667,1,0;0.8549,1,0;0.8431,1,0;0.8275,1,0;0.8157,1,0;0.8,1,0;0.7882,1,0;0.7765,1,0;0.7608,1,0;0.749,1,0;0.7333,1,0;0.7216,1,0;0.7059,1,0;0.6941,1,0;0.6784,1,0;0.6627,1,0;0.651,1,0;0.6353,1,0;0.6235,1,0;0.6078,1,0;0.5922,1,0;0.5765,1,0;0.5647,1,0;0.549,1,0;0.5333,1,0;0.5176,1,0;0.5059,1,0;0.4902,1,0;0.4745,1,0;0.4588,1,0;0.4431,1,0;0.4275,1,0;0.4118,1,0;0.3961,1,0;0.3804,1,0;0.3647,1,0;0.3451,1,0;0.3294,1,0;0.3137,1,0;0.2941,1,0;0.2784,1,0;0.2627,1,0;0.2431,1,0;0.2235,1,0;0.2078,1,0;0.1882,1,0;0.1686,1,0;0.149,1,0;0.1255,1,0;0.1059,1,0;0.0824,1,0;0.0549,1,0;0,1,0.0549;0,1,0.0824;0,1,0.1059;0,1,0.1255;0,1,0.149;0,1,0.1686;0,1,0.1882;0,1,0.2078;0,1,0.2235;0,1,0.2431;0,1,0.2627;0,1,0.2784;0,1,0.2941;0,1,0.3137;0,1,0.3294;0,1,0.3451;0,1,0.3647;0,1,0.3804;0,1,0.3961;0,1,0.4118;0,1,0.4275;0,1,0.4431;0,1,0.4588;0,1,0.4745;0,1,0.4902;0,1,0.5059;0,1,0.5176;0,1,0.5333;0,1,0.549;0,1,0.5647;0,1,0.5765;0,1,0.5922;0,1,0.6078;0,1,0.6235;0,1,0.6353;0,1,0.651;0,1,0.6627;0,1,0.6784;0,1,0.6941;0,1,0.7059;0,1,0.7216;0,1,0.7333;0,1,0.749;0,1,0.7608;0,1,0.7765;0,1,0.7882;0,1,0.8;0,1,0.8157;0,1,0.8275;0,1,0.8431;0,1,0.8549;0,1,0.8667;0,1,0.8824;0,1,0.8941;0,1,0.9059;0,1,0.9216;0,1,0.9333;0,1,0.9451;0,1,0.9608;0,1,0.9725;0,1,0.9843;0,1,0.9961;0,0.9882,1;0,0.9765,1;0,0.9647,1;0,0.9529,1;0,0.9373,1;0,0.9255,1;0,0.9137,1;0,0.898,1;0,0.8863,1;0,0.8745,1;0,0.8588,1;0,0.8471,1;0,0.8353,1;0,0.8196,1;0,0.8078,1;0,0.7922,1;0,0.7804,1;0,0.7647,1;0,0.7529,1;0,0.7373,1;0,0.7255,1;0,0.7098,1;0,0.698,1;0,0.6824,1;0,0.6706,1;0,0.6549,1;0,0.6431,1;0,0.6275,1;0,0.6118,1;0,0.6,1;0,0.5843,1;0,0.5686,1;0,0.5529,1;0,0.5412,1;0,0.5255,1;0,0.5098,1;0,0.4941,1;0,0.4784,1;0,0.4627,1;0,0.4471,1;0,0.4314,1;0,0.4157,1;0,0.4,1;0,0.3843,1;0,0.3686,1;0,0.3529,1;0,0.3373,1;0,0.3176,1;0,0.302,1;0,0.2863,1;0,0.2667,1;0,0.251,1;0,0.2314,1;0,0.2118,1;0,0.1961,1;0,0.1765,1;0,0.1569,1;0,0.1333,1;0,0.1137,1;0,0.0902,1;0,0.0667,1;0.0471,0,1;0.0706,0,1;0.0941,0,1;0.1176,0,1;0.1373,0,1;];
    end
    ColorMap=flipdim(ColorMap,1);


function rest_report(data,head,ClusterConnectivityCriterion)
% Generate the report of the thresholded clusters.
% Based on CUI Xu's xjview. (http://www.alivelearn.net/xjview/)
% Revised by YAN Chao-Gan and ZHU Wei-Xuan 20091108: suitable for different Cluster Connectivity Criterion: surface connected, edge connected, corner connected.

if ~(exist('TDdatabase.mat'))
    uiwait(msgbox('This function is based on CUI Xu''s xjview, please install xjview8 or later version at first (http://www.alivelearn.net/xjview/).','REST Slice Viewer'));
    return
end

disp('This report is based on CUI Xu''s xjview. (http://www.alivelearn.net/xjview/)'); 
disp('Revised by YAN Chao-Gan and ZHU Wei-Xuan 20091108: suitable for different Cluster Connectivity Criterion: surface connected, edge connected, corner connected.');
nozeropos=find(data~=0);
[i j k]=ind2sub(size(data),nozeropos);
cor=[i j k];
mni=cor2mni(cor,head.mat);

if isempty(mni)
    %errordlg('No cluster is picked up.','oops');
    disp( 'No cluster is found. So no report will be generated.'); 
    return;
end

intensity=data(nozeropos);


L=cor';
dim = [max(L(1,:)) max(L(2,:)) max(L(3,:))];
vol = zeros(dim(1),dim(2),dim(3));
indx = sub2ind(dim,L(1,:)',L(2,:)',L(3,:)');
vol(indx) = 1;
[cci,num] = bwlabeln(vol,ClusterConnectivityCriterion);
A = cci(indx');

clusterID = unique(A);
numClusters = length(clusterID);
disp(['Number of clusters found: ' num2str(numClusters)]);

for mm = clusterID
    pos = find(A == clusterID(mm));
    numVoxels = length(pos);
    tmpmni = mni(pos,:);
    tmpintensity = intensity(pos);
    
    peakpos = find(abs(tmpintensity) == max(abs(tmpintensity)));
    peakcoord = tmpmni(peakpos,:);
    peakintensity = tmpintensity(peakpos);
    
        % list structure of voxels in this cluster
    x = load('TDdatabase.mat');
    [a, b] = cuixuFindStructure(tmpmni, x.DB);
    names = unique(b(:));
    index = NaN*zeros(length(b(:)),1);
    for ii=1:length(names)
        pos = find(strcmp(b(:),names{ii}));
        index(pos) = ii;
    end

    report = {};
    
    for ii=1:max(index)
        report{ii,1} = names{ii};
        report{ii,2} = length(find(index==ii));
    end
    for ii=1:size(report,1)
        for jj=ii+1:size(report,1)
            if report{ii,2} < report{jj,2}
                tmp = report(ii,:);
                report(ii,:) = report(jj,:);
                report(jj,:) = tmp;
            end
        end
    end
    report = [{'structure','# voxels'}; {'--TOTAL # VOXELS--', length(a)}; report];

    report2 = {sprintf('%s\t%s',report{1,2}, report{1,1}),''};
    for ii=2:size(report,1)
        if strcmp('undefined', report{ii,1}); continue; end
        report2 = [report2, {sprintf('%5d\t%s',report{ii,2}, report{ii,1})}];
    end

    disp(['----------------------'])
    disp(['Cluster ' num2str(mm)])
    disp(['Number of voxels: ' num2str(numVoxels)])
    disp(['Peak MNI coordinate: ' num2str(peakcoord)])
    [a,b] = cuixuFindStructure(peakcoord, x.DB);
    disp(['Peak MNI coordinate region: ' a{1}]);
    disp(['Peak intensity: ' num2str(peakintensity)])
    for kk=1:length(report2)
        disp(report2{kk});
    end
end
return


function mni = cor2mni(cor, T)
% function mni = cor2mni(cor, T)
% convert matrix coordinate to mni coordinate
%
% cor: an Nx3 matrix
% T: (optional) rotation matrix
% mni is the returned coordinate in mni space
%
% caution: if T is not given, the default T is
% T = ...
%     [-4     0     0    84;...
%      0     4     0  -116;...
%      0     0     4   -56;...
%      0     0     0     1];
%
% xu cui
% 2004-8-18
% last revised: 2005-04-30

if nargin == 1
    T = ...
        [-4     0     0    84;...
         0     4     0  -116;...
         0     0     4   -56;...
         0     0     0     1];
end

cor = round(cor);
mni = T*[cor(:,1) cor(:,2) cor(:,3) ones(size(cor,1),1)]';
mni = mni';
mni(:,4) = [];
return;

function coordinate = mni2cor(mni, T)
% function coordinate = mni2cor(mni, T)
% convert mni coordinate to matrix coordinate
%
% mni: a Nx3 matrix of mni coordinate
% T: (optional) transform matrix
% coordinate is the returned coordinate in matrix
%
% caution: if T is not specified, we use:
% T = ...
%     [-4     0     0    84;...
%      0     4     0  -116;...
%      0     0     4   -56;...
%      0     0     0     1];
%
% xu cui
% 2004-8-18
%

if isempty(mni)
    coordinate = [];
    return;
end

if nargin == 1
	T = ...
        [-4     0     0    84;...
         0     4     0  -116;...
         0     0     4   -56;...
         0     0     0     1];
end

coordinate = [mni(:,1) mni(:,2) mni(:,3) ones(size(mni,1),1)]*(inv(T))';
coordinate(:,4) = [];
coordinate = round(coordinate);
return;

function [onelinestructure, cellarraystructure] = cuixuFindStructure(mni, DB)
% function [onelinestructure, cellarraystructure] = cuixuFindStructure(mni, DB)
%
% this function converts MNI coordinate to a description of brain structure
% in aal
%
%   mni: the coordinates (MNI) of some points, in mm.  It is Nx3 matrix
%   where each row is the coordinate for one point
%   LDB: the database.  This variable is available if you load
%   TDdatabase.mat
%
%   onelinestructure: description of the position, one line for each point
%   cellarraystructure: description of the position, a cell array for each point
%
%   Example:
%   cuixuFindStructure([72 -34 -2; 50 22 0], DB)
%
% Xu Cui
% 2007-11-20
%

N = size(mni, 1);

% round the coordinates
mni = round(mni/2) * 2;

T = [...
     2     0     0   -92
     0     2     0  -128
     0     0     2   -74
     0     0     0     1];

index = mni2cor(mni, T);

cellarraystructure = cell(N, length(DB));
onelinestructure = cell(N, 1);

for ii=1:N
    for jj=1:length(DB)
        graylevel = DB{jj}.mnilist(index(ii, 1), index(ii, 2),index(ii, 3));
        if graylevel == 0
            thelabel = 'undefined';
        else
            if jj==length(DB); tmp = ' (aal)'; else tmp = ''; end
            thelabel = [DB{jj}.anatomy{graylevel} tmp];
        end
        cellarraystructure{ii, jj} = thelabel;
        onelinestructure{ii} = [ onelinestructure{ii} ' // ' thelabel ];
    end
end
            
function P=ThrdtoP(Thrd,AConfig)
if isfield(AConfig.Overlay.Header,'descrip')
    headinfo=AConfig.Overlay.Header.descrip; %dong 090921AConfig.Df.Ttest=0;
    if ~isempty(strfind(headinfo,'{T_['))% dong 100331 begin
        testFlag='T';
        Tstart=strfind(headinfo,'{T_[')+length('{T_[');
        Tend=strfind(headinfo,']}')-1;
        testDf = str2num(headinfo(Tstart:Tend));
    elseif ~isempty(strfind(headinfo,'{F_['))
        testFlag='F';
        Tstart=strfind(headinfo,'{F_[')+length('{F_[');
        Tend=strfind(headinfo,']}')-1;
        testDf = str2num(headinfo(Tstart:Tend));
    elseif ~isempty(strfind(headinfo,'{R_['))
        testFlag='R';
        Tstart=strfind(headinfo,'{R_[')+length('{R_[');
        Tend=strfind(headinfo,']}')-1;
        testDf = str2num(headinfo(Tstart:Tend));
    elseif ~isempty(strfind(headinfo,'{Z_['))
        testFlag='Z';
        Tstart=strfind(headinfo,'{Z_[')+length('{Z_[');
        Tend=strfind(headinfo,']}')-1;
        testDf = str2num(headinfo(Tstart:Tend));
    end
    if exist('testFlag')
        if ~isempty(testFlag)
            if exist('testDf')
                if testFlag == 'T'
                    AConfig.Df.Ttest=testDf;
                elseif testFlag == 'F'
                    AConfig.Df.Ftest=testDf;
                elseif testFlag == 'R'
                    AConfig.Df.Rtest=testDf;
                elseif testFlag == 'Z'
                    AConfig.Df.Ztest=testDf;
                end
            end % dong 100331 end
        end
    end
end
if AConfig.Df.Ttest~=0 ,
    AConfig.Overlay.ValueP=2*(1-tcdf(Thrd,AConfig.Df.Ttest));
elseif numel(find(AConfig.Df.Ftest))~=0 ,
    AConfig.Overlay.ValueP =1-fcdf(Thrd,AConfig.Df.Ftest(1),AConfig.Df.Ftest(2));
elseif AConfig.Df.Ztest~=0 ,
    AConfig.Overlay.ValueP=2*(1-normcdf(Thrd));
elseif AConfig.Df.Rtest ~= 0 ,
    AConfig.Overlay.ValueP=2*(1-tcdf(abs(Thrd)*sqrt((AConfig.Df.Rtest)/(1-Thrd*Thrd)),AConfig.Df.Rtest));
end
if  (AConfig.Df.Ttest ==0 && numel(find(AConfig.Df.Ftest)) ==0) && numel(find(AConfig.Df.Ztest)) ==0 && numel(find(AConfig.Df.Rtest)) ==0,AConfig.Overlay.ValueP = 1;end
P=AConfig.Overlay.ValueP;

    
    
function Thrd=PtoThrd(Pvalue,AConfig);
    if isfield(AConfig.Overlay.Header,'descrip')
        headinfo=AConfig.Overlay.Header.descrip; %dong 090921AConfig.Df.Ttest=0;
         if isfield(AConfig.Overlay.Header,'descrip')
                 headinfo=AConfig.Overlay.Header.descrip; %dong 090921AConfig.Df.Ttest=0;
                 if ~isempty(strfind(headinfo,'{T_['))% dong 100331 begin
                     testFlag='T';
                     Tstart=strfind(headinfo,'{T_[')+length('{T_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 elseif ~isempty(strfind(headinfo,'{F_['))
                     testFlag='F';
                     Tstart=strfind(headinfo,'{F_[')+length('{F_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 elseif ~isempty(strfind(headinfo,'{R_['))
                     testFlag='R';
                     Tstart=strfind(headinfo,'{R_[')+length('{R_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 elseif ~isempty(strfind(headinfo,'{Z_['))
                     testFlag='Z';
                     Tstart=strfind(headinfo,'{Z_[')+length('{Z_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 end
                 if exist('testFlag')
                     if ~isempty(testFlag)
                         if exist('testDf')
                             if testFlag == 'T'
                                AConfig.Df.Ttest=testDf;
                             elseif testFlag == 'F'
                                AConfig.Df.Ftest=testDf;
                             elseif testFlag == 'R'
                                 AConfig.Df.Rtest=testDf;
                             elseif testFlag == 'Z'
                                 AConfig.Df.Ztest=testDf;
                             end
                         end % dong 100331 end
                     end
                 end
         end
    end
    if AConfig.Df.Ttest~=0 ,
        if AConfig.Overlay.Tchoose == 2 % YAN Chao-Gan, 100201
            Thrd=tinv(1 - Pvalue/2,AConfig.Df.Ttest);%2*(1-tcdf(Pvalue,AConfig.Df.Ttest));
        else
            Thrd=tinv(1 - Pvalue,AConfig.Df.Ttest);%2*(1-tcdf(Pvalue,AConfig.Df.Ttest));
        end
    elseif numel(find(AConfig.Df.Ftest))~=0 ,
        Thrd =finv(1-Pvalue,AConfig.Df.Ftest(1),AConfig.Df.Ftest(2));%1-fcdf(Pvalue,AConfig.Df.Ftest(1),AConfig.Df.Ftest(2));
    elseif AConfig.Df.Ztest~=0 ,
        if AConfig.Overlay.Tchoose == 2 % YAN Chao-Gan, 100201
            Thrd=norminv(1 - Pvalue/2);%2*(1-normcdf(Pvalue));
        else
            Thrd=norminv(1 - Pvalue);%2*(1-normcdf(Pvalue));
        end
    elseif AConfig.Df.Rtest ~= 0 ,
        if AConfig.Overlay.Tchoose == 2 % YAN Chao-Gan, 100201
            TRvalue=tinv(1 - Pvalue/2,AConfig.Df.Rtest);
            Thrd=sqrt(TRvalue^2/(AConfig.Df.Rtest+TRvalue^2));%2*(1-tcdf(abs(Pvalue)*sqrt((AConfig.Df.Rtest)/(1-Pvalue*Pvalue)),AConfig.Df.Rtest));
        else
            TRvalue=tinv(1 - Pvalue,AConfig.Df.Rtest);
            Thrd=sqrt(TRvalue^2/(AConfig.Df.Rtest+TRvalue^2));%2*(1-tcdf(abs(Pvalue)*sqrt((AConfig.Df.Rtest)/(1-Pvalue*Pvalue)),AConfig.Df.Rtest));
        end
    end
    if  (AConfig.Df.Ttest ==0 && numel(find(AConfig.Df.Ftest)) ==0) && numel(find(AConfig.Df.Ztest)) ==0 && numel(find(AConfig.Df.Rtest)) ==0,Thrd = 0;end
    
    
    
    
    
function Result=CheckDf(AConfig)
Result=AConfig;
    if isfield(AConfig.Overlay,'Header')
        if isfield(AConfig.Overlay.Header,'descrip')
        headinfo=AConfig.Overlay.Header.descrip; %dong 090921AConfig.Df.Ttest=0;
                 if ~isempty(strfind(headinfo,'{T_['))% dong 100331 begin
                     testFlag='T';
                     Tstart=strfind(headinfo,'{T_[')+length('{T_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 elseif ~isempty(strfind(headinfo,'{F_['))
                     testFlag='F';
                     Tstart=strfind(headinfo,'{F_[')+length('{F_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 elseif ~isempty(strfind(headinfo,'{R_['))
                     testFlag='R';
                     Tstart=strfind(headinfo,'{R_[')+length('{R_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 elseif ~isempty(strfind(headinfo,'{Z_['))
                     testFlag='Z';
                     Tstart=strfind(headinfo,'{Z_[')+length('{Z_[');
                     Tend=strfind(headinfo,']}')-1;
                     testDf = str2num(headinfo(Tstart:Tend));
                 end
                 if exist('testFlag')
                     if ~isempty(testFlag)
                         if exist('testDf')
                             if testFlag == 'T'
                                AConfig.Df.Ttest=testDf;
                             elseif testFlag == 'F'
                                AConfig.Df.Ftest=testDf;
                             elseif testFlag == 'R'
                                 AConfig.Df.Rtest=testDf;
                             elseif testFlag == 'Z'
                                 AConfig.Df.Ztest=testDf;
                             end
                         end % dong 100331 end
                     end
                 end
         end
    end
    Result=AConfig;
    
function [pID,pN] = rest_FDR(p,q)
% FORMAT [pID,pN] = FDR(p,q)
% 
% p   - vector of p-values
% q   - False Discovery Rate level
%
% pID - p-value threshold based on independence or positive dependence
% pN  - Nonparametric p-value threshold
%______________________________________________________________________________
% @(#)FDR.m	1.3 Tom Nichols 02/01/18
% 
% example: [pID pN] = FDR(p,0.05)
% DONG FDR 100117  added Tom's FDR routine for REST 
p = sort(p(:));
V = length(p);
I = (1:V)';

cVID = 1;
cVN = sum(1./(1:V));

pID = p(max(find(p<=I/V*q/cVID)));
pN = p(max(find(p<=I/V*q/cVN)));

function Result =SetThrdAbsValueFDR(AConfig)	
%DONG FDR added 100117, for the FDR displays
AConfig=CheckDf(AConfig);
Pvalue =AConfig.Overlay.ValueP;
Result =PtoThrd(Pvalue,AConfig);

theMin =get(AConfig.hSliderThrdValue, 'Min');
theMax =get(AConfig.hSliderThrdValue, 'Max');
if Result<theMin,
    Result =theMin;
    Pvalue=ThrdtoP(theMin,AConfig);
elseif Result>theMax,
    Result =theMax;
    Pvalue=0;
end
set(AConfig.hSliderThrdValue, 'Value', Result);
set(AConfig.hEdtThrdValue, 'String', num2str(Result));
set(AConfig.hEdtPValue, 'String', num2str(Pvalue)); %DONG FDR added 100117, for the FDR displays
