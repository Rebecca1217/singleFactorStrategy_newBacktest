function [newList,err] = getNewTargetList_tmp(listI,hisHands) 
% 对导入的未经处理的目标交易单进行预处理


if height(listI)==1
    newList = listI;
else %当天有多个交易单
    %划分开仓单和平仓单
    listO = listI(ismember(listI.Mark,'开'),:);
    listC = listI(ismember(listI.Mark,'平'),:);
    newList = [];
    % 开仓单合并
    if ~isempty(listO) %有开仓单
         if height(listO)==1
             newList = [newList;listO];
         else %有多个开仓单，进行合并
             % 先判断是否可以合并
             uni = unique(listO(:,{'date';'time';'futCode';'targetP';'targetC'}),'rows');
             if height(uni)==1
                 tthands = sum(listO.hands);
                 newList = [newList;[uni(:,{'date';'time';'futCode'}),array2table(tthands,'VariableNames',{'hands'}),uni(:,{'targetP';'targetC';'Mark'})]];
             else
                 disp([num2str(uni.date(1)),' ',num2str(uni.time(1)),'输入的开仓交易单有误！！'])
                 err = 1;
                 return;
             end
         end
    end
    % 平仓单合并
    if ~isempty(listC) %有平仓单
        if height(listC)==1
            newList = [newList;listC];
        else %有多个平仓单，进行合并
            % 先判断是否可以合并
            uni = unique(listC(:,{'date';'time';'futCode';'targetP';'targetC'}),'rows');
            if height(uni)==1
                tthands = sum(listC.hands);
                newList = [newList;[uni(:,{'date';'time';'futCode'}),array2table(tthands,'VariableNames',{'hands'}),uni(:,{'targetP';'targetC';'Mark'})]];
            else
                %多个单子的平仓条件可能不同
                newList = [newList;listC];
            end
        end
    end
    % 开仓单和平仓单进行合并
    % 上面的合并进行完之后，如果开仓单和平仓单都存在，则开仓单一个，平仓单有1个或者多个
    aimHands = hisHands+sum(newList.hands); %目标手数   
    if ~isempty(listO) && ~isempty(listC) %有开仓单和平仓单
        if aimHands==0 || sign(aimHands)==sign(hisHands) %目标手数的方向和原方向相同或者目标手数为0
            nlistO = newList(ismember(newList.Mark,'开'),:);
            nlistC = newList(ismember(newList.Mark,'平'),:);
            nlistO.Mark = {'平'};  %开仓单直接变为平仓单
            % 检查一下有没有可以和该平仓单合并的平仓单
            locs = find(isnan(nlistC.targetP) & isnan(nlistC.targetC));
            if ~isempty(locs)
                nlistO.hands = nlistC.hands(locs)+nlistO.hands;
                nlistC(locs,:) = [];
                if nlistO.hands>hisHands
                    tmp = nlistO;
                    tmp.hands = nlistO.hands-hisHands;
                    tmp.Mark = {'开'};
                    nlistO = [nlistO;tmp];
                end
            end
            newHisHands = hisHands+sum(nlistO.hands); %假设上述平仓操作已经做了之后的头寸
            newAimHands = aimHands-newHisHands; %距离目标手数还需要处理的部分，如果是负的，是需要开空的部分；如果是正的，是需要开多的部分
            if newAimHands~=0 %还有需要处理的头寸
                if height(nlistC)==1 %只有一笔平仓单了
                    nlistC.hands = newAimHands;
                    nlistC.Mark = {'条件开'};
                else %还有多笔平仓单，需要导入tick数据才能判断哪个平仓单改成条件开
                    % 导入tick数据
                    load([tickDataPath,'\',freqK,'\',num2str(nlistC.date(1)),'_',num2str(nlistC.time(1)),'.mat'])
                    % 判断各个条件下触到出场条件的时间，先触到的单子变成条件开
                    locs = zeros(height(nlistC),1);
                    for i = 1:height(nlistC)
                        [locs(i),err] = findOutTime(tickData,sign(nlistC.hands(i)),nlistC.targetP(i),nlistC.targetC(i),crossType);
                        if err==1
                            disp([num2str(nlistC.date(1)),' ',num2str(nlistC.time(1)),'传入的止盈止损价有误！！'])
                            return;
                        end
                    end
                    if locs(1)<locs(2) %先碰到的变为条件开
                        nlistC.Mark(1) = {'条件开'};
                    else
                        nlistC.Mark(2) = {'条件开'};
                    end                                            
                end
            end
            newList = [nlistO;nlistC];
        else %目标手数的方向和原方向相反
            % 生成一个新的平仓单，手数和原持仓手数相同
            nlistO = newList(1,:);
            nlistO.hands = -hisHands;
            nlistO.targetP = nan;
            nlistO.targetC = nan;
            nlistO.Mark = {'平'};
            % 剩余的手数
            newHisHands = hisHands+nlistO.hands; %假设上述平仓操作已经做了之后的头寸
            newAimHands = aimHands-newHisHands; %距离目标手数还需要处理的部分，如果是负的，是需要开空的部分；如果是正的，是需要开多的部分
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
        end
    end
                
end
             
             
        
