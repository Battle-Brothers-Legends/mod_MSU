::MSU.Class.KeybindsModAddon <- class extends ::MSU.Class.SystemModAddon
{
	function add( _keybind )
	{
		::MSU.System.Keybinds.add(_keybind);
	}

	function update( _id, _keyCombinations )
	{
		::MSU.System.Keybinds.update(this.getID(), _id, _keyCombinations);
	}

	function addSQKeybind( _id, _keyCombinations, _state, _function, _name = null, _keyState = null, _description = "" )
	{
		local keybind = ::MSU.Class.KeybindSQ(this.getID(), _id, _keyCombinations, _state, _function, _name, _keyState);
		keybind.setDescription(_description);
		::MSU.System.Keybinds.add(keybind);
	}

	function addJSKeybind( _id, _keyCombinations, _name = null, _keyState = null, _description = "" )
	{
		local keybind = ::MSU.Class.KeybindJS(this.getID(), _id, _keyCombinations, _name, _keyState);
		keybind.setDescription(_description);
		::MSU.System.Keybinds.add(keybind)
	}

	function addDivider( _id, _name )
	{
		::MSU.System.Keybinds.addKeybindDivider(this.getID(), _id, _name);
	}
}
