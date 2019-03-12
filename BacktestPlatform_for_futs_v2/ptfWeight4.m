function [TableHands,error] = ptfWeight4(TableData,type,volWin)
% TableData格式：date,time,code
% type=0:等权；type=1:波动率倒数归一；type=2：ATR倒数归一；type=3：等ATR；type=4：等波动率；type=5：等风险贡献；type=6：等手数
% volWin:波动率的窗口期参数,默认值是20
% ------------------------------------
% 注意：
% 1.等ATR和ATR倒数加权归一化只针对期货来做
% 2.如果是期货的话，要考虑流动性的问题，流动性不好的品种不分配权重
% 处理方式：先剔除流动性不好的品种，然后计算完仓位之后再把流动性不好的品种添加上，TableWeight的长度和TableData相同
% 3.等风险贡献部分暂时无法实现，因为无法计算协方差矩阵
% --------------------------------------
% 20180513：不能先剔除流动性不好的品种，要在计算完波动率之后再剔除，不然计算波动率用的数据是不连续的
% 20180514：修改了历史波动率计算的代码，期货计算的时候不能剔除amt为0的数据，因为在那一段就是交易不活跃，剔除之后计算的波动率不能反映当时的真实波动情况
% 20180813：输入的type也可以是str格式的
% 20181129：对期货的流动性进行重新判断，过去20日日均成交量大于1w手
% 20181203:：输出为手数

% 判断是否是期货，如果是期货的话，先剔除流动性不好的品种
if TableData.code(1)<700000 %如果是股票，增加合约乘数列，值均为1
    TableData.multifactor = ones(height(TableData),1);
end
%
if isa(type,'char')
    typeList = {'eqSize';'normVol';'normATR';'eqATR';'eqVol';'eqRisk';'eqHands'};
    type = find(ismember(typeList,type))-1;
end
% 计算历史波动率
if ismember(type,[1,4,5]) %type1,4,5需要用到波动率数据
    %计算历史波动率，剔除停牌(amt=0)的天数，再填充
    TableData.adjclose = TableData.close .* TableData.adjfactor;
    TableData = sortrows(TableData,{'code';'date';'time'},'ascend');
    TableData.preadjclose = shiftN(TableData.adjclose,TableData.code,1);
    TableData.pctchange = TableData.adjclose./TableData.preadjclose -1;
    if nargin==2
        win = 20;
    else
        win = volWin;
    end
    if TableData.code(1)>700000 %期货
        iTableData = TableData;
    else
        iTableData = TableData(TableData.amt>0,:); %股票要剔除amt=0的部分
    end
    iTableData.hisVolatility =  movstd(iTableData.pctchange,[win-1,0],0,1,'Endpoints','fill'); %
    nanL = NanL_from_chgCode(iTableData.code,win);
    iTableData.hisVolatility(nanL) = nan;
    TableData = outerjoin(TableData,iTableData(:,{'code','date','time','hisVolatility'}),'MergeKeys',true,'Type','left');
    TableData = sortrows(TableData,{'code';'date';'time'},'ascend');% 再次排序
    if TableData.code(1)<700000 %股票
        TableData.hisVolatility(TableData.amt==0) = nan;
        %剔除异常值：波动率太小，导致权重过大
        TableData.hisVolatility(TableData.hisVolatility<0.001) = nan;
    end
    TableData.hisVolatility1 = fillmissing(TableData.hisVolatility,'previous');
    TableData.hisVolatility1(nanL) = nan;
end  
  
% 判断是否是期货，如果是期货的话，先剔除流动性不好的品种
if TableData.code(1)>700000
    % 进行流动性筛选
    TableOri = TableData;
    TableData(TableData.status==0,:) = [];
end
    
error = 0;
% 判断一下品种和采用的处理方式是否匹配
if ismember(type,[2,3])
    if TableData.code(1)<700000 %股票
        disp('股票不能采用ATR的方式进行权重分配，需修改权重分配方式！')
        error = 1;
        TableHands = [];
        return;
    end
end

TableData = sortrows(TableData,{'date','time','code'});
if type == 0 %eqSize
    TableHands = TableData(:,{'date';'time';'code'});
    TableHands.hand = round(5000000./(TableData.close.*TableData.multifactor));
elseif type ==1 %波动率倒数归一
    %计算权重
    TableData.volweight = 1./TableData.hisVolatility1;
    tbl_dt=varfun(@nansum,TableData(:,{'date','time','volweight'}),'GroupingVariables',{'date','time'});
    TableHands = outerjoin(TableData(:,{'date','time','code','volweight'}),tbl_dt,'MergeKeys',true,'Type','left');
    TableHands.weight = TableHands.volweight./TableHands.nansum_volweight;
elseif type ==2  %仅针对期货,atr倒数诡异 
    TableData.atrweight = 1./(TableData.atrABS./TableData.close);
    tbl_dt=varfun(@nansum,TableData(:,{'date','time','atrweight'}),'GroupingVariables',{'date','time'});
    TableHands = outerjoin(TableData(:,{'date','time','code','atrweight'}),tbl_dt,'MergeKeys',true,'Type','left');
    TableHands.weight = TableHands.atrweight./TableHands.nansum_atrweight;
elseif type==3 %等ATR，仅针对期货
    TableHands = TableData(:,{'date','time','code'});
    % 开仓手数=atr预算/(atr的绝对数值*合约乘数)
    TableHands.hand = round(100000./(TableData.atrABS.*TableData.multifactor)); 
%     % 折算到市值，按照固定的总市值进行分配
%     TableData = sortrows(TableData,{'date','time','code'});
%     % 开仓市值=atr预算/(atr的绝对数值*合约乘数)*未复权收盘价
%     TableData.openSize = 100000./TableData.atrABS.*TableData.close; %开仓市值
%     tmp = TableData(:,{'date','time','code','openSize'});
%     TotalSize_dly = varfun(@nansum,tmp,'GroupingVariables',{'date','time'});
%     TotalSize_dly = TotalSize_dly(:,{'date';'time';'nansum_openSize'});
%     tmp = outerjoin(tmp,TotalSize_dly,'MergeKeys',true,'Type','left');
%     tmp.weight = tmp.openSize./tmp.nansum_openSize; %持仓权重
%     TableWeight = tmp(:,{'date';'time';'code';'weight'});
%     TableHands.hand = round(10000000*TableWeight.weight./(TableData.multifactor.*TableData.close));
elseif type==4 % 等波动率，股票期货均可
    TableData = sortrows(TableData,{'date','time','code'});
    TableData.calP = TableData.close; %以防股票不是用未复权收盘价
    % 开仓市值=波动率预算/波动率*未复权收盘价*合约乘数
    TableData.openSize = 1./TableData.hisVolatility1.*TableData.multifactor.*TableData.calP; %开仓市值
    tmp = TableData(:,{'date','time','openSize'});
    TotalSize_dly = varfun(@nansum,tmp,'GroupingVariables',{'date','time'});
    tmp = outerjoin(tmp,TotalSize_dly,'MergeKeys',true,'Type','left');
    weight = tmp.openSize./tmp.nansum_openSize; %持仓权重
    TableHands = table;
    TableHands.date = TableData.date;
    TableHands.time = TableData.time;
    TableHands.code = TableData.code;
    TableHands.weight = weight;
% elseif type==5 %等风险贡献，股票期货均可
elseif type==6 % 等手数，股票期货均可
    TableData = sortrows(TableData,{'date';'time';'code'});
    TableData.calP = TableData.close; %用未复权收盘价计算
    % 开仓市值=手数*未复权收盘价*合约乘数
    TableData.openSize = 1*TableData.calP.*TableData.multifactor; %开仓市值
    tmp = TableData(:,{'date','time','openSize'});
    TotalSize_dly = varfun(@nansum,tmp,'GroupingVariables',{'date','time'});
    tmp = outerjoin(tmp,TotalSize_dly,'MergeKeys',true,'Type','left');
    weight = tmp.openSize./tmp.nansum_openSize; %持仓权重
    TableHands = table;
    TableHands.date = TableData.date;
    TableHands.time = TableData.time;
    TableHands.code = TableData.code;
    TableHands.weight = weight;
end
    
if TableData.code(1)>700000
    TableHands = outerjoin(TableOri,TableHands,'MergeKeys',true,'Type','left');
end
TableHands = TableHands(:,{'date','time','code','hand'});
TableHands.hand(isnan(TableHands.hand)) = 0;    
end

