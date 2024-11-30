::MSU.Class.Event <- class
{
	__Functions = null;

	constructor()
	{
		this.__Functions = [];
	}

	function register( _env, _function )
	{
		// ::MSU.requireFunction(_function);
		foreach (i, funcInfo in this.__Functions)
		{
			if (funcInfo[1] == _function)
			{
				return;
			}
		}

		this.__Functions.push([_env, _function]);
	}

	function unregister( _function )
	{
		// ::MSU.requireFunction(_function);
		foreach (i, funcInfo in this.__Functions)
		{
			if (funcInfo[1] == _function)
			{
				this.__Functions.remove[i];
				return;
			}
		}

		throw ::MSU.Exception.KeyNotFound(_function);
	}

	function invoke( _argsArray = null )
	{
		if (_argsArray == null) _argsArray = [null];
		else _argsArray.insert(0, null);

		foreach (funcInfo in this.__Functions)
		{
			_argsArray[0] = funcInfo[0];
			funcInfo[1].acall(_argsArray);
		}
	}

	// Will iterate over every registered function and check _conditionFunction
	// if _conditionFunction returns false, stops iteration immediately
	function conditionalInvoke( _conditionFunction, _argsArray = null )
	{
		if (_argsArray == null) _argsArray = [null];
		else _argsArray.insert(0, null);

		foreach (funcInfo in this.__Functions)
		{
			if (_conditionFunction() == false)
				return;

			_argsArray[0] = funcInfo[0];
			funcInfo[1].acall(_argsArray);
		}
	}

	function clear()
	{
		this.__Functions.clear();
	}
}
