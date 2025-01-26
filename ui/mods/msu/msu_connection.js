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
	var transformText = function(_text)
	{
		// Change line ending to <br>, replace # markdown with <h> tags, replace markdown links with clickable spans
		var asLines = _text.split(/\r?\n/);
		var ret = "";
		for (var i = 0; i < asLines.length; i++) {
			var line = asLines[i].trim();
			var hashCount = 0;
			for (var j = 0; j < line.length; j++) {
				if (line[j] == "#") hashCount++
				else break
			}
			if (hashCount > 0) line = "<h" + hashCount + ">" + line.slice(hashCount) + "</h" + hashCount + ">";
			else line += "<br>";
			line = line.replace(/\[(.+)\]\((.+)\)/g, '<span class="msu-popup-link" onclick="openURL(\'$2\')">$1</span>'); // replace link with onClick element to open in browser
			ret += line;
		}
		return ret;
	}

	var self = this;
	var numUpdates = 0;
	var hasNew = false;
	var numMods = Object.keys(_modVersionData).length
	var objectsToAdd = [];
	$.each(_modVersionData, function (_modID, _modInfo)
	{
		if (_modInfo.UpdateInfo === undefined)
			return;
		numUpdates++;
		var updateInfo = _modInfo.UpdateInfo;
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

		// Add update patch notes, with a click handler to show/hide them
		if (updateInfo.changes)
		{
			var neatText = transformText(updateInfo.changes);
			var patchNotesInfoRow = $('<div class="description-font-normal font-color-description">Click to hide patch notes</div>')
				.appendTo(modInfoContainer);
			var descriptionRow = $('<div class="msu-mod-info-description description-font-normal font-color-description"/>')
				.html(neatText)
				.appendTo(modInfoContainer);
			modInfoContainer.click(function(){
				if (descriptionRow.html() == ""){
					patchNotesInfoRow.text("Click to hide patch notes");
					descriptionRow.html(neatText);
				}
				else {
					patchNotesInfoRow.text("Click to show patch notes");
					descriptionRow.html("");
				}
			})
		}
		// New patches up top, old patches bottom
		if (updateInfo.isNew)
		{
			var isNewSymbol = $('<div class="msu-popup-is-new-symbol"/>')
				.appendTo(modInfoContainer);
			objectsToAdd.push(modInfoContainer);
			hasNew = true;
		}
		else
		{
			objectsToAdd.splice(0, 0, modInfoContainer);
		}
	});

	if (numUpdates == 0)
		return;

	$.each(objectsToAdd, function(_, _modInfoContainer){
		MSU.Popup.addListContent(_modInfoContainer)
	})
	delete objectsToAdd;

	var checkText = "" + numMods + (numMods == 1 ? " mod" : " mods") + " checked<br>";
	checkText += numUpdates + (numUpdates == 1 ? " update" : " updates");
	MSU.Popup.setSmallContainerInfo(checkText);
	MSU.Popup.setState(hasNew ? MSU.Popup.mState.Full : MSU.Popup.mState.Small);
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
