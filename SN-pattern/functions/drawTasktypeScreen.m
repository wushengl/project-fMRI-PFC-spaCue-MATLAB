function drawTasktypeScreen(cfg,thisTaskType)

switch thisTaskType
    case 'S'
        text1 = sprintf('SPATIAL TASK');
    case 'N'
        text1 = sprintf('NONSPATIAL TASK');
end

Screen('TextSize', cfg.win, cfg.textSize);
DrawFormattedText(cfg.win, text1, 'center','center',[255 255 255]);

end