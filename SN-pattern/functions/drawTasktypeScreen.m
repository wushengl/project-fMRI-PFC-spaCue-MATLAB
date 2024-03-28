function drawTasktypeScreen(cfg,thisTaskType,blockID)

switch thisTaskType
    case 'S'
        text1 = sprintf('SPATIAL TASK');
    case 'N'
        text1 = sprintf('NONSPATIAL TASK');
end

text2 = sprintf('BLOCK %d',blockID);

Screen('TextSize', cfg.win, cfg.textSize);
DrawFormattedText(cfg.win, text2, 'center',(cfg.rect(4)/2 - 20),[255 255 255]);
DrawFormattedText(cfg.win, text1, 'center',(cfg.rect(4)/2 + 20),[255 255 255]);

end