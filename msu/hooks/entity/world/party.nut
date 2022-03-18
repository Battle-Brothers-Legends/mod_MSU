::mods_hookExactClass("entity/world/party", function(o) {
	o.m.RealBaseMovementSpeed <- o.m.BaseMovementSpeed;
	o.m.BaseMovementSpeedMult <- 1.0;
	o.m.MovementSpeedMult <- 1.0;
	o.m.MovementSpeedMultFunctions <- {};

	local create = o.create;
	o.create = function()
	{
		create();
		this.m.MovementSpeedMultFunctions["BaseMovementSpeedMult"] <- this.getBaseMovementSpeedMult;
		this.m.MovementSpeedMultFunctions["RoadMovementSpeedMult"] <- this.getRoadMovementSpeedMult;
		this.m.MovementSpeedMultFunctions["SlowdownPerUnitMovementSpeedMult"] <- this.getSlowdownPerUnitMovementSpeedMult;
		this.m.MovementSpeedMultFunctions["GlobalMovementSpeedMult"] <- this.getGlobalMovementSpeedMult;
		this.m.MovementSpeedMultFunctions["NightTimeMovementSpeedMult"] <- this.getNightTimeMovementSpeedMult;
		this.m.MovementSpeedMultFunctions["RiverMovementSpeedMult"] <- this.getRiverMovementSpeedMult;
		this.m.MovementSpeedMultFunctions["NotPlayerMovementSpeedMult"] <- this.getNotPlayerMovementSpeedMult;
	}

	o.setRealBaseMovementSpeed <- function( _speed )
	{
		this.m.RealBaseMovementSpeed = _speed;
	}

	o.getRealBaseMovementSpeed <- function()
	{
		return this.m.RealBaseMovementSpeed;
	}

	o.setBaseMovementSpeed <- function( _speed )
	{
		this.m.BaseMovementSpeed = _speed;
	}

	o.resetBaseMovementSpeed <- function()
	{
		this.setBaseMovementSpeed(this.getRealBaseMovementSpeed());
	}

	o.getBaseMovementSpeedMult <- function()
	{
		return this.m.BaseMovementSpeedMult;
	}

	o.setBaseMovementSpeedMult <- function( _mult )
	{
		this.m.BaseMovementSpeedMult = _mult;
	}

	o.getMovementSpeedMult <- function()
	{
		return this.m.MovementSpeedMult;
	}

	o.setMovementSpeed <- function( _speed )
	{
		this.setBaseMovementSpeedMult(_speed / 100.0);
	}

	o.setMovementSpeedMult <- function( _mult )
	{
		this.m.MovementSpeedMult = _mult;
	}

	o.getFinalMovementSpeedMult <- function()
	{
		local mult = 1.0;
		foreach (key, func in this.m.MovementSpeedMultFunctions)
		{
			local funcResult = func();
			::MSU.Mod.Debug.printLog("Function " + key + " returned a mult of: " + funcResult, "movement");
			mult *= funcResult;
		}
		return mult;
	}

	o.updateMovementSpeedMult <- function()
	{
		this.setMovementSpeedMult(this.getFinalMovementSpeedMult());
	}

	o.getMovementSpeed <- function( _update = false )
	{
		if (_update)
		{
			this.updateMovementSpeedMult();
		}
		local speed = this.getBaseMovementSpeed() * this.getMovementSpeedMult();
		return speed;
	}

	o.getTimeDelta <- function() 
	{
		local delta = this.Math.maxf(0.0, this.Time.getVirtualTimeF() - this.m.LastUpdateTime);
		return delta;
	}

	//------------- All movementspeed factors, extracted out of party onUpdate() ---------------------

	o.getSlowdownPerUnitMovementSpeedMult <- function()
	{
		return (1.0 - this.Math.minf(0.5, this.m.Troops.len() * ::Const.World.MovementSettings.SlowDownPartyPerTroop));
	}

	o.getGlobalMovementSpeedMult <- function()
	{
		return ::Const.World.MovementSettings.GlobalMult;
	}

	o.getRoadMovementSpeedMult <- function()
	{
		if (this.isIgnoringCollision())
		{
			return 1.0;
		}
		local myTile = this.getTile();
		if (myTile.HasRoad)
		{
			return this.Math.maxf(::Const.World.TerrainTypeSpeedMult[myTile.Type] * ::Const.World.MovementSettings.RoadMult, 1.0);
		}
		else
		{
			return ::Const.World.TerrainTypeSpeedMult[myTile.Type];
		}
	}

	o.getNightTimeMovementSpeedMult <- function()
	{
		if (!this.m.IsSlowerAtNight || ::World.isDaytime())
		{
			return 1.0;
		}
		return ::Const.World.MovementSettings.NighttimeMult;
	}

	o.getRiverMovementSpeedMult <- function()
	{
		if (!this.getTile().HasRiver)
		{
			return 1.0;
		}
		return ::Const.World.MovementSettings.RiverMult;
	}

	//could be baseMovementSpeedMult for all parties that player_party overrides anyways
	o.getNotPlayerMovementSpeedMult <- function()
	{
		if (this.getFaction() == ::Const.Faction.Player)
		{
			return 1.0;
		}
		return ::Const.World.MovementSettings.NotPlayerMult;
	}

	o.onUpdate = function()
	{
		this.world_entity.onUpdate();
		local delta = this.getTimeDelta();
		this.m.LastUpdateTime = this.Time.getVirtualTimeF();
		
		if (this.isInCombat())
		{
			this.setOrders("Fighting");
			return;
		}

		if (this.m.StunTime > this.Time.getVirtualTimeF())
		{
			return;
		}

		if (this.m.Controller != null)
		{
			this.m.Controller.think();
		}

		if (this.m.Flags.get("IsAlps"))
		{
			this.m.IsLeavingFootprints = false;

			if (::World.getTime().IsDaytime)
			{
				//use function instead of accessing m
				this.setVisibilityMult(0.0);
				this.getController().getBehavior(::Const.World.AI.Behavior.ID.Attack).setEnabled(false);
			}
			else
			{
				//use function instead of accessing m
				this.setVisibilityMult(1.0);
				this.getController().getBehavior(::Const.World.AI.Behavior.ID.Attack).setEnabled(true);
			}
		}

		if (this.m.Path != null)
		{
			if (this.m.Path.isAtWaypoint(this.getPos()))
			{
				this.m.Path.pop();

				if (this.m.Path.isEmpty())
				{
					this.m.Path = null;
					this.m.Destination = null;
				}
			}

			if (this.m.Path != null)
			{
				this.m.Destination = ::World.tileToWorld(this.m.Path.getCurrent());
			}
		}

		if (this.m.Destination != null)
		{
			if (this.m.IsMirrored)
			{
				if (this.getSprite("bodyUp").HasBrush)
				{
					if (this.m.Destination.Y < this.getPos().Y)
					{
						this.getSprite("bodyUp").Visible = false;
						this.getSprite("body").Visible = true;
					}
					else
					{
						this.getSprite("bodyUp").setHorizontalFlipping(this.m.Destination.X < this.getPos().X);
						this.getSprite("bodyUp").Visible = true;
						this.getSprite("body").Visible = false;
					}
				}

				this.getSprite("body").setHorizontalFlipping(this.m.Destination.X < this.getPos().X);
			}

			local myTile = this.getTile();
			local speed = this.getMovementSpeed(true) * delta;

			if (this.m.IsLeavingFootprints && !myTile.IsOccupied)
			{
				if (this.Time.getVirtualTimeF() - this.m.LastFootprintTime >= 1.0)
				{
					local scale;

					if (this.m.FootprintSizeOverride == 0.0)
					{
						scale = this.Math.minf(1.0, this.Math.maxf(0.4, this.m.Troops.len() * 0.05));
					}
					else
					{
						scale = this.m.FootprintSizeOverride;
					}

					::World.spawnFootprint(this.createVec(this.getPos().X - 5, this.getPos().Y - 15), this.m.Footprints[this.getDirection8To(this.m.Destination)] + "_0" + this.m.LastFootprintType, scale, this.m.FootprintSizeOverride != 0.0 ? 30.0 : 0.0, ::World.Assets.getFootprintVision(), this.m.FootprintType);
					this.m.LastFootprintTime = this.Time.getVirtualTimeF();
					this.m.LastFootprintType = this.m.LastFootprintType == 1 ? 2 : 1;
				}
			}

			if (!this.move(this.m.Destination, speed))
			{
				this.m.Destination = null;
			}
		}

		if (this.m.IdleSoundsIndex != 0 && this.m.LastIdleSound + 10.0 < this.Time.getRealTimeF() && this.Math.rand(1, 100) <= 5 && this.isVisibleToEntity(::World.State.getPlayer(), 500))
		{
			this.m.LastIdleSound = this.Time.getRealTimeF();
			::Sound.play(::Const.SoundPartyAmbience[this.m.IdleSoundsIndex][this.Math.rand(0, ::Const.SoundPartyAmbience[this.m.IdleSoundsIndex].len() - 1)], ::Const.Sound.Volume.Ambience, this.getPos());
		}
	}
	
	local onSerialize = o.onSerialize;
	o.onSerialize = function( _out )
	{
		this.getFlags().set("RealBaseMovementSpeed", this.getRealBaseMovementSpeed());
		this.getFlags().set("BaseMovementSpeedMult", this.getBaseMovementSpeedMult());
		onSerialize(_out);
	}

	local onDeserialize = o.onDeserialize;
	o.onDeserialize = function( _in )
	{
		onDeserialize(_in);
		if (this.getFlags().has("RealBaseMovementSpeed"))
		{
			this.setRealBaseMovementSpeed(this.getFlags().get("RealBaseMovementSpeed"));
		}
		if (this.getFlags().has("BaseMovementSpeedMult"))
		{
			this.setBaseMovementSpeedMult(this.getFlags().get("BaseMovementSpeedMult"));
		}
		this.resetBaseMovementSpeed();

	}
});
