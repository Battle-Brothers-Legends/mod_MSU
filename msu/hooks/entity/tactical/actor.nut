::MSU.MH.hook("scripts/entity/tactical/actor", function(q) {
	q.onMovementStart = @(__original) function ( _tile, _numTiles )
	{
		__original(_tile, _numTiles);
		this.m.IsMoving = true;
		this.m.Skills.onMovementStarted(_tile, _numTiles);
		this.m.IsMoving = false;
	}

	q.onMovementFinish = @(__original) function ( _tile )
	{
		__original(_tile);
		this.m.IsMoving = true;
		this.m.Skills.onMovementFinished(_tile);
		this.m.IsMoving = false;
	}

	q.onMovementStep = @(__original) function( _tile, _levelDifference )
	{
		return onMovementStep(_tile, _levelDifference) && this.m.Skills.onMovementStep(_tile, _levelDifference);
	}

	// VANILLAFIX: http://battlebrothersgame.com/forums/topic/oncombatstarted-is-not-called-for-ai-characters/
	// This fix is spread out over 4 files: tactical_entity_manager, actor, player, standard_bearer
	q.onCombatStart <- function()
	{
		this.m.Skills.onCombatStarted();
		this.m.Items.onCombatStarted();
		this.m.Skills.update();
	}

	// Vanilla only has setMaxMoraleState. We add the getter.
	q.getMaxMoraleState <- function()
	{
		return this.m.MaxMoraleState;
	}

	q.getMainhandItem <- function()
	{
		return this.getItems().getItemAtSlot(::Const.ItemSlot.Mainhand);
	}

	q.getOffhandItem <- function()
	{
		return this.getItems().getItemAtSlot(::Const.ItemSlot.Offhand);
	}

	q.getHeadItem <- function()
	{
		return this.getItems().getItemAtSlot(::Const.ItemSlot.Head);
	}

	q.getBodyItem <- function()
	{
		return this.getItems().getItemAtSlot(::Const.ItemSlot.Body);
	}

	q.isArmedWithOneHandedWeapon <- function()
	{
		local item = this.getMainhandItem();
		return item != null && item.isItemType(::Const.Items.ItemType.OneHanded);
	}

	q.isArmedWithTwoHandedWeapon <- function()
	{
		local item = this.getMainhandItem();
		return item != null && item.isItemType(::Const.Items.ItemType.TwoHanded);
	}

	q.getRemainingArmorFraction <- function( _bodyPart = null )
	{
		local totalArmorMax = 0;
		local currentArmor = 0;

		if (_bodyPart == null)
		{
			totalArmorMax = this.getArmorMax(::Const.BodyPart.Head) + this.getArmorMax(::Const.BodyPart.Body);
			currentArmor = this.getArmor(::Const.BodyPart.Head) + this.getArmor(::Const.BodyPart.Body);
		}
		else
		{
			totalArmorMax = this.getArmorMax(_bodyPart);
			currentArmor = this.getArmor(_bodyPart);
		}

		return totalArmorMax > 0 ? currentArmor / (totalArmorMax * 1.0) : 0.0;
	}

	q.isEngagedInMelee <- function()
	{
		return this.isPlacedOnMap() && this.getTile().hasZoneOfControlOtherThan(this.getAlliedFactions());
	}

	q.isDoubleGrippingWeapon <- function()
	{
		local s = this.getSkills().getSkillByID("special.double_grip");

		return s != null && !s.isHidden();
	}

	q.isDisarmed <- function()
	{
		return this.getSkills().hasSkill("effects.disarmed");
	}

	q.addExcludedInjuries <- function(_injuries)
	{
		foreach (injury in _injuries)
		{
			if (this.m.ExcludedInjuries.find(injury) == null)
			{
				this.m.ExcludedInjuries.push(injury);
			}
		}
	}
});

::MSU.QueueBucket.VeryLate.push(function() {
	::MSU.MH.hookTree("scripts/entity/tactical/actor", function(q) {
		q.onDeath = @(__original) function( _killer, _skill, _tile, _fatalityType )
		{
			local deathTile = this.isPlacedOnMap() ? this.getTile() : null;
			this.m.Skills.onDeathWithInfo(_killer, _skill, deathTile, _tile, _fatalityType);

			__original(_killer, _skill, _tile, _fatalityType);

			if (!::Tactical.State.isFleeing() && deathTile != null)
			{
				foreach (faction in ::Tactical.Entities.getAllInstances())
				{
					foreach (actor in faction)
					{
						if (actor.getID() != this.getID())
						{
							actor.getSkills().onOtherActorDeath(_killer, this, _skill, deathTile, _tile, _fatalityType);
						}
					}
				}
			}
		}
	});
});
