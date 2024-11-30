local getDefaultFaction = ::Const.EntityType.getDefaultFaction;
::Const.EntityType.getDefaultFaction = function( _id )
{
	local ret = getDefaultFaction(_id);
	if (ret == ::Const.FactionType.Generic && (_id in ::MSU.Entities.EntityTypeToDefaultFactionMap))
	{
		return ::MSU.Entities.EntityTypeToDefaultFactionMap[_id];
	}

	return ret;
}
