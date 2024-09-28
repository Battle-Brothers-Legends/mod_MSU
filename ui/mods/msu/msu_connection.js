var MSUConnection = function ()
{
	MSUBackendConnection.call(this);
};

MSUConnection.prototype = Object.create(MSUBackendConnection.prototype);
Object.defineProperty(MSUConnection.prototype, 'constructor', {
	value: MSUConnection,
	enumerable: false,
	writable: true
});

MSUConnection.prototype.onQuerySettingsData = function (_data)
{
	MSU.Keybinds.setKeybinds(_data.keybinds);
	Screens.ModSettingsScreen.setSettings(_data.settings);
};

MSUConnection.prototype.removeKeybind = function (_keybind)
{
	MSU.Keybinds.removeKeybind(_keybind.modID, _keybind.id);
};

MSUConnection.prototype.addKeybind = function (_keybind)
{
	MSU.Keybinds.addKeybindFromSQ(_keybind.modID, _keybind.id, _keybind.keyCombinations);
};

MSUConnection.prototype.clearKeys = function ()
{
	MSU.Keybinds.PressedKeys = {};
}

MSUConnection.prototype.setInputDenied = function (_bool)
{
	SQ.call(this.mSQHandle, "setInputDenied", _bool);
}

MSUConnection.prototype.getUpdateCheckPromise = function (_updateURL)
{
	var ret = $.Deferred();
	var xhttp = new XMLHttpRequest();
	xhttp.onloadend = function()
	{
		if (this.status == 200)
		{
			ret.resolve(JSON.parse(this.responseText)); // will (probably) need adjustment if we add more update sources (other than github)
			return;
		}
		ret.resolve(null);
	}
	xhttp.ontimeout = function()
	{
		ret.resolve(null);
	}
	xhttp.open('GET', _updateURL);
	xhttp.send();
	return ret;
}

MSUConnection.prototype.checkForModUpdates = function (_modsWithUpdateData)
{
	var self = this;
	var modIDs = [];
	var promises = [];
	$.each(_modsWithUpdateData, function (_id, _version)
	{
		modIDs.push(_id);
		promises.push(self.getUpdateCheckPromise(_version));
	})
	$.when.apply($, promises).done(function()
	{
		var modVersionData = {};
		var args = arguments;
		modIDs.forEach(function(_modID, _i)
		{
			if (args[_i] != null)
			{
				modVersionData[_modID] = args[_i];
			}
		})
		self.compareModVersions(modVersionData)
	}).fail(function()
	{
		console.error("Something went wrong with MSU Update checks");
	});
}

MSUConnection.prototype.compareModVersions = function (_modVersionData)
{
	var self = this;
	SQ.call(self.mSQHandle, "compareModVersions", _modVersionData, function(_ret)
	{
		self.showModUpdates(_ret)
	});
}

MSUConnection.prototype.showModUpdates = function (_modVersionData)
{
	var self = this;
	var numUpdates = 0;
	var numNew = 0;
	var numMods = Object.keys(_modVersionData).length
	$.each(_modVersionData, function (_modID, _modInfo)
	{
		if (_modInfo.UpdateInfo === undefined)
			return;
		numUpdates++;
		var updateInfo = _modInfo.UpdateInfo;
		if (updateInfo.isNew) numNew++;
		var modInfoContainer = $('<div class="msu-mod-info-container"/>');
		var nameRow = $('<div class="msu-mod-name-row title title-font-big font-bold font-color-title">' + updateInfo.name + '</div>')
			.appendTo(modInfoContainer)

		var versionRow = $('<div class="msu-mod-version-row">')
			.appendTo(modInfoContainer)

		var colorFromIdx = 0;
		if (updateInfo.updateType != "MAJOR")
		{
			colorFromIdx = updateInfo.availableVersion.indexOf('.') + 1;
		}
		if (updateInfo.updateType == "PATCH")
		{
			colorFromIdx = updateInfo.availableVersion.indexOf('.', colorFromIdx + 1) + 1;
		}
		var start = updateInfo.availableVersion.slice(0, colorFromIdx);
		var coloredSpan = '<span style="color:red;">' + updateInfo.availableVersion.slice(colorFromIdx) + '</span>';
		versionRow.append($('<div class="msu-mod-version-info text-font-normal">' + updateInfo.currentVersion + ' => ' + start + coloredSpan + ' (Update Available)</div>'));

		$.each(updateInfo.sources, function (_, _source) {
			var container = $('<div class="l-source-button"/>').appendTo(versionRow);
			var button = container.createImageButton(Path.GFX + "mods/msu/logos/" + _source.icon + "-32.png", function ()
			{
				openURL(_source.URL);
			});
		})

		// Add update text
		if (updateInfo.changes)
		{
			var descriptionRow = $('<div class="msu-mod-info-description description-font-normal font-color-description"/>')
				.html(updateInfo.changes.replace(/(?:\r\n|\r|\n)/g, '<br>'))
				.appendTo(modInfoContainer)
		}
		MSU.Popup.addListContent(modInfoContainer)
	});
	if (numUpdates == 0)
		return;
	var checkText = "" + numMods + (numMods == 1 ? " mod" : " mods") + " checked<br>";
	checkText += numUpdates + (numUpdates == 1 ? " update" : " updates");
	MSU.Popup.setSmallContainerInfo(checkText);
	MSU.Popup.setState(numNew > 0 ? MSU.Popup.mState.Full : MSU.Popup.mState.Small);
}

// this should be reworked if/when we added JS side settings callbacks
MSUConnection.prototype.onVanillaBBCodeUpdated = function (_bool)
{
	var elements = document.getElementsByTagName('link');
	for (var i = 0; i < elements.length; i++)
	{
		if (elements[i].href.indexOf("ui/mods/msu/css/vanilla_font_unbold.css") != -1)
		{
			elements[i].disabled = _bool;
			break;
		}
	}
}

registerScreen("MSUConnection", new MSUConnection());
