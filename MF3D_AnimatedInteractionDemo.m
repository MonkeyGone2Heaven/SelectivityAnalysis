

%==================== MF3D_AnimatedInteractionDemo.m ======================
% This script runs a simple demo of how multiple short movie clips/ image 
% sequences can be presented in an interactive closed loop using standard
% PsychToolbox functions.
%
%
%==========================================================================



%============ Prepare PTB window
Stereo              = 0;                            % Stereoscopic presentation?
Display             = DisplaySettings(Stereo);      % Get display settings
Display.Rect        = Display.Rect/2                % For debugging...
Display.Background  = [0 0 0];                      % Set background color (RGB)
Display.Imagingmode = [];                           
%HideCursor;                                         % Don't show cursor on screen
KbName('UnifyKeyNames');                            % Prepare keyboard
Screen('Preference', 'SkipSyncTests', 1);           % Skip PTB sync tests for now...
Screen('Preference', 'VisualDebugLevel', 1);        % Default PTB window color is black
[Display.win, rect2] = Screen('OpenWindow', Display.ScreenID, Display.Background, Display.Rect,[],[], Display.Stereomode, [], Display.Imagingmode);
Screen('BlendFunction', Display.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);    	% Enable alpha channel   
 

%============= Load animation data
AnimationDir    = '/Volumes/Seagate Backup 1/NIH_PhD_nonthesis/7. 3DMacaqueFaces/AnimationDemos';
AnimationDir    = '/Users/aidanmurphy/Desktop/MacaqueLookAtDemo/';
FileFormat      = 'avi';
ClipFiles       = wildcardsearch(AnimationDir, sprintf('*.%s',FileFormat));
Clips           = MF3D_LoadClips(ClipFiles, Display.win, 1);

%============= Generate blink sequence
Blink.Duration  = Clips(1).TotalDuration;
Blink.NoFrames  = numel(Clips(1).framehandles);
Blink.Total     = 10^5;
Blink.Mu        = 0.2;                                              % Mean blink rate (Hz)
Blink.Sigma     = 0.2;                                              % Standard deviation of blink rate (Hz)
Blink.IBIs      = lognrnd(Blink.Mu,Blink.Sigma,[1,Blink.Total])+2;  % Inter-blink intervals (seconds)
Blink.Onsets    = cumsum(Blink.IBIs);                               % Blink onset times (seconds)
Blink.Count     = 1;
Blink.Frame     = 0;

%============= Generate LookAt timing
LookAt.On           = 0;
LookAt.FPA          = 120;                                      % Frames per action sequence
LookAt.Order        = [5,2,1,4,7,8];
LookAt.StartFrame   = [1, 1+(1:numel(LookAt.Order)-1)*LookAt.FPA];
LookAt.EndFrame     = LookAt.StartFrame+LookAt.FPA/2;


rect2
Display.Rect
DestRect        = Display.Rect*2;

MaskFile        = '/Volumes/Seagate Backup 1/NIH_PhD_nonthesis/7. 3DMacaqueFaces/AnimationDemos/TargetMask2.png';
MaskIm          = imread(MaskFile);
MaskIm          = imresize(MaskIm, Display.Rect([4,3]));
MaskTex         = Screen('MakeTexture', Display.win, double(MaskIm)/max(double(MaskIm(:)))*255);    

GazeRectSize    = [0,0,40,40];
GazeColor       = [1,0,0; 0,1,0]*255;
for g = 1:2
    GazeMarker(g)	= Screen('MakeTexture', Display.win, zeros(GazeRectSize(3), GazeRectSize(4), 4));
    Screen('FillOval', GazeMarker(g), GazeColor(g,:), GazeRectSize-[0,0,5,5]);
end

%============= Begin demo
MovieTex = Clips(1).framehandles(1);
FrameOnset  = [];
EndTrial    = 0;
StartTime   = GetSecs;
while EndTrial == 0
    
    %============== Check gaze/ mouse location
    [x,y,b]        	= GetMouse(Display.win);                                  	% Get cursor coordinates (pixels relative to upper left corner)
    EyePos          = [ceil(x),ceil(y)];                                        % Round coordinates to nearest pixel
    if any(b)                                                                   % If a mouse button was pressed...
        fprintf('Mouse pos = %d, %d\n', EyePos);
    end
    for e = 1:2
        if any(EyePos(e) < 1)                                                	% Constrain possible gaze positions based on screen resolution
            EyePos(e) = 1;
        end
        if EyePos(e) > Display.Rect(2+e)
            EyePos(e) = Display.Rect(2+e);
        end
    end
    RegionIndex     = MaskIm(EyePos(2),EyePos(1));                                      % Query which region of the image the cursor is over
    GazeDestRect	= CenterRectOnPoint(GazeRectSize,EyePos(1),EyePos(2));
    if RegionIndex > 0                                                                  % If cursor is currently over a target...
        DrawMousePos    = 1;
        GazeColorIndx   = 2;
        if LookAt.On == 0
            LookAt.On = 1;
            LookAt.CurrentFrame = LookAt.StartFrame(find(LookAt.Order==RegionIndex));   % Set start frame for saccade
        elseif LookAt.On == 1
            LookAt.CurrentFrame = LookAt.CurrentFrame+1;
            if LookAt.CurrentFrame >= LookAt.StartFrame(find(LookAt.Order==RegionIndex))+LookAt.FPA-1
                LookAt.On = 0;
            end
        end
        MovieTex = Clips(2).framehandles(LookAt.CurrentFrame);
    else
        DrawMousePos = 1;
        GazeColorIndx = 1;
    end
    
    %============ Check blink action
    if Blink.Frame == 0 && LookAt.On == 0                           % If no other action is currently in progress...
        if (GetSecs-StartTime) > Blink.Onsets(Blink.Count)          % If next blink onset time has arrived...
            Blink.Count = Blink.Count+1;                            % Advance blink count
            Blink.Frame = Blink.Frame+1;                            % Advance blink frame count
        end
    elseif Blink.Frame > 0                                          % If current blink frame is not zero
        MovieTex    = Clips(1).framehandles(Blink.Frame);           % Get current blink frame
        Blink.Frame = Blink.Frame+1;                                % Advance blink frame count
        if Blink.Frame > Blink.NoFrames                             % If blink has completed...
            Blink.Frame = 0;                                        % Reset blink frame count to zero
        end
    end
        
%     Screen('PlayMovie',Clips(1).handle,1,[],Movie.Volume);
%     Screen('SetmovieTimeIndex',Clips(1).handle,StartTime,1); 
%     MovieTex = Screen('GetMovieImage', Display.win, Clips(1).handle, 1);

    
    %============== Draw frame
    for Eye = 1:2                                                                   % For each eye...
        currentbuffer = Screen('SelectStereoDrawBuffer', Display.win, Eye-1);       % Select buffer for each eye
        if exist('MovieTex','var')
            Screen('DrawTexture', Display.win, MovieTex, [], DestRect);             % Draw frame for current eye
        end
        %Screen('DrawTexture', Display.win, MaskTex, [], Display.Rect);            	% Draw mask texture to screen
        if DrawMousePos == 1                                                        % If cursor is on target region...
            Screen('DrawTexture', Display.win, GazeMarker(GazeColorIndx), [], GazeDestRect);  	% Draw eye position
        end
    end
    [VBL FrameOnset(end+1)] = Screen('Flip', Display.win);                          % Flip frame to screen
    
    %============== Check user input
    [keyIsDown,secs,keyCode] = KbCheck;                                             % Check keyboard for 'escape' press        
    if keyIsDown && keyCode(KbName('Escape')) == 1                                  % Press Esc for abort
        EndTrial = 1;
        break
    end
    
    
end
disp('Exited loop')

%============== Perform clean up
Screen('CloseAll');  
sca
%ShowCursor;

%============== Show some stats about software performance
Frametimes      = diff(FrameOnset);
meanFrameRate   = mean(Frametimes(2:end))*1000;
semFrameRate    = (std(Frametimes(2:end))*1000)/sqrt(numel(Frametimes(2:end)));
fprintf('Frames shown............%d\n', numel(Frametimes));
fprintf('Mean frame duration.....%.2f ms +/- %.2f ms\n', meanFrameRate, semFrameRate);
fprintf('Max frame duration......%.2f ms\n\n', max(Frametimes)*1000);


