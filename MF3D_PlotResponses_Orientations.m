function MF3D_PlotResponses_Orientations(Subject, Date, Channel, CellIndx, Output)

%==================== MF3D_PlotResponses_Orientations.m ===================
% Plot head orientation tuning for STS cells tested in 'StereoFace' pilot
% experiments 1 & 2.
%
%==========================================================================

if nargin == 0
    Subject     = 'Avalanche';
    Date        = '20160715';
    Channel     = 76;
    CellIndx   	= 1;
    Output      = 'svg';
end


Expression  = 'Neutral';
Species     = 'Macaque';
switch Subject
    case 'Avalanche'
%         if datenum(Date, 'yyyymmdd')>datenum('20160629','yyyymmdd')
%             error('Invalid session for orientation analysis!')
%         end
        if strcmp(Date, '20160629')
            Expression = 'Fear';
        end
        if datenum(Date, 'yyyymmdd')>= datenum('20160714','yyyymmdd')
            Species = 'Human';
        end
    case 'Matcha'
        if datenum(Date, 'yyyymmdd')>datenum('20160615','yyyymmdd')
            error('Invalid session for orientation analysis!')
        end
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
    ProcessedSessionData    = fullfile(Append, '/procdata/murphya/Physio/StereoFaces/PSTHs/StereoFaces/',Subject,Date,sprintf('%s_%s.mat', Subject, Date));
    HeadOrientationDir      = fullfile(Append, '/projects/murphya/MacaqueFace3D/PilotExpStim/');
    load(TimingData)
    load(ProcessedSessionData);
end
SaveDir = fullfile(Append, '/procdata/murphya/Physio/StereoFaces/HeadOrientationTuning', Subject);
if ~exist(SaveDir, 'dir')
    mkdir(SaveDir);
end

%=========== Load head oreintation image
switch Species
    case 'Macaque'
        HeadOrientationImage    = fullfile(HeadOrientationDir, sprintf('OrientStim_%s.png', lower(Expression)));
    case 'Human'
        Identity = 1;
        HeadOrientationImage    = fullfile(HeadOrientationDir, sprintf('HumanID_%d.png', Identity));
end
[HeadIm,cm,HeadImAlpha]	= imread(HeadOrientationImage);                                   % Load head orientation overlay
HeadImSize              = size(HeadIm);

%============= Settings
Cell        = find(ismember(ChIndx(:,[2,3]), [Channel, CellIndx], 'rows'));
fh          = figure('position', get(0,'screensize')./[1 1 2 1]);   	% Open half-screen figure window
NoAxY       = numel(Params.Elevations)*2;
NoAxX       = numel(Params.Azimuths);       
Axh         = tight_subplot(NoAxY, NoAxX,0, 0.05,0.05);           	% Generate axes
RastAxIndx  = [];
for r = 1:numel(Params.Elevations)
    RastAxIndx(end+1:end+NoAxX) = (1:NoAxX) + (r-1)*(NoAxX*2);    	% Specify which axes are for raster plots
end
%RastAxIndx  = [1:7, 15:21, 29:35];                                  % Specify which axes are for raster plots
SDFAxIndx   = RastAxIndx+NoAxX;                                   	% Specify axes for SDF plots
Ylims       = [0 100];                                            	% Specify y-axis limits for SDFs (spikes per second)
Xlims       = [-100, 400];                                          % Specify x-axis limits for all axes (ms)       
WinColor    = [0.5, 0.5, 0.5];                                      % Color of sliding window 
WinAlpha    = 0.5;                                                  % Transparency of sliding window
SDFdims     = [0.1,0.05];
Rastdims    = [0.1,0.04];
PlotXpos    = 0.1+(0:(NoAxX-1))*(SDFdims(1)+0.02);
PlotYpos    = 0.02+cumsum([0, SDFdims(2), Rastdims(2),SDFdims(2), Rastdims(2),SDFdims(2)]);
PlotYpos    = PlotYpos(end:-1:1)+0.65;
ph          = [];
lh          = [];
Twin        = [80, 150];                                            % Specify time window to calculate mean response from (ms) *if output type is 'svg'
BaseWin     = [-50 50];                                         	% Specify time window to calculate baseline response from (ms)
BaseIndx    = find(HistBins>BaseWin(1) & HistBins<BaseWin(2));      % Calculate which bins to include as baseline measure
switch Output
    case 'gif'
        TwinPos 	= 0:10:300;                                             % Specify timepoints of window start position (ms)
        TwinWidth   = 50;                                                   % Specify window width (ms)
    case 'svg'
        TwinPos 	= 150;
        TwinWidth   = 100;    
end

%========== Pool neural data across scales and depths
% figure('position', [-1911, 168, 1799, 840]);
% Axh     = tight_subplot(3,7,0.02, 0.02,0.02);
% AxIndx  = 1;
% Ylims   = [0 100];                                                  % Specify 
% Tindx   = find(HistBins>Twin(1) & HistBins<Twin(2));
% BaseIndx = find(HistBins>BaseWin(1) & HistBins<BaseWin(2));
% WinColor = [0.5, 0.5, 0.5];
% WinAlpha = 0.5;

AxIndx = 1;
for el = 1:numel(Params.Elevations)
    for az = 1:numel(Params.Azimuths)
        CondIndx = find(ismember(Params.ConditionMatrix(:,[2,3]), [az, el],'rows'));
     	OrientationSDF{az,el} = [];
        
        %========= Plot rasters
    	axes(Axh(RastAxIndx(AxIndx)));
        line = 1;
        for c = 1:numel(CondIndx)
            for t = 1:size(AllSpikes, 3)
                 if ~isnan(AllSpikes{Cell, CondIndx(c), t})
                     OrientationSDF{az,el}(end+1,:) = hist(AllSpikes{Cell, CondIndx(c), t}, HistBins)*10^3/diff(HistBins([1,2]));
                     for sp = 1:numel(AllSpikes{Cell, CondIndx(c), t})                                            	% For each spike...
                        rph = plot(repmat(AllSpikes{Cell, CondIndx(c), t}(sp), [1,2]), [line-1, line], '-k');       % Draw a vertical line
                        hold on;
                     end
                    line = line+1;
                 end
            end
        end
        axis tight
        box off
        set(gca,'yticklabels',[], 'xticklabels',[]);
        nx = rem(RastAxIndx(AxIndx),NoAxX);
        ny = ceil(RastAxIndx(AxIndx)/NoAxX);
        if nx == 0
            nx = NoAxX;
        end
        set(gca, 'Position', [PlotXpos(nx), PlotYpos(ny), Rastdims]);


        %========= Calculate time window matrices
        for t = 1:numel(TwinPos)
            Twin                    	= [TwinPos(t)-TwinWidth/2, TwinPos(t)+TwinWidth/2];                                   	% Specify time window to calculate mean response from (ms)
            Tindx                   	= find(HistBins>Twin(1) & HistBins<Twin(2));    
            OrientRawMean(az, el, t)    = mean(mean(OrientationSDF{az,el}(:,Tindx)));
            OrientBaseMean(az, el, t)   = mean(mean(OrientationSDF{az,el}(:,BaseIndx)));
            OrientRawSEM{t}(az, el)     = std(std(OrientationSDF{az,el}(:,Tindx)))/sqrt(size(OrientationSDF{az,el},1));
            OrientDiffMat{t}(az, el)    = OrientRawMean(az, el, t)-OrientBaseMean(az, el, t);
            MaxDiffMat(t)               = max(OrientDiffMat{t}(:));
            MinDiffMat(t)               = min(OrientDiffMat{t}(:));
        end
        
        %========= Plot head oreintation SDFs
        axes(Axh(SDFAxIndx(AxIndx)));
        BinSEM{az, el} = std(OrientationSDF{az,el})/sqrt(size(OrientationSDF{az,el}, 1));
        [ha, hb, hc] = shadedplot(HistBins, mean(OrientationSDF{az,el})-BinSEM{az, el}, mean(OrientationSDF{az,el})+BinSEM{az, el}, [1,0.5,0.5]);
        hold on;
        delete([hb, hc]);
        plot(HistBins, mean(OrientationSDF{az,el}), '-r');
        ph(end+1) = patch(Twin([1,1,2,2]), Ylims([1,2,2,1]), Ylims([1,2,2,1]), 'facecolor', WinColor, 'edgecolor', 'none', 'facealpha', WinAlpha);
        lh(end+1) = plot([0,0],Ylims, '-k','linewidth',2);
        uistack(ph(end), 'bottom')
        
        set(gca,'xlim', Xlims, 'ylim', Ylims,'xtick', Xlims(1):100:Xlims(2));
        if ismember(SDFAxIndx(AxIndx), [1:NoAxX:(6*NoAxX)])
            ylabel(sprintf('%d �', Params.Elevations(el)), 'fontsize', 16);
        else
            set(gca,'yticklabels',[]);
        end
        if SDFAxIndx(AxIndx) >= (5*NoAxX)+1
            xlabel(sprintf('%d �', Params.Azimuths(az)), 'fontsize', 16);
        else
            set(gca,'xticklabels',[]);
        end
%             set(gca, 'color', ExpColors(id,:));
        nx = rem(SDFAxIndx(AxIndx),NoAxX);
        ny = ceil(SDFAxIndx(AxIndx)/NoAxX);
        if nx == 0
            nx = NoAxX;
        end
        set(gca, 'Position', [PlotXpos(nx), PlotYpos(ny), SDFdims]);
        AxIndx = AxIndx+1;
        grid on
        box off
        %axis off
        drawnow
    end
end

%========= Adjust y-axis limits
Ylims = [0, ceil(max(MaxDiffMat(:))/50)*50];
set(Axh(SDFAxIndx),'ylim', Ylims);
set(ph, 'Ydata', Ylims([1,2,2,1]));
set(lh, 'Ydata', Ylims);
    
%============== Plot orientation firing rate matrix
t = 1;
MatClims = [min(MinDiffMat(:)), max(MaxDiffMat(:))];

AxMat                   = axes('position', [0.1, 0.28, 0.8 0.32]);
PixelOffset             = round([HeadImSize(1)/size(OrientDiffMat{t},2), HeadImSize(2)/size(OrientDiffMat{t},1)]/2);
imh(1)                  = imagesc([PixelOffset(2), HeadImSize(2)-PixelOffset(2)],[PixelOffset(1), HeadImSize(1)-PixelOffset(1)], OrientDiffMat{t}');                                                       
hold on
imh(2)                  = image(HeadIm);                                                        % Draw head image overlay
alpha(imh(2), HeadImAlpha);                                                                         % Set alpha transparency
axis equal tight
colormap hot
box off
set(gca,'xtick',linspace(PixelOffset(2), HeadImSize(2)-PixelOffset(2), size(OrientDiffMat{t},1)),...
        'xticklabel',Params.Azimuths, ...
        'ytick', linspace(PixelOffset(1), HeadImSize(1)-PixelOffset(1), size(OrientDiffMat{t},2)),...
        'yticklabel',Params.Elevations,...
        'fontsize',16,...
        'tickdir', 'out');
set(gca, 'xticklabel', []);                                                 % Turn off x-tick labels
% xlabel('Azimuth (�)', 'fontsize', 18);
ylabel('Elevation (�)',  'fontsize', 18);
AxColLims       = get(gca,'clim');
cbh             = colorbar;                                               	% Add a color bar
set(cbh.Label, 'String', '\Delta Firing rate (Hz)', 'FontSize', 18);        % Give the color bar a title
cbh.Position    = cbh.Position+[0.03, 0,0,0];                            	% Adjust colorbar position
MatrixPos       = get(AxMat, 'position');

%============== Plot orientation tuning curves for azimuth angle
AxTune      = axes('position', [MatrixPos(1), 0.07, MatrixPos(3), 0.2]);
Colors    	= jet(size(OrientationSDF,2)+1);
for el = 1:size(OrientDiffMat{1},2)
%     [ha, hb, hc] = shadedplot(1:size(OrientDiffMat,1), [OrientDiffMat(:,el)-OrientRawSEM(:, el)]', [OrientDiffMat(:,el)+OrientRawSEM(:, el)]', [0.75, 0.75, 0.75]);
%     delete([hb, hc]);
%     hold on
    plh(el) = plot(OrientDiffMat{1}(:,el),'linewidth',2);
    hold on;
    ebh(el) = errorbar(1:size(OrientDiffMat{1}, 1), OrientDiffMat{1}(:,el), OrientRawSEM{1}(:, el), OrientRawSEM{1}(:, el));
    set(ebh(el), 'color', get(plh(el), 'color'));
    LegendTextEl{el} = sprintf('%d �', Params.Elevations(el));
end
plh(el+1) = plot(mean(OrientDiffMat{1}'),'--k','linewidth',3);
grid on
box off
LegendTextEl{end+1} = 'Mean';
legend(plh, LegendTextEl, 'location', 'EastOutside', 'fontsize',18);
set(gca,'xlim',[0.5, numel(Params.Azimuths)+0.5],'xtick',1:1:numel(Params.Azimuths),'xticklabel', Params.Azimuths,'tickdir','out','fontsize',16);
set(gca,'position', [0.139, 0.0683, 0.67, 0.2]);
xlabel('Azimuth (�)', 'fontsize', 18);
ylabel('\Delta Firing rate (Hz)',  'fontsize', 18);

suptitle(sprintf('%s %s channel %d cell %d', Subject, Date, Channel, CellIndx), 20);


%============= Animate moving window
if strcmpi(Output, 'gif')
    giffilename = fullfile(SaveDir, sprintf('OrientationTimeline_%s_%s_ch%03d_cell%d.gif',Subject, Date, Channel, CellIndx));
    set(AxMat,'clim', MatClims);                                                % Adjust colormap scales for all axes at all timepoints
    set(AxTune,'ylim', MatClims);  
  	ClockH = axes('position', [0.1,0.95,0.1,0.05]);
    ClockTextH = text( 0.5, 0, '0 ms', 'FontSize', 30, 'FontWeight', 'Bold', 'HorizontalAlignment', 'Right', 'VerticalAlignment', 'Bottom' ) ;
    axis off
    for t = 1:numel(TwinPos)
        Twin = [TwinPos(t)-TwinWidth/2, TwinPos(t)+TwinWidth/2];
        set(ClockTextH, 'string', sprintf('%d ms',TwinPos(t)));
        set(ph, 'Xdata', Twin([1,1,2,2]));
        set(lh, 'Xdata', repmat(TwinPos(t),[1,2]));
      	set(imh(1), 'cdata', OrientDiffMat{t}');
        for el = 1:numel(Params.Elevations)
            set(plh(el), 'Ydata', OrientDiffMat{t}(:,el));
            set(ebh(el), 'Ydata', OrientDiffMat{t}(:,el), 'LData', OrientRawSEM{t}(:,el), 'Udata', OrientRawSEM{t}(:,el));
        end
        set(plh(el+1), 'Ydata', mean(OrientDiffMat{t}'));
        drawnow
        frame = getframe(fh);
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        if t == 1
          imwrite(imind,cm,giffilename,'gif', 'Loopcount',inf,'DelayTime', 0.3);
        else
          imwrite(imind,cm,giffilename,'gif','WriteMode','append');
        end

    end
elseif strcmpi(Output, 'svg')
    print('-painters', '-dsvg', fullfile(SaveDir, sprintf('OrientationTuning_%s_%s_ch%03d_cell%d.svg',Subject, Date, Channel, CellIndx)))
    export_fig(fullfile(SaveDir, sprintf('OrientationTuning_%s_%s_ch%03d_cell%d.png',Subject, Date, Channel, CellIndx)), '-png');
end