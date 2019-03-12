function [BacktestResult,BacktestAnalysis] = CTABacktest_GeneralPlatform_v2_2(TargetTradeList,StrategyPara,TradePara)
% ======================CTA通用回测平台3.0-20181111==============================
% -----------------------平台说明---------------------------
% 用于期货的回测，输入目标交易单，输出回测净值和绩效分析结果
% -------------------------输入------------------------------
% TargetTradeList:Table格式，date、time、futCont、hands、targetP、targetC、Mark(开平标志）
% StrategyPara:struct格式，策略相关的参数：crossType(止盈为上穿还是下穿,默认为下穿),freqK(K线频率，默认为日频）
% TradePara:struct格式，包括数据路径和交易成本参数，如果某个参数没有赋值，则该参数用默认值
% 交易成本参数：固定成本、滑点、交易价格、tick数据滞后个数
% 数据路径参数：
% -------------------------输出------------------------------
% BacktestResult:struct格式，策略整体和各个品种上面的回测结果，每个品种上的输出格式为table
% BacktestAnalysis:struct格式，策略整体和各个品种上面的回测结果


TargetTradeList.Properties.VariableNames = {'date';'time';'futCont';'hands';'targetP';'targetC';'Mark'}; %改一下名字

% 参数赋值
if nargin==1 
    StrategyPara = [];
    TradePara = [];
elseif nargin==2
    TradePara = [];
end
crossType = 'dn';
freqK = 'Dly';
edDate = 999999999;
if isempty(StrategyPara)
    names = {'crossType';'freqK';'edDate'};
else
    names = setdiff({'crossType';'freqK';'edDate'},fieldnames(StrategyPara));
end
for n = 1:length(names)
    eval(['StrategyPara.',names{n},'=',names{n},';'])
end
% 先统一用默认的参数赋值，然后对TradePara提供的参数值进行重新赋值
fixC = 0.0002; %固定成本
slip = 2; %滑点
PType = 'open'; %交易价格
tickNum = 10;
strategyType = 'trend';
% 交易数据路径
futDataPath = 'D:\期货数据2.0\KData'; 
tickDataPath = '\\10.201.227.227\d\期货数据\Data_Cleaning\WWB'; %tick数据路径
ttNames = {'fixC';'slip';'PType';'tickNum';'futDataPath';'tickDataPath';'strategyType'};
if isempty(TradePara)
    names = ttNames;
else
    names = setdiff(ttNames,fieldnames(TradePara));
end
for n = 1:length(names)
    eval(['TradePara.',names{n},'=',names{n},';'])
end




% 按照品种对TargetTradeList进行排序
fut_variety = regexp(TargetTradeList.futCont,'\D*(?=\d)','match');
fut_variety = reshape([fut_variety{:}],size(fut_variety));
TargetTradeList.fut = fut_variety;
fut_variety = unique(fut_variety); %全部待交易品种
TargetTradeList = sortrows(TargetTradeList,{'futCont';'date';'time'}); 
% 逐个品种进行回测，然后把每个品种的结果结合起来，作为整体回测结果
for i_fut = 1:length(fut_variety) 
    fut = fut_variety{i_fut};
    disp([fut,'开始回测'])
    TargetListI = TargetTradeList(ismember(TargetTradeList.fut,fut),:);
    TargetListI = sortrows(TargetListI,{'date';'time'});
    % 导入品种数据
    if strcmp(TradePara.strategyType,'trend')
        try
            load([TradePara.futDataPath,'\',StrategyPara.freqK,'\',fut,'.mat']) %TableData
        catch
            load([TradePara.futDataPath,'\',StrategyPara.freqK,'\',fut,'\',fut,'.mat']) %TableData
        end
    elseif strcmp(TradePara.strategyType,'spread')
        load([TradePara.futDataPath,'\',StrategyPara.freqK,'\',TradePara.name,'.mat'])
%         cont = unique(TargetListI.futCont);
        TableData = getData(TableData,fut);
    end
        
    if ~ismember('futCont',TableData.Properties.VariableNames)
        TableData.futCont = TableData.mainCont;
    end
%     % 把品种的数据和TargetListI的起始日期对齐
%     TableData = TableData(find(ismember(TableData(:,{'date';'time'}),TargetListI(1,{'date';'time'}),'rows'),1,'first'):find(TableData.date<=StrategyPara.edDate,1,'last'),:);
%     TableData.adjfactor(TableData.code==700021 & TableData.date==20181019) = TableData.adjfactor(TableData.code==700021 & TableData.date==20181022);
%     TableData.adjfactorABS(TableData.code==700021 & TableData.date==20181019) = TableData.adjfactorABS(TableData.code==700021 & TableData.date==20181022);
%     TableData.adjfactor(TableData.code==700020 & TableData.date==20181019) = TableData.adjfactor(TableData.code==700020 & TableData.date==20181022);
%     TableData.adjfactorABS(TableData.code==700020 & TableData.date==20181019) = TableData.adjfactorABS(TableData.code==700020 & TableData.date==20181022);
%     TableData.adjfactor(TableData.code==700022 & TableData.date==20181019) = TableData.adjfactor(TableData.code==700022 & TableData.date==20181022);
%     TableData.adjfactorABS(TableData.code==700022 & TableData.date==20181019) = TableData.adjfactorABS(TableData.code==700022 & TableData.date==20181022);
%     TableData.adjfactor(TableData.code==700022 & TableData.date==20181116) = TableData.adjfactor(TableData.code==700022 & TableData.date==20181119);
%     TableData.adjfactorABS(TableData.code==700022 & TableData.date==20181116) = TableData.adjfactorABS(TableData.code==700022 & TableData.date==20181119);

    % 计算收益
    [tdList,err] = calRtnByRealData_v2_2(TargetListI,TableData,StrategyPara,TradePara);
    if err==1
        return;
    end
    % 结果分析
    analysisI = getCTAAnalysis(tdList);
    % 赋值
    eval(['BacktestResult.',fut,'=tdList;'])
    eval(['Analysis.',fut,'=analysisI;'])
end

% 结果整合
[BacktestResult,BacktestAnalysis] = GetResultCombine(BacktestResult,Analysis);

end
%%
function data = getData(dataI,fut)

names = dataI.Properties.VariableNames(startsWith(dataI.Properties.VariableNames,[fut,'_']));
data = dataI(:,names);
names = regexp(names,'(?<=_)\w*','match');
names = reshape([names{:}],size(names));
data.Properties.VariableNames = names;
data = [dataI(:,{'date';'time'}),data];
data.mainCont = data.cont;
end
    