

%============================= MF3D_PlotGaze.m ============================
% This function loads the gaze data for a single session date and performs
% some basic analysis to check whether fixation behaviour differed across
% experimental conditions.
%
%==========================================================================

Subject = 'Matcha';
Date    = '20160613';
%addpath(genpath(cd))

%============== SET PATHS FOR CURRENT SYSTEM
Append = [];
if ismac, Append = '/Volumes'; end
[~,CompName] = system('hostname');  
if strcmpi(CompName(1:end-1), 'Aidans-MacBook-Pro.local')
    TimingDir   = fullfile(Append, '/Seagate Backup 1/NeuralData/FacePatchPilot/Timing/StereoFaces');
    GazeDir     = fullfile(Append, '/Seagate Backup 1/NeuralData/FacePatchPilot/TDT_convertedTDT_converted/',Subject,Date);
else
    TimingDir   = fullfile(Append, '/procdata/murphya/Physio/StereoFaces/Timing/StereoFaces');
    GazeDir     = fullfile(Append, '/rawdata/murphya/Physio/TDT_converted/',Subject,Date);
    ImDir       = fullfile(Append, '/projects/murphya/MacaqueFace3D/BlenderFiles/Renders/Monkey_1/');
end
TimingFile  = fullfile(TimingDir, sprintf('StimTimes_%s_%s.mat', Subject, Date));
GazeFiles  	= wildcardsearch(GazeDir, '*eyeSignal.mat');
load(TimingFile)

%=============== Viewing geometry parameters
ADC             = mode([ExpParam.ADCdegHV]');                               	% Get analog-digital conversion for this session
DegPerV         = repmat(204.8,[1,2])./ADC;                                  	% Calculate DVA per Volt
DisplaySizeMM   = [598, 335];                                                   % Size of display monitor (mm)
DisplaySizePx   = [1920, 1080];                                                 % Resolution of display monitor (pixels)
ViewingDistance = 780;                                                          % Viewing distance (mm)
DisplaySizeDeg  = atand(DisplaySizeMM./[ViewingDistance,ViewingDistance]);
DisplayRectDeg  = DisplaySizeDeg/2;
HistEdges{1}    = linspace(-DisplayRectDeg(1), DisplayRectDeg(1), DisplaySizePx(1));
HistEdges{2}    = linspace(-DisplayRectDeg(2), DisplayRectDeg(2), DisplaySizePx(2));

%=============== Load gaze data from all blocks
Eye.Signal  = [];
Eye.Times   = [];
for f = 1:numel(GazeFiles)
    fprintf('Loading eye tracking data (%d/%d)...\n', f, numel(GazeFiles));
    load(GazeFiles{f})
    [eyeCh,eyeSig,eyeSigPerSample] = size(eyeCodesAll);                                                     % Check matrix dimensions
    for n = 1:eyeCh                                                                                         % For each channel...
        AllEyeCodes(n,:) = reshape(permute(eyeCodesAll(n,:,:),[3,2,1]),[1,numel(eyeCodesAll(n,:,:))]);      % Reshape eye signal
        if n < 3
            AllEyeCodes(n,:)    = AllEyeCodes(n,:)*DegPerV(n);                                              % Convert volts to degrees visual angle
        end
    end
    eyeTimes            = linspace(0, eyeTimesAll(end), length(AllEyeCodes));
    Eye.Signal        	= [Eye.Signal, AllEyeCodes];
    if f > 1
        Eye.Times   	= [Eye.Times, eyeTimes+Eye.Times(end)+eyeTimes(2)];
    else
        Eye.Times     	= eyeTimes;
    end
end

% %============== Sanity check
% figure;
% ah(1) = subplot(3,1,1);
% SampleIndx = 60000:160000;
% plot(Eye.Times(SampleIndx), Eye.Signal(1,SampleIndx), '-r');
% ylabel('Eye X position (dva)','fontsize', 18);
% grid on
% ah(2) = subplot(3,1,2);
% plot(Eye.Times(SampleIndx), Eye.Signal(2,SampleIndx), '-r');
% ylabel('Eye Y position (dva)','fontsize', 18);
% grid on
% ah(3) = subplot(3,1,3);
% plot(Eye.Times(SampleIndx), PD.Signal(1,SampleIndx), '-b');
% grid on
% xlabel('Time (seconds)','fontsize', 18);
% ylabel('Photodiode (V)','fontsize', 18);
% linkaxes(ah, 'x');


%=============== Gather gaze data by stimulus ID
TrialPeriod     = [-0.1, 0.4]; 
StimSamples     = round(diff(TrialPeriod)*eyeSampleRate);
Fh  = figure('position',get(0,'screensize'));
AxH = tight_subplot(6,9,0.02,0.02,0.02);
for S = 1:numel(Stim.Onsets)
    Eye.SigX{S} = [];
    Eye.SigY{S} = [];
    Eye.SigP{S} = [];
    for t = 1:numel(Stim.Onsets{S})
        StimTime    = Stim.Onsets{S}(t)+TrialPeriod;
        StimSample1 = find(Eye.Times > Stim.Onsets{S}(t)+TrialPeriod(1));
        Eye.SigX{S}     = [Eye.SigX{S}; Eye.Signal(1, StimSample1(1)+(0:StimSamples-1))];
        Eye.SigY{S}     = [Eye.SigY{S}; Eye.Signal(2, StimSample1(1)+(0:StimSamples-1))];
        Eye.SigP{S}     = [Eye.SigP{S}; Eye.Signal(3, StimSample1(1)+(0:StimSamples-1))];
    end
    
    %============= Plot gaze distribution over stimuli
    axes(AxH(S));
    [Im,Cm,ImAlpha]	= imread(fullfile(ImDir, Params.Filenames{S}));
    ImH(S,1)        = imagesc(DisplaySizeDeg([1,1]).*[-0.5,0.5], DisplaySizeDeg([2,2]).*[-0.5,0.5], Im(:,1:size(Im,2)/2, :));
    alpha(ImH(S,1), ImAlpha(:,1:size(ImAlpha,2)/2, :));
    hold on;
%     HistH = ndhist(reshape(Eye.SigX{S}',[1,numel(Eye.SigX{S})]), reshape(Eye.SigY{S}',[1,numel(Eye.SigY{S})]));
    HistH = hist3([reshape(Eye.SigX{S}',[numel(Eye.SigX{S}),1]), reshape(Eye.SigY{S}',[numel(Eye.SigY{S}),1])],...
        'edges', HistEdges);
    ImH(S,2)  	= imagesc(DisplaySizeDeg([1,1]).*[-0.5,0.5], DisplaySizeDeg([2,2]).*[-0.5,0.5], HistH');
    alpha(ImH(S,2), 0.5);
    FmH(S,1)      = plot(0,0,'.g');
    FmH(S,2)      = plot(xlim, [0,0],'--w');
    FmH(S,3)      = plot([0,0],ylim,'--w');
    axis equal tight
    box off
    set(gca,'color', [0.5, 0.5, 0.5]);
    drawnow
end

%============= Save processed gaze data
SaveDir = fullfile(Append, '/procdata/murphya/Physio/StereoFaces/Gaze',Subject);
Filename = fullfile(SaveDir, sprintf('GazeBehaviour_%s_%s.mat', Subject, Date));
save(Filename, 'Eye');

