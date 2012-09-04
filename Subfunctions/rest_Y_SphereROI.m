function varargout = rest_Y_SphereROI(AOperation, varargin)
%Define a ROI ball %Dawnwei.Song @ gmail.com % 20070830
%------------------------------------------------------------------------------------------------------------------------------
%	Copyright(c) 2007~2010
%	State Key Laboratory of Cognitive Neuroscience and Learning in Beijing Normal University
%	Written by Xiao-Wei Song 
%	http://resting-fmri.sourceforge.net
% 	Mail to Authors:  <a href="Dawnwei.Song@gmail.com">Xiaowei Song</a>; <a href="ycg.yan@gmail.com">Chaogan Yan</a> 
%	Version=1.3;
%	Release=20091215;
%   Revised by YAN Chao-Gan 080610: NIFTI compatible
%   Revised by YAN Chao-Gan, 091126. LastSphereMask would be stored under temp dir other than {REST_DIR}.
%   Revised by YAN Chao-Gan, 091215. Add Right/Left notice when input coordinates of ROI seed.
%   Revised by YAN Chao-Gan, 101025. For image with affine matrix (i.e., NIfTI images), calculate the voxel index by using VoxelIndex=inv(AffineMatrix)*Coordinates.
%   Revised by YAN Chao-Gan 120817. No longer output mask file in temp dir but output specified mask file.
%------------------------------------------------------------------------------------------------------------------------------
  
if nargin<1, AOperation='Init'; end	%Revise the Start
switch upper(AOperation),
case 'INIT',		%Init	
	AROICenter=[0 0 0]; AROIRadius=0;
	if nargin>0,
		if ischar(varargin{1})
			[AROICenter, AROIRadius] =rest_Y_SphereROI('Str2ROIBall', varargin{1});
		elseif nargin==2,
			AROICenter=varargin{1}; 
			AROIRadius=varargin{2}; 		
		else
			error('False Input');
		end	
	end 
	theConfig =InitControls(AROICenter, AROIRadius);
	%setappdata(theConfig.hFig, 'Config', theConfig);
	
	uiwait(theConfig.hFig);
	theX =str2num(get(theConfig.hEditPositionX, 'String'));		
	theY =str2num(get(theConfig.hEditPositionY, 'String'));		
	theZ =str2num(get(theConfig.hEditPositionZ, 'String'));		
	AROICenter =[theX, theY, theZ];
	if get(theConfig.hTal2Mni, 'Value'),
		%AROICenter =round(rest_tal2mni([theX,theY,theZ]));
        msgbox('The coordinates convertion from Talairach space to MNI space has changed from tal2mni.m to tal2icbm_spm.m. The function is developed and validated by Jack Lancaster (Lancaster et al., 2007).','Function Change'); %YAN Chao-Gan, 111213. Note REST users the function is changed.
        AROICenter =round(rest_tal2icbm_spm([theX,theY,theZ]));
	end
	AROIRadius=str2num(get(theConfig.hEditRadius, 'String'));
	varargout{1} =rest_Y_SphereROI('ROIBall2Str', AROICenter, AROIRadius);
	
	delete(theConfig.hFig);
	
case 'SETANDQUIT',		%SetAndQuit
	theFig =findobj(allchild(0),'flat','Tag','figSetROI');
	if ~isempty(theFig) && rest_misc( 'ForceCheckExistFigure' , theFig),
		%theConfig =getappdata(theFig, 'Config');		
		uiresume(theFig);	
	end
case 'ROIBALL2STR',			%ROIBall2Str
	if nargin~=3, error('Usage: result =rest_Y_SphereROI( ''ROIBall2Str'' , AROICenter, AROIRadius);'); end

	AROICenter=varargin{1}; 
	AROIRadius=varargin{2};
	varargout{1} =sprintf('ROI Center(mm)=(%d, %d, %d); Radius=%.2f mm.', ...
						AROICenter(1), AROICenter(2), AROICenter(3), ...
						AROIRadius);
	
case 'STR2ROIBALL', 		%Str2ROIBall
	if nargin~=2, error('Usage: result =rest_Y_SphereROI( ''Str2ROIBall'' , ABallDefinition);'); end
	
	ABallDefinition =varargin{1};
	if rest_Y_SphereROI( 'IsBallDefinition', ABallDefinition),
		[posBegin, posEnd] =regexp(ABallDefinition, '=\(.*\)');
		AROICenter = str2num(ABallDefinition((posBegin+2):(posEnd-1)));
		varargout{1} =AROICenter;
		ABallDefinition =ABallDefinition(posEnd+1:end);
		[posBegin, posEnd] =regexp(ABallDefinition, '=.*mm');
		AROIRadius = str2num(ABallDefinition((posBegin+1):(posEnd-2)));
		varargout{2} =AROIRadius;
	else
		varargout{1} =[0 0 0];
		varargout{2} =0;
	end
	
	
	
case 'ISBALLDEFINITION',		%IsBallDefinition
	if nargin~=2, error('Usage: result =rest_Y_SphereROI( ''IsBallDefinition'' , ABallDefinition);'); end
	ABallDefinition =varargin{1};
	if isempty(ABallDefinition), varargout{1} =0; return; end
	
	[posBegin, posEnd] =regexp(ABallDefinition, '.*ROI\ Center\(mm\)=\(.*\);\ Radius=.*mm\..*');
	if (~isempty(posBegin) && ~isempty(posEnd)) && (posBegin>=1) && (posEnd<=length(ABallDefinition)),
		varargout{1} =1;
	else	
		varargout{1} =0;
	end
	
case 'BALLDEFINITION2MASK'		%BallDefinition2Mask
	if nargin<5, error('Usage: mask =rest_Y_SphereROI( ''BallDefinition2Mask'' , ABallDefinition, ABrainSize, AVoxelSize, Header [, OutputMaskFileName]);'); end
	ABallDefinition =varargin{1};
	if isempty(ABallDefinition), varargout{1} =0; error('No Ball definition! Please Check!'); end	
	ABrainSize = varargin{2};
    ABrainSize = ABrainSize(1:3); %YAN Chao-Gan, 120822. In case the brain size is a 4D size.
	AVoxelSize =varargin{3};
	Header =varargin{4};

	[AROICenter, AROIRadius] =rest_Y_SphereROI('STR2ROIBALL', ABallDefinition);
    
%   %No longer need this. YAN Chao-Gan 101010
% 	%Revise Left/Right, I think Left Img is Right brain and Left Img is +/Right brain is +
% 	AROICenter(1) =AROICenter(1) *(-1);
	
    %Prepare
	AROICenter=reshape(AROICenter, 1,length(AROICenter));
	Header.Origin=reshape(Header.Origin, 1,length(Header.Origin));
	AVoxelSize=reshape(AVoxelSize, 1,length(AVoxelSize));	
    
	theMask =Ball2Mask(ABrainSize, AVoxelSize, AROICenter, AROIRadius, Header);
	fprintf('\n\n\t\tSeed ROI Definition: %s\n\t\t\tBrain Size: (%s),\t\tVoxel Size: (%s),\t\tOrigin: (%s)\n\t\t\tContained Voxel count: %d\n\n', ABallDefinition, num2str(ABrainSize),num2str(AVoxelSize), num2str(Header.Origin), length(find(theMask)));
	
    varargout{1} =theMask;
    
    % YAN Chao-Gan 120817. No longer output temp mask file.
%     OldDirTemp=pwd;
%     cd (tempdir);
%     rest_writefile(theMask, ...
%         ['LastSphereMask_',rest_misc('GetCurrentUser'),'.img'], ...    %Revised by YAN Chao-Gan, 091126. LastSphereMask would be stored under temp dir other than {REST_DIR}. %fullfile(rest_misc('WhereIsREST'),'LastSphereMask'), ...
%         ABrainSize,AVoxelSize, Header,'int16');
%     cd (OldDirTemp);
    
    if nargin==6 % Added by YAN Chao-Gan, 110111. Also output wanted mask file.
        rest_writefile(theMask, ... 
            varargin{5}, ...
            ABrainSize,AVoxelSize, Header,'int16');
    end

otherwise	
 end
 
function Result =InitControls(AROICenter, AROIRadius)
	theFig =figure('Units', 'pixel', 'Toolbar', 'none', 'MenuBar', 'none', ...
					'Tag', 'figSetROI', 'WindowStyle', 'modal', ...
					'CloseRequestFcn', 'rest_Y_SphereROI(''SetAndQuit'');', ...
					'NumberTitle', 'off', 'Visible', 'off', ... 
					'Name', sprintf('Seed ROI Definition'), ...
					'Position', [0,0,250, 350], 'Resize','off');  	%YAN Chao-Gan 091215. 'Position', [0,0,250, 150], 'Resize','off');
	movegui(theFig, 'center'); 
	
	OffsetX =0; MarginX=10; OffsetY=0; MarginY=25;
	theEditCallbackFcn =sprintf('');
	theLeft =OffsetX+MarginX; theBottom =OffsetY+MarginY+35+MarginY/2;
	uicontrol(theFig, 'Style','text', 'Units','pixels', ...
			  'String', 'X(mm)', ...
			  'BackgroundColor', get(theFig,'Color'), ...			  
			  'Position',[theLeft, theBottom, 46,15]);
	theLeft =OffsetX+MarginX; theBottom =OffsetY+MarginY+20;
	hEditPositionX =uicontrol(theFig, 'Style','edit', 'Units','pixels', ...
							  'String', int2str(AROICenter(1)), ...
							  'BackgroundColor', 'white', ...
							  'Callback', theEditCallbackFcn, ...
							  'Position',[theLeft, theBottom, 46,20]);
							  
	theLeft =OffsetX+MarginX+30+MarginX; theBottom =OffsetY+MarginY+35+MarginY/2;					  
	uicontrol(theFig, 'Style','text', 'Units','pixels', ...
			  'String', 'Y(mm)', ...
			  'BackgroundColor', get(theFig,'Color'), ...
			  'Position',[theLeft+8, theBottom, 46,15]);
	theLeft =OffsetX+MarginX+30+MarginX; theBottom =OffsetY+MarginY+20;			  
	hEditPositionY =uicontrol(theFig, 'Style','edit', 'Units','pixels', ...
							  'String', int2str(AROICenter(2)), ...
							  'BackgroundColor', 'white', ...
							  'Callback', theEditCallbackFcn, ...
							  'Position',[theLeft+8, theBottom, 46,20]);
			
	theLeft =OffsetX+MarginX+30+MarginX+30+MarginX; theBottom =OffsetY+MarginY+35+MarginY/2;		
	uicontrol(theFig, 'Style','text', 'Units','pixels', ...
			  'String', 'Z(mm)', ...
			  'BackgroundColor', get(theFig,'Color'), ...
			  'Position',[theLeft+16, theBottom, 46,15]);
			  
	theLeft =OffsetX+MarginX+30+MarginX+30+MarginX; theBottom =OffsetY+MarginY+20;		  
	hEditPositionZ =uicontrol(theFig, 'Style','edit', 'Units','pixels', ...
							  'String', int2str(AROICenter(3)), ...
							  'BackgroundColor', 'white', ...
							  'Callback', theEditCallbackFcn, ...
							  'Position',[theLeft+16, theBottom, 46,20]);
							  
	theLeft =OffsetX+MarginX; 
	hTal2Mni =uicontrol(theFig, 'Style','checkbox ', 'Units','pixels', ...
						'String', 'From Talairach to MNI', ...
						'Value', 0, 'Visible', 'on',...
						'BackgroundColor', get(theFig,'Color'), ...
						'Enable', 'on', ...						
						'Position',[theLeft, 15, 180,20]);
		
	theLeft =OffsetX+MarginX+30+MarginX+30+MarginX+30+MarginX; theBottom =OffsetY+MarginY+35+MarginY/2;
	uicontrol(theFig, 'Style','text', 'Units','pixels', ...
			  'String', 'Radius(mm)', ...
			  'BackgroundColor', get(theFig,'Color'), ...
			  'Position',[theLeft+32, theBottom, 60,15]);
	theLeft =OffsetX+MarginX+30+MarginX+30+MarginX+30+MarginX; theBottom =OffsetY+MarginY+20;		  
	hEditRadius =uicontrol(theFig, 'Style','edit', 'Units','pixels', ...
							  'String', int2str(AROIRadius), ...
							  'BackgroundColor', 'yellow', ...
							  'Callback', theEditCallbackFcn, ...
							  'Position',[theLeft+32, theBottom, 60,20]);
	

	
	hbtnClose=uicontrol(theFig,'Style', 'pushbutton', 'Units', 'pixels', ...
						'Position', [195 10 50 25], ...
						'FontSize', 10, ...
						'String', 'Ok', ...
						'Callback', 'rest_Y_SphereROI(''SetAndQuit'');');
	
	%Attention!!!	20071122
	theLeft =OffsetX+MarginX; theBottom =OffsetY+MarginY+35+MarginY/2;
	uicontrol(theFig, 'Style','text', 'Units','pixels', ...
			  'String', sprintf('Attention:\nFor NIFTI images (e.g., preprocessed by SPM5 or above version), just type in the MNI coordinates, i.e. positive x value means right hemisphere of brain, which displayed in the left side in REST Slice Viewer (REST Slice Viewer displayed in Radiology convention).\n\nFor ANALYZE images (e.g., preprocessed by SPM2), please check the correspondence between x value and left/right hemisphere in REST Slice Viewer because ANALYZE images do not contain left/right information!!!'), ...  %YAN Chao-Gan 091215. %'String', sprintf('Attention:\nPositive X means left and negative X means right in SliceViewer''s image!!!'), ...
			  'HorizontalAlignment', 'left', ...
			  'BackgroundColor', get(theFig,'Color'), ...			  
			  'ForegroundColor', 'red', ...
			  'FontWeight', 'bold', ... %			  'Callback', 'rest_misc( ''Attention_Coordinates'');', ...	%Not work!!!
			  'Position',[theLeft, theBottom+25, 230,15*15]);  %YAN Chao-Gan 091215. %'Position',[theLeft, theBottom+25, 230,15*3]);

	
	%Save to config
	theConfig.hFig			=theFig;			%handle of the config
	theConfig.hEditPositionX =hEditPositionX;
	theConfig.hEditPositionY =hEditPositionY;
	theConfig.hEditPositionZ =hEditPositionZ;
	theConfig.hEditRadius 	=hEditRadius;
	theConfig.hTal2Mni 		=hTal2Mni;
		
	Result =theConfig;
	set(theFig, 'Visible', 'on');
	
function Result =Ball2Mask(ABrainSize, AVoxelSize, AROICenter, AROIRadius, Header);
    AOrigin=Header.Origin;	
    mask =zeros(ABrainSize); %ABrainSize, such as [61, 73, 61]

    AROICenter=reshape(AROICenter, 1,length(AROICenter));
	
    % Revised by YAN Chao-Gan 101010
    if isfield(Header,'mat')
        AROICenter=round(inv(Header.mat)*[AROICenter,1]');
        AROICenter=AROICenter(1:3);
        AROICenter=reshape(AROICenter, 1,length(AROICenter));
    else
        AROICenter =round(-1*AROICenter./AVoxelSize) +AOrigin;%Revised by dawnsong, 20070904
    end
	
	radiusX =round(AROIRadius /AVoxelSize(1));
	if (AROICenter(1)-radiusX)>=1 && (AROICenter(1)+radiusX)<=ABrainSize(1)
		rangeX	=(AROICenter(1)-radiusX):(AROICenter(1)+radiusX);
	elseif (AROICenter(1)-radiusX)<1 && (AROICenter(1)+radiusX)<=ABrainSize(1)
		rangeX	=1:(AROICenter(1)+radiusX);
	elseif (AROICenter(1)-radiusX)>=1 && (AROICenter(1)+radiusX)>ABrainSize(1)
		rangeX	=(AROICenter(1)-radiusX):ABrainSize(1);
	else
		rangeX =1:ABrainSize(1);
	end
	
	radiusY =round(AROIRadius /AVoxelSize(2));
	if (AROICenter(2)-radiusY)>=1 && (AROICenter(2)+radiusY)<=ABrainSize(2)
		rangeY	=(AROICenter(2)-radiusY):(AROICenter(2)+radiusY);
	elseif (AROICenter(2)-radiusY)<1 && (AROICenter(2)+radiusY)<=ABrainSize(2)
		rangeY	=1:(AROICenter(2)+radiusY);
	elseif (AROICenter(2)-radiusY)>=1 && (AROICenter(2)+radiusY)>ABrainSize(2)
		rangeY	=(AROICenter(2)-radiusY):ABrainSize(2);
	else
		rangeY =1:ABrainSize(2);
	end
	
	radiusZ =round(AROIRadius /AVoxelSize(3));
	if (AROICenter(3)-radiusZ)>=1 && (AROICenter(3)+radiusZ)<=ABrainSize(3)
		rangeZ	=(AROICenter(3)-radiusZ):(AROICenter(3)+radiusZ);
	elseif (AROICenter(3)-radiusZ)<1 && (AROICenter(3)+radiusZ)<=ABrainSize(3)
		rangeZ	=1:(AROICenter(3)+radiusZ);
	elseif (AROICenter(3)-radiusZ)>=1 && (AROICenter(3)+radiusZ)>ABrainSize(3)
		rangeZ	=(AROICenter(3)-radiusZ):ABrainSize(3);
	else
		rangeZ =1:ABrainSize(3);
	end
	
	for x=rangeX, for y=rangeY, for z=rangeZ,
		%Ball Definition, Computing within a cubic to minimize the time to be consumed
		if norm(([x, y, z] -AROICenter).*AVoxelSize)<=AROIRadius,
			mask(x, y, z) =1;
		end
	end; end; end;
	
	Result =mask;	
	

	