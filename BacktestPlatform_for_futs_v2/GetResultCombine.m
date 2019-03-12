function [BacktestResult,BacktestAnalysis] = GetResultCombine(Result,Analysis)


BacktestResult = Result;
futs = fieldnames(Result); %Æ·ÖÖ
for i = 1:length(futs)
    tdList = eval(['Result.',futs{i}]);
    ana = eval(['Analysis.',futs{i}]);
    ana = array2table(ana,'VariableNames',{'title';futs{i}});
    %
    list = tdList(:,{'date';'time';'profit'});
    list.Properties.VariableNames = {'date';'time';futs{i}};
    if i==1
        rtn = list;
        BacktestAnalysis = ana;
    else
        if height(rtn)>height(list)
            rtn = outerjoin(rtn,list,'type','left','mergekeys',1);
        else
            rtn = outerjoin(list,rtn,'type','left','mergekeys',1);
        end
        BacktestAnalysis = [BacktestAnalysis,ana(:,2)];
    end
   
end

rtn = sortrows(rtn,{'date';'time'});
data = rtn{:,3:end};
data(isnan(data)) = 0;
rtn{:,3:end} = data;
rtn.portfolio = sum(data,2);

portfolio = rtn(:,{'date';'time';'portfolio'});
portfolio.Properties.VariableNames = {'date';'time';'profit'};
BacktestResult.portfolio = portfolio;

nv = array2table([rtn{:,{'date';'time'}},cumsum(rtn{:,3:end})],'VariableNames',rtn.Properties.VariableNames);
BacktestResult.Summary = nv;

analysisI = getCTAAnalysis(BacktestResult.portfolio);
BacktestAnalysis.portfolio = analysisI(:,2);