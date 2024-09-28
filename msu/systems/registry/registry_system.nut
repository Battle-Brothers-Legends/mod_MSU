::MSU.Class.RegistrySystem <- class extends ::MSU.Class.System
{
	static ModSources = {};
	static ModSourceDomain = ::MSU.Class.Enum([
		"GitHub",
		"GitHubTags",
		"NexusMods"
	]);
	Mods = null;
	constructor()
	{
		base.constructor(::MSU.SystemID.Registry);
		this.Mods = {};
	}

	function addNewModSource( _modSource )
	{
		::MSU.requireInstanceOf(::MSU.Class.ModSource, _modSource.instance());
		this.ModSources[_modSource.ModSourceDomain] <- _modSource;
	}

	function addMod( _mod )
	{
		this.Mods[_mod.getID()] <- _mod;
		_mod.Registry = ::MSU.Class.RegistryModAddon(_mod);
		::logInfo(format("<span style=\"color: green;\">MSU registered <span style=\"color: white;\">%s</span>, version: <span style=\"color: white;\">%s</span></span>", _mod.getName(), _mod.getVersionString()));
	}

	function registerMod( _mod )
	{
		if (_mod.getID() != "vanilla")
		{
			if (_mod.getID() in this.Mods)
			{
				::logError("Duplicate Mod ID for mod: " + _mod.getID());
				throw ::MSU.Exception.DuplicateKey(_mod.getID());
			}
			if (::Hooks.getMod(_mod.getID()) == null)
			{
				::logError("Register your mod using the same ID with mod_hooks before creating a ::MSU.Class.Mod");
				throw ::MSU.Exception.KeyNotFound(_mod.getID());
			}
			if (::Hooks.getMod(_mod.getID()).getVersionString() != _mod.getVersionString())
			{
				::logError("Register your mod using the same version with mod_hooks before creating a ::MSU.Class.Mod");
				throw ::MSU.Exception.InvalidValue(_mod.getVersionString());
			}
		}

		this.addMod(_mod);
	}

	function getModsForUpdateCheck()
	{
		local ret = {};
		foreach (mod in this.Mods)
		{
			if (mod.Registry.hasUpdateSource())
			{
				ret[mod.getID()] <- mod.Registry.getUpdateSource().getUpdateURL();
			}
		}
		return ret;
	}

	function checkIfModVersionsAreNew( _modVersionData )
	{
		local storedInfo = {};
		if (::MSU.Mod.PersistentData.hasFile("StoredModUpdates"))
		{
			storedInfo = ::MSU.Mod.PersistentData.readFile("StoredModUpdates");
		}
		local modInfos = {};
		foreach (modID, modData in _modVersionData)
		{
			modInfos[modID] <- {};
			local mod = ::MSU.System.Registry.getMod(modID);
			local release = mod.Registry.getUpdateSource().extractRelease(modData);
			if (!release) continue;
			local version = release.Version;
			if (!::MSU.SemVer.isSemVer(version))
			{
				::MSU.Popup.addMessage(format("The version '%s' from the mod %s (%s) isn't using <span style=\"color: lightblue; text-decoration: underline;\" onclick=\"openURL('https://semver.org')\">semantic versioning</span> for its online versions, despite registering to use the MSU update checker. Let the mod author know if you see this error", version,  mod.getName(), modID));
				continue;
			}
			if (!::MSU.SemVer.compareVersionWithOperator(version, ">", mod)) continue;
			local type = "PATCH";
			if (::MSU.SemVer.compareMajorVersionWithOperator(version, ">", mod)) type = "MAJOR";
			else if (::MSU.SemVer.compareMinorVersionWithOperator(version, ">", mod)) type = "MINOR";
			modInfos[modID].UpdateInfo <- {
				name = mod.getName(),
				currentVersion = mod.getVersionString(),
				availableVersion = version,
				updateType = type,
				changes = release.Changes,
				sources = {},
				isNew = true
			};
			modInfos[modID].UpdateInfo.isNew = !(modID in storedInfo) || (storedInfo[modID].UpdateInfo.availableVersion != modInfos[modID].UpdateInfo.availableVersion);
			foreach (modSource in mod.Registry.__ModSources)
			{
				local sourceKey = ::MSU.System.Registry.ModSourceDomain.getKeyForValue(modSource.ModSourceDomain);
				modInfos[modID].UpdateInfo.sources[sourceKey] <- {URL = modSource.getURL(), icon = modSource.Icon};
			}
		}
		// rate limit handling; would actually need to check for rate limits... But I suppose not many players will hit that.
		if (modInfos.len() > 0) ::MSU.Mod.PersistentData.createFile("StoredModUpdates", modInfos);
		return modInfos;
	}

	function getMod( _modID )
	{
		if (!(_modID in this.Mods))
		{
			::logError("Mod " + _modID + " not found in MSU! Did you forget to create a Mod Object via ::MSU.Class.Mod?");
			throw ::MSU.Exception.KeyNotFound(_modID);
		}
		return this.Mods[_modID];
	}

	function hasMod( _modID )
	{
		return (_modID in this.Mods);
	}
}
