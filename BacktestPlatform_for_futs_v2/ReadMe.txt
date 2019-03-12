一、货数据存储路径：\\10.201.227.227\期货数据\Data_Cleaning\WWB
二、回测：
运行demo（修改数据路径）
三、回测平台CTABacktest_GeneralPlatform_v2_1说明：
1.用于各个频率的期货策略回测，仅适用于单策略的回测，支持Bar内止盈止损的回测
2.输入参数：TargetTradeList,StrategyPara,TradePara
3.参数说明：
3.1. TargetTradeList说明：
（1）目标交易单，标明后一根bar需要进行的交易，不需要考虑换月的问题（程序内部自行处理）
（2）table格式，共7列：date,time,futCont,hands,targetP,targetC,Mark
date,time:指令发出对应的时间（比如20181119对应的开仓指令，用20181120开盘价入场）
futCont:交易的合约代码，如A1901（注意：月份合约必须是4位数字，比如A809必须写作A0809）
hands:交易的手数（带方向，买：1，卖：-1）
targetP:止盈目标价（如果没有，为nan）
targetC:止损目标价（如果没有，为nan）
Mark:开平标记（开、平）
具体示例见TargetTradeList中的文件
3.2. StrategyPara说明：
（1）策略相关的参数
（2）struct格式，包括crossType,freqK,edDate三个参数
crossType:止盈时穿过价格的方式，dn（默认，下穿）或者up
freqK:K线频率，Dly（默认）或者NMIN(5MIN,10MIN,...)
edDate:回测截止日期，nan（默认，默认回测到最新日期）
（3）传入时，可以只对某个参数赋值，其他采用默认参数
3.3. TradePara说明：
（1）交易相关的参数
（2）struct格式，包括fixC,slip,PType,tickNum,futDataPath,tickDataPath六个参数
fixC:固定成本，0.0002（默认）
slip:滑点个数，2（默认）
PType:交易价格，open（默认开盘价交易）
tickNum:用到tick数据时时间滞后数，10（默认，比如判断100000000出场，出场价为100005000时刻的价格）
futDataPath:K线数据存储路径，\\10.201.227.227\期货数据\Data_Cleaning\WWB（默认）
tickDataPath:tick数据存储路径，\\10.201.227.227\期货数据\Data_Cleaning\WWB（默认）
（3）传入时，可以只对某个参数赋值，其他采用默认参数