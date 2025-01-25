// Base for the Serialization and Deserialization Emulators
::MSU.Class.SerDeEmulator <- class
{
	MetaData = null;
	SerializationData = null;

	// Used to populate SerializationEmulator and FlagSerializationEmulator classes after their creation to emulate multiple inheritance
	static __ReadFields = {
		Idx = -1,

		function readString()
		{
			return this.__readData(::MSU.Serialization.DataType.String);
		}

		function readBool()
		{
			return this.__readData(::MSU.Serialization.DataType.Bool);
		}

		function readI32()
		{
			return this.__readData(::MSU.Serialization.DataType.I32);
		}

		function readU32()
		{
			return this.__readData(::MSU.Serialization.DataType.U32);
		}

		function readI16()
		{
			return this.__readData(::MSU.Serialization.DataType.I16);
		}

		function readU16()
		{
			return this.__readData(::MSU.Serialization.DataType.U16);
		}

		function readI8()
		{
			return this.__readData(::MSU.Serialization.DataType.I8);
		}

		function readU8()
		{
			return this.__readData(::MSU.Serialization.DataType.U8);
		}

		function readF32()
		{
			return this.__readData(::MSU.Serialization.DataType.F32);
		}
	};

	// Used to populate DeserializationEmulator and FlagDeserializationEmulator classes after their creation to emulate multiple inheritance
	static __WriteFields = {
		function writeString( _string )
		{
			::MSU.requireString(_string);
			this.__writeData(_string, ::MSU.Serialization.DataType.String);
		}

		function writeBool( _bool )
		{
			::MSU.requireBool(_bool);
			this.__writeData(_bool, ::MSU.Serialization.DataType.Bool);
		}

		function writeI32( _int )
		{
			_int = convertFloatToIntIfEqual(_int);
			::MSU.requireInt(_int);
			this.__writeData(_int, ::MSU.Serialization.DataType.I32);
		}

		function writeU32( _int )
		{
			_int = convertFloatToIntIfEqual(_int);
			::MSU.requireInt(_int);
			if (_int < 0)
				throw ::MSU.Exception.InvalidValue(_int);
			this.__writeData(_int, ::MSU.Serialization.DataType.U32);
		}

		function writeI16( _int )
		{
			_int = convertFloatToIntIfEqual(_int);
			::MSU.requireInt(_int);
			if (_int < -32768 || _int > 32767)
				throw ::MSU.Exception.InvalidValue(_int);
			this.__writeData(_int, ::MSU.Serialization.DataType.I16);
		}

		function writeU16( _int )
		{
			_int = convertFloatToIntIfEqual(_int);
			::MSU.requireInt(_int);
			if (_int < 0 || _int > 65535)
				throw ::MSU.Exception.InvalidValue(_int);
			this.__writeData(_int, ::MSU.Serialization.DataType.U16);
		}

		function writeI8( _int )
		{
			_int = convertFloatToIntIfEqual(_int);
			::MSU.requireInt(_int);
			if (_int < -128 || _int > 127)
				throw ::MSU.Exception.InvalidValue(_int);
			this.__writeData(_int, ::MSU.Serialization.DataType.I8);
		}

		function writeU8( _int )
		{
			_int = convertFloatToIntIfEqual(_int);
			::MSU.requireInt(_int);
			if (_int < 0 || _int > 255)
				throw ::MSU.Exception.InvalidValue(_int);
			this.__writeData(_int, ::MSU.Serialization.DataType.U8);
		}

		function writeF32( _float )
		{
			::MSU.requireOneFromTypes(["float", "integer"], _float);
			this.__writeData(_float, ::MSU.Serialization.DataType.F32);
		}
	};

	constructor( _metaDataEmulator, _serializationData = null )
	{
		this.MetaData = _metaDataEmulator;
		if (_serializationData == null)
			this.resetData();
		else
		{
			::MSU.requireInstanceOf(::MSU.Class.SerializationData, _serializationData);
			this.SerializationData = _serializationData;
		}
	}

	function convertFloatToIntIfEqual(_int)
	{
		if (typeof _int == "float" && _int.tointeger() == _int)
			return _int.tointeger();
		return _int;
	}

	function resetData()
	{
		this.SerializationData = ::MSU.Class.SerializationData();
	}

	function getData()
	{
		return this.SerializationData;
	}

	function getMetaData()
	{
		return this.MetaData;
	}

	function __writeData( _data, _type )
	{
		this.SerializationData.write(_data, _type);
	}

	function __readData( _type )
	{
		if (this.SerializationData.len() <= ++this.Idx)
		{
			::logError(format("Tried to read data beyond (%i) the length (%i) of the Deserialization Emulator", this.Idx, this.SerializationData.len()));
			return null;
		}
		local data = this.SerializationData.getDataArray()[this.Idx];
		if (!data.isTypeValid(_type))
		{
			local stackinfos = ::getstackinfos(2);

			local errorMsg = format("The type being read %s isn't the same as the type %s (with value: %s) stored in the Deserialization Emulator (%s -> %s : %i)",
				::MSU.Serialization.DataType.getKeyForValue(_type),
				::MSU.Serialization.DataType.getKeyForValue(this.SerializationData.getDataArray()[this.Idx].getType()), data.getData() + "",
				stackinfos.func == "unknown" ? "" : stackinfos.func, stackinfos.src, stackinfos.line);
			::MSU.Mod.Debug.printWarning(errorMsg, "serde");
			if (::MSU.Mod.Debug.isEnabled("serde")) {
				::MSU.Log.printStackTrace(); // TODO: Temporary, should be removed once log spam issue is resolved
			}
		}
		return data.getData();
	}
}
