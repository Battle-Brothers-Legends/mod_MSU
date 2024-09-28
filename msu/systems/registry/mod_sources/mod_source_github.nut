::MSU.Class.ModSourceGitHub <- class extends ::MSU.Class.ModSource
{
	static ModSourceDomain = ::MSU.Class.RegistrySystem.ModSourceDomain.GitHub;
	static Regex = regexp("https:\\/\\/github\\.com\\/([-\\w]+)\\/([-\\w]+)");
	static BadURLMessage = "A GitHub link must be a link to a specific repository, e.g. 'https://github.com/MSUTeam/MSU' Check to make sure there's not an issue with your URL and that it is formatted the same way as the MSU URL.";
	static Icon = "github";

	function setUpdateCheckURL()
	{
		local capture = this.Regex.capture(this.__BaseURL);
		this.__UpdateCheckURL = "https://api.github.com/repos/" + ::MSU.regexMatch(capture, this.__BaseURL, 1) + "/" + ::MSU.regexMatch(capture, this.__BaseURL, 2) + "/releases/latest";
	}

	function setTargetURL(_data)
	{
		this.__TargetURL = _data.html_url;
	}

	function extractRelease(_data)
	{
		this.setTargetURL(_data);
		return {Version = _data.tag_name, Changes = _data.body};
	}
}
