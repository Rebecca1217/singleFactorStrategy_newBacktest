function [tdList,err] = calRtnByRealData_v2_1(TargetListI,TableData,StrategyPara,TradePara)
% -------����Ŀ�꽻�׵����㾻ֵ--------------
% -----------����----------------
% TargetListI������Ʒ���ϵ�Ŀ�꽻�׵�
% TableData:Ʒ�ֶ�Ӧ��table��ʽ������
% -----------���-----------------
% tdList

err = 0;

% ������ֵ
crossType = StrategyPara.crossType;
freqK = StrategyPara.freqK;
fixC = TradePara.fixC;
slip = TradePara.slip;
PType = TradePara.PType;
tickNum = TradePara.tickNum;
tickDataPath = TradePara.tickDataPath;

% ��TargetListI�����ں�ʱ�������һ��
locs = find(ismember(TableData(:,{'date';'time'}),TargetListI(:,{'date';'time'}),'rows'))+1;
if locs(end)>height(TableData)
    TargetListI(end,:) = [];
    locs(end) = [];
end
TargetListI(:,{'date';'time'}) = TableData(locs,{'date';'time'});
% �ز����
% �����̼ۼ���ӯ��
tdList = [TableData(:,{'date';'time';'futCont'}),array2table(zeros(height(TableData),3),'VariableNames',{'direct';'hands';'profit'})]; %���ڣ�ʱ�䣬Ʒ�ִ��룬���򣬳ֲ�����(�������򣩣�����ӯ�������ղ���
for ia = 2:height(TableData)
    li = find(ismember(TargetListI(:,{'date';'time'}),TableData(ia,{'date';'time'}),'rows'));
    
    if ~isempty(li) %��һ���н��׵�
        tdList.tradeInfo = TargetListI(li,:);
        [listI,err] = getNewTargetList(TargetListI(li,:)); %��Ŀ�꽻�׵�����Ԥ����
        if err==1
            return;
        end
        % ���ж�һ������Ľ��׵���û������
        % �������date��time��futCode��targetP��targetL��ͬ�Ķ�����׵���˵������������
        judge = unique(listI(:,{'date';'time';'futCode';'targetP';'targetC'}),'rows');
        if height(judge)~=height(listI)
            disp([num2str(TableData.date(ia)),' ',num2str(TableData.time(ia)),'���׵������������'])
            err = 1;
            return;
        end
        % ���ս��׵����н���
        hisHands = tdList.hands(ia-1); %��ǰ�ֲ�����
        if hisHands==0 %û����ʷ�ֲ֣�����Ϊ�¿���,һ��Ҫ���ֽ���
            % ��û����ʷ�ֲֵ�����£������ж��Ҳ����ֻ��һ��
            profitHis = 0;
            profitT = 0; %���׵���ӯ��
            for ib = 1:height(listI)
                tmp = listI(ib,:);
                tradeP = eval(['TableData.',PType,'(ia);']); %���ּ�
                tradeH = abs(tmp.hands); %��������
                tradeS = sign(tmp.hands); %���׷���
                openP = (tradeP+tradeS*slip*TableData.minTick(ia))*(1+tradeS*fixC); %���ּ�
                if isnan(tmp.targetP) && isnan(tmp.targetC) %û��ָ����ֹӯֹ���
                    profitT = profitT+(TableData.close(ia)-openP)*tradeS*tradeH;
                    tdList.direct(ia) = tradeS;
                    tdList.hands = tradeH;
                else %��ֹӯֹ��ۣ�Ҫ�������е��ж�
                    % ���ֹӯֹ��۶����ڵ���Bar�ڣ�˵������ļ۸�������
                    if nanmax([tmp.targetP,tmp.targetC])>TableData.high(ia) && nanmin([tmp.targetP,tmp.targetC])<TableData.low(ia)
                        disp([num2str(tmp.date),' ',num2str(tmp.time),'�����ֹӯֹ������󣡣�'])
                        err = 1;
                        return;
                    else %���̵������Ҫ�õ�tick��
                        load([tickDataPath,'\',freqK,'\',num2str(tmp.date),'_',num2str(tmp.time),'.mat']) %���뵱��Bar��tick����
                        % ����ʱ��
                        [outTime,err] = findOutTime(tickData,tradeS,targetP,targetC,crossType);
                        if err==1
                            return;
                        end
                        closeP = tickData.lastprice(min([outTime+tickNum,height(tickData)]));
                        closeP = (closeP-tradeS*slip*TableData.minTick(ia))*(1-tradeS*fixC); %������
                        %
                        profitT = profitT+(closeP-openP)*tradeS*tradeH;
                    end
                end
            end
        else %��������ʷ�ֲ�,�����µĽ��׶���ʷ�ֲֵ�Ӱ�죬Ȼ�������ʷ�ֲֵ�����
            hisDirect = tdList.direct(ia-1);
            if TableData.adjfactor(ia)~=TableData.adjfactor(ia-1) %��һ���ǻ�����
                % ƽ���ɺ�Լ����
                tradeS = tdList.direct(ia-1);
                tradeH = tdList.hands(ia-1);
                adjfactor = TableData.adjfactor(ia);
                adjfactorBF = tableData.adjfactor(ia-1);
                closeP = TableData.open(ia)*adjfactor/adjfactorBF; %ƽ���ɺ�Լ�ļ۸�--�ɺ�Լ�Ŀ��̼�
                closeP = (closeP-tradeS*slip*TableData.minTick(ia))*(1-tradeS*fixC); %������
                profitClose = (closeP-TableData.close(ia-1))*tradeS*tradeH; % ƽ���ɺ�Լ��ӯ��
            else
                profitClose = 0;
            end
            % ���ײ��ֵ�����
            profitT = 0;
            newHands = 0;
            hisHandsLeft = hisHands;
            for ib = 1:height(listI) %��ʽ���
                tmp = listI(ib,:);
                tradeP = eval(['TableData.',PType,'(ia);']); %���ּ�
                tradeH = abs(tmp.hands); %��������
                tradeS = sign(tmp.hands); %���׷���
                openP = (tradeP+tradeS*slip*TableData.minTick(ia))*(1+tradeS*fixC); %���ּ�
                if tradeS==-hisDirect %���׵�����ʷ�ֲַ�����
                    if tradeH<=hisHandsLeft %��������򿪲ֵ�������ʷ�ֲ�
                        % ��ʲ����ף�ֱ�ӵֿ���ʷ�ֲ���Ҫ�¿��Ĳ���
                        hisHandsLeft = hisHandsLeft-tradeH;
                        continue;
                    else %Ҫ���׵�����������ʷ�ֲ�
                        hisHandsleft = 0;
                        tradeH = tradeH-hisHandsLeft; %ʣ���Ҫ���׵Ĳ���
                    end
                end
                if isnan(tmp.targetP) && isnan(tmp.targetC) %û��ָ����ֹӯֹ���
                    profitT = profitT+(TableData.close(ia)-openP)*tradeS*tradeH;
                    newHands = newHands+tradeS*tradeH;
                else %��ֹӯֹ��ۣ�Ҫ�������е��ж�
                    % ���ֹӯֹ��۶����ڵ���Bar�ڣ�˵������ļ۸�������
                    if nanmax([tmp.targetP,tmp.targetC])>TableData.high(ia) && nanmin([tmp.targetP,tmp.targetC])<TableData.low(ia)
                        disp([num2str(tmp.date),' ',num2str(tmp.time),'�����ֹӯֹ������󣡣�'])
                        err = 1;
                        return;
                    else %���̵������Ҫ�õ�tick��
                        load([tickDataPath,'\',freqK,'\',num2str(tmp.date),'_',num2str(tmp.time),'.mat']) %���뵱��Bar��tick����
                        % ����ʱ��
                        [outTime,err] = findOutTime(tickData,tradeS,targetP,targetC,crossType);
                        if err==1
                            return;
                        end
                        closeP = tickData.lastprice(min([outTime+tickNum,height(tickData)]));
                        closeP = (closeP-tradeS*slip*TableData.minTick(ia))*(1-tradeS*fixC); %������
                        %
                        profitT = profitT+(closeP-openP)*tradeS*tradeH;
                    end
                end
            end
            if TableData.adjfactor(ia)~=TableData.adjfactor(ia-1) %��һ���ǻ�����
                % ���º�Լ������
                if hisHandsLeft~=0 %��ʷ�ֲ�Ҫ�¿��Ĳ��ֲ���������
                    openP = TableData.open(ia); %�º�Լ�Ŀ��ּ۸�--�º�Լ�Ŀ��̼�
                    openP = (openP+tdList.direct(ia-1)*slip*TableData.minTick(ia))*(1+tdList.direct(ia-1)*fixC); %���ּ�
                    profitOpen = (TableData.close(ia)-openP)*tdList.direct(ia-1)*hisHandsLeft; %���º�Լ��ӯ��
                end
                profitHis = profitOpen+profitClose;
            else
                % ��ʷ��Լ������
                if hisHandsLeft~=0 % ��ʷ�ֲֻ������µĲ���
                    profitHis = (TableData.close(ia)-TableData.close(ia-1))*tdList.direct(ia-1)*hisHandsLeft;
                end
            end
            tdList.direct(ia) = sign(tdList.direct(ia-1)*hisHandsLeft+newHands);
            tdList.hands(ia) = abs(tdList.direct(ia-1)*hisHandsLeft+newHands);
        end
        tdList.profit(ia) = profitT+profitHis;
    else %��һ��û�н��׵�
        if tdList.hands(ia-1)==0 %��һ��û����ʷ�ֲ�
            continue;
        else % ��һ������ʷ�ֲ�
            % ������ʷ�ֲ��ڵ��������
            tdList.direct(ia) = tdList.direct(ia-1);
            tdList.hands(ia) = tdList.hands(ia-1);
            % �ж��Ƿ��ǻ�����
            if TableData.adjfactor(ia)==TableData.adjfactor(ia-1) %��һ�첻�ǻ�����     
                tdList.profit(ia) = (TableData.close(ia)-TableData.close(ia-1))*tdList.direct(ia-1)*tdList.hands(ia-1);
            else %��һ�컻��
                % �ھɺ�Լ����ƽ�֣����º�Լ���濪��--�ÿ��̼ۻ���
                tradeS = tdList.direct(ia-1);
                tradeH = tdList.hands(ia-1);
                adjfactor = TableData.adjfactor(ia);
                adjfactorBF = tableData.adjfactor(ia-1);
                closeP = TableData.open(ia)*adjfactor/adjfactorBF; %ƽ���ɺ�Լ�ļ۸�--�ɺ�Լ�Ŀ��̼�
                closeP = (closeP-tradeS*slip*TableData.minTick(ia))*(1-tradeS*fixC); %������
                openP = TableData.open(ia); %�º�Լ�Ŀ��ּ۸�--�º�Լ�Ŀ��̼�
                openP = (openP+tradeS*slip*TableData.minTick(ia))*(1+tradeS*fixC); %���ּ�
                profitClose = (closeP-TableData.close(ia-1))*tradeS*tradeH; % ƽ���ɺ�Լ��ӯ��
                profitOpen = (TableData.close(ia)-openP)*tradeS*tradeH; %���º�Լ��ӯ��
                tdList.profit(ia) = profitOpen+profitClose;
            end
        end
    end
end

tdList.profit = tdList.profit.*TableData.multifactor;    
tdList.riskExposure = tdList.hands.*tdList.close.*TableData.multifactor; %���ճ���



   



