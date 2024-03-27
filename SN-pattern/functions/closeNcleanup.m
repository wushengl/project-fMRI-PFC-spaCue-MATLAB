function closeNcleanup(cfg)
if cfg.eyetracker
     Eyelink('Command', 'set_idle_mode');
     WaitSecs(0.5);
     Eyelink('CloseFile');
     % download data file
     
     try
         fprintf('Receiving data file ''%s''\n', cfg.edf_filename );
         status=Eyelink('ReceiveFile');
         if status > 0
             fprintf('ReceiveFile status %d\n', status);
         end
         if 2==exist(cfg.edf_filename, 'file')
             fprintf('Data file ''%s'' can be found in ''%s''\n', cfg.edf_filename, pwd );
         end
     catch
         fprintf('Problem receiving data file ''%s''\n', cfg.edf_filename );
     end
     %%%%%%%%%%%%%%%%shut it down
     Eyelink('ShutDown');
end

PsychPortAudio('Close', cfg.pahandle);
Screen('CloseAll');
end