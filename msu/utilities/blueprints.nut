::MSU.Blueprints <- {
	NewIngredients = {},
	ItemsToChange = {},
	BlueprintToItemScriptMap = {},

	// _blueprintID is the id of this blueprint defined in its create function.
	// _conditionFunction is a function that returns a Boolean. If it returns true, then the changes will be applied. Pass null for no conditions.
	// _ingredients are the new ingredients for the blueprint. Pass null if ingredients shouldn't be changed.
	// _itemFunction is a function that takes a single argument which is the item that will be crafted from this blueprint. You can modify the properties of the item in this function.
	// _blueprintScript is a string that is the address of this blueprint's script file in the BB data folder. Don't include the "scripts/" part of the address.
	function changeBlueprint( _blueprintID, _conditionFunction = null, _ingredients = null, _itemFunction = null, _blueprintScript = null )
	{
		if (_ingredients == null && _itemFunction == null) return;

		if (_itemFunction != null)
		{
			if (_blueprintScript == null)
			{
				this.logError("If you provide an _itemFunction, you must also provide a _blueprintScript");
				throw ::MSU.Exception.InvalidType;
			}

			this.ItemsToChange[_blueprintID] <- _itemFunction;
		}

		if (_ingredients != null) this.NewIngredients[_blueprintID] <- _ingredients;

		::mods_hookBaseClass("crafting/blueprint", function(o) {
			o = o[o.SuperName];

			local getUIData = o.getUIData;
			o.getUIData = function()
			{
				if (_conditionFunction == null || _conditionFunction())
				{      
					local id = this.getID();
					if (id in ::MSU.Blueprints.NewIngredients)
					{
						this.m.PreviewComponents.clear();
						this.init(::MSU.Blueprints.NewIngredients[id]);
						delete ::MSU.Blueprints[id];		
					}

					if (id in ::MSU.Blueprints.ItemsToChange)
					{
						::MSU.Blueprints.ItemsToChange[id](this.m.PreviewCraftable);
						::MSU.BlueprintToItemScriptMap[id] <- this.IO.scriptFilenameByHash(this.m.PreviewCraftable.ClassNameHash);
						delete ::MSU.Blueprints.ItemsToChange[id];
					}
				}

				return getUIData();
			}
		});

		if (_blueprintScript != null)
		{
			::mods_hookExactClass(_blueprintScript, function(o) {
				local onCraft = o.onCraft;
				o.onCraft = function( _stash )
				{
					if (_itemFunction != null && (_conditionFunction == null || _conditionFunction()))
					{
						local item = this.new(::MSU.BlueprintToItemScriptMap[this.getID()]);
						_itemFunction(item);
						_stash.add(item);
					}
					else
					{
						onCraft(_stash);
					}
				}
			});
		}
	}
}
