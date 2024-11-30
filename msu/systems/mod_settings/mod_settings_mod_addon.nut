::MSU.Class.ModSettingsModAddon <- class extends ::MSU.Class.SystemModAddon
{
	function getPanel()
	{
		return ::MSU.System.ModSettings.getPanel(this.Mod.getID());
	}

	function getPage( _pageID )
	{
		return this.getPanel().getPage(_pageID);
	}

	function addPage( _pageID, _pageName = null )
	{
		local page = ::MSU.Class.SettingsPage(_pageID, _pageName);
		this.getPanel().addPage(page);
		return page;
	}

	function getSetting( _settingID )
	{
		return ::MSU.System.ModSettings.getPanel(this.Mod.getID()).getSetting(_settingID);
	}

	function getAllElementsAsArray( _filter = null )
	{
		return this.getPanel().getAllElementsAsArray(_filter);
	}

	function resetSettings()
	{
		return this.getPanel().resetSettings();
	}

	function hasSetting( _settingID )
	{
		return ::MSU.System.ModSettings.getPanel(this.Mod.getID()).hasSetting(_settingID);
	}	

	function addLock( _setting, _lockID, _lockReason )
	{
		if (typeof _setting == "string") _setting = this.getSetting(_setting);

		_lockID = this.getMod().getID() + "." + _lockID;
		_setting.addLock(_lockID, _lockReason);
	}

	function removeLock( _setting, _lockID )
	{
		if (typeof _setting == "string") _setting = this.getSetting(_setting);

		_lockID = this.getMod().getID() + "." + _lockID;
		_setting.removeLock(_lockID);
	}
}
