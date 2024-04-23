function el = setupEyelink(cfg,rect,edf_filename)


% set "width" and "height"
width = rect(3);
height = rect(4);
cfg.vDistance = 107.5; % scanner viewing distance w/ eyetracker
cfg.dWidth = 41.5; % scanner display width w/ eyetracker
ppd = pi*rect(3) / atan(cfg.dWidth/cfg.vDistance/2) / 360; % pixels per degree

% Initialize
el = EyelinkInitDefaults(cfg.win);

% Set display colors
el.backgroundcolour = [0,0,0];
el.foregroundcolour = [100 100 100];
el.calibrationtargetcolour = [255,255,255];

EyelinkUpdateDefaults(el); % Apply the changes set above.

% Check it came up.
if ~EyelinkInit(0)
    fprintf('Eyelink Init aborted.\n');
    Eyelink('Shutdown');
    return;
end

% Sanity check connection
connected = Eyelink('IsConnected')
[v vs] = Eyelink('GetTrackerVersion');
fprintf('Running experiment on a ''%s'' tracker.\n', vs);

% open file to record tracker data
tempeyefile = Eyelink('Openfile', edf_filename);
if tempeyefile ~= 0
    fprintf('Cannot create EDF file ''%s'' ', edf_filename);
    Eyelink('Shutdown');
    return;
end

% Host PC parameters
Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, rect(3)-1, rect(4)-1); % 0,0,width,height
Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, rect(3)-1, rect(4)-1);

% 9-target calibration - specify target locations.
Eyelink('command', 'calibration_type = HV9');
Eyelink('command', 'generate_default_targets = NO');

caloffset=round(4.5*ppd); % changed from 6.5 to 4.5 according to Abby code
Eyelink('command','calibration_samples = 10');
Eyelink('command','calibration_sequence = 0,1,2,3,4,5,6,7,8,9');
Eyelink('command','calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d',...
    round(width/2),round(height/2),  round(width/2),round(height/2)-caloffset,  round(width/2),round(height/2) + caloffset,  round(width/2) -caloffset,round(height/2),  round(width/2) +caloffset,round(height/2),...
    round(width/2)-caloffset, round(height/2)- caloffset, round(width/2)-caloffset, round(height/2)+ caloffset, round(width/2)+caloffset, round(height/2)- caloffset, round(width/2)+caloffset, round(height/2)+ caloffset);
Eyelink('command','validation_samples = 9');
Eyelink('command','validation_sequence = 0,1,2,3,4,5,6,7,8,9');
Eyelink('command','validation_targets = %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d',...
    round(width/2),round(height/2),  round(width/2),round(height/2)-caloffset,  round(width/2),round(height/2) + caloffset,  round(width/2) -caloffset,round(height/2),...
    round(width/2) +caloffset,round(height/2),...
    round(width/2)-caloffset, round(height/2)- caloffset, round(width/2)-caloffset, round(height/2)+ caloffset, round(width/2)+caloffset, round(height/2)- caloffset, round(width/2)+caloffset, round(height/2)+ caloffset);

% Set lots of criteria
Eyelink('command', 'saccade_acceleration_threshold = 8000');
Eyelink('command', 'saccade_velocity_threshold = 30');
Eyelink('command', 'saccade_motion_threshold = 0.0');
Eyelink('command', 'saccade_pursuit_fixup = 60');
Eyelink('command', 'fixation_update_interval = 0');

% set EDF file contents
Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS');

% set link data (used for gaze cursor)
Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS');

% make sure we're still connected.
if Eyelink('IsConnected')~=1
    Eyelink( 'Shutdown');
    return;
end

% Initial calibration of the eye tracker
EyelinkDoTrackerSetup(el);
eye_used = Eyelink('EyeAvailable');
    

%% draw box of fixation

% Must be offline to draw to EyeLink screen
Eyelink('Command', 'set_idle_mode');

% clear tracker display and draw box at fix point
box = round(2.5*ppd);
Eyelink('Command', 'clear_screen 0')
Eyelink('command', 'draw_box %d %d %d %d 15', (width/2)-box, (height/2)-box, (width/2)+box, (height/2)+box);

end