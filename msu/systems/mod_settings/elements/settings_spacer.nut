::MSU.Class.SettingsSpacer <- class extends ::MSU.Class.SettingsElement
{
	static Type = "Spacer";
	constructor(_id, _width, _height)
	{
		base.constructor(_id);
		this.Data.Width <- _width;
		this.Data.Height <- _height;
	}
}
