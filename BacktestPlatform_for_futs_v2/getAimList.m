function aimHands = getAimList(hisHands,hisMainCont,tradeList)
% ������ʷ�ֲֺͽ��׵�ȷ��Ŀ��ֲ�

hisList = table;
hisList.futCont = {hisMainCont};
hisList.hands = hisHands;

% �ϲ�
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