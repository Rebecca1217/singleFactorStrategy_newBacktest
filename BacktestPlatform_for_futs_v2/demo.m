%% ���߲���
load TargetTradeList\TargetTradeList_Dly.mat

TradePara.futDataPath = 'U:\�ڻ�����\Data_Cleaning\WWB';
[BacktestResult_Dly,BacktestAnalysis_Dly] = CTABacktest_GeneralPlatform_v2_1(TargetTradeList);


%% �����߲���
load TargetTradeList\TargetTradeList_5Min.mat

StrategyPara.freqK = '30MIN';
StrategyPara.edDate = 20181008; 
TradePara.futDataPath = 'U:\�ڻ�����\Data_Cleaning\WWB';
[BacktestResult_5M,BacktestAnalysis_5M] = CTABacktest_GeneralPlatform_v2_1(TargetListI,StrategyPara,TradePara);
