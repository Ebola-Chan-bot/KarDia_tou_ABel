classdef Monster<handle
	properties(SetAccess=immutable)
		Name(1,1)string
	end
	properties(SetAccess=protected)
		EloHistory timetable
	end
	properties(Dependent)
		ELO
	end
	properties(Constant,GetAccess=protected)
		EloBasalRate=7;
	end
	methods
		function obj=Monster(Name)
			obj.Name=Name;
			obj.EloHistory.ELO(datetime)=1;
		end
		function E=get.ELO(obj)
			E=obj.EloHistory.ELO(end);
		end
	end
	methods(Static)
		function Fight(Attackers,Defenders,AttackersWin)
			switch nargin
				case 1
					%Attackers战胜了无名之辈
					NumMonsters=numel(Attackers);
					Timestamp=datetime;
					for A=1:NumMonsters
						Attackers(A).EloHistory.ELO(Timestamp)=Attackers(A).ELO+Monster.EloBasalRate/NumMonsters;
						fprintf('%s：%u→%u\n',Attackers(A).Name,uint16(Attackers(A).EloHistory.ELO(end-1)),uint16(Attackers(A).ELO));
					end
				case 2
					EloSettlement(Attackers,Defenders);
				case 3
					if AttackersWin
						%Attackers战胜了Defenders
						EloSettlement(Attackers,Defenders);
					else
						%Defenders战胜了Attackers
						EloSettlement(Defenders,Attackers);
					end
			end
		end
		function RL=RankList(Monsters)
			%输出Monster的排名
			%如果有多个Monster的ELO相同，则按Name字典序排列
			ELO=vertcat(Monsters.ELO);
			[ELO,SortIndex]=sort(ELO,'descend');
			RL=table(vertcat(Monsters(SortIndex).Name),uint16(ELO),'VariableNames',["Name","ELO"]);
		end
		function Rollback(Monsters,Timestamp)
			arguments
				Monsters(1,:)
				Timestamp datetime
			end
			ELO=[Monsters.ELO];
			for M=Monsters
				M.EloHistory(M.EloHistory.Time>Timestamp,:)=[];
			end
			arrayfun(@(M,OldElo)fprintf('%s：%u→%u\n',M.Name,uint16(OldElo),uint16(M.ELO)),Monsters,ELO);
		end
	end
end
function EloSettlement(Winners,Losers)
%需要考虑Winners和Losers可能有重叠
NumMonsters=numel(Losers);
EloChange=sqrt([Losers.ELO])*Monster.EloBasalRate/NumMonsters;
Timestamp=datetime;
for D=1:NumMonsters
	Losers(D).EloHistory.ELO(Timestamp)=max(Losers(D).ELO-EloChange(D),1);
end
NumMonsters=numel(Winners);
EloChange=sum(EloChange)/NumMonsters;
for A=1:NumMonsters
	Winners(A).EloHistory.ELO(Timestamp)=Winners(A).ELO+EloChange;
end
arrayfun(@(M)fprintf('%s：%u→%u\n',M.Name,uint16(M.EloHistory.ELO(end-1)),uint16(M.ELO)),union(Winners,Losers));
end