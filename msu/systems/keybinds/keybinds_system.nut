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

	function registerMod( _mod )
	{
		base.registerMod(_mod);
		if (!::MSU.System.ModSettings.has(_mod.getID()))
		{
			::MSU.System.ModSettings.registerMod(_mod);
		}

		_mod.Keybinds = ::MSU.Class.KeybindsModAddon(_mod);

		::MSU.System.ModSettings.get(_mod.getID()).addPage(::MSU.Class.SettingsPage("Keybinds"));

		this.KeybindsByMod[_mod.getID()] <- {};
		this.KeybindsForJS[_mod.getID()] <- {};
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
			if (::MSU.UI.JSConnection.isConnected())
			{
				::MSU.UI.JSConnection.addKeybind(_keybind);
			}
			this.KeybindsForJS[_keybind.getModID()][_keybind.getID()] <- _keybind;
		}
		else
		{
			foreach (key in _keybind.getRawKeyCombinations())
			{
				::MSU.Mod.Debug.printWarning(format("Adding keyCombination %s for keybind %s", key, _keybind.getID()), "keybinds")
				if (!(key in this.KeybindsByKey))
				{
					this.KeybindsByKey[key] <- [];
					::MSU.Mod.Debug.printWarning("Creating Keybind array for key: " + key, "keybinds")
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
		::getModSetting(_modID, _id).set(keybind.getKeyCombinations(), true, true, false);
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
			::MSU.Mod.Debug.printWarning("Checking keybind: " + keybind.tostring(), "keybinds");
			if (!keybind.hasState(_state))
			{
				continue;
			}

			if (!keybind.callOnKeyState(_keyState))
			{
				continue;
			}

			::MSU.Mod.Debug.printWarning("Calling keybind", "keybinds");
			if (keybind.call(_environment) == false)
			{
            	::MSU.Mod.Debug.printWarning("Returning after keybind call returned false.", "keybinds");
				return false;
			}
		}
	}

	function addKeybindDivider( _modID, _id, _name )
	{
		::MSU.System.ModSettings.get(_modID).getPage("Keybinds").add(::MSU.Class.SettingsDivider(_id, _name));
	}

	function addKeybindSetting( _keybind )
	{
		::MSU.System.ModSettings.get(_keybind.getModID()).getPage("Keybinds").add(_keybind.makeSetting());
	}

	function getJSKeybinds()
	{
		// ret = [
		// 	{
		// 		id = "modID",
		// 		keybinds = [
		// 			{
		// 				id = "keybindID",
		// 				keyCombinations = "x/y+z",
		// 				keyState = ::MSU.Key.Keystate.Release
		// 			}
		// 		]
		// 	}
		// ]
		local ret = []
		foreach (modID, mod in this.KeybindsForJS)
		{
			foreach (keybindID, keybind in mod)
			{
				ret.push(keybind.getUIData());
			}
		}
		return ret;
	}

	function onKeyInput( _key, _environment, _state )
	{
		local keyAsString = _key.getKey().tostring();
		if (!(keyAsString in ::MSU.Key.KeyMapSQ))
		{
			::MSU.Mod.Debug.printWarning("Unknown key pressed: %s" + _key.getKey(), "keybinds");
			return;
		}
		keyAsString = ::MSU.Key.KeyMapSQ[keyAsString];
		local keyState;
		if (this.isKeyStateContinuous(_key))
		{
			keyState = ::MSU.Key.KeyState.Continuous;
		}
		else
		{
			keyState = ::MSU.Key.getKeyState(_key.getState())
		}
		return this.onInput(_key, _environment, _state, keyAsString, keyState);
	}

	function onMouseInput( _mouse, _environment, _state )
	{
		local keyAsString = _mouse.getID().tostring();
		if (!(keyAsString in ::MSU.Key.MouseMapSQ))
		{
			::MSU.Mod.Debug.printWarning("Unknown key pressed: %s" + _mouse.getID(), "keybinds");
			return;
		}
		keyAsString = ::MSU.Key.MouseMapSQ[keyAsString];
		return this.onInput(_mouse, _environment, _state, keyAsString, _mouse.getState());
	}

	// Private
	function onInput( _key, _environment, _state, _keyAsString, _keyState )
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
		return this.call(key, _environment, _state, _keyState);
	}

	function isKeyStateContinuous( _key )
	{
		// Assumes key is in KeyMapSQ
		local key = ::MSU.Key.KeyMapSQ[_key.getKey().tostring()];
		::MSU.Log.printData(this.PressedKeys)

		if (_key.getState() == 1)
		{
			this.logInfo("keystate 1" + _key.getKey());
			if (key in this.PressedKeys)
			{
				this.logInfo("should be continuous");
				return true;
			}
			this.PressedKeys[key] <- 1;
		}
		else
		{
			if (key in this.PressedKeys) // in case the keypress started while tabbed out for example
			{
				delete this.PressedKeys[key];
			}
		}
		return false;
	}
}
