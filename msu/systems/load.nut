::MSU.System <- {};
::MSU.SystemID <- {
	Serialization = 0,
	ModSettings = 1,
	Registry = 2,
	Log = 3,
	Keybinds = 4,
	PersistentData = 5,
	Tooltips = 6
};

local function includeLoad( _folder )
{
	::includeLoad("msu/systems/", _folder);
}

local function includeFile( _file )
{
	::includeFile("msu/systems/", _file + ".nut")
}

includeFile("system");
includeFile("system_mod_addon");
includeLoad("registry");
includeLoad("debug");
includeLoad("mod_settings");
includeLoad("serialization");
includeLoad("keybinds");
includeLoad("persistent_data");
includeLoad("tooltips");

includeFile("mod");
