this.MSU.Class.KeybindsSystem <- class extends this.MSU.Class.System
{
	KeybindsByKey = null;
	KeybindsByMod = null;
	KeybindsForJS = null;
	PressedKeys = null;

	constructor()
	{
		base.constructor(this.MSU.SystemID.Keybinds);
		this.KeybindsByKey = {};
		this.KeybindsByMod = {};
		this.KeybindsForJS = {};
		this.PressedKeys = {};
	}

	function registerMod( _modID )
	{
		base.registerMod(_modID);
		if (!::MSU.System.ModSettings.has(_modID))
		{
			::MSU.System.ModSettings.registerMod(_modID);
		}

		::MSU.System.ModSettings.get(_modID).addPage(::MSU.Class.SettingsPage("Keybinds"));

		this.KeybindsByMod[_modID] <- {};
		this.KeybindsForJS[_modID] <- {};
	}

	// maybe add a Bind suffix to all these functions: eg addBind, updateBind etc
	function add( _keybind, _makeSetting = true )
	{
		if (!(_keybind instanceof ::MSU.Class.Keybind))
		{
			throw this.Exception.InvalidType;
		}
		if (_keybind instanceof ::MSU.Class.KeybindJS)
		{
			this.KeybindsForJS[_keybind.getModID()][_keybind.getID()] <- _keybind;
		}
		else
		{
			foreach (key in _keybind.getRawKeyCombinations())
			{
				::printWarning(format("Adding keyCombination %s for keybind %s", key, _keybind.getID()), ::MSU.ID, "keybinds")
				if (!(key in this.KeybindsByKey))
				{
					this.KeybindsByKey[key] <- [];
					::printWarning("Creating Keybind array for key: " + key, ::MSU.ID, "keybinds")
				}
				this.KeybindsByKey[key].push(_keybind);
			}
		}

		this.KeybindsByMod[_keybind.getModID()][_keybind.getID()] <- _keybind;
		if (_makeSetting)
		{
			this.addKeybindSetting(_keybind)
		}
	}

	// Private
	function remove( _modID, _id )
	{
		this.logInfo(this.KeybindsByMod[_modID][_id]);
		local keybind = this.KeybindsByMod[_modID].rawdelete(_id);
		if (keybind instanceof ::MSU.Class.KeybindJS)
		{
			this.KeybindsForJS[_modID].rawdelete(_id);
			::MSU.UI.JSConnection.removeKeybind(keybind);
		}
		else
		{
			foreach (key in keybind.getRawKeyCombinations())
			{
				this.KeybindsByKey[key].remove(this.KeybindsByKey[key].find(keybind));
				if (this.KeybindsByKey[key].len() == 0)
				{
					this.KeybindsByKey.rawdelete(key);
				}
			}
		}
		return keybind;
	}

	function update( _modID, _id, _keyCombinations )
	{
		local keybind = this.remove(_modID, _id);
		keybind.KeyCombinations = split(::MSU.Key.sortKeyCombinationsString(_keyCombinations),"/");
		::getModSetting(_modID, _id).set(keybind.getKeyCombatinations(), true, true, false);
		this.add(keybind, false);
	}

	function call( _key, _environment, _state, _keyState )
	{
		if (!(_key in this.KeybindsByKey))
		{
			return;
		}

		foreach (keybind in this.KeybindsByKey[_key])
		{
			::printWarning(format("Checking handler function: key %s | ID %s | State %s", _key, keybind.getID(), keybind.getState().tostring()), ::MSU.ID, "keybinds");
			if (keybind.getState() != _state && keybind.getState != ::MSU.Key.State.All)
			{
				continue;
			}

			if (!keybind.callOnKeyState(_keyState))
			{
				continue;
			}

			::printWarning(format("Calling handler function: key %s | ID %s | State %s", _key, keybind.getID(), keybind.getState().tostring()), this.MSU.ID, "keybinds");
			if (keybind.call(_environment) == false)
			{
            	::printWarning("Returning after keybind call returned false.", ::MSU.ID, "keybinds");
				return false;
			}
		}
	}

	function addKeybindSetting( _keybind )
	{
		::MSU.System.ModSettings.get(_keybind.getModID()).getPage("Keybinds").add(_keybind.makeSetting());
	}

	function getJSKeybinds()
	{
		// ret = {
		// 	modID = {
		// 		keybindID = {
		// 			name = "",
		// 			key = ""
		// 		}
		// 	}
		// }
		local ret = {}
		foreach (modID, mod in this.KeybindsForJS)
		{
			ret[modID] <- {};
			foreach (keybindID, keybind in mod)
			{
				ret[modID][keybindID] <- keybind.getForJS();
			}
		}
		return ret;
	}

	function onKeyInput( _key, _environment, _state )
	{
		local keyAsString = _key.getKey().tostring();
		if (!(keyAsString in ::MSU.Key.KeyMapSQ))
		{
			::printWarning("Unknown key pressed: %s" + _key.getKey(), ::MSU.ID, "keybinds");
			return;
		}
		keyAsString = ::MSU.Key.KeyMapSQ[keyAsString];
		return this.onInput(_key, _environment, _state, keyAsString);
	}

	function onMouseInput( _key, _environment, _state )
	{
		local keyAsString = _key.getID().tostring();
		if (!(keyAsString in ::MSU.Key.MouseMapSQ))
		{
			::printWarning("Unknown key pressed: %s" + _key.getID(), ::MSU.ID, "keybinds");
			return;
		}
		keyAsString = ::MSU.Key.MouseMapSQ[keyAsString];
		return this.onInput(_key, _environment, _state, keyAsString);
	}

	// Private
	function onInput( _key, _environment, _state, _keyAsString )
	{
		local key = "";
		foreach (pressedKeyID, value in this.PressedKeys)
		{
			if (_keyAsString != pressedKeyID)
			{
				key += pressedKeyID + "+";
			}
		}
		key += _keyAsString;
		return this.call(key, _environment, _state, _key.getState());
	}

	function updatePressedKey( _key )
	{
		local key = _key.getKey().tostring();
		if (!(key in ::MSU.Key.KeyMapSQ))
		{
			return false;
		}

		key = ::MSU.Key.KeyMapSQ[key];
		local wasPressed = key in this.PressedKeys;
		if (_key.getState() == 1)
		{
			if (wasPressed)
			{
				return false;
			}
			this.PressedKeys[key] <- 1;
		}
		else
		{
			delete this.PressedKeys[key];
		}
		return true;
	}
}
