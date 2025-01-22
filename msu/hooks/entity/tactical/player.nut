::MSU.MH.hook("scripts/entity/tactical/player", function(q) {
	q.m.LevelUpsSpent <- 0;

	// VANILLAFIX: http://battlebrothersgame.com/forums/topic/oncombatstarted-is-not-called-for-ai-characters/
	// This fix is spread out over 4 files: tactical_entity_manager, actor, player, standard_bearer
	q.onCombatStart = @() function()
	{
		this.m.MaxEnemiesThisTurn = 1;
		this.m.CombatStats.DamageReceivedHitpoints = 0;
		this.m.CombatStats.DamageReceivedArmor = 0;
		this.m.CombatStats.DamageDealtHitpoints = 0;
		this.m.CombatStats.DamageDealtArmor = 0;
		this.m.CombatStats.Kills = 0;
		this.m.CombatStats.XPGained = 0;
		this.human.onCombatStart();
		this.getAIAgent().getProperties().BehaviorMult[::Const.AI.Behavior.ID.Retreat] = 0.0;
	}

	q.getMovementSpeedMult <- function()
	{
		return 1.0;
	}

	q.setAttributeLevelUpValues = @(__original) function( _v )
	{
		__original(_v);
		this.m.LevelUpsSpent++;
	}

	q.onHired = @(__original) function()
	{
		__original();
		this.getSkills().onHired();

		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			if (bro.getID() != this.getID())
			{
				bro.getSkills().onOtherPlayerHired(this);
			}
		}

	}

	q.onSerialize = @(__original) function( _out )
	{
		this.getFlags().set("LevelUpsSpent", this.m.LevelUpsSpent);
		__original(_out);
		this.getFlags().remove("LevelUpsSpent");
	}

	q.onDeserialize = @(__original) function( _in )
	{
		__original(_in);
		this.m.LevelUpsSpent = this.getFlags().has("LevelUpsSpent") ? this.getFlags().get("LevelUpsSpent") : 0;
	}
});
