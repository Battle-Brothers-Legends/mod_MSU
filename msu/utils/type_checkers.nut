::MSU.requireString <- function( ... )
{
	::MSU.requireTypeArray("string", vargv);
}

::MSU.requireInt <- function( ... )
{
	::MSU.requireTypeArray("integer", vargv);
}

::MSU.requireUInt <- function( ... )
{
	foreach (value in vargv)
	{
		if (typeof value != "integer" || value < 0)
		{
			::logError(value + " must have the type: unsigned");
			throw ::MSU.Exception.InvalidType(value);
		}
	}
}

::MSU.requireArray <- function( ... )
{
	::MSU.requireTypeArray("array", vargv);
}

::MSU.requireFloat <- function( ... )
{
	::MSU.requireTypeArray("float", vargv);
}

::MSU.requireBool <- function( ... )
{
	::MSU.requireTypeArray("bool", vargv);
}

::MSU.requireTable <- function( ... )
{
	::MSU.requireTypeArray("table", vargv);
}

::MSU.requireInstance <- function( ... )
{
	::MSU.requireTypeArray("instance", vargv);
}

::MSU.requireInstanceOf <- function( _class, ... )
{
	foreach (value in vargv)
	{
		if (!(value instanceof _class))
		{
			::logError(value + " must be an instance of the class: " + _class);
			throw ::MSU.Exception.InvalidType(value);
		}
	}
}

::MSU.requireFunction <- function( ... )
{
	::MSU.requireTypeArray("function", vargv);
}

::MSU.requireType <- function( _type, ... )
{
	::MSU.requireTypeArray(_type, vargv);
}

// Private
::MSU.requireTypeArray <- function( _type, _values )
{
	foreach (value in _values)
	{
		if (typeof value != _type)
		{
			::logError(value + " must have the type: " + _type);
			throw ::MSU.Exception.InvalidType(value);
		}
	}
}

::MSU.requireOneFromTypes <- function( _typeArray, ... )
{
	foreach (value in vargv)
	{
		if (_typeArray.find(typeof value) == null)
		{
			::logError(value + " must have one of the types: " + _typeArray.reduce(@(a, b) format("%s, %s", a, b)));
			throw ::MSU.Exception.InvalidType(value);
		}
	}
}

::MSU.requireAnyTypeExcept <- function( _typeArray, ... )
{
	foreach (value in vargv)
	{
		if (_typeArray.find(typeof value) != null)
		{
			::logError(value + " must NOT have one of the types: " + _typeArray.reduce(@(a, b) format("%s, %s", a, b)));
			throw ::MSU.Exception.InvalidType(value);
		}
	}
}
