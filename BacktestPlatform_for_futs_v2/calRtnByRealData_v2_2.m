function [tdList,err] = calRtnByRealData_v2_2(TargetListI,TableData,StrategyPara,TradePara)
% -------����Ŀ�꽻�׵����㾻ֵ2.0--------------
% ----------˵��-----------------
% ��Ե����Խ��лز�
% ����˳��
% ������ƽ-��-������ƽ
% -----------����----------------
% TargetListI������Ʒ���ϵ�Ŀ�꽻�׵�
% TableData:Ʒ�ֶ�Ӧ��table��ʽ������
% -----------���-----------------
% tdList

err = 0;

% ��TargetListI�����ں�ʱ�������һ��
TargetListI(ismember(TargetListI(:,{'date';'time'}),TableData(end,{'date';'time'}),'rows'),:) = [];
[uni,~,locs] = unique(TargetListI(:,{'date';'time'}),'stable');
dateAdd1 = TableData(find(ismember(TableData(:,{'date';'time'}),uni,'rows'))+1,{'date';'time'});
TargetListI(:,{'date';'time'}) = dateAdd1(locs,:);
contAdd1 = TableData(find(ismember(TableData(:,{'date';'time'}),uni,'rows'))+1,{'futCont'});
TargetListI(:,{'futCont'}) = contAdd1(locs,:);
% �ز����
% �����̼ۼ���ӯ��
tdList = [TableData(:,{'date';'time';'futCont'}),array2table(zeros(height(TableData),2),'VariableNames',{'hands';'profit'})]; %���ڣ�ʱ�䣬Ʒ�ִ��룬�ֲ�����(�����򣩣�����ӯ��
for ia = 2:height(TableData)
    li = ismember(TargetListI(:,{'date';'time'}),TableData(ia,{'date';'time'}),'rows');
    listI = TargetListI(li,:); %����Ľ��׵�
    hisHands = tdList.hands(ia-1); %��ǰ����ʷ�ֲ�
%     chgIF = TableData.adjfactor(ia)~=TableData.adjfactor(ia-1); %��һ���ǲ��ǻ�����   
    chgIF = ~strcmp(TableData.mainCont(ia),TableData.mainCont(ia-1));
    hisMainCont = TableData.futCont{ia-1};
    [listI,err] = getNewTargetList_2(listI,hisHands,chgIF,hisMainCont,TableData(ia,{'date';'time';'futCont'}));
    if err==1
        return;
    end
    if isempty(listI) %��һ��û���κν���
        if hisHands==0
            continue;
        else %����ʷ�ֲ�
            tdList.hands(ia) = hisHands;
            tdList.profit(ia) = (TableData.close(ia)-TableData.close(ia-1))*hisHands;
        end
    else %��һ���н���
        tdList.tradeInfo{ia} = listI;
        % ȷ��Ŀ��ֲ�--������֮��ĳֲֺ�Ŀ��ֲֽ��бȶԣ����һ�£�˵��û������
        aimHands = getAimList(hisHands,hisMainCont,listI(:,{'futCont';'hands'}));
        tdList.hands(ia) = aimHands.hands;
        % �����յ������ֳ��������֣���ʷ�ֲ��в��ܽ���Ӱ��Ĳ��ִ���������+���״���������
        if chgIF==0
            hisLeft = sign(hisHands)*min(abs([hisHands,aimHands.hands])); %����Ӱ�������
            profitH = (TableData.close(ia)-TableData.close(ia-1))*hisLeft;
        else
            profitH = 0;
        end
        % ������׵����н���
        profitT = 0;
        for i = 1:height(listI)
            [profitI,err] = getProfit_onBar(TableData(ia-1:ia,:),listI(i,:),StrategyPara,TradePara);
            if err==1
                return;
            end
            profitT = profitT+profitI;
        end
        tdList.profit(ia) = profitT+profitH;
    end
end

tdList.profit = tdList.profit.*TableData.multifactor;    
tdList.riskExposure = abs(tdList.hands).*TableData.close.*TableData.multifactor; %���ճ���



   



