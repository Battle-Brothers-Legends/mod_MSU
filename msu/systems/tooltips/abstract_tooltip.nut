::MSU.Class.Tooltip <- class
{
	Data = null;

	constructor( _data = null )
	{
		this.setData(_data);
	}

	function setData( _data )
	{
		if (_data == null) _data = {};
		::MSU.requireTable(_data);
		this.Data = _data;
	}

	function getUIData( _data )
	{
		return null;
	}
}
