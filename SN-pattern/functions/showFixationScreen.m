function showFixationScreen(cfg)

Screen('TextSize', cfg.win, cfg.textSize);
DrawFormattedText(cfg.win, 'Fixation time...', 'center','center',[255 255 255]);
Screen('Flip', cfg.win);

end