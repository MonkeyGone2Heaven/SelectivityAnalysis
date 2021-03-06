function MF3D_RunStats(Subject, Channel, Cell)

%========================== MF3D_RunStats.m ===============================
% This function calculates summary statistics for the specified neuron
% based on it's visual responses to the 'finger print 60' stimulus set and
% spike waveform/ inter-spike interval data. A plot is generated for each
% session that the putative neuron was recorded and across-session
% correlations are computed.
%==========================================================================

if nargin == 0
%     Subject     = 'Avalanche';
%     Channel     = 71;
%     Cell        = 1;

    Subject     = 'Spice';
    Channel     = 44;
    Cell        = 2;
end

switch Subject
    case 'Avalanche'
        Dates	= {'20160627','20160628','20160629','20160630','20160712','20160713','20160714','20160715'};
    case 'Matcha'
        Dates   = {'20160615','20160616','20160617','20160719','20160720','20160721','20160722'};
    case 'Spice'
        Dates   = {'20160620','20160621','20160622','20160623','20160624'};
end

for d = 2:numel(Dates)
    MF3D_RunSessionStats(Subject, Dates{d}, Channel, Cell);
end

end


function MF3D_RunSessionStats(Subject, Date, Channel, Cell)

%============= Load data
Append              = [];
if ismac, Append    = '/Volumes'; end
FingerPrintDataFile = fullfile(Append, '/procdata/murphya/Physio/StereoFaces/PSTHs/FingerPrint/', Subject, Date, sprintf('%s_%s.mat', Subject, Date));
StereoDataFile      = fullfile(Append, '/procdata/murphya/Physio/StereoFaces/PSTHs/', Subject, Date, sprintf('%s_%s.mat', Subject, Date));
WaveClusDir         = fullfile(Append, '/NIF/procdata/murphya/Physio/FingerPrint/',Subject, Date, sprintf('%d',Channel));
SaveDir             = fullfile(Append, '/procdata/murphya/Physio/StereoFaces/FingerPrintSummary/', Subject);
if ~exist(SaveDir, 'dir')
    mkdir(SaveDir);
end
load(FingerPrintDataFile);
% load(StereoDataFile);
ChannelFile         = wildcardsearch(WaveClusDir, 'times*_concat_spikes.mat');
load(ChannelFile{1});

%============ Set analysis parameters

BaselineWindow      = [0, 50];                  % Time window to calculate baseline (ms relative to stimulus onset)
BaselineBins        = find(HistBins>BaselineWindow(1) & HistBins<BaselineWindow(2));
VisRespWindow       = [50, 200];
VisRespBins         = find(HistBins>VisRespWindow(1) & HistBins<VisRespWindow(2));
VisRespThreshSDs   	= 1;                        % Number of standard deviations of baseline for cell to qualify as 'visually responsive'
VisRespDuration     = 20;                       % Number of consecutive bins that response must cross threshold for
VisRespMinspikes    = 300;                      % Minimum number total spikes for cell to qualify as 'visually responsive'
BinWidth            = 10;                       % Bin width for histogram (ms)

LatencyCat          = 1;                        % Calculate latency from average response to best category?
LatencyThreshSDs   	= 3;                        % Number of standard deviations of baseline at which latency is calculated

FP.StimPerCat       = 10;                       
FP.Categories       = {'Human faces','Macaque faces','Bodies','Objects','Scenes','Birds'};
FP.CatNums          = reshape(1:(FP.StimPerCat*numel(FP.Categories)), [FP.StimPerCat,numel(FP.Categories)])';
FP.StimOn           = [0, 100];


cellindx            = ChIndx(ismember(ChIndx(:,[2,3]), [Channel,Cell],'rows'),1);
if isempty(cellindx)
    fprintf('No cell %d on channel %d on %s!\n', Cell, Channel, Date);
    return
end
PlotColors          = [1,0,0; 0 0 1; 0 1 0; 1 0 1; 0 1 1; 1 0.5 0];
PlotColors2         = PlotColors;
PlotColors2(PlotColors2==0) = 0.5;


%=================== Plot mean response for each 'Finger Print' category
Fh      = figure('position', get(0,'screensize'));
Axh(1)  = subplot(2,3,1);
na = 1;
for cat = 1:numel(FP.Categories)                                            % For each category....
    CatSpikeTimes{cellindx, cat} = [];
    nc = 1;                                                                 % Initialize count
    for s = 1:FP.StimPerCat                                                 % For each stimulus....
     	nt = 1;
        for t = 1:size(AllSpikes,3)                                         % For each repetition...
            if ~isempty(AllSpikes{cellindx, FP.CatNums(cat,s), t})
                CatSpikeTimes{cellindx, cat, nc} = AllSpikes{cellindx, FP.CatNums(cat,s), t};
                StimBinData{cellindx, FP.CatNums(cat,s)}(nt,:) = (hist(AllSpikes{cellindx, FP.CatNums(cat,s), t}, HistBins))*(1000/BinWidth);
                CatBinData{cellindx, cat}(nc,:)  = (hist(CatSpikeTimes{cellindx, cat, nc}, HistBins))*(1000/BinWidth);
                AllBinData{cellindx}(na,:)     	 = CatBinData{cellindx, cat}(nc,:);
                nc = nc+1;
                na = na+1;
            end
         	nt = nt+1;
        end
    end
    CatBinMeans{cellindx, cat}	= mean(CatBinData{cellindx, cat});
    CatBinSEM{cellindx, cat}   	= std(CatBinData{cellindx, cat})/sqrt(size(CatBinData{cellindx, cat},1));
    BaselineMean{cellindx}     	= mean(mean(AllBinData{cellindx}(:,BaselineBins)));
    BaselineSD{cellindx}     	= std(mean(AllBinData{cellindx}(:,BaselineBins)));
    
    [ha, hb, hc] = shadedplot(HistBins, CatBinMeans{cellindx, cat}-CatBinSEM{cellindx, cat}, CatBinMeans{cellindx, cat}+CatBinSEM{cellindx, cat}, PlotColors2(cat,:));
    hold on;
    delete([hb, hc]);
    ph(cat) = plot(HistBins, CatBinMeans{cellindx, cat}, '-b', 'color', PlotColors(cat,:), 'linewidth', 2);
end
uistack(ph, 'top');
grid on
box off
set(gca,'fontsize',18,'tickdir','out');
legend(ph, FP.Categories, 'location','northeast','fontsize', 18);
Ylims = get(gca,'ylim');
StimH = patch(FP.StimOn([1,1,2,2]), Ylims([1,2,2,1]), Ylims([1,2,2,1]), 'facecolor', [0.75, 0.75, 0.75], 'edgecolor', 'none', 'facealpha', 0.5);
uistack(StimH, 'bottom');
BaselineThresh  = BaselineMean{cellindx}+BaselineSD{cellindx}*VisRespThreshSDs;
LatencyThresh   = BaselineMean{cellindx}+BaselineSD{cellindx}*LatencyThreshSDs;
baseH   = plot(xlim, repmat(BaselineThresh, [1,2]), '--r', 'linewidth',2);
latH    = plot(xlim, repmat(LatencyThresh, [1,2]), '--g', 'linewidth',2);
set(gca,'ylim', [0, Ylims(2)]);
xlabel('Time (ms)','fontsize', 18);
ylabel('Firing rate (Hz)','fontsize', 18);

%=================== Find visual response and latency
Axh(2)  = subplot(2,3,2);

for s = 1:size(AllSpikes,2)
    Data = reshape(StimBinData{cellindx,s}(:,VisRespBins), [1,numel(VisRespBins)*size(StimBinData{cellindx,s},1)]);
    StimMean(s) = mean(Data);
    StimSEM(s) = std(Data)/sqrt(numel(Data));
end

for cat = 1:numel(FP.Categories)
    StimIndx        = ((cat-1)*FP.StimPerCat) + (1:FP.StimPerCat);
    bh(cat)         = bar(StimIndx, StimMean(StimIndx));
    hold on;
    set(bh(cat), 'facecolor', PlotColors(cat,:));
    
    CatMean(cat)    = mean(CatBinMeans{cellindx, cat}(VisRespBins));
    CatSEM(cat)     = std(CatBinMeans{cellindx, cat}(VisRespBins))/sqrt(numel(VisRespBins));
    CatBarH(cat)    = plot(StimIndx([1,end]), repmat(CatMean(cat),[1,2]), '-k', 'linewidth', 2);%, 'color', PlotColors(cat,:));
    hold on;
    CatEBH(cat)     = errorbar(mean(StimIndx), CatMean(cat), CatSEM(cat), CatSEM(cat), 'color', [0 0 0]);
    FP.CatAbb{cat}  = FP.Categories{cat}(1);
end
grid on
box off
set(gca,'fontsize',18,'tickdir','out','xtick',(FP.StimPerCat/2):FP.StimPerCat:(numel(FP.Categories)*FP.StimPerCat),'xticklabel',FP.CatAbb,'xlim',[0,size(AllSpikes,2)+0.5]);
ylabel('Mean firing rate (Hz)','fontsize', 18);
Ylims = get(gca,'ylim');
BarText = {sprintf('Time window = %d - %d ms', VisRespWindow),...
           sprintf('Preferred category = %s', FP.Categories{2})};
text(4, Ylims(2)-diff(Ylims)*0.2, BarText, 'fontsize', 18);

%=================== Find visual response and latency
Axh(3)  = subplot(2,3,3);
Stats.MeanFR      = [];
Stats.VisualResp  = [];                     % Is the cell visually responsive?
Stats.BestCat     = [];                     % Which category elicited maximal response?
Stats.Latency     = [];                     % What is the latency for the best category?
Stats.FSI         = [];                     % What is the face selectivity index?

%================== Plot FSI timecourse
FaceCat         = 2;                        % Which category to use as 'faces'?
NonFaceCats     = 3:6;                      % Which categories to use as 'non-faces'?
NonFaceBin      = [];
for n = 1:numel(NonFaceCats)
    NonFaceBin      = [NonFaceBin; CatBinData{cellindx, n}];
end
RespFace        = CatBinMeans{cellindx, FaceCat};
RespNonFace     = mean(NonFaceBin);
FSI             = (RespFace-RespNonFace)./(RespFace+RespNonFace);
MFSI            = (CatBinMeans{cellindx, 2}-CatBinMeans{cellindx, 1})./(CatBinMeans{cellindx, 2}+CatBinMeans{cellindx, 1});

Axh(4)          = subplot(2,3,4);
FSIH(1)         = plot(HistBins, FSI, '-r', 'linewidth',2);
hold on;
FSIH(2)         = plot(HistBins, MFSI, '-b', 'linewidth',2);
legend(FSIH, {'Faces vs non-faces','Macaque vs Human'}, 'location','northeast','fontsize', 18);
plot(xlim, [0.33,0.33], '--k');
plot(xlim, -[0.33,0.33], '--k');
plot(xlim, [0, 0], '-k');
grid on
box off
set(gca,'fontsize',18,'tickdir','out');
xlabel('Time (ms)','fontsize', 18);
ylabel('Face Selectivity Index','fontsize', 18);

%================== Plot waveform
Axh(5)              = subplot(2,3,5);
SampleRate          = 24000;
spikes              = spikes*10^6;
TimePoints          = linspace(0, size(spikes,2)/SampleRate*1000, size(spikes,2));
SpikeIndx           = find(cluster_class(:,1)==Cell);
WaveMean            = mean(spikes(SpikeIndx,:));
WaveSEM             = std(spikes(SpikeIndx,:))/sqrt(size(spikes(SpikeIndx,:),1));
WaveAmp             = min(WaveMean);
WavePeak            = find(WaveMean<WaveAmp/2);
WaveFWHM            = diff(TimePoints(WavePeak([1, end])));
WavesH              = plot(TimePoints, spikes(SpikeIndx,:), '-b', 'color', [0.5,0.5,1]);
hold on;
WaveH               = plot(TimePoints, WaveMean,'-b','linewidth',2); 
WaveAmpH            = plot(xlim, [WaveAmp,WaveAmp], '--k');
WaveFWHMH         	= plot(TimePoints(WavePeak([1, end])), [WaveAmp/2,WaveAmp/2], '-g', 'linewidth',2);
grid on
box off
axis tight
set(gca,'fontsize',18,'tickdir','out');
xlabel('Time (ms)','fontsize', 18);
ylabel('Voltage (\muV)', 'fontsize', 18);
Ylims = get(gca,'ylim');
WaveText = {sprintf('Wave amplitude = %.1f \muV', WaveAmp),...
            sprintf('Wave FWHM      = %.2f ms',WaveFWHM)};
text(1.2, Ylims(1)+diff(Ylims)*0.15, WaveText, 'fontsize', 18);

%================== Plot ISI distribution
Axh(6)          = subplot(2,3,6);
% ISIs            = diff();
% hist(ISIs, 100);
hold on;
grid on
box off
axis tight
set(gca,'fontsize',18,'tickdir','out');
xlabel('ISI (ms)','fontsize', 18);
ylabel('Frequency', 'fontsize', 18);


%================== Save figure and data
suptitle(sprintf('%s Ch %d cell %d - %s', Subject, Channel, Cell, Date), 20);
Filename = fullfile(SaveDir, sprintf('%s_Ch%d_cell%d_%s.png', Subject, Channel, Cell, Date)); 
export_fig(Filename, '-png','-transparent');


end