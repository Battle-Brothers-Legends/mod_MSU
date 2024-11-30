::MSU.Class.AbstractSetting <- class extends ::MSU.Class.SettingsElement
{
	static Type = "Abstract";
	Value = null;
	BaseValue = null;
	Locks = null;
	BeforeChangeCallbacks = null;
	AfterChangeCallbacks = null;
	Persistence = null; //if it should print change to log for further manipulation

	constructor( _id, _value, _name = null, _description = null )
	{
		base.constructor(_id, _name, _description)
		this.Value = _value;
		this.BaseValue = _value;
		this.Locks = {};
		this.Persistence = true;
		this.BeforeChangeCallbacks = [];
		this.AfterChangeCallbacks = [];
		this.Data.IsSetting <- true;
	}

	function setPersistence( _bool )
	{
		this.Persistence = _bool;
	}

	function getPersistence()
	{
		return this.Persistence;
	}

	function onBeforeChangeCallback( _newValue )
	{
		foreach (callback in this.BeforeChangeCallbacks)
		{
			callback.call(this, _newValue);
		}
	}

	function onAfterChangeCallback( _oldValue )
	{
		foreach (callback in this.AfterChangeCallbacks)
		{
			callback.call(this, _oldValue);
		}
	}

	function addBeforeChangeCallback( _callback )
	{
		this.BeforeChangeCallbacks.push(_callback);
	}

	function addAfterChangeCallback( _callback )
	{
		this.AfterChangeCallbacks.push(_callback);
	}

	function reset()
	{
		this.set(this.BaseValue, true, true, true, true);
	}

	function setBaseValue( _value, _reset = false)
	{
		this.BaseValue = _value;
		if (_reset)
		{
			this.reset();
		}
	}

	function set( _newValue, _updateJS = true, _updatePersistence = true, _updateBeforeChangeCallback = true, _force = false, _updateAfterChangeCallback = true)
	{
		if (this.isLocked())
		{
			::logError("Setting \'" + this.Name + "\'' is locked and its value cannot be changed. Lock reason: " + this.getLockReason());
			return false;
		}

		if (_newValue != this.Value || _force)
		{
			local oldValue = this.Value;
			if (_updateBeforeChangeCallback)
			{
				this.onBeforeChangeCallback(_newValue);
			}
			this.Value = _newValue;
			if (_updateAfterChangeCallback)
			{
				this.onAfterChangeCallback(oldValue);
			}
			if (_updatePersistence && this.Persistence)
			{
				::MSU.System.ModSettings.exportSettingToPersistentData(this);
			}
			if (_updateJS)
			{
				::MSU.System.ModSettings.updateSettingInJS(this.getPanelID(), this.getID(), _newValue);
			}
		}

		return true;
	}

	function getValue()
	{
		return this.Value;
	}

	function setDescription( _description )
	{
		this.Description = _description;
	}

	function getDescription()
	{
		local ret = base.getDescription();
		if (this.isLocked())
		{
			ret += "\n\n[color=" + ::Const.UI.Color.NegativeValue + "]Locked[/color]\n" + this.getLockReason();
		}
		return ret;
	}

	function isLocked()
	{
		return this.Locks.len() != 0;
	}

	function getLockReason()
	{
		local ret = "";
		foreach (lockReason in this.Locks)
		{
			ret += lockReason + " +++ ";
		}
		return ret == "" ? "" : ret.slice(0, -5);
	}

	// Deprecated - use addLock instead
	function lock( _lockReason = "" )
	{
		// "MSU_LegacyLock" is for legacy support for the days when settings used to have
		// a this.Locked Boolean which could be set/unset using lock() and unlock()
		this.Locks["MSU_LegacyLock" + this.Locks.len()] <- _lockReason;
	}

	function addLock( _lockID, _lockReason )
	{
		this.Locks[_lockID] <- _lockReason;
	}

	function removeLock( _lockID )
	{
		if (_lockID in this.Locks) delete this.Locks[_lockID];
	}

	function unlock()
	{
		this.Locks.clear();
	}

	function getUIData(_flags = [])
	{
		local ret = base.getUIData(_flags);
		ret.locked <- this.isLocked();
		ret.value <- this.getValue();
		ret.currentValue <- this.getValue();
		return ret;
	}

	function __getSerializationTable()
	{
		return {
			Value = this.getValue()
		};
	}

	function __setFromSerializationTable( _table )
	{
		this.unlock();
		this.set(_table.Value, true, false, true, true);
	}

	function getSerDeFlag()
	{
		return "ModSetting." + this.getID();
	}

	function flagSerialize( _out )
	{
		this.getMod().Serialization.flagSerialize(this.getSerDeFlag(), this.__getSerializationTable());
	}

	function flagDeserialize( _in )
	{
		if (::MSU.Mod.Serialization.isSavedVersionAtLeast("1.2.0-rc.1", _in.getMetaData()))
		{
			this.__setFromSerializationTable(this.getMod().Serialization.flagDeserialize(this.getSerDeFlag(), this.__getSerializationTable()));
		}
		else if (::MSU.Mod.Serialization.isSavedVersionAtLeast("0.0.1", _in.getMetaData()))
		{
			local getPropertyFlag = @( _modID, _property ) "ModSetting." + _modID + "." + this.getID() + "." + _property;
			local function setPropertyIfFlagExists( _property, _modID )
			{
				local flag = getPropertyFlag(_modID, _property);
				if (::World.Flags.has(flag))
				{
					this[_property] = ::World.Flags.get(flag);
					::World.Flags.remove(flag);
				}
			}

			local modID = this.getMod().getID();
			local valueFlag = getPropertyFlag(modID, "Value");
			if (::World.Flags.has(valueFlag) && ::World.Flags.get(valueFlag) != null + "")
			{
				this.unlock();
				this.set(::World.Flags.get(valueFlag), true, false, true, true);
			}
		}
		else
		{
			// This is what runs when we load a vanilla game, leaving this as placeholder for now
			// I think we should consider resetting the value here, (we should definitely reset once we have persistent data working with cookies)
			// as while it is less convenient, not resetting could theoretically cause issues.
		}
	}

	function tostring()
	{
		return "Type: " + this.getType() + " | ID: " + this.getID() + " | Name: " + this.getName() + " | Value: " + this.getValue();
	}

	function _tostring()
	{
		return this.tostring();
	}

	// Deprecated
	function addCallback( _callback )
	{
		this.addBeforeChangeCallback(_callback);
	}
}
