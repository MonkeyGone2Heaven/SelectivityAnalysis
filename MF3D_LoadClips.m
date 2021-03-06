function Clips = MF3D_LoadClips(ClipFiles, PTBwin, verbose)

%========================= MF3D_LoadClips.m ===============================
% This function loads the movie frames/ image files specified in 'ClipFiles' 
% into PsychToolbox textures and returns the texture handles to them.
%
%==========================================================================

if nargin < 3
    verbose = 0;
end
if nargin < 2
    Method = 2;
else
    Method = 1;
end

%=========== Check memory usage
for c = 1:numel(ClipFiles)
    temp = dir(ClipFiles{c});
    Clips(c).FullFilename   = ClipFiles{c};
    [Clips(c).Dir,Clips(c).Filename,Clips(c).Format] = fileparts(ClipFiles{c});
    Clips(c).MemMB          = temp.bytes/10^6;
end
% if verbose ==1
%     resp = questdlg(sprintf('Total memory required = %.2f MB. Proceed with loading movie files?', sum([Clips.MemMB])), 'Memory Required','Yes','No','Yes');
%     if strcmp(resp, 'No')
%         Clips = [];
%         return
%     end
% end

%=========== Settings
preloadsecs     = [];
pixelFormat     = 5;
AudioVol        = 0;        
StartTime       = 1;        % Start from 1st frame

%=========== Load each clip
%wbh = waitbar(0);
for c = 1:numel(Clips)
    %waitbar(c/numel(Clips), wbh, sprintf('Loading %s = %.2f MB... (%d/%d)',Clips(c).Filename,Clips(c).MemMB,c,numel(Clips)));
    fprintf('Loading %s = %.2f MB... (%d/%d)',Clips(c).Filename,Clips(c).MemMB,c,numel(Clips));
    if verbose == 1 && exist('PTBwin','var')
        TextString = sprintf('Loading %s = %.2f MB... (%d/%d)',Clips(c).Filename,Clips(c).MemMB,c,numel(Clips));
        DrawFormattedText(PTBwin, TextString, 200, 200, [1 1 1]*255);
        Screen('Flip', PTBwin);  
    end

    if Method == 1      %============== Use PTB 'GetMovieImage'
        [Clips(c).handle, Clips(c).TotalDuration, Clips(c).fps, width, height, Clips(c).count, Clips(c).AR] = Screen('OpenMovie', PTBwin, Clips(c).FullFilename, [], preloadsecs, [], pixelFormat);
        Clips(c).FrameDim       = [width, height];
        Clips(c).TotalFrames    = Clips(c).TotalDuration*Clips(c).fps;
        Screen('PlayMovie', Clips(c).handle, 1, [], AudioVol);
        Screen('SetmovieTimeIndex', Clips(c).handle, StartTime, 1); 
        for f = 1:Clips(c).TotalFrames
            Clips(c).framehandles(f) = Screen('GetMovieImage', PTBwin, Clips(c).handle, 1);
        end
        
    elseif Method == 2  %============== Use PTB 'MakeTexture'
        video = mmread(Clips(c).FullFilename, [],[],[],true);           % read movie
        for f = 1:numel(video.frames)
            Clips(c).Frames(:,:,:,f) = video.frames(f).cdata;
        end
        Clips(c).TotalFrames    = video.nrFramesTotal;
        Clips(c).fps            = round(video.rate);
        Clips(c).FrameDim       = [video.width, video.height];
        Clips(c).TotalDuration  = Clips(c).TotalFrames/Clips(c).fps;
%         for f = 1:Clips(c).TotalFrames
%             Clips(c).framehandles(f) = Screen('MakeTexture', Frames(:,:,:,f));
%         end
    end
end
%delete(wbh)