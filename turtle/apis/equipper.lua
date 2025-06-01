local Config = require('supo.config')

local peripheral = _G.peripheral
local turtle     = _G.turtle

local Equipper = { }

local equipmentList = Config.load('equipment', {
	[ 'plethora:scanner' ] = 'plethora:module_scanner',
	[ 'plethora:sensor' ] = 'plethora:module_sensor',
	[ 'plethora:laser' ] = 'plethora:module_laser',
	[ 'plethora:introspection' ] = 'plethora:module_introspection',
	[ 'plethora:kinetic' ] = 'plethora:module_kinetic',
	[ 'advanced_modem' ] = 'computercraft:wireless_modem_advanced',
	[ 'standard_modem' ] = 'computercraft:wireless_modem_normal',
})

local SCANNER_EQUIPPED = 'plethora:scanner'
local SCANNER_INV      = equipmentList[SCANNER_EQUIPPED] or 'unknown'

local reversed = {
	left = 'right',
	right = 'left'
}

local function getEquipped()
	Equipper.equipped = { }
	Equipper.equipped.left = peripheral.getType('left')
	Equipper.equipped.right = peripheral.getType('right')

	if not Equipper.equipped.left or not Equipper.equipped.right then
		-- try to detect non-peripheral type items - such as minecraft:diamond_pickaxe
		local side = Equipper.isEquipped(SCANNER_EQUIPPED)
		local meta
		if side then
			meta = peripheral.call(side, 'getBlockMeta', 0, 0, 0)

		elseif turtle.has(SCANNER_INV) then
			local swapSide = peripheral.getType('right') == 'modem' and 'left' or 'right'
			turtle.equip(swapSide, SCANNER_INV)
			Equipper.equipped[swapSide] = 'plethora:scanner'
			meta = peripheral.call(swapSide, 'getBlockMeta', 0, 0, 0)
		end

		if meta then
			if not Equipper.equipped.left then
				Equipper.equipped.left = meta.turtle.left and meta.turtle.left.id
			end
			if not Equipper.equipped.right then
				Equipper.equipped.right = meta.turtle.right and meta.turtle.right.id
			end

		elseif not Equipper.equipped.left then
			local slot = Equipper.unequip('left')
			if slot then
				turtle.equip('left', slot.name .. ':'  .. slot.damage)
				Equipper.equipped.left = slot.name .. ':'  .. slot.damage
			end

		elseif not Equipper.equipped.right then
			local slot = Equipper.unequip('right')
			if slot then
				turtle.equip('right', slot.name .. ':'  .. slot.damage)
				Equipper.equipped.right = slot.name .. ':'  .. slot.damage
			end
		end
	end
end

local function matches(left, right)
	-- return a match for 'minecraft:diamond_sword:0' with 'minecraft:diamond_sword'
	if left and right then
		return left:match(right)
	end
end

function Equipper.unequip(side)
	local slot = turtle.selectOpenSlot()
	if not slot then
		error('No slots available')
	end
	turtle.equip(side)
	if Equipper.equipped then
		Equipper.equipped[side] = nil
	end
	return turtle.getItemDetail(slot)
end

function Equipper.isEquipped(name)
	if not Equipper.equipped then
		getEquipped()
	end

	return Equipper.equipped.left  == name and 'left' or
				 Equipper.equipped.right == name and 'right'
end

-- so convoluted - needs it's own function
function Equipper.equipModem(side)
	if peripheral.getType(side) ~= 'modem' then
		if peripheral.getType(reversed[side]) then
			Equipper.unequip(reversed[side])
		end
		if turtle.has(equipmentList['advanced_modem']) then
			local success, result = pcall(Equipper.equip, side, equipmentList['advanced_modem'])
			if success then
				return result
			else
				-- Log the error for debugging
				print('Failed to equip advanced modem: ' .. tostring(result))
			end
		end
		if turtle.has(equipmentList['standard_modem']) then
			local success, result = pcall(Equipper.equip, side, equipmentList['standard_modem'])
			if success then
				return result
			else
				-- Log the error for debugging
				print('Failed to equip standard modem: ' .. tostring(result))
			end
		end
		error('Missing modem')
	end
end

function Equipper.equip(side, item)
	if not Equipper.equipped then
		getEquipped()
	end

	-- is it already equipped ?
	if matches(Equipper.equipped[side], item) then
		return peripheral.getType(side) and peripheral.wrap(side)
	end

	-- is it equipped on other side ?
	if matches(Equipper.equipped[reversed[side]], item) then
		Equipper.unequip(reversed[side])
	end

	local s, m = turtle.equip(side, equipmentList[item] or item)
	if not s then
		error(string.format('Unable to equip %s\n%s', item, m))
	end

	Equipper.equipped[side] = peripheral.getType(side) or item

	return peripheral.getType(side) and peripheral.wrap(side)
end

function Equipper.equipLeft(item)
	return Equipper.equip('left', item)
end

function Equipper.equipRight(item)
	return Equipper.equip('right', item)
end

-- Debug function to check equipment configuration
function Equipper.debugEquipment()
	print('Equipment list:')
	for k, v in pairs(equipmentList) do
		print('  ' .. k .. ' = ' .. v)
	end
	print('Advanced modem check:')
	print('  equipmentList[\'advanced_modem\'] = ' .. tostring(equipmentList['advanced_modem']))
	print('  turtle.has(equipmentList[\'advanced_modem\']) = ' .. tostring(turtle.has(equipmentList['advanced_modem'])))
	print('  turtle.has(\'computercraft:wireless_modem_advanced\') = ' .. tostring(turtle.has('computercraft:wireless_modem_advanced')))
end

return Equipper
