
%======================== MF3D_PlotCategoryResponses.m ====================
% Plot head orientation tuning for STS cells tested in 'StereoFace' pilot
% experiments.
%
%==========================================================================

Subject     = 'Avalanche';
Date        = '20160627';
Expression  = 'Neutral';

switch Subject
    case 'Avalanche'
        if strcmp(Date, '20160629')
            Expression = 'Fear';
        end
    case 'Matcha'
     	if strcmp(Date, '20160615')
            Expression = 'Fear';
        end
    case 'Spice'
       	if strcmp(Date, '20160622')
            Expression = 'Fear';
        end
end

%============= Set directories
if ~exist('AllSpikes','var')
    Append  = [];
    if ismac, Append = '/Volumes'; end
    StimDir                 = fullfile(Append, '/projects/murphya/MacaqueFace3D/BlenderFiles/Renders/Monkey_1/');
    TimingData              = fullfile(Append, '/procdata/murphya/Physio/StereoFaces/Timing/StereoFaces/',sprintf('StimTimes_%s_%s.mat', Subject, Date));
    ProcessedSessionData    = fullfile(Append, '/procdata/murphya/Physio/StereoFaces/PSTHs/',Subject,Date,sprintf('%s_%s.mat', Subject, Date));
    HeadOrientationImage    = fullfile(Append, '/projects/murphya/MacaqueFace3D/PilotData/PNGs/', sprintf('OrientStim_%s.png', Expression));
    load(TimingData)
    load(ProcessedSessionData);
end


%============= Settings
Channel     = 76;
CellIndx   	= 1;
Cell        = find(ismember(ChIndx(:,[2,3]), [Channel, CellIndx], 'rows'));
Twin        = [80, 200];                                                    % Specify time window to calculate mean response from (ms)
BaseWin     = [-50 50];                                                     % Specify time window to calculate baseline response from (ms)


%========== Pool neural data across scales and depths
figure('position', [-1911, 168, 1799, 840]);
Axh     = tight_subplot(3,7,0.02, 0.02,0.02);
AxIndx  = 1;
Ylims   = [0 100];                                                  % Specify 
Tindx   = find(HistBins>Twin(1) & HistBins<Twin(2));
BaseIndx = find(HistBins>BaseWin(1) & HistBins<BaseWin(2));
WinColor = [0.5, 0.5, 0.5];
WinAlpha = 0.5;

for el = 1:numel(Params.Elevations)
    for az = 1:numel(Params.Azimuths)
        CondIndx = find(ismember(Params.ConditionMatrix(:,[2,3]), [az, el],'rows'));
        OrientationSDF{az,el} = [];
        for c = 1:numel(CondIndx)
            for t = 1:size(AllSpikes, 3)
                 if ~isnan(AllSpikes{Cell, CondIndx(c), t})
                     OrientationSDF{az,el}(end+1,:) = hist(AllSpikes{Cell, CondIndx(c), t}, HistBins)*10^3/diff(HistBins([1,2]));
                 end
            end
        end

        OrientRawMean(az, el)   = mean(mean(OrientationSDF{az,el}(:,Tindx)));
        OrientBaseMean(az, el)  = mean(mean(OrientationSDF{az,el}(:,BaseIndx)));
        OrientRawSEM(az, el)    = std(std(OrientationSDF{az,el}(:,Tindx)))/sqrt(size(OrientationSDF{az,el},1));
        OrientDiffMat(az, el)   = OrientRawMean(az, el)-OrientBaseMean(az, el);

        axes(Axh(AxIndx));
        BinSEM{az, el} = std(OrientationSDF{az,el})/sqrt(size(OrientationSDF{az,el}, 1));
        [ha, hb, hc] = shadedplot(HistBins, mean(OrientationSDF{az,el})-BinSEM{az, el}, mean(OrientationSDF{az,el})+BinSEM{az, el}, [1,0.5,0.5]);
        hold on;
        delete([hb, hc]);
        plot(HistBins, mean(OrientationSDF{az,el}), '-r');
        ph = patch(Twin([1,1,2,2]), Ylims([1,2,2,1]), Ylims([1,2,2,1]), 'facecolor', WinColor, 'edgecolor', 'none', 'facealpha', WinAlpha);
        uistack(ph, 'bottom')
        xlabel('Firing rate (Hz)');
        AxIndx = AxIndx+1;
        grid on
        %axis off
    end
end
set(Axh, 'ylim', Ylims);
suptitle(sprintf('%s %s channel %d cell %d', Subject, Date, Channel, CellIndx));
export_fig(fullfile(Append, '/PROCDATA/murphya/Physio/StereoFaces/HeadOrientationTuning', Subject,sprintf('AllOrientations_%s_%s_ch%03d_cell%d.png',Subject, Date, Channel, CellIndx)), '-png');

twin = inputdlg({'Time window start (ms)','Time window end (ms)'},'Time window', 1, {sprintf('%0.2f', Twin(1)), sprintf('%0.2f', Twin(2))});
if isempty(twin)
    return
end
Twin = [str2num(twin{1}), str2num(twin{2})];


%% ================ PLOT ORIENTATION SUMMARY FIGURE =======================
LegendOn                = 1;
mfh                     = figure('name',sprintf('%s %s - cell %d orientation analysis', Subject, Date, Cell),'position',[1,1,650,1007]);
Axh(1)                  = subplot(3,2,1);
Colors                  = jet(size(OrientationSDF,1));
for az = 1:size(OrientationSDF,1)
    AllEl{az} = [];
    for el = 1:size(OrientationSDF,2)
        AllEl{az} = [AllEl{az}; OrientationSDF{az,el}];
    end
    phaz(az) = plot(HistBins, mean(AllEl{az}),'linewidth',2,'color',Colors(az,:));
    hold on;
end
StimH = plot([0, 300], [1, 1], '-k', 'linewidth', 10);
YlimsC = get(gca,'ylim');
ph = patch([Twin([1,1]),Twin([2,2])], [0,YlimsC([2,2]),0], 0, 'facecolor', WinColor, 'edgecolor', 'none', 'facealpha', WinAlpha);
uistack(ph, 'bottom');
set(get(get(ph,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
set(get(get(StimH,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
if LegendOn == 1
    for az = 1:numel(Params.Azimuths)
        LegendTextAz{az}  = sprintf('%d �',Params.Azimuths(az));
    end
    legend(phaz, LegendTextAz, 'location', 'northeast', 'fontsize',14);
end
xlabel('Time (ms)', 'fontsize', 18);
ylabel('Firing rate (Hz)',  'fontsize', 18);
set(gca,'fontsize',14,'xlim',[HistBins(1), HistBins(end)],'tickdir','out');
grid on
box off
title('Azimuth angle','fontsize', 16)


Axh(2)                  = subplot(3,2,2);
Colors                  = jet(size(OrientationSDF,2));
for el = 1:size(OrientationSDF,2)
    AllAz{el} = [];
    for az = 1:size(OrientationSDF,1)
        AllAz{el} = [AllAz{el}; OrientationSDF{az,el}];
    end
    phel(el) = plot(HistBins, mean(AllAz{el}),'linewidth',2,'color',Colors(el,:));
    hold on;
end
StimH = plot([0, 300], [1, 1], '-k', 'linewidth', 10);
YlimsC = get(gca,'ylim');
ph = patch([Twin([1,1]),Twin([2,2])], [0,YlimsC([2,2]),0], 0, 'facecolor', WinColor, 'edgecolor', 'none', 'facealpha', WinAlpha);
uistack(ph, 'bottom');
set(get(get(ph,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
set(get(get(StimH,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
if LegendOn == 1
    for el = 1:numel(Params.Elevations)
        LegendTextEl{el}  = sprintf('%d �',Params.Elevations(el));
    end
    legend(phel, LegendTextEl, 'location', 'northeast', 'fontsize',14);
end
xlabel('Time (ms)', 'fontsize', 18);
ylabel('Firing rate (Hz)',  'fontsize', 18);
set(gca,'fontsize',14,'xlim',[HistBins(1), HistBins(end)],'tickdir','out');
grid on
box off
title('Elevation angle','fontsize', 16)

%============== Plot orientation firing rate matrix
Axh(3)                  = subplot(3,2,[3,4]);
[HeadIm,cm,HeadAlpha]   = imread(HeadOrientationImage);                                   % Load head orientation overlay
HeadImSize              = size(HeadIm);
PixelOffset             = round([HeadImSize(1)/size(OrientDiffMat,2), HeadImSize(2)/size(OrientDiffMat,1)]/2);
imh(1)                  = imagesc([PixelOffset(2), HeadImSize(2)-PixelOffset(2)],[PixelOffset(1), HeadImSize(1)-PixelOffset(1)], OrientDiffMat');                                                       
hold on
imh(2)                  = image(HeadIm);                                                    % Draw head image overlay
alpha(imh(2), HeadAlpha);                                                                   % Set alpha transparency
axis equal tight
colormap hot
box off
set(gca,'xtick',linspace(PixelOffset(2), HeadImSize(2)-PixelOffset(2), size(OrientDiffMat,1)),...
        'xticklabel',Params.Azimuths, ...
        'ytick', linspace(PixelOffset(1), HeadImSize(1)-PixelOffset(1), size(OrientDiffMat,2)),...
        'yticklabel',Params.Elevations,...
        'fontsize',16,...
        'tickdir', 'out');
xlabel('Azimuth (�)', 'fontsize', 18);
ylabel('Elevation (�)',  'fontsize', 18);
cbh = colorbar;
set(cbh.Label, 'String', '\Delta Firing rate (Hz)', 'FontSize', 16);

%============== Plot orientation tuning curves for azimuth angle
MainAxPos   = get(gca,'position');
AxH(4)      = subplot(3,2,[5,6]);%axes('position', [MainAxPos(1), MainAxPos(2)-0.05, MainAxPos(3), 0.25]);
Colors    	= jet(size(OrientationSDF,2)+1);
for el = 1:size(OrientDiffMat,2)
%     [ha, hb, hc] = shadedplot(1:size(OrientDiffMat,1), [OrientDiffMat(:,el)-OrientRawSEM(:, el)]', [OrientDiffMat(:,el)+OrientRawSEM(:, el)]', [0.75, 0.75, 0.75]);
%     delete([hb, hc]);
%     hold on
    plh(el) = plot(OrientDiffMat(:,el),'linewidth',2);
    hold on;
    ebh(el) = errorbar(1:size(OrientDiffMat, 1), OrientDiffMat(:,el), OrientRawSEM(:, el), OrientRawSEM(:, el));
    set(ebh(el), 'color', get(plh(el), 'color'));
end
plh(el+1) = plot(mean(OrientDiffMat'),'--k','linewidth',3);
grid on
box off
LegendTextEl{end+1} = 'Mean';
legend(plh, LegendTextEl, 'fontsize',18);
set(gca,'xlim',[0.5, 7.5],'xtick',1:1:7,'xticklabel', Params.Azimuths,'tickdir','out','fontsize',16);
xlabel('Azimuth (�)', 'fontsize', 16);
ylabel('Firing rate (Hz)',  'fontsize', 18);

suptitle(sprintf('Head orientation summary - %s %s channel %d cell %d', Subject, Date, Channel, CellIndx));

%============== Save figure
saveas(mfh, fullfile(Append, '/PROCDATA/murphya/Physio/StereoFaces/HeadOrientationTuning', Subject,sprintf('OrientationTuning_%s_%s_ch%03d_cell%d.eps',Subject, Date, Channel, CellIndx)),'epsc');
%     export_fig(fullfile(Append, '/projects/murphya/MacaqueFace3D/PilotData/PNG/',sprintf('OrientationMatrix_%s_%s_cell%d.png',Subject, Date, Cell)), '-png');


% export_fig(fullfile(Append, '/Volumes/PROCDATA/murphya/Physio/StereoFaces/HeadOrientationTuning',sprintf('OrientationMatrix_%s_%s_cell%d.png',Subject, Date, Cell)), '-png');
