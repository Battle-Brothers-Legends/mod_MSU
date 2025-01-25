// a number of test cases for modinfos 
local function __addDebugModVersions(_modInfos)
{
	_modInfos["A"] <- {
		UpdateInfo = {
			name = "Test_A_NEW",
			currentVersion = "1.2.3",
			availableVersion = "1.2.2",
			updateType = "PATCH",
			changes = @"# H1
			## H2
			### H3
			#### H4
			##### H5",
			sources = {},
			isNew = true
	}};
	_modInfos["B"] <- {
		UpdateInfo = {
			name = "Test_B",
			currentVersion = "1.2.3",
			availableVersion = "1.2.2",
			updateType = "MAJOR",
			changes = "",
			sources = {},
			isNew = false
	}};
	_modInfos["C"] <- {
		UpdateInfo = {
			name = "Test_C_NEW",
			currentVersion = "1.2.3",
			availableVersion = "1.2.2",
			updateType = "MINOR",
			changes = "",
			sources = {},
			isNew = true
	}};
	_modInfos["D"] <- {
		UpdateInfo = {
			name = "Test_D",
			currentVersion = "1.2.3",
			availableVersion = "1.2.2",
			updateType = "MINOR",
			changes = "",
			sources = {},
			isNew = false
	}};
	_modInfos["E"] <- {
		UpdateInfo = {
			name = "Test_E_NEW",
			currentVersion = "1.2.3",
			availableVersion = "1.2.2",
			updateType = "MINOR",
			changes = "",
			sources = {},
			isNew = true
	}};
}