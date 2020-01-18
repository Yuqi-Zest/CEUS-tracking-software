function varargout = objectTracking(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @objectTracking_OpeningFcn, ...
    'gui_OutputFcn',  @objectTracking_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --------------------------------------------------------------------

% --- Executes just before objectTracking is made visible.
function objectTracking_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to objectTracking (see VARARGIN)
handles=resetParentFigure(handles);
% Choose default command line output for objectTracking
set(hObject,'CloseRequestFcn',@closereq);
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes objectTracking wait for user response (see UIRESUME)
% uiwait(handles.figure1);
% --------------------------------------------------------------------

% --- Outputs from this function are returned to the command line.
function varargout = objectTracking_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function  handles=resetParentFigure(handles)
if isfield(handles,'timer')
    delete(handles.DefVar.timers);
end
handles.DefVar=[];
handles.TackingOn.Value=1;
handles.autoA.Value=0;
handles.Mirror.Value=0;
set(handles.figure1,'Resize','on');
handles.DefVar.path=pwd;
stringCell={'I','II','III','IV','V','VI','VII','VIII'};
for i=1:length(stringCell)
    BO=eval(['handles.',stringCell{i}]);
    BO.BackgroundColor=[0.9,0.9,0.9];
end
handles.DefVar.EightColor=[1,0,0;1,0.65,0;1,1,0;0,1,0;0,1,1;0,0,1;0.545,0,1;0,0,0];
ax=findobj(handles.figure1,'type','uicontrol');
set(ax,'Enable','off');
handles.FlowLast.Enable='off';
handles.FlowNext.Enable='off';
handles.Mirror.Enable='off';
ax=findobj(handles.figure1,'type','axes');
for i=1:length(ax)
    cla(ax(i));
end

function closereq(varargin)
source=varargin{1};
handles=guidata(source);
if isfield(handles.DefVar,'fullname')&&~isempty(handles.DefVar.fullname)
    selection = questdlg('Whether to exit and save？','Close Request',{'Yes','No','Cancel'});
    if strcmp(selection,'Yes')
        saveMat(handles);
    elseif strcmp(selection,'Cancel')
        return;
    end
end
if isfield(handles.DefVar,'timer')
    delete(handles.DefVar.timer);
end
handles.DefVar=[];
delete(handles.figure1);


function saveMat(handles)
fullname=handles.DefVar.fullname;
RectsArray=handles.DefVar.RectsArray;
FrameNumsArray=handles.DefVar.FrameNumsArray;
LeftIsZaoying=handles.LeftIsZaoying.Value;
ZaoyingPos=handles.DefVar.ZaoyingPos;
ErweiPos=handles.DefVar.ErweiPos;
%ShuangfuTimeSeries=handles.DefVar.ShuangfuTimeSeries;
% BofangTimeSeries= handles.DefVar.BofangTimeSeries;
% time_array= handles.DefVar.time_array;
% vx= handles.DefVar.vx;
flowRecommand=handles.DefVar.flowRecommand;
RecommandPic= handles.DefVar.RecommandPic;
ShotingPic=handles.DefVar.ShotingPic;
[pathstr,name,~]=fileparts(fullname);
sep=filesep;
tempath=strcat(pathstr,sep,name);
uisave({'fullname','RectsArray','FrameNumsArray','LeftIsZaoying',...
    'ZaoyingPos','ErweiPos','ShotingPic','RecommandPic','flowRecommand'},tempath);



% --------------------------------------------------------------------
function LoadVideo_Callback(hObject, eventdata, handles)
% hObject    handle to LoadVideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'DefVar')&&isfield(handles.DefVar,'pic')&& ~okToClearExisting()
    return
else
    handles=resetParentFigure(handles);
end

path=handles.DefVar.path;
if exist([path,'\ObjectTrackingConfig.mat'],'file')
    confg=open([path,'\ObjectTrackingConfig.mat']);
    if isfield(confg,'Defaultdir')&&exist(confg.Defaultdir,'dir')
        path=confg.Defaultdir;
    end
end
[ReadVideoFileName,Defaultdir,ReadVideoFilterIndex] = uigetfile({'*.avi;*.mp4;*.wmv','VideoFile(*.avi,*.mp4,*.wmv)';'*.avi','AVIVideoFile(*.avi)';'*.*','AllFile(*.*)'},'ReadVideo',...
    'MultiSelect','off',path); %设置默认路径
if isequal(ReadVideoFileName,0) || isequal(Defaultdir,0) || isequal(ReadVideoFilterIndex,0)
    msgbox('Failed to import video, click OK to close the dialog and re-import');
    return;
else
    %只读入一个视频
    fullname=fullfile( Defaultdir,ReadVideoFileName);%视频完整路径
    if exist([handles.DefVar.path,'\ObjectTrackingConfig.mat'],'file')
        save([handles.DefVar.path,'\ObjectTrackingConfig.mat'],'Defaultdir','-append');
    else
        save([handles.DefVar.path,'\ObjectTrackingConfig.mat'],'Defaultdir');
    end
    hData = VideoReader(fullname);
    frames=hData.NumberOfFrames;
    if frames>1
        pic=read(hData,1);
    else
        msgbox('Failed to import video, click OK to close the dialog and re-import');
        return;
    end
    screenSize=get(0,'screensize');
    whratio=hData.Width*1.0/hData.Height;
    handles.DefVar.flowRecommand=[];
    %     handles.DefVar.ShuangfuTimeSeries=[];
    %     handles.DefVar.BofangTimeSeries=[];
    %     handles.DefVar.time_array=[];
    %     handles.DefVar.vx=[];
    handles.DefVar.ZaoyingPos=[];
    handles.DefVar.ErweiPos=[];
    handles.DefVar.fullname=fullname;
    if  screenSize(4)*whratio<screenSize(3)
        fig2=screenSize(4)*0.05;
        fig4=screenSize(4)*0.9;
        fig3=screenSize(4)*0.9*whratio;
        fig1=screenSize(3)*0.5-fig3*0.5;
        
    else
        fig1=screenSize(3)*0.05;
        fig3=screenSize(3)*0.9;
        fig4=screenSize(3)*0.9/whratio;
        fig2=screenSize(4)*0.5-fig3*0.5;
    end
    if isfield(handles,'posAxes1')
        set(handles.ObjectTrackingAxes1,'OuterPosition',handles.posAxes1);
    end
    set(handles.figure1,'Resize','off','unit','pixels','Position',[fig1 fig2 fig3 fig4]);
    
    %         handles.htablePanel=uipanel(handles.hfigure,'unit','normalized',...
    %                                     'position',[0 0.5 0.4 0.5]);
    
    handles.DefVar.hData=hData;
    %      set(hfigure,'deleteFcn',"load('base','pic',pic)");
    handles.DefVar.fullname=fullname;
    xRate=1.0;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%控制播放速率
    handles.DefVar.frameRate=xRate*hData.frameRate;
    %fix(hData.FrameRate*hData.currentTime+1);
    handles.DefVar.currentFrameNum=1;
    handles.DefVar.currentTime=hData.CurrentTime;
    set(handles.VedioDuration,'String',[num2str(floor(hData.Duration/60)),'  Min',num2str(roundn(hData.Duration-fix(hData.Duration/60)*60,-2)),'  Sec']);
    set(handles.ImageHeight,'String',num2str(hData.Height));
    set(handles.ImageWidth,'String',num2str(hData.Width));
    set(handles.CurrentMin,'String',num2str(floor(handles.DefVar.currentTime/60)));
    set(handles.CurrentSec,'String',num2str(roundn(handles.DefVar.currentTime-fix(handles.DefVar.currentTime/60)*60,-2)));
    set(handles.ObjectTrackingAxes1,'unit','pixels');
    
    posAxes1=get(handles.ObjectTrackingAxes1,'OuterPosition');
    handles.posAxes1=posAxes1;
    
    if posAxes1(3)*1.00/posAxes1(4)>whratio
        set(handles.ObjectTrackingAxes1,'OuterPosition',[ posAxes1(1)+( posAxes1(3)- posAxes1(4)*whratio)/2, posAxes1(2), posAxes1(4)*whratio, posAxes1(4)]);
    else
        set(handles.ObjectTrackingAxes1,'OuterPosition',[ posAxes1(1), posAxes1(2)+( posAxes1(3)*1.0/whratio- posAxes1(4))/2, posAxes1(3), posAxes1(3)*1.0/ whratio]);
    end
    handles.DefVar.pic=pic;
    set(handles.ObjectTrackingAxes1,'YTick',[],'XTick',[],'XTickLabel',[],'YTickLabel',[]);
    image(handles.DefVar.pic,'Parent',handles.ObjectTrackingAxes1,'PickableParts','visible','HitTest','off');
    set(handles.ObjectTrackingAxes1,'YTick',[],'XTick',[],'XTickLabel',[],'YTickLabel',[]);
    
    handles.DefVar.timer=timer('Name','controlVideo',...
        'Period',1.0/handles.DefVar.frameRate,...
        'StartDelay',0,...
        'TasksToExecute',inf,...
        'ExecutionMode','fixedSpacing',...
        'TimerFcn',{@timecall,handles.ObjectTrackingAxes1},...
        'StartFcn',{@timerstarcall,handles.ObjectTrackingAxes1},...
        'StopFcn',{@timerstopcall,handles.ObjectTrackingAxes1});
    set(handles.figure1,'deleteFcn',@figuredelete);
    set(handles.VideoPlaySlider,'value',handles.DefVar.currentFrameNum,'min',1,'max',frames);
    c=uicontextmenu;
    uimenu(c,'label','Next Picture','callback',@cmenu_call,'Tag','Menu');
    uimenu(c,'label','Previous picture','callback',@cmenu_call,'Tag','Menu');
    uimenu(c,'label','Next second picture','callback',@cmenu_call,'Tag','Menu');
    uimenu(c,'label','Last second picture','callback',@cmenu_call,'Tag','Menu');
    uimenu(c,'label','Next Shoting picture','callback',@cmenu_call,'Tag','Menu');
    uimenu(c,'label','Previous Shoting Picture','callback',@cmenu_call,'Tag','Menu');
    handles.ObjectTrackingAxes1.UIContextMenu=c;
    a=[0,0,0,0,0,0,0,0];
    handles.DefVar.RectsArray=mat2cell(a',a+1);
    handles.DefVar.FrameNumsArray=mat2cell(a',a+1);
    handles.DefVar.ShotingPic=zeros(20,frames,3)+1;
    handles.DefVar.imRect=[];
    handles.DefVar.imRectM=[];
    ax=findobj('parent',handles.figure1,'type','uicontrol');
    set(ax,'Enable','on');
    handles.FlowLast.Enable='off';
    handles.FlowNext.Enable='off';
    handles.Mirror.Enable='off';
    guidata(hObject,handles);
    
end

function tf = okToClearExisting()
tf = false;

selectedStr = questdlg( 'Delete the current workspace and open a new file','Open a new video file',...
    'Yes', 'No' ,'No');
if(strcmp(selectedStr, 'Yes'))
    tf = true;
end

function []=figuredelete(varargin)
tmr= timerfind('Name','controlVideo');
delete(tmr);
obj=varargin{1};
handles=guidata(obj);
h= findobj(handles);
for i=1:length(h)
    delete(h(i));
end
guidata(obj,handles);


function []=timerstarcall(varargin)
%    hfigure=gcf;
% handles=guidata(hfigure);
obj=varargin{3};
handles=guidata(obj);
handles.CurrentMin.Enable='off';
handles.CurrentSec.Enable='off';
handles.ObjectTrackingAxes1.Visible='off';
guidata(obj,handles);

function []=timerstopcall(varargin)
% hfigure=gcf;
% handles=guidata(hfigure);
obj=varargin{3};
handles=guidata(obj);
handles.CurrentMin.Enable='on';
handles.CurrentSec.Enable='on';
handles.ObjectTrackingAxes1.Visible='on';
handles.playControler.String='Play';
guidata(obj,handles);

function []=timecall(varargin)
obj=varargin{3};
tmr=varargin{1};
% if ~strcmp(hfigure(1).Name,'objectTracking')
%     stop(tmr);   %%%%应该关闭time
%     return;
% end
handles=guidata(obj);
hdata=handles.DefVar.hData;
currentframenum=handles.DefVar.currentFrameNum;
currenttime=handles.DefVar.currentTime;
if currentframenum<handles.DefVar.hData.NumberOfFrames
    currentframenum=currentframenum+1;
    currenttime=currenttime+tmr.Period;
else
    currentframenum=1;
    currenttime=0.0;
end
handles.DefVar.pic=read(hdata,currentframenum);
image(handles.DefVar.pic,'Parent',handles.ObjectTrackingAxes1,'PickableParts','visible','HitTest','off');
set(handles.ObjectTrackingAxes1,'YTick',[],'XTick',[],'XTickLabel',[],'YTickLabel',[]);
handles.VideoPlaySlider.String=[num2str(roundn(currentframenum*1.0/hdata.NumberOfFrames*100,-2)),'%'];
handles.DefVar.currentTime=currenttime;
handles.DefVar.currentFrameNum=currentframenum;
[ShotingNum,ShotingFrameIdx]=findShotingNum( handles.DefVar.currentFrameNum,handles.DefVar.FrameNumsArray);
set(handles.CurrentMin,'String',num2str(floor(handles.DefVar.currentTime/60)));
set(handles.CurrentSec,'String',num2str(roundn(handles.DefVar.currentTime-fix(handles.DefVar.currentTime/60)*60,-2)));
set(handles.VideoPlaySlider,'value',handles.DefVar.currentFrameNum);
stringCell={'I','II','III','IV','V','VI','VII','VIII'};
for i=1:length(stringCell)
    if handles.DefVar.FrameNumsArray{i}(1)>0
        BO=eval(['handles.',stringCell{i}]);
        BO.BackgroundColor=[1,0,0];
    end
end

if ~isempty(ShotingNum)
    for i=1:length(ShotingNum)
        BO=eval(['handles.',stringCell{ShotingNum(i)}]);
        getImRect(BO,handles,ShotingNum(i),ShotingFrameIdx(i));
        handles=guidata(BO);
    end
else
    handles.DefVar.imRect=[];
    handles.DefVar.imRectM=[];
end
guidata(obj,handles);

function []=videoControl(varargin)
obj=varargin{1};
handles=guidata(obj);
hdata=handles.DefVar.hData;
framerate=hdata.frameRate;
frames=hdata.NumberOfFrames;
currenttime=handles.DefVar.currentTime;
% currentframenum=handles.DefVar.currentFrameNum;
switch obj.Tag
    case 'VideoPlaySlider'
        currentframenum=fix(obj.Value);
        currenttime=roundn(currentframenum/framerate,-2);
        %     case  'listbox'
        %         ratelist={1 0.2 2 4 8 16};
        %          handles.xRate=ratelist{obj.Value};
        %          htableData{6}=[num2str(handles.xRate),'倍'];
    case 'CurrentMin'
        currentf=str2double(obj.String);
        if isnan(currentf)||currentf<0||currentf>floor(handles.DefVar.hData.Duration/60)
            obj.String=num2str(floor(currenttime/60));
            guidata(obj,handles);
            return;
        end
        timenow=currentf*60+currenttime-floor(currenttime/60)*60;
        currentframenum=max(min(fix(timenow*handles.DefVar.hData.FrameRate),frames),1);
        %obj.String=[num2str(roundn(currentframenum*1.0/frames*100,-2)),'%'];
        currenttime=roundn(timenow,-3);
        
    case 'CurrentSec'
        currentf=str2double(obj.String);
        if isnan(currentf)||currentf<0||currentf>60
            obj.String=num2str(roundn(currenttime-floor(currenttime/60)*60,-3));
            guidata(obj,handles);
            return;
        end
        timenow=currentf+floor(currenttime/60)*60;
        currentframenum=max(min(fix(timenow*framerate),frames),1);
        %obj.String=roundn(currentf,-3);
        currenttime=roundn(currentframenum/framerate,-2);
        
    case 'FlowLast'
        if ~isempty(handles.DefVar.flowRecommand)
            A=handles.DefVar.flowRecommand(:,2);
            C=find(A<currenttime);
            if ~isempty(C)
                currenttime=(handles.DefVar.flowRecommand(C(end),1)+handles.DefVar.flowRecommand(C(end),2))/2;
            else
                errordlg('No last light flow suggested position');
                return;
            end
        else
            errordlg('No optical flow suggested location, please run automatic analysis');
            return;
        end
        
    case 'FlowNext'
        if ~isempty(handles.DefVar.flowRecommand)
            A=handles.DefVar.flowRecommand(:,1);
            C=find(A>currenttime);
            if ~isempty(C)
                currenttime=(handles.DefVar.flowRecommand(C(1),1)+handles.DefVar.flowRecommand(C(1),2))/2;
            else
                errordlg('No Next light flow suggested position');
                return;
            end
        else
            errordlg('No optical flow suggested location, please run automatic analysis');
            return;
        end
end
if ~isempty(handles.ObjectTrackingAxes1)
    currentframenum=max(floor(currenttime*framerate),1);
    handles.VideoPlaySlider.Value=currentframenum;
    set(handles.CurrentMin,'String',num2str(floor(currenttime/60)));
    set(handles.CurrentSec,'String',num2str(roundn(currenttime-fix(currenttime/60)*60,-2)));
    handles.DefVar.currentFrameNum=min(max(fix(currentframenum),1),frames);
    handles.DefVar.currentTime=currenttime;
    handles.DefVar.pic=read(handles.DefVar.hData,currentframenum);
    [ShotingNum,ShotingFrameIdx]=findShotingNum( handles.DefVar.currentFrameNum,handles.DefVar.FrameNumsArray);
    image(handles.DefVar.pic,'Parent',handles.ObjectTrackingAxes1,'PickableParts','visible','HitTest','off');
    set(handles.ObjectTrackingAxes1,'YTick',[],'XTick',[],'XTickLabel',[],'YTickLabel',[]);
    stringCell={'I','II','III','IV','V','VI','VII','VIII'};
    for i=1:length(stringCell)
        if handles.DefVar.FrameNumsArray{i}(1)>0
            BO=eval(['handles.',stringCell{i}]);
            BO.BackgroundColor=[1,0,0];
        end
    end
    if ~isempty(ShotingNum)
        for i=1:length(ShotingNum)
            BO=eval(['handles.',stringCell{ShotingNum(i)}]);
            getImRect(BO,handles,ShotingNum(i),ShotingFrameIdx(i));
            handles=guidata(BO);
        end
    else
        handles.DefVar.imRect=[];
        handles.DefVar.imRectM=[];
    end
    guidata(obj,handles);
end

function []=cmenu_call(varargin)
cmenu=varargin{1};
if strcmp(cmenu.Tag,'Menu')
    A=cmenu.Text;
    B={'Next picture','Previous picture','Last second picture','Next second picture','Next Shoting picture','Previous Shoting Picture'};
else
    A=cmenu.String;
    B={'Next picture','Last picture','Last second','Next second','a','b'};
end
handles=guidata(cmenu);
hdata=handles.DefVar.hData;
duration=hdata.Duration;
framerate=hdata.frameRate;
frames=hdata.NumberOfFrames;
currenttime=handles.DefVar.currentTime;
currentframenum=handles.DefVar.currentFrameNum;
switch A
    case B{1}
        if currentframenum==hdata.NumberOfFrames
            handles.DefVar.currentTime=duration;
            errordlg('The picture is already the last one！！！');
            return;
        else
            currenttime=min(roundn(currenttime+1.0/framerate,-2),duration);
            handles.DefVar.currentFrameNum=fix(handles.DefVar.currentFrameNum+1);
            handles.DefVar.currentTime=currenttime;
        end
    case B{2}
        if currentframenum>=2
            handles.DefVar.currentFrameNum=fix(handles.DefVar.currentFrameNum-1);
            handles.DefVar.currentTime=max(roundn(handles.DefVar.currentTime-1.0/framerate,-2),0.0);
        else
            errordlg('The picture is the first！！！');
            return;
        end
    case B{3}
        if currentframenum> framerate
            handles.DefVar.currentFrameNum=max(fix(currentframenum-framerate),1);
            handles.DefVar.currentTime=max(currenttime-1,1.0/framerate);
        else
            handles.DefVar.currentTime=0.0;
            handles.DefVar.currentFrameNum=1;
        end
        
    case B{4}
        if frames-framerate>currentframenum
            handles.DefVar.currentTime=currenttime+1;
            handles.DefVar.currentFrameNum=min(fix(currentframenum+framerate),frames);
        else
            handles.DefVar.currentTime=duration;
            handles.DefVar.currentFrameNum=fix(frames);
        end
        
    case B{5}
        [ShotingNum,ShotingFrameIdx]=findNextShotingNum(currentframenum,handles.DefVar.FrameNumsArray);
        if ShotingNum==0
            return;
        else
            handles.DefVar.currentFrameNum=handles.DefVar.FrameNumsArray{ShotingNum}(ShotingFrameIdx);
            handles.DefVar.currentTime=roundn(handles.DefVar.currentFrameNum/framerate,-3);
        end
    case B{6}
        [ShotingNum,ShotingFrameIdx]=findLastShotingNum(currentframenum,handles.DefVar.FrameNumsArray);
        if ShotingNum==0
            return;
        else
            handles.DefVar.currentFrameNum=handles.DefVar.FrameNumsArray{ShotingNum}(ShotingFrameIdx);
            handles.DefVar.currentTime=roundn(handles.DefVar.currentFrameNum/framerate,-3);
        end
end

handles.DefVar.pic= read(hdata,handles.DefVar.currentFrameNum);
[ShotingNum,ShotingFrameIdx]=findShotingNum( handles.DefVar.currentFrameNum,handles.DefVar.FrameNumsArray);
image(handles.DefVar.pic,'Parent',handles.ObjectTrackingAxes1,'PickableParts','visible','HitTest','off');
set(handles.ObjectTrackingAxes1,'YTick',[],'XTick',[],'XTickLabel',[],'YTickLabel',[]);
stringCell={'I','II','III','IV','V','VI','VII','VIII'};
for i=1:length(stringCell)
    if handles.DefVar.FrameNumsArray{i}(1)>0
        BO=eval(['handles.',stringCell{i}]);
        BO.BackgroundColor=[1,0,0];
    end
end
if ~isempty(ShotingNum)
    for i=1:length(ShotingNum)
        BO=eval(['handles.',stringCell{ShotingNum(i)}]);
        getImRect(BO,handles,ShotingNum(i),ShotingFrameIdx(i));
        handles=guidata(BO);
    end
else
    handles.DefVar.imRect=[];
    handles.DefVar.imRectM=[];
end
set(handles.CurrentMin,'String',num2str(floor(handles.DefVar.currentTime/60)));
set(handles.CurrentSec,'String',num2str(roundn(handles.DefVar.currentTime-fix(handles.DefVar.currentTime/60)*60,-2)));
set(handles.VideoPlaySlider,'value',handles.DefVar.currentFrameNum);
guidata(cmenu,handles);

function  [ShotingNum,ShotingFrameNum]=findNextShotingNum(currentframenum,FrameNumsArray)
ShotingNum=0;
ShotingFrameNum=0;
minb=1000000;
for i=1:length(FrameNumsArray)
    if FrameNumsArray{i}(1)>currentframenum&&FrameNumsArray{i}(1)<minb
        minb=FrameNumsArray{i}(1);
        ShotingNum=i;
        ShotingFrameNum=minb;
    end
end



function  [ShotingNum,ShotingFrameNum]=findLastShotingNum(currentframenum ,FrameNumsArray)
ShotingNum=0;
ShotingFrameNum=0;
maxb=0;
for i=1:length(FrameNumsArray)
    if FrameNumsArray{i}(1)~=0&&FrameNumsArray{i}(end)<currentframenum&&FrameNumsArray{i}(end)>maxb
        ShotingNum=i;
        ShotingFrameNum=FrameNumsArray{i}(end);
        maxb=ShotingFrameNum;
    end
end



function  [ShotingNum,ShotingFrameNum]=findShotingNum(currentframenum , FrameNumsArray)
ShotingNum=zeros(size(FrameNumsArray));
ShotingFrameNum=ShotingNum;
for i=1:length(FrameNumsArray)
    a=find(FrameNumsArray{i}==currentframenum);
    if ~isempty(a)
        ShotingNum(i)=i;
        ShotingFrameNum(i)=a(1);
    end
end
ShotingNum=find(ShotingNum);
ShotingFrameNum=ShotingFrameNum(ShotingNum);
%     if i==length(FrameNumsArray)&&j==length(FrameNumsArray{i})&&currentframenum~=FrameNumsArray{i}(j)
%         ShotingNum=0;
%         ShotingFrameNum=0;
%     else
%         ShotingNum=i;
%         ShotingFrameNum=j;
%     end



function [ableToAuto,ShuangfuTimeSeries,BofangTimeSeries,time_array,vx,out_series,pos_left,pos_right]=get_good_frame(video_path,leftIsErwei)
ShuangfuTimeSeries=[];
BofangTimeSeries=[];
series=[];
ableToAuto=false;
isone_array=[];
time_array=[];
hData= VideoReader(video_path);
pos_right=[0,0,0,0];pos_left=[0,0,0,0];
vx=[];
out_series={};
% leftIsErwei=true;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
picBefore=readFrame(hData);
Zanting=[];
diff=[];
totalImag=zeros(size(picBefore,1),size(picBefore,2));
while hasFrame(hData)&&hData.CurrentTime<(hData.Duration-0.3)
    vidFrame=readFrame(hData);
    time_array=[time_array,hData.CurrentTime];
    hData.CurrentTime=hData.CurrentTime+0.2;%%%%%%%%%%%%%%%%%%%%%%%采样时间间隔
    absDiff=rgb2gray(abs(vidFrame-picBefore));
    diff=[diff,mean(absDiff(:))];
    picBefore=vidFrame;
    if mean(absDiff)<1
        Zanting=[Zanting,1];
    else
        Zanting=[Zanting,0];
        totalImag=totalImag+im2double(absDiff);
    end
end

if length(Zanting)>1
    series2=get_series(Zanting,0.5,5);
    s=size(series2,1);
    if s>1
        series=series2(1,:);
        i=2;
        while i<=s
            if (series2(i,1)-series(end,2))<5
                if size(series,1)==1
                    series=[series(1,1),series2(i,2)];
                else
                    a=series(1:end-1,:);
                    series=[a;[series(end,1),series2(i,2)]];
                end
            else
                series=[series;[series2(i,1),series2(i,2)]];
            end
            i=i+1;
        end
    elseif s==1
        series=series2;
    else
        return;
    end
    for kl=1:size(series,1)
        BofangTimeSeries=[BofangTimeSeries;series(kl,1),series(kl,2)];%%%%%%%%%%%%%%%
    end
else
    return;
end

maxV=max(totalImag(:));
minV=min(totalImag(:));
totalImag=(totalImag-minV)./(maxV-minV);
if ~one_or_two_side(totalImag,0.03)
    [pos_left,pos_right]= crop_image(totalImag,0.03);
    if isempty(pos_left)
        return;
    end
else
    return;
end
pos=[pos_left(1),pos_left(2),pos_left(3)*0.6,min(pos_left(3),pos_left(4))];
isone_array=zeros(length(time_array),1)+1;
for i=1:size(BofangTimeSeries,1)
    for j=BofangTimeSeries(i,1):5:BofangTimeSeries(i,2)
        hData.CurrentTime=time_array(j);
        pic=rgb2gray(imcrop(readFrame(hData),pos));
        pic=pic(:);
        if sum(pic>30)>pos(3)*pos(4)*0.3
            for k=0:4
                isone_array(j+k)=0;
            end
        end
    end
end
% plot(isone_array);
series2=get_series(isone_array,0.5,20);
if ~isempty(series2)
    s=size(series2,1);
    if s>=1
        series=series2(1,:);
        i=2;
        while i<=s
            if (series2(i,1)-series(end,2))<20
                if size(series,1)==1
                    series=[series(1,1),series2(i,2)];
                else
                    a=series(1:end-1,:);
                    series=[a;[series(end,1),series2(i,2)]];
                end
            else
                series=[series;[series2(i,1),series2(i,2)]];
            end
            i=i+1;
        end
        for kl=1:size(series,1)
            ShuangfuTimeSeries=[ShuangfuTimeSeries;series(kl,1),series(kl,2)];%%%%%%%%%%%%%%%
        end
    elseif s==0
        return;
    end
else
    return;
end
hData= VideoReader(video_path);
vx=zeros(length(time_array),1);
if leftIsErwei
    posA=pos_left;
else
    posA=pos_right;
end

for k=1:size(ShuangfuTimeSeries,1)
    opticFlow = opticalFlowLKDoG('NumFrames',3,'ImageFilterSigma',3,'GradientFilterSigma',2,'NoiseThreshold',0.0001);
    hData.CurrentTime=time_array(ShuangfuTimeSeries(k,1));
    for  ml=ShuangfuTimeSeries(k,1):ShuangfuTimeSeries(k,2)
        if ml>size(time_array,1)
            ShuangfuTimeSeries(k,2)=size(time_array,1);
            continue;
        end
        hData.CurrentTime=time_array(ml);
        vidFrame=readFrame(hData);
        img=imcrop(vidFrame,posA);
        frameGray=im2double(rgb2gray(img));
        flow = estimateFlow(opticFlow,frameGray);
        vx(ml)=sum(flow.Magnitude(:));
    end
    A=get_series(vx(ShuangfuTimeSeries(k,1):ShuangfuTimeSeries(k,2)),mean(vx(ShuangfuTimeSeries(k,1):ShuangfuTimeSeries(k,2))),10);
    if isempty(A)
        continue;
    else
        out_series=[out_series;A+(ShuangfuTimeSeries(k,1)-1)];
    end
end
ableToAuto=true;


function [vx]=optflow(time_array,hData,posA,begin,iend)
opticFlow = opticalFlowLKDoG('NumFrames',3,'ImageFilterSigma',3,'GradientFilterSigma',2,'NoiseThreshold',0.0001);
for  ml=begin:iend
    hData.CurrentTime=time_array(ml);
    vidFrame=readFrame(hData);
    img=imcrop(vidFrame,posA);
    frameGray=im2double(rgb2gray(img));
    flow = estimateFlow(opticFlow,frameGray);
    vx(ml)=sum(flow.Magnitude(:));
end

function series=get_series(flowMagnitude,threshM,picNum)%%plot_hht(注意路径）
series=[];
i=1;
while i<=length(flowMagnitude)
    series=[series;i,i];
    if flowMagnitude(i)>=threshM
        i=i+1;
    end
    while  i<=length(flowMagnitude)&&flowMagnitude(i)<threshM
        series(size(series,1),2)=i;
        i=i+1;
    end
    if series(size(series,1),2)-series(size(series,1),1)<picNum
        series=series(1:size(series,1)-1,:);
    end
end
% mea=mean(flowMagnitude);
% st=std(flowMagnitude);
% flowMagnitude(flowMagnitude>3*mea)=0;
%figure;
% plot(flowMagnitude);
% hold on;
% array=zeros(length(flowMagnitude),1);
% for i=1:size(series,1)
%     array(series(i,1):series(i,2))=mea;
% end
% plot(array);
% hold off;


function [pos_left,pos_right]= crop_image(img1,thresh)%%%%%%must be gray
img1=padarray(img1,[8,8],0);
if length(size(img1))==3
    image_mask=rgb2gray(img1);
else
    image_mask=img1;
end
bw=edge(image_mask,'Sobel');
[H,theta,rho]=hough(bw);
Peaks=houghpeaks(H,12,'NHoodSize',[5,5],'Threshold',ceil(0.1*max(H(:))));
lines=houghlines(bw,theta,rho,Peaks);
% figure
% imshow(img1);
% imshow(bw);
% hold on
% for k=1:length(lines)
% xy=[lines(k).point1;lines(k).point2];
% plot(xy(:,1),xy(:,2),'LineWidth',2);
% end
% hold off;
y_max=0;
x_max=0;
y_min=5000;
x_min=5000;
for k=1:length(lines)
    if lines(k).theta==0
        if lines(k).point1(1)>x_max
            x_max=lines(k).point1(1);
        end
        if lines(k).point1(1)<x_min
            x_min=lines(k).point1(1);
        end
        if lines(k).point1(2)>y_max
            y_max=lines(k).point1(2);
        end
        if lines(k).point1(2)<y_min
            y_min=lines(k).point1(2);
        end
        if lines(k).point2(2)>y_max
            y_max=lines(k).point2(2);
        end
        if lines(k).point2(2)<y_min
            y_min=lines(k).point2(2);
        end
    end
end
pos=[x_min,y_min,x_max-x_min,y_max-y_min];
if  pos(3)*pos(4)>size(img1,1)*size(img1,2)*0.15&&pos(3)>0.4*size(img1,1)
    if pos(2)<size(img1,2)*0.5&&withInRect([pos(1),pos(2),pos(3)*2,pos(4)],[9,9,size(img1,2)-18,size(img1,1)-18])
        pos_left=[pos(1)-8,pos(2)-8,pos(3),pos(4)];
        pos_right=[pos(1)+pos(3)-8,pos(2)-8,pos(3),pos(4)];
        return;
        
    elseif withInRect([pos(1)-pos(3),pos(2),pos(3)*2,pos(4)],[9,9,size(img1,2)-18,size(img1,1)-18])
        pos_left=[pos(1)-pos(3)-8,pos(2)-8,pos(3),pos(4)];
        pos_right=[pos(1)-8,pos(2)-8,pos(3),pos(4)];
        return;
    end
end
        
if withInRect(pos,[9,9,size(img1,2)-18,size(img1,1)-18])&& pos(3)*pos(4)>size(img1,1)*size(img1,2)*0.35
    pos_left=[pos(1)-8,pos(2)-8,pos(3)*0.5,pos(4)];
    pos_right=[pos(1)+pos(3)*0.5-8,pos(2)-8,pos(3)*0.5,pos(4)];
else

    image_mask1=image_mask<0.03;%thresh;
    image_mask1=255*image_mask1;
    se=strel('disk',1);
    image2=imopen(image_mask1,se);
    se=strel('disk',3);
    image2=imclose(image2,se);
    se=strel('disk',5);
    image2=imclose(image2,se);
    bw=edge(image2,'Sobel');
    [H,theta,rho]=hough(bw);
    Peaks=houghpeaks(H,12,'NHoodSize',[5,5],'Threshold',ceil(0.1*max(H(:))));
    lines=houghlines(bw,theta,rho,Peaks);
    y_max=0;
    x_max=0;
    y_min=5000;
    x_min=5000;
    for k=1:length(lines)
        if lines(k).theta==0
            if lines(k).point1(1)>x_max
                x_max=lines(k).point1(1);
            end
            if lines(k).point1(1)<x_min
                x_min=lines(k).point1(1);
            end
            if lines(k).point1(2)>y_max
                y_max=lines(k).point1(2);
            end
            if lines(k).point1(2)<y_min
                y_min=lines(k).point1(2);
            end
            if lines(k).point2(2)>y_max
                y_max=lines(k).point2(2);
            end
            if lines(k).point2(2)<y_min
                y_min=lines(k).point2(2);
            end
        end
    end
    pos=[x_min,y_min,x_max-x_min,y_max-y_min];
    if withInRect(pos,[9,9,size(img1,2)-18,size(img1,1)-18])&& pos(3)*pos(4)>size(img1,1)*size(img1,2)*0.3
        pos_left=[pos(1)-8,pos(2)-8,pos(3)*0.5,pos(4)];
        pos_right=[pos(1)+pos(3)*0.5-8,pos(2)-8,pos(3)*0.5,pos(4)];
    else
        image_mask1=image_mask<0.01;%thresh;
        image_mask1=255*image_mask1;
        se=strel('disk',1);
        image2=imopen(image_mask1,se);
        se=strel('disk',3);
        image2=imclose(image2,se);
        se=strel('disk',5);
        image2=imclose(image2,se);
        bw=edge(image2,'Sobel');
        [H,theta,rho]=hough(bw);
        Peaks=houghpeaks(H,12,'NHoodSize',[5,5],'Threshold',ceil(0.1*max(H(:))));
        lines=houghlines(bw,theta,rho,Peaks);
        y_max=0;
        x_max=0;
        y_min=5000;
        x_min=5000;
        for k=1:length(lines)
            if lines(k).theta==0
                if lines(k).point1(1)>x_max
                    x_max=lines(k).point1(1);
                end
                if lines(k).point1(1)<x_min
                    x_min=lines(k).point1(1);
                end
                if lines(k).point1(2)>y_max
                    y_max=lines(k).point1(2);
                end
                if lines(k).point1(2)<y_min
                    y_min=lines(k).point1(2);
                end
                if lines(k).point2(2)>y_max
                    y_max=lines(k).point2(2);
                end
                if lines(k).point2(2)<y_min
                    y_min=lines(k).point2(2);
                end
            end
        end
        pos=[x_min,y_min,x_max-x_min,y_max-y_min];
        if withInRect(pos,[9,9,size(img1,2)-18,size(img1,1)-18])&& pos(3)*pos(4)>size(img1,1)*size(img1,2)*0.3
            pos_left=[pos(1)-8,pos(2)-8,pos(3)*0.5,pos(4)];
            pos_right=[pos(1)+pos(3)*0.5-8,pos(2)-8,pos(3)*0.5,pos(4)];
        else
            
            image_mask1=image_mask<0.0001;%thresh;
            image_mask1=255*image_mask1;
            se=strel('disk',20);
            image2=imopen(image_mask1,se);
            bw=edge(image2,'Sobel');
            [H,theta,rho]=hough(bw);
            Peaks=houghpeaks(H,12,'NHoodSize',[5,5],'Threshold',ceil(0.1*max(H(:))));
            lines=houghlines(bw,theta,rho,Peaks);
            y_max=0;
            x_max=0;
            y_min=5000;
            x_min=5000;
            for k=1:length(lines)
                if lines(k).theta==0
                    if lines(k).point1(1)>x_max
                        x_max=lines(k).point1(1);
                    end
                    if lines(k).point1(1)<x_min
                        x_min=lines(k).point1(1);
                    end
                    if lines(k).point1(2)>y_max
                        y_max=lines(k).point1(2);
                    end
                    if lines(k).point1(2)<y_min
                        y_min=lines(k).point1(2);
                    end
                    if lines(k).point2(2)>y_max
                        y_max=lines(k).point2(2);
                    end
                    if lines(k).point2(2)<y_min
                        y_min=lines(k).point2(2);
                    end
                end
            end
            pos=[x_min,y_min,x_max-x_min,y_max-y_min];
            if withInRect(pos,[9,9,size(img1,2)-18,size(img1,1)-18])&& pos(3)*pos(4)>size(img1,1)*size(img1,2)*0.3
                pos_left=[pos(1)-8,pos(2)-8,pos(3)*0.5,pos(4)];
                pos_right=[pos(1)+pos(3)*0.5-8,pos(2)-8,pos(3)*0.5,pos(4)];
            else
                pos_left=[];
                pos_right=[];
            end
        end
    end
    
end

% pos_left=[pos(1)+pos(3)*0.05-8,pos(2)+pos(4)*0.1-8,pos(3)*0.5*0.8,pos(4)*0.8];
% pos_right=[pos(1)+pos(3)*0.55-8,pos(2)+pos(4)*0.1-8,pos(3)*0.5*0.8,pos(4)*0.8];
% image4=imcrop(img1,pos);
% sizeI=size(image4);
% pos=[ceil(sizeI(2)*0.15),ceil(sizeI(1)*0.15),ceil(sizeI(2)*0.7),ceil(sizeI(1)*0.7)];
% image4=imcrop(image4,pos);
% sizeI=size(image4);
% out1=imcrop(img1,pos_left);
% out2=imcrop(img1,pos_right);


function isone=one_or_two_side(img,thresh)
if length(size(img))==3
    img=rgb2gray(img);
end
img=padarray(img,[8,8],0);
image_mask=255*(img>thresh);%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%imshow(image_mask);
se=strel('disk',1);
image2=imopen(image_mask,se);
se=strel('disk',3);
image2=imclose(image2,se);
se=strel('disk',5);
image2=imclose(image2,se);
bw=edge(image2,'Sobel');
[H,theta,rho]=hough(bw);
Peaks=houghpeaks(H,12,'NHoodSize',[5,5],'Threshold',ceil(0.1*max(H(:))));
lines=houghlines(bw,theta,rho,Peaks);
Slash=45;
Slash_band=20;
Thresh_length=size(img,1)*0.3;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% imshow(bw);
% hold on
% for k=1:length(lines)
% xy=[lines(k).point1;lines(k).point2];
% plot(xy(:,1),xy(:,2),'LineWidth',2);
% end
% hold off;
isone=false;
i=1;
while i<=length(lines)
    if abs(lines(i).theta)<Slash+Slash_band&&abs(lines(i).theta)>=Slash-Slash_band
        if abs(lines(i).point1(2)-lines(i).point2(2))>Thresh_length
            isone=true;
            %             xy=[lines(i).point1;lines(i).point2];
            %             plot(xy(:,1),xy(:,2),'LineWidth',2);
            break;
        elseif i<length(lines)
            j=i+1;
            a=lines(i).point2(2)-lines(i).point1(2);
            b=lines(i).point1(1)-lines(i).point2(1);
            c=-(a*lines(i).point1(1)+b*lines(i).point1(2));
            while j<=length(lines)
                if abs(lines(j).theta-lines(i).theta)<5 && abs(a*lines(j).point1(1)+b*lines(j).point1(2)+c)<abs(0.05*c)
                    minx=min(min(min(lines(i).point1(1),lines(i).point2(1)),lines(j).point1(1)),lines(j).point2(1));
                    miny=min(min(min(lines(i).point1(2),lines(i).point2(2)),lines(j).point1(2)),lines(j).point2(2));
                    maxx=max(max(max(lines(i).point1(1),lines(i).point2(1)),lines(j).point1(1)),lines(j).point2(1));
                    maxy=max(max(max(lines(i).point1(2),lines(i).point2(2)),lines(j).point1(2)),lines(j).point2(2));
                    if(lines(i).point1(1)<lines(i).point2(1)&&lines(i).point1(2)<lines(i).point2(2))
                        lines(i).point1=[minx,miny];
                        lines(i).point2=[maxx,maxy];
                    elseif(lines(i).point1(1)<lines(i).point2(1)&&lines(i).point1(2)>lines(i).point2(2))
                        lines(i).point1=[minx,maxy];
                        lines(i).point2=[maxx,miny];
                    elseif (lines(i).point1(1)>lines(i).point2(1)&&lines(i).point1(2)<lines(i).point2(2))
                        lines(i).point1=[maxx,miny];
                        lines(i).point2=[minx,maxy];
                    elseif (lines(i).point1(1)>lines(i).point2(1)&&lines(i).point1(2)>lines(i).point2(2))
                        lines(i).point2=[minx,miny];
                        lines(i).point1=[maxx,maxy];
                    end
                end
                j=j+1;
            end
            if abs(lines(i).point1(2)-lines(i).point2(2))>Thresh_length
                isone=true;
                %                xy=[lines(i).point1;lines(i).point2];
                %                plot(xy(:,1),xy(:,2),'LineWidth',2);
                break;
            end
        end
    end
    i=i+1;
end
%    hold off;


% --------------------------------------------------------------------
% --- Executes on slider movement.
function VideoPlaySlider_Callback(hObject, eventdata, handles)
% hObject    handle to VideoPlaySlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
videoControl(hObject);

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function VideoPlaySlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VideoPlaySlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbutton1.
function pushbutton1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in lastSecond.
function lastSecond_Callback(hObject, eventdata, handles)
% hObject    handle to lastSecond (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cmenu_call(hObject);

% --- Executes on button press in playControler.
function playControler_Callback(hObject, eventdata, handles)
% hObject    handle to playControler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% t=timerfind('Name','controlVideo');
if strcmp(hObject.String,'Play')
    start(handles.DefVar.timer);
    set(hObject,'String','Off');
else
    stop(handles.DefVar.timer);
    set(hObject,'String','Play');
end
guidata(hObject,handles);

% --- Executes on button press in lastFrame.
function lastFrame_Callback(hObject, eventdata, handles)
% hObject    handle to lastFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cmenu_call(hObject);

% --- Executes on button press in nextFrame.
function nextFrame_Callback(hObject, eventdata, handles)
% hObject    handle to nextFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cmenu_call(hObject);

% --- Executes on button press in nextSecond.
function nextSecond_Callback(hObject, eventdata, handles)
% hObject    handle to nextSecond (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cmenu_call(hObject);

function openMat_Callback(hObject, eventdata, handles)
% hObject    handle to openMat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'DefVar')&&isfield(handles.DefVar,'pic')
    if okToClearExisting()
        handles=resetParentFigure(handles);
    else
        return
    end
else
    handles=resetParentFigure(handles);
end

path=handles.DefVar.path;
if exist([path,'\ObjectTrackingConfig.mat'],'file')
    confg=open([path,'\ObjectTrackingConfig.mat']);
    if isfield(confg,'Defaultdir')&&exist(confg.Defaultdir,'dir')
        path=confg.Defaultdir;
    end
end
[ReadVideoFileName,Defaultdir,ReadVideoFilterIndex] = uigetfile({'*.mat','MatFile(.mat)'},'LoadMat',...
    'MultiSelect','off',path); %设置默认路径
if isequal(ReadVideoFileName,0) || isequal(Defaultdir,0) || isequal(ReadVideoFilterIndex,0)
    msgbox('Mat file import failed, click OK to close the dialog box, then re-import');
    return;
else
    %只读入一个视频
    fullname=fullfile( Defaultdir,ReadVideoFileName);%视频完整路径
    if exist([handles.DefVar.path,'\ObjectTrackingConfig.mat'],'file')
        save([handles.DefVar.path,'\ObjectTrackingConfig.mat'],'Defaultdir','-append');
    else
        save([handles.DefVar.path,'\ObjectTrackingConfig.mat'],'Defaultdir');
    end
    conf=open(fullname);
    conf.fullname=replace(conf.fullname,'E:\已勾画完成肝癌数据\', 'E:\fusan\DONE\');
    if ~isfield(conf,'fullname')||exist(conf.fullname,'file')~=2
        errordlg('Mat file format is wrong, please re-select');
    end
    hData = VideoReader(conf.fullname);
    frames=hData.NumberOfFrames;
    if frames>1
        pic=read(hData,1);
    else
        msgbox('Failed to import video, click OK to close the dialog and re-import');
        return;
    end
    screenSize=get(0,'screensize');
    whratio=hData.Width*1.0/hData.Height;
    
    if  screenSize(4)*whratio<screenSize(3)
        fig2=screenSize(4)*0.05;
        fig4=screenSize(4)*0.9;
        fig3=screenSize(4)*0.9*whratio;
        fig1=screenSize(3)*0.5-fig3*0.5;
        
    else
        fig1=screenSize(3)*0.05;
        fig3=screenSize(3)*0.9;
        fig4=screenSize(3)*0.9/whratio;
        fig2=screenSize(4)*0.5-fig3*0.5;
    end
    if isfield(handles,'posAxes1')
        set(handles.ObjectTrackingAxes1,'OuterPosition',handles.posAxes1);
    end
    set(handles.figure1,'Resize','off','unit','pixels','Position',[fig1 fig2 fig3 fig4]);
    
    %         handles.htablePanel=uipanel(handles.hfigure,'unit','normalized',...
    %                                     'position',[0 0.5 0.4 0.5]);
    
    handles.DefVar.hData=hData;
    %      set(hfigure,'deleteFcn',"load('base','pic',pic)");
    handles.DefVar.fullname=fullname;
    xRate=1.0;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%控制播放速率
    handles.DefVar.frameRate=xRate*hData.frameRate;
    %fix(hData.FrameRate*hData.currentTime+1);
    handles.DefVar.currentFrameNum=1;
    handles.DefVar.currentTime=hData.CurrentTime;
    set(handles.VedioDuration,'String',[num2str(floor(hData.Duration/60)),'分',num2str(roundn(hData.Duration-fix(hData.Duration/60)*60,-2)),'秒']);
    set(handles.ImageHeight,'String',num2str(hData.Height));
    set(handles.ImageWidth,'String',num2str(hData.Width));
    set(handles.CurrentMin,'String',num2str(floor(handles.DefVar.currentTime/60)));
    set(handles.CurrentSec,'String',num2str(roundn(handles.DefVar.currentTime-fix(handles.DefVar.currentTime/60)*60,-2)));
    set(handles.ObjectTrackingAxes1,'unit','pixels');
    
    posAxes1=get(handles.ObjectTrackingAxes1,'OuterPosition');
    handles.posAxes1=posAxes1;
    
    if posAxes1(3)*1.00/posAxes1(4)>whratio
        set(handles.ObjectTrackingAxes1,'OuterPosition',[ posAxes1(1)+( posAxes1(3)- posAxes1(4)*whratio)/2, posAxes1(2), posAxes1(4)*whratio, posAxes1(4)]);
    else
        set(handles.ObjectTrackingAxes1,'OuterPosition',[ posAxes1(1), posAxes1(2)+( posAxes1(3)*1.0/whratio- posAxes1(4))/2, posAxes1(3), posAxes1(3)*1.0/ whratio]);
    end
    handles.DefVar.pic=pic;
    set(handles.ObjectTrackingAxes1,'YTick',[],'XTick',[],'XTickLabel',[],'YTickLabel',[]);
    image(handles.DefVar.pic,'Parent',handles.ObjectTrackingAxes1,'PickableParts','visible','HitTest','off');
    set(handles.ObjectTrackingAxes1,'YTick',[],'XTick',[],'XTickLabel',[],'YTickLabel',[]);
    
    handles.DefVar.timer=timer('Name','controlVideo',...
        'Period',1.0/handles.DefVar.frameRate,...
        'StartDelay',0,...
        'TasksToExecute',inf,...
        'ExecutionMode','fixedSpacing',...
        'TimerFcn',{@timecall,handles.ObjectTrackingAxes1},...
        'StartFcn',{@timerstarcall,handles.ObjectTrackingAxes1},...
        'StopFcn',{@timerstopcall,handles.ObjectTrackingAxes1});
    set(handles.figure1,'deleteFcn',@figuredelete);
    set(handles.VideoPlaySlider,'value',handles.DefVar.currentFrameNum,'min',1,'max',frames);
    c=uicontextmenu;
    uimenu(c,'label','Next picture','callback',@cmenu_call,'Tag','Menu');
    uimenu(c,'label','Previous picture','callback',@cmenu_call,'Tag','Menu');
    uimenu(c,'label','Next second picture','callback',@cmenu_call,'Tag','Menu');
    uimenu(c,'label','Last second picture','callback',@cmenu_call,'Tag','Menu');
    uimenu(c,'label','Next Shoting picture','callback',@cmenu_call,'Tag','Menu');
    uimenu(c,'label','Last Shoting picture','callback',@cmenu_call,'Tag','Menu');
    handles.ObjectTrackingAxes1.UIContextMenu=c;
%    handles.DefVar.flowRecommand=conf.flowRecommand;
    %     handles.DefVar.ShuangfuTimeSeries=conf.ShuangfuTimeSeries;
    %     handles.DefVar.BofangTimeSeries=conf.BofangTimeSeries;
    %     handles.DefVar.time_array=conf.time_array;
    %     handles.DefVar.vx=conf.vx;
    handles.DefVar.ZaoyingPos=conf.ZaoyingPos;
    handles.DefVar.ErweiPos=conf.ErweiPos;
    handles.DefVar.fullname=conf.fullname;
    handles.DefVar.RectsArray=conf.RectsArray;
    handles.DefVar.FrameNumsArray=conf.FrameNumsArray;
    handles.DefVar.ShotingPic=conf.ShotingPic;
    handles.DefVar.imRect=[];
    handles.DefVar.imRectM=[];
    handles.DefVar.RecommandPic=conf.RecommandPic;
   % handles.DefVar.flowRecommand=conf.flowRecommand;
    image(handles.axes2,handles.DefVar.RecommandPic);
    set(handles.axes2,'YTick',[],'YTickLabel',[]);
    image(handles.axes3,handles.DefVar.ShotingPic);
    set(handles.axes3,'YTick',[],'YTickLabel',[]);
    ax=findobj('parent',handles.figure1,'type','uicontrol');
    set(ax,'Enable','on');
    
%     if isempty(handles.DefVar.flowRecommand)
%         handles.FlowLast.Enable='off';
%         handles.FlowNext.Enable='off';
%     end
    if isempty(handles.DefVar.ZaoyingPos)
        handles.Mirror.Enable='off';
    else
        handles.Mirror.Value=1;
    end
    [ShotingNum,ShotingFrameIdx]=findShotingNum( handles.DefVar.currentFrameNum,handles.DefVar.FrameNumsArray);
    stringCell={'I','II','III','IV','V','VI','VII','VIII'};
    for i=1:length(stringCell)
        if handles.DefVar.FrameNumsArray{i}(1)>0
            BO=eval(['handles.',stringCell{i}]);
            BO.BackgroundColor=[1,0,0];
        end
    end
    if ~isempty(ShotingNum)
        for i=1:length(ShotingNum)
            BO=eval(['handles.',stringCell{ShotingNum(i)}]);
            getImRect(BO,handles,ShotingNum(i),ShotingFrameIdx(i));
            handles=guidata(BO);
        end
    else
        handles.DefVar.imRect=[];
        handles.DefVar.imRectM=[];
    end
    guidata(hObject,handles);
    
end


% --------------------------------------------------------------------
function saveAll_Callback(hObject, eventdata, handles)
% hObject    handle to saveAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
saveMat(handles);

% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in I.
function I_Callback(hObject, eventdata, handles)
% hObject    handle to I (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ShotingConotrol(hObject,handles,1);


% --- Executes on button press in II.
function II_Callback(hObject, eventdata, handles)
% hObject    handle to II (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ShotingConotrol(hObject,handles,2);

% --- Executes on button press in III.
function III_Callback(hObject, eventdata, handles)
% hObject    handle to III (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ShotingConotrol(hObject,handles,3);

% --- Executes on button press in IV.
function IV_Callback(hObject, eventdata, handles)
% hObject    handle to IV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ShotingConotrol(hObject,handles,4);

% --- Executes on button press in V.
function V_Callback(hObject, eventdata, handles)
% hObject    handle to V (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ShotingConotrol(hObject,handles,5);

% --- Executes on button press in VI.
function VI_Callback(hObject, eventdata, handles)
% hObject    handle to VI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ShotingConotrol(hObject,handles,6);

% --- Executes on button press in VII.
function VII_Callback(hObject, eventdata, handles)
% hObject    handle to VII (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ShotingConotrol(hObject,handles,7);

% --- Executes on button press in VIII.
function VIII_Callback(hObject, eventdata, handles)
% hObject    handle to VIII (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ShotingConotrol(hObject,handles,8);


function CurrentMin_Callback(hObject, eventdata, handles)
% hObject    handle to CurrentMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
videoControl(hObject);
% Hints: get(hObject,'String') returns contents of CurrentMin as text
%        str2double(get(hObject,'String')) returns contents of CurrentMin as a double


% --- Executes during object creation, after setting all properties.
function CurrentMin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CurrentMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function CurrentSec_Callback(hObject, eventdata, handles)
% hObject    handle to CurrentSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
videoControl(hObject);
% Hints: get(hObject,'String') returns contents of CurrentSec as text
%        str2double(get(hObject,'String')) returns contents of CurrentSec as a double


% --- Executes during object creation, after setting all properties.
function CurrentSec_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CurrentSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in FlowLast.
function FlowLast_Callback(hObject, eventdata, handles)
% hObject    handle to FlowLast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
videoControl(hObject);

% --- Executes on button press in FlowNext.
function FlowNext_Callback(hObject, eventdata, handles)
% hObject    handle to FlowNext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
videoControl(hObject);

% --- Executes on selection change in LeftIsZaoying.
function LeftIsZaoying_Callback(hObject, eventdata, handles)
% hObject    handle to LeftIsZaoying (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.TackingOn.Value=0;
guidata(hObject,handles);
% Hints: contents = cellstr(get(hObject,'String')) returns LeftIsZaoying contents as cell array
%        contents{get(hObject,'Value')} returns selected item from LeftIsZaoying


% --- Executes during object creation, after setting all properties.
function LeftIsZaoying_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LeftIsZaoying (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobutton4.
function radiobutton4_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton4


% --- Executes on button press in Mirror.
function Mirror_Callback(hObject, eventdata, handles)
% hObject    handle to Mirror (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if hObject.Value
    if ~isempty(handles.DefVar.imRect)
        if ~isempty(handles.DefVar.ZaoyingPos)&&~isempty(handles.DefVar.ErweiPos)
            h=handles.DefVar.imRect;
            api=iptgetapi(h);
            pointMat=api.getPosition();
            mirPos=computMirror(pointMat,handles.DefVar.ErweiPos,handles.DefVar.ZaoyingPos);
            if ~isempty(mirPos)
                h2=imrect(handles.ObjectTrackingAxes1,mirPos);
                api2=iptgetapi(h2);
                api2.setColor([0.4,0.4,0.4]);
                chld = get(h2,'Children');
                cmenu_obj2 = findobj(chld,'Type','line','-or','Type','patch');
                set(cmenu_obj2,'uicontextmenu',[]);
                addNewPositionCallback(h2,@(varagin)impoly_newPosition2(h2,hObject,idx1,idx2));
                handles.DefVar.imRectM=h2;
            end
        end
    end
else
    if ~isempty(handles.DefVar.imRectM)
        api=iptgetapi(handles.DefVar.imRectM);
        api.delete;
        handles.DefVar.imRectM=[];
    end
end
guidata(hObject,handles);
% Hint: get(hObject,'Value') returns toggle state of Mirror

function LoadVideo_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to LoadVideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function lastSecond_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to lastSecond (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cmenu_call(hObject);



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over lastFrame.
function lastFrame_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to lastFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cmenu_call(hObject);



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over nextFrame.
function nextFrame_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to nextFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cmenu_call(hObject);

function nextSecond_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to nextFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cmenu_call(hObject);

function [ fna1,rectsA1]=track(points,stdimg,pos,CutPos,hData,cfn,bsfn,esfn,pp)
if pp==1
    pointTracker = vision.PointTracker('MaxBidirectionalError', 2);
    initialize(pointTracker, points, stdimg);
    oldPoints=points;
    bboxPoints = bbox2points(pos);
    fna1=zeros(cfn-bsfn,1);
    rectsA1=zeros(cfn-bsfn,4);
    for i=1:cfn-bsfn
        img=im2double(rgb2gray(imcrop(read(hData,cfn-i),CutPos)));
        img=min(max(img,0),1);
        %         img = PlugPlayADMM_general(img,A,lambda,method,opts);
        [points, isFound] = step(pointTracker, img);
        visiblePoints = points(isFound, :);
        oldInliers = oldPoints(isFound, :);
        if size(visiblePoints, 1) >= 2
            [xform, oldInliers, visiblePoints] = estimateGeometricTransform(...
                oldInliers, visiblePoints, 'similarity', 'MaxDistance', 4);
            
            % Apply the transformation to the bounding box points
            bboxPoints = transformPointsForward(xform, bboxPoints);
            [xlim,ylim]= boundingbox(polyshape(bboxPoints));
            fna1(cfn-i-bsfn+1)=cfn-i;
            rectsA1(cfn-i-bsfn+1,:)=[xlim(1)+CutPos(1),ylim(1)+CutPos(2),xlim(2)-xlim(1),ylim(2)-ylim(1)];
            % Insert a bounding box around the object being tracked
            % bboxPolygon = reshape(bboxPoints', 1, []);
            %         figure;
            %         imshow(img,[]);
            %         impoly(gca,bboxPoints);
            %         img = insertShape(img, 'Polygon', bboxPolygon, ...
            %             'LineWidth', 2);
            %         imshow(img,[]);
            % Reset the points
            oldPoints = visiblePoints;
            setPoints(pointTracker, oldPoints);
        end
    end
else
    pointTracker = vision.PointTracker('MaxBidirectionalError', 2);
    initialize(pointTracker, points, stdimg);
    oldPoints=points;
    bboxPoints = bbox2points(pos);
    fna1=zeros(esfn-cfn,1);
    rectsA1=zeros(esfn-cfn,4);
    for i=cfn+1:esfn
        img=im2double(rgb2gray(imcrop(read(hData,i),CutPos)));
        img= min(max(img,0),1);
        %                 img = PlugPlayADMM_general(img,A,lambda,method,opts);
        [points, isFound] = step(pointTracker, img);
        visiblePoints = points(isFound, :);
        oldInliers = oldPoints(isFound, :);
        if size(visiblePoints, 1) >= 2
            [xform, oldInliers, visiblePoints] = estimateGeometricTransform(...
                oldInliers, visiblePoints, 'similarity', 'MaxDistance', 4);
            bboxPoints = transformPointsForward(xform, bboxPoints);
            [xlim,ylim]= boundingbox(polyshape(bboxPoints));
            fna1(i-bsfn+1)=i;
            rectsA1(i-bsfn+1,:)=[xlim(1)+CutPos(1),ylim(1)+CutPos(2),xlim(2)-xlim(1),ylim(2)-ylim(1)];
            oldPoints = visiblePoints;
            setPoints(pointTracker, oldPoints);
        end
    end
end

% --- Executes on button press in tracking.
function tracking_Callback(hObject, eventdata, handles)
% hObject    handle to tracking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if hObject.Value==1&&~isempty(handles.DefVar.imRect)
    [ShotingNum,ShotingFrameIdx]=findShotingNum( handles.DefVar.currentFrameNum,handles.DefVar.FrameNumsArray);
    if isempty(ShotingNum)||length(handles.DefVar.FrameNumsArray{ShotingNum(1)})>1
        return;
    end
    
    api=iptgetapi(handles.DefVar.imRect);
    pos=api.getPosition;
    if withInRect(pos,handles.DefVar.ZaoyingPos)
        CutPos=handles.DefVar.ZaoyingPos;
    elseif withInRect(pos,handles.DefVar.ErweiPos)
        CutPos=handles.DefVar.ErweiPos;
    else
        errordlg('Tracking box position Error!!!');
        return;
    end
    cfn=handles.DefVar.currentFrameNum;
    duration=round(handles.slider4.Value);
    hData=handles.DefVar.hData;
    timeDuration=1.0/hData.FrameRate;
    [ShotingNumL,ShotingFrameNumL]=findLastShotingNum(handles.DefVar.currentFrameNum,handles.DefVar.FrameNumsArray);
    [ShotingNumN,ShotingFrameNumN]=findNextShotingNum(handles.DefVar.currentFrameNum,handles.DefVar.FrameNumsArray);
    if ShotingNumL>0
        minN=handles.DefVar.FrameNumsArray{ShotingNumL}(end)+1;
    else
        minN=1;
    end
    if ShotingNumN>0
        maxN=handles.DefVar.FrameNumsArray{ShotingNumN}(1)-1;
    else
        maxN=hData.NumberOfFrames;
    end
    
    bsfn=round(cfn+1-duration/2);
    esfn=round(cfn+duration-duration/2);
    
    if bsfn<minN
        bsfn=minN;
    end
    if esfn>maxN
        esfn=maxN;
    end
    cfnpos=pos;
    method = 'RF';
    switch method
        case 'RF'
            lambda = 0.005;%0.0005
        case 'NLM'
            lambda = 0.005;%0.005
        case 'BM3D'
            lambda = 0.03;%0.001
        case 'TV'
            lambda = 0.05;%0.01
    end
    opts.rho     = 1;
    opts.gamma   = 1;%%
    opts.max_itr = 20;
    opts.print   = false;
    
    stdimg=im2double(rgb2gray(imcrop(read(hData,cfn),CutPos)));
    stdimg=min(max(stdimg,0),1);
    dim = size(stdimg);
    h = fspecial('gaussian',[9 9],1);
    A = @(z,trans_flag) afun(z,trans_flag,h,dim);
    % imgArray=zeros(esfn-bsfn,CutPos(4),CutPos(3));
    %     stdimg = PlugPlayADMM_general(stdimg,A,lambda,method,opts);
    pos=[pos(1)-CutPos(1),pos(2)-CutPos(2),pos(3),pos(4)];
    points = detectMinEigenFeatures(stdimg, 'ROI', pos);
    points = points.Location;
    p=gcp();
    for idx=1:2
        f(idx)=parfeval(p,@track,2,points,stdimg,pos,CutPos,hData,cfn,bsfn,esfn,idx);
    end
    [idx,fna1,rectsA1]=fetchNext(f);
    [idx,fna2,rectsA2]=fetchNext(f);
    if ~isempty(fna1)
        zeromask=fna1>0;
        fna1=fna1(zeromask);
        rectsA1=rectsA1(zeromask,:);
    end
    if ~isempty(fna2)
        zeromask=fna2>0;
        fna2=fna2(zeromask);
        rectsA2=rectsA2(zeromask,:);
    end
    [frameNumsArray,I]=sort([fna1;cfn;fna2]);
    rectsA=[rectsA1;cfnpos;rectsA2];
    rectsArray=zeros(size(rectsA));
    for i=1:length(I)
        rectsArray(I(i),:)=rectsA(i,:);
    end
    a=frameNumsArray(frameNumsArray>0);
    b=rectsArray(frameNumsArray>0,:);
    %     j=1;
    %     a=[];
    %     b=[];
    %     for i=1:length(frameNumsArray)
    %         if frameNumsArray(i)>0
    %             a=[a,frameNumsArray(i)];
    %             b=[b;rectsArray(i,:)];
    %             j=j+1;
    %         end
    %     end
    handles.DefVar.FrameNumsArray{ShotingNum(1)}=a;
    handles.DefVar.RectsArray{ShotingNum(1)}=b;
    hObject.Enable='off';
    b=handles.DefVar.EightColor(ShotingNum(1),:);
    for i=1:length(a)
        handles.DefVar.ShotingPic(:,max(a(i)-5,1):min(a(i)+5,handles.DefVar.hData.NumberOfFrames),1)=b(1);
        handles.DefVar.ShotingPic(:,max(a(i)-5,1):min(a(i)+5,handles.DefVar.hData.NumberOfFrames),2)=b(2);
        handles.DefVar.ShotingPic(:,max(a(i)-5,1):min(a(i)+5,handles.DefVar.hData.NumberOfFrames),3)=b(3);
    end
    image(handles.axes3,handles.DefVar.ShotingPic);
    set(handles.axes3,'YTick',[],'YTickLabel',[]);
    guidata(hObject,handles);
end
% Hint: get(hObject,'Value') returns toggle state of tracking

function ShotingConotrol(hObject,handles,idx)
if idx<1||idx>length(handles.DefVar.FrameNumsArray)
    return;
end
getImRect(hObject,handles,idx,1);


function getImRect(hObject,handles,idx1,idx2)
% handles=guidate(hObject);
if size(handles.DefVar.RectsArray{idx1},2)==1
    h=imrect(handles.ObjectTrackingAxes1);
    if isempty(h)
        return;
    end
    api=iptgetapi(h);
    handles.DefVar.FrameNumsArray{idx1}(1)=handles.DefVar.currentFrameNum;
    handles.DefVar.RectsArray{idx1}=api.getPosition;
    b=handles.DefVar.EightColor(idx1,:);
    cfn=handles.DefVar.currentFrameNum;
    handles.DefVar.ShotingPic(:,max(cfn-5,1):min(cfn+5,handles.DefVar.hData.NumberOfFrames),1)=b(1);
    handles.DefVar.ShotingPic(:,max(cfn-5,1):min(cfn+5,handles.DefVar.hData.NumberOfFrames),2)=b(2);
    handles.DefVar.ShotingPic(:,max(cfn-5,1):min(cfn+5,handles.DefVar.hData.NumberOfFrames),3)=b(3);
    image(handles.axes3,handles.DefVar.ShotingPic);
    set(handles.axes3,'YTick',[],'YTickLabel',[]);
else
    currentframenum=handles.DefVar.FrameNumsArray{idx1}(idx2);
    currenttime=roundn( 1.0*currentframenum/handles.DefVar.hData.frameRate,-3);
    if currentframenum~=handles.DefVar.currentFrameNum
        handles.VideoPlaySlider.Value=currentframenum;
        set(handles.CurrentMin,'String',num2str(floor(currenttime/60)));
        set(handles.CurrentSec,'String',num2str(roundn(currenttime-fix(currenttime/60)*60,-2)));
        handles.DefVar.currentFrameNum=min(max(fix(currentframenum),1),handles.DefVar.hData.NumberOfFrames);
        handles.DefVar.currentTime=currenttime;
        handles.DefVar.pic=read(handles.DefVar.hData,currentframenum);
        image(handles.DefVar.pic,'Parent',handles.ObjectTrackingAxes1,'PickableParts','visible','HitTest','off');
        set(handles.ObjectTrackingAxes1,'YTick',[],'XTick',[],'XTickLabel',[],'YTickLabel',[]);
    end
    h=imrect(handles.ObjectTrackingAxes1,handles.DefVar.RectsArray{idx1}(idx2,:));
    api=iptgetapi(h);
end
if length(handles.DefVar.FrameNumsArray{idx1})==1
    handles.tracking.Value=0;
    handles.tracking.Enable='on';
end
stringCell={'I','II','III','IV','V','VI','VII','VIII'};
for i=1:length(stringCell)
    if handles.DefVar.FrameNumsArray{i}(1)>0
        BO=eval(['handles.',stringCell{i}]);
        BO.BackgroundColor=[1,0,0];
    end
end
pointMat=api.getPosition;
hObject.BackgroundColor=[0,1,0];
chld = get(h,'Children');
cmenu_obj = findobj(chld,'Type','line','-or','Type','patch');
set(cmenu_obj,'uicontextmenu',[]);
conM=uicontextmenu(handles.figure1);
uiDel=uimenu(conM,'Label','Delete');
uimenu(uiDel,'Label','delete this one','Callback',{@roiDelete,hObject,idx1,idx2});
uimenu(uiDel,'Label','delete before in the shoting','Callback',{@roiDelete,hObject,idx1,idx2});
uimenu(uiDel,'Label','delete after in the shoting','Callback',{@roiDelete,hObject,idx1,idx2});
uimenu(uiDel,'Label','delete this shoting','Callback',{@roiDelete,hObject,idx1,idx2});
if isempty(handles.DefVar.ZaoyingPos)||isempty(handles.DefVar.ErweiPos)||handles.Mirror.Value==0
    uiMir=uimenu(conM,'Label','Mirror ROI','Enable','off');
else
    uiMir=uimenu(conM,'Label','Mirror ROI','Enable','on');
    mirPos=computMirror(pointMat,handles.DefVar.ErweiPos,handles.DefVar.ZaoyingPos);
    if ~isempty(mirPos)
        h2=imrect(handles.ObjectTrackingAxes1,mirPos);
        api2=iptgetapi(h2);
        api2.setColor([0.4,0.4,0.4]);
        chld = get(h2,'Children');
        cmenu_obj2 = findobj(chld,'Type','line','-or','Type','patch');
        set(cmenu_obj2,'uicontextmenu',[]);
        addNewPositionCallback(h2,@(varagin)impoly_newPosition2(h2,hObject,idx1,idx2));
        handles.DefVar.imRectM=h2;
    end
end
uimenu(uiMir,'Label','Mirror this one','Enable','on','Callback',{@getMirror,h,idx1,idx2});
uimenu(uiMir,'Label','Mirror before in the shoting','Enable','on','Callback',{@getMirror,h,idx1,idx2});
uimenu(uiMir,'Label','Mirror after in the shoting','Enable','on','Callback',{@getMirror,h,idx1,idx2});
uimenu(uiMir,'Label','Mirror this shoting','Enable','on','Callback',{@getMirror,h,idx1,idx2});
%     if  ~isempty(handles.DefVar.ZaoyingPos) &&~isempty(handles.DefVar.ErweiPos) && withinCrop(handles.DefVar.ErweiPos,handles.DefVar.ZaoyingPos,pointMat)&&handles.Mirror.Value
%         set(uiMir,'Enable','on');
%     else
%         handles.Mirror.Value=0;
%     end
set(cmenu_obj,'uicontextmenu',conM);
addNewPositionCallback(h,@(varagin)impoly_newPosition(h,hObject,idx1,idx2));
handles.DefVar.imRect=h;
guidata(hObject,handles);

function getMirror(varargin)
label=varargin{1}.Label;
hObject=varargin{3};
handles=guidata(varargin{1});
idx1=varargin{4};
idx2=varargin{5};
if isempty(handles.DefVar.ErweiPos)||isempty(handles.DefVar.ZaoyingPos)
    return;
end
api=iptgetapi(hObject);
pos=api.getPosition;
mirroPos=computMirror(pos,handles.DefVar.ErweiPos,handles.DefVar.ZaoyingPos);
if isempty(mirroPos)
    return;
else
    api.setPosition(mirroPos);
end
%  handles.DefVar.imRect=hobject;设置跟踪看看什么情况
switch label
    case 'Mirror this one'
        handles.DefVar.RectsArray{idx1}(idx2,:)=mirroPos;
    case 'Mirror after in the shoting'
        for i=idx2:size(handles.DefVar.RectsArray{idx1},1)
            mirroPos=computMirror(  handles.DefVar.RectsArray{idx1}(i,:),handles.DefVar.ErweiPos,handles.DefVar.ZaoyingPos);
            if isempty(mirroPos)
                continue;
            else
                handles.DefVar.RectsArray{idx1}(i,:)=mirroPos;
            end
        end
    case 'Mirror before in the shoting'
        for i=1:idx2
            mirroPos=computMirror(  handles.DefVar.RectsArray{idx1}(i,:),handles.DefVar.ErweiPos,handles.DefVar.ZaoyingPos);
            if isempty(mirroPos)
                continue;
            else
                handles.DefVar.RectsArray{idx1}(i,:)=mirroPos;
            end
        end
        
    case 'Mirror this shoting'
        for i=1:size(handles.DefVar.RectsArray{idx1},1)
            mirroPos=computMirror(  handles.DefVar.RectsArray{idx1}(i,:),handles.DefVar.ErweiPos,handles.DefVar.ZaoyingPos);
            if isempty(mirroPos)
                continue;
            else
                handles.DefVar.RectsArray{idx1}(i,:)=mirroPos;
            end
        end
end
guidata(varargin{1},handles);

function mirroPos=computMirror(pos,ErweiPos,ZaoyingPos)
mirroPos=[];
if withInRect(pos,ErweiPos)
    mirroPos(1)=-ErweiPos(1)+pos(1)+ZaoyingPos(1);
    mirroPos(2)=pos(2);
    mirroPos(3)=pos(3);
    mirroPos(4)=pos(4);
elseif withInRect(pos,ZaoyingPos)
    mirroPos(1)=ErweiPos(1)+pos(1)-ZaoyingPos(1);
    mirroPos(2)=pos(2);
    mirroPos(3)=pos(3);
    mirroPos(4)=pos(4);
end

function a=withInRect(pos1,pos2)
if pos1(3)<0||pos1(4)<0
    a=false;
elseif pos1(1)>=pos2(1)&&pos1(2)>=pos2(2)&&(pos1(1)+pos1(3))<=(pos2(1)+pos2(3))&&(pos1(2)+pos1(4))<=(pos2(2)+pos2(4))
    a=true;
else
    a=false;
end


function roiDelete(varargin)
label=varargin{1}.Label;
idx1=varargin{4};
idx2=varargin{5};
hObject=varargin{3};
handles=guidata(hObject);
a=handles.DefVar.ShotingPic;
delete(handles.DefVar.imRect);
handles.DefVar.imRect=[];
if ~isempty(handles.DefVar.imRectM)
    delete(handles.DefVar.imRectM);
    handles.DefVar.imRectM=[];
end
cfn=handles.DefVar.currentFrameNum;
switch label
    case 'delete this one'
        handles.DefVar.ShotingPic(:,max(cfn-5,1):min(cfn+5,handles.DefVar.hData.NumberOfFrames),1)=1;
        handles.DefVar.ShotingPic(:,max(cfn-5,1):min(cfn+5,handles.DefVar.hData.NumberOfFrames),2)=1;
        handles.DefVar.ShotingPic(:,max(cfn-5,1):min(cfn+5,handles.DefVar.hData.NumberOfFrames),3)=1;
        if length(handles.DefVar.FrameNumsArray{idx1})==1
            handles.DefVar.FrameNumsArray{idx1}=[0];
            handles.DefVar.RectsArray{idx1}=[0];
            hObject.BackgroundColor=[0.9,0.9,0.9];
        else
            handles.DefVar.FrameNumsArray{idx1}=[handles.DefVar.FrameNumsArray{idx1}( 1:idx2-1),handles.DefVar.FrameNumsArray{idx1}(idx2+1:end)];
            handles.DefVar.RectsArray{idx1}=[handles.DefVar.RectsArray{idx1}(1:idx2-1,:);...
                handles.DefVar.RectsArray{idx1}(idx2+1:end,:)];
        end
        
    case 'delete before in the shoting'
        for i=1:idx2
            num=handles.DefVar.FrameNumsArray{idx1}(i);
            handles.DefVar.ShotingPic(:,max(num-5,1):min(num+5,handles.DefVar.hData.NumberOfFrames),1)=1;
            handles.DefVar.ShotingPic(:,max(num-5,1):min(num+5,handles.DefVar.hData.NumberOfFrames),2)=1;
            handles.DefVar.ShotingPic(:,max(num-5,1):min(num+5,handles.DefVar.hData.NumberOfFrames),3)=1;
        end
        if length(handles.DefVar.FrameNumsArray{idx1})==1||idx2==length(handles.DefVar.FrameNumsArray{idx1})
            handles.DefVar.FrameNumsArray{idx1}=[0];
            handles.DefVar.RectsArray{idx1}=[0];
            hObject.BackgroundColor=[0.9,0.9,0.9];
        else
            a2 = handles.DefVar.FrameNumsArray{idx1};
            handles.DefVar.FrameNumsArray{idx1}=a2( idx2+1:end);
            a1 = handles.DefVar.RectsArray{idx1};
            handles.DefVar.RectsArray{idx1}=a1(idx2+1:end,:);
        end
        
    case 'delete after in the shoting'
        for i=idx2:length(handles.DefVar.FrameNumsArray{idx1})
            num=handles.DefVar.FrameNumsArray{idx1}(i);
            handles.DefVar.ShotingPic(:,max(num-5,1):min(num+5,handles.DefVar.hData.NumberOfFrames),1)=1;
            handles.DefVar.ShotingPic(:,max(num-5,1):min(num+5,handles.DefVar.hData.NumberOfFrames),2)=1;
            handles.DefVar.ShotingPic(:,max(num-5,1):min(num+5,handles.DefVar.hData.NumberOfFrames),3)=1;
        end
        if length(handles.DefVar.FrameNumsArray{idx1})==1||idx2==1
            handles.DefVar.FrameNumsArray{idx1}=[0];
            handles.DefVar.RectsArray{idx1}=[0];
            hObject.BackgroundColor=[0.9,0.9,0.9];
        else
            handles.DefVar.FrameNumsArray{idx1}= handles.DefVar.FrameNumsArray{idx1}( 1:idx2-1);
            a1=handles.DefVar.RectsArray{idx1};
            handles.DefVar.RectsArray{idx1}=a1(1:idx2-1,:);
        end
        
    case 'delete this shoting'
        for i=1:length(handles.DefVar.FrameNumsArray{idx1})
            num=handles.DefVar.FrameNumsArray{idx1}(i);
            handles.DefVar.ShotingPic(:,max(num-5,1):min(num+5,handles.DefVar.hData.NumberOfFrames),1)=1;
            handles.DefVar.ShotingPic(:,max(num-5,1):min(num+5,handles.DefVar.hData.NumberOfFrames),2)=1;
            handles.DefVar.ShotingPic(:,max(num-5,1):min(num+5,handles.DefVar.hData.NumberOfFrames),3)=1;
        end
        handles.DefVar.FrameNumsArray{idx1}=[0];
        handles.DefVar.RectsArray{idx1}=[0];
        hObject.BackgroundColor=[0.9,0.9,0.9];
end

image(handles.axes3,handles.DefVar.ShotingPic);
set(handles.axes3,'YTick',[],'YTickLabel',[]);
guidata(hObject,handles);

function impoly_newPosition(h,hObject,i,j)
handles=guidata(hObject);
api=iptgetapi(h);
pointMat=api.getPosition;
handles.DefVar.RectsArray{i}(j,:)=pointMat;
if ~isempty(handles.DefVar.imRectM)
    api2=iptgetapi(handles.DefVar.imRectM);
    mirPos=computMirror(pointMat,handles.DefVar.ErweiPos,handles.DefVar.ZaoyingPos);
    if ~isempty(mirPos)
        api2.setPosition(mirPos);
    else
        handles.DefVar.imRectM=[];
    end
end
guidata(hObject,handles);

function impoly_newPosition2(h,hObject,i,j)
handles=guidata(hObject);
api=iptgetapi(h);
pointMat=api.getPosition;
if ~isempty(handles.DefVar.imRect)
    api2=iptgetapi(handles.DefVar.imRect);
    mirPos=computMirror(pointMat,handles.DefVar.ErweiPos,handles.DefVar.ZaoyingPos);
    if ~isempty(mirPos)
        api2.setPosition(mirPos);
        handles.DefVar.RectsArray{i}(j,:)=mirPos;
    end
end
guidata(hObject,handles);

% --- Executes on button press in autoA.
function autoA_Callback(hObject, eventdata, handles)
% hObject    handle to autoA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of autoA
if hObject.Value==1
    if handles.LeftIsZaoying.Value==2
        leftIsErwei=true;
    else
        leftIsErwei=false;
    end
    ax=findobj(handles.figure1,'type','uicontrol');
    set(ax,'Enable','off');
    [ableToAuto,ShuangfuTimeSeries,BofangTimeSeries,time_array,vx,out_series,pos_left,pos_right]=get_good_frame(handles.DefVar.fullname,leftIsErwei);
    if ableToAuto
        if leftIsErwei
            handles.DefVar.ZaoyingPos=[pos_right(1),20,pos_right(3),pos_right(4)+pos_right(2)-20];
            handles.DefVar.ErweiPos=[pos_left(1),20,pos_left(3),pos_left(4)+pos_left(2)-20];
        else
            handles.DefVar.ZaoyingPos=[pos_left(1),20,pos_left(3),pos_left(4)+pos_left(2)-20];
            handles.DefVar.ErweiPos=[pos_right(1),20,pos_right(3),pos_right(4)+pos_right(2)-20];
        end
                %         handles.DefVar.ShuangfuTimeSeries=ShuangfuTimeSeries;
                %         handles.DefVar.BofangTimeSeries=BofangTimeSeries;
                %         handles.DefVar.time_array=time_array;
                %         handles.DefVar.vx=vx;
        flowCommand=zeros(40,length(time_array),3)+192;%背景色 灰色 代表暂停
                %        figure;
                %        imshow(flowCommand);
        
                %        imshow(flowCommand);
                for wl=1:size(BofangTimeSeries,1)%绿色 代表单幅播放
                    flowCommand(:,BofangTimeSeries(wl,1):BofangTimeSeries(wl,2),1)=128;
                    flowCommand(:,BofangTimeSeries(wl,1):BofangTimeSeries(wl,2),2)=128;
                    flowCommand(:,BofangTimeSeries(wl,1):BofangTimeSeries(wl,2),3)=64;
                end
        
                for wl=1:size(ShuangfuTimeSeries,1) %蓝色 代表双福变化大
                    flowCommand(:,ShuangfuTimeSeries(wl,1):ShuangfuTimeSeries(wl,2),1)=0;
                    flowCommand(:,ShuangfuTimeSeries(wl,1):ShuangfuTimeSeries(wl,2),2)=128;
                    flowCommand(:,ShuangfuTimeSeries(wl,1):ShuangfuTimeSeries(wl,2),3)=255;
                end
        
        
                %        imshow(flowCommand);
                for wl=1:length(out_series)
                    for wll=1:size(out_series{wl},1) % 红色 双福推荐
                        flowCommand(:,out_series{wl}(wll,1):out_series{wl}(wll,2),1)=225;
                        flowCommand(:,out_series{wl}(wll,1):out_series{wl}(wll,2),2)=0;
                        flowCommand(:,out_series{wl}(wll,1):out_series{wl}(wll,2),3)=0;
                        handles.DefVar.flowRecommand=[handles.DefVar.flowRecommand;[time_array(out_series{wl}(wll,1)),time_array(out_series{wl}(wll,2))]];
        
                    end
                end
                %        imshow(flowCommand);
        handles.DefVar.RecommandPic=flowCommand*1.0/255;
        image(handles.axes2,handles.DefVar.RecommandPic);
        set(handles.axes2,'YTick',[],'YTickLabel',[]);
        %        hold on;
        %        plot(handles.axes2,vx);
        %        hold off;
        ax=findobj(handles.figure1,'type','uicontrol');
        set(ax,'Enable','on');
        handles.FlowLast.Enable='off';
        handles.FlowNext.Enable='off';
        handles.Mirror.Value=1.0;
        handles.Mirror.Enable='on';
        uiMir=findobj('type','Menu','Text','Mirror ROI');
        set(uiMir,'Enable','on');
    else
        ax=findobj(handles.figure1,'type','uicontrol');
        set(ax,'Enable','on');
        handles.FlowLast.Enable='off';
        handles.FlowNext.Enable='off';
        handles.Mirror.Enable='off';
        msgbox('Automatic analysis failed, click OK to close the dialog！！！');
    end
    handles.autoA.Value=0;
    guidata(hObject,handles);
end


% --- Executes on slider movement.
function slider4_Callback(hObject, eventdata, handles)
% hObject    handle to slider4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
set(handles.edit4, 'Value',hObject.Value);


% --- Executes during object creation, after setting all properties.
function slider4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on mouse press over axes background.
function ObjectTrackingAxes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to ObjectTrackingAxes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double
    value=min(max(hObject.Value,0),200);
    set(hObject,'Value',value);
    set(handles.slider4,'Value',value);


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
