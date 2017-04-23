pico-8 cartridge // http://www.pico-8.com
version 8
__lua__


-- ************************************************************************ constant definition ************************************************************************
-- button inputs
button_left   = 0
button_right  = 1
button_up     = 2
button_down   = 3
button_action = 4
button_jump   = 5

-- unit machine state constants
unit_state_idle    = 0
unit_state_dead    = 1
unit_state_walk    = 2
unit_state_jump    = 3
unit_state_djump   = 4
unit_state_falling = 5
unit_state_shooting= 6
unit_state_charging= 7
unit_state_animated= 8
unit_state_random  = 9

-- game state constants
game_state_playing = 0
game_state_popup   = 1
game_state_end     = 2
game_state_camtransition = 3

-- unit type enumeration and environement
type_environement            = 1
unit_type_player             = 2
unit_type_particule          = 3
unit_type_particule_generator= 4
unit_type_scenario           = 5

-- standard particule generators (extention of unit type)
generator_fire = 6
generator_acid = 7

-- ennemy type (extention of unit type)
ennemy_walker = 8
ennemy_jumper = 9
ennemy_flyer  = 10

-- material flags
flag_none   	 = 0
flag_solid  	 = 1
flag_traversable = 2
flag_destructible= 3
flag_enemy		 = 4

-- rooms definition for camera placement
-- room format : {posx, posy, width, height, {neighbors room, ...}, {monster, particle generator, ...}, }
-- unit format : {posx, posy, type, optionnal (looking direction, ...)}
rooms = {
	-- room 1
	{0, 0, 16*8, 16*8, {2,8}, {
		{10*8, 14*8, 6, 1},		-- fire
		{4*8, 14*8, 6, 1},		-- fire
		{3*8, 14*8, 6, 1}}},	-- scenario shoot

	-- room 2
	{16*8, 0, 16*8, 16*8, {1,3}, {
		{28*8, 10*8, 8, 1}}},			-- walker

	-- room 3
	{16*16, 0, 16*8, 16*8, {2,4},{
		{39*8, 3*8, 8, 1},				-- walker
		{45*8, 14*8, 5, 1}}},			-- scenario shoot
	
	-- room 4
	{16*24, 0, 16*8, 16*8, {3,5}, {
		{59*8, 4*8, 8, 1},				-- walker
		{59*8, 7*8, 8, 1},				-- walker
		{57*8, 12*8, 8, 1}}},			-- walker

	-- room 5
	{16*8*3, 16*8, 16*8, 16*8, {4,6,9}, {
		{57*8, 20*8, 8, 1},				-- walker
		{50*8, 22*8, 8, 1},				-- walker
		{58*8, 27*8, 9, 1}}},			-- jumper

	-- room 6
	{16*16, 16*8, 16*8, 16*8, {5,7}, {
		{35*8, 20*8, 8, -1}}},			-- walker

	-- room 7
	{16*8, 16*8, 16*8, 16*8, {6,8}, {
		{35*8, 20*8, 8, 1}}},			-- walker

	-- room 8
	{0, 16*8, 16*8, 16*8, {7, 1}, {}},

	-- room 9
	{16*8*4, 0, 16*8, 16*8*3, {5,10,12,15}, {
		{77*8, 46*8, 5, 3} }},			-- scenario charged shoot

	-- room 10
	{16*8*2, 16*8*2, 16*8*2, 16*8, {9,11},{}},

	-- room 11
	{0, 16*8*2, 16*8*2, 16*8, {10}, {
		{18*8, 46*8, 7, 1},	{19*8, 46*8, 7, 1},		-- acid
		{21*8, 46*8, 7, 1}, {22*8, 46*8, 7, 1},		-- acid
		{24*8, 46*8, 7, 1}, {25*8, 46*8, 7, 1},		-- acid
		{27*8, 46*8, 7, 1},							-- acid
		{29*8, 38*8, 5, 2} }},						-- scenario double jump

	-- room 12
	{16*8*5, 0, 16*8*2, 16*8, {9,13}, {
		{83*8, 6*8, 7, 1}, {85*8, 6*8, 7, 1},		-- acid
		{87*8, 6*8, 7, 1}, {88*8, 6*8, 7, 1},		-- acid
		{89*8, 6*8, 7, 1}, {91*8, 6*8, 7, 1},		-- acid
		{92*8, 6*8, 7, 1}, {93*8, 6*8, 7, 1},		-- acid
		{94*8, 6*8, 7, 1}, {95*8, 6*8, 7, 1},		-- acid
		{96*8, 6*8, 7, 1}, {98*8, 6*8, 7, 1},		-- acid
		{99*8, 6*8, 7, 1}, {101*8, 6*8, 7, 1},		-- acid
		{102*8, 6*8, 7, 1},{103*8, 6*8, 7, 1},		-- acid
		{105*8, 6*8, 7, 1},{106*8, 6*8, 7, 1},		-- acid
		{107*8, 6*8, 7, 1},{109*8, 6*8, 7, 1},		-- acid
		{85*8, 6*8, 7, 1}	}},

	{16*8*7, 0, 16*8, 16*8*3, {12,14,16}, {}},
	{16*8*6, 16*8, 16*8, 16*8, {13,15}, {}},
	{16*8*5, 16*8, 16*8, 16*8*2, {14,9}, {}},
	{16*8*6, 16*8*2, 16*8, 16*8, {13}, {}}
}

-- scenario definition
scenario = {
	-- {sprite, picked, {text for popup in line array}, optionnal string}
	{33, false, {"god damn gun !","finnaly got you !"}, "shoot"},
	{34, false, {"ha! my jetpack,","could be useful in a","place like this."}, "djump"},
	{33, false, {"nice!, this experimental","gun can be charged for","more dammage!"}, "cshoot"}
}

-- player constant
constant_jumpspeed = -4
constant_walkspeed = 1.8
constant_chargeshoottime = 60
constant_invulnerabilitytime = 30

-- ennemy constant
constant_random_behaviour = 60
constant_walkerspeed = 0.3
constant_jumperspeedx = 1.3
constant_jumperspeedy = 4
constant_flyerspeed = 0.5



-- ************************************************************************ global variables ************************************************************************
-- frame counter
framecounter = 0

-- game state
gamestate = game_state_playing

-- player unit
player = {}

-- all the unit present in the game
unitlist = {}
tmpunitlist = {}

-- current room of the player unit
currentroom = 1

-- camera
cam = {}



-- ************************************************************************ pico8 and specific engine function functions ************************************************************************
function _init()
	initializecontroller()
	initializeplayer()
	initializecollision()
	initializecamera()
	reset()

	--placescenario(9*8, 14*8, 33)
	--placescenario(11*8, 14*8, 34)
	--placescenario(13*8, 14*8, 35)
end

function reset()
	reload(0x2000, 0x2000, 0x1000)
	gamestate = game_state_playing
	resetcontroller()
	resetplayer()
	resetroomsystem()
	resetscenario()

	setplayerposition(111*8, 46*8)
	player.djumpenable = true
	player.shootenable = true
	player.chargeshootenable = true
end

function _update()
	-- need to reset game
	if (player.state == unit_state_dead) then
		reset()

	-- normal mode of game
	elseif (gamestate == game_state_playing) then
		-- update players and controller
		framecounter += 1;
		updatecontroller(framecounter)
		updateplayerstate()
		updateplayeraction()
		updateplayerdammage()

		-- update unit and unit ia 
		for unit in all(unitlist) do
			if (unit.controller) then unit.controller(unit) end
		end
		for unit in all(unitlist) do
			if (unit.update) then unit.update(unit) end
		end

		-- compute subframe factor for subframe physics update
		local maxspeed = max(1, max(abs(player.speedx), abs(player.speedy)))
		for unit in all(unitlist) do
			maxspeed = max(maxspeed, max(abs(unit.speedx), abs(unit.speedy)))
		end
		local step = flr(maxspeed)

		-- subframe update
		for i = 1, step do
			-- update all physics
			updatephysics(player, 1.0/step)
			for unit in all(unitlist) do
				updatephysics(unit, 1.0/step)
			end

			-- update all collisions
			for unit1 in all(unitlist) do
				if (collisioncheck(player, unit1) and _colisionmatrix[unit_type_player][unit1.type]) then
					_colisionmatrix[unit_type_player][unit1.type](player, unit1)
				end

				
				for unit2 in all(unitlist) do
					if(unit1 == unit2) then break end -- only check with previous unit
					if (collisioncheck(unit1, unit2) and _colisionmatrix[unit1.type][unit2.type]) then
						_colisionmatrix[unit1.type][unit2.type](unit1, unit2)
					end
				end
			end
			for unit in all(unitlist) do
				if (unit.state == unit_state_dead) then del(unitlist, unit) end
			end
		end

		-- update room system
		updateroom()

	-- game in popup mode
	elseif (gamestate == game_state_popup) then
		updatecontroller(framecounter)
		if (controllerbuttonup(button_action)) then
			gamestate = game_state_playing
			for line in all(cam.popuptext) do del(cam.popuptext, line) end
		end

	-- move only camera
	elseif (gamestate == game_state_camtransition) then
		if (cam.x == cam.targetx and cam.y == cam.targety) then
			gamestate = game_state_playing
			for unit in all(tmpunitlist) do del(tmpunitlist, unit) end
		end

	-- game finished !
	elseif (gamestate == game_state_end) then
	end

	updatecameraposition()
end

function _draw()
	-- clear screen, place camera, and draw background
	cls()
	camera(cam.x, cam.y)
	map(0, 0, 0, 0, 128, 48)

	-- draw all unit (first due to particle under player sprite)
	for unit in all(unitlist) do
		drawunit(unit)
	end
	for unit in all(tmpunitlist) do
		drawunit(unit)
	end

	-- draw player base on player animation state machine
	if (player.visible) then
		-- jetpack sprite
		if (player.state == unit_state_djump) then
			spr(234, player.positionx - 8*player.direction, player.positiony+3, 1, 1, (player.direction < 0))
		end

		-- player sprite based on animation state
		spr(player.animations[player.state].start + player.pose, player.positionx, player.positiony, player.sizex, player.sizey, (player.direction < 0))

		-- helmet / head dammage
		if (player.healthpoint > 2) then
			if (player.direction > 0) then line(player.positionx+1, player.positiony, player.positionx+3, player.positiony, 12)
			else line(player.positionx+4, player.positiony, player.positionx+6, player.positiony, 12) end
		elseif (player.healthpoint == 1) then
			if (player.direction > 0) then line(player.positionx+1, player.positiony, player.positionx+3, player.positiony, 8)
			else line(player.positionx+4, player.positiony, player.positionx+6, player.positiony, 8) end
		end
		
		-- gun charging and fire shoot sprite
		if (player.action == unit_state_shooting) then
			spr(253, player.positionx + player.direction*8*player.sizex, player.positiony, 1, 1, (player.direction > 0))
		elseif (player.action == unit_state_charging) then
			if (framecounter - player.shoottime > constant_chargeshoottime) then
				line(player.positionx+3, player.positiony+3, player.positionx+4, player.positiony+3, 3)
			elseif (framecounter - player.shoottime > constant_chargeshoottime/2) then
				pset(player.positionx+3, player.positiony+3, 3)
			end
		end
	end

	-- draw popup if needed
	if (gamestate == game_state_popup) then
		drawpopup()
	end

	print(flr((player.positionx+4)/8), player.positionx, player.positiony - 12)
	print(flr((player.positiony+4)/8), player.positionx, player.positiony - 6)

	--print(count(unitlist), player.positionx, player.positiony - 6)
end



-- ************************************************************************ player functions ************************************************************************
-- initialize the player special unit
function initializeplayer()
	player = newunit(7*8, 14*8, 1, 1, unit_type_player, newanimation(17, 2, 30))
	player.healthpoint = 3
	player.djumpavailable = true
	player.shoottime = 0
	player.action = unit_state_idle
	player.framedammage = 0
	player.dammagetime = 0

	player.shootenable = false
	player.djumpenable = false
	player.chargeshootenable = false

	-- attach more animation
	player.animations[unit_state_dead] = newanimation(20, 1, 5)
	player.animations[unit_state_walk] = newanimation(18, 2, 2)
	player.animations[unit_state_jump] = newanimation(20, 1, 5)
	player.animations[unit_state_djump] = newanimation(20, 1, 5)
	player.animations[unit_state_falling] = newanimation(20, 1, 5)
end

-- reset player state
function resetplayer()
	player.positionx = 7*8
	player.positiony = 14*8
	player.speedx = 0
	player.speedy = 0
	player.state = unit_state_idle
	player.action = unit_state_idle
	player.healthpoint = 3
	player.direction = 1
	player.pose = 0
	player.dammagetime = 0
	player.visible = true
	player.framedammage = 0
	player.djumpavailable = true
	player.shoottime = 0

	player.shootenable = false
	player.djumpenable = false
	player.chargeshootenable = false
end

function setplayerposition(x, y)
	player.positionx = x
	player.positiony = y

	local found = false
	for i = 1, 16 do -- check all room
		if (inroom(x, y, i)) then
			currentroom = i
			found = true
			break
		end
	end
	if (not found) then
		player.positionx = 7*8
		player.positiony = 14*8
		currentroom = 1
	end
	updatecameraposition()
	initializeroom(currentroom)
end

-- the player state machine
function updateplayerstate()
	-- begin
	local pstate = player.state
	player.statetime += 1
	player.speedx = 0

	-- idle
	if(player.state == unit_state_idle) then
		player.djumpavailable = true
		if (controllerbuttondown(button_jump)) then
			player.speedy = constant_jumpspeed
			player.traversable = true
			player.state = unit_state_jump
		elseif (controllerbuttonispressed(button_right) or controllerbuttonispressed(button_left)) then player.state = unit_state_walk
		end

	-- walk
	elseif(player.state == unit_state_walk) then
		player.djumpavailable = true
		if (controllerbuttonispressed(button_right)) then player.speedx = constant_walkspeed
		elseif (controllerbuttonispressed(button_left)) then player.speedx = -constant_walkspeed end
		if (controllerbuttondown(button_jump)) then
			player.speedy = constant_jumpspeed
			player.traversable = true
			player.state = unit_state_jump
		end
		if (player.state == unit_state_walk and player.speedx == 0) then player.state = unit_state_idle end

	-- jump
	elseif(player.state == unit_state_jump) then
		if (controllerbuttonispressed(button_right)) then player.speedx = constant_walkspeed
		elseif (controllerbuttonispressed(button_left)) then player.speedx = -constant_walkspeed end
		if (controllerbuttondown(button_jump) and player.djumpavailable and player.djumpenable) then
			player.speedy = constant_jumpspeed
			player.traversable = true
			player.state = unit_state_djump
			player.djumpavailable = false
		end
		if (player.speedy >= 0) then
			player.state = unit_state_falling
			player.traversable = false
		end

	-- double jump
	elseif(player.state == unit_state_djump) then
		if (count(unitlist) < 15) then
			local smoke = initializeparticule(player.positionx, player.positiony, newanimation(240, 1, 5), 7)
			smoke.direction = -player.direction
		end

		if (controllerbuttonispressed(button_right)) then player.speedx = constant_walkspeed
		elseif (controllerbuttonispressed(button_left)) then player.speedx = -constant_walkspeed
		end
		if (player.speedy >= 0) then
			player.state = unit_state_falling
			player.traversable = false
		end

	-- falling
	elseif(player.state == unit_state_falling) then
		player.traversable = false
		if (controllerbuttonispressed(button_right)) then player.speedx = constant_walkspeed
		elseif (controllerbuttonispressed(button_left)) then player.speedx = -constant_walkspeed end
		if (controllerbuttondown(button_jump) and player.djumpavailable and player.djumpenable) then
			player.speedy = constant_jumpspeed
			player.traversable = true
			player.state = unit_state_djump
			player.djumpavailable = false
		elseif (player.speedy <= 0) then
			player.state = unit_state_idle
		end
	end

	-- end and animation update
	if (player.state != unit_state_falling and player.speedy > 0) then
		player.state = unit_state_falling
		player.traversable = false
	end
	if (player.state != pstate) then player.statetime = 0 end
	if (player.speedx > 0) then player.direction = 1
	elseif (player.speedx < 0) then player.direction = -1 end
	player.pose = flr(player.statetime / player.animations[player.state].time) % player.animations[player.state].frames
end

-- the player action state machine
function updateplayeraction()
	player.action = unit_state_idle
	if (not player.shootenable) then
	elseif (controllerbuttondown(button_action)) then
		player.shoottime = controllergetstatechangetime(button_action)
	elseif (controllerbuttonup(button_action)) then
		if (controllergetstatechangetime(button_action) - player.shoottime > constant_chargeshoottime and player.chargeshootenable) then
			local bullet = initializeparticule(player.positionx + player.direction*(8*player.sizex - 2) - player.direction*5, player.positiony+1, newanimation(249, 1, 5), 50)
			bullet.speedx = player.direction*5
			bullet.sizey = 0.7
			bullet.damage = 3
			bullet.direction = player.direction
			bullet.gravityafected = false
			bullet.traversable = true
		else
			local bullet = initializeparticule(player.positionx + player.direction*(8*player.sizex - 2) - player.direction*10, player.positiony, newanimation(250, 1, 5), 50)
			bullet.speedx = player.direction*10
			bullet.sizey = 0.7
			bullet.damage = 1
			bullet.direction = player.direction
			bullet.gravityafected = false
			bullet.traversable = true
		end

		if(player.state == unit_state_idle) then
			player.pose = 1
			player.statetime = 0
		end
		player.shoottime = 0
		player.action = unit_state_shooting
	elseif (controllerbuttonispressed(button_action)) then
		player.statetime = 0
		player.action = unit_state_charging
	end

	if (controllerbuttonispressed(button_down)) then player.traversable = true end
end

-- the player dammage machine state function
function updateplayerdammage()
	if (player.dammagetime == 0) then
		if (player.framedammage > 0) then
			--player.healthpoint -= 1
			player.dammagetime += 1
			player.visible = false

			local impact = initializeparticule(player.positionx, player.positiony, newanimation(221, 3, 3), 9)
			impact.pose = 3
			impact.speedx = player.speedx
			impact.speedy = player.speedy
			impact.environementafected = false
			impact.gravityafected = true
		end
	elseif (player.dammagetime >= constant_invulnerabilitytime) then
		player.dammagetime = 0
		player.visible = true
	else
		player.dammagetime += 1
		player.visible = not player.visible
	end

	player.framedammage = 0
	if (player.healthpoint <= 0) then player.state = unit_state_dead end
end



-- ************************************************************************ ennemy functions ************************************************************************
-- initialize walker ennemy
function initializewalker(x, y)
	local ennemy  = newunit(x, y, 1, 1, ennemy_walker, newanimation(49, 2, 17))
	ennemy.healthpoint = 1
	ennemy.targetx = x
	ennemy.targety = y
	ennemy.targetdistance = 0
	ennemy.damage = 1

	-- behaviour
	ennemy.update = updatewalker
	ennemy.controller = controllerwalker

	-- attach more animation
	ennemy.animations[unit_state_dead] = newanimation(49, 1, 1)
	ennemy.animations[unit_state_walk] = newanimation(50, 2, 7)
	add(unitlist, ennemy)
end

function controllerwalker(unit)
	-- avoid falling
	if (unit.speedx > 0 and not checkflag(unit.positionx + 7, unit.positiony + 8, flag_solid) and not checkflag(unit.positionx + 7, unit.positiony + 8, flag_traversable)) then
		unit.direction = -unit.direction
	elseif (unit.speedx < 0 and not checkflag(unit.positionx, unit.positiony + 8, flag_solid) and not checkflag(unit.positionx, unit.positiony + 8, flag_traversable)) then
		unit.direction = -unit.direction

	-- avoid wall collision
	elseif (unit.speedx > 0 and (checkflag(unit.positionx + 8, unit.positiony + 7, flag_solid) or checkflag(unit.positionx + 8, unit.positiony + 7, flag_traversable))) then
		unit.direction = -unit.direction
	elseif (unit.speedx < 0 and (checkflag(unit.positionx - 1, unit.positiony + 7, flag_solid) or checkflag(unit.positionx - 1, unit.positiony + 7, flag_traversable))) then
		unit.direction = -unit.direction

	-- avoid exit room
	elseif (unit.speedx > 0 and not inroom(unit.positionx + 8, unit.positiony + 7, currentroom)) then
		unit.direction = -unit.direction
	elseif (unit.speedx < 0 and not inroom(unit.positionx - 1, unit.positiony + 7, currentroom)) then
		unit.direction = -unit.direction
	end
end

function updatewalker(unit)
	local pstate = unit.state
	unit.statetime += 1

	unit.state = unit_state_walk
	unit.speedx = -unit.direction * constant_walkerspeed

	-- end
	if (unit.state != pstate) then unit.statetime = 0 end
	unit.pose = flr(unit.statetime / unit.animations[unit.state].time) % unit.animations[unit.state].frames
end



-- initialize jumper ennemy
function initializejumper(x, y)
	local ennemy  = newunit(x, y, 2, 2, ennemy_jumper, newanimation(10, 2, 20))
	ennemy.healthpoint = 3
	ennemy.targetx = x
	ennemy.targety = y
	ennemy.targetdistance = 0
	ennemy.damage = 1

	-- behaviour
	ennemy.update = updatejumper
	ennemy.controller = controllerjumper

	-- attach more animation
	ennemy.animations[unit_state_dead] = newanimation(10, 2, 20)
	ennemy.animations[unit_state_jump] = newanimation(14, 1, 1)
	add(unitlist, ennemy)
end

function controllerjumper(unit)
	local d = distance(unit, player)
	if (d <= 40 and d >= 4) then
		unit.targetx = player.positionx
		unit.targety = player.positiony
		unit.targetdistance = d
	elseif (unit.statetime > constant_random_behaviour) then
		unit.targetx = unit.positionx - 16 + rnd(32)
		unit.targety = unit.positiony
		unit.targetdistance = abs(unit.targetx - unit.positionx)
		unit.statetime = 0
	end
end

function updatejumper(unit)
	local pstate = unit.state
	unit.statetime += 1

	if (unit.state == unit_state_idle) then
		unit.speedx = 0
		if (abs(unit.targetx - unit.positionx) > 4) then
			unit.state = unit_state_jump
			unit.speedy = -constant_jumperspeedy
		end
	elseif (unit.state == unit_state_jump) then
		if (unit.targetx - unit.positionx > 4) then
			unit.speedx = constant_jumperspeedx
		elseif (unit.targetx - unit.positionx < -4) then
			unit.speedx = -constant_jumperspeedx
		else unit.speedx = 0 end

		if (checkflag(unit.positionx-1, unit.positiony + 8*unit.sizey, flag_solid) or checkflag(unit.positionx + 8*unit.sizex -2, unit.positiony + 8*unit.sizey, flag_solid) ) then
			unit.state = unit_state_idle
		elseif (checkflag(unit.positionx-1, unit.positiony + 8*unit.sizey, flag_traversable) or checkflag(unit.positionx + 8*unit.sizex -2, unit.positiony + 8*unit.sizey, flag_traversable) ) then
			unit.state = unit_state_idle
		end
	end

	-- end
	if (unit.speedy < 0) then unit.traversable = true end
	if (unit.state != pstate) then unit.statetime = 0 end
	if (unit.speedx > 0) then unit.direction = -1
	elseif (unit.speedx < 0) then unit.direction = 1 end
	unit.pose = flr(unit.statetime / unit.animations[unit.state].time) % unit.animations[unit.state].frames
end



-- initialize flyer ennemy
function initializeflyer(x, y)
	local ennemy  = newunit(x, y, 2, 2, ennemy_jumper, newanimation(44, 2, 20))
	ennemy.healthpoint = 3
	ennemy.targetx = x
	ennemy.targety = y
	ennemy.targetdistance = 0
	ennemy.damage = 1
	ennemy.gravityafected = false

	-- behaviour
	ennemy.update = updateflyer
	ennemy.controller = controllerflyer

	-- attach more animation
	ennemy.animations[unit_state_dead] = newanimation(44, 2, 20)
	ennemy.animations[unit_state_walk] = newanimation(44, 2, 10)
	add(unitlist, ennemy)
end

function controllerflyer(unit)
	local d = distance(unit, player)
	if (d <= 64 and d >= 4) then
		unit.targetx = player.positionx
		unit.targety = player.positiony
		unit.targetdistance = d
	elseif (unit.statetime > constant_random_behaviour) then
		unit.targetx = unit.positionx - 16 + rnd(32)
		unit.targety = unit.positiony
		unit.targetdistance = abs(unit.targetx - unit.positionx)
		unit.statetime = 0
	end
end

function updateflyer(unit)
	local pstate = unit.state
	unit.statetime += 1

	if (unit.state == unit_state_idle) then
		if (unit.targetdistance > 4) then
			unit.state = unit_state_walk
		end
	elseif(unit.state == unit_state_walk) then
		if (unit.targetx - unit.positionx > 4) then
			unit.speedx = constant_flyerspeed
		elseif (unit.targetx - unit.positionx < -4) then
			unit.speedx = -constant_flyerspeed
		else unit.speedx = 0 end

		if (unit.targety - unit.positiony > 4) then
			unit.speedy = constant_flyerspeed
		elseif (unit.targety - unit.positiony < -4) then
			unit.speedy = -constant_flyerspeed
		else unit.speedy = 0 end

		if (unit.targetdistance < 4) then unit.state = unit_state_idle end
	end

	-- end
	if (unit.state != pstate) then unit.statetime = 0 end
	if (unit.speedx > 0) then unit.direction = -1
	elseif (unit.speedx < 0) then unit.direction = 1 end
	unit.pose = flr(unit.statetime / unit.animations[unit.state].time) % unit.animations[unit.state].frames
end



-- ************************************************************************ particles and particule generators functions ************************************************************************
-- initialize particle
function initializeparticule(x, y, idleanimation, life)
	local particule = newunit(x, y, 1, 1, unit_type_particule, idleanimation)
	particule.life = life
	particule.update = updateparticle
	particule.environementafected = true
	add(unitlist, particule)
	return particule
end

-- update function for particles
function updateparticle(unit)
	unit.life -= 1
	unit.pose = flr(max(unit.life, 0) / unit.animations[unit.state].time) % unit.animations[unit.state].frames
	if (unit.life <= 0) then
		unit.state = unit_state_dead
	end
end

-- initialize particle generator
-- positionate a lot of parameter in default value (to keep an initialize function small)
function initializeparticulegenerator(x, y,idleanimation, particleanimation, spawntime)
	local generator = newunit(x, y, 1, 1, unit_type_particule_generator, idleanimation)

	-- modifiable attribute to twick to create a full customized particule generator
	generator.plife = 50
	generator.plifedispertion = 0
	generator.panimation = particleanimation	-- particule idle animation
	generator.pgravity = false 					-- particule are affected by gravity
	generator.pspeedx = 0						-- particule initial speed on x axis
	generator.pspeedy = 0						-- particule initial speed on y axis
	generator.ppositionx = 0					-- particule initial position on x axis
	generator.ppositiony = 0					-- particule initial position on y axis
	generator.pdamage = 0						-- particule dammage
	generator.pdirection = 1					-- particule initial direction. zero mean that the particule direction is random
	generator.spawntime = spawntime 			-- spawn interval time
	generator.spawntimedispertion = 0			-- random interval for spawn time

	-- machine state related attributes
	generator.time = 0
	generator.nextspawntime = 0
	generator.update = updateparticulegenerator
	add(unitlist, generator)
	return generator
end

-- update particule generator
function updateparticulegenerator(unit)
	unit.time += 1
	unit.pose = flr(unit.time / unit.animations[unit.state].time) % unit.animations[unit.state].frames

	if (unit.time >= unit.nextspawntime) then
		local particule = initializeparticule(unit.positionx + unit.ppositionx, unit.positiony + unit.ppositiony, unit.panimation, unit.plife + rnd(unit.plifedispertion))
		particule.gravityafected = unit.pgravity
		particule.speedx = unit.pspeedx
		particule.speedy = unit.pspeedy
		particule.damage = unit.pdamage

		if (unit.pdirection == 0) then particule.direction = 3*rnd(1)-1
		else particule.direction = unit.pdirection end

		unit.time = 0
		unit.nextspawntime = unit.spawntime - rnd(unit.spawntimedispertion)
	end
end

-- place standard firework (generate some smoke)
function placefire(x, y)
	local fire = initializeparticulegenerator(x, y, newanimation(203,2,5), newanimation(240, 2, 10), 15)
	fire.gravityafected = false
	fire.pspeedy = -1
	fire.plife = 20
	fire.plifedispertion = 20
	fire.spawntimedispertion = 4
	fire.damage = 1
	fire.pdirection = 0

	fire.pose = rnd(1)
	fire.time = rnd(fire.spawntime)
	fire.nextspawntime = rnd(fire.spawntime) + rnd(fire.spawntimedispertion)
end

-- place standard acid block (generate some buble)
function placeacid(x, y)
	local acid = initializeparticulegenerator(x, y, newanimation(224,2,20), newanimation(219, 2, 3), 100)
	acid.gravityafected = false
	acid.plife = 6
	acid.spawntimedispertion = 40
	acid.ppositiony = -8
	acid.damage = 1

	acid.pose = rnd(1)
	acid.time = rnd(acid.spawntime)
	acid.nextspawntime = rnd(acid.spawntime) + rnd(acid.spawntimedispertion)
end



-- ************************************************************************ room system functions ************************************************************************
-- reset room system
function resetroomsystem()
	for unit in all(unitlist) do del(unitlist, unit) end
	for unit in all(tmpunitlist) do del(tmpunitlist, unit) end
	currentroom = 1
	initializeroom(currentroom)
end

-- initialize room : place unit of correct type to correct position depending of the room structure
function initializeroom(room)
	newunitlist = rooms[room][6]
	for i = 1, count(newunitlist) do
		if (newunitlist[i][3] == generator_fire) then placefire(newunitlist[i][1], newunitlist[i][2])
		elseif (newunitlist[i][3] == generator_acid) then placeacid(newunitlist[i][1], newunitlist[i][2])
		elseif (newunitlist[i][3] == ennemy_walker) then initializewalker(newunitlist[i][1], newunitlist[i][2])
		elseif (newunitlist[i][3] == ennemy_jumper) then initializejumper(newunitlist[i][1], newunitlist[i][2])
		elseif (newunitlist[i][3] == ennemy_flyer) then initializeflyer(newunitlist[i][1], newunitlist[i][2])
		elseif (newunitlist[i][3] == unit_type_scenario) then
			local item = scenario[newunitlist[i][4]]
			if (item and not item[2]) then
				placescenario(newunitlist[i][1], newunitlist[i][2], item[1], newunitlist[i][4])
			end
		end
	end
end

-- update current room depending on player position
function updateroom()
	if (mid(player.positionx, rooms[currentroom][1], rooms[currentroom][1] + rooms[currentroom][3]) == player.positionx) and (mid(player.positiony, rooms[currentroom][2], rooms[currentroom][2] + rooms[currentroom][4]) == player.positiony) then
		return
	else 
		for i = 1, count(rooms[currentroom][5]) do
			local r = rooms[currentroom][5][i]
			if (mid(player.positionx, rooms[r][1], rooms[r][1] + rooms[r][3]) == player.positionx) and (mid(player.positiony, rooms[r][2], rooms[r][2] + rooms[r][4]) == player.positiony) then
	   			currentroom = r
	   			break
	   		end
		end

		-- swap tmpunitlist and unitlist
		tmpunitlist, unitlist = unitlist, tmpunitlist
		initializeroom(currentroom)
		gamestate = game_state_camtransition

		cam.targetx = mid(player.positionx - 64, rooms[currentroom][1], rooms[currentroom][1] + rooms[currentroom][3] - 128)
		cam.targety = mid(player.positiony - 64, rooms[currentroom][2], rooms[currentroom][2] + rooms[currentroom][4] - 128)
	end
end



-- ************************************************************************ scenario functions ************************************************************************
-- place a scenario block (a chest with a sprite floating on top)
-- has to reference a index on scenario table to have acces to additionnal parameter
function placescenario(x, y, sprite, index)
	local block = initializeparticulegenerator(x, y, newanimation(32,1,1), newanimation(sprite, 1, 1), 60)
	block.type = unit_type_scenario
	block.plife = block.spawntime+1
	block.pdirection = 0
	block.index = index
end

-- initialize scenario for the current game
-- all scenario item referenced by the scenario table are positionate as unpicked
function resetscenario()
	for item in all(scenario) do
		item[2] = false
	end
end




-- ************************************************************************ physics functions ************************************************************************
-- move object to delta and check collision with environement
function updatephysics(unit, step)
	local collisionthreshold = 1
	local gravity = 0.4

	-- aply gravity if unit is not touching ground
	if (unit.gravityafected) then
		if (checkflag(unit.positionx + collisionthreshold, unit.positiony + 8*unit.sizey, flag_solid) or
			checkflag(unit.positionx + 8*unit.sizex - 1 - collisionthreshold, unit.positiony + 8*unit.sizey, flag_solid) ) then
		elseif (not unit.traversable and (checkflag(unit.positionx + collisionthreshold, unit.positiony + 8*unit.sizey, flag_traversable) or
										  checkflag(unit.positionx + 7 - collisionthreshold, unit.positiony + 8, flag_traversable) )) then
		else
			unit.speedy += step*gravity
		end
	end

	if (_colisionmatrix[type_environement][unit.type]) then
		-- check left and right collision with environement
		if (unit.speedx > 0) then
			if (checkflag(unit.positionx + 8*unit.sizex - 1 + step*unit.speedx, unit.positiony + collisionthreshold, flag_solid) or
				checkflag(unit.positionx + 8*unit.sizex - 1 + step*unit.speedx, unit.positiony + 8*unit.sizey - 1 - collisionthreshold, flag_solid) ) then
				_colisionmatrix[type_environement][unit.type](unit, flag_solid, "x")

			elseif (not unit.traversable and (checkflag(unit.positionx + 8*unit.sizex - 1 + step*unit.speedx, unit.positiony + collisionthreshold, flag_traversable) or
											  checkflag(unit.positionx + 8*unit.sizex - 1 + step*unit.speedx, unit.positiony + 8*unit.sizey - 1 - collisionthreshold, flag_traversable) )) then
				_colisionmatrix[type_environement][unit.type](unit, flag_traversable, "x")
			else
				unit.positionx += step*unit.speedx
			end
		elseif (unit.speedx < 0) then
			if (checkflag(unit.positionx + step*unit.speedx, unit.positiony + collisionthreshold, flag_solid) or checkflag(unit.positionx + step*unit.speedx, unit.positiony + 8*unit.sizey - 1 - collisionthreshold, flag_solid) ) then
				_colisionmatrix[type_environement][unit.type](unit, flag_solid, "x")
			elseif (not unit.traversable and (checkflag(unit.positionx + step*unit.speedx, unit.positiony + collisionthreshold, flag_traversable) or checkflag(unit.positionx + step*unit.speedx, unit.positiony + 8*unit.sizey - 1 - collisionthreshold, flag_traversable) )) then
				_colisionmatrix[type_environement][unit.type](unit, flag_traversable, "x")
			else
				unit.positionx += step*unit.speedx
			end
		end

		-- check up and down collision with environement
		if (unit.speedy > 0) then
			if (checkflag(unit.positionx + collisionthreshold, unit.positiony + 8*unit.sizey - 1 + step*unit.speedy, flag_solid) or checkflag(unit.positionx + 8*unit.sizex - 1 - collisionthreshold, unit.positiony + 8*unit.sizey - 1 + step*unit.speedy, flag_solid) ) then
				_colisionmatrix[type_environement][unit.type](unit, flag_solid, "y")
			elseif (not unit.traversable and (checkflag(unit.positionx + collisionthreshold, unit.positiony + 8*unit.sizey - 1 + step*unit.speedy, flag_traversable) or checkflag(unit.positionx + 8*unit.sizex - 1 - collisionthreshold, unit.positiony + 8*unit.sizey - 1 + step*unit.speedy, flag_traversable) )) then
				_colisionmatrix[type_environement][unit.type](unit, flag_traversable, "y")
			else
				unit.positiony += step*unit.speedy
			end
		elseif (unit.speedy < 0) then
			if (checkflag(unit.positionx + collisionthreshold, unit.positiony + step*unit.speedy, flag_solid) or checkflag(unit.positionx + 8*unit.sizex - 1 - collisionthreshold, unit.positiony + step*unit.speedy, flag_solid) ) then
				_colisionmatrix[type_environement][unit.type](unit, flag_solid, "y")
			elseif (not unit.traversable and (checkflag(unit.positionx + collisionthreshold, unit.positiony + step*unit.speedy, flag_traversable) or checkflag(unit.positionx + 8*unit.sizex - 1 - collisionthreshold, unit.positiony + step*unit.speedy, flag_traversable) )) then
				_colisionmatrix[type_environement][unit.type](unit, flag_traversable, "y")
			else
				unit.positiony += step*unit.speedy
			end

		-- speed null so repositionate unit in a good way to avoid overlay on y axis (repositionate on top of the nearest plateform)
		else
			if (checkflag(unit.positionx + collisionthreshold, unit.positiony + 8*unit.sizey - 1, flag_solid) or checkflag(unit.positionx + 8*unit.sizex - 1 - collisionthreshold, unit.positiony + 8*unit.sizey - 1, flag_solid) ) then
				unit.positiony -= 1
			elseif (not unit.traversable and (checkflag(unit.positionx + collisionthreshold, unit.positiony + 8*unit.sizey - 1, flag_traversable) or checkflag(unit.positionx + 8*unit.sizex - 1 - collisionthreshold, unit.positiony + 8*unit.sizey - 1, flag_traversable) )) then
				unit.positiony -= 1
			end
		end
	else
		unit.positionx += step*unit.speedx
		unit.positiony += step*unit.speedy
	end
end

-- environement collision callbacks
function callbackphysicsenvironementunit(unit, blockflag, colisionaxis)
	if (colisionaxis == "x") then
		unit.speedx = 0
	else
		unit.speedy = 0
	end
end
function callbackphysicsenvironementparticule(unit, blockflag, colisionaxis)
	if (colisionaxis == "x" and unit.environementafected) then
		if (unit.damage > 0) then
			if (unit.damage >= 3) then
				if (unit.speedx > 0) then
					if (checkflag(unit.positionx + 8, unit.positiony + 3, flag_destructible) or checkflag(unit.positionx + 8, unit.positiony + 7 - 3, flag_destructible) ) then
						destroy(unit.positionx + 8, unit.positiony + 3)
					end
				elseif (unit.speedx < 0) then
					if (checkflag(unit.positionx - 1, unit.positiony + 3, flag_destructible) or checkflag(unit.positionx - 1, unit.positiony + 7 - 3, flag_destructible) ) then
						destroy(unit.positionx - 1, unit.positiony + 3)
					end
				end
			end
			local dead = initializeparticule(unit.positionx, unit.positiony, newanimation(251, 5, 1), 5)
			dead.gravityafected = false
			dead.direction = unit.direction
		end

		unit.speedx = 0
		unit.life = 0
		unit.visible = false
	else
		unit.speedy = 0
	end
end



-- ************************************************************************ unit collision functions ************************************************************************
-- initialize collision callbacks matrix
function initializecollision()
	_colisionmatrix = {}
	for i = 1, 11 do
		_colisionmatrix[i] = {}
		for j = 1, 11 do
			_colisionmatrix[i][j] = nil
		end
	end

	_colisionmatrix[type_environement][unit_type_player] = callbackphysicsenvironementunit				-- [1][2]
	_colisionmatrix[type_environement][unit_type_particule] = callbackphysicsenvironementparticule		-- [1][3]
	_colisionmatrix[type_environement][unit_type_particule_generator] = callbackphysicsenvironementunit	-- [1][4]
	_colisionmatrix[type_environement][unit_type_scenario] = callbackphysicsenvironementunit			-- [1][5]
	_colisionmatrix[type_environement][generator_fire] = callbackphysicsenvironementunit				-- [1][6]
	_colisionmatrix[type_environement][generator_acid] = callbackphysicsenvironementunit				-- [1][7]
	_colisionmatrix[type_environement][ennemy_walker] = callbackphysicsenvironementunit					-- [1][8]
	_colisionmatrix[type_environement][ennemy_jumper] = callbackphysicsenvironementunit					-- [1][9]
	_colisionmatrix[type_environement][ennemy_flyer] = callbackphysicsenvironementunit					-- [1][10]

	_colisionmatrix[unit_type_player][unit_type_particule_generator] = callbackcollisionplayerennemy	-- [2][4]
	_colisionmatrix[unit_type_player][generator_fire] = callbackcollisionplayerennemy					-- [2][6]
	_colisionmatrix[unit_type_player][unit_type_scenario] = callbackcollisionplayerscenario				-- [2][5]
	_colisionmatrix[unit_type_player][generator_acid] = callbackcollisionplayerennemy					-- [2][7]
	_colisionmatrix[unit_type_player][ennemy_walker] = callbackcollisionplayerennemy					-- [2][8]
	_colisionmatrix[unit_type_player][ennemy_jumper] = callbackcollisionplayerennemy					-- [2][9]
	_colisionmatrix[unit_type_player][ennemy_flyer] = callbackcollisionplayerennemy						-- [2][10]

	_colisionmatrix[unit_type_particule][ennemy_walker] = callbackcollisionparticuleunit				-- [3][8]
	_colisionmatrix[unit_type_particule][ennemy_jumper] = callbackcollisionparticuleunit				-- [3][9]
	_colisionmatrix[unit_type_particule][ennemy_flyer] = callbackcollisionparticuleunit					-- [3][10]

	-- symetrize matrix
	for i = 1, 11 do
		for j = i, 11 do
			_colisionmatrix[j][i] = _colisionmatrix[i][j]
		end
	end
end

-- check if two unit currently collide (overlap)
function collisioncheck(unit1, unit2)
	if ( abs(unit1.positionx + 4*unit1.sizex - (unit2.positionx + 4*unit2.sizex)) < 4*(unit1.sizex + unit2.sizex) - 1 ) then
		if ( abs(unit1.positiony + 4*unit1.sizey - (unit2.positiony + 4*unit2.sizey)) < 4*(unit1.sizey + unit2.sizey) - 1 ) then
			return true
		end
	end
	return false
end

-- units collision callbacks
function callbackcollisionparticuleunit(unit1, unit2)
	-- begin
	local particule
	local unit
	if(unit1.type == unit_type_particule) then
		particule = unit1
		unit = unit2
	else
		particule = unit2
		unit = unit1
	end

	-- collision interaction
	if (particule.life > 0 and particule.damage > 0) then
		local impact = initializeparticule(unit.positionx + unit.sizex*4 - 4 + 0.2*particule.speedx, unit.positiony + unit.sizey*4 - 4 + 0.2*particule.speedy, newanimation(205, 3, 3), 9)
			impact.pose = 3
			impact.environementafected = false
			impact.speedx = particule.direction * 0.8
			impact.gravityafected = false
			impact.direction = particule.direction

		particule.speedx = 0
		particule.speedy = 0
		particule.life = 0
		unit.healthpoint -= particule.damage
		if (unit.healthpoint <= 0) then
			unit.visible = false
			unit.state = unit_state_dead
		end
	end
end
function callbackcollisionplayerennemy(unit1, unit2)
	-- begin
	local unit
	if(unit1.type == unit_type_player) then unit = unit2
	else unit = unit1 end
	player.framedammage += unit.damage
end
function callbackcollisionplayerscenario(unit1, unit2)
	-- begin
	local unit
	if(unit1.type == unit_type_player) then unit = unit2
	else unit = unit1 end
	unit.state = unit_state_dead

	local item = scenario[unit.index]
	item[2] = true
	if (item[4] == "shoot") then
		player.shootenable = true
	elseif (item[4] == "djump") then
		player.djumpenable = true
	elseif (item[4] == "cshoot") then
		player.chargeshootenable = true
	end

	if (count(item[3])) then
		cam.popuptext = item[3]
		gamestate = game_state_popup
	end
end

-- ************************************************************************ rendering functions ************************************************************************
function drawunit(unit)
	if (unit.visible) then
		local sx = flr(unit.sizex + 0.5)
		local sy = flr(unit.sizey + 0.5)
		spr(unit.animations[unit.state].start + unit.pose*sx, unit.positionx, unit.positiony, sx, sy, (unit.direction < 0))
	end
end

function drawpopup()
	local w = 80
	local h = max(30, 10*count(cam.popuptext))

	rect(cam.x + 63 - w/2, cam.y + 63 - h/2, cam.x + 65 + w/2, cam.y + 65 + h/2, 12)
	rectfill(cam.x + 64 - w/2, cam.y + 64 - h/2, cam.x + 64 + w/2, cam.y + 64 + h/2, 0)
	for i = 1, count(cam.popuptext) do
		print(cam.popuptext[i], cam.x + 64 - 2.0 * #cam.popuptext[i] + 1, cam.y + 60 - h/2 + 8*i, 7)
	end
end

function initializecamera()
	cam.x = 0
	cam.y = 0
	cam.targetx = 0
	cam.targety = 0
	cam.speed = 5.0
	cam.popuptext = {}
end

function updatecameraposition()
	if (gamestate == game_state_camtransition) then
		local dx = cam.targetx - cam.x
		local dy = cam.targety - cam.y
		local d = sqrt(dx*dx + dy*dy)
		if(d < cam.speed) then
			cam.x = cam.targetx
			cam.y = cam.targety
		else
			cam.x += cam.speed * dx / d
			cam.y += cam.speed * dy / d
		end
	else
		cam.x = mid(player.positionx - 64, rooms[currentroom][1], rooms[currentroom][1] + rooms[currentroom][3] - 128)
		cam.y = mid(player.positiony - 64, rooms[currentroom][2], rooms[currentroom][2] + rooms[currentroom][4] - 128)
	end
end



-- ************************************************************************ controller functions ************************************************************************
-- initialize the controller structure
function initializecontroller()
	_controllerbuttonmap = {}
	for i = 1, 6 do
		_controllerbuttonmap[i] = {}
		_controllerbuttonmap[i].previous = false
		_controllerbuttonmap[i].state = false
		_controllerbuttonmap[i].time = 0
	end
end

-- initialize the controller structure (as constructor in c++)
function resetcontroller()
	for i = 1, 6 do
		_controllerbuttonmap[i].previous = false
		_controllerbuttonmap[i].state = false
	end
end

-- update all button state. parameter define the current frame
-- if a button changing state is detected this time will be refered as the changing state time for the button
function updatecontroller(time)
	for i = 1, 6 do
		_controllerbuttonmap[i].previous = _controllerbuttonmap[i].state
		_controllerbuttonmap[i].state = btn(i-1)
		if (_controllerbuttonmap[i].previous != _controllerbuttonmap[i].state) then
			_controllerbuttonmap[i].time = time
		end
		controllerbuttonup(i-1)
		controllerbuttondown(i-1)
		controllerbuttonispressed(i-1)
		controllergetstatechangetime(i-1)
	end
end

-- draw all state of button, all previous state and all change time
function debugcontroller()
	for i = 1, 6 do
		local value = "false"
		if (_controllerbuttonmap[i].state) then value = "true" end
		print(value,0,8*i)

		local pvalue = "false"
		if (_controllerbuttonmap[i].previous) then pvalue = "true" end
		print(pvalue,30,8*i)

		print(_controllerbuttonmap[i].time,60,8*i)
	end
end

-- return boolean true if button state change from pressed to up this frame 
function controllerbuttonup(button) return (not _controllerbuttonmap[button+1].state and _controllerbuttonmap[button+1].previous) end

-- return boolean true if button state change from up to pressed this frame
function controllerbuttondown(button) return (_controllerbuttonmap[button+1].state and not _controllerbuttonmap[button+1].previous) end

-- return boolean true if button state is pressed
function controllerbuttonispressed(button) return _controllerbuttonmap[button+1].state end

-- return time (in frame) when button state change. reference (zero) is programme start.
function controllergetstatechangetime(button) return _controllerbuttonmap[button+1].time end



-- ************************************************************************ utils functions ************************************************************************
function newanimation(start, frames, time)
	local dummyanim = {}
	dummyanim.start = start
	dummyanim.frames = frames
	dummyanim.time = time
	return dummyanim
end

function newunit(x, y, w, h, type, idleanimation)
	local unit = {}
	unit.type = type 									-- unit type (see at file beginig to see full type list)
	unit.positionx = x 									-- unit position on x axis
	unit.positiony = y 									-- unit position on y axis
	unit.speedx = 0										-- unit speed on x axis (could be positif or negatif)
	unit.speedy = 0										-- unit speed on y axis (could be positif or negatif)
	unit.sizex = w 										-- unit size on x axis (scale is in tile (8 pixel))
	unit.sizey = h 										-- unit size on y axis (scale is in tile (8 pixel))
	unit.direction = 1									-- unit direction. default is 1. if you want to flip unit on x axis direction is equals to -1
	unit.gravityafected = true							-- define if unit is afected by gravity
	unit.traversable = false 							-- define if unit can cross traversable plateform

	unit.state = unit_state_idle 						-- unit state
	unit.statetime = 0									-- state time elapsed since the unit change its state
	unit.damage = 0										-- unit dammage (dammage given to the player)

	unit.animations = {}								-- animations list
	unit.animations[unit_state_idle] = idleanimation	-- define idle animation
	unit.animations[unit_state_dead] = idleanimation	-- define dead animation. can be changed if you want (but define in "construcor" since it could cause a crash)
	unit.pose = 0										-- used for animation state
	unit.visible = true									-- unit is visible (or not!)

	unit.update = nil 									-- unit update function (machine state)
	unit.controller = nil 								-- unit behaviour (ia)
	return unit
end

function checkflag(x, y, flag)
	local sprite_id = mget(flr(x/8),flr(y/8))
	if (fget(sprite_id, flag)) return true
	return false
end

function destroy(x, y)
	mset(flr(x/8), flr(y/8), 0)
	local particle = initializeparticule(8*flr(x/8), 8*flr(y/8), newanimation(205,2,5), 10)
	particle.gravityafected = false

	if(checkflag(x+8, y, flag_destructible)) then destroy(x+8,y) end
	if(checkflag(x-8, y, flag_destructible)) then destroy(x-8,y) end
	if(checkflag(x, y+8, flag_destructible)) then destroy(x,y+8) end
	if(checkflag(x, y-8, flag_destructible)) then destroy(x,y-8) end
end

function inroom(x, y, room)
	if (mid(x, rooms[room][1], rooms[room][1] + rooms[room][3]) == x) and (mid(y, rooms[room][2], rooms[room][2] + rooms[room][4]) == y) then
		return true
	else return false end
end

function distance(unit1, unit2)
	local x = unit1.positionx - unit2.positionx
	local y = unit1.positiony - unit2.positiony
	return sqrt(x*x + y*y)
end



-- ************************************************************************ cartrige data/assets ************************************************************************
__gfx__
80000008000000000005055044477794497999999777774424242222222242250000000000000000000000000000000000000088888000000007788778000000
08000080000000005055505549799999797777799999997452422222242222550220002222000000000008888800000000077887778800000072827777800000
00800800000000000552550542799949999999999499992252244244442442222882882882800000007788777880000000072827778800000078887877800000
00081000000000005555255244249999999999929949992222424444424424252882888822880000007282777888000000078887888880000008888888880000
0001800000000000505525254429499994299999499992422244424444442422228888888888222000788878888880000000888888888880000eeeee88880000
00800800000000005555255244422229422222222929222422244444444244228288888668882822000888888888888000000eeee88888880000eeeee8888000
08000080000000005525222544424222424242242992244422444444424242228888e886ee8888220000eeee888888800000022eee888880000022eee8888800
800000080000000052255222442242442242242422224444224444244424444288887776777882800000022eee8888880000020eee888080000020eee8880880
5000000009990000099900000999000009990000000000002244444444444422888e7e777c7e7e800000020eee88808000000202ee8880800000202ee8800008
60000000c444c000c444c000c444c000c444c00000000000224444444444442288877c77cc7777e800000202ee88808000000202208880807222202208800880
70770700ccccc000ccd66dddccccc000ccd66ddd0000000022444444444444228887cccecc6cc7e8000002022088808000002202208808800222022288878800
90ee030accd66dddccddd46dccd66dddccddd46d0000000022424444444444220888cc208c2c67e8000022022088088000002202208808800720022088008700
40880b01ccddd46dcc4cdc00ccddd46dcc4cd0000000000052524444442424252082882080226e88000022022088088000007200200808070000002008800000
20220c0dcc4cdc000cccd000cc4cdc000c00d0000000000025244444445442552082282280222880000072002008080700000070200807000000000200080000
000000000c0cd0000c0c00000c0cd0000c00c0000000000055222222222522250282080208202288000000702208870000000000200800000000000020008000
000000000c0c00000c0c0000c000c000c00c00000000000055522222222222552280288280202288000000000200800000000000200800000000000000000000
000000000d33ddd000cc440000000000000000004422242444444422444224442444442222444424444244444444442200000000000000000000770000770000
000000000ddd66d000cc04000003b3000000c6004294244444424222444442442444424252444242444444444442242200000070000000000007887887887000
00000000d00d000000cc4400000333000000cc004244244444444422944494442444444224224244244444244244242200000777000777000087888787887000
00000000000d00000099000000036300000000004444224444444422444444442444444222242444444442444244424200007887787887700088788888887000
00000000000000000000000000000000000000004294442444422422444444242244442225242224442444244424225200087888887887000088888888878000
05c55c50000000000000000000000000000000004242249444244222444442945224422552425242222222222442422500088788888888000088887788888800
0cccccc0000000000000000000000000000000004444444444444222244944442522225225242222222222522222422500888877888888000088877878888280
05c55c50000000000000000000000000000000004442944444444422444444445522252555225252252225252222525500888778788882200088878878880280
0000600070007000000707000000000049442444494444442244444452225225222252520000667711111c1c7600000080888788788800280008887888882080
00055600070700000070700007007700449442444494429422244444552222552252222500067777cccccccc7766000080088878888828280080888888800280
005bbb60070700070707007070070000477927949977779422422424522552555222525200677777cccccccc7777602000808888888008208080208028800288
055b5556070600700706007070600770479299729777cc72222244445525555552252255007777777cccccc77277720000802080288002008080208020880028
5555b55006e8e60006e8e6006e8e6000977299929766cc6222444444555255255255525506777777777777772777760000822880208800200008208020080020
05bbb5006e8880066e888006e8880066247929942796676222444444552255555225555507277727777777277277772000020800200880000000208002800200
00555000088888e0088888e088888e00429922444299222422442444552555555525555527727277772777727277272200020880020080000002008020800000
00050000082228880822288882228888442224444222244422224444555555555555555522727727727727272772772200000080000000000000080020080000
0222222222222222222222200222222000000000000500000022222222222222222922222222220000ccc0000e10000000000000000d000d5555556600000555
244242422424244224242442242424420005000000555000022222292999992222299992922222200cc7ac000110000000d00000000010015555566600005055
224944422444942424449422244494220000000005550050224299999999229924044449999922220c77acc001d10e1000100d00000011d15555556600050555
244999244299999242999442229994420500000005550555222429992244242929404404999222220a77aac01111111de100010001d001115555666600000055
229299999999299999992922244929220500050055555055249442209940444444042094922222220c77aac0111e111000101100100011115555566600050555
292424999942444999424292249242920500500555555555494292404444044040444404992922920c777ac01111111011101000011011110555666600005055
2242424444242424442424222424242205555550555555552224409440040040404040004992222200c77c001111111111111100001111115555566600000555
0222222222222222222222200222222055555555555555552299290000000000000000044992992200077c001111111111111111111111115555566600005005
5555111555550000000000005555555555555555555500002994424029949940049949920024499200c77c00111111110000000000000000088ee8222ee88000
5511551111155000000050050555555555555555550000002999440029244400004449290444999200ca700c1111111100e0000066660000888ee22e28e88800
5516655151115000005000555555555555555555550050002299904092404000000402294449992200ca7c001111111101100100666660002828228e28e28200
55116551552155000005055505555555555555555555500029940400994004000040049944444992000a7700111111111100d01066666600028e228888e82000
555126615121550005055555055555555555555555550000299222409490044040400949042229920c0aa7001111111111000010666666600082822882e80000
5555222152215500000055550555555555555555555550002900444444040004000040444444499200c0a7001111111101000110555566668822e222e8228800
05555255221555000555555500055055555555555555550029040900400000400044000404944992000aa0001111111101100100055556662828e822e8828200
05555255221555000005555500000555555555555555500029494040000000000000000004449492000a0000111111110011110055555666222e222e22822200
00555255121555500005005555555555555555555555555022244400000040000000000000444222000000000700000000000000000000009999999999446666
00555255521550500000555555555555555555555555555022440099400040040004400499040422000002400777000000000000000000009994499999446666
005555555d1550005000055555555555555555555555550092944440440400004000404404404929000020020027670000000000000000009999949999446666
050555050dd055000005555555555555555555555555000092990900949004404040094904949929000000000007766000000000000000009999449999944666
5500550500d100000055555555555555555555555555000092922004994004000440049940442929040000000007766000000000000000009999944999944466
000005000d2100000555555555555555555555555550000099999442994040000004049924004999402000020027266000000777777700009944444999999466
00005000dd1100000005555555555555555555500500050099244400929444000044492994440499002042040027662000077777777270009999444499999446
0000500dd11111100005055555555555555550500000000092944494299499400499492242242929040240400022620000777772222670009994444499999944
00000000224299425555555505555555505550500000000022299944000000000000000004499222555555560000000007777772666627009999424499229999
000000d0242994225555555500055555505500500000000029942224000404000404004040949922555555610000000007777772666667009999424492ffff99
700000002449944255555555500555055050005000000000929929494204020400244404449949295555561100000000272777266666620099fff2f44ffffff9
0000000022992422555555550005050000000550000000002999449944044444204240449944992955556111007722202777726666666670ffffffffffffffff
0d000000244992425555555500050005000000000000500022922992224444492294440929922999555611110772666602777266666266207777777777777777
00000d00224994225555555000550000005000500500500029999922222229999999229422999992556111117726662607272666662626606666666666666666
00000007244299425005050000550050005000000505555029222929922922999222929292922292561111117762666207726666626262209994666494949496
00000000222499420000000000500000005000005555555502922222222222222222222222222920611111112762262007226662662222009949444449494949
00000000000000000000000000867787777787778777877787778777877787768677877787778777877787778777877787778777877787778777877787778776
0095000c1c2c0000000c2c0000677777877787778776960000000000000065000086778777877787778777877787768595000c2c00650000008687778777a666
86878777877787778777877787979c8c9c009d8c9c009d8c9d009c009c8c9d65958c8c9d9c9d9d9c9d005744009d9d009d9d9d9c9d574457009d9c9d9d9d8c65
009600000000000000000000d42f3f3f3f3f3f3f3f669600340000000000660086978c9d00e500000000f59c9d8c677696000000006600008697000034008566
95d4b4b4c400000000000000000000000000000000000000000000000000c5669600005444574457445445455444445455444400254545455544575455000067
87970000000000004454000064847484943e3f3f3f6595000000000000006500957e000000e593a3a3b3f50000007d6595000000006500869734000034000065
96b5b5b5b5c45c9e9e9e000000000000000000000000000000009ed4b4d4b5659500f44545454545454545454545454545454545454545454545454556000000
00000000000000253636570065000000955c3e3f3f66960000003c00000066009600000000e560727270f500005c9e6696000c2c006500960034000000000066
95b50424b564748474847484945c0000000000000000a0b0009e6474942eb566960000454545454545454527454735454545454545454545454556379e9e6474
7484940000005436363636006777877685141414141497003c000000000065009500000020603040505370550004146595000000006787970000000000000065
96b52f3f2e6777877787777685949e00000000000000a1b19e647500953e2e659500f4454527454527455600370000c6d6003747003705150037009e64747500
0000959e00003636373636009d9c8c650095000000000000000000000c1c66009644575460727272435243705500006696000000003400340000000000000066
95342e2f3f4f0000000000677685949e7c5c5c5c5c5c5c9e6475000096033e669600004537000515003700009e5c7cc7d75c5c9e000006169e5c7c6475000000
0000859400f43656004736550000006586970000000000000424000000006500953c3c4563435372725362b25644006595000c2c003400000000000000000065
673e3f2e2f3f4f0000000000677797747484748474847484750000008574847595000045009e0616000064748474847484748474847484748474847500000000
0000869700f436550057363655000066950000000000000000000000000066009600003592725230505262733c3c006696000000000000000000006494000066
8574943e2e2f3f4f00000000000017677787768777767787778777877787777696000045000c1c2c000067778777877777877787778777877787877600000000
0000959d3c00273644363636560000659600000000000000000000647474340095000000459272525372b2450000006585748474847484748474849796000065
0000857484740d9400000000000034009d9d179d9d179d9d9d9d179d9d0085659500004700000000000000008c9d473745559d8c8c8c000000009c6500000000
0086970000000035363636470000006695000000006474747474747500000000965757443545928252b2734544575766867776008677760000000000951c1c66
00000000002d0085940000000000000000003400003400000000340000000066969e5c9e0000c6d6000000000000002545560000000000000000006600000000
00958c00003c0000473627000000d46596000000047500867787778776000000963c3c3c3c3773838283363c3c3c3c6595008587750065000000008696000065
008687778776002d85940000000000000000000000000000000000000000006685748424009ec7d7000000000000f44547005754575700009e007d6500000000
00960000009e9e0000370000c5d4647596003c000034009600000000857600009500000000003546734647000000006696760000008666a6a686779700000066
0095000000671d76008594000000000000000000000000340000000000000065a686979c00041424009e000000002545572545454545550034007d6600000000
0095009e006424000000d4b464141476950000000000349500000000006600009500000000000047454555000000006585848484847586777797000000006400
00960000000000650000859400000000003400000000001700003400000000677797c50000008c9d003c7e002645454545454545450515003400006500000000
0096003400349d0000d4b5b5179d9c679700003c0000003400000000006500009500000000000000374547000000006777877787778797000000000000006600
0095000000000066000000859400000000170000340000170000170034008f3f3f7fb5b45c9e9e9e9e9e9e254545454545454556340616a63400026600000000
00959e5c5c5c5c9ed4b5b564170357000000000000000000000000000066000085949e0000b700000037440000009e5c00000000000000000000648474847500
00857484748474750000000085748474747574847584747574847484748474847484748474847484748474847484848474847484748474847484747500000000
00857484748474847484747585748474847484748474847474847484747500000085748474847484748474847484748474847484748474847484750000000000
02222222222222222222222002222220000ccc000f0000000000000000000000d2202d2002000222000000000008990000008090008000000000000000000000
2242442222424422224244222242442200c77bc000d000000000000000000000020220d0026002d0000000000009800000009890000000000000008000000000
2242424242424242424242422242424200c77ba000d00f0000777700077700000d00d0d006a60dd0000000000098000000008900000000000088080000000000
2d42244d2d42244d2d4224422d42244200c7baa00020d00007cc2c60077270000d0020d00060dd00000000000088980000898800000000080008802000008000
22dd2dddd2dd2dddd2d42dd222dd2dd2000c770000d0d00f07722660072627000d0d000d000df00000000000008aa980089aa800208000000008800000082800
0200200d0000200d0000200d020020d000077b00d020d0d022cc222007266220d000d000000faf000000000008aaaa908aaa8980000002000088080200028000
d0000d0000020000000d000000d00e00c0077c000d2020d02266622227226292000000000000f0000000000009a98a98aaa89990000000080000000000000000
0000000000000000000000000000000000c77c00222220202226222222272699000000000000000000000000988aa999aaaaa889080200000080000000000000
22222222000000000000000000000000000a700c55552225555500000000000055555555a0200020000000000000000000000000000000000000000000000000
29999922000404000000000000000000000ab00055229922222550000000002005555555000d00d0000000000000000000000000000000000000000000000000
99992299420402040000000000000000000ab700552999925222500000000d020555555500000200000000000000000003000000000000000ccc0c1000000000
22442429440444440000000000000000000cab005522999255425500000000000555555500000000000000000000300000000b000000000000ccc100000c1000
994044442244444900000000000000000000a700555249925242550000000000005555550000000000000000000000300000bab000c01001011cc000000ccc00
4444044022222999000000000000000000c070005555444254425500000000020055555500000000000000000000000000000b0000c00c0000cc0c0000010000
400400409229229900000000000000000000700005555455442555000000000205555555000000000000000000000b000ba00000cc100c0000c0100000000000
000000002222222200000000000000000000c0000555545544255500000000d0555555550000000000000000000300033bb30000000000000000000000000000
3333333333333333011111110101010100000000005554552425555000d000001111111100000000000000000000000000a77a0000077000000aa00000000000
3bb333333bb333b310111111001010100000000000555455542550502d00000011111110000000000000000009000090090000900a7007a009a77a9000000000
3b33bb3333b333b301011111000101010000000000555555542550000000000011111101000000000000700800000000a000000a070000700a7777a0000aa000
bb333bb33bb3bb33101011110000101000000000050555050440550000000000111110100000000000000790000000007000000770000007a777777a00aa7a00
3bb333b333b3b3330101011100000101000000005500550500420000200000001111010100000000000007a7000000007000000770000007a777777a00a7aa00
3b33bbb333b3bbb310101011000000100000000000000500044200000d00000011101010000f00000000007000000000a000000a070000700a7777a0000aa000
bbb3bbb33bb333b3010101010000000100000000000050004422000000000000110101010e0020000000070009000090090000900a7007a009a77a9000000000
3bbbbbbb3bbbbbbb10101010000000000000000000005004422222200000000010101010020200f0000007000000000000a77a0000077000000aa00000000000
000000000000000001010101010101010000000000000000555545a60101010100000001000000000000000000000000000003b0000000300000000000000000
0000000000000000101010101010101010000000000000005554596a10101011000000100003b330000000000000000000000000000030000000000000000000
000000000000000011010101010101010100000000000000555545a6010101110000010103bbba730003bbb3000000000000000b000000b00000030000000000
0000600000000600111010101010101010100000000000005554696a1010111100001010bbb7aaaabbbaaaaa000030000000000000000bb000000bbb000000bb
000000000000000011110101010101010101000000000000555546a6010111110001010103bbba730003bbb30000003000000003000bbb0b0003bbbb000000bb
0000050005000000111110101010101010101000000000000554696a10111111001010100003b3300000000000000000000003b000000bb00000300000000000
000000000000000011111101010101010101010000000000555546a60111111101010101000000000000000000000b0000000000000000b30000000000000000
0000000000000000111111101010101010101010000000005554596a1111111110101010000000000000000000030003000b3030000003000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04040004040040000404000404004000040400040400400004040004040040000404000404004000040400040400400004040004040040400000040004400404
04020400244404420402040024440442040204002444044204020400244404420402040024440442040204002444044204020400244404440400004000404400
04444420424044440444442042404444044444204240444404444420424044440444442042404444044444204240444404444420424044949004404040094920
44444922944409224444492294440922444449229444092244444922944409224444492294440922444449229444092244444922944409994004000440049922
22299999992294222229999999229422222999999922942222299999992294222229999999229422222999999922942222299999992294994040000004049999
29229992229292922922999222929292292299922292929229229992229292922922999222929292292299922292929229229992229292929444000044492992
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222299499400499492222
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000299442400024499200
00000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000299944000444999200
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000229990404449992200
00000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000299404004444499200
00000000000000000000000000000000000000000000000500050000000000000000000000000000000000000000000000000000000000299222400422299200
00000000000000000000000000000000000000000000000500500500000000000000000000000000000000000000000000000000000000290044444444499200
00000000000000000000000000000000000000000000000555555000000000000000000000000000000000000000000000000000000000290409000494499200
00000000000000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000294940400444949200
22220000000000000000000000000000000000000000005555555500050000000000000000000000050000555500000000000000000000222444000044422200
22222000000000000000000000000000000000000050055555555500555000000500000005000000555000550000000000000000000000224400999904042200
9922220baaab00000000000000000000000000005000555555555505550050000000000000000005550050550050000000000000000000929444400440492900
9222220baaab00000000000000000000000000000505555555555505550555050000000500000005550555555550000000000000000000929909000494992900
2222220bbbbb00000000000000000000000000050555555555555555555055050005000500050055555055555500000000000000000000929220044044292900
2922920b777b00000000000000000000000000000055555555555555555555050050050500500555555555555550000000000000000000999994422400499900
9222220b777b00000000000000000000000000055555555555555555555555055555500555555055555555555555000000000000000000992444009444049900
92992200000000000000000000000000000000000555555555555555555555555555555555555555555555555550000000000000000000929444944224292900
22222222222222222222200000000000050055555555555555555555555555555555555555555555555555555555500000000000000000299442400024499200
24244224242442242424420000000000005555555555555555555555555555555555555555555555555555555555500000000000000000299944000444999200
44942424449424244494220000000050000555555555555555555555555555555555555555555555555555555555000000000000000000229990404449992200
99999242999992429994420000000000055555555555555555555555555555555555555555555555555555555500000000000000000000299404004444499200
99299999992999999929220000000000555555555555555555555555555555555555555555555555555555555500000000000000000000299222400422299200
42444999424449994242920000000005555555555555555555555555555555555555555555555555555555555000000000000000000000290044444444499200
24242444242424442424220000000000055555555555555555555555555555555555555555555555555555050005000000000000000000290409000494499200
22222222222222222222200000000000050555555555555555555555555555555555555555555555555555000000000000000000000000294940400444949200
00000000000000000000000000000000000000555555555555555555555555555555555555555555555550000000000000000000000000222444000044422200
00000000000000000000000000000000000000055555555555555555555555555555555555555555555550000000000000000000000000224400999904042200
00000000000000000000000000000000000000555555555555555555555555555555555555555555555500000000000000000000000000929444400440492900
00000000000000000000000000000000000000055555555555555555555555555555555555555555550000000000000000000000000000929909000494992900
00000000000000000000000000000000000000055555555555555555555555555555555555555555550000000000000000000000000000929220044044292900
00000000000777777700000000000000000000055555555555555555555555555555505555555555500000000000000000000000000000999994422400499900
00000000077777777270000000000000000000000550555555555555555555500505005555555505000500000000000000000000000000992444009444049900
00000000777772222670000000000000000000000005555555555555555555000000005555555500000000000000000000000000000000929444944224292900
00000007777772666627000000000000000000000000005555222555550000000000000555555500000000000000000000000000000000222999440449922200
00000007777772666667000000000000000000000000005522992222255000000000000005555500000000000000000000000000000000299422244094992200
00000027277726666662000000000000000000000000005529999252225000000000005005550500000000000000000000000000000000929929494499492900
00000027777266666666700000000000000000000000005522999255425500000000000005050000000000000000000000000000000000299944999944992900
00000002777266666266200000000000000000000000005552499252425500000000000005000500000000000000000000000000000000229229922992299900
00000007272666662626600000000000000000000000005555444254425500000000000055000000000000000000000000000000000000299999222299999200
00000007726666626262200000000000000000000000000555545544255500000000000055005000000000000000000000000000000000292229299292229200
00000007226662662222000000000000000000000000000555545544255500000000000050000000000000000000000000000000000000029222222222292000
22222222292222222222222229222222222200000000000055545524255550000000000000000000000000000000000700000000000000000000000000000000
99992222299992299999222229999292222220000000000055545554255050000000000000000000000000000000000777000000000000000000000000000000
99229924044449999922992404444999992222000000000055555554255000000000000000000000000000000000000027670000000000000000000000000000
44242929404404224424292940440499922222000000000505550504405500000000000000000000000000000000000007766000000000000000000000000000
40444444042094994044444404209492222222000000005500550500420000000000000000000000000000000000000007766000000000000000000000000000
44044040444404444404404044440499292292000000000000050004420000000000000000000000000000000000000027266000000000000000000000000000
04004040404000400400404040400049922222000000000000500044220000000000000000000000000000000000000027662000000000000000000000000000
00000000000004000000000000000449929922000000000000500442222220000000000000000000000000000000000022620000000000000000000000000000
00000000000000000000000000000004994992222222222229222222222200000000000000000002222222222222222229222222222222222922222222222222
00000000000000000000000000000000444929299999222229999292222220000000000000000024424242242424422229999229999922222999922999992222
00000000000000000000000000000000040229999922992404444999992222000000000000000022494442244494242404444999992299240444499999229924
00000000000000000000000000000000400499224424292940440499922222000000000000000024499924429999922940440422442429294044042244242929
00000000000000000000000000000000400949994044444404209492222222000000000000000022929999999929994404209499404444440420949940444444
00000000000000000000000000000000004044444404404044440499292292000000000000000029242499994244494044440444440440404444044444044040
00000000000000000000000000000000000004400400404040400049922222000000000000000022424244442424244040400040040040404040004004004040
00000000000000000000000000000000000000000000000000000449929922000000000000000002222222222222220000000400000000000000040000000000
00000000000000000000000000000000000000000000000000000000244992000999000000000000000000222999440000000000000000000000000000000000
0400400004040004040040000404000404004000040400040400400444999200c444c00000000000000000299422244000000400000000000000000004400400
2444044204020400244404420402040024440442040204002444044449992200ccccc00000000000000000929929494404000000000000000000004000404442
4240444404444420424044440444442042404444044444204240444444499200ccd66ddd00000000000000299944999490044000000000000000004040094944
9444092244444922944409224444492294440922444449229444090422299200ccddd46d00000000000000229229929940040000000000000000000440049922
9922942222299999992294222229999999229422222999999922944444499200cc4cdc0000000000000000299999229940400000000000000000000004049922
22929292292299922292929229229992229292922922999222929204944992000c0cd00000000000000000292229299294440000000000000000000044492992
22222222222222222222222222222222222222222222222222222204449492000c0c000000000000000000029222222994994000000000000000000499492222
0000000000000000000000d2202d200000000000000000d2202d2002222222222222200000000000000000000000002224440000000000000000000024499200
0000000000000000000000020220d00000000000000000020220d024424242242424420000000000000000000000002244009900000000000000000444999200
00000000000000000000000d00d0d000000000000000000d00d0d022494442244494220000000000000000000000009294444000000000000000004449992200
00000000000000000000000d0020d000000000000000000d0020d024499924429994420000000000000000000000009299090000000000000000004444499200
00000000000000000000000d0d000d00000000000000000d0d000d22929999999929220000000000000000000000009292200400000000000000000422299200
0000000000000000000000d000d0000000000000000000d000d00029242499994242920000000000000000000000009999944200000000000000004444499200
00000000000000000000000000000000000000000000000000000022424244442424220000000000000000000000009924440000000000000000000494499200
00000000000000000000000000000000000000000000000000000002222222222222200000000000000000000000009294449400000000000000000444949200
00000000000000000000000005000000050000000000000000000000000000022222222222222000000000700007002994424000000000000000000044422200
00000000000000000050050055500000555000000005000000050000000000244242422424244200000000070070002999440000000000000002409904042200
00000000000000005000550555005005550050000000000000000000000000224944422444942200000000070700072299904000000000000020020440492900
00000000000000000505550555055505550555050000000500000000000000244999244299944200000000070600702994040000000000000000000494992900
0000000000000005055555555550555555505500000000000000000000000022929999999929220000000006e8e6002992224000000000040000004044292900
000000000000000000555555555555555555550500000005000000000000002924249999424292000000006e8880062900444400000000402000022400499900
00000000000000055555555555555555555555550555505505555000000000224242444424242200000000088888e02904090000000000002042049444049900
00000000000000000555555555555555555555555555555555555500000000022222222222222000000000082228882949404000000000040240404224292900
00000000000000555555555555555555555555555555555555555555550000000000000000000000000000022222222222222200000000000000000024499200
00000000005005555555555555555555555555555555555555555555000000000000000000000000000000244242422424244200040400400000040444999200
00000000500055555555555555555555555555555555555555555555005000000000000000000000000000224944422444942442040204440400004449992200
00000000050555555555555555555555555555555555555555555555555000000000000000000000000000244999244299999244044444949004404444499200
00000005055555555555555555555555555555555555555555555555550000000000000000000000000000229299999999299922444449994004000422299200
00000000005555555555555555555555555555555555555555555555555000000000000000000000000000292424999942444922222999994040004444499200
00000005555555555555555555555555555555555555555555555555555500000000000000000000000000224242444424242492292299929444000494499200
00000000055555555555555555555555555555555555555555555555555000000000000000000000000000022222222222222222222222299499400444949200
00000000050055555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000299442400044422200
00000000005555555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000299944009904042200
00000050000555555555555555555555555555555555555555555555555500000000000000000000000000000000000000000000000000229990400440492900
00000000055555555555555555555555555555555555555555555555550000000000000077222000000000000000000000000000000000299404000494992900
00000000555555555555555555555555555555555555555555555555550000000000000772666600000000000000000000000000000000299222404044292900
00000005555555555555555555555055555550555555555555555555500000000000007726662600000000000000000000000000000000290044442400499900
00000000055555555555555005050050050500555555555555555505000500000000007762666200000000000000000000000000000000290409009444049900
00000000050555555555550000000000000000555555555555555500000000000000002762262000000000000000000000000000000000294940404224292900
00000005555555505550500000000000000000055555555055505000000000022222222222222222222222222222222222222222222222222222220449922200
00000000055555505500500000000000000000000555555055005000000000244242422424244224242442242424422424244224242442242424424094992200
00000050055505505000500000000000000000500555055050005000000000224944422444942424449424244494242444942424449424244494244499492900
00000000050500000005500000000000000000000505000000055000000000244999244299999242999992429999924299999242999992429999929944992900
00000000050005000000000000000000000000000500050000000000000000229299999999299999992999999929999999299999992999999929992992299900
00000000550000005000500000077777770000005500000050005000000000292424999942444999424449994244499942444999424449994244492299999200
00000000550050005000000007777777727000005500500050000000000000224242444424242444242424442424244424242444242424442424249292229200
00000000500000005000000077777222267000005000000050000000000000022222222222222222222222222222222222222222222222222222222222292000
00000000000000000000000777777266662700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000777777266666700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000002727772666666200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000002777726666666670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000277726666626620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000727266666262660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000772666662626220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000722666266222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222292222222222222229222222222222222922222222222222292222222222222229222222222222222922222222222222292222222222222222222222
99992222299992299999222229999229999922222999922999992222299992299999222229999229999922222999922999992222299992299999222999992222
99229924044449999922992404444999992299240444499999229924044449999922992404444999992299240444499999229924044449999922999999229924
44242929404404224424292940440422442429294044042244242929404404224424292940440422442429294044042244242929404404224424292244242929
40444444042094994044444404209499404444440420949940444444042094994044444404209499404444440420949940444444042094994044449940444444
44044040444404444404404044440444440440404444044444044040444404444404404044440444440440404444044444044040444404444404404444044040
04004040404000400400404040400040040040404040004004004040404000400400404040400040040040404040004004004040404000400400404004004040
00000000000004000000000000000400000000000000040000000000000004000000000000000400000000000000040000000000000004000000000000000000

__gff__
0000001a1a1a1a1a00080000000000000000000000001a1a000000000000000000000000000e1a0e1a1a1a1a00000000000000000e0e1a0000080808000000000202020200000202020200000000020000000000000002020202000000020a0a0000000000000202020200000000000000020000000002020202020000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004040404000000000000001010000000040402000000000000000000000000001010000000000000000000000000000000000000000002000000000000000000
__map__
0070000000000000000000000000005668777877787778777877787778777867687877787778777877787778777867006877787778777877787778777877786700687778777877787778777877787867687778777877787778777877787778777877787778777877787778777877787778777877786700000000000000687767
00000000000000f000000000007000565900000000c8004400c800c9c8c800565900c9c800c9c8c800c900c9c8c8666a69e7000000c800c800c80000c800c956005900c9d900c800c9000000d9c80056590000000000000000000000000043000043004300004300430000430000430043430043007677670000006877790056
0000525455f1000000000045000000665849000000005263454444455500006669e70045440000000000000000d7566a59e76c6d00624544444544440000006600690000000000000000000000e90056690000000000000000000000000043000000004300000000430000000000430000430000000000766700005900000066
000054000000005255004563000000566841414200626363636363636500d75659e762636500000000c5000000d7660069e77c7d00007365536365740000d756005900c3000000000000000040414177790030000000000000000000000000000000000000000000000000000000000000430000000000007667005900000056
0000540062550062540063730000f1665900000000005363637263650000d76669006372d7404141414142e74c4d767779404142000000c5007400000000d766006900000000000000000000c8c9d900000043000000000000000000430000000000000000000000000000000000000000000000000000000056006900000066
75005363636500536500536300000056690000c700000050510073000000007679e773000000c5c5c5c5004d5b5bf2f3f3f3f3f3f4464749e700d7c0c200d7566879000000000000000000000000d746490043004300000000000000000043000000000043000000000000004300000000000000000000000076777900000056
4f5d0045550070007500007444000066584748474849006061000000006b0000000000d746484747484748495b5b5bf2f3f3f3f3f3566a59e70000000000d766590000000000000000000000000000666900430043004300000043000000000000430000430000004300000043004300000000000000000000005e5f00000066
004e00534400450063004500635455566a000000006a47484900004041484748474847485700000000000058474747474847484748576a5900000000000000566900004300000000000000000000d756694748484748474848484748484848474848474747484748474847484748474847484748474847484748474800000056
004e0000540054545400540054736566687877787778777859e700d77667000068777877787778777877787778777867687778777877787900c0c1c2e7000056590000710000000000005c4d4b5c4d66590000000000000000000000000000000000766759000000000000000000000000000000000046576877570000000066
004e006265f174007200540054740056690000c9c8c9c9c84042000000766700590000c8440000c90044000000c80056690000c90000c8000000000000c500666900e971c7c5004d4b4d5b5b5b5b5b56694141420040420043004042004300000000007659000000000000000000004647484748470056006957000000000056
00725d00f000000000f074007300006659e700524545757500c0c2000000566a690000626345754445634575000000665900004445754555754544d7c0c2d7566841414141424d5b5b5b5b5b5b5b5b66590000000000000000000000000000000000005659490043430046490000c06659000000000066005900000000004666
00524e010101f100000000000000005669e7526363636363550000d740417767590052636363636363636363550000566900626363636363727265000000d76659f3f371f3f3e25b5b5b5b5b5b43e25669474847484748474748474847484200000000667658434343465769c200005669004041414166006900000000005866
004f4e0101010100000000000000007679e762637272636365007b000000c556690062636363636363657365000000665900626363657473000000000000005669f3f343f3f3f3e25b5b5b5b5b71f37679000000000000000000000000000000000000767778777877787779000000665900000000005600590000c300000056
4f4f4e01010101000000005c4d4b4df243f473746c6d73740040414141414141790000737272737273000000000000566900627250510000c0c1c1c2e700006659f3f3f3f3f3f3f3e25b5b5b5b71f3f400000000000000000000000000000000c0c2000000430000004300000043005669414141420066006900000000000066
4f4f4e010101010001004d5b5b5b5b5bf2f3f4007c7d00000000000000000000000000c500c5007b00c5c500c5000066590073006061c50000e9e9e9e9c7e9565847484749f343f343e243e24647484749c500000000000000000000000000000000000000000043000000430000006659000000000079005900c0c200000056
4f4f4e48474747484748474847484748484748474847484748474847484748474748474847484748474847484748474869c0c1c24647484748474847484748570000687879e3f3f3f3f3f3f376777767584748474847484747484748474847484748474847484748474847484748475747490040414166006900000000000066
4f4f4e57586877787778777877787778777877787778777877787778777877787778777877786700000000000000006a5900000056000000000000000000000068787900c900e3c0c2f3f3f3f400c9566877787778777877787778777877787778777877787778777877787778777867005900000000766759000000c3000043
4f4f4e676859f3f3f3f3f3f3f4c8c9c9d9c9d9d9007500c900c900000000c900000000000000767778777877786700006900c3007677787778777877787778675900c8000000000000e3f3f3f3f40066590000000000000000000000000000000000000000000000000000000000005600584900000000666900000000000056
004f4e687879f3f3f3f3f3f3f3f400e9c5c5e900526345457544756b00e90000000000000000c8c9c87500c9c876676a597b000000000000000000c80000d75669000000000000000000c0c1c2e3f45658490000000000000000000000000000000000000000000000000000000000666879584900c300565943000000004066
00527a5b5b5bf2f3f3f3f3f3f3f3464847484748474847484748474847484748474849006c6d62636363454400c876675847484900000000000000000000d7665900000000000000c50000000000e366687900000000000000000000000000000000000000000000000000000000005659007679000000666900000000000056
527a5b5b5b5b5bf2f3f3f3464748570068777877787778777877787778777867006a69007c7d0053636363635500c95668777841414149e9000000005cc54d56690000000000c0c1c1c200000000005659000000000000000000000000000000000000000000000000000000000000665900000000c3005659000000c3000066
495b5b5b5b5b5b5b464748570000006a69c8c900c900000000c8d9c8d9c9d7560000584847484900745363d5d600d77679e70000d7764141414141425b43e26659000000000000000000000000004d66584141414141414141414141414141414142000040414141414141414141416769000000000000666900000000000056
595b5b5b46474847570000000000000059e7000000000000e90000454400d76668787778670059c5c50074e5e6c50000000000004df2f3f3f3f3f3f3e2f2f3565849000000000000000000c30040416759000000000000000000000000000000000000000000000000000000000000565900000040414166590000c300000066
5841425b5600000000000000000000006900000000000000430052545455d7566900005e6600584748474847484748474847484748474847484748474847485768794200000000000000000000d9c86659000000000000000000000000000000000000000000000000000000000000666900c300000000566900000000004066
59f3f75b66000000000000000000000059000000d74042e949e962545465d7666841425e7678777877787778777877676878777877777877787778777877786759c8c90000000000c0c2000000000056584900000000000000000046474847484748474847484748474847484200005659000000000000565943000000000056
69f7e84041787778777877787778670069e7c0c20000c846584900545455d75659c8005e5f000000c9c8c80000c9c85659d9c9d9c8c8c9c8c8c9d9c9c8c8d95669e7000000000000c9d900450000d766005849000000000043000076677678787900000076777877790000000000466669000043000000666900000000000056
59e8f3f4c8d9c8c9c8c8d9c9d9d7560059000000e90000560059e77354650066690000c0c2000000000000000000006669e7000000000000000000000000d7665900000000d7c0c2e70062635500d756006a5900000000000000000056000000000000000000000000000000000066595900000000000056590000c0c2000066
69f3c0c2000000000000000000d7666a690000c0c200d7660069e7007400d756590000000000c0c1c20000e90000005659e7000000000000000000000000d75669e70000000000000052636365000066687742484748490000000000560000000000404149004641414148484748486969000000000043666900000000004356
59f3f400d7c0c2e700e9000000d77677790000000000465700584900000000666900000000000000000000430000006669e7000000000000000000000000d7665900d7c0c1c2e700004f63635500d7565900767778676900c0c1c200560000000000000076417900007677787778777879000000000000565900000000000066
69f3f3f4000000d7c0c1c2e7000000000000c0c2004556000000590000000076790000000000000000004649004d4b7679000000000000006c6d00000000007679e70000000000e90000536365000076790000000056590000000000560000000000000000000000000000000000000000000000000000767900000000000056
59f3f3f3f40000c5c5c5c50044457b44c5c5c5c562636600000069c5c5c700000000e9000000e9e9004657694d5b5bf2f3f4e9c5c5c5c7c57c7dc5c5c56be9e9000000000000c0c1c2e7007300e9c7e9e9e9c5c6e966690000000000584748484748474847484748474847484749000000000000000000000000000000464866
584748474847484748474847484748474847484748475700000058474847484747484748474847484757005847484748474847484748474847484748474847484749000000e900000000000000464748474847484757590000434300000066000000000000000000000000000058474849000000004647484748474847576a56
__sfx__
000400000f5500a550105500f5500c550075500355001550025500155000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
0110001001750097500175005750017500a7500175006750017500a75001750067500575009750017500675001750017500175001750000000000000000000000000000000000000000000000000000000000000
00140008015003f5303f5503f5703f5503f5300150001500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000100003c450374503045029450224501b45015450104500c4500765004650026500165000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
0001000001150011500315004150071500b1500f15013150001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
0018000c05750077603372005770037701b77003710047700377005770347700a7100770000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00100015000000b35010350133501535016350153500000010350063000630009300183000c35011300083500b3500f350103500d3000b3500000000000000000000000000000000000000000000000000000000
0110001001750097500175005750017500a7500175006750017500a75001750067500575009750017500675001750017500175001750007000070000700007000070000700007000070000700007000070000700
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002837200000283622830228352000002834200000283322830228322283022831200000283120000031372313023136200000313520000031342000003133200000313220000031322000003131200000
011000003037232302303620000030362000003035200000303520000030342000003034200000303320000030332000003032200000303220000030312000003031200000303120000030312000003031200000
011000003537235302353720000035362000003536200000353520000035352000003534200000353420000035332000003533200000353220000035322000003531200000353120000035312000003531200000
011000001077010770107601076010750107501074010740107301073010720107201071010710107101071112770127701276012760127501275012740127401273012730127201272012710127101271012710
011000000f7700f7700f7700f7700f7600f7600f7600f7600f7500f7500f7500f7500f7400f7400f7400f7400f7300f7300f7300f7300f7200f7200f7200f7200f7100f7100f7100f7100f7100f7100f7100f710
0110000015773393020060300603006030060315773157031a67300603006031a6031a613006031a61315773157731a6130060300603006030060315773006031a6730060300603006031a6231a6331a6231a613
0110000015773393020060300603006030060315773157031a67300603006031a6031a613006031a61315773157731a6131577300603157730060315773006031a6431a6531a6631a6731a6431a6531a6631a673
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00010203
02 00010204
00 41424344
00 41424344
00 41424344
00 0a4d4344
00 0b4e4344
00 0a4d4344
00 0c4e4344
00 0a0d4344
00 0b0e4344
00 0a0d4344
00 0c0e4f44
01 0a0d0f44
00 0b0e0f44
00 0a0d0f44
02 0c0e1044
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

