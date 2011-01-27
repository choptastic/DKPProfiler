DKPProfiler = {};
DKPProfilerCharInfo = {};
DKPProfilerGuildBank = {};
BankOpenedOnce = false;
local DKPPVersion = "0.637 (2010-01-24)";



function DKPProfiler_OnLoad(this)
	--his:RegisterEvent("CHAT_MSG_WHISPER");
	--this:RegisterEvent("PLAYER_ENTERING_WORLD");
	
	SlashCmdList["DKPProfiler"] = DKPProfiler_SlashHandler;
	SLASH_DKPProfiler1 = "/dkpp";
	SLASH_DKPProfiler2 = "/gbk";
	
	this:RegisterEvent("BANKFRAME_OPENED");
	this:RegisterEvent("GUILDBANKFRAME_OPENED");
	this:RegisterEvent("GUILDBANK_UPDATE_TABS");
	this:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED");
	this:RegisterEvent("PLAYERBANKSLOTS_CHANGED");
	this:RegisterEvent("BAG_UPDATE");
	this:RegisterEvent("TRADE_SKILL_SHOW");
	this:RegisterEvent("CRAFT_SHOW");
	this:RegisterEvent("CRAFT_UPDATE");
	this:RegisterEvent("TRADE_SKILL_UPDATE");
	this:RegisterEvent("CHARACTER_POINTS_CHANGED");
	this:RegisterEvent("CONFIRM_TALENT_WIPE");
	this:RegisterEvent("CHAT_MSG_SKILL");
	this:RegisterEvent("PLAYER_ENTERING_WORLD");
	--this:RegisterEvent("PLAYER_LEAVING_WORLD");
	this:RegisterEvent("CHAT_MSG_MONEY");
	this:RegisterEvent("UPDATE_FACTION");
	this:RegisterEvent("QUEST_WATCH_UPDATE");
	this:RegisterEvent("QUEST_FINISHED");
	this:RegisterEvent("QUEST_COMPLETE");
	this:RegisterEvent("QUEST_PROGRESS");
	this:RegisterEvent("ARENA_TEAM_UPDATE");
	this:RegisterEvent("ACHIEVEMENT_EARNED");

	DEFAULT_CHAT_FRAME:AddMessage("DKP Profiler (from DKPSystem.com) Version "..DKPPVersion.." loaded. ");
	DEFAULT_CHAT_FRAME:AddMessage("DKP Profiler will attempt to profile your character while you play, but typing |c00ffff00/dkpp|r will manually initiate a snapshot of the data available to the DKPProfiler mod");
end

function DKPPinitialize()
	if(DKPProfilerCharInfo == nil) then
		DKPProfilerCharInfo = {};
	end
	if DKPProfiler == nil then
		DKPProfiler = {};
	end
end

function DKPProfiler_OnEvent(self,event,...)
	local arg1 = ...;

	if (event == "BANKFRAME_OPENED") then
		BankOpenedOnce = true;
	elseif (event == "GUILDBANKFRAME_OPENED") then
		DKPPRefreshAllBankTabs();
	elseif (event == "GUILDBANK_UPDATE_TABS" or event=="GUILDBANKBAGSLOTS_CHANGED") then
		DKPPStoreGuildBankItems();
	elseif (event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE") then
		DKPPGetCurrentTradeSkill();
		DKPPGetTalents();
		DKPPGetQuests();
	elseif (event == "ACHIEVEMENT_EARNED") then
		DKPPGetAchievements();
	elseif (event == "CHAT_MSG_SKILL") then
		DKPPGetTalents();
	elseif (event == "ADDON_LOADED") then
		DKPPinitialize();
		DKPPGetPvP();
		DKPPGetTalents();
		DKPPGetGold();
		DKPPStorePlayerItems();
	elseif (event == "QUEST_WATCH_UPDATE" or event=="QUEST_FINISHED" or event=="QUEST_COMPLETE" or event=="QUEST_PROGRESS") then
		DKPPGetQuests();
	elseif (event == "CHARACTER_POINTS_CHANGED" or event=="CONFIRM_TALENT_WIPE" or event=="PLAYER_ENTERING_WORLD") then
		DKPPGetTalents();
	elseif (event == "UPDATE_FACTION") then
		DKPPGetReputations();
	elseif (event == "CHAT_MSG_MONEY") then
		DKPPGetGold();
	elseif (event == "ARENA_TEAM_UPDATE") then
		DKPPGetPvP();
	end
	if (event=="GUILDBANKFRAME_OPENED" or (BankOpenedOnce==true and (event == "BANKFRAME_OPENED" or (event == "PLAYERBANKSLOTS_CHANGED" and arg1 == nil) or (event == "BAG_UPDATE" and arg1 >= 6 and arg1 <= 10)))) then
		DKPPGetTalents();
		DKPPGetPvP();
		DKPPGetQuests();
		DKPPPurgeResistance();
		if(event == "BANKFRAME_OPENED") then
			DKPPStorePlayerItems();
			DKPPStoreBankItems();
		elseif(event == "GUILDBANKFRAME_OPENED") then
			DKPPStoreGuildBankGold();
		end
		DKPPGetGold();
	end
end

function DKPPRefreshAllBankTabs()
	local i;
	for i = 1,GetNumGuildBankTabs() do
		QueryGuildBankTab(i);
	end
end

function DKPPPurgeResistance()
	local player = UnitName("player");
	if(DKPProfilerCharInfo[player] == nil) then
		DKPProfilerCharInfo[player] = {};
	end
	DKPProfilerCharInfo[player].resistances = {};
end

function DKPProfiler_SlashHandler(msg)
	DEFAULT_CHAT_FRAME:AddMessage("DKP Profiler Version "..DKPPVersion);
	DKPPGetTalents();
	DKPPGetPvP();
	DKPPGetQuests();
	DKPPPurgeResistance();
	DKPPStorePlayerItems();
	DKPPGetGold();
	DKPPGetAchievements();
end

function DKPPGetAchievements()
	local player = UnitName("player");
	if(DKPProfilerCharInfo[player] == nil) then
		DKPPRofilerCharInfo[player] = {};
	end
	DKPProfilerCharInfo[player].achievements = {};
	local cats = GetCategoryList();
	local cat,ach,achs;
	local achi = 1;
	local achpoints,comp,desc;
	local catrec = {};
	for i,catid in pairs(cats) do
		cat = GetCategoryInfo(catid);
		local numach = GetCategoryNumAchievements(catid);
		for ii = 1,numach do
			local numdone = 0;
			achid,ach,achpoints,comp,_,_,_,desc = GetAchievementInfo(catid,ii);
			catrec = {};
			catrec.category = cat;
			catrec.ach = ach;
			catrec.description = desc;
			catrec.completed = comp;
			catrec.crit = {};

			local numcrit = GetAchievementNumCriteria(achid);
			for iii = 1,numcrit do
				local crit,_,critcomp = GetAchievementCriteriaInfo(achid,iii);
				if critcomp == false then
					catrec.crit[iii] = crit;
				else
					numdone = numdone + 1;
					catrec.crit[iii] = "<strike>"..crit.."</strike>";
				end
			end

			if numcrit == 0 then
				catrec.progress = nil;
			else
				catrec.progress = numdone.."/"..numcrit;
			end

			if comp or numdone>0 then
				DKPProfilerCharInfo[player].achievements[achi] = catrec;
				achi = achi + 1;
			end
		end
	end
	
end

function DKPPGetReputations()
	local faction,repstr, lvl, i, standingid,header,top,bot,mylvl,mymax,cat,counter;
	local player = UnitName("player");
	counter = 0;
	DKPPinitialize();
	if(DKPProfilerCharInfo[player] == nil) then
		DKPProfilerCharInfo[player] = {};
	end
	if GetNumFactions() > 0 then
		DKPProfilerCharInfo[player].factions = {};
		for i = 1,GetNumFactions() do
			faction,_,standingid,bot,top,lvl,_,_,header = GetFactionInfo(i);
			if header == nil and faction~=nil then
				mylvl = lvl-bot;
				mymax = top-bot;
				DKPProfilerCharInfo[player].factions[counter] = {};
				DKPProfilerCharInfo[player].factions[counter].category = cat;
				DKPProfilerCharInfo[player].factions[counter].faction = faction;
				DKPProfilerCharInfo[player].factions[counter].standinglabel=getglobal("FACTION_STANDING_LABEL"..standingid);
				DKPProfilerCharInfo[player].factions[counter].standingid=standingid;
				DKPProfilerCharInfo[player].factions[counter].level=mylvl;
				DKPProfilerCharInfo[player].factions[counter].maxlvl=mymax;
				counter = counter + 1;
			else
				cat = faction;
			end
		end
	end
end	


function DKPPGetQuests()
	local player = UnitName("player");
	counter = 0;
	DKPPinitialize();
	if(DKPProfilerCharInfo[player] == nil) then
		DKPProfilerCharInfo[player] = {};
	end
	DKPProfilerCharInfo[player].quests = {};
	local i=1;
	local headername = "";
	local questTitle = "";
	while (questTitle ~= nil and i < 80) do
		questTitle, level, tag, suggestedGroup, header, collapsed, completed = GetQuestLogTitle(i);
		if (not header) then
			DKPProfilerCharInfo[player].quests[counter] = {};
			DKPProfilerCharInfo[player].quests[counter].title = questTitle;
			DKPProfilerCharInfo[player].quests[counter].tag = tag;
			DKPProfilerCharInfo[player].quests[counter].header = headername;
			DKPProfilerCharInfo[player].quests[counter].completed = completed;
			DKPProfilerCharInfo[player].quests[counter].objectives = {};
			--local numobj = GetNumQuestLogLeaderBoards(i); --number of objectives
			local o = 1;
			local desc,done;
			desc = "dgdsgdfgdghfdhfdghf";
			while desc~=nil and desc~="" and o<10 do
				desc,_,done = GetQuestLogLeaderBoard(o,i);
				if(desc) then
					DKPProfilerCharInfo[player].quests[counter].objectives[o] = {};
					DKPProfilerCharInfo[player].quests[counter].objectives[o].text = desc;
					DKPProfilerCharInfo[player].quests[counter].objectives[o].done = done;
				end
				o = o + 1;
			end
			counter = counter + 1
		else
			headername = questTitle;
		end
		i = i + 1;
	end
end
	

function DKPPGetGold()
	local c = GetMoney();
	local g,s,level,race,class,apoints;
	g = math.floor(c/10000);
	c = c - (g*10000);
	s = math.floor(c/100);
	c = c - (s*100);
	local player = UnitName("player");
	if(DKPProfilerCharInfo[player] == nil) then
		DKPProfilerCharInfo[player] = {};
	end
	DKPProfilerCharInfo[player].money = g.." Gold, "..s.." Silver,"..c.." Copper";
	level = UnitLevel("player");
	race = UnitRace("player");
	class = UnitClass("player");
	apoints = GetTotalAchievementPoints();

	DKPProfilerCharInfo[player].achpoints = apoints;
	if level~=nil then
		DKPProfilerCharInfo[player].level = level;
	end
	if race~=nil then
		DKPProfilerCharInfo[player].race = race
	end
	if class~=nil then
		DKPProfilerCharInfo[player].class = class;
	end
	DKPProfilerCharInfo[player].realm = GetRealmName();
end

function DKPPGetTalents()
	local tab,tabname,talentname, rank, max, i;
	local talentstring = "";
	local player = UnitName("player");
	if(DKPProfilerCharInfo[player] == nil) then
		DKPProfilerCharInfo[player] = {};
	end
	if GetTalentInfo(1,1)~=nil then
		DKPProfilerCharInfo[player].talents = {};
		for tab = 1, GetNumTalentTabs() do
			tabname = GetTalentTabInfo(tab);
			DKPProfilerCharInfo[player].talents[tabname] = {};
			for i = 1, GetNumTalents(tab) do
				talentname,_,_,_,rank,max = GetTalentInfo(tab,i);
				DKPProfilerCharInfo[player].talents[tabname][i] = {};
				DKPProfilerCharInfo[player].talents[tabname][i].name = talentname;
				DKPProfilerCharInfo[player].talents[tabname][i].rank = rank;
				DKPProfilerCharInfo[player].talents[tabname][i].max = max;
				talentstring = talentstring .. rank;
			end
		end
		DKPProfilerCharInfo[player].talents.talentstring = talentstring;
	end
end

function DKPPGetCurrentTradeSkill()
	local profname, lvl, max = GetTradeSkillLine();
	local linked,linkedplayer = IsTradeSkillLinked();
	if linked then
		
	else
		local player = UnitName("player");
		
		if profname ~= nil and profname ~= "UNKNOWN" then
			if DKPProfilerCharInfo[player].professions == nil then
				DKPProfilerCharInfo[player].professions = {};
			end
			if DKPProfilerCharInfo[player].professions[profname]==nil then
				DKPProfilerCharInfo[player].professions[profname] = {};
			end
			if DKPProfilerCharInfo[player].professions[profname].skills == nil then
				DKPProfilerCharInfo[player].professions[profname].skills = {};
			end
			DKPProfilerCharInfo[player].professions[profname].level = lvl;
			local i, name, type;
			for i = 1,GetNumTradeSkills() do
				name, type, _, _ = GetTradeSkillInfo(i);
				if(type ~= "header")then
					DKPProfilerCharInfo[player].professions[profname].skills[name]=name;
				end
			end
		end
	end
end


function DKPPGetPvP()
	local player = UnitName("player");
	if(DKPProfilerCharInfo[player] == nil) then
		DKPProfilerCharInfo[player] = {};
	end
	if(DKPProfilerCharInfo[player].pvp == nil) then
		DKPProfilerCharInfo[player].pvp = {};
	end
	
	DKPProfilerCharInfo[player].pvp.arena = {};
	local team,size,rating;
	for i = 1,3 do
		team,size,rating = GetArenaTeam(i);
		if size ~= nil and size>0 then
			DKPProfilerCharInfo[player].pvp.arena[i] = {
				["teamname"] = team,
				["size"] = size,
				["rating"] = rating,
			};
		end
	end	
	local hk,dk,rank,rankid;
	hk, dk = GetPVPLifetimeStats();
	rankid = GetCurrentTitle();
	if rank ~= nil then
		rank = GetTitleName(rankid);
	else
		rank = nil;
	end
	DKPProfilerCharInfo[player].pvp.rankid = rankid;
	DKPProfilerCharInfo[player].pvp.rank = rank;
	DKPProfilerCharInfo[player].pvp.LifetimeHKs = hk;
	DKPProfilerCharInfo[player].pvp.LifetimeDKs = dk;
	--DKPProfilerCharInfo[player].pvp.HonorPoints = GetHonorCurrency(); -- call removed in 4.0
	--DKPProfilerCharInfo[player].pvp.ArenaPoints = GetArenaCurrency();

end


function PurgeNecessarySkills()
	local player = UnitName("player");
	local skill,v;
	for skill in pairs(DKPProfilerCharInfo[player].professions) do
		--DKPPPrint("Attempting to Purge: "..skill);
		if (IsMySkill(skill)==0) then
			--DKPPPrint("purging "..skill);
			DKPProfilerCharInfo[player].professions[skill] = nil;
		end
	end
end




function DKPPPrint(msg)
	DEFAULT_CHAT_FRAME:AddMessage("DKPP: "..msg);
end

function DKPPPrintAll()
	--DKPPPrint("Printing it");
	local i, v;
	local player = UnitName("player");
	for i, v in ipairs(DKPProfiler[player]["Bank"]) do DKPPPrint("Bank: " .. i .. " x " .. v) end
	for i, v in ipairs(DKPProfiler[player]["Bags"]) do DKPPPrint("Bags: " .. i .. " x " .. v) end
end

function DKPPNameFromLink(link)
	local quality;
	local s,e=string.find(link,"%[.*]");
	local itemname = string.sub(link,s+1,e-1);
	s,e = string.find(link,"item:%d+:%d+:%d+:%d+");
	local itemid = string.sub(link,s,e);
	local _,_,quality,_,itype,isubtype = GetItemInfo(itemid);
	--DKPPPrint(link..": "..itype.." :: "..isubtype.." :: "..ITEM_CLASSES_ALLOWED);
	if(quality == nil) then
		quality = 1;
	end
	return quality..":::"..itemname;
end

--StoredPlace can be: "Bank","Bags","Player" for Bank, Player's Bags, and Currently Equipped
function DKPPStoreBag(BagNum,StoredPlace)
	local items,name,itemtype,itemsubtype,equiploc,ttlevel;
	local player = UnitName("player");
	local i;
	local qty,quality,itemstring;
	local s,e;
	--DKPPPrint("Bag: "..BagNum);
	items = GetContainerNumSlots(BagNum);
	if (items) then
		for i = 1, items do
			link = GetContainerItemLink(BagNum, i);
			_, qty = GetContainerItemInfo(BagNum, i);
			if( link ) then
				--DKPPPrint("Doing Item: "..link);
				--name,quality = DKPPNameFromLink(link);
				name,_,quality,_,level,itemtype,itemsubtype,_,equiploc = GetItemInfo(link);
				class,ttlevel = DKPPGetClassAndLevelOfItem(BagNum,i);
				local totalitem = name;
				if class~=nil and string.len(class)>0 then
					totalitem=totalitem..";;"..class;
				end
				if ttlevel~=nil and string.len(ttlevel)>0 then
					totalitem=totalitem..";;"..ttlevel;
				end
				if (DKPProfiler[player][StoredPlace][totalitem]==nil or type(DKPProfiler[player][StoredPlace][totalitem])~="table") then
					DKPProfiler[player][StoredPlace][totalitem]={};
					if(qty==0) then
						qty=1;
					end
					DKPProfiler[player][StoredPlace][totalitem].qty=qty;
					DKPProfiler[player][StoredPlace][totalitem].quality=quality;
					if(level>0) then
						DKPProfiler[player][StoredPlace][totalitem].level=level;
					end
					DKPProfiler[player][StoredPlace][totalitem].itemtype=itemtype;
					DKPProfiler[player][StoredPlace][totalitem].itemsubtype=itemsubtype;
					DKPProfiler[player][StoredPlace][totalitem].equiploc=getglobal(equiploc);
					DKPProfiler[player][StoredPlace][totalitem].itemclasses=class;
				else
					DKPProfiler[player][StoredPlace][totalitem].qty=DKPProfiler[player][StoredPlace][totalitem].qty+qty;
				end
			end
		end
	end
end

function DKPPStorePlayer()
	local StoredPlace="Player";
	local player=UnitName("player");
	local classlvl,ttlevel;
	local i, link, name, s, e
	for i = 0,19 do
		link = GetInventoryItemLink("player", i);
		if (link) then
			--name = DKPPNameFromLink(link);
			name,_,quality,_,level,itemtype,itemsubtype,_,equiploc = GetItemInfo(link);
			class,ttlevel = DKPPGetClassAndLevelOfItem("player",i);
			local totalitem = name;
			if class ~= nil and string.len(class)>0 then
				totalitem=totalitem..";;"..class
			end
			if ttlevel ~= nil and string.len(ttlevel)>0 then
				totalitem=totalitem..";;"..ttlevel;
			end
			DKPProfiler[player][StoredPlace][totalitem]={};
			DKPProfiler[player][StoredPlace][totalitem].qty=qty;
			DKPProfiler[player][StoredPlace][totalitem].quality=quality;
			if(level>0) then
				DKPProfiler[player][StoredPlace][totalitem].level=level;
			end
			DKPProfiler[player][StoredPlace][totalitem].itemtype=itemtype;
			DKPProfiler[player][StoredPlace][totalitem].itemsubtype=itemsubtype;
			DKPProfiler[player][StoredPlace][totalitem].itemclasses=class;
			DKPProfiler[player][StoredPlace][totalitem].equiploc=getglobal(equiploc);
		end
	end
end
	
function DKPPStoreBankItems()
	local StoredPlace="Bank";
	local player = UnitName("player");
	local i;
	DKPProfiler[player][StoredPlace]={};
	DKPPStoreBag(BANK_CONTAINER,StoredPlace);
	for i = 5,10 do
		DKPPStoreBag(i,StoredPlace);
	end
end

function DKPPStorePlayerItems()
	local i;
	local player=UnitName("player");
	local StoredPlace="Bags";
	DKPPinitialize();
	if(DKPProfiler[player]==nil) then
		DKPProfiler[player]={};
	end
	DKPProfiler[player]["Player"]={};
	DKPPStorePlayer();

	DKPProfiler[player]["Bags"]={};
	for i = 0,4 do
		DKPPStoreBag(i,StoredPlace);
	end
	DKPPStoreBag(-2,StoredPlace);

end

function B(t)
	if( t == nil) then
		return "[Blank]";
	else
		return t;
	end
end

function DKPPStoreGuildBankItems()
	local name;
	local qty;
	local tabs;
	local i,j,items;
	tabs = GetNumGuildBankTabs();
	for i = 1,tabs do
		DKPProfilerGuildBank[i] = {};
		name = GetGuildBankTabInfo(i);
		DKPProfilerGuildBank[i].name = name;
		DKPProfilerGuildBank[i].items = {};
		for j = 1,98 do
			_,qty = GetGuildBankItemInfo(i,j);
			item = GetGuildBankItemLink(i,j);
			if(item~=nil) then
				name,_,quality,_,level,itemtype,itemsubtype,_,equiploc = GetItemInfo(item);
				class,ttlevel = DKPPGetClassAndLevelOfBankItem(i,j);
				local totalitem = name;
				if class ~= nil and string.len(class)>0 then
					totalitem=totalitem..";;"..class
				end
				if ttlevel ~= nil and string.len(ttlevel)>0 then
					totalitem=totalitem..";;"..ttlevel;
				end
				if (DKPProfilerGuildBank[i].items[totalitem]==nil or type(DKPProfilerGuildBank[i].items[totalitem])~="table") then
					DKPProfilerGuildBank[i].items[totalitem]={};
					DKPProfilerGuildBank[i].items[totalitem].qty=qty;
					DKPProfilerGuildBank[i].items[totalitem].quality=quality;
					if(level>0) then
						DKPProfilerGuildBank[i].items[totalitem].level=level;
					end
					DKPProfilerGuildBank[i].items[totalitem].itemtype=itemtype;
					DKPProfilerGuildBank[i].items[totalitem].itemsubtype=itemsubtype;
					DKPProfilerGuildBank[i].items[totalitem].itemclasses=class;
					DKPProfilerGuildBank[i].items[totalitem].equiploc=getglobal(equiploc);
				else
					DKPProfilerGuildBank[i].items[totalitem].qty=DKPProfilerGuildBank[i].items[totalitem].qty+qty;
				end
			end
		end
	end
end


function DKPPStoreGuildBankGold()
	
end

function DKPPNumNilZero(v)
	v = tonumber(v);
	if v == nil then
		v = 0
	end
	return v;
end

function DKPPGetClassAndLevelOfBankItem(tab,slot)
	local class,level=nil,nil;
	DKPPKTooltip:ClearLines();
	DKPPKTooltip:SetGuildBankItem(tab,slot);
	local textadd="";
	--DKPPPrint(DKPPKTooltip:NumLines());
	for i = 1,30 do
		local left = getglobal("DKPPKTooltipTextLeft"..i);
		local text;
		if left ~= nil then
			text = left:GetText();
			if text~=nil then
				_,_,c = string.find(text,"Classes:%s*(.+)%s*");
				if c~=nil then
					class = c;
				else
					_,_,l = string.find(text,"(Level%s%d*)");
					if l~=nil then
						level = l;
					end
				end
			end
		end
	end
	return class,level;
end

function DKPPGetClassAndLevelOfItem(bag,slot)
	local class,level=nil,nil;
	DKPPKTooltip:ClearLines();
	if(bag=="player") then
		DKPPKTooltip:SetInventoryItem("player",slot);
	else
		DKPPKTooltip:SetBagItem(bag,slot);
	end
	local textadd="";
	--DKPPPrint(DKPPKTooltip:NumLines());
	for i = 1,30 do
		local left = getglobal("DKPPKTooltipTextLeft"..i);
		local text;
		if left ~= nil then
			text = left:GetText();
			if text~=nil then
				_,_,c = string.find(text,"Classes:%s*(.+)%s*");
				if c~=nil then
					class = c;
				else
					_,_,l = string.find(text,"(Level%s%d*)");
					if l~=nil then
						level = l;
					end
				end
			end
		end
	end
	return class,level;
end













