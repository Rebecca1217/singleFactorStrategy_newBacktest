function [BacktestResult,BacktestAnalysis] = CTABacktest_GeneralPlatform_v2_2(TargetTradeList,StrategyPara,TradePara)
% ======================CTAͨ�ûز�ƽ̨3.0-20181111==============================
% -----------------------ƽ̨˵��---------------------------
% �����ڻ��Ļز⣬����Ŀ�꽻�׵�������ز⾻ֵ�ͼ�Ч�������
% -------------------------����------------------------------
% TargetTradeList:Table��ʽ��date��time��futCont��hands��targetP��targetC��Mark(��ƽ��־��
% StrategyPara:struct��ʽ��������صĲ�����crossType(ֹӯΪ�ϴ������´�,Ĭ��Ϊ�´�),freqK(K��Ƶ�ʣ�Ĭ��Ϊ��Ƶ��
% TradePara:struct��ʽ����������·���ͽ��׳ɱ����������ĳ������û�и�ֵ����ò�����Ĭ��ֵ
% ���׳ɱ��������̶��ɱ������㡢���׼۸�tick�����ͺ����
% ����·��������
% -------------------------���------------------------------
% BacktestResult:struct��ʽ����������͸���Ʒ������Ļز�����ÿ��Ʒ���ϵ������ʽΪtable
% BacktestAnalysis:struct��ʽ����������͸���Ʒ������Ļز���


TargetTradeList.Properties.VariableNames = {'date';'time';'futCont';'hands';'targetP';'targetC';'Mark'}; %��һ������

% ������ֵ
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
% ��ͳһ��Ĭ�ϵĲ�����ֵ��Ȼ���TradePara�ṩ�Ĳ���ֵ�������¸�ֵ
fixC = 0.0002; %�̶��ɱ�
slip = 2; %����
PType = 'open'; %���׼۸�
tickNum = 10;
strategyType = 'trend';
% ��������·��
futDataPath = 'D:\�ڻ�����2.0\KData'; 
tickDataPath = '\\10.201.227.227\d\�ڻ�����\Data_Cleaning\WWB'; %tick����·��
ttNames = {'fixC';'slip';'PType';'tickNum';'futDataPath';'tickDataPath';'strategyType'};
if isempty(TradePara)
    names = ttNames;
else
    names = setdiff(ttNames,fieldnames(TradePara));
end
for n = 1:length(names)
    eval(['TradePara.',names{n},'=',names{n},';'])
end




% ����Ʒ�ֶ�TargetTradeList��������
fut_variety = regexp(TargetTradeList.futCont,'\D*(?=\d)','match');
fut_variety = reshape([fut_variety{:}],size(fut_variety));
TargetTradeList.fut = fut_variety;
fut_variety = unique(fut_variety); %ȫ��������Ʒ��
TargetTradeList = sortrows(TargetTradeList,{'futCont';'date';'time'}); 
% ���Ʒ�ֽ��лز⣬Ȼ���ÿ��Ʒ�ֵĽ�������������Ϊ����ز���
for i_fut = 1:length(fut_variety) 
    fut = fut_variety{i_fut};
    disp([fut,'��ʼ�ز�'])
    TargetListI = TargetTradeList(ismember(TargetTradeList.fut,fut),:);
    TargetListI = sortrows(TargetListI,{'date';'time'});
    % ����Ʒ������
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
%     % ��Ʒ�ֵ����ݺ�TargetListI����ʼ���ڶ���
%     TableData = TableData(find(ismember(TableData(:,{'date';'time'}),TargetListI(1,{'date';'time'}),'rows'),1,'first'):find(TableData.date<=StrategyPara.edDate,1,'last'),:);
%     TableData.adjfactor(TableData.code==700021 & TableData.date==20181019) = TableData.adjfactor(TableData.code==700021 & TableData.date==20181022);
%     TableData.adjfactorABS(TableData.code==700021 & TableData.date==20181019) = TableData.adjfactorABS(TableData.code==700021 & TableData.date==20181022);
%     TableData.adjfactor(TableData.code==700020 & TableData.date==20181019) = TableData.adjfactor(TableData.code==700020 & TableData.date==20181022);
%     TableData.adjfactorABS(TableData.code==700020 & TableData.date==20181019) = TableData.adjfactorABS(TableData.code==700020 & TableData.date==20181022);
%     TableData.adjfactor(TableData.code==700022 & TableData.date==20181019) = TableData.adjfactor(TableData.code==700022 & TableData.date==20181022);
%     TableData.adjfactorABS(TableData.code==700022 & TableData.date==20181019) = TableData.adjfactorABS(TableData.code==700022 & TableData.date==20181022);
%     TableData.adjfactor(TableData.code==700022 & TableData.date==20181116) = TableData.adjfactor(TableData.code==700022 & TableData.date==20181119);
%     TableData.adjfactorABS(TableData.code==700022 & TableData.date==20181116) = TableData.adjfactorABS(TableData.code==700022 & TableData.date==20181119);

    % ��������
    [tdList,err] = calRtnByRealData_v2_2(TargetListI,TableData,StrategyPara,TradePara);
    if err==1
        return;
    end
    % �������
    analysisI = getCTAAnalysis(tdList);
    % ��ֵ
    eval(['BacktestResult.',fut,'=tdList;'])
    eval(['Analysis.',fut,'=analysisI;'])
end

% �������
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
    