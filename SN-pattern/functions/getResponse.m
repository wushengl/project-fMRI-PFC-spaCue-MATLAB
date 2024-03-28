function [response,responseTime] = getResponse(cfg)

KbQueueCreate;
KbQueueStart;
anyPressed = 0;

while GetSecs - cfg.respStartTime < cfg.respDur
    [pressed, firstPress]=KbQueueCheck;
    if pressed
        kidx = find(firstPress);
        kstr = KbName(kidx);
        if ismember(kstr,cfg.responseKeys) 
            response = kidx;
            responseTime = firstPress(kidx);
            anyPressed = 1;
            fprintf("%s key pressed at %.3f\n",kstr,responseTime)
            break
        elseif ismember(kstr,cfg.escapeKey)
            % workspace is saved per trial, don't need to worry about that
            closeNcleanup(cfg)
            error("Escape key pressed")
        end
    end
end

if ~anyPressed
    response = nan;
    responseTime = nan;
end

KbQueueRelease;

end