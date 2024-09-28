::MSU.Class.ModSource <- class
{
	static ModSourceDomain = null;
	static Regex = null;
	static BadURLMessage = "A link must be pointing to a specific mod.";
	static Icon = null;
	__BaseURL = null; //basic URL that is passed
	__UpdateCheckURL = null; // URL where we check for updates
	__TargetURL = null; // URL to the release/update source

	constructor( _baseURL, _opts = null )
	{
		if (this.Regex != null && !this.Regex.match(_baseURL))
		{
			::logError(this.BadURLMessage);
			throw ::MSU.Exception.InvalidValue(_baseURL);
		}
		this.__BaseURL = _baseURL;
		if (_opts != null) {
			foreach (key, value in _opts) this[key] = value;
		}
		this.setUpdateCheckURL();
	}

	function getBaseURL()
	{
		return this.__BaseURL;
	}

	function setUpdateCheckURL()
	{

	}

	function getUpdateCheckURL()
	{
		return this.__UpdateCheckURL;
	}

	function setTargetURL(_data)
	{

	}

	function getTargetURL()
	{
		return this.__TargetURL;
	}

	function extractRelease(_data) {
		return null;
	}
}
