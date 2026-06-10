local CloneFunction = clonefunction or function(Func)
	return Func;
end;

local PCall: (any, ...any) -> (boolean, ...any) = CloneFunction(pcall);
local ToString: (any) -> string = CloneFunction(tostring);

local IPairs = CloneFunction(ipairs);

local StringLower: (string) -> string = CloneFunction(string.lower);
local StringFind: (string, string, number?, boolean?) -> number? = CloneFunction(string.find);

local TaskDelay = CloneFunction(task.delay);

local Players = cloneref(game:GetService("Players"));

local BLOCKED_EXECUTORS = {
	"xeno",
};

local GetExecutorName do
	GetExecutorName = function(): string?
		if identifyexecutor then
			local Success, Name = PCall(identifyexecutor);

			if Success and Name then
				return ToString(Name);
			end
		end

		if getexecutorname then
			local Success, Name = PCall(getexecutorname);

			if Success and Name then
				return ToString(Name);
			end
		end

		if EXECUTOR_NAME then
			return ToString(EXECUTOR_NAME);
		end

		return nil;
	end;
end

local IsBlockedExecutor do
	IsBlockedExecutor = function(): (boolean, string?)
		local Name = GetExecutorName();

		if not Name then
			return false, nil;
		end

		local LowerName = StringLower(Name);

		for _, BlockedName in IPairs(BLOCKED_EXECUTORS) do
			if StringFind(LowerName, BlockedName, 1, true) then
				return true, Name;
			end
		end

		return false, nil;
	end;
end

local IsBlockedExecutor do
	IsBlockedExecutor = function(): (boolean, string?)
		local Name = GetExecutorName() or GetExecutorNameFromGlobals();

		if not Name then
			return false, nil;
		end

		local LowerName = Name:lower();

		for _, BlockedName in IPairs(BLOCKED_EXECUTORS) do
			if LowerName:find(BlockedName, 1, true) then
				return true, Name;
			end
		end

		return false, nil;
	end;
end

do
	local Blocked, ExecutorName = IsBlockedExecutor();

	if Blocked then
		Players.LocalPlayer:Kick(
			"\n[Loader] Executor not supported: "
			.. ExecutorName
			.. "\nPlease use a supported executor."
		);

		return;
	end
end

local LibClass = loadstring(game:HttpGet(
	"https://github.com/PLU3t0/Meathead/raw/refs/heads/main/OperationOne-main/ui_lib.lua"
))();

local PLACE_IDS = {
	["AstroOp1"]       = 72920620366355;
	["OperationOnev2"] = 72920620366355;
	["Bloxstrike"]     = 114234929420007;
};

local SCRIPT_URLS = {
	["AstroOp1"]       = "https://github.com/PLU3t0/Meathead/raw/refs/heads/main/OperationOne-main/loader.lua";
	["OperationOnev2"] = "https://github.com/PLU3t0/Meathead/raw/refs/heads/main/OperationOne-main/v2.lua";
	["Bloxstrike"]     = "https://github.com/PLU3t0/Meathead/raw/refs/heads/main/Bloxstrike/loader.lua";
};

local Window;

local CloseLoader do
	CloseLoader = function()
		for _, Callback in IPairs(Window._closeCallbacks or {}) do
			PCall(Callback);
		end

		Window._disconnectAll();

		if Window.screenGui and Window.screenGui.Parent then
			Window.screenGui:Destroy();
		end
	end;
end

local Execute do
	Execute = function(GameName: string)
		local RequiredPlaceId = PLACE_IDS[GameName];
		local CurrentPlaceId  = game.PlaceId;

		if CurrentPlaceId ~= RequiredPlaceId then
			Window:notify(
				"Wrong Game",
				GameName
					.. " requires place ID "
					.. ToString(RequiredPlaceId)
					.. ". You are in "
					.. ToString(CurrentPlaceId)
					.. ".",
				nil,
				false
			);

			return;
		end

		local Success, Result = PCall(
			loadstring,
			game:HttpGet(SCRIPT_URLS[GameName])
		);

		if not Success then
			Window:notify(
				"Load Error",
				"Failed to load "
					.. GameName
					.. ": "
					.. ToString(Result),
				nil,
				false
			);

			return;
		end

		local Executed, Error = PCall(Result);

		if not Executed then
			Window:notify(
				"Script Error",
				GameName
					.. " errored: "
					.. ToString(Error),
				nil,
				false
			);

			return;
		end

		Window:notify(
			"Success",
			GameName
				.. " loaded successfully, wait 1-5 seconds for the Gui",
			nil,
			false
		);

		TaskDelay(1.5, CloseLoader);
	end;
end

Window = LibClass.new("Loader");

Window:addTab("Games");
Window:addSection("Select Game");

Window:addButton("AstroOp1", function()
	Execute("AstroOp1");
end);

Window:addButton("OperationOne v2", function()
	Execute("OperationOnev2");
end);

Window:addButton("Bloxstrike", function()
	Execute("Bloxstrike");
end);

Window:notify(
	"Loader",
	"Select a game to inject.",
	nil,
	false
);
