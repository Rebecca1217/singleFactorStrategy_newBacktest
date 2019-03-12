function TableHands = getTableHands_Between_Codes(TableData,type,Reb,wkDay)
% TableData格式：date,time,code
% 导入的一定是日线数据
% -------------------------
% 20181224：
% 原版本的权重是逐日再平衡，现在改成每周再平衡一次，默认周五再平衡

if nargin==2
    Reb = 0;
elseif nargin==3
    Reb = 1;
    wkDay = 'Fri';
end

ttSize = 50000000; %开仓总市值
ttATR = 1000000; %总ATR

% 进行流动性筛选
TableOri = TableData;
TableData(TableData.status==0,:) = [];

TableData = sortrows(TableData,{'date';'time';'code'});
sumFuts = varfun(@nansum,TableData(:,{'date';'time'}),'GroupingVariables',{'date';'time'}); %各个交易日的品种总数
TableData = outerjoin(TableData,sumFuts,'Mergekeys',1,'type','left');
TableData = sortrows(TableData,{'date';'time';'code'});
if strcmpi(type,'eqSize')
    % 各个品种权重
    TableData.weight = 1./TableData.GroupCount;
    TableData.Size = ttSize.*TableData.weight;
    TableHands = TableData(:,{'date';'time';'code'});
    TableHands.hand = round(TableData.Size./(TableData.multifactor.*TableData.close));
elseif strcmpi(type,'eqATR')
    % 总波动水平不变，总波动为100w
    TableData.SizeATR = ttATR./TableData.GroupCount; %每个品种上面分配到的ATR数量
    TableHands = TableData(:,{'date';'time';'code'});
    TableHands.hand = round(TableData.SizeATR./(TableData.multifactor.*TableData.atrABS));
elseif strcmpi(type,'eqATR2')
    % 单个品种有波动上限，20w
    TableData.SizeATR = min([ttATR./TableData.GroupCount,200000*ones(height(TableData),1)],[],2);
    TableHands = TableData(:,{'date';'time';'code'});
    TableHands.hand = round(TableData.SizeATR./(TableData.multifactor.*TableData.atrABS));
elseif strcmpi(type,'eqATR3')
    % 固定单个品种的ATR=100000
    TableHands = TableData(:,{'date';'time';'code'});
    TableHands.hand = round(100000./(TableData.multifactor.*TableData.atrABS));
end

    
TableHands = outerjoin(TableOri(:,{'date';'time';'code'}),TableHands,'MergeKeys',true,'Type','left');
TableHands = TableHands(:,{'date','time','code','hand'});
TableHands.hand(isnan(TableHands.hand)) = 0;    
TableHands = sortrows(TableHands,{'date';'time';'code'});

% 每周进行权重的再平衡
if Reb==1 %需要进行再平衡
    wkDay = lower(wkDay);
    wkNum = find(ismember({'mon';'tue';'wes';'thu';'fri'},wkDay))+1; %monday:2,...,friday:6
    stDate = TableHands.date(find(TableHands.hand~=0,1,'first')); %开始日期
    dateUni = unique(TableHands.date(TableHands.date>=stDate)); %全部的交易日期
    dateUni(:,2) = weekday(datenum(num2str(dateUni),'yyyymmdd'));
    % 提取需要再平衡的日期
    dateReb = dateUni(dateUni(:,2)==wkNum,1);
    dateReb(1) = [];
    dateReb = [stDate;dateReb];
    % 再平衡日期对应的持仓情况
    TableHandsReb = TableHands(ismember(TableHands.date,dateReb),:);
    % 日期补全
    TableHandsReb = outerjoin(TableOri(:,{'date';'time';'code'}),TableHandsReb,'MergeKeys',true,'Type','left');
    TableHandsReb = sortrows(TableHandsReb,{'code';'date';'time'});
    codeUni = unique(TableHandsReb.code);
    for c = 1:length(codeUni)
        tmp = TableHandsReb(TableHandsReb.code==codeUni(c),:);
        tmp.hand = fillmissing(tmp.hand,'previous');
        TableHandsReb.hand(TableHandsReb.code==codeUni(c)) = tmp.hand;
    end
    TableHands = TableHandsReb;  
    TableHands.hand(isnan(TableHands.hand)) = 0;
    TableHands = sortrows(TableHands,{'date';'time';'code'});
end

