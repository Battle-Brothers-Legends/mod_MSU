::MSU.Class.Regexp <- class
{
	__regexp = null;

	constructor( _expression )
	{
		::MSU.requireString(_expression);
		this.__regexp = regexp(_expression);
	}

	function _get( _key )
	{
		return this.__regexp[_key];
	}

	function captureAll( _string, _startIndex = 0 )
	{
		local captures = [];
		while (true)
		{
			local capture = this.capture(_string, _startIndex);
			if (capture == null) break;

			captures.push(capture);
			_startIndex	 = capture[0].end;
		}

		return captures.len() != 0 ? captures : null;
	}

	function getMatch( _string, _group = 0, _capture = null )
	{
		if (_capture == null) _capture = this.capture(_string);
		if (_capture[_group].end <= 0 || _capture[_group].begin > _string.len()) return null;

		return _string.slice(capture[_group].begin, capture[_group].end);
	}

	function getMatches( _string, _group = 0, _captures = null )
	{
		if (_captures == null) _captures = this.captureAll(_string);

		local matches = [];
		foreach (capture in _captures)
		{
			local match = this.getMatch(capture, _string, _group);
			if (match != null) matches.push(match);
		}

		return matches.len() != 0 ? matches : null;
	}
}
