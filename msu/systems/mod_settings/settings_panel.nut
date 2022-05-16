::MSU.Class.SettingsPanel <- class
{
	Pages = null;
	ID = null;
	Name = null;
	Mod = null;
	Order = 1;

	constructor( _id, _name = null )
	{
		this.ID = _id;
		this.Name = _name == null ? _id : _name;
		this.Pages = ::MSU.Class.OrderedMap();
	}

	function getPages()
	{
		return this.Pages;
	}

	function addPage( _page )
	{
		if (!(_page instanceof ::MSU.Class.SettingsPage))
		{
			throw ::MSU.Exception.InvalidType(_page);
		}
		_page.setPanel(this);
		local hasKeybinds = this.Pages.contains("Keybinds")
		this.Pages[_page.getID()] <- _page;
		if (hasKeybinds)
		{
			this.Pages.sort(function(_id1, _page1, _id2, _page2)
			{
				if (_id1 == "Keybinds")
				{
					return 1;
				}
				if (_id2 == "Keybinds")
				{
					return -1;
				}
				return 0;
			});
		}
	}

	function getSetting( _settingID )
	{
		foreach (page in this.Pages)
		{
			if (page.getSettings().contains(_settingID))
			{
				return page.get(_settingID);
			}
		}

		throw ::MSU.Exception.KeyNotFound(_settingID);
	}

	function hasSetting( _settingID )
	{
		foreach (page in this.Pages)
		{
			if (page.getSettings().contains(_settingID))
			{
				return true;
			}
		}

		return false;
	}

	function hasPage( _pageID )
	{
		return this.getPages().contains(_pageID);
	}

	function getPage( _pageID )
	{
		return this.Pages[_pageID];
	}

	function getPages()
	{
		return this.Pages;
	}

	function verifyFlags( _flags )
	{
		foreach (page in this.Pages)
		{
			if (page.verifyFlags(_flags))
			{
				return true;
			}
		}
		return false;
	}

	function getName()
	{
		return this.Name;
	}

	function getID()
	{
		return this.ID;
	}

	function setMod( _mod )
	{
		this.Mod = _mod.weakref();
	}

	function getMod()
	{
		return this.Mod;
	}

	function getModID()
	{
		return this.Mod.getID();
	}

	function callSettingsFunction( _function, ... )
	{
		vargv.insert(0, null);
		foreach (page in this.Pages)
		{
			foreach (setting in page.getSettings())
			{
				if (setting instanceof ::MSU.Class.AbstractSetting)
				{
					vargv[0] = setting;
					setting[_function].acall(vargv);
				}
			}
		}
	}

	function flagSerialize()
	{
		this.callSettingsFunction("flagSerialize");
	}

	function flagDeserialize()
	{
		this.callSettingsFunction("flagDeserialize");
	}

	function resetFlags()
	{
		this.callSettingsFunction("resetFlags");
	}

	function getUIData( _flags = [] )
	{
		local ret = {
			id = this.getID(),
			name = this.getName(),
			pages = [],
			hidden = !this.verifyFlags(_flags),
			order = this.Order
		}

		foreach (pageID, page in this.Pages)
		{
			ret.pages.push(page.getUIData(_flags));
		}

		return ret;
	}
}
