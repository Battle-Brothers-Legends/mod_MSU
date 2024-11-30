::MSU.MH.hook("scripts/entity/tactical/tactical_entity_manager", function(q) {
	// VANILLAFIX: http://battlebrothersgame.com/forums/topic/oncombatstarted-is-not-called-for-ai-characters/
	// This fix is spread out over 4 files: tactical_entity_manager, actor, player, standard_bearer
	q.spawn = @(__original) function( _properties )
	{
		local ret = __original(_properties);

		::World.Assets.getOrigin().onCombatStarted();

		foreach (i, faction in this.getAllInstances())
		{
			if (i != ::Const.Faction.Player)
			{
				foreach (actor in faction)
				{
					actor.onCombatStart();
				}
			}
		}

		::Math.seedRandom(::Time.getRealTime());

		return ret;
	}
	
	q.getActorsByFunction <- function( _function )
	{
		local ret = [];
		foreach (faction in this.getAllInstances())
		{
			foreach (actor in faction)
			{
				if (_function(actor)) ret.push(actor);
			}
		}
		return ret;
	}

	q.getActorsWithinRange <- function( _tile, _max = 1, _min = 1 )
	{
		if (_tile.ID == 0)
		{
			::logError("The ID of _tile is 0 which means that the actor this tile was fetched from is not placed on map.");
			throw ::MSU.Exception.InvalidValue(_tile);
		}

		if (_max < _min)
		{
			::logError("_max must be equal to or greater than _min");
			throw ::MSU.Exception.InvalidValue(_max);
		}

		if (_max == 1)
		{
			local ret = this.getAdjacentActors(_tile);
			if (_min == 0 && _tile.IsOccupiedByActor)
				ret.push(_tile.getEntity());
			return ret;
		}

		return this.getActorsByFunction(function(_actor) {
			if (!_actor.isPlacedOnMap())
				return false;
			local distance = _tile.getDistanceTo(_actor.getTile());
			return distance <= _max && distance >= _min;
		});
	}

	q.getAdjacentActors <- function( _tile )
	{
		if (_tile.ID == 0)
		{
			::logError("The ID of _tile is 0 which means that the actor this tile was fetched from is not placed on map.");
			throw ::MSU.Exception.InvalidValue(_tile);
		}

		local ret = [];
		for (local i = 0; i < 6; i++)
		{
			if (!_tile.hasNextTile(i))
				continue;

			local nextTile = _tile.getNextTile(i);
			if (nextTile.IsOccupiedByActor)
				ret.push(nextTile.getEntity());
		}
		return ret;
	}
	
	q.getAlliedActors <- function( _faction, _tile = null, _distance = null, _atDistance = false )
	{
		if (_tile != null)
		{
			if (_tile.ID == 0)
			{
				::logError("The ID of _tile is 0 which means that the actor this tile was fetched from is not placed on map.");
				throw ::MSU.Exception.InvalidValue(_tile);
			}
			if (_distance == 1)
			{
				return this.getActorsWithinRange(_tile, 1, _atDistance ? 1 : 0).filter(@(_, _a) _a.isAlliedWith(_faction));
			}
		}

		return this.getActorsByFunction(function(_actor) {
			if (!_actor.isAlliedWith(_faction)) return false;
			if (_tile != null)
			{
				if (!_actor.isPlacedOnMap()) return false;
				local distance = _tile.getDistanceTo(_actor.getTile());
				if (distance > _distance || (_atDistance && distance != _distance)) return false;
			}
			return true;
		});
	}
	
	q.getHostileActors <- function( _faction, _tile = null, _distance = null, _atDistance = false )
	{
		if (_tile != null)
		{
			if (_tile.ID == 0)
			{
				::logError("The ID of _tile is 0 which means that the actor this tile was fetched from is not placed on map.");
				throw ::MSU.Exception.InvalidValue(_tile);
			}
			if (_distance == 1)
			{
				return this.getActorsWithinRange(_tile, 1, _atDistance ? 1 : 0).filter(@(_, _a) !_a.isAlliedWith(_faction));
			}
		}

		return this.getActorsByFunction(function(_actor) {
			if (_actor.isAlliedWith(_faction)) return false;
			if (_tile != null)
			{
				if (!_actor.isPlacedOnMap()) return false;
				local distance = _tile.getDistanceTo(_actor.getTile());
				if (distance > _distance || (_atDistance && distance != _distance)) return false;
			}
			return true;
		});
	}
	
	q.getFactionActors <- function( _faction, _tile = null, _distance = null, _atDistance = false )
	{
		if (_tile == null)
		{
			return clone this.getInstancesOfFaction(_faction);
		}
		else
		{
			if (_tile.ID == 0)
			{
				::logError("The ID of _tile is 0 which means that the actor this tile was fetched from is not placed on map.");
				throw ::MSU.Exception.InvalidValue(_tile);
			}
			if (_distance == 1)
			{
				return this.getActorsWithinRange(_tile, 1, _atDistance ? 1 : 0).filter(@(_, _a) _a.getFaction() == _faction);
			}
		}
				
		local actors = this.getInstancesOfFaction(_faction);
		local ret = [];
		foreach (actor in actors)
		{
			if (!actor.isPlacedOnMap()) continue;
			local distance = _tile.getDistanceTo(actor.getTile());
			if (distance > _distance || (_atDistance && distance != _distance)) continue;
			ret.push(actor);			
		}
		return ret;
	}
	
	q.getNonFactionAlliedActors <- function( _faction, _tile = null, _distance = null, _atDistance = false )
	{
		if (_tile != null)
		{
			if (_tile.ID == 0)
			{
				::logError("The ID of _tile is 0 which means that the actor this tile was fetched from is not placed on map.");
				throw ::MSU.Exception.InvalidValue(_tile);
			}
			if (_distance == 1)
			{
				return this.getActorsWithinRange(_tile, 1, _atDistance ? 1 : 0).filter(@(_, _a) _a.getFaction() != _faction && _a.isAlliedWith(_faction));
			}
		}

		return this.getActorsByFunction(function(_actor) {
			if (!_actor.isAlliedWith(_faction) || _actor.getFaction() == _faction) return false;
			if (_tile != null)
			{
				if (!_actor.isPlacedOnMap()) return false;
				local distance = _tile.getDistanceTo(_actor.getTile());
				if (distance > _distance || (_atDistance && distance != _distance)) return false;
			}
			return true;
		});
	}
});
