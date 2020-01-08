local engine = select(2,...)

local SLOT_TRINKET = 0x1
local SLOT_RING = 0x2
local SLOT_METAGEM = 0x3
local SLOT_BACK = 0x4


engine[1] = {
	[42292] = {{51377,51378}, 120, SLOT_TRINKET}, -- medalion
	[60064] = {44912, 45,  SLOT_TRINKET},
	[71607] = {50354, 120, SLOT_TRINKET},
	[71485] = {50362, 90,  SLOT_TRINKET},
	[67772] = {47131, 45,  SLOT_TRINKET},
	[71556] = {50363, 90,  SLOT_TRINKET},
	[75466] = {54572, 45,  SLOT_TRINKET},
	[71572] = {50345, 0,   SLOT_TRINKET},
	[71584] = {50358, 45,  SLOT_TRINKET},
	[71541] = {50343, 45,  SLOT_TRINKET},
	[71486] = {50362, 90,  SLOT_TRINKET},
	[67773] = {47131, 45,  SLOT_TRINKET},
	[71561] = {50363, 90,  SLOT_TRINKET},
	[71636] = {50365, 75,  SLOT_TRINKET},
	[64713] = {45518, 45,  SLOT_TRINKET},
	[71644] = {50348, 75,  SLOT_TRINKET},
	[71396] = {50355, 0,   SLOT_TRINKET},
	[75495] = {54589, 120, SLOT_TRINKET},
	[67750] = {47059, 0,   SLOT_TRINKET},
	[71601] = {50353, 75,  SLOT_TRINKET},
	[71605] = {50360, 75,  SLOT_TRINKET},
	[67703] = {47115, 45,  SLOT_TRINKET},
	[75456] = {54590, 45,  SLOT_TRINKET},
	[71491] = {50362, 90,  SLOT_TRINKET},
	[71558] = {50363, 90,  SLOT_TRINKET},
	[71574] = {50346, 120, SLOT_TRINKET},
	[71586] = {50356, 120, SLOT_TRINKET},
	[71401] = {50342, 45,  SLOT_TRINKET},
	[75458] = {54569, 45,  SLOT_TRINKET},
	[67696] = {47041, 0,   SLOT_TRINKET},
	[71560] = {50363, 90,  SLOT_TRINKET},
	[71484] = {50362, 90,  SLOT_TRINKET},
	[67708] = {47115, 45,  SLOT_TRINKET},
	[71492] = {50362, 90,  SLOT_TRINKET},
	[71559] = {50363, 90,  SLOT_TRINKET},
	[75490] = {54573, 120, SLOT_TRINKET},
	[75473] = {54588, 45,  SLOT_TRINKET},
	[71432] = {50351, 0,   SLOT_TRINKET},
	[71638] = {50364, 60,  SLOT_TRINKET},
	[71579] = {50357, 120, SLOT_TRINKET},
	[71635] = {50361, 60,  SLOT_TRINKET},
	[60065] = {44914, 45,  SLOT_TRINKET},
	[60443] = {40371, 45,  SLOT_TRINKET},

	[72412] = {50402, 60,  SLOT_RING}, -- icc agility
	[72416] = {50398, 60,  SLOT_RING}, -- icc caster
	[72412] = {52572, 60,  SLOT_RING}, -- icc strange
	[72418] = {50400, 60,  SLOT_RING}, -- icc heal
	[55637] = {3722, 45,   SLOT_BACK}, -- enchant spd
	[55775] = {3730, 45,   SLOT_BACK}, -- enchant ap
	[55379] = {41400, 45,  SLOT_METAGEM}, -- melee haste

}