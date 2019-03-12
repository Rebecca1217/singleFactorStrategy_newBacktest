function BacktestAnalysis = getCTAAnalysis(tdList)
% 计算绩效


nv = tdList{:,{'date';'time';'profit'}}; %金额
nv = [nv(:,1:2),cumsum(nv(:,3)),nv(:,3)];
if nv(1,2)==999999999
    dayNum = 244;
else % 高频，计算每年平均的K线根数
    % 计算每天的K线根数，然后对这个根数求平均，然后乘以244
    tmp = array2table(nv(:,1:2),'VariableNames',{'date';'time'});
    tmp = varfun(@nansum,tmp,'GroupingVariables','date');
    meanBarNum = floor(mean(tmp.GroupCount));
    dayNum = 244*meanBarNum;
end
nv = nv(:,[1,3,4]);
tt = {'累计收益';'年化收益';'年化波动';'日胜率';'盈亏比';'最大回撤';'回撤最长持续时间';'夏普比';'收益回撤比';'回测开始日期';'回测结束日期'};

analysis = zeros(length(tt),1);
analysis(1) = nv(end,2); %累计收益
analysis(2) = mean(nv(:,3))*dayNum; %年化收益
analysis(3) = std(nv(:,3))*sqrt(dayNum); %年化波动
analysis(4) = sum(nv(:,3)>0)/sum(nv(:,3)~=0); %有仓位的情况下的日胜率
analysis(5) = mean(nv(nv(:,3)>0,3))/-mean(nv(nv(:,3)<0,3)); %盈亏比
dd = nv(:,2)-cummax(nv(:,2)); 
% dd由0变负，开始回撤；dd由负变0，结束回撤
sgn = sign(dd);
noDDLocs = find(sgn==0); %没有回撤的时间点所在行
if noDDLocs(end)~=length(sgn)
    noDDLocs(end+1) = length(sgn);
end
analysis(6) = -min(dd); %最大回撤
try
    analysis(7) = max(diff(noDDLocs)); %回撤最长持续时长
catch
    analysis(7) = length(dd);
end
analysis(8) = analysis(2)/analysis(3); %sr
analysis(9) = analysis(2)/-min(dd); %calmar
analysis(10) = nv(1,1);
analysis(11) = nv(end,1);


BacktestAnalysis = [tt,num2cell(analysis)];


end