

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
%HideCursor;
KbName('UnifyKeyNames');
Screen('Preference', 'VisualDebugLevel', 1);     
[Display.win, rect2] = Screen('OpenWindow', Display.ScreenID, Display.Background, Display.Rect,[],[], Display.Stereomode, [], Display.Imagingmode);
Screen('BlendFunction', Display.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);    	% Enable alpha channel   

%============= Load animation data
AnimationDir    = '/Volumes/Seagate Backup 1/NIH_PhD_nonthesis/7. 3DMacaqueFaces/AnimationDemos';
FileFormat      = 'avi';
ClipFiles       = wildcardsearch(AnimationDir, sprintf('*.%s',FileFormat));
Clips           = MF3D_LoadClips(ClipFiles, Display.win);


SourceRect      = Display.Rect;
DestRect        = Display.Rect;

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
FrameOnset = [];
while 1
    %============== Check gaze/ mouse location
    [x,y]           = GetMouse(Display.win);                                  	% Get cursor coordinates (pixels relative to upper left corner)
    EyePos          = [ceil(x),ceil(y)];                                        % Round coordinates to nearest pixel
    for e = 1:2
        if any(EyePos(e) < 1)                                                      % Constrain possible gaze positions based on screen resolution
            EyePos(e) = 1;
        end
        if EyePos(e) > Display.Rect(2+e)
            EyePos(e) = Display.Rect(2+e);
        end
    end
    RegionIndex     = MaskIm(EyePos(2),EyePos(1));                             	% Query which region of the image the cursor is over
    GazeDestRect	= CenterRectOnPoint(GazeRectSize,EyePos(1),EyePos(2));
    if RegionIndex > 0                                                          % If cursor is not over a target...
        DrawMousePos    = 1;
        g = 2;
    else
        DrawMousePos = 1;
        g = 1;
    end
%     Screen('PlayMovie',Clips(1).handle,1,[],Movie.Volume);
%     Screen('SetmovieTimeIndex',Clips(1).handle,StartTime,1); 
%     MovieTex = Screen('GetMovieImage', Display.win, Clips(1).handle, 1);
    MovieTex = Clips(1).framehandles(1);
    
    %============== Draw frame
    for Eye = 1:2                                                                   % For each eye...
        currentbuffer = Screen('SelectStereoDrawBuffer', Display.win, Eye-1);       % Select buffer for each eye
        if exist('MovieTex','var')
            Screen('DrawTexture', Display.win, MovieTex, SourceRect, DestRect);   	% Draw frame for current eye
        end
        %Screen('DrawTexture', Display.win, MaskTex, [], Display.Rect);            	% Draw mask texture to screen
        if DrawMousePos == 1                                                        % If cursor is on target region...
            Screen('DrawTexture', Display.win, GazeMarker(g), [], GazeDestRect);  	% Draw eye position
        end
    end
    [VBL FrameOnset(end+1)] = Screen('Flip', Display.win);                          % Flip frame to screen
    
    %============== Check user input
    [keyIsDown,secs,keyCode] = KbCheck;                                             % Check keyboard for 'escape' press        
    if keyIsDown && keyCode(KbName('Escape')) == 1                                  % Press Esc for abort
        break
    end
    
    
end

%============== Perform clean up
Screen('CloseAll');      
%ShowCursor;

%============== Show some stats about software performance
Frametimes      = diff(FrameOnset);
meanFrameRate   = mean(Frametimes(2:end))*1000;
semFrameRate    = (std(Frametimes(2:end))*1000)/sqrt(numel(Frametimes(2:end)));
fprintf('Frames shown............%.0f\n', numel(Frametimes));
fprintf('Mean frame duration.....%.0f ms +/- %.0f ms\n', meanFrameRate, semFrameRate);
fprintf('Max frame duration......%.0f ms\n', max(Frametimes)*1000);


