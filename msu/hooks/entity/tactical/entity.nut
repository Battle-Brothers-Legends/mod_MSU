::MSU.MH.hook("scripts/entity/tactical/entity", function(q) {
	q.create <- @(__original) function()
	{
		__original();
		this.getFlags().set("MSU_UID", ::MSU.Utils.generateUID());
	}

	q.getUID <- function()
	{
		return this.getFlags().get("MSU_UID");
	}

	q.onDeserialize = @(__original) function( _in )
	{
		__original(_in);
		if (!this.getFlags().has("MSU_UID"))
		{
			this.getFlags().set("MSU_UID", ::MSU.Utils.generateUID());
		}
	}
});
