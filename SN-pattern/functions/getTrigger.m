function triggerTime = getTrigger(cfg)

KbQueueCreate;
KbQueueStart;

while 1
    [pressed, firstPress]=KbQueueCheck;
    if pressed
        kidx = find(firstPress);
        kstr = KbName(kidx);
        if ismember(kstr,cfg.triggerKeys) 
            triggerTime = firstPress(kidx);
            fprintf("%s key pressed at %.3f\n",kstr,triggerTime)
            break
        end
    end
end

KbQueueRelease;

end