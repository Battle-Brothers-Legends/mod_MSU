MSUKeybind = function( _modID, _id _keyCombinations )
{
	this.ModID = _modID;
	this.ID = _id;
	this.KeyCombinations = _keyCombinations;
}

MSUKeybind.prototype.getRawKeyCombinations = function()
{
	return this.KeyCombinations.split('/');
}
