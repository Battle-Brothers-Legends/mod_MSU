::MSU.Class.WeightedContainer <- class
{
	Total = null;
	Table = null;
	Forced = null;
	IItems = null;
	IIndexStack = null;

	constructor( _array = null )
	{
		this.Total = 0.0;
		this.Table = {};
		this.Forced = [];
		this.IIndexStack = [];
		if (_array != null) this.addArray(_array);
	}

	function _get( _item )
	{
		if (_item in this.Table) return this.Table[_item];
		throw null;
	}

	function _cloned( _original )
	{
		this.Total = _original.Total;
		this.Table = clone _original.Table;
		this.Forced = clone _original.Forced;
	}

	function _nexti( _prev )
	{
		if (_prev == null)
		{
			if (this.IItems == null)
				this.IItems = ::MSU.Table.keys(this.Table);
			this.IIndexStack.push(0)
		}
		_prev = this.IIndexStack[this.IIndexStack.len() - 1]++;

		if (_prev == this.Table.len())
		{
			this.IIndexStack.pop();
			if (this.IIndexStack.len() == 0)
				this.IItems = null;
			return null;
		}

		return this.IItems[_prev];
	}

	function toArray( _itemsOnly = true )
	{
		local ret = ::array(this.Table.len());
		local i = 0;
		foreach (item, weight in this.Table)
		{
			if (_itemsOnly) ret[i++] = item;
			else ret[i++] = [weight, item];
		}
		return ret;
	}

	function addArray( _array )
	{
		::MSU.requireArray(_array);
		foreach (pair in _array)
		{
			::MSU.requireArray(pair);
			if (pair.len() != 2) throw ::MSU.Exception.InvalidType(pair);
			
			this.add(pair[1], pair[0]);
		}
	}

	function merge( _otherContainer )
	{
		::MSU.requireInstanceOf(::MSU.Class.WeightedContainer, _otherContainer);
		foreach (item, weight in _otherContainer.Table)
		{
			this.add(item, weight);
		}
	}

	function addMany( _weight, _array )
	{
		::MSU.requireArray(_array);
		foreach (item in _array)
		{
			this.add(item, _weight);
		}
		return this;
	}

	function add( _item, _weight = 1 )
	{
		::MSU.requireOneFromTypes(["integer", "float"], _weight);
		_weight = _weight.tofloat();

		if (_item in this.Table)
		{
			local newWeight = this.Table[_item] < 0 ? _weight : this.Table[_item] + _weight;
			this.updateWeight(_item, newWeight);
		}
		else
		{
			this.Table[_item] <- 0;
			this.updateWeight(_item, _weight);
		}
	}

	function remove( _item )
	{
		if (this.Table[_item] < 0) delete this.Forced[_item];
		else this.Total -= this.Table[_item];
		delete this.Table[_item];
	}

	function contains( _item )
	{
		return _item in this.Table;
	}

	function getProbability( _item, _exclude = null )
	{
		if (_exclude != null)
		{
			::MSU.requireArray(_exclude);
			if (_exclude.find(_item) != null) return 0.0;
		}

		local forced = _exclude == null ? this.Forced : this.Forced.filter(@(idx, item) _exclude.find(item) == null);
		foreach (item in forced)
		{
			if (item == _item) return 1.0 / forced.len();
		}
		
		if (forced.len() != 0) return 0.0;

		return this.Table[_item] == 0 ? 0.0 : this.Table[_item] / this.getTotal(_exclude);
	}

	function getWeight( _item )
	{
		return this.Table[_item];
	}

	function setWeight( _item, _weight )
	{
		::MSU.requireOneFromTypes(["integer", "float"], _weight);
		this.updateWeight(_item, _weight);
	}

	function apply( _function )
	{
		// _function (_item, _weight)
		// must return new weight for _item

		foreach (item, weight in this.Table)
		{
			this.setWeight(item, _function(item, weight))
		}
	}

	function map( _function )
	{
		// _function (_item, _weight)
		// must return a len 2 array with weight, item as elements

		local ret = ::MSU.Class.WeightedContainer();
		foreach (item, weight in this.Table)
		{
			local pair = _function(item, weight); 
			ret.add(pair[1], pair[0]);
		}
		return ret;
	}

	function filter( _function )
	{
		// _function (_item, _weight)
		// must return a boolean

		local ret = ::MSU.Class.WeightedContainer();
		foreach (item, weight in this.Table)
		{
			if (_function(item, weight)) ret.add(item, weight);
		}
		return ret;
	}

	function clear()
	{
		this.Total = 0.0;
		this.Table.clear();
		this.Forced.clear();
	}

	function max()
	{
		local maxWeight = 0.0;
		local ret;

		foreach (item, weight in this.Table)
		{
			if (weight > maxWeight)
			{
				maxWeight = weight;
				ret = item;
			}
		}

		return ret;
	}

	function rand( _exclude = null )
	{
		if (_exclude != null) ::MSU.requireArray(_exclude);

		local rand = ::Math.rand(0, (this.Table.len() - _exclude == null ? 0 : _exclude.len()) - 1)
		local i = 0;
		foreach (item, weight in this.Table)
		{
			if (_exclude == null || _exclude.find(item) == null)
			{
				if (rand == i++) return item;
			}
		}
		return null;
	}

	function roll( _exclude = null )
	{
		if (_exclude != null) ::MSU.requireArray(_exclude);

		local forced = _exclude == null ? this.Forced : this.Forced.filter(@(idx, item) _exclude.find(item) == null);
		if (forced.len() > 0)
		{
			return ::MSU.Array.rand(forced);
		}

		local roll = ::MSU.Math.randf(0.0, this.getTotal(_exclude));
		foreach (item, weight in this.Table)
		{
			if (_exclude != null && _exclude.find(item) != null) continue;

			if (roll <= weight && weight != 0.0) return item;

			roll -= weight;
		}

		return null;
	}

	function rollChance( _chance, _exclude = null )
	{
		return ::Math.rand(1, 100) <= _chance ? this.roll(_exclude) : null;
	}

	function len()
	{
		return this.Table.len();
	}

	function onSerialize( _out )
	{
		_out.writeU32(this.Total);
		::MSU.Utils.serialize(this.Table, _out);
	}

	function onDeserialize( _in )
	{
		this.Total = _in.readU32();
		this.Table = ::MSU.Utils.deserialize(_in);
	}

	// Private
	function updateWeight( _item, _newWeight )
	{
		_newWeight = _newWeight.tofloat();

		if (this.Table[_item] >= 0)
		{
			this.Total -= this.Table[_item];
			if (_newWeight < 0) this.Forced.push(_item);
		}

		if (_newWeight >= 0)
		{
			this.Total += _newWeight;
			if (this.Table[_item] < 0) this.Forced.remove(this.Forced.find(_item));
		}

		this.Table[_item] = _newWeight;
	}

	// Private
	function getTotal( _exclude = null )
	{
		if (_exclude == null) return this.Total;

		local ret = this.Total;
		foreach (item in _exclude)
		{
			if (this.Table[item] > 0) ret -= this.Table[item];
		}

		return ret;
	}
}
