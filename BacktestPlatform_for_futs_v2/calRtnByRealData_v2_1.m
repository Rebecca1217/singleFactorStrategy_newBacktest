function [tdList,err] = calRtnByRealData_v2_1(TargetListI,TableData,StrategyPara,TradePara)
% -------根据目标交易单计算净值--------------
% -----------输入----------------
% TargetListI：单个品种上的目标交易单
% TableData:品种对应的table格式的数据
% -----------输出-----------------
% tdList

err = 0;

% 参数赋值
crossType = StrategyPara.crossType;
freqK = StrategyPara.freqK;
fixC = TradePara.fixC;
slip = TradePara.slip;
PType = TradePara.PType;
tickNum = TradePara.tickNum;
tickDataPath = TradePara.tickDataPath;

% 把TargetListI的日期和时间往后错一根
locs = find(ismember(TableData(:,{'date';'time'}),TargetListI(:,{'date';'time'}),'rows'))+1;
if locs(end)>height(TableData)
    TargetListI(end,:) = [];
    locs(end) = [];
end
TargetListI(:,{'date';'time'}) = TableData(locs,{'date';'time'});
% 回测规则
% 用收盘价计算盈亏
tdList = [TableData(:,{'date';'time';'futCont'}),array2table(zeros(height(TableData),3),'VariableNames',{'direct';'hands';'profit'})]; %日期，时间，品种代码，方向，持仓手数(不带方向），当日盈亏，当日操作
for ia = 2:height(TableData)
    li = find(ismember(TargetListI(:,{'date';'time'}),TableData(ia,{'date';'time'}),'rows'));
    
    if ~isempty(li) %这一天有交易单
        tdList.tradeInfo = TargetListI(li,:);
        [listI,err] = getNewTargetList(TargetListI(li,:)); %对目标交易单进行预处理
        if err==1
            return;
        end
        % 先判断一下输入的交易单有没有问题
        % 如果存在date、time、futCode、targetP、targetL相同的多个交易单，说明轧差有问题
        judge = unique(listI(:,{'date';'time';'futCode';'targetP';'targetC'}),'rows');
        if height(judge)~=height(listI)
            disp([num2str(TableData.date(ia)),' ',num2str(TableData.time(ia)),'交易单轧差不完整！！'])
            err = 1;
            return;
        end
        % 按照交易单进行交易
        hisHands = tdList.hands(ia-1); %当前持仓手数
        if hisHands==0 %没有历史持仓，当天为新开仓,一定要开仓进场
            % 在没有历史持仓的情况下，可能有多笔也可能只有一笔
            profitHis = 0;
            profitT = 0; %交易单的盈亏
            for ib = 1:height(listI)
                tmp = listI(ib,:);
                tradeP = eval(['TableData.',PType,'(ia);']); %开仓价
                tradeH = abs(tmp.hands); %交易手数
                tradeS = sign(tmp.hands); %交易方向
                openP = (tradeP+tradeS*slip*TableData.minTick(ia))*(1+tradeS*fixC); %开仓价
                if isnan(tmp.targetP) && isnan(tmp.targetC) %没有指定的止盈止损价
                    profitT = profitT+(TableData.close(ia)-openP)*tradeS*tradeH;
                    tdList.direct(ia) = tradeS;
                    tdList.hands = tradeH;
                else %有止盈止损价，要进行盘中的判断
                    % 如果止盈止损价都不在当根Bar内，说明传入的价格有问题
                    if nanmax([tmp.targetP,tmp.targetC])>TableData.high(ia) && nanmin([tmp.targetP,tmp.targetC])<TableData.low(ia)
                        disp([num2str(tmp.date),' ',num2str(tmp.time),'传入的止盈止损价有误！！'])
                        err = 1;
                        return;
                    else %开盘当天必须要用到tick数
                        load([tickDataPath,'\',freqK,'\',num2str(tmp.date),'_',num2str(tmp.time),'.mat']) %导入当根Bar的tick数据
                        % 出场时间
                        [outTime,err] = findOutTime(tickData,tradeS,targetP,targetC,crossType);
                        if err==1
                            return;
                        end
                        closeP = tickData.lastprice(min([outTime+tickNum,height(tickData)]));
                        closeP = (closeP-tradeS*slip*TableData.minTick(ia))*(1-tradeS*fixC); %出场价
                        %
                        profitT = profitT+(closeP-openP)*tradeS*tradeH;
                    end
                end
            end
        else %当天有历史持仓,考虑新的交易对历史持仓的影响，然后计算历史持仓的收益
            hisDirect = tdList.direct(ia-1);
            if TableData.adjfactor(ia)~=TableData.adjfactor(ia-1) %这一天是换月日
                % 平掉旧合约收益
                tradeS = tdList.direct(ia-1);
                tradeH = tdList.hands(ia-1);
                adjfactor = TableData.adjfactor(ia);
                adjfactorBF = tableData.adjfactor(ia-1);
                closeP = TableData.open(ia)*adjfactor/adjfactorBF; %平掉旧合约的价格--旧合约的开盘价
                closeP = (closeP-tradeS*slip*TableData.minTick(ia))*(1-tradeS*fixC); %出场价
                profitClose = (closeP-TableData.close(ia-1))*tradeS*tradeH; % 平掉旧合约的盈亏
            else
                profitClose = 0;
            end
            % 交易部分的收益
            profitT = 0;
            newHands = 0;
            hisHandsLeft = hisHands;
            for ib = 1:height(listI) %逐笔交易
                tmp = listI(ib,:);
                tradeP = eval(['TableData.',PType,'(ia);']); %开仓价
                tradeH = abs(tmp.hands); %交易手数
                tradeS = sign(tmp.hands); %交易方向
                openP = (tradeP+tradeS*slip*TableData.minTick(ia))*(1+tradeS*fixC); %开仓价
                if tradeS==-hisDirect %交易单和历史持仓反方向
                    if tradeH<=hisHandsLeft %如果反方向开仓单少于历史持仓
                        % 这笔不交易，直接抵扣历史持仓中要新开的部分
                        hisHandsLeft = hisHandsLeft-tradeH;
                        continue;
                    else %要交易的手数多于历史持仓
                        hisHandsleft = 0;
                        tradeH = tradeH-hisHandsLeft; %剩余的要交易的部分
                    end
                end
                if isnan(tmp.targetP) && isnan(tmp.targetC) %没有指定的止盈止损价
                    profitT = profitT+(TableData.close(ia)-openP)*tradeS*tradeH;
                    newHands = newHands+tradeS*tradeH;
                else %有止盈止损价，要进行盘中的判断
                    % 如果止盈止损价都不在当根Bar内，说明传入的价格有问题
                    if nanmax([tmp.targetP,tmp.targetC])>TableData.high(ia) && nanmin([tmp.targetP,tmp.targetC])<TableData.low(ia)
                        disp([num2str(tmp.date),' ',num2str(tmp.time),'传入的止盈止损价有误！！'])
                        err = 1;
                        return;
                    else %开盘当天必须要用到tick数
                        load([tickDataPath,'\',freqK,'\',num2str(tmp.date),'_',num2str(tmp.time),'.mat']) %导入当根Bar的tick数据
                        % 出场时间
                        [outTime,err] = findOutTime(tickData,tradeS,targetP,targetC,crossType);
                        if err==1
                            return;
                        end
                        closeP = tickData.lastprice(min([outTime+tickNum,height(tickData)]));
                        closeP = (closeP-tradeS*slip*TableData.minTick(ia))*(1-tradeS*fixC); %出场价
                        %
                        profitT = profitT+(closeP-openP)*tradeS*tradeH;
                    end
                end
            end
            if TableData.adjfactor(ia)~=TableData.adjfactor(ia-1) %这一天是换月日
                % 开新合约的收益
                if hisHandsLeft~=0 %历史持仓要新开的部分产生的收益
                    openP = TableData.open(ia); %新合约的开仓价格--新合约的开盘价
                    openP = (openP+tdList.direct(ia-1)*slip*TableData.minTick(ia))*(1+tdList.direct(ia-1)*fixC); %开仓价
                    profitOpen = (TableData.close(ia)-openP)*tdList.direct(ia-1)*hisHandsLeft; %开新合约的盈亏
                end
                profitHis = profitOpen+profitClose;
            else
                % 历史合约的收益
                if hisHandsLeft~=0 % 历史持仓还保留下的部分
                    profitHis = (TableData.close(ia)-TableData.close(ia-1))*tdList.direct(ia-1)*hisHandsLeft;
                end
            end
            tdList.direct(ia) = sign(tdList.direct(ia-1)*hisHandsLeft+newHands);
            tdList.hands(ia) = abs(tdList.direct(ia-1)*hisHandsLeft+newHands);
        end
        tdList.profit(ia) = profitT+profitHis;
    else %这一天没有交易单
        if tdList.hands(ia-1)==0 %这一天没有历史持仓
            continue;
        else % 这一天有历史持仓
            % 计算历史持仓在当天的收益
            tdList.direct(ia) = tdList.direct(ia-1);
            tdList.hands(ia) = tdList.hands(ia-1);
            % 判断是否是换月日
            if TableData.adjfactor(ia)==TableData.adjfactor(ia-1) %这一天不是换月日     
                tdList.profit(ia) = (TableData.close(ia)-TableData.close(ia-1))*tdList.direct(ia-1)*tdList.hands(ia-1);
            else %这一天换月
                % 在旧合约上面平仓，在新合约上面开仓--用开盘价换月
                tradeS = tdList.direct(ia-1);
                tradeH = tdList.hands(ia-1);
                adjfactor = TableData.adjfactor(ia);
                adjfactorBF = tableData.adjfactor(ia-1);
                closeP = TableData.open(ia)*adjfactor/adjfactorBF; %平掉旧合约的价格--旧合约的开盘价
                closeP = (closeP-tradeS*slip*TableData.minTick(ia))*(1-tradeS*fixC); %出场价
                openP = TableData.open(ia); %新合约的开仓价格--新合约的开盘价
                openP = (openP+tradeS*slip*TableData.minTick(ia))*(1+tradeS*fixC); %开仓价
                profitClose = (closeP-TableData.close(ia-1))*tradeS*tradeH; % 平掉旧合约的盈亏
                profitOpen = (TableData.close(ia)-openP)*tradeS*tradeH; %开新合约的盈亏
                tdList.profit(ia) = profitOpen+profitClose;
            end
        end
    end
end

tdList.profit = tdList.profit.*TableData.multifactor;    
tdList.riskExposure = tdList.hands.*tdList.close.*TableData.multifactor; %风险敞口



   



