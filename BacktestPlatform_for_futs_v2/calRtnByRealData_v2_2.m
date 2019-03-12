function [tdList,err] = calRtnByRealData_v2_2(TargetListI,TableData,StrategyPara,TradePara)
% -------根据目标交易单计算净值2.0--------------
% ----------说明-----------------
% 针对单策略进行回测
% 交易顺序：
% 无条件平-开-有条件平
% -----------输入----------------
% TargetListI：单个品种上的目标交易单
% TableData:品种对应的table格式的数据
% -----------输出-----------------
% tdList

err = 0;

% 把TargetListI的日期和时间往后错一根
TargetListI(ismember(TargetListI(:,{'date';'time'}),TableData(end,{'date';'time'}),'rows'),:) = [];
[uni,~,locs] = unique(TargetListI(:,{'date';'time'}),'stable');
dateAdd1 = TableData(find(ismember(TableData(:,{'date';'time'}),uni,'rows'))+1,{'date';'time'});
TargetListI(:,{'date';'time'}) = dateAdd1(locs,:);
contAdd1 = TableData(find(ismember(TableData(:,{'date';'time'}),uni,'rows'))+1,{'futCont'});
TargetListI(:,{'futCont'}) = contAdd1(locs,:);
% 回测规则
% 用收盘价计算盈亏
tdList = [TableData(:,{'date';'time';'futCont'}),array2table(zeros(height(TableData),2),'VariableNames',{'hands';'profit'})]; %日期，时间，品种代码，持仓手数(带方向），当日盈亏
for ia = 2:height(TableData)
    li = ismember(TargetListI(:,{'date';'time'}),TableData(ia,{'date';'time'}),'rows');
    listI = TargetListI(li,:); %当天的交易单
    hisHands = tdList.hands(ia-1); %当前的历史持仓
%     chgIF = TableData.adjfactor(ia)~=TableData.adjfactor(ia-1); %这一天是不是换月日   
    chgIF = ~strcmp(TableData.mainCont(ia),TableData.mainCont(ia-1));
    hisMainCont = TableData.futCont{ia-1};
    [listI,err] = getNewTargetList_2(listI,hisHands,chgIF,hisMainCont,TableData(ia,{'date';'time';'futCont'}));
    if err==1
        return;
    end
    if isempty(listI) %这一天没有任何交易
        if hisHands==0
            continue;
        else %有历史持仓
            tdList.hands(ia) = hisHands;
            tdList.profit(ia) = (TableData.close(ia)-TableData.close(ia-1))*hisHands;
        end
    else %这一天有交易
        tdList.tradeInfo{ia} = listI;
        % 确定目标持仓--交易完之后的持仓和目标持仓进行比对，如果一致，说明没有问题
        aimHands = getAimList(hisHands,hisMainCont,listI(:,{'futCont';'hands'}));
        tdList.hands(ia) = aimHands.hands;
        % 将当日的收益拆分成两个部分：历史持仓中不受交易影响的部分带来的收益+交易带来的收益
        if chgIF==0
            hisLeft = sign(hisHands)*min(abs([hisHands,aimHands.hands])); %不受影响的手数
            profitH = (TableData.close(ia)-TableData.close(ia-1))*hisLeft;
        else
            profitH = 0;
        end
        % 逐个交易单进行交易
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
tdList.riskExposure = abs(tdList.hands).*TableData.close.*TableData.multifactor; %风险敞口



   



