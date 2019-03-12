cd 'E:\Repository\singleFactorStrategy_newBcktest';
% addpath getdata factorFunction getholding newSystem3.0 newSystem3.0\gen_for_BT2 public
addpath getdata getholding BacktestPlatform_for_futs_v2

% @2019.03.08修改为最新的每日交易单回测系统

%% 一些通用参数
% getBasicData得到一个面板table，包含日期，各品种主力合约每日的复权价格
% global usualPath
usualPath = '\\Cj-lmxue-dt\期货数据2.0\usualData'; %
dataPath = '\\Cj-lmxue-dt\期货数据2.0\dlyData';
factorDataPath = 'E:\Repository\factorTest\factorDataTT.mat';

%% 读取因子
fNameUniverse = {'SpotPremiumV4Lag1'};
volWin = 90;
holdingUniverse = 50;

finalRes = num2cell(nan(11, length(holdingUniverse) * length(fNameUniverse) + 1));
totalResult = cell(1, length(holdingUniverse));
for jFactor = 1:length(fNameUniverse)
    
    factorName = fNameUniverse{jFactor};
    % factorName = 'warrant250';
    % 因子本身参数在这里已无需设置了，这里的参数只是策略上的参数，如持仓时间
    % factorPara.dataPath = [dataPath, '\主力合约-比例后复权']; % 计算因子（收益率）用复权数据
    factorPara.lotsDataPath = [dataPath, '\主力合约']; % 计算手数需要用主力合约，不复权
    factorPara.dateFrom = 20100101;
    factorPara.dateTo = 20190115;
    factorPara.priceType = 'Close';  % 海通和华泰都是复权收盘发信号，主力结算交易
    holdingTime = holdingUniverse;
    
    tradingPara.groupNum = 3; % 对冲比例10%，20%对应5组
    tradingPara.pct = 0.5; % 高波动率筛选的标准，剔除百分位pctATR以下的
    tradingPara.capital = 1e8;
    tradingPara.direct = 1; % 这里用的是factorDataTT本身，和factorTest里面用的factorRankTT不一样（Rank已经调整过顺序）
    tradingPara.volWin = 90;
    % tradePara.futUnitPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\minTickInfo.mat'; %期货最小变动单位
    tradingPara.futMainContPath = '\\Cj-lmxue-dt\期货数据2.0\商品期货主力合约代码';
    tradingPara.futDataPath = '\\CJ-LMXUE-DT/futureData_fromWind\priceData_byFut'; %期货主力合约数据路径
    tradingPara.futUnitPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\minTickInfo.mat'; %期货最小变动单位
    tradingPara.futMultiPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\PunitInfo'; %期货合约乘数
    tradingPara.PType = 'open'; %交易价格，一般用open（开盘价）或者avg(日均价）
    tradingPara.fixC = 0.0002; %固定成本 华泰是单边万五，海通单边万三
    tradingPara.slip = 2; %滑点 两家券商都不加滑点
    
    % 等算持仓的时候再剔除非流动性和股指国债期货
    
    %% 用因子排序得到多空组合，包括持仓方向，手数
    % 这中间先得到调仓日多空方向，补齐非调仓日的方向，然后再把主力合约填补进去
    
    % 本地保存liquidityData的时候是一个包含Date及列名的table
    % 和因子数据点乘的时候用的是不含Date和列名的matrix
    
    
    bcktstAnalysis = num2cell(nan(11, length(holdingTime) + 1));
    
    for kHolding = 1:length(holdingTime)
        
        tradingPara.holdingTime = holdingTime(kHolding); % 调仓间隔（持仓日期）
        % 确定通道数，持仓时间30天以下的每5天一条通道，30填以上的每10天一条通道，持仓时间一般不会超过100天
        if tradingPara.holdingTime <= 30
            tradingPara.passwayInterval = 2;
        else
            tradingPara.passwayInterval = 5;
        end
        tradingPara.passway = floor(tradingPara.holdingTime / tradingPara.passwayInterval); % 通道数
        
        load(factorDataPath)
        %% 因子数据筛选：第一：日期
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
        
        %@2019.03.06 在这个地方加一个因子数据标准化，先剔除3倍标准差，再取Z-score
        factorData = zscoreValid(factorData);
        
        %%%%%%until now factorData是各品种因子排序
        % 因子数据筛选：第二：流动性
        %     每次循环的liquidityInfo时间不一样，与factorData的时间保持一致
        %         load('E:\futureData\liquidityInfo.mat')
        % @2019.02.21 原始的liquidityInfo是从漫雪之前保存的数据直接读的，以后都不用这个了，全改为每次自己生成判断
        % 漫雪现在也是每次现判断
        load('E:\futureData\liquidityInfoHuatai2.mat')
        liquidityInfo = liquidityInfoHuatai2;
        liquidityInfo = liquidityInfo(...
            liquidityInfo.Date >= min(factorData.Date) &...
            liquidityInfo.Date <= max(factorData.Date), :);
        % @2018.12.24 liquidityInfo也要剔除股指和国债期货
        % 因子数据筛选：第三：纯商品部分
        liquidityInfo = delStockBondIdx(liquidityInfo); %% 这一步其实不用，因为Huatai版本已经剔除了股指和国债期货
        liquidityInfo = table2array(liquidityInfo(:, 2:end));
        
        
        %     % 仓单数据是否为0值
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
        % 仓单因子可选择的品种保留1，其他设为NaN
        
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
        %% 定义回测汇总结果
        totalRes = array2table(num2cell(nan(11, tradingPara.passway + 1)));
        totalBacktestNV = nan(size(factorData, 1), tradingPara.passway + 1);
        totalBacktestExposure = nan(size(factorData, 1), tradingPara.passway + 1);
        %     回测除第一条通道外，后面的日期会缺失一些，需要补齐
        
        totalBacktestNV(:, 1) = factorData.Date;
        totalBacktestExposure(:, 1) = factorData.Date;
        
        %     totalBacktestNV = table(factorData.Date, 'VariableNames', {'Date'});
        %     totalBacktestExposure = totalBacktestNV;
        % @2018.12.26 不同通道结果结合，用intersect还是比outerjoin略快一点
        % 10条通道的话，intersect 22.78秒，outerjoin 23.08秒，所以还是用intersect做
        %% 每条通道循环测试
        for jPassway = 1 : tradingPara.passway % 每条通道  比较不同通道下的结果
            passway = jPassway;
            
            posTradingDirect = getholding(passway, tradingPara); %得到iWin和jPassway下的换仓日序列持仓方向
            
            %                 % 只看多头，把-1 都改为0
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
            posFullDirect = posFullDirect(nonNaN, :); % 这样操作虽然代码繁琐一点，但速度快，不需要用arrayfun这种本质循环的东西
            
            posHands = getholdinghands(posTradingDirect, posFullDirect, tradingPara.capital / tradingPara.passway);
            
            %             targetPortfolio = getMainContName(posHands);
            %             [BacktestResult,err] = CTABacktest_GeneralPlatform_3(targetPortfolio,tradingPara);
            %             BacktestAnalysis = CTAAnalysis_GeneralPlatform_2(BacktestResult);
            %             修改为新平台
            %             将targetPortfolio修改为TargetListI的格式，第一天是初始手数，后面都是轧差后的交易单
            
            targetListI = getTargetList(posHands);
            
            strategyPara.crossType = 'dn';
            strategyPara.freqK = 'Dly';
            strategyPara.stDate = 20100101;
            strategyPara.edDate = 20190115;
            [BacktestResult, BacktestAnalysis] = ...
                CTABacktest_GeneralPlatform_v2_1(targetListI, strategyPara, tradingPara);
            % 这个地方TargetListI输入是日间的，tradingPara的数据TableData要和日间对应，日内的要和日内对应
            % 可以跑通，回测变慢了不少
            
            % 把品种A挑出来，详细比对结果差异：
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
            
            % 补全回测净值序列
            
            [~, idx0, ~] = intersect(totalBacktestNV(:, 1), BacktestResult.Summary.date);
            totalBacktestNV(idx0, jPassway + 1) = BacktestResult.Summary.portfolio;
            
        end
        
        % 修改getMainContName函数后，循环通道速度从1条通道38秒提升到10条通道只需要23秒
        
        %% tradingPara.passway条通道的结果结合：
        % 首先这里没有fill previous NaN，因为默认后面不会出现NaN，NaN都是由于passway在一开始造成
        % 先把NaN补0  % Exposure这个没有用，回测平台里计算有问题，这里只是为了能够跑通强行加上
        totalBacktestNV = arrayfun(@(x, y, z) ifelse(isnan(x), 0, x), totalBacktestNV);
        
        % 加总
        totalBacktestNV(:, tradingPara.passway + 2) = sum(totalBacktestNV(:, 2:end), 2);
        
        totalBacktestResult.nv = totalBacktestNV(:, [1 end]);
        totalBacktestResult.nv(:, 3) = [0; diff(totalBacktestResult.nv(:, 2))];
        %         totalBacktestResult.riskExposure = totalBacktestExposure(:, [1 end]);
        % @2019.03.11
        % 这个地方把通道净值结果汇集起来用于1、画图，2、得到最终的Analysis，
        % 但是新版回测平台计算Analysis和净值整合到一起了，所以如果单独计算Analysis，需要调整一下
        %         totalBacktestAnalysis = CTAAnalysis_GeneralPlatform_2(totalBacktestResult);
        totalTdList = array2table(totalBacktestResult.nv, 'VariableNames', {'date', 'cum', 'profit'});
        totalTdList.time = ones(height(totalTdList), 1) * 999999999;
        
        % 输入getCTAAnalysis的tdList 只用到时间和profit(DR)这两列，只构造这两列即可。
        totalBacktestAnalysis = getCTAAnalysis(totalTdList);
        totalResult{1, jFactor} = totalBacktestResult.nv;
        
        dn = datenum(num2str(totalBacktestResult.nv(:, 1)), 'yyyymmdd');
        plot(dn, (tradingPara.capital + totalBacktestResult.nv(:, 2)) ./ tradingPara.capital, 'DisplayName', '改进老动量')
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


