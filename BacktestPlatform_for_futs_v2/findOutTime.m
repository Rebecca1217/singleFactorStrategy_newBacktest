function [outTime,err] = findOutTime(tickData,tradeS,targetP,targetC,crossType)
% 牵扯到日内的情况下，找出场时间点


if ~isnan(targetC)
    difL = tradeS*(tickData.lastprice-targetC);
    timeL = find(difL<0 & [0;difL(1:end-1)]>0,1,'first');
else
    timeL = [];
end
% 上穿或者下穿targetP的时间
if ~isnan(targetP)
    difP = tradeS*(tickData.lastprice-targetP);
    if strcmp(crossType,'up')
        timeP = find(difP>0 & [0;difP(1:end-1)]>0,1,'first');
    else
        timeP = find(difP<0 & [0;difP(1:end-1)]<0,1,'first');
    end
else
    timeP = [];
end
if ~isempty(timeP) && ~isempty(timeL)
    outTime = min([timeP,timeL]);
elseif isempty(timeP) && ~isempty(timeL)
    outTime = timeL;
elseif isempty(timeL) && ~isempty(timeP)
    outTime = timeP;
else 
    disp([num2str(date),' ',num2str(time),'的止盈止损价设置有误！！'])
    err = 1;
    return;
end


end