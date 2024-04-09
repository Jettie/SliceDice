--初始参数
SLICEDICE_VERSION = "SliceDice 1.0"

SLICEDICE_AUTHOR = "Jettie"

SLICEDICE_STATUS = 1

SLICEDICE_TEXT = "JT"

SLICEDICE_INVERT = false

SLICEDICE_SHOW = 0

SLICEDICE_SCALE = 1

SLICEDICE_PROFILE = ""

SliceDice_Save = {}

SLICEDICE_VARIABLES_LOADED = false

SLICEDICE_VARIABLE_TIMER = 0

--SND GV
SND_IS_ACTIVE = false
SND_STARTTIME = 0
SND_TIMELEFT = 0
SND_ENDTIME = 0

--加载时，注册事件
function SliceDice_OnLoad()
	this:RegisterEvent("PLAYER_AURAS_CHANGED");

	SLASH_SLICEDICE1 = "/slicedice";
	SLASH_SLICEDICE2 = "/slice";

	SlashCmdList["SLICEDICE"] = function(msg)
		SliceDice_SlashCommandHandler(msg);
	end

	DEFAULT_CHAT_FRAME:AddMessage(SLICEDICE_VERSION.."  By "..SLICEDICE_AUTHOR.." ( /slice )");
end

--事件处理
function SliceDice_OnEvent(event)
	if( SLICEDICE_STATUS == 0 ) then
		return
	end
	
	SliceDice_EventHandler[event](arg1, arg2, arg3, arg4, arg5);
end

SliceDice_EventHandler = {}

--光环变化，可以在这里判断切割，同时判断是否显示隐藏
SliceDice_EventHandler["PLAYER_AURAS_CHANGED"] = function()

	SliceDice_OnUpdate();
end

--命令处理，暂时保留
function SliceDice_SlashCommandHandler(msg)
	if( msg ) then
		local command = string.lower(msg);
		if( command == "on" ) then
			if( SLICEDICE_STATUS == 0 ) then
				SLICEDICE_STATUS = 1;
				SliceDice_Save[SLICEDICE_PROFILE].status = SLICEDICE_STATUS;
				DEFAULT_CHAT_FRAME:AddMessage("SliceDice enabled");
				SliceDiceBar:Show();
			end
		elseif( command == "off" ) then
			if( SLICEDICE_STATUS ~= 0 ) then
				SLICEDICE_STATUS = 0;
				SliceDice_Save[SLICEDICE_PROFILE].status = SLICEDICE_STATUS;
				DEFAULT_CHAT_FRAME:AddMessage("SliceDice disabled");
				SliceDiceBar:Hide();
			end
		elseif( command == "unlock" ) then
			if( SLICEDICE_STATUS ~= 2 ) then
				SLICEDICE_STATUS = 2;
				SliceDice_Save[SLICEDICE_PROFILE].status = SLICEDICE_STATUS;
				DEFAULT_CHAT_FRAME:AddMessage("SliceDice unlocked");
			end
		elseif( command == "lock" ) then
			if( SLICEDICE_STATUS == 2 ) then
				SLICEDICE_STATUS = 1;
				SliceDice_Save[SLICEDICE_PROFILE].status = SLICEDICE_STATUS;
				DEFAULT_CHAT_FRAME:AddMessage("SliceDice locked");
			end
		elseif( command == "clear" ) then
			local pn = UnitName("player");
			if(pn ~= nil and pn ~= UNKNOWNBEING and pn ~= UKNOWNBEING and pn ~= UNKNOWNOBJECT) then
				SLICEDICE_PROFILE = pn .. " of " .. GetCVar("RealmName");
				SliceDice_Save[SLICEDICE_PROFILE] = nil;
				SLICEDICE_VARIABLES_LOADED = false;
				SliceDice_LoadVariables(2);
			else
				DEFAULT_CHAT_FRAME:AddMessage("SliceDice: World not yet loaded, please wait...")
			end
		elseif( command == "invert" ) then
			SLICEDICE_INVERT = not SLICEDICE_INVERT;
			SliceDice_Save[SLICEDICE_PROFILE].invert = SLICEDICE_INVERT;
			if SLICEDICE_INVERT then
				DEFAULT_CHAT_FRAME:AddMessage("SliceDice inversion on");
			else
				DEFAULT_CHAT_FRAME:AddMessage("SliceDice inversion off");
			end
		elseif( command == "show always") then
			SliceDice_Save[SLICEDICE_PROFILE].show = 0;
			SLICEDICE_SHOW = SliceDice_Save[SLICEDICE_PROFILE].show
			if SLICEDICE_STATUS ~= 0 then
				SliceDiceBar:Show()
			end
		elseif( command == "show combat") then
			SliceDice_Save[SLICEDICE_PROFILE].show = 1;
			SLICEDICE_SHOW = SliceDice_Save[SLICEDICE_PROFILE].show
			if SLICEDICE_STATUS ~= 0 then
				if UnitAffectingCombat("player") then
					EnerbyWatchBar:Show()
				else
					SliceDiceBar:Hide()
				end
			end
		elseif( command == "show stealth" or command == "show stealthonly" ) then
      if ( command == "show stealth" ) then
			  SliceDice_Save[SLICEDICE_PROFILE].show = 2;
      else
  			SliceDice_Save[SLICEDICE_PROFILE].show = 3;
      end
			SLICEDICE_SHOW = SliceDice_Save[SLICEDICE_PROFILE].show
			local i = 0
			while GetPlayerBuffTexture(i) ~= nil do
				if GetPlayerBuffTexture(i) == "Interface\\Icons\\Ability_Stealth" then
					SliceDiceBar:Show()
					return
				else
					i = i + 1
				end
			end
			if UnitAffectingCombat("player") then
				SliceDiceBar:Show()
			else
				SliceDiceBar:Hide()
			end
		elseif( string.sub(command, 1, 5) == "scale" ) then
			DEFAULT_CHAT_FRAME:AddMessage("Usage : /slice scale NUMBER (0.25 =< scale <= 3.0)")
			local scale = tonumber(string.sub(command, 7))
			if( scale <= 3.0 and scale >= 0.25 ) then
				SliceDice_Save[SLICEDICE_PROFILE].scale = scale;
				SLICEDICE_SCALE = scale;
				SliceDiceBar:SetScale(SLICEDICE_SCALE * UIParent:GetScale());
				DEFAULT_CHAT_FRAME:AddMessage("SliceDice scale set to "..scale);
			else
				SliceDice_Help()
			end
		else
			SliceDice_Help();
		end
	end
end

--检查切割
function checkSnd()
	
	local i = 0
	local timeleft = 0
	local checktime = GetTime()
	local sndfound = false

	while GetPlayerBuffTexture(i) ~= nil do

		if GetPlayerBuffTexture(i) == "Interface\\Icons\\Ability_Rogue_SliceDice" then
			timeleft = GetPlayerBuffTimeLeft(i)
--			DEFAULT_CHAT_FRAME:AddMessage('Slice snd found!!')
			sndfound = true
			SND_IS_ACTIVE = true
			return i, checktime, timeleft
		else
			i = i + 1
		end
	end

--	DEFAULT_CHAT_FRAME:AddMessage('No snd!!')
	SND_IS_ACTIVE = false
	return -1, 0, 0

end

--避免释放低级切割亏时间 JT自己用的
function castSnd()
	local c = GetComboPoints("target")
	local talentrank = select(5,GetTalentInfo(2, 6))
	local sndtimetable = { 9, 12, 15, 18, 21 }
	local _, _, sndtimeleft = checkSnd()
	if c > 0 and sndtimeleft < sndtimetable[c]*(1+0.15*talentrank) then
		CastSpellByName("切割")
	end
end

--避免释放低级切割亏时间(只判断) JT自己用的
function canSnd()

	local c = GetComboPoints("target")
	local talentrank = select(5,GetTalentInfo(2, 6))
	local sndtimetable = { 9, 12, 15, 18, 21 }
	local _, _, sndtimeleft = checkSnd()

	if c > 0 and sndtimeleft < sndtimetable[c]*(1+0.15*talentrank) then
		return true
	else
		return false
	end
end

--刷新显示，用这部分直接改成切割判断试试
function SliceDice_OnUpdate()
	if( SLICEDICE_STATUS == 0 ) then
		return;
	end

	local sparkPosition = 0;
	
	local sndindex, sndstart, sndtimeleft = checkSnd()
--	DEFAULT_CHAT_FRAME:AddMessage('sndindex: '..sndindex.." sndstart: "..sndstart.." sndtimeleft: "..sndtimeleft)
	local sndendtime = sndstart +sndtimeleft
	local fraction = 0
	local direction = "LEFT"

	if SLICEDICE_INVERT then
		fraction = 1
	end

	--战斗中 或者 有切割的时候保持显示
	if UnitAffectingCombat("player") or SND_IS_ACTIVE then
		SliceDiceBar:Show()
	else
		SliceDiceBar:Hide()
	end

	if ( SLICEDICE_STATUS ~= 2 ) then
		SliceDiceBar:EnableMouse(false)
	else
		SliceDiceBar:EnableMouse(true)
	end

	if SND_IS_ACTIVE then 
		if SND_ENDTIME < sndendtime then
			SND_STARTTIME = sndstart
			SND_TIMELEFT = sndtimeleft
			SND_ENDTIME = sndendtime
		else
			SND_ENDTIME = SND_ENDTIME
		end
		fraction = ( sndtimeleft ) / ( SND_ENDTIME - SND_STARTTIME )

	else
		SND_IS_ACTIVE = false
		SND_STARTTIME = 0
		SND_TIMELEFT = 0
		SND_ENDTIME = 0
	end

	SliceDiceFrameStatusBar:SetMinMaxValues(0, 1);

	sparkPosition = ( ( sndtimeleft ) / ( SND_ENDTIME - SND_STARTTIME )) * SliceDiceFrameStatusBar:GetWidth()
--	DEFAULT_CHAT_FRAME:AddMessage('STARTTIME: '..SND_STARTTIME.." SND_ENDTIME: "..SND_ENDTIME.." SND_TIMELEFT: "..SND_TIMELEFT)

	if SLICEDICE_INVERT then
		direction = "RIGHT"
		sparkPosition = 0 - sparkPosition
		SliceDiceFrameStatusBar:SetValue( 1 - fraction);
	else
		SliceDiceFrameStatusBar:SetValue(fraction);
	end

--	if( sparkPosition < 0 ) then
--		sparkPosition = 0;
--	end

	SliceDiceSpark:SetPoint("CENTER", "SliceDiceFrameStatusBar", direction, sparkPosition, -1);
	SliceDice_TextUpdate(sndtimeleft);

	--剩余2秒变色
	if sndtimeleft <=2 then
		SliceDiceFrameStatusBar:SetStatusBarColor("1", "0.5", "0.8")
	else
		SliceDiceFrameStatusBar:SetStatusBarColor("1", "0.88", "0.69")
	end


end


--设置数据处理
function SliceDice_LoadVariables(arg1)
	if SLICEDICE_VARIABLES_LOADED then
		return
	end

	SLICEDICE_VARIABLE_TIMER = SLICEDICE_VARIABLE_TIMER + arg1
	if SLICEDICE_VARIABLE_TIMER < 0.2 then
		return
	end
	SLICEDICE_VARIABLE_TIMER = 0;

	local playerName=UnitName("player")
	if playerName==nil or playerName==UNKNOWNBEING or playerName==UKNOWNBEING or playerName==UNKNOWNOBJECT then
		return
	end

	SLICEDICE_PROFILE = playerName.." of "..GetCVar("RealmName");

	if SliceDice_Save[SLICEDICE_PROFILE] == nil then
		SliceDice_Save[SLICEDICE_PROFILE] = { };
		if SD_Save ~= nil and SD_Save[SLICEDICE_PROFILE] ~= nil then
			if SD_Save[SLICEDICE_PROFILE].status ~= nil then
				SliceDice_Save[SLICEDICE_PROFILE].status = SD_Save[SLICEDICE_PROFILE].status;
				SD_Save[SLICEDICE_PROFILE].status = nil
			end
			if SD_Save[SLICEDICE_PROFILE].text ~= nil then
				SliceDice_Save[SLICEDICE_PROFILE].text = SD_Save[SLICEDICE_PROFILE].text;
				SD_Save[SLICEDICE_PROFILE].text = nil
			end
			if SD_Save[SLICEDICE_PROFILE] == { } then
				SD_Save[SLICEDICE_PROFILE] = nil;
			end
			if SD_Save == { } then
				SD_Save = nil;
			end
		end
	end

	if SliceDice_Save[SLICEDICE_PROFILE].status == nil then
		SliceDice_Save[SLICEDICE_PROFILE].status = 1;
	end
	if SliceDice_Save[SLICEDICE_PROFILE].text == nil then
		SliceDice_Save[SLICEDICE_PROFILE].text = "JT";
	end
	if SliceDice_Save[SLICEDICE_PROFILE].invert == nil then
		SliceDice_Save[SLICEDICE_PROFILE].invert = false;
	end
	if SliceDice_Save[SLICEDICE_PROFILE].show == nil then
		SliceDice_Save[SLICEDICE_PROFILE].show = 0;
	end
	if SliceDice_Save[SLICEDICE_PROFILE].scale == nil then
		SliceDice_Save[SLICEDICE_PROFILE].scale = 1;
	end

	SLICEDICE_TEXT = SliceDice_Save[SLICEDICE_PROFILE].text;
	SLICEDICE_STATUS = SliceDice_Save[SLICEDICE_PROFILE].status;
	SLICEDICE_INVERT = SliceDice_Save[SLICEDICE_PROFILE].invert;
	SLICEDICE_SHOW = SliceDice_Save[SLICEDICE_PROFILE].show;
	SLICEDICE_SCALE = SliceDice_Save[SLICEDICE_PROFILE].scale;	

	SliceDiceBar:SetScale(SLICEDICE_SCALE * UIParent:GetScale());

	if( SLICEDICE_STATUS ~= 0 ) then
		if SLICEDICE_SHOW == 0 then
			SliceDiceBar:Show();
		end
	else
		SliceDiceBar:Hide();
	end

	SLICEDICE_VARIABLES_LOADED = true;
	SliceDice_Variable_Frame:Hide();

end

function formatTime(t)
	local h = floor(t / 3600)
	local m = floor((t - h * 3600) / 60)
	local s = t - (h * 3600 + m * 60)
	if h > 0 then
		return format('%d:%02d:02d', h, m, s)
	elseif m > 0 then
		return format('%d:%02d', m, s)
	elseif s < 10 then
		return format('%.1f', s)
	else
		return format('%.0f', s)
	end
end


function SliceDice_TextUpdate(t)
	if SND_IS_ACTIVE then 
		if t > 0 then
			SliceDiceText:SetText(formatTime(t));
			SliceDiceText:Show();
		else
			SliceDiceText:SetText("");
			SliceDiceText:Hide();
		end
	else
		SliceDiceText:SetText("");
		SliceDiceText:Hide();
	end
end

function SliceDice_Help()
	DEFAULT_CHAT_FRAME:AddMessage(SLICEDICE_VERSION.." : Usage - /slice option");
	DEFAULT_CHAT_FRAME:AddMessage(" options:");
	DEFAULT_CHAT_FRAME:AddMessage("  on      : Enables SliceDice");
	DEFAULT_CHAT_FRAME:AddMessage("  off     : Disables SliceDice");
	DEFAULT_CHAT_FRAME:AddMessage("  unlock  : Allows you to move SliceDice");
	DEFAULT_CHAT_FRAME:AddMessage("  lock    : Locks SliceDice");
	DEFAULT_CHAT_FRAME:AddMessage("  invert  : Invert progress bar direction");
	DEFAULT_CHAT_FRAME:AddMessage("  scale _ : Scales SliceDice (0.25 - 3.0)");
	DEFAULT_CHAT_FRAME:AddMessage("  help    : Prints help for certain options (below)");

end

