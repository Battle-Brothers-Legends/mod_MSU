::mods_hookNewObject("items/weapons/oriental/nomad_sling", function(o) {
	if (o.isWeaponType(::Const.Items.WeaponType.Throwing))
	{
		o.removeWeaponType(::Const.Items.WeaponType.Throwing, false);
		o.addWeaponType(::Const.Items.WeaponType.Sling);
	}
});
