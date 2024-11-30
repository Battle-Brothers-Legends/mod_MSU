::MSU.Class.KwargsFunction <- class
{
	__Function = null;
	__DefaultArgs = null;
	__KwargsArgIdx = null;

	constructor( _defaultArgs, _function )
	{
		this.set(_function);
		this.__DefaultArgs = _defaultArgs;
	}

	function _call( ... )
	{
		vargv[this.__KwargsArgIdx] = this.__getKwargs(vargv[this.__KwargsArgIdx]);
		return this.__Function.acall(vargv);
	}

	function _typeof()
	{
		return typeof this.__Function;
	}

	function _tostring()
	{
		return this.__Function.tostring();
	}

	function _get( _key )
	{
		if (_key == "weakref") throw null;
		return this.__Function[_key];
	}

	function _cloned( _original )
	{
		throw "cloning a function";
	}

	function bindenv( _env )
	{
		local ret = ::MSU.Class.KwargsFunction(this.__DefaultArgs, this.__Function.bindenv(_env));
		ret.__KwargsArgIdx = this.__KwargsArgIdx;
		return ret;
	}

	function get()
	{
		return this.__Function;
	}

	function set( _function )
	{
		::MSU.requireFunction(_function);
		local info = _function.getinfos();
		this.__KwargsArgIdx = info.parameters.find("_kwargs");
		if (this.__KwargsArgIdx == null || info.defparams[this.__KwargsArgIdx - info.parameters.len() + info.defparams.len()] != null)
		{
			throw "The kwargs function must have an argument named \'_kwargs\' that defaults to null";
		}

		this.__Function = _function;
	}

	function addArg( _name, _value )
	{
		if (_name in this.__DefaultArgs) throw ::MSU.Exception.DuplicateKey(_name);
		::MSU.requireString(_name);

		this.__DefaultArgs[_name] <- _value;
	}

	function addArgs( _table )
	{
		foreach (key, value in _table)
		{
			this.addArg(key, value);
		}
	}

	function __getKwargs( _kwargs = null )
	{
		if (_kwargs == null) _kwargs = {};
		foreach (key, value in _kwargs)
		{
			if (!(key in this.__DefaultArgs))
			{
				::logError(key + " is not a valid keyword argument for this function. If you are trying to add a new argument, you must first use addArg/addArgs to add your argument(s)");
				throw ::MSU.Exception.KeyNotFound(key);
			}
		}

		_kwargs.setdelegate(clone this.__DefaultArgs);
		return _kwargs;
	}
}
