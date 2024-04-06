function drawTasktypeScreen(cfg,thisTaskType,blockID)

taskType = thisTaskType(1);
tarDir = thisTaskType(2);

switch tarDir
    case 'L'
        text3 = sprintf('<');
    case 'R'
        text3 = sprintf('>');
end

switch taskType
    case 'S'
        text2 = sprintf('SPATIAL TASK');
    case 'N'
        text2 = sprintf('NONSPATIAL TASK');
    case 'P'
        text2 = sprintf('PASSIVE');
        text3 = sprintf('<>');
end

text1 = sprintf('BLOCK %d',blockID);

Screen('TextSize', cfg.win, cfg.textSize);
DrawFormattedText(cfg.win, text1, 'center',(cfg.rect(4)/2 - 20),[255 255 255]);
DrawFormattedText(cfg.win, text2, 'center',(cfg.rect(4)/2 + 20),[255 255 255]);
DrawFormattedText(cfg.win, text3, 'center',(cfg.rect(4)/2 + 60),[255 255 255]);

end