
%========================= AnalyzeStereoFaces.m ===========================
% This script loads data from all sessions of a specified experiment and
% saves processed data for each, which can then be combined.
%
%==========================================================================

ExpName         = 'StereoFaces';
SubjectID       = 'Matcha';
DateStrings     = {'20160613','20160614','20160615','20160616','20160617'};
ExpTypes       	= [1, 1, 2, 2, 3];

%======================== GET PATHS
[~,CompName] = system('hostname');  
if strcmpi(CompName(1:end-1), 'Aidans-MacBook-Pro.local')
    NeuralDataDir 	= fullfile('/Volumes/Seagate Backup 1/NeuralData/FacePatchPilot/RawLFP',SubjectID);
    ProcDataDir     = fullfile('/Volumes/Seagate Backup 1/NeuralData/FacePatchPilot/');
else
    NeuralDataDir 	= fullfile('/Volumes/PROCDATA/murphya/Physio/WaveClusSorted/',SubjectID);
    ProcDataDir     = '/Volumes/PROCDATA/murphya/Physio/StereoFaces';
end

%======================== ANALYSE DATA
for d = 1:numel(DateStings)
    %============ Get conditions info
	ConditionsFile{d}   = fullfile(ProcDataDir, sprintf('StereoFaces_Conditions_%s.mat', DateStrings{d}));
    if exist(ConditionsFile{d}, 'file')
        load(ConditionsFile{d});
    else
        fprintf('Conditions file %s does not exist... creating new conditions file\n', ConditionsFile{d});
        Params = GetConditions(ExpTypes(d));
    end
    
    %============ Get timing info
    TimingFile{d}       = fullfile(ProcDataDir, 'Timing/StereoFaces', sprintf('StimTimes_%s_%s.mat', SubjectID, DateStrings{d}));
    if exist(TimingFile{d}, 'file')
        load(TimingFile{d});
    else
        fprintf('Timing file %s does not exist... creating new timing file\n', TimingFile{d});
        [QNX, PD] = GetStimulusTimes(ExpName, SubjectID, DateStrings{d}, ExpTypes(d), 0);
    end

    %============ Analyse data from all channels
    RawLFPfiles = wildcardsearch(fullfile(NeuralDataDir, DateStrings{d}), '*.mat');
    PlotERPs(RawLFPfiles, Timing, Cond);
    PlotSpect(RawLFPfiles, Timing, Cond);

end

