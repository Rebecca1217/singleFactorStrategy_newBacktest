function [profitI,err] = getProfit_onBar(data,listI,StrategyPara,TradePara)
% 计算单根bar上面由交易产生的收益,以及该笔交易完成后的持仓
% 如果当根bar的tick数据缺失，用均价作为出场价格

err = 0;
% 参数赋值
crossType = StrategyPara.crossType;
freqK = StrategyPara.freqK;
fixC = TradePara.fixC;
slip = TradePara.slip;
PType = TradePara.PType;
tickNum = TradePara.tickNum;
tickDataPath = TradePara.tickDataPath;



% 分三种情况进行处理：开，无条件平，条件平
tradeS = sign(listI.hands); %交易方向
tradeH = abs(listI.hands); %交易手数
if ismember('开',listI.Mark)
    tradeP = eval(['data.',PType,'(2);']); %开仓价
    openP = (tradeP+tradeS*slip*data.minTick(2))*(1+tradeS*fixC); %开仓价
    profitI = (data.close(2)-openP)*tradeS*tradeH;
elseif ismember('平',listI.Mark) && (~isnan(listI.targetP) || ~isnan(listI.targetC))
    try
        load([tickDataPath,'\',freqK,'\',num2str(listI.date),'_',num2str(listI.time),'.mat'])
        [outTime,err] = findOutTime(tickData,tradeS,listI.targetP,listI.targetC,crossType);
        if err==1
            profitI = 0;
            return;
        end
        tradeP = tickData.lastprice(min([outTime+tickNum,height(tickData)]));
    catch
        tradeP = (data.open(2)+data.close(2)+data.high(2)+data.low(2))/4;
    end
    closeP = (tradeP+tradeS*slip*data.minTick(2))*(1+tradeS*fixC); %出场价
    profitI = (data.close(1)-closeP)*tradeS*tradeH;   
else %无条件平
    % 分两种情况：换月时平掉旧合约或者平当前合约
    if strcmp(listI.futCont,data.futCont{2}) %平当前合约
        tradeP = eval(['data.',PType,'(2);']); %平仓价        
    else %换月时平掉旧合约
        adjfactor = data.adjfactor(2);
        adjfactorBF = data.adjfactor(1);
        tradeP = data.open(2)*adjfactor/adjfactorBF;
    end
    closeP = (tradeP+tradeS*slip*data.minTick(2))*(1+tradeS*fixC); %出场价
    profitI = (data.close(1)-closeP)*tradeS*tradeH;
end


