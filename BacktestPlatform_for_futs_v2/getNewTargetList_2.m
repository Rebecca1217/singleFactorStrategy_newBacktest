function [newList,err] = getNewTargetList_2(listI,hisHands,chgIF,hisMainCont,info)
% 交易单可能有三种情况：
% 1.如果有一个交易单，不用处理
% 2.如果有两个交易单，只有两种情况：
% 2.1.无条件开+平（有条件平或者无条件平都有可能）
% 2.2.两笔平仓条件不同的平仓单
% 3.三个交易单：
% 开+无条件平+有条件平（其中有条件平和开是对应的，并且无条件平要把历史仓位完全平掉）
% 处理方式：
% 开平不合并
% 单子的交易顺序：
% 无条件平；开；有条件平

err = 0;
date = info.date(1);
time = info.time(1);
% 先检查一下交易单是否有误
if ~isempty(listI)
    if height(listI)==1 %只有一笔交易单
        if ismember('开',listI.Mark)
            if hisHands~=0 && sign(hisHands)~=sign(listI.hands) %未平仓的情况下反向开仓
                disp([num2str(date),' ',num2str(time),'交易单有误,未平仓的情况下发出了反向开仓指令！！'])
                err = 1;
            end
        elseif ismember('平',listI.Mark)
            if hisHands==0 || sign(hisHands)==sign(listI.hands) %平仓单有误
                disp([num2str(date),' ',num2str(time),'交易单有误,仓位不足无法执行平仓指令！！'])
                err = 1;
            end
        end
    elseif height(listI)==2
        if sum(ismember(listI.Mark,'平'))==2 %全是平仓单
            if abs(hisHands)<abs(sum(listI.hands)) || sign(hisHands)==sign(listI.hands(1)) || sign(hisHands)==sign(listI.hands(2))
                disp([num2str(date),' ',num2str(time),'交易单有误,仓位不足无法执行平仓指令！！'])
                err = 1;
            end
            if height(unique(listI(:,{'targetP';'targetC'})))==1 %说明两个平仓单的平仓条件是一致的，应该合并才对
                disp([num2str(date),' ',num2str(time),'交易单有误,两个平仓单的平仓条件一致，检查是否需要合并！！'])
                err = 1;
            end
        elseif sum(ismember(listI.Mark,'开'))==2 %全是开仓单
            disp([num2str(date),' ',num2str(time),'交易单有误,不应出现两个开仓单，检查是否需要合并！！'])
            err = 1;
        else %一个开仓单一个平仓单
            % 判断平仓单类型
            tmpO = listI(ismember(listI.Mark,'开'),:);
            tmpC = listI(ismember(listI.Mark,'平'),:);
            if isnan(tmpC.targetP) && isnan(tmpC.targetC) %无条件平
                if hisHands==0 || sign(hisHands)==sign(tmpC.hands) || abs(hisHands)<abs(tmpC.hands)
                    disp([num2str(date),' ',num2str(time),'交易单有误,仓位不足无法执行平仓指令！！'])
                    err = 1;
                else
                    if sign(tmpO.hands)==sign(hisHands) %开平需要轧差
                        netHands = tmpO.hands+tmpC.hands;
                        if netHands==0
                            listI = [];
                        elseif sign(netHands)==sign(hisHands) %净开仓
                            listI = tmpO;
                            listI.hands = netHands;
                        else %净平仓
                            listI = tmpC;
                            listI.hands = netHands;
                        end
                    else %开仓的方向是反向的
                        if tmpC.hands~=-hisHands
                            disp([num2str(date),' ',num2str(time),'交易单有误,未平仓的情况下发出了反向开仓指令！！'])
                            err = 1;
                        end
                    end
                end
            else %有条件的平仓,开仓的方向必须和历史仓位相同
                if sign(tmpO.hands)~=sign(hisHands)
                    disp([num2str(date),' ',num2str(time),'交易单有误,未平仓的情况下发出了反向开仓指令！！'])
                    err = 1;
                end
            end
        end
    elseif height(listI)==3 %开、无条件平、有条件平
        if hisHands==0
            disp([num2str(date),' ',num2str(time),'交易单有误,没有历史持仓的情况下单个交易日的交易单不应超过2个！！'])
            err = 1;
        else
            tmpCN = listI(ismember(listI.Mark,'平') & isnan(listI.targetP) & isnan(listI.targetC),:);
            tmpC2 = listI(ismember(listI.Mark,'平') & (~isnan(listI.targetP) | ~isnan(listI.targetC)),:);
            tmpO = listI(ismember(listI.Mark,'开'),:);
            if isempty(tmpCN) || isempty(tmpC2) || isempty(tmpO)
                disp([num2str(date),' ',num2str(time),'交易单有误,三个交易单类型有误！！'])
                err = 1;
            else %一定要先把原有的仓位先平完；有条件平仓一定是与开仓对应的
                % 分两种情况：
                % 无条件平仓单将原仓位全平：可以同向开仓或者反向开仓，有条件平仓单要和新的开仓单对应
                % 无条件平仓单没有将原仓位全平：只能同向开仓，最后头寸要和原头寸方向相同
                if tmpCN.hands==-hisHands %全平
                    if abs(tmpO.hands)<abs(tmpC2.hands) || sign(tmpO.hands)==sign(tmpC2.hands)
                        disp([num2str(date),' ',num2str(time),'交易单有误,新的开仓单和平仓单不对应！！'])
                        err = 1;
                    end
                elseif abs(tmpCN.hands)<abs(hisHands) && sign(tmpCN.hands)==-sign(hisHands) % 没有全平
                    if sign(hisHands+tmpCN.hands+tmpC2.hands+tmpO.hands)~=sign(hisHands) || sign(hisHands+tmpCN.hands+tmpC2.hands+tmpO.hands)~=0
                        disp([num2str(date),' ',num2str(time),'交易单有误,仓位不足无法执行平仓指令！！'])
                        err = 1;
                    else
                        if sign(tmpO.hands)~=sign(hisHands)
                            disp([num2str(date),' ',num2str(time),'交易单有误,未平仓的情况下发出了反向开仓指令！！'])
                            err = 1;
                        end
                    end
                else
                    disp([num2str(date),' ',num2str(time),'交易单有误,仓位不足无法执行平仓指令！！'])
                    err = 1;
                end
            end
        end
    elseif height(listI)>3
        disp([num2str(date),' ',num2str(time),'交易单有误,单个交易日的交易单不应超过3个！！'])
        err = 1;
    end
end
if err==1
    newList = [];
    return;
end

fut = regexp(hisMainCont,'\D*','match');
fut = fut{1};

if hisHands==0 || (hisHands~=0 && chgIF==0)
    newList = listI;
else %有历史持仓且要换月   
    % 平旧合约的交易单
    listC = info(:,{'date';'time'});
    listC.futCont = {hisMainCont};
    listC.hands = -hisHands;
    listC.targetP = nan;
    listC.targetC = nan;
    listC.Mark = {'平'};
    listC.fut = {fut};
    newList = listC;
    %
    if isempty(listI) %当天没有额外的交易
        listO = info;
        listO.hands = hisHands;
        listO.targetP = nan;
        listO.targetC = nan;
        listO.Mark = {'开'};
        listO.fut = {fut};
        newList = [newList;listO];
    else
        if height(listI)==1
            if strcmp(listI.Mark,'开')
                listO = listI;
                listO.hands = listO.hands+hisHands;
            else
                netHands = hisHands+listI.hands;
                % 在新合约上开仓
                listO = info;
                listO.hands = netHands;
                listO.targetP = nan;
                listO.targetC = nan;
                listO.Mark = {'开'};
                listO.fut = {fut};
            end
            newList = [newList;listO];
        elseif height(listI)==2 %两笔
            if ismember('开',listI.Mark) %一开一平
                % 如果是条件平，当前的开仓一定和历史持仓方向相同，所以把开仓交易单合并一下
                % 如果是无条件平，则平仓手数一定和历史持仓是相同的，然后进行反向开仓
                tmpO = listI(ismember(listI.Mark,'开'),:);
                tmpC = listI(ismember(listI.Mark,'平'),:);
                if ~isnan(tmpC.targetP) || ~isnan(tmpC.targetC) %有条件的平
                    listO = info;
                    listO.hands = hisHands+tmpO.hands;
                    listO.targetP = nan;
                    listO.targetC = nan;
                    listO.Mark = {'开'};
                    listO.fut = {fut};
                    newList = [newList;listO;tmpC];
                else % 无条件的平
                    newList = [newList;tmpO];
                end
            else %两笔平仓单
                tmpCN = listI(isnan(listI.targetP) & isnan(listI.targetC),:);
                if ~isempty(tmpCN) %无条件平仓单
                    netHands = hisHands+tmp.hands;
                else
                    netHands = hisHands;
                end
                listO = info;
                listO.hands = netHands;
                listO.targetP = nan;
                listO.targetC = nan;
                listO.Mark = {'开'};
                listO.fut = {fut};
                % 其他的平仓单
                tmpC2 = listI(~isnan(listI.targetP) | ~isnan(listI.targetC),:);
                newList = [newList;listO;tmpC2];
            end
        else %三笔:平+开+有条件平
            % 平仓单和新合约上的开仓单轧差
            tmpCN = listI(ismember(listI.Mark,'平') & isnan(listI.targetP) & isnan(listI.targetC),:);
            tmpC2 = listI(ismember(listI.Mark,'平') & (~isnan(listI.targetP) | ~isnan(listI.targetC)),:);
            tmpO = listI(ismember(listI.Mark,'开'),:);
            netHands = hisHands+tmpCN.hands+tmpO.hands; %净开仓手数：新合约上的开仓单和无条件平仓单和开仓单合并
            listO = info;
            listO.hands = netHands;
            listO.targetP = nan;
            listO.targetC = nan;
            listO.Mark = {'开'};
            listO.fut = {fut};
            newList = [newList;listO;tmpC2];
        end
    end
end

      
% 排序：无条件平+开+有条件平
if height(newList)>1
    tmpCN = newList(ismember(newList.Mark,'平') & isnan(newList.targetP) & isnan(newList.targetC),:);
    tmpO = newList(ismember(newList.Mark,'开'),:);
    tmpC = newList(ismember(newList.Mark,'平') & (~isnan(newList.targetP) | ~isnan(newList.targetC)),:);
    newList = [tmpCN;tmpO;tmpC];
end
newList(newList.hands==0,:) = [];
