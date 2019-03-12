cd 'E:\Repository\singleFactorStrategy_newBcktest';
% addpath getdata factorFunction getholding newSystem3.0 newSystem3.0\gen_for_BT2 public
addpath getdata getholding BacktestPlatform_for_futs_v2

% @2019.03.08�޸�Ϊ���µ�ÿ�ս��׵��ز�ϵͳ

%% һЩͨ�ò���
% getBasicData�õ�һ�����table���������ڣ���Ʒ��������Լÿ�յĸ�Ȩ�۸�
% global usualPath
usualPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData'; %
dataPath = '\\Cj-lmxue-dt\�ڻ�����2.0\dlyData';
factorDataPath = 'E:\Repository\factorTest\factorDataTT.mat';

%% ��ȡ����
fNameUniverse = {'SpotPremiumV4Lag1'};
volWin = 90;
holdingUniverse = 50;

finalRes = num2cell(nan(11, length(holdingUniverse) * length(fNameUniverse) + 1));
totalResult = cell(1, length(holdingUniverse));
for jFactor = 1:length(fNameUniverse)
    
    factorName = fNameUniverse{jFactor};
    % factorName = 'warrant250';
    % ���ӱ������������������������ˣ�����Ĳ���ֻ�ǲ����ϵĲ�������ֲ�ʱ��
    % factorPara.dataPath = [dataPath, '\������Լ-������Ȩ']; % �������ӣ������ʣ��ø�Ȩ����
    factorPara.lotsDataPath = [dataPath, '\������Լ']; % ����������Ҫ��������Լ������Ȩ
    factorPara.dateFrom = 20100101;
    factorPara.dateTo = 20190115;
    factorPara.priceType = 'Close';  % ��ͨ�ͻ�̩���Ǹ�Ȩ���̷��źţ��������㽻��
    holdingTime = holdingUniverse;
    
    tradingPara.groupNum = 3; % �Գ����10%��20%��Ӧ5��
    tradingPara.pct = 0.5; % �߲�����ɸѡ�ı�׼���޳��ٷ�λpctATR���µ�
    tradingPara.capital = 1e8;
    tradingPara.direct = 1; % �����õ���factorDataTT��������factorTest�����õ�factorRankTT��һ����Rank�Ѿ�������˳��
    tradingPara.volWin = 90;
    % tradePara.futUnitPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\minTickInfo.mat'; %�ڻ���С�䶯��λ
    tradingPara.futMainContPath = '\\Cj-lmxue-dt\�ڻ�����2.0\��Ʒ�ڻ�������Լ����';
    tradingPara.futDataPath = '\\CJ-LMXUE-DT/futureData_fromWind\priceData_byFut'; %�ڻ�������Լ����·��
    tradingPara.futUnitPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\minTickInfo.mat'; %�ڻ���С�䶯��λ
    tradingPara.futMultiPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\PunitInfo'; %�ڻ���Լ����
    tradingPara.PType = 'open'; %���׼۸�һ����open�����̼ۣ�����avg(�վ��ۣ�
    tradingPara.fixC = 0.0002; %�̶��ɱ� ��̩�ǵ������壬��ͨ��������
    tradingPara.slip = 2; %���� ����ȯ�̶����ӻ���
    
    % ����ֲֵ�ʱ�����޳��������Ժ͹�ָ��ծ�ڻ�
    
    %% ����������õ������ϣ������ֲַ�������
    % ���м��ȵõ������ն�շ��򣬲���ǵ����յķ���Ȼ���ٰ�������Լ���ȥ
    
    % ���ر���liquidityData��ʱ����һ������Date��������table
    % ���������ݵ�˵�ʱ���õ��ǲ���Date��������matrix
    
    
    bcktstAnalysis = num2cell(nan(11, length(holdingTime) + 1));
    
    for kHolding = 1:length(holdingTime)
        
        tradingPara.holdingTime = holdingTime(kHolding); % ���ּ�����ֲ����ڣ�
        % ȷ��ͨ�������ֲ�ʱ��30�����µ�ÿ5��һ��ͨ����30�����ϵ�ÿ10��һ��ͨ�����ֲ�ʱ��һ�㲻�ᳬ��100��
        if tradingPara.holdingTime <= 30
            tradingPara.passwayInterval = 2;
        else
            tradingPara.passwayInterval = 5;
        end
        tradingPara.passway = floor(tradingPara.holdingTime / tradingPara.passwayInterval); % ͨ����
        
        load(factorDataPath)
        %% ��������ɸѡ����һ������
        factorData = factorDataTT(:, {'date', 'code', factorName});
        factorData = factorData(factorData.date >= factorPara.dateFrom & ...
            factorData.date <= factorPara.dateTo, :);
        codeName = getVarietyCode();
        factorData = outerjoin(factorData, codeName, 'type', 'left', 'MergeKeys', true, ...
            'LeftKeys', 'code', 'RightKeys', 'ContCode');
        factorData.ContName = cellfun(@char, factorData.ContName, 'UniformOutput', false);
        factorData = unstack(factorData(:, {'date', factorName, 'ContName'}), factorName, 'ContName');
        factorData = delStockBondIdx(factorData);
        factorData.Properties.VariableNames{1} = 'Date';
        
        %@2019.03.06 ������ط���һ���������ݱ�׼�������޳�3����׼���ȡZ-score
        factorData = zscoreValid(factorData);
        
        %%%%%%until now factorData�Ǹ�Ʒ����������
        % ��������ɸѡ���ڶ���������
        %     ÿ��ѭ����liquidityInfoʱ�䲻һ������factorData��ʱ�䱣��һ��
        %         load('E:\futureData\liquidityInfo.mat')
        % @2019.02.21 ԭʼ��liquidityInfo�Ǵ���ѩ֮ǰ���������ֱ�Ӷ��ģ��Ժ󶼲�������ˣ�ȫ��Ϊÿ���Լ������ж�
        % ��ѩ����Ҳ��ÿ�����ж�
        load('E:\futureData\liquidityInfoHuatai2.mat')
        liquidityInfo = liquidityInfoHuatai2;
        liquidityInfo = liquidityInfo(...
            liquidityInfo.Date >= min(factorData.Date) &...
            liquidityInfo.Date <= max(factorData.Date), :);
        % @2018.12.24 liquidityInfoҲҪ�޳���ָ�͹�ծ�ڻ�
        % ��������ɸѡ������������Ʒ����
        liquidityInfo = delStockBondIdx(liquidityInfo); %% ��һ����ʵ���ã���ΪHuatai�汾�Ѿ��޳��˹�ָ�͹�ծ�ڻ�
        liquidityInfo = table2array(liquidityInfo(:, 2:end));
        
        
        %     % �ֵ������Ƿ�Ϊ0ֵ
        %     load('E:\futureData\dataWarrant.mat')
        %     dataWarrant = outerjoin(dataWarrant, codeName, 'type', 'left', 'MergeKeys', true, ...
        %         'LeftKeys', 'ContCode', 'RightKeys', 'ContCode');
        %     dataWarrant.ContName = cellfun(@char, dataWarrant.ContName, 'UniformOutput', false);
        %     dataWarrant = unstack(dataWarrant(:, {'Date', 'ContName', 'Warrant'}), 'Warrant', 'ContName');
        %     dataWarrant = delStockBondIdx(dataWarrant);
        %     dataWarrant = dataWarrant(dataWarrant.Date >= factorData.Date(1) & ...
        %         dataWarrant.Date <= factorData.Date(end), :);
        %     warrantLabel = arrayfun(@(x, y, z) ifelse(isnan(x), NaN, ifelse(x == 0, NaN, 1)), table2array(dataWarrant(:, 2:end)));
        %     clear dataWarrant
        % �ֵ����ӿ�ѡ���Ʒ�ֱ���1��������ΪNaN
        
        %         liquidityInfo = getBasicData('future');
        %         avgVol = movavg(liquidityInfo.Volume, 'simple', 20);
        %         nanL = NanL_from_chgCode(liquidityInfo.ContCode, 19);
        %         avgVol(nanL) = 0;
        %         avgVol(isnan(avgVol)) = 0;
        %
        %         liquidityInfo.LiqStatus = ones(height(liquidityInfo), 1);
        %         liquidityInfo.LiqStatus(avgVol < 10000) = 0;
        %         liquidityInfo = liquidityInfo(liquidityInfo.Date >= factorData.Date(1) & ...
        %             liquidityInfo.Date <= factorData.Date(end), {'Date', 'ContName', 'LiqStatus'});
        %         liquidityInfo.ContName = cellfun(@char, liquidityInfo.ContName, 'UniformOutput', false);
        %         liquidityInfo = unstack(liquidityInfo, 'LiqStatus', 'ContName');
        %         liquidityInfo = delStockBondIdx(liquidityInfo);
        %         liquidityInfo = table2array(liquidityInfo(:, 2:end));
        %
        %% ����ز���ܽ��
        totalRes = array2table(num2cell(nan(11, tradingPara.passway + 1)));
        totalBacktestNV = nan(size(factorData, 1), tradingPara.passway + 1);
        totalBacktestExposure = nan(size(factorData, 1), tradingPara.passway + 1);
        %     �ز����һ��ͨ���⣬��������ڻ�ȱʧһЩ����Ҫ����
        
        totalBacktestNV(:, 1) = factorData.Date;
        totalBacktestExposure(:, 1) = factorData.Date;
        
        %     totalBacktestNV = table(factorData.Date, 'VariableNames', {'Date'});
        %     totalBacktestExposure = totalBacktestNV;
        % @2018.12.26 ��ͬͨ�������ϣ���intersect���Ǳ�outerjoin�Կ�һ��
        % 10��ͨ���Ļ���intersect 22.78�룬outerjoin 23.08�룬���Ի�����intersect��
        %% ÿ��ͨ��ѭ������
        for jPassway = 1 : tradingPara.passway % ÿ��ͨ��  �Ƚϲ�ͬͨ���µĽ��
            passway = jPassway;
            
            posTradingDirect = getholding(passway, tradingPara); %�õ�iWin��jPassway�µĻ��������гֲַ���
            
            %                 % ֻ����ͷ����-1 ����Ϊ0
            %                 posTradingDirect = array2table(...
            %                     arrayfun(@(x, y, z) ifelse(x == 1, 0, x), table2array(posTradingDirect)), ...
            %                     'VariableNames', posTradingDirect.Properties.VariableNames);
            
            posFullDirect = factorData(:, 1);
            posFullDirect = outerjoin(posFullDirect, posTradingDirect, 'type', 'left', 'MergeKeys', true);
            posFullDirect = varfun(@(x) fillmissing(x, 'previous'), posFullDirect);
            posFullDirect.Properties.VariableNames = posTradingDirect.Properties.VariableNames;
            %                                 posFullDirect = posTradingDirect;
            
            
            nonNaN = sum(~isnan(table2array(posFullDirect(:, 2:end))), 2);
            nonNaN = nonNaN ~= 0;
            posFullDirect = posFullDirect(nonNaN, :); % ����������Ȼ���뷱��һ�㣬���ٶȿ죬����Ҫ��arrayfun���ֱ���ѭ���Ķ���
            
            posHands = getholdinghands(posTradingDirect, posFullDirect, tradingPara.capital / tradingPara.passway);
            
            %             targetPortfolio = getMainContName(posHands);
            %             [BacktestResult,err] = CTABacktest_GeneralPlatform_3(targetPortfolio,tradingPara);
            %             BacktestAnalysis = CTAAnalysis_GeneralPlatform_2(BacktestResult);
            %             �޸�Ϊ��ƽ̨
            %             ��targetPortfolio�޸�ΪTargetListI�ĸ�ʽ����һ���ǳ�ʼ���������涼�������Ľ��׵�
            
            targetListI = getTargetList(posHands);
            
            strategyPara.crossType = 'dn';
            strategyPara.freqK = 'Dly';
            strategyPara.stDate = 20100101;
            strategyPara.edDate = 20190115;
            [BacktestResult, BacktestAnalysis] = ...
                CTABacktest_GeneralPlatform_v2_1(targetListI, strategyPara, tradingPara);
            % ����ط�TargetListI�������ռ�ģ�tradingPara������TableDataҪ���ռ��Ӧ�����ڵ�Ҫ�����ڶ�Ӧ
            % ������ͨ���ز�����˲���
            
            % ��Ʒ��A����������ϸ�ȶԽ�����죺
            %             targetListTest = targetListI;
            %             targetListTest.Variety = regexp(targetList.futCont, '[A-Z]+', 'match');
            %             targetListTest.Variety = cellfun(@char, targetListTest.Variety, 'UniformOutput', false);
            %             targetListTest = targetListTest(strcmp(targetListTest.Variety, 'A'), :);
            %             targetListTest.Variety = [];
            %             [BacktestResult, BacktestAnalysis] = ...
            %                 CTABacktest_GeneralPlatform_v2_1(targetListTest, strategyPara, tradingPara);
            
            if jPassway == 1
                totalRes(:, [1 2]) = BacktestAnalysis(:, [1 end]);
            else
                totalRes(:, jPassway + 1) = BacktestAnalysis(:, end);
            end
            
            % ��ȫ�ز⾻ֵ����
            
            [~, idx0, ~] = intersect(totalBacktestNV(:, 1), BacktestResult.Summary.date);
            totalBacktestNV(idx0, jPassway + 1) = BacktestResult.Summary.portfolio;
            
        end
        
        % �޸�getMainContName������ѭ��ͨ���ٶȴ�1��ͨ��38��������10��ͨ��ֻ��Ҫ23��
        
        %% tradingPara.passway��ͨ���Ľ����ϣ�
        % ��������û��fill previous NaN����ΪĬ�Ϻ��治�����NaN��NaN��������passway��һ��ʼ���
        % �Ȱ�NaN��0  % Exposure���û���ã��ز�ƽ̨����������⣬����ֻ��Ϊ���ܹ���ͨǿ�м���
        totalBacktestNV = arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), totalBacktestNV);
        
        % ����
        totalBacktestNV(:, tradingPara.passway + 2) = sum(totalBacktestNV(:, 2:end), 2);
        
        totalBacktestResult.nv = totalBacktestNV(:, [1 end]);
        totalBacktestResult.nv(:, 3) = [0; diff(totalBacktestResult.nv(:, 2))];
        %         totalBacktestResult.riskExposure = totalBacktestExposure(:, [1 end]);
        % @2019.03.11
        % ����ط���ͨ����ֵ����㼯��������1����ͼ��2���õ����յ�Analysis��
        % �����°�ز�ƽ̨����Analysis�;�ֵ���ϵ�һ���ˣ����������������Analysis����Ҫ����һ��
        %         totalBacktestAnalysis = CTAAnalysis_GeneralPlatform_2(totalBacktestResult);
        totalTdList = array2table(totalBacktestResult.nv, 'VariableNames', {'date', 'cum', 'profit'});
        totalTdList.time = ones(height(totalTdList), 1) * 999999999;
        
        % ����getCTAAnalysis��tdList ֻ�õ�ʱ���profit(DR)�����У�ֻ���������м��ɡ�
        totalBacktestAnalysis = getCTAAnalysis(totalTdList);
        totalResult{1, jFactor} = totalBacktestResult.nv;
        
        dn = datenum(num2str(totalBacktestResult.nv(:, 1)), 'yyyymmdd');
        plot(dn, (tradingPara.capital + totalBacktestResult.nv(:, 2)) ./ tradingPara.capital, 'DisplayName', '�Ľ��϶���')
        datetick('x', 'yyyymmdd', 'keepticks', 'keeplimits')
        hold on
        if  kHolding == 1
            bcktstAnalysis(:, [1 2]) = totalBacktestAnalysis;
        else
            bcktstAnalysis(:, kHolding + 1) = ...
                totalBacktestAnalysis(:, 2);
        end
        
        
    end
end

