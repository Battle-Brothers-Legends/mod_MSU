::MSU.MH.hook("scripts/skills/skill_container", function(q) {
	q.m.ScheduledChangesSkills <- [];
	q.m.IsPreviewing <- false;
	q.m.PreviewProperty <- {};

	q.update = @(__original) function()
	{
		if (this.m.IsUpdating || !this.m.Actor.isAlive())
		{
			return;
		}

		foreach (skill in this.m.Skills)
		{
			if (!skill.isGarbage()) skill.softReset();
		}

		__original();

		foreach (skill in this.m.ScheduledChangesSkills)
		{
			if (!skill.isGarbage()) skill.executeScheduledChanges();
		}

		this.m.ScheduledChangesSkills.clear();
	}

	q.callSkillsFunction <- function( _function, _argsArray = null, _update = true, _aliveOnly = false )
	{
		if (_argsArray == null) _argsArray = [null];
		else _argsArray.insert(0, null);

		local wasUpdating = this.m.IsUpdating;
		this.m.IsUpdating = true;
		this.m.IsBusy = false;
		this.m.BusyStack = 0;

		foreach (skill in this.m.Skills)
		{
			if (_aliveOnly && !this.m.Actor.isAlive())
			{
				break;
			}

			if (!skill.isGarbage())
			{
				_argsArray[0] = skill;
				skill[_function].acall(_argsArray);
			}
		}

		this.m.IsUpdating = wasUpdating;
		
		if (_update)
		{
			this.update();
		}
	}

	q.callSkillsFunctionWhenAlive <- function( _function, _argsArray = null, _update = true )
	{
		this.callSkillsFunction(_function, _argsArray, _update, true);
	}

	q.buildProperties <- function( _function, _argsArray )
	{
		_argsArray.insert(0, null);
		_argsArray.push(this.m.Actor.getCurrentProperties().getClone());

		local wasUpdating = this.m.IsUpdating;
		this.m.IsUpdating = true;

		foreach (skill in this.m.Skills)
		{
			_argsArray[0] = skill;
			skill[_function].acall(_argsArray);
		}
		this.m.IsUpdating = wasUpdating;
		return _argsArray[_argsArray.len() - 1];
	}

	q.onMovementStarted <- function( _tile, _numTiles )
	{
		this.callSkillsFunction("onMovementStarted", [
			_tile,
			_numTiles
		]);
	}

	q.onMovementFinished <- function( _tile )
	{
		this.callSkillsFunctionWhenAlive("onMovementFinished", [
			_tile
		]);
	}

	q.onMovementStep <- function( _tile, _levelDifference )
	{
		this.callSkillsFunction("onMovementStep", [
			_tile,
			_levelDifference
		], false);
	}

	q.onAnySkillExecuted <- function( _skill, _targetTile, _targetEntity, _forFree )
	{
		// Don't update if using a skill that sets Tile to ID 0 e.g. Rotation because this leads
		// to crashes if any skill tries to access the current tile in its onUpdate
		// function as the tile at this point is not a valid tile.

		this.callSkillsFunctionWhenAlive("onAnySkillExecuted", [
			_skill,
			_targetTile,
			_targetEntity,
			_forFree
		], this.getActor().isPlacedOnMap());
	}

	q.onBeforeAnySkillExecuted <- function( _skill, _targetTile, _targetEntity, _forFree )
	{
		this.callSkillsFunction("onBeforeAnySkillExecuted", [
			_skill,
			_targetTile,
			_targetEntity,
			_forFree
		]);
	}
	
	q.onUpdateLevel <- function()
	{
		this.callSkillsFunction("onUpdateLevel");
	}

	q.onNewMorning <- function()
	{
		this.callSkillsFunctionWhenAlive("onNewMorning");
	}

	q.onGetHitFactors <- function( _skill, _targetTile, _tooltip )
	{
		this.callSkillsFunction("onGetHitFactors", [
			_skill,
			_targetTile,
			_tooltip
		], false);

		local targetEntity = _targetTile.getEntity();
		if (targetEntity != null && targetEntity.getID() != this.getActor().getID())
		{
			targetEntity.getSkills().onGetHitFactorsAsTarget(_skill, _targetTile, _tooltip);
		}
	}

	q.onGetHitFactorsAsTarget <- function( _skill, _targetTile, _tooltip )
	{
		this.callSkillsFunction("onGetHitFactorsAsTarget", [
			_skill,
			_targetTile,
			_tooltip
		], false);
	}

	q.onQueryTileTooltip <- function( _tile, _tooltip )
	{
		this.callSkillsFunction("onQueryTileTooltip", [
			_tile,
			_tooltip
		], false);
	}

	q.onQueryTooltip <- function( _skill, _tooltip )
	{
		this.callSkillsFunction("onQueryTooltip", [
			_skill,
			_tooltip
		], false);
	}

	q.onDeathWithInfo <- function( _killer, _skill, _deathTile, _corpseTile, _fatalityType )
	{
		this.callSkillsFunction("onDeathWithInfo", [
			_killer,
			_skill,
			_deathTile,
			_corpseTile,
			_fatalityType
		], false);
	}

	q.onOtherActorDeath <- function( _killer, _victim, _skill, _deathTile, _corpseTile, _fatalityType )
	{
		this.callSkillsFunctionWhenAlive("onOtherActorDeath", [
			_killer,
			_victim,
			_skill,
			_deathTile,
			_corpseTile,
			_fatalityType
		]);
	}

	q.onEnterSettlement <- function( _settlement )
	{
		this.callSkillsFunction("onEnterSettlement", [
			_settlement
		]);
	}

	q.onEquip <- function( _item )
	{
		this.callSkillsFunction("onEquip", [
			_item
		]);
	}

	q.onUnequip <- function( _item )
	{
		this.callSkillsFunction("onUnequip", [
			_item
		]);
	}

	q.onAffordablePreview <- function( _skill, _movementTile )
	{
		this.m.PreviewProperty.clear();
		foreach (skill in this.m.Skills)
		{
			skill.m.PreviewField.clear();
		}

		this.callSkillsFunction("onAffordablePreview", [
			_skill,
			_movementTile,
		], false);

		if (::MSU.Skills.QueuedPreviewChanges.len() == 0) return;

		local propertiesClone = this.getActor().getBaseProperties().getClone();

		local getChange = function( _function )
		{
			local skills = _function == "executeScheduledChanges" ? this.m.ScheduledChangesSkills : this.m.Skills;
			foreach (skill in skills)
			{
				if (!skill.isGarbage())
				{
					foreach (caller, changes in ::MSU.Skills.QueuedPreviewChanges)
					{
						if (caller == skill)
						{
							foreach (change in changes)
							{
								local target = change.TargetSkill != null ? change.TargetSkill.m : propertiesClone;
								change.ValueBefore = target[change.Field];
							}
						}
					}

					if (_function == "executeScheduledChanges") skill[_function]();
					else skill[_function](propertiesClone);

					foreach (caller, changes in ::MSU.Skills.QueuedPreviewChanges)
					{
						if (caller == skill)
						{
							foreach (change in changes)
							{
								if (typeof change.NewChange == "bool") continue;

								local target = change.TargetSkill != null ? change.TargetSkill.m : propertiesClone;
								if (target[change.Field] == change.ValueBefore) continue;

								if (change.Multiplicative) change.CurrChange *= target[change.Field] / change.ValueBefore;
								else change.CurrChange += target[change.Field] - change.ValueBefore;
							}
						}
					}
				}
			}
		}

		foreach (skill in this.m.Skills)
		{
			skill.softReset();
		}

		getChange("onUpdate");
		getChange("onAfterUpdate");
		getChange("executeScheduledChanges");

		foreach (changes in ::MSU.Skills.QueuedPreviewChanges)
		{
			foreach (change in changes)
			{
				local target;
				local previewTable;
				if (change.TargetSkill != null)
				{
					target = change.TargetSkill.m;
					previewTable = change.TargetSkill.m.PreviewField;
				}
				else
				{
					target = this.getActor().getCurrentProperties();
					previewTable = this.m.PreviewProperty;
				}

				if (!(change.Field in previewTable)) previewTable[change.Field] <- { Change = change.Multiplicative ? 1 : 0, Multiplicative = change.Multiplicative };

				if (change.Multiplicative)
				{
					previewTable[change.Field].Change *= change.NewChange / (change.CurrChange == 0 ? 1 : change.CurrChange);
				}
				else if (typeof change.NewChange == "bool")
				{
					previewTable[change.Field].Change = change.NewChange;
				}
				else
				{
					previewTable[change.Field].Change += change.NewChange - change.CurrChange;
				}
			}
		}

		::MSU.Skills.QueuedPreviewChanges.clear();
	}

	//Vanilla Overwrites start
	
	q.onAfterDamageReceived = @() function()
	{
		this.callSkillsFunctionWhenAlive("onAfterDamageReceived");
	}

	q.buildPropertiesForUse = @() function( _caller, _targetEntity )
	{
		_caller.resetField("HitChanceBonus");
		if (::MSU.isIn("AdditionalAccuracy", _caller.m, true)) _caller.resetField("AdditionalAccuracy");
		if (::MSU.isIn("AdditionalHitChance", _caller.m, true)) _caller.resetField("AdditionalHitChance");

		return this.buildProperties("onAnySkillUsed", [
			_caller,
			_targetEntity
		]);
	}

	q.buildPropertiesForDefense = @() function( _attacker, _skill )
	{
		return this.buildProperties("onBeingAttacked", [
			_attacker,
			_skill
		]);
	}

	q.buildPropertiesForBeingHit = @() function( _attacker, _skill, _hitinfo )
	{
		return this.buildProperties("onBeforeDamageReceived", [
			_attacker,
			_skill,
			_hitinfo
		]);
	}

	q.onBeforeActivation = @() function()
	{
		this.callSkillsFunctionWhenAlive("onBeforeActivation");
	}

	q.onTurnStart = @() function()
	{
		this.callSkillsFunctionWhenAlive("onTurnStart");
	}

	q.onResumeTurn = @() function()
	{
		this.callSkillsFunctionWhenAlive("onResumeTurn");
	}

	q.onRoundEnd = @() function()
	{
		this.callSkillsFunctionWhenAlive("onRoundEnd");
	}

	q.onTurnEnd = @() function()
	{
		this.m.IsPreviewing = false;
		this.callSkillsFunctionWhenAlive("onTurnEnd");
	}

	q.onWaitTurn = @() function()
	{
		this.m.IsPreviewing = false;
		this.callSkillsFunctionWhenAlive("onWaitTurn");
	}

	q.onNewRound = @() function()
	{
		this.callSkillsFunction("onNewRound");
	}

	q.onNewDay = @() function()
	{
		this.callSkillsFunctionWhenAlive("onNewDay");
	}

	q.onDamageReceived = @() function( _attacker, _damageHitpoints, _damageArmor )
	{
		this.callSkillsFunction("onDamageReceived", [
			_attacker,
			_damageHitpoints,
			_damageArmor
		]);
	}

	q.onBeforeTargetHit = @() function( _caller, _targetEntity, _hitInfo )
	{
		if (_caller.isAttack() && _caller.getDamageType() != null)
		{
			_hitInfo.DamageType = _caller.getDamageType().roll();

			// Can also pull the Damage Weight of that Damage Type in this skill and do cool things with
			// that e.g. make some perks which only work if the used skill has 60% or more Blunt damage
			// and here we can pull the Damage Weight of the Damage Type that was rolled and use it!

			_hitInfo.DamageTypeProbability = _caller.getDamageType().getProbability(_hitInfo.DamageType);

			if (::MSU.isIn(_targetEntity.m, "IsHeadless", true) && _targetEntity.m.IsHeadless)
			{
				_hitInfo.BodyPart = ::Const.BodyPart.Body;
			}

			local injuries = ::Const.Damage.getApplicableInjuries(_hitInfo.DamageType, _hitInfo.BodyPart, _targetEntity);

			if (injuries.len() > 0)
			{
				_hitInfo.Injuries = injuries;
			}
		}

		this.callSkillsFunction("onBeforeTargetHit", [
			_caller,
			_targetEntity,
			_hitInfo
		]);
	}

	q.onTargetHit = @() function( _caller, _targetEntity, _bodyPart, _damageInflictedHitpoints, _damageInflictedArmor )
	{
		this.callSkillsFunction("onTargetHit", [
			_caller,
			_targetEntity,
			_bodyPart,
			_damageInflictedHitpoints,
			_damageInflictedArmor
		]);
	}

	q.onTargetMissed = @() function( _caller, _targetEntity )
	{
		this.callSkillsFunction("onTargetMissed", [
			_caller,
			_targetEntity
		]);
	}

	q.onTargetKilled = @() function( _targetEntity, _skill )
	{
		this.callSkillsFunction("onTargetKilled", [
			_targetEntity,
			_skill
		]);
	}

	q.onMissed = @() function( _attacker, _skill )
	{
		this.callSkillsFunction("onMissed", [
			_attacker,
			_skill
		]);
	}

	q.onCombatStarted = @() function()
	{
		this.callSkillsFunction("onCombatStarted");
	}

	q.onCombatFinished = @() function()
	{
		this.m.IsPreviewing = false;
		this.callSkillsFunction("onCombatFinished");
	}

	q.onDeath = @() function( _fatalityType )
	{
		this.callSkillsFunction("onDeath", [_fatalityType]);
	}

	q.onDismiss = @() function()
	{
		this.callSkillsFunction("onDismiss");
	}

	//Vanilla Ovewrites End
	
	q.getItemActionCost <- function( _items )
	{
		local info = [];
		foreach (skill in this.m.Skills)
		{
			local cost = skill.getItemActionCost(_items);
			if (cost != null)
			{
				info.push({Skill = skill, Cost = cost});
			}
		}

		return info;
	}

	q.onPayForItemAction <- function( _skill, _items )
	{
		this.callSkillsFunction("onPayForItemAction", [
			_skill,
			_items
		]);
	}

	q.getSkillsByFunction <- function( _function )
	{
		local ret = [];
		foreach (skill in this.m.Skills)
		{
			if (!skill.isGarbage() && _function(skill))
			{
				ret.push(skill);
			}
		}

		return ret;
	}
});
