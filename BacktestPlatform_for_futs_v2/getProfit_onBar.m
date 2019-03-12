function [profitI,err] = getProfit_onBar(data,listI,StrategyPara,TradePara)
% ���㵥��bar�����ɽ��ײ���������,�Լ��ñʽ�����ɺ�ĳֲ�
% �������bar��tick����ȱʧ���þ�����Ϊ�����۸�

err = 0;
% ������ֵ
crossType = StrategyPara.crossType;
freqK = StrategyPara.freqK;
fixC = TradePara.fixC;
slip = TradePara.slip;
PType = TradePara.PType;
tickNum = TradePara.tickNum;
tickDataPath = TradePara.tickDataPath;



% ������������д�������������ƽ������ƽ
tradeS = sign(listI.hands); %���׷���
tradeH = abs(listI.hands); %��������
if ismember('��',listI.Mark)
    tradeP = eval(['data.',PType,'(2);']); %���ּ�
    openP = (tradeP+tradeS*slip*data.minTick(2))*(1+tradeS*fixC); %���ּ�
    profitI = (data.close(2)-openP)*tradeS*tradeH;
elseif ismember('ƽ',listI.Mark) && (~isnan(listI.targetP) || ~isnan(listI.targetC))
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
    closeP = (tradeP+tradeS*slip*data.minTick(2))*(1+tradeS*fixC); %������
    profitI = (data.close(1)-closeP)*tradeS*tradeH;   
else %������ƽ
    % ���������������ʱƽ���ɺ�Լ����ƽ��ǰ��Լ
    if strcmp(listI.futCont,data.futCont{2}) %ƽ��ǰ��Լ
        tradeP = eval(['data.',PType,'(2);']); %ƽ�ּ�        
    else %����ʱƽ���ɺ�Լ
        adjfactor = data.adjfactor(2);
        adjfactorBF = data.adjfactor(1);
        tradeP = data.open(2)*adjfactor/adjfactorBF;
    end
    closeP = (tradeP+tradeS*slip*data.minTick(2))*(1+tradeS*fixC); %������
    profitI = (data.close(1)-closeP)*tradeS*tradeH;
end


