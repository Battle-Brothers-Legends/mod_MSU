# Modding Standards & Utilities (MSU)
Documentation for v0.6.6

This documentation follows a **Traffic Light** system:
- Green 🟢 signifies stable features which are unlikely to undergo major save-breaking changes.
- Yellow 🟡 signifies beta features which may undergo save-breaking changes.
- Red 🔴 signifies experimental features which are under development and may undergo significant changes.

The traffic light assigned to a main heading also applies to all of its sub-headings unless the sub-heading has its own traffic light.

# Skills 🟢
MSU provides groundbreaking functionality for clean, optimized, and highly inter-mod compatible skill modding. This solves two major problems in vanilla Battle Brothers skills.

Firstly, in vanilla BB, skills are often tightly coupled, so if one skill wants to modify a parameter in another skill, the two are tightly coupled via a function. Secondly, in vanilla BB, many parameters of skills cannot be changed in increments e.g. `this.m.ActionPointCost`. If a skill changes its `this.m.ActionPointCost` via an increment e.g. `+= 1` during its `onUpdate` or `onAfterUpdate` function, then the value of the `ActionPointCost` will continue to increase indefinitely every time that function is called. 

Let's take a random attack skill, Thrust, as an example. Let's say we have a skill that modifies the AP cost of Thrust by -1. The way to do this in vanilla would be:
```
function onAfterUpdate( _properties )
{
	this.m.ActionPointCost = this.getContainer().hasSkill("ourSkill") ? 3 : 4.	
}
```
Such a value is very hard for modders to modify without changing the entire `onAfterUpdate` function. MSU's **Automated Resetting** feature allows overcoming both of these problems in an elegant way, allowing you to write clean code for example like this:
```
// in ourSkill
function onAfterUpdate( _properties )
{
	local thrust = this.getContainer().getSkillByID("actives.thrust");
	if (thrust != null)
	{
		thrust.m.ActionPointCost -= 1
	}
}
```
This method keeps things encapsulated. Thrust doesn't need to know anything about whether "ourSkill" exists or not. Furthermore, it allows modders to modify the parameters of Thrust without breaking compatibility.

## Automated Resetting
MSU provides several functions to reset the m table of a skill back to its base values:

- `softReset()`
- `hardReset()`
- `resetField( _field )`

MSU stores the base values of a skill immediately before its first onUpdate is called. This ensures that any changes made to the skill before or during adding to an actor are considered as the base state of the skill.

### `softReset()`
This function resets the following fields of the skill's `m` table:

- ActionPointCost
- FatigueCost
- FatigueCostMult
- MinRange
- MaxRange

`softReset()` is automatically called during the `update()` function of the `skill_container` before any skills' `onUpdate` or `onAfterUpdate` are called. It can also be manually called using `<skill>.softReset()`.

### `hardReset()`
This function is never automatically called, but can be manually called using `<skill>.hardReset()` to reset every value in the `m` table back to its original value.

### `resetField( _field )`
This function can be used to reset a particular field back to its base value e.g. `<skill>.resetField(“Description”)`.

### Use Cases
This system allows changing a value in a skill’s m table in increments rather than assigning it particular values, which opens up possibilities for flexible and compatible modding. For example, now you can do:
```
function onAfterUpdate( _properties )
{
	this.m.ActionPointCost -= 1
}
```
In the original game, doing this will cause the action point cost of the skill to continue to reduce indefinitely on every call to this function. However, with the MSU resetting system, this will ensure that the skill’s action point cost is only reduced by 1 compared to its base cost. Another mod can then hook the same function and add or subtract from the cost in further increments.

## Scheduled Changes
Skills in Battle Brothers are updated in the order of their SkillOrder. Imagine we have two skills:

- Skill A with `this.m.SkillOrder = this.Const.SkillOrder.First`
- Skill B with `this.m.SkillOrder = this.Const.SkillOrder.Any`

Whenever the skill_container runs its `update()` or `buildPropertiesForUse` (which calls the `onAnySkillUsed` function in skills) functions, the respective functions are called on the skills in the order of their `SkillOrder`. Hence, skill A will update before skill B in the above example.

If you want skill A to modify something in skill B after skill B’s update, you would have to change the order of skill A to be something later than that of skill B e.g. set skill A’s order to `this.Const.SkillOrder.Last`. Usually this is quite doable. However, there may be cases where you absolutely want skill A to be updated before skill B but still want skill A to be able to change something in skill B when skill B is updated. MSU allows you to do this via the `scheduleChange` function.

Multiple changes to the same skill can be scheduled by using the function multiple times. Scheduled changes are executed in the `onAfterUpdate` function of the target skill after its base `onAfterUpdate` function (i.e. the one defined in the skill’s own file) has run.

### Usage:
`<skill>.scheduleChange( _field, _change, _set = false )`

`_field` is the key in the `m` table for which you want to schedule a change. `_change` is the new value. `_set` is a Boolean which, if `true`, sets the value of `_field` to `_change` and if `false` and if `_field` points to an integer or string value, adds `_change` to the value of `_field`.

#### Example:
The following code is written in skill A and will reduce the action point cost of skill B by 1 even if skill A updates before skill B:
```
function onUpdate( _properties )
{
	skillB.scheduleChange(“ActionPointCost”, -1);
}
```

## Damage Type 🟡
MSU adds a robust and flexible `DamageType` system for skills. The purpose of this system is to allow skills to deal a variety of damage types and to streamline the injuries system. This system also eliminates the need to use `this.m.InjuriesOnBody` and `this.m.InjuriesOnHead` in skills. Only the `DamageType` needs to be defined.

Each skill now has a parameter called `this.m.DamageType` which can be set during the skill’s `create()` function. This parameter is an array which contains tables as its entries. Each table contains two keys: `Type` and `Weight`. For example:
```
this.m.DamageType = [
	{ Type = this.Const.Damage.DamageType.Cutting, Weight = 75 },
	{ Type = this.Const.Damage.DamageType.Piercing, Weight = 25 }
]
```
The above example will give this skill 75% Cutting damage and 25% Piercing damage.

When attacking a target, the skill pulls a weighted random `DamageType` from its `this.m.DamageType` array. The rolled damage type is then passed to the `_hitInfo` during `onBeforeTargetHit`. The type of injuries the skill can inflict is also determined at this point based on what type of damage it rolled, and which part of the body is going to be hit.

The skill’s rolled damage type’s Probability is also passed to `_hitInfo` calculated using the `<skill>.getDamageTypeProbability( _damageType )` function. This allows the target to access this information and receive different effects depending on how much weight of that `DamageType` the skill has.

MSU also adds the damage types of a skill to the skill’s tooltip automatically including their relative probabilities.

### Adding a new damage type
`this.Const.Damage.addNewDamageType( _damageType, _injuriesOnHead, _injuriesOnBody, _damageTypeName = "" )`

`_damageType` is a string which will become a key in the `this.Const.Damage.DamageType` table. `_injuriesOnHead` and `_injuriesOnBody` are arrays of strings where each entry is an ID of an injury skill. `_damageTypeName` is a string which can be used as the name of this damage type in tooltips; if not provided then `_damageType` is used as the name in tooltips.

### Getting a damage type's name
`this.Const.Damage.getDamageTypeName( _damageType )`

`_damageType` is a slot in the `this.Const.Damage.DamageType` table.

Returns the name of the damage type as string, or returns an empty string if `_damageType` does not exist.

###	Getting a list of injuries a damage type can inflict
`this.Const.Damage.getDamageTypeInjuries( _damageType )`

`_damageType` is a slot in the `this.Const.Damage.DamageType` table.

Returns a table `{ Head = [], Body = [] }` where Head and Body are arrays containing IDs of the injury skills this damage type can inflict on the respective body part.

### Setting the injuries an existing damage type can inflict
`this.Const.Damage.setDamageTypeInjuries( _damageType, _injuriesOnHead, _injuriesOnBody )`

`_damageType` is a string which will become a key in the `this.Const.Damage.DamageType` table. `_injuriesOnHead` and `_injuriesOnBody` are arrays of strings where each entry is an ID of an injury skill.

###	Getting a list of injuries applicable to a situation
`this.Const.Damage.getApplicableInjuries( _damageType, _bodyPart, _targetEntity = null )`

`_damageType` is a slot in the `this.Const.Damage.DamageType` table. `_bodyPart` is the body part hit. `_targetEntity` is the entity being attacked which, if not null, removes the ExcludedInjuries of the `_targetEntity` from the returned array.

Returns an array which contains IDs of the injury skills that this damage type can apply in the given situation.

### Checking if a skill has a damage type
`<skill>.hasDamageType( _damageType, _only = false )`

`_damageType` is a slot in the `this.Const.Damage.DamageType` table. If `_only` is true, then function only returns true if the skill has no other damage type.

Returns a `true` if the skill has the damage type and `false` if it doesn’t.

### Adding a damage type to a skill
`<skill>.addDamageType( _damageType, _weight )`

`_damageType` is a slot in the `this.Const.Damage.DamageType` table. `_weight` is an integer.

Adds the given damage type to the skill’s `this.m.DamageType` array with the provided weight.

###	Removing a damage type from a skill
`<skill>.removeDamageType( _damageType )`

`_damageType` is a slot in the `this.Const.Damage.DamageType` table.

Removes the given damage type from the skill if the skill has it.

### Getting the damage type of a skill
`<skill>.getDamageType()`

Returns the `this.m.DamageType` array of the skill.

### Getting the weight of a skill’s particular damage type
`<skill>.getDamageTypeWeight( _damageType )`

`_damageType` is a slot in the `this.Const.Damage.DamageType` table.

Returns an integer which is the weight of the given damage type in the skill. Returns null if the skill does not have the given damage type.

###	Setting the weight of a skill’s particular damage type
`<skill>.setDamageTypeWeight( _damageType, _weight )`

`_damageType` is a slot in the `this.Const.Damage.DamageType` table. `_weight` is an integer.

Finds the given damage type in the skill’s damage types and sets its weight to the given value. Does nothing if the skill does not have the given damage type.

### Getting the probability of a skill's particular damage type
`<skill>.getDamageTypeProbability( _damageType )`

`_damageType` is a slot in the `this.Const.Damage.DamageType` table.

Returns a float between 0 and 1 which is the probability of rolling the given damage type when using a skill. Returns null if the skill does not have the given damage type.

###	Rolling a damage type from a skill
`<skill>.getWeightedRandomDamageType()`

Selects a damage type from the skill based on weighted random distribution and returns it. The returned value is a slot in the `this.Const.Damage.DamageType` table. For example, this function is used by MSU in the `msu_injuries_handler_effect.nut` to roll a damage type from the skill when attacking a target.

### Accessing a skill's rolled damage type and damage weight during an attack
MSU adds the following two slots to the `this.Const.Tactical.HitInfo` table:
- `DamageType`
- `DamageTypeProbability`

When a skill is used to attack a target, the damage type of the skill is rolled using the `msu_injuries_handler_effect.nut` using the `onBeforeTargetHit` function, which adds the rolled `DamageType` and it's `DamageTypeProbability` (calculated using the `getDamageTypeProbability` function) to the hit info. These parameters can then be accessed by all skills which have access to the `_hitInfo`.

#### Example
For example, if a skill should only do something when the attacker attacked with Cutting damage using a skill which has more than 50% probability for cutting damage.
```
function onBeforeTargetHit( _skill, _targetEntity, _hitInfo )`
{
	if( _hitInfo.DamageType == this.Const.Damage.DamageType.Cutting && _hitInfo.DamageTypeProbability > 0.5)
	{
		// Do stuff
	}
}
```

## Item Actions
Item Action refers to swapping/equipping/removing items on a character during combat. MSU completely overhauls how the action point costs for this are handled. Now you can add skills that modify how many Action Points it costs to swap items, depending on what kind of items they are. This is accomplished via three things:

1. `ItemActionOrder`
2. `getItemActionCost( _items )`
3. `onPayForItemAction( _skill, _items )`

### Defining a skill's item action order
The `ItemActionOrder` parameter of a skill defines the priority in which a skill is consumed for changing the AP cost of an item action. The possible values are defined in a table `this.Const.ItemActionOrder` and can be expanded. A skill's order can then be defined during the `create()` function by an expression such as `this.m.ItemActionOrder = this.Const.ItemActionOrder.First`. 

By default all skills are assigned `this.m.ItemActionOrder = this.Const.ItemActionOrder.Any`.

### Allowing a skill to change an item action's Action Point cost
`getItemActionCost( _items )`

`_items` is an array containing the items involved in the item action.

The function returns either `null` or an `integer`. If it retunrs null, this means that this skill does not change the Action Point cost of this item action. Returning an integer means that this skill will make this item action's Action Point cost equal to the returned value. By default it returns null for all skills.

This function can be defined in a skill, and programmed to suit the needs and effects of that skill.

### Changing parameters in a skill after an item action
`onPayForItemActionCost( _skill, _items )`

`_skill` is the skill chosen for determining the Action Point cost of the item action. `_items` is an array containing the items involved in the item action.

This function is called on all skills after an item action.

### Example
Using this new system, Quick Hands is now implemented as follows:
```
this.m.IsSpent = false;
this.m.ItemActionOrder = this.Const.ItemActionOrder.Any;

function getItemActionCost( _items )
{
	return this.m.IsSpent ? null : 0;
}

function onPayForItemAction( _skill,  _items )
{
	if( _skill == this)
	{
		this.m.IsSpent = true;
	}
}

function onTurnStart()
{
	this.m.IsSpent = false;
}
```
Similarly, if a skill was designed to only allow 0 Action Point cost swapping between two one-handed items, the `getItemActionCost` function could be coded as follows:
```
function getItemActionCost( _items )
{
	local count = 0;
	foreach (item in _items)
	{
		if (item != null && item.isItemType(this.Const.Items.ItemType.OneHanded))
		{
			count++;
		}
	}

	return count == 2 ? 0 : null;
}
```

## New onXYZ functions
MSU adds the following onXYZ functions to all skills. These functions are called on all skills of an actor whenever they trigger.

### Using a skill
- `onBeforeAnySkillExecuted( _skill, _targetTile )`
- `onAnySkillExecuted( _skill, _targetTile, _targetEntity )`

`_skill` is the skill being used. `_targetTile` is the tile on which the skill is being used. `_targetEntity` is the entity occupying `_targetTile` and is null if the tile was empty.

The first function is called before the used skill's `use` function triggers, whereas the second function is called after the `use` function is complete.

### Actor movement
- `onMovementStarted( _tile, _numTiles )`
- `onMovementFinished( _tile )`

`_tile` is the tile on which the movement was started or finished and `_numTiles` is how many tiles the actor is trying to move (?).

During these function calls, the `this.m.IsMoving` parameter of the actor is `true`.

### Damage
- `onAfterDamageReceived()`

This function is called after the actor has received damage.

### Time of Day
- `onNewMorning()`

This function is called when the time of day reaches Morning. This is different from `onNewDay()` which runs at noon.

## Injuries 🟡
MSU adds a system to exclude certain sets of injuries from certain entities easily. MSU comes with the following sets of injuries built-in (only include vanilla injuries):
- Hand
- Arm
- Foot
- Leg
- Face
- Head

### Creating a new set of excluded injuries or expanding an existing set
`this.Const.Injury.ExcludedInjuries.add( _name, _injuries, _include = [] )`

`_name` is a string that will become a key in the `this.Const.Injury.ExcludedInjuries` table. `_injuries` is an array containing skill IDs of injuries. `_include` is an array of slots from the `this.Const.Injury.ExcludedInjuries` table.

Creates an entry in the `this.Const.Injury.ExcludedInjuries` table with `_name` as key and `{ Injuries = _injuries, Include = _include }` as value. The slots passed in the `_include` array must already exist.

If the key `_name` already exists in `this.Const.Injury.ExcludedInjuries` then its associated `Injuries` and `Include` are expanded to include `_injuries` and `_include`.

#### Example
```
this.Const.Injury.ExcludedInjuries.add(
	“Hand”,
	[
		“injury.fractured_hand”,
		“injury.crushed_finger”
	]
);

this.Const.Injury.ExcludedInjuries.add(
	“Arm”, 
	[
		“injury.fractured_elbow”
	],
	[
		this.Const.Injury.ExcludedInjuries.Hand
	]
);
```

### Getting a set of excluded injuries
`this.Const.Injury.ExcludedInjuries.get( _injuries )`

`_injuries` is a slot in the `this.Const.Injury.ExcludedInjuries` table.

Returns an array including the skill IDs of all the injuries associated with that slot. The array is expanded using the all the sets of injuries defined in the associated `Include` of that set.

#### Example
```
this.Const.Injury.ExcludedInjuries.add(
	“Hand”,
	[
		“injury.fractured_hand”,
		“injury.crushed_finger”
	]
);

this.Const.Injury.ExcludedInjuries.add(
	“Arm”, 
	[
		“injury.fractured_elbow”
	],
	[
		this.Const.Injury.ExcludedInjuries.Hand
	]
);

local result = this.Const.Injury.ExcludedInjuries.get(this.Const.Injury.ExcludedInjuries.Arm);
```
In this example `result` will be equal to `["injury.fractured_elbow", “injury.fractured_hand”, “injury.crushed_finger”]`.

### Adding excluded injuries to actors
`<actor>.addExcludedInjuries( _injuries )`

`_injuries` is a slot in the `this.Const.Injury.ExcludedInjuries` table.

Uses the `this.Const.Injury.ExcludedInjuries.get` function using the passed parameter and adds the entries in the returned array to the `this.m.ExcludedInjuries` array of `<actor>`. Entries already present in `this.m.ExcludedInjuries` are not duplicated.

#### Example
In order to prevent Serpents from gaining Arm related injuries, hook the `onInit` function of serpent and add the following line of code:
```
this.addExcludedInjuries(this.Const.Injury.ExcludedInjuries.Arm);
```

# Weapons 🟢
## WeaponType and Categories
In the vanilla game, each item contains a `this.m.Categories` parameter which is a string and determines what is shown in the weapon’s tooltip e.g. `“Sword, Two-Handed”`. However, the actual type of the item is defined separately in `this.m.ItemType`. So it is entirely possible for someone to make a mistake and write `“Two-Handed”` in categories but assign `this.m.ItemType` as `this.Const.Items.ItemType.Onehanded`.

Similarly a weapon may be a Sword but someone can write `“Hammer, One-Handed”` in the categories and it won’t cause any errors. But this can lead to issues in terms of player confusion and especially if any mod adds skills/perks which require a certain type of weapon e.g. if the skill should only work with Swords.

MSU eliminates the need for manually typing `this.m.Categories` and builds this parameter automatically using assigned `WeaponType` and `ItemType` values.

### Weapon types
Weapon types are defined in the table `this.Const.Items.WeaponType`.

### Added a new weapon type
`this.Const.Items.addNewWeaponType( _weaponType, _weaponTypeName = "" )`

`_weaponType` is a string which will become a key in the `this.Const.Items.WeaponType` table. `_weaponTypeName` is an optional string parameter that will be used as the name of this weapon type in tooltips; if not provided then the same string as `_weaponType` is used as the name.

#### Example
`this.Const.Items.addNewWeaponType(“Musical”, “Musical Instrument”)` will add a weapon type that can then be accessed and checked against using `this.Const.Items.WeaponType.Musical` and will show up as `“Musical Instrument”` in tooltips.

### Getting the name of a weapon type
`this.Const.Items.getWeaponTypeName( _weaponType )`

Returns a string which is the the associated name of `_weaponType`. For instance, in the above example it will return `“Musical Instrument”` if `this.Const.Items.WeaponType.Musical` is passed as a parameter. If `_weaponType` does not exist as a weapon type, it returns an empty string.

### Adding a weapon type to a weapon
There are two methods of doing this. The recommended method is to use the `create()` function of the weapon to set its `this.m.WeaponType`. For example, for an Axe/Hammer hybrid weapon:
```
this.m.WeaponType = this.Const.Items.WeaponType.Axe | this.Const.Items.WeaponType.Hammer;
```

Alternatively, the following function can be used after the weapon has been created:
`<weapon>.addWeaponType( _weaponType, _setupCategories = true )`

`_weaponType` is a slot in the `this.Const.Items.WeaponType table`. If `_setupCategories` is true, then MSU will recreate the `this.m.Categories` of the weapon.

### Removing a weapon type from a weapon
`<weapon>.removeWeaponType( _weaponType, _setupCategories = true )`

`_weaponType` is a slot in the `this.Const.Items.WeaponType table`. If `_setupCategories` is true, then MSU will recreate the `this.m.Categories` of the weapon.

Removes a weapon type from the given weapon. Does nothing if the weapon does not have the given weapon type.

### Setting a weapon's weapon type
`<weapon>.setWeaponType( _weaponType, _setupCategories = true )`

`_weaponType` is a slot in the `this.Const.Items.WeaponType table`. If `_setupCategories` is true, then MSU will recreate the `this.m.Categories` of the weapon.

Sets the weapon’s `this.m.WeaponType` to `_weaponType`. Multiple weapon types can be passed `_weaponType` by using the bitwise |.

### Checking if a weapon has a certain weapon type
`<weapon>.isWeaponType( _weaponType, _only = false )`

`_weaponType` is a slot in the `this.Const.Items.WeaponType table`.

Returns true if the weapon has the given weapon type. If `_only` is true then it will only return true if the weapon has the given weapon type and no other weapon type.

### Setting a weapon's categories
This is generally discouraged, as modders are encouraged to use the WeaponType system to allow the categories to be automatically built. However, if the categories must be changed after a weapon has been created, it can be done using the following function:

`<weapon>.setCategories( _categories, _setupWeaponType = true )`

`_categories` is a string which will become the new `this.m.Categories` of that weapon. If `_setupWeaponType` is true, then MSU will automatically rebuild the WeaponType of the system based on the new categories string.

# Utilities 🟢
## Logging
`this.MSU.Log.printStackTrace( _maxDepth = 0, _maxLen = 10, _advanced = false )`

Prints the entire stack trace at the point where it is called, including a list of all variables. Also prints the elements of any arrays or tables up to `_maxDepth` and `_maxLen`. If `_advanced` is set to true, it also prints the memory address of each object.

## Tile
`this.MSU.Tile.canResurrectOnTile( _tile, _force = false )`

`_tile` is a Battle Brothers tile instance.

Returns false if there is no corpse on the tile. If there is a corpse on the tile, then it returns true if that corpse can resurrect or if `_false` is set to true. This function can be hooked by mods to add additional functionality.

## String
`this.MSU.String.capitalizeFirst( _string )`

Returns the passed string `_string` with its first letter having been capitalized.

`this.MSU.String.replace( _string, _find, _replace )`

Finds the string `_find` in the string `_string` and replaces it with the string `_replace`. Then returns the result.




