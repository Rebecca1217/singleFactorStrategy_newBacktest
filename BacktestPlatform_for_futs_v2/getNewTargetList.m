function [newList,err] = getNewTargetList(listI)
% 交易单只可能有一下两种情况：
% 1.如果有一个交易单，不用处理
% 2.如果有两个交易单，只有两种情况：
% 2.1.无条件平仓单和无条件开仓单
% 2.2.无条件平仓单和有条件平仓单

err = 0;



if height(listI)==1
    newList = listI(:,{'date';'time';'futCode';'hands';'targetP';'targetC'});
elseif height(listI)==2 %当天有多个交易单
    listO = listI(ismember(listI.Mark,'开'),:);
    listC = listI(ismember(listI.Mark,'平'),:);
    if ~isempty(listO)
        % 轧差
        newList = [listI(1,{'date';'time';'futCode'}),array2table([sum(listI.hands),nan,nan],'VariableNames',{'hands';'targetP';'targetC'})];
    else %两个平仓单
        newList = listI(:,{'date';'time';'futCode';'hands';'targetP';'targetC'});
    end
else
    disp([nu2mstr(listI.date(1)),' ',num2str(listI.time(1)),'导入的交易单有误！！'])
    err = 1;
    return;
end