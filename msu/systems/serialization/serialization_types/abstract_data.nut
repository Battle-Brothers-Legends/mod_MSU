::MSU.Class.AbstractData <- class
{
	__Type = null;
	__Data = null;

	constructor( _type, _data )
	{
		this.__Type = _type;
		this.__Data = _data;
	}

	function getType()
	{
		return this.__Type;
	}

	function getData()
	{
		return this.__Data;
	}

	function serialize( _out )
	{
		_out.writeU8(this.__Type);
	}

	// Must be overridden by children
	function deserialize( _in )
	{
	}

	function __readValueFromStorage( _type, _in )
	{
		switch (_type)
		{
			case ::MSU.Serialization.DataType.U8: case ::MSU.Serialization.DataType.U16: case ::MSU.Serialization.DataType.U32:
			case ::MSU.Serialization.DataType.I8: case ::MSU.Serialization.DataType.I16: case ::MSU.Serialization.DataType.I32:
			case ::MSU.Serialization.DataType.F32: case ::MSU.Serialization.DataType.Bool: case ::MSU.Serialization.DataType.String:
				return ::MSU.Class.PrimitiveData(_type, _in["read" + ::MSU.Serialization.DataType.getKeyForValue(_type)]());

			case ::MSU.Serialization.DataType.Table:
				local ret = ::MSU.Class.TableData({});
				ret.deserialize(_in);
				return ret;

			case ::MSU.Serialization.DataType.Array:
				local ret = ::MSU.Class.ArrayData([]);
				ret.deserialize(_in);
				return ret;

			case ::MSU.Serialization.DataType.SerializationData:
				local ret = ::MSU.Class.SerializationData([]);
				ret.deserialize(_in);
				return ret;
		}
	}

	function __convertValueFromBaseType( _value )
	{
		switch (typeof _value)
		{
			case "integer":
				if (_value >= 0)
				{
					if (_value <= 255)
						return ::MSU.Class.PrimitiveData(::MSU.Serialization.DataType.U8, _value);
					else if (_value <= 65535)
						return ::MSU.Class.PrimitiveData(::MSU.Serialization.DataType.U16, _value);
					else
						return ::MSU.Class.PrimitiveData(::MSU.Serialization.DataType.U32, _value);
				}
				else
				{
					if (_value >= -128)
						return ::MSU.Class.PrimitiveData(::MSU.Serialization.DataType.I8, _value);
					else if  (_value >= -32768)
						return ::MSU.Class.PrimitiveData(::MSU.Serialization.DataType.I16, _value);
					else
						return ::MSU.Class.PrimitiveData(::MSU.Serialization.DataType.I32, _value);
				}
				break;
			case "string":
				return ::MSU.Class.PrimitiveData(::MSU.Serialization.DataType.String, _value);
			case "float":
				return ::MSU.Class.PrimitiveData(::MSU.Serialization.DataType.F32, _value);
			case "bool":
				return ::MSU.Class.PrimitiveData(::MSU.Serialization.DataType.Bool, _value);
			case "null":
				return ::MSU.Class.PrimitiveData(::MSU.Serialization.DataType.Null, null);
			case "table":
				if (::MSU.isBBObject(_value))
				{
					::logError("MSU Serialization cannot serialize BB Objects directly");
					throw ::MSU.Exception.InvalidValue(_value);
				}
				return ::MSU.Class.TableData(_value);
			case "array":
				return ::MSU.Class.ArrayData(_value);
			case "instance":
				if (_value instanceof ::MSU.Class.SerializationData)
					return _value;

				// TODO:
				// if (_value instanceof ::MSU.Class.StrictSerDeEmulator)
				// 	return _value.getDataArray();
				// ::logError("MSU Serialization cannot handle instances other than descendants of ::MSU.Class.AbstractSerializationData");
				throw ::MSU.Exception.InvalidValue(_value);

			// TODO: Can't really have a default case if we want this switch to be extenadable by submodders
			default:
				::logError("Attempted to serialize unknown type");
				throw ::MSU.Exception.InvalidType(_value);
		}
	}
}
