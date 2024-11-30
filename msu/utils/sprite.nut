::MSU.Sprite <- {
	SpriteOrder = {},

	function addSprite( _object, _sprite, _orderInfo, _native )
	{
		foreach (sprite in _orderInfo[_sprite].InFrontOf)
		{
			if (!_object.hasSprite(sprite))
				_object.addSprite(sprite);
		}

		// If the object already has the sprite that `addSprite` is trying to add then we fetch that
		// instead of adding it again. Necessary with this system because if someone changes order
		// of vanilla sprites, then this function may add those sprites to the entity
		// before a manual vanilla `addSprite` call to add that sprite.
		local ret = _object.hasSprite(_sprite) ? _object.getSprite(_sprite) : _native(_sprite);

		foreach (sprite in _orderInfo[_sprite].Behind)
		{
			if (!_object.hasSprite(sprite))
				_object.addSprite(sprite);
		}

		return ret;
	}

	function setOrder( _script, _sprite, _behind = null, _inFrontOf = null )
	{
		// Ensure that both _behind and _inFrontOf are not null at the same time.
		// And when not null, they are arrays.
		if (_behind != null) ::MSU.requireArray(_behind);
		else ::MSU.requireArray(_inFrontOf);
		if (_inFrontOf != null) ::MSU.requireArray(_inFrontOf);
		else ::MSU.requireArray(_behind);

		if (!(_script in this.SpriteOrder))
		{
			this.SpriteOrder[_script] <- {};
		}

		if (!(_sprite in this.SpriteOrder[_script]))
		{
			this.SpriteOrder[_script][_sprite] <- {
				Behind = [],
				InFrontOf = []
			};
		}

		if (_behind != null)
		{
			foreach (sprite in _behind)
			{
				if (this.__isInFrontOf(_script, _sprite, sprite))
				{
					::logWarning(format("Trying to set sprite order of \'%s\' to be behind \'%s\' but another mod has already set it to be in front", _sprite, sprite));
					continue;
				}
				if (this.SpriteOrder[_script][_sprite].Behind.find(sprite) == null)
					this.SpriteOrder[_script][_sprite].Behind.push(sprite);
			}
		}
		if (_inFrontOf != null)
		{
			foreach (sprite in _inFrontOf)
			{
				if (this.__isBehind(_script, _sprite, sprite))
				{
					::logWarning(format("Trying to set sprite order of \'%s\' to be in front of \'%s\' but another mod has already set it to be behind", _sprite, sprite));
					continue;
				}
				if (this.SpriteOrder[_script][_sprite].InFrontOf.find(sprite) == null)
					this.SpriteOrder[_script][_sprite].InFrontOf.push(sprite);
			}
		}
	}

	function __isInFrontOf( _script, _sprite1, _sprite2 )
	{
		local spriteOrder = this.SpriteOrder[_script];
		if ((_sprite1 in spriteOrder) && spriteOrder[_sprite1].InFrontOf.find(_sprite2) != null)
			return true;
		if ((_sprite2 in spriteOrder) && spriteOrder[_sprite2].Behind.find(_sprite1) != null)
			return true;

		return false;
	}

	function __isBehind( _script, _sprite1, _sprite2 )
	{
		local spriteOrder = this.SpriteOrder[_script];
		if ((_sprite1 in spriteOrder) && spriteOrder[_sprite1].Behind.find(_sprite2) != null)
			return true;
		if ((_sprite2 in spriteOrder) && spriteOrder[_sprite2].InFrontOf.find(_sprite1) != null)
			return true;

		return false;
	}
}

::MSU.QueueBucket.VeryLate.push(function() {
	foreach (script, spriteOrder in ::MSU.Sprite.SpriteOrder)
	{
		local orderInfo = spriteOrder;
		::MSU.HooksMod.hook(script, function(q) {
			q.addSprite = @(__native) function( _sprite )
			{
				if (_sprite in orderInfo)
					return ::MSU.Sprite.addSprite(this, _sprite, orderInfo, __native);
				return __native(_sprite);
			}
		});
	}
	delete ::MSU.Sprite.SpriteOrder;
});
