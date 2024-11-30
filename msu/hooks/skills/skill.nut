::MSU.MH.hookTree("scripts/skills/skill", function(q) {
	if (!q.contains("create"))
		return;

	q.create = @(__original) function()
	{
		if (this.m.DamageType == null)
		{
			this.m.DamageType = ::MSU.Class.DamageType();
			this.m.DamageType.setSkill(this);
		}

		__original();

		this.m.DamageType.doInit();
	}
});

::MSU.MH.hook("scripts/skills/skill", function(q) {
	q.m.AIBehaviorID <- null;
	q.m.DamageType <- null;
	q.m.ItemActionOrder <- ::Const.ItemActionOrder.Any;

	q.m.IsBaseValuesSaved <- false;
	q.m.ScheduledChanges <- [];

	q.m.IsApplyingPreview <- false;
	q.m.PreviewField <- {};

	q.isType = @() function( _t, _any = true, _only = false )
	{
		if (_any)
		{
			return _only ? this.m.Type - (this.m.Type & _t) == 0 : (this.m.Type & _t) != 0;
		}
		else
		{
			return _only ? (this.m.Type & _t) == this.m.Type : (this.m.Type & _t) == _t;
		}
	}

	q.addType <- function ( _t )
	{
		this.m.Type = this.m.Type | _t;
	}

	q.setType <- function( _t )
	{
		this.m.Type = _t;
	}

	q.removeType <- function( _t )
	{
		if (this.isType(_t, false)) this.m.Type -= _t;
		else throw ::MSU.Exception.KeyNotFound(_t);
	}

	q.scheduleChange <- function( _field, _change, _set = false )
	{
		this.m.ScheduledChanges.push({Field = _field, Change = _change, Set = _set});
		if (this.getContainer().m.ScheduledChangesSkills.find(this) == null)
			this.getContainer().m.ScheduledChangesSkills.push(this);
	}

	q.executeScheduledChanges <- function()
	{
		if (this.m.ScheduledChanges.len() == 0)
		{
			return;
		}

		foreach (c in this.m.ScheduledChanges)
		{
			switch (typeof c.Change)
			{
				case "integer":
				case "string":
					if (c.Set) this.m[c.Field] = c.Change;
					else this.m[c.Field] += c.Change;
					break;

				default:
					this.m[c.Field] = c.Change;
					break;
			}
		}

		this.m.ScheduledChanges.clear();
	}

	q.saveBaseValues <- function()
	{
		if (!this.m.IsBaseValuesSaved)
		{
			this.b <- clone this.skill.m;
			local obj = this;
			local tables = [];
			while (obj.ClassName != "skill")
			{
				tables.push(clone obj.m);
				obj = obj[obj.SuperName];
			}

			// Iterate in reverse so that the values of slots with the same name in a parent
			// are always taken from the bottom most child.
			for (local i = tables.len() - 1; i >= 0; i--)
			{
				foreach (key, value in tables[i])
				{
					this.b[key] <- value;
				}
			}

			this.m.IsBaseValuesSaved = true;
		}
	}

	q.getBaseValue <- function( _field )
	{
		return this.b[_field];
	}

	q.setBaseValue <- function( _field, _value )
	{
		if (this.m.IsBaseValuesSaved) this.b[_field] = _value;
	}

	q.softReset <- function()
	{
		if (!this.m.IsBaseValuesSaved)
		{
			::logWarning("MSU Mod softReset() skill \"" + this.getID() + "\" does not have base values saved.");
			::MSU.Log.printStackTrace();
			return false;
		}

		foreach (fieldName in ::MSU.Skills.SoftResetFields)
		{
			this.m[fieldName] = this.b[fieldName]
		}

		return true;
	}

	q.hardReset <- function( _exclude = null )
	{
		if (!this.m.IsBaseValuesSaved)
		{
			::logWarning("MSU Mod hardReset() skill \"" + this.getID() + "\" does not have base values saved.");
			::MSU.Log.printStackTrace();
			return false;
		}

		if (_exclude == null) _exclude = [];
		::MSU.requireArray(_exclude);

		local toExclude = ["IsNew", "Order", "Type"];
		toExclude.extend(_exclude);

		foreach (k, v in this.b)
		{
			if (toExclude.find(k) == null) this.m[k] = v;
		}

		return true;
	}

	q.resetField <- function( _field )
	{
		if (!this.m.IsBaseValuesSaved)
		{
			::logWarning("MSU Mod resetField(\"" + _field + "\") skill \"" + this.getID() + "\" does not have base values saved.");
			::MSU.Log.printStackTrace();
			return false;
		}

		this.m[_field] = this.b[_field];

		return true;
	}

	// TODO: Should probably switch to a hookTree on `onAdded` in VeryLateBucket
	q.setContainer = @(__original) function( _c )
	{
		if (_c == null)
		{
			if (this.m.AIBehaviorID != null && !::MSU.isNull(this.getContainer()))
			{
				local agent = this.getContainer().getActor().getAIAgent();
				local activeBehavior = agent.m.ActiveBehavior;
				if (activeBehavior != null && activeBehavior.getID() == this.m.AIBehaviorID) agent.m.MSU_BehaviorToRemove = activeBehavior;
				else agent.removeBehaviorByStack(this.m.AIBehaviorID);
			}

			return __original(_c);
		}

		this.saveBaseValues();
		__original(_c);

		if (this.m.AIBehaviorID != null && !::MSU.isNull(this.getContainer().getActor()))
		{
			local agent = this.getContainer().getActor().getAIAgent();
			if (!::MSU.isNull(agent) && agent.getID() != ::Const.AI.Agent.ID.Player)
			{
				agent.addBehavior(::new(::MSU.AI.getBehaviorScriptFromID(this.m.AIBehaviorID)));
				agent.finalizeBehaviors();
			}
		}
	}

	q.onMovementStarted <- function( _tile, _numTiles )
	{
	}

	q.onMovementFinished <- function( _tile )
	{
	}

	q.onMovementStep <- function( _tile, _levelDifference )
	{
		return true;
	}

	q.onAfterDamageReceived <- function()
	{
	}

	q.onAnySkillExecuted <- function( _skill, _targetTile, _targetEntity, _forFree )
	{
	}

	q.onBeforeAnySkillExecuted <- function( _skill, _targetTile, _targetEntity, _forFree )
	{
	}

	q.onUpdateLevel <- function()
	{
	}

	q.getItemActionCost <- function( _items )
	{
	}

	q.getItemActionOrder <- function()
	{
		return this.m.ItemActionOrder;
	}

	q.onPayForItemAction <- function( _skill, _items )
	{
	}

	q.onNewMorning <- function()
	{
	}

	q.onGetHitFactors <- function( _skill, _targetTile, _tooltip )
	{
	}

	q.onGetHitFactorsAsTarget <- function( _skill, _targetTile, _tooltip )
	{
	}

	q.onQueryTileTooltip <- function( _tile, _tooltip )
	{
	}

	q.onQueryTooltip <- function( _skill, _tooltip )
	{
	}

	q.onDeathWithInfo <- function( _killer, _skill, _deathTile, _corpseTile, _fatalityType )
	{
	}

	q.onOtherActorDeath <- function( _killer, _victim, _skill, _deathTile, _corpseTile, _fatalityType )
	{			
	}

	q.onEnterSettlement <- function( _settlement )
	{		
	}

	q.onEquip <- function( _item )
	{
	}

	q.onUnequip <- function( _item )
	{
	}

	q.onAffordablePreview <- function( _skill, _movementTile )
	{
	}

	q.modifyPreviewField <- function( _skill, _field, _newChange, _multiplicative )
	{
		::MSU.Skills.modifyPreview(this, _skill, _field, _newChange, _multiplicative);
	}

	q.modifyPreviewProperty <- function( _skill, _field, _newChange, _multiplicative )
	{
		::MSU.Skills.modifyPreview(this, null, _field, _newChange, _multiplicative);
	}

	q.use = @(__original) function( _targetTile, _forFree = false )
	{
		// Save the container as a local variable because some skills delete
		// themselves during use (e.g. Reload Bolt) causing this.m.Container
		// to point to null.
		local container = this.m.Container;
		local targetEntity = _targetTile.IsOccupiedByActor ? _targetTile.getEntity() : null;

		container.onBeforeAnySkillExecuted(this, _targetTile, targetEntity, _forFree);

		local ret = __original(_targetTile, _forFree);

		container.onAnySkillExecuted(this, _targetTile, targetEntity, _forFree);

		return ret;
	}

	q.getDamageType <- function()
	{
		return this.m.DamageType;
	}

	q.getWeightedRandomDamageType <- function()
	{
		return this.m.DamageType == null ? null : this.m.DamageType.roll();
	}

	q.verifyTargetAndRange <- function( _targetTile, _origin = null )
	{
		if (_origin == null)
		{
			_origin = this.getContainer().getActor().getTile();	
		}
		
		return this.onVerifyTarget(_origin, _targetTile) && this.isInRange(_targetTile, _origin);
	}

	q.getDescription = @(__original) function()
	{
		if (this.m.DamageType.len() == 0 || (this.m.DamageType.len() == 1 && this.m.DamageType.contains(::Const.Damage.DamageType.None)) || !::MSU.Mod.ModSettings.getSetting("ExpandedSkillTooltips").getValue())
		{
			return __original();
		}

		local ret = "[color=" + ::Const.UI.Color.NegativeValue + "]Inflicts ";

		foreach (d in this.m.DamageType.toArray())
		{
			local probability = ::Math.round(this.m.DamageType.getProbability(d) * 100);

			if (probability < 100)
			{
				ret += probability + "% ";
			}

			ret += ::Const.Damage.getDamageTypeName(d) + ", ";
		}

		ret = ret.slice(0, -2);

		ret += " Damage [/color]\n\n" + __original();

		return ret;
	}

	q.getHitFactors = @(__original) function( _targetTile )
	{
		local ret = __original(_targetTile);
		if (::MSU.Mod.ModSettings.getSetting("ExpandedSkillTooltips").getValue() && ::MSU.isIn("AdditionalAccuracy", this.m, true) && this.m.AdditionalAccuracy != 0)
		{
			local payload = {
				icon = this.m.AdditionalAccuracy > 0 ? "ui/tooltips/positive.png" : "ui/tooltips/negative.png",
				text = this.getName()
			};

			if (this.m.AdditionalAccuracy > 0) ret.insert(0, payload);
			else ret.push(payload);
		}
		this.getContainer().onGetHitFactors(this, _targetTile, ret);
		return ret;
	}

	q.getRangedTooltip <- function( _tooltip = null )
	{
		if (_tooltip == null) _tooltip = [];
		
		local rangeBonus = ", more";
		if (this.m.MaxRangeBonus == 0)
		{
			rangeBonus = " or"
		}
		else if (this.m.MaxRangeBonus < 0)
		{
			rangeBonus = ", less"
		}

		_tooltip.push({
			id = 6,
			type = "text",
			icon = "ui/icons/vision.png",
			text = "Has a range of [color=" + ::Const.UI.Color.PositiveValue + "]" + this.getMaxRange() + "[/color] tiles on even ground" + rangeBonus + " if shooting downhill"
		});

		local accuText = "";
		if (this.m.AdditionalAccuracy != 0)
		{
			local color = this.m.AdditionalAccuracy > 0 ? ::Const.UI.Color.PositiveValue : ::Const.UI.Color.NegativeValue;
			local sign = this.m.AdditionalAccuracy > 0 ? "+" : "";
			accuText = "Has [color=" + color + "]" + sign + this.m.AdditionalAccuracy + "%[/color] chance to hit";
		}

		if (this.m.AdditionalHitChance != 0)
		{
			accuText += this.m.AdditionalAccuracy == 0 ? "Has" : ", and";
			local additionalHitChance = this.m.AdditionalHitChance + this.getContainer().getActor().getCurrentProperties().HitChanceAdditionalWithEachTile;
			local sign = additionalHitChance > 0 ? "+" : "";
			accuText += " [color=" + (additionalHitChance > 0 ? ::Const.UI.Color.PositiveValue : ::Const.UI.Color.NegativeValue) + "]" + sign + additionalHitChance + "%[/color]";
			accuText += this.m.AdditionalAccuracy == 0 ? " chance to hit " : "";
			accuText += " per tile of distance";
		}

		if (accuText.len() != 0)
		{
			_tooltip.push({
				id = 7,
				type = "text",
				icon = "ui/icons/hitchance.png",
				text = accuText
			});
		}

		return _tooltip;
	}
});

::MSU.QueueBucket.VeryLate.push(function() {
	::MSU.MH.hook("scripts/skills/skill", function(q) {
		foreach (func in ::MSU.Skills.PreviewApplicableFunctions)
		{
			q[func] = @(__original) function()
			{
				if (!this.m.IsApplyingPreview) return __original();

				local temp = {};
				foreach (field, change in this.m.PreviewField)
				{
					temp[field] <- this.m[field];
					if (change.Multiplicative)
					{
						this.m[field] *= change.Change;
					}
					else if (typeof change.Change == "bool")
					{
						this.m[field] = change.Change;
					}
					else
					{
						this.m[field] += change.Change;
					}
				}

				local properties = this.getContainer().getActor().getCurrentProperties();
				foreach (field, change in this.getContainer().m.PreviewProperty)
				{
					temp[field] <- properties[field];
					if (change.Multiplicative)
					{
						properties[field] *= change.Change;
					}
					else if (typeof change.Change == "bool")
					{
						properties[field] = change.Change;
					}
					else
					{
						properties[field] += change.Change;
					}
				}

				local ret = __original();

				if (temp.len() > 0)
				{
					foreach (field, change in this.m.PreviewField)
					{
						this.m[field] = temp[field];
					}

					foreach (field, change in this.getContainer().m.PreviewProperty)
					{
						properties[field] = temp[field];
					}
				}

				return ret;
			}
		}

		q.isAffordablePreview = @(__original) function()
		{
			if (!this.getContainer().m.IsPreviewing) return __original();
			this.m.IsApplyingPreview = true;
			local ret = __original();
			this.m.IsApplyingPreview = false;
			return ret;
		}

		q.getCostString = @(__original) function()
		{
			if (!this.getContainer().m.IsPreviewing) return __original();
			local preview = ::Tactical.TurnSequenceBar.m.ActiveEntityCostsPreview;
			if (preview != null && preview.id == this.getContainer().getActor().getID())
			{
				this.m.IsApplyingPreview = true;
				local ret = __original();
				this.m.IsApplyingPreview = false;
				local skillID = this.getContainer().getActor().getPreviewSkillID();
				local str = " after " + (skillID == "" ? "moving" : "using " + this.getContainer().getSkillByID(skillID).getName());
				ret = ::MSU.String.replace(ret, "Fatigue[/color]", "Fatigue[/color]" + str);
				return ret;
			}

			return __original();
		}
	});
});
