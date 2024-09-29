var MSUPopup = function ()
{
	this.mSQHandle = null
	this.mContainer = null;
	this.mSmallContainer = null;
	this.mSmallContainerInfo = null;
	this.mID = "MSUPopup";

	this.mHeaderContainer = null;
	this.mContentContainer = null;
	this.mListScrollContainer = null;
	this.mFooterContainer = null;
	this.mOkButton = null;
	this.mTitle = null;
	this.mState = {
		None : 0,
		Small : 1,
		Full : 2
	}
	this.mCurrentState = this.mState.None;
}

MSUPopup.prototype.onConnection = function (_handle)
{
	this.register($('.root-screen'));
	this.mSQHandle = _handle;
}

MSUPopup.prototype.createDIV = function (_parentDiv)
{
	var self = this;
	this.mContainer = $('<div class="msu-popup ui-control dialog"/>');
	_parentDiv.append(this.mContainer);

	this.mHeaderContainer = $('<div class="header"/>');
	this.mContainer.append(this.mHeaderContainer);

	this.mTitle = $('<div class="title title-font-very-big font-bold font-bottom-shadow font-color-title">Info Popup</div>');
	this.mHeaderContainer.append(this.mTitle);

	this.mListContainer = this.mContainer.createList(1, 'content-container');
	this.mListScrollContainer = this.mListContainer.findListScrollContainer();
	this.mContainer.append(this.mContentContainer);


	this.mFooterContainer = $('<div class="footer"/>')
	this.mContainer.append(this.mFooterContainer);

	this.mOkButton = this.mFooterContainer.createTextButton("Ok", function()
	{
		self.setState(self.mState.Small);
	}, "ok-button", 1);
}

MSUPopup.prototype.createSmallDIV = function (_parentDiv)
{
	var self = this;
	this.mSmallContainer = $('<div class="msu-popup-small msu-popup-main-menu-screen"/>')
		.appendTo(_parentDiv)
		.mousedown(function(event) {
		    switch (event.which) {
		        case 1:
		            self.setState(self.mState.Full);
		            break;
		        case 3:
		            self.setState(self.mState.None);
		            break;
		    }
		})
	this.mSmallContainerButton = $('<div class="msu-popup-small-update-button"/>')
		.appendTo(this.mSmallContainer)
	this.mSmallContainerInfo = $('<div class="msu-popup-small-update-info font-color-description"/>')
		.appendTo(this.mSmallContainer);
}

MSUPopup.prototype.addMessage = function (_info)
{
	var container = $('<div class="msu-mod-info-container"/>');
	if (_info.modName)
	{
		container.append($('<div class="title-font-normal font-color-title">' + _info.modName + '</div>'))
	}
	container.append($('<div class="description-font-normal font-color-description">' + _info.text + '</div>'));
	this.addListContent(container);
}

MSUPopup.prototype.addListContent = function (_content)
{
	this.mListScrollContainer.prepend(_content);
}

MSUPopup.prototype.setTitle = function (_content)
{
	this.mTitle.text(_content);
}

MSUPopup.prototype.setSmallContainerInfo = function (_content)
{
	this.mSmallContainerInfo.html(_content)
}

MSUPopup.prototype.setForceQuit = function(_bool)
{
	var self = this;
	this.mOkButton.off("click");
	if (_bool)
	{
		this.mOkButton.findButtonText().html("Quit Game");
		this.mOkButton.on("click", function()
		{
			self.quitGame();
		})
	}
	else
	{
		this.mOkButton.findButtonText().html("Ok");
		this.mOkButton.on("click", function()
		{
			self.setState(self.mState.Small);
		})
	}
}

MSUPopup.prototype.create = function(_parentDiv)
{
	this.createDIV(_parentDiv);
	this.createSmallDIV(_parentDiv);
	this.mSmallContainer.hide();
};

MSUPopup.prototype.destroy = function ()
{
	this.destroyDIV();
	this.destroySmallDIV();
}

MSUPopup.prototype.destroySmallDIV = function ()
{
	this.mSmallContainer.empty();
	this.mSmallContainer.remove();
	this.mSmallContainer = null;
}

MSUPopup.prototype.fadeIn = function (_container)
{
	var self = this;
	if (_container.css("display") != "none")
		return;
	_container.css("opacity", 0);
	_container.velocity("finish", true).velocity({opacity: 1},
	{
		duration: Constants.SCREEN_SLIDE_IN_OUT_DELAY,
		easing: 'swing',
		begin: function ()
		{
			self.notifyBackendOnAnimating();
			$(this).show();
		},
		complete: function ()
		{
			if (_container == self.mContainer)
				self.notifyBackendOnShown();
		}
	});
}

MSUPopup.prototype.fadeOut = function (_container)
{
	var self = this;
	if (_container.css("display") == "none")
		return;
	_container.velocity("finish", true).velocity({opacity: 0},
	{
		duration: Constants.SCREEN_SLIDE_IN_OUT_DELAY,
		easing: 'swing',
		begin: function()
		{
			self.notifyBackendOnAnimating();
		},
		complete: function()
		{
			if (_container == self.mContainer)
				self.notifyBackendOnHidden();
			$(this).hide();
		}
	});
}

MSUPopup.prototype.setState = function (_state)
{
	if (!_state in this.mState)
	{
		console.error("Invalid State " + _state + " passed to MSU popup!");
		return;
	}
	if (this.mCurrentState == _state)
		return;
	this.mCurrentState = _state;
	if (this.mCurrentState == this.mState.None)
	{
		this.fadeOut(this.mContainer);
		this.fadeOut(this.mSmallContainer);
	}
	else if (this.mCurrentState == this.mState.Small)
	{
		this.fadeIn(this.mSmallContainer);
		this.fadeOut(this.mContainer);
	}
	else
	{
		this.fadeOut(this.mSmallContainer);
		this.fadeIn(this.mContainer);
	}
}

MSUPopup.prototype.hide = function ()
{
	if (this.mCurrentState == this.mState.Full)
		this.setState(this.mState.Small);
}

MSUPopup.prototype.clear = function ()
{
	this.mListScrollContainer.empty();
}

MSUPopup.prototype.isVisible = function ()
{
	return this.mContainer.css('display') == "block";
}

MSUPopup.prototype.register = function (_parentDiv)
{
	console.log('MSUPopup::REGISTER');
	this.create(_parentDiv);
}

MSUPopup.prototype.unregister = function ()
{
	console.log('MSUPopup::UNREGISTER');
	this.destroy();
}

MSUPopup.prototype.quitGame = function ()
{
	SQ.call(this.mSQHandle, "quitGame");
}

MSUPopup.prototype.notifyBackendOnShown = function ()
{
	if (this.mSQHandle !== null)
	{
		SQ.call(this.mSQHandle, 'onScreenShown');
	}
};

MSUPopup.prototype.notifyBackendOnHidden = function ()
{
	if (this.mSQHandle !== null)
	{
		SQ.call(this.mSQHandle, 'onScreenHidden');
	}
};

MSUPopup.prototype.notifyBackendOnAnimating = function ()
{
	if (this.mSQHandle !== null)
	{
		SQ.call(this.mSQHandle, 'onScreenAnimating');
	}
};

registerScreen("MSUPopup", new MSUPopup());
