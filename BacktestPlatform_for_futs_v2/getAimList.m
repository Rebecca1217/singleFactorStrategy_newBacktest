function aimHands = getAimList(hisHands,hisMainCont,tradeList)
% 根据历史持仓和交易单确定目标持仓

hisList = table;
hisList.futCont = {hisMainCont};
hisList.hands = hisHands;

% 合并
list = [hisList;tradeList];
aimList = varfun(@sum,list,'GroupingVariables',{'futCont'});
aimList = aimList(:,{'futCont';'sum_hands'});
aimList.Properties.VariableNames = {'futCont';'hands'};
if height(aimList)==2
    aimHands = aimList(aimList.hands~=0,:);
else
    aimHands = aimList;
end


end