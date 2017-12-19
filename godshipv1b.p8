pico-8 cartridge // http://www.pico-8.com
version 8
__lua__


-- ************************************************************************ constant definition ************************************************************************
-- button inputs
button_left   = 1
button_right  = 2
button_up     = 3
button_down   = 4
button_action = 5
button_jump   = 6

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
unit_type_useless			 = 13

unit_type_generator_fire 	= 6
unit_type_generator_acid 	= 7

unit_type_ennemy_walker 	= 8
unit_type_ennemy_jumper		= 9
unit_type_ennemy_flyer  	= 10
unit_type_ennemy_particule	= 11

unit_type_ennemy_generator	= 12

-- material flags
flag_none   	  = 0
flag_solid  	  = 1
flag_traversable  = 2
flag_destructible = 3
flag_transmission = 4

-- rooms definition for camera placement
-- room format : {posx, posy, width, height, {neighbors room, ...}, {monster, particle generator, ...}, }
-- unit format : {posx, posy, type, optionnal (looking direction, ...)}
rooms = {
	-- room 1
	{0, 0, 128, 128, {2,8}, {
		--{10, 14, 6, 1},		-- fire
		{4, 14, 6, 1},		-- fire
		{3, 14, 6, 1}}},	-- scenario shoot

	-- room 2
	{128, 0, 128, 128, {1,3}, {
		{28, 10, 8, 1},				-- walker
		{23, 14, 8,1}}},			-- walker

	-- room 3
	{256, 0, 128, 128, {2,4},{
		{39, 3,  8, 1},				-- walker
		{45, 14, 5, 1}}},			-- scenario shoot
	
	-- room 4
	{384, 0, 128, 128, {3,5}, {
		{59, 4,  8, 1},				-- walker
		{59, 7,  8, 1},				-- walker
		{57, 12, 8, 1}}},			-- walker

	-- room 5
	{384, 128, 128, 128, {4,6,9}, {
		{57, 20, 8, 1},				-- walker
		{50, 22, 8, 1},				-- walker
		{53, 29, 9, 0xffff}}},		-- jumper  -- 0xffff = -1

	-- room 6
	{256, 128, 128, 128, {5,7}, {
		{35, 20, 8, 0xffff},		-- walker
		{39, 26, 8, 0xffff}}},		-- walker

	-- room 7
	{128, 128, 128, 128, {6,8}, {
		{21, 23, 8, 1}}},			-- walker

	-- room 8
	{0, 128, 128, 128, {7, 1}, {
		{1, 22, 6, 1},			-- fire
  		{2, 22, 6, 1},			-- fire
  					-- {6, 21, 6, 1} fire
		{9, 28, 8, 1}}},			-- walker

	-- room 9
	{512, 0, 128, 384, {5,10,12,15}, {
		{77, 46, 5, 3},				-- scenario charged shoot
		{71, 29, 8, 1},				-- walker
		{73, 23, 8, 0xffff},		-- walker
		{72, 19, 8, 1},				-- walker
		{68, 27, 8, 1},				-- walker
		{70, 43, 8, 1},				-- walker
		{73, 5, 10, 1},				-- flyer
		{73, 44, 10, 0xffff}}},		-- flyer
					
	-- room 10
	{256, 256, 256, 128, {9,11}, {
		{46, 37, 9, 1},				-- jumper
		{38, 39, 8, 1},				-- walker
		{33, 43, 8, 1}}},			-- walker

	-- room 11
	{0, 256, 256, 128, {10}, {
		{18, 46, 7, 1},	{19, 46, 7, 1},			-- acid
		{21, 46, 7, 1}, {22, 46, 7, 1},			-- acid
		{24, 46, 7, 1}, {25, 46, 7, 1},			-- acid
		{27, 46, 7, 1},							-- acid
		{29, 38, 5, 2},							-- scenario double jump
		{21, 37, 8, 0xffff},					-- walker
		{16, 37, 8, 1},							-- walker
		{5,  40, 8, 1} }},						-- walker

	-- room 12
	{640, 0, 256, 128, {9,13}, {
		{83,  6, 7, 1}, {85,  6, 7, 1},		-- acid
		{87,  6, 7, 1}, {88,  6, 7, 1},		-- acid
		{89,  6, 7, 1}, {91,  6, 7, 1},		-- acid
		{92,  6, 7, 1}, {93,  6, 7, 1},		-- acid
		{94,  6, 7, 1}, {95,  6, 7, 1},		-- acid
		{96,  6, 7, 1}, {98,  6, 7, 1},		-- acid
		{99,  6, 7, 1}, {101, 6, 7, 1},		-- acid
		{102, 6, 7, 1}, {103, 6, 7, 1},		-- acid
		{105, 6, 7, 1}, {106, 6, 7, 1},		-- acid
		{107, 6, 7, 1}, {109, 6, 7, 1},		-- acid
		{85,  6, 7, 1},
		{82,  3, 5, 4}	}},

	-- room 13
	{896, 0, 128, 384, {12,14,16}, {
		{116, 10, 8,  0xffff},					-- walker
		{125, 33, 10, 0xffff},					-- flyer
		{125, 12, 10, 1},						-- flyer
		{113, 46, 5, 5}}},						-- scenario boss door close

	-- room 14
	{768, 128, 128, 128, {13,15}, {
		{105, 17, 10, 1},					-- flyer
		{101, 27, 7, 1},					-- acid
		{102, 27, 7, 1},					-- acid
		{106, 23, 8, 1}	}},					-- walker

	-- room 15
	{640, 128, 128, 256, {14,9}, {
		{87, 19, 9, 0xffff},					-- flyer
		{84, 26, 8, 1},						-- walker
		{89, 27, 8, 0xffff},					-- walker
		{92, 36, 8, 1},						-- walker
		{90, 46, 8, 0xffff}	}},					-- walker

	-- boss room
	{768, 256, 128, 128, {13}, {}}
}

bossroomplateform = {
	{97,38},{98,38},
	{107,38},{108,38},
	{97,42},{98,42},{99,42},{100,42},
	{107,42},{108,42},{109,42},{110,42}
}

-- scenario block definition
scenario = {
	-- {sprite, picked, {text for popup in line array}, optionnal string}
	{33, false, {"get plasma gun !","press \151 to shoot !"}, "shoot"},
	{34, false, {"get jetpack !","double press \142","to double jump"}, "djump"},
	{33, false, {"get charged gun !","keep \151 pressed","for more damage!"}, "cshoot"},
	{1,  false, {"way to boss open"}, "key"},											-- use 1 to place a trigger scenario box
	{1,  false, {"i need to find a","way to open this","corridor."}, ""}
}

-- player constant
constant_jumpspeed = -4
constant_walkspeed = 1.8
constant_chargeshoottime = 60
constant_invulnerabilitytime = 30

-- ennemy constant
constant_random_behaviour = 60
constant_walkerspeed = 0.3
constant_jumperspeedx = 0.8
constant_jumperspeedy = 5
constant_flyerspeed = 0.5



-- ************************************************************************ global variables ************************************************************************
-- frame counter
framecounter = 0

-- game state
gamestate = game_state_playing

-- player unit
player = {}
deadposition = {}

-- all the unit present in the game
unitlist = {}
tmpunitlist = {}

-- hud unit
hudunit = {}

-- current room of the player unit
currentroom = 1

-- camera
cam = {}

-- cheat system
cheatsequence = { button_up, button_up, button_down, button_down, button_left, button_right, button_left, button_right, button_jump, button_action }
cheatstate = 1

-- ************************************************************************ pico8 and specific engine function functions ************************************************************************
function _init()
	-- add custom menu entry
	menuitem( 1, "suicide ...", function() player.healthpoint = 0 end )

	-- init controller
	_controllerbuttonmap = {}
	for i = 1, 7 do
		_controllerbuttonmap[i] = {}
		_controllerbuttonmap[i].previous = false
		_controllerbuttonmap[i].state = false
		_controllerbuttonmap[i].time = 0
	end

	initializeplayer()
	initializecollision()
	
	-- init camera
	cam.x = 0
	cam.y = 0
	cam.targetx = 0
	cam.targety = 0
	cam.speed = 5.0
	cam.popuptext = {}
	
	-- init boss system
	killboard = {}
	boss = {}

	--	end init
	reset()

	-- popup on first entrance in game
	--cam.popuptext = {"i survived, but","not my gear."}
	--gamestate = game_state_popup
end

function reset()
	-- reset map
	reload(0x2000, 0x2000, 0x1000)

	-- reset game elements and state
	gamestate = game_state_playing
	
	-- reset controller
	for i = 1, 7 do
		_controllerbuttonmap[i].previous = false
		_controllerbuttonmap[i].state = false
	end

	-- reset player state
	player.positionx, player.positiony, player.speedx, player.speedy = 56, 112, 0, 0
	player.state, player.action = unit_state_idle, unit_state_idle
	player.healthpoint, player.direction, player.pose = 3, 1, 0
	player.dammagetime, player.framedammage, player.shoottime = 0, 0, 0
	player.visible, player.djumpavailable = true, true
	player.shootenable, player.djumpenable, player.chargeshootenable = false, false, false
	killboard.walker, killboard.jumper, killboard.flyer = 0, 0, 0

	-- reset room system
	for unit in all(unitlist) do del(unitlist, unit) end
	for unit in all(tmpunitlist) do del(tmpunitlist, unit) end
	currentroom = 1
	initializeroom(currentroom)
	bossroomstate = 0
	
	-- reset scenario
	for item in all(scenario) do
		item[2] = false
	end

	-- reset boss system
	mset(111, 46, 0)
	boss.state, boss.timer, boss.currentwave = 0, 0, 1
	boss.wave = {{
		ennemytype = unit_type_ennemy_walker,
		layer = {
			{101,33,39},												{106,33,40},
			{101,34,39},												{106,34,40},
			{101,35,39},												{106,35,40},
			{101,36,55},												{106,36,56}
		}	
	}, {
		ennemytype = unit_type_ennemy_jumper,
		layer = {
						{102,33,37},						{105,33,38},
						{102,34,37},						{105,34,38},
						{102,35,37},						{105,35,38},
						{102,36,53},						{105,36,54}
		}
	},{
		ennemytype = unit_type_ennemy_flyer,
		layer = {
									{103,33,41},{104,33,42},
									{103,34,41},{104,34,42},
									{103,35,41},{104,35,42},
									{103,36,41},{104,36,42}
		}
	}}

	-- cheat init zone
	--setplayerposition(84, 4)
	--player.djumpenable, player.shootenable, player.chargeshootenable, player.invulnerable = true, true, true, true
	--killboard.walker, killboard.jumper, killboard.flyer = 2, 1, 1
end

function _update()
	-- need to reset game
	if (player.state == unit_state_dead) then
		-- create dead position vector
		local deadx, deady = player.positionx, player.positiony

		-- gravity on body
		while true do
			if (checkflag(deadx + 1, deady + 8, flag_solid) or checkflag(deadx + 6, deady + 8, flag_solid) ) then
				break
			elseif (checkflag(deadx + 1, deady + 8, flag_traversable) or checkflag(deadx + 6, deady + 8, flag_traversable) ) then
				break
			else
				deady += 1
			end
		end

		-- search body room
		for i = 1, 16 do -- check all room
			if (inroom(deadx, deady, i)) then
				add(rooms[i].deadbodylist, {positionx = deadx, positiony = deady})
				break
			end
		end

		-- reset
		reset()

	-- normal mode of game
	elseif (gamestate == game_state_playing) then
		-- cheat
		if (currentroom == 1) then updatecheat() end

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
		for unit in all(hudunit) do
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

			-- remove dead unit
			for unit in all(unitlist) do
				if (unit.state == unit_state_dead) then del(unitlist, unit) end
			end
		end

		-- remove dead unit of hud
		for unit in all(hudunit) do
			if (unit.state == unit_state_dead) then del(hudunit, unit) end
		end

		-- update room system
		updateroom()
		if (currentroom == 16) then updatebossroom() end

	-- game in popup mode
	elseif (gamestate == game_state_popup) then
		updatecontroller(framecounter)
		if (controllerbuttonup(button_action)) then
			gamestate = game_state_playing
			cam.popuptext = {}
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
	local camx, camy = cam.x, cam.y
	camera(camx, camy)
	map(0, 0, 0, 0, 128, 48)

	-- draw all unit (first due to particle under player sprite)
	for unit in all(unitlist) do
		drawunit(unit)
	end
	for unit in all(tmpunitlist) do
		drawunit(unit)
	end

	-- temporary informations
	local offset = 0 -- offset x, offset y
	for unit in all(hudunit) do
		drawhudunit(unit, offset)
		offset += 8
	end

	-- killboard & collectible hud
	rectfill(camx + 70, cam.y, camx + 128, camy + 7, 0)
	print(killboard.walker + killboard.jumper + killboard.flyer, camx + 112, camy + 1, 7)
	spr(36, camx + 103, cam.y)
	print( "6".."/66", camx + 80, camy + 1, 7)
	spr(35, camx + 72, camy)
	
	-- draw player based on player animation state machine
	if (player.visible) then
		local px, py, dir = player.positionx, player.positiony, player.direction > 0

		-- jetpack sprite
		if (player.state == unit_state_djump) then
			spr(234, px - 8 * player.direction, py+3, 1, 1, not dir)
		end

		-- player sprite based on animation state
		drawunit(player)

		-- helmet / head dammage
		if (player.healthpoint > 2) then
			if (dir) then line(px + 1, py, px + 3, py, 12)
			else line(px + 4, py, px + 6, py, 12) end
		elseif (player.healthpoint == 1) then
			if (dir) then line(px + 1, py, px + 3, py, 8)
			else line(px + 4, py, px + 6, py, 8) end
		end
		
		-- gun charging and fire shoot sprite
		if (player.action == unit_state_shooting) then
			spr(253, px + player.direction*8*player.sizex, py, 1, 1, dir)
		elseif (player.action == unit_state_charging) then
			local sprite, color = player.animations[player.state].start + player.pose, 3 -- current player sprite, charging gun color

			if ((framecounter - player.shoottime)%2 == 0) then color = 11 end
			if (framecounter - player.shoottime > constant_chargeshoottime) then
				if(sprite == 17 or sprite == 19) then line(px + 3, py + 3, px + 4, py + 3, color)
				else line(px + 3, py + 2, px + 4, py + 2, color) end
			elseif (framecounter - player.shoottime > constant_chargeshoottime/2) then
				if(sprite == 17 or sprite == 19) then pset(px + 3, py + 3, color)
				else pset(px + 3, py + 2, color) end
			end
		end
	end

	print(currentroom, player.positionx, player.positiony - 6)

	-- draw popup if needed
	if (gamestate == game_state_popup or gamestate == game_state_end) then
		drawpopup()
	end
end

-- ************************************************************************ player functions ************************************************************************
-- cheat system
function updatecheat()
	local last = controllergetlast()
	if(last != cheatsequence[cheatstate] and controllerbuttondown(last)) then
		cheatstate = 1
	elseif(controllerbuttondown(cheatsequence[cheatstate])) then
		cheatstate += 1
		if(cheatstate > count(cheatsequence)) then
			cheatstate = 1
			player.djumpenable, player.shootenable, player.chargeshootenable, player.invulnerable = true, true, true, true
		end
	end
end


-- ************************************************************************ player functions ************************************************************************
-- initialize the player special unit
function initializeplayer()
	player = newunit(56, 112, unit_type_player, newanimation(17, 2, 30))
	player.healthpoint, player.djumpavailable, player.shoottime = 3, true, 0
	player.action, player.framedammage, player.dammagetime = unit_state_idle, 0, 0
	player.djumpenable, player.shootenable, player.chargeshootenable, player.invulnerable = false, false, false, false

	-- attach more animation
	player.animations[unit_state_dead] = newanimation(16, 1, 5)
	player.animations[unit_state_walk] = newanimation(18, 2, 2)
	player.animations[unit_state_jump] = newanimation(20, 1, 5)
	player.animations[unit_state_djump] = newanimation(20, 1, 5)
	player.animations[unit_state_falling] = newanimation(20, 1, 5)
end

function setplayerposition(x, y)
	player.positionx = 8*x
	player.positiony = 8*y

	local found = false
	for i = 1, 16 do -- check all room
		if (inroom(player.positionx, player.positiony, i)) then
			currentroom = i
			found = true
			break
		end
	end
	if (not found) then				-- begining position
		player.positionx = 56
		player.positiony = 112
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
			sfx(4)
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
			sfx(4)
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
		-- initialize a bullet unit
		local bullet = initializeparticule(player.positionx + player.direction*(8*player.sizex - 2), player.positiony, newanimation(249, 1, 5), 50)
		if (controllergetstatechangetime(button_action) - player.shoottime > constant_chargeshoottime and player.chargeshootenable) then
			bullet.speedx = player.direction*5
			bullet.damage = 5
		else
			bullet.speedx = player.direction*10
			bullet.damage = 1
			sfx(3)
		end
		bullet.positionx -= bullet.speedx
		bullet.sizey = 0.7
		bullet.direction = player.direction
		bullet.gravityafected = false
		bullet.traversable = true

		-- change player state machine
		if(player.state == unit_state_idle) then
			player.statetime = 0
		end
		player.shoottime = 0
		player.action = unit_state_shooting
	elseif (controllerbuttonispressed(button_action) and player.chargeshootenable) then
		player.action = unit_state_charging
	end

	if (controllerbuttonispressed(button_down)) then player.traversable = true end
end

-- the player dammage machine state function
function updateplayerdammage()
	if (player.dammagetime == 0) then
		if (player.framedammage > 0) then
			if (not player.invulnerable) then 
				player.healthpoint -= 1
				sfx(5)
				end
			player.dammagetime += 1
			player.visible = false

			local impact = initializeparticule(player.positionx, player.positiony, newanimation(221, 3, 4), 12)
			impact.pose = 3
			impact.speedx, impact.speedy = player.speedx, player.speedy
			impact.environementafected, impact.gravityafected = false, true
		end
	elseif (player.dammagetime >= constant_invulnerabilitytime) then
		player.dammagetime, player.visible = 0, true
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
	local ennemy  = newunit(x, y, unit_type_ennemy_walker, newanimation(49, 2, 17))
	ennemy.healthpoint, ennemy.damage = 1, 1
	ennemy.update, ennemy.controller = updatewalker, controllerwalker
	ennemy.state = unit_state_walk

	-- attach more animation
	ennemy.animations[unit_state_dead] = newanimation(49, 1, 1)
	ennemy.animations[unit_state_walk] = newanimation(50, 2, 7)
	add(unitlist, ennemy)
end

function controllerwalker(unit)
	local px, py, dir = unit.positionx, unit.positiony, unit.direction

	-- avoid falling
	if (dir < 0 and not checkflag(px + 7, py + 8, flag_solid) and not checkflag(px + 7, py + 8, flag_traversable)) then
		unit.direction = -dir
	elseif (dir > 0 and not checkflag(px, py + 8, flag_solid) and not checkflag(px, py + 8, flag_traversable)) then
		unit.direction = -dir

	-- avoid wall collision
	elseif (dir < 0 and (checkflag(px + 8, py + 7, flag_solid) or checkflag(px + 8, py + 7, flag_traversable))) then
		unit.direction = -dir
	elseif (dir > 0 and (checkflag(px - 1, py + 7, flag_solid) or checkflag(px - 1, py + 7, flag_traversable))) then
		unit.direction = -dir

	-- avoid exit room
	elseif (dir < 0 and not inroom(px + 8, py + 7, currentroom)) then
		unit.direction = -dir
	elseif (dir > 0 and not inroom(px - 1, py + 7, currentroom)) then
		unit.direction = -dir
	end
end

function updatewalker(unit)
	unit.statetime += 1
	unit.speedx = -unit.direction * constant_walkerspeed
	unit.pose = flr(unit.statetime / unit.animations[unit.state].time) % unit.animations[unit.state].frames
end



-- initialize jumper ennemy
function initializejumper(x, y)
	local ennemy  = newunit(x, y, unit_type_ennemy_jumper, newanimation(10, 2, 20), 2, 2)
	ennemy.healthpoint, ennemy.damage = 5, 1
	ennemy.targetx, ennemy.targety, ennemy.targetdistance = x, y, 0
	ennemy.traversable = true
	ennemy.update, ennemy.controller = updatejumper, controllerjumper

	-- attach more animation
	ennemy.animations[unit_state_dead] = newanimation(10, 2, 20)
	ennemy.animations[unit_state_jump] = newanimation(14, 1, 1)
	add(unitlist, ennemy)
end

function controllerjumper(unit)
	local d = distance(unit, player)
	if (d <= 40 and d >= 4) then
		unit.targetx, unit.targety, unit.targetdistance = player.positionx, player.positiony, d
	elseif (unit.statetime > constant_random_behaviour) then
		unit.targetx, unit.targety = unit.positionx - 16 + rnd(32), unit.positiony - rnd(1)
		unit.targetdistance = abs(unit.targetx - unit.positionx)
		unit.statetime = 0
	end
end

function updatejumper(unit)
	local pstate, px = unit.state, unit.positionx
	unit.statetime += 1

	if (unit.state == unit_state_idle) then
		unit.speedx = 0
		if (abs(unit.targetx - px) > 4 and unit.statetime >= 10) then
			unit.state = unit_state_jump
			unit.speedy = -constant_jumperspeedy
		end
	elseif (unit.state == unit_state_jump) then
		if (unit.targetx - px > 4) then
			unit.speedx = constant_jumperspeedx
		elseif (unit.targetx - px < -4) then
			unit.speedx = -constant_jumperspeedx
		else unit.speedx = 0 end

		if (checkflag(px - 1, unit.positiony + 8 * unit.sizey, flag_solid) or checkflag(px + 8 * unit.sizex - 2, unit.positiony + 8 * unit.sizey, flag_solid) ) then
			unit.state = unit_state_idle
		--elseif (checkflag(unit.positionx-1, unit.positiony + 8*unit.sizey, flag_traversable) or checkflag(unit.positionx + 8*unit.sizex -2, unit.positiony + 8*unit.sizey, flag_traversable) ) then
		--	unit.state = unit_state_idle
		end
	end

	-- end
	--if (unit.speedy < 0) then unit.traversable = true
	--elseif (unit.speedy > 0) then unit.traversable = false end
	--if (unit.targety < unit.positiony) then unit.traversable = true end

	if (unit.state != pstate) then unit.statetime = 0 end
	if (unit.speedx > 0) then unit.direction = -1
	elseif (unit.speedx < 0) then unit.direction = 1 end
	unit.pose = flr(unit.statetime / unit.animations[unit.state].time) % unit.animations[unit.state].frames
end



-- initialize flyer ennemy
function initializeflyer(x, y)
	local ennemy  = newunit(x, y, unit_type_ennemy_flyer, newanimation(44, 2, 20), 2, 2)
	ennemy.healthpoint, ennemy.damage = 3, 1
	ennemy.targetx, ennemy.targety, ennemy.targetdistance = x, y, 0
	ennemy.gravityafected, ennemy.traversable = false, true
	ennemy.update, ennemy.controller = updateflyer, controllerflyer

	-- attach more animation
	ennemy.animations[unit_state_dead] = newanimation(44, 2, 20)
	ennemy.animations[unit_state_walk] = newanimation(44, 2, 10)
	add(unitlist, ennemy)
end

function controllerflyer(unit)
	local d = distance(unit, player)
	if (d <= 64 and d >= 4) then
		unit.targetx, unit.targety, unit.targetdistance = player.positionx, player.positiony, d
	elseif (unit.statetime > constant_random_behaviour) then
		unit.targetx, unit.targety = unit.positionx - 16 + rnd(32), unit.positiony
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



-- ************************************************************************ particles, particule generators and ennemy generators functions ************************************************************************
-- initialize particle
function initializeparticule(x, y, idleanimation, life)
	local particule = newunit(x, y, unit_type_particule, idleanimation)
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
function initializeparticulegenerator(x, y, idleanimation, particleanimation, spawntime)
	local generator = newunit(x, y, unit_type_particule_generator, idleanimation)

	-- modifiable attribute to twick to create a full customized particule generator
	generator.plife, generator.plifedispertion, generator.pdamage = 50, 0, 0	-- particle life and dammage
	generator.plifedispertion = 0												-- particle life dispertion
	generator.panimation = particleanimation									-- particule idle animation
	generator.pgravity, generator.pdirection = false, 1							-- particule are affected by gravity, initial direction (0 means random)
	generator.pspeedx, generator.pspeedy = 0, 0									-- particule initial speed
	generator.ppositionx, generator.ppositiony = 0, 0							-- particule initial position
	generator.spawntime, generator.spawntimedispertion = spawntime, 0 			-- spawn interval time and related dispertion

	-- machine state related attributes
	generator.time, generator.nextspawntime = 0, 0
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
		particule.gravityafected, particule.speedx, particule.speedy, particule.damage = unit.pgravity, unit.pspeedx, unit.pspeedy, unit.pdamage
		if (unit.pdirection == 0) then particule.direction = 3*rnd(1)-1
		else particule.direction = unit.pdirection end
		unit.time, unit.nextspawntime = 0, unit.spawntime - rnd(unit.spawntimedispertion)
	end
end

-- place standard firework (generate some smoke)
function placefire(x, y)
	local fire = initializeparticulegenerator(x, y, newanimation(203,2,5), newanimation(240, 2, 10), 15)
	fire.gravityafected, fire.spawntimedispertion = false, 4
	fire.pspeedy, fire.pdirection, fire.plife, fire.plifedispertion = -1, 0, 20, 20
	fire.damage, fire.pose, fire.time = 1, rnd(1), rnd(fire.spawntime)
	fire.nextspawntime = rnd(fire.spawntime) + rnd(fire.spawntimedispertion)
end

-- place standard acid block (generate some buble)
function placeacid(x, y)
	local acid = initializeparticulegenerator(x, y, newanimation(224,2,20), newanimation(219, 2, 3), 100)
	acid.gravityafected, acid.spawntimedispertion = false, 40
	acid.ppositiony, acid.plife = -8, 6
	acid.damage, acid.pose, acid.time, acid.nextspawntime = 1, rnd(1), rnd(acid.spawntime), rnd(acid.spawntime) + rnd(acid.spawntimedispertion)
end

-- initialize ennemy generators
function initializeennemygenerator(x, y, ennemytype, spawntime, ennemycount)
	local generator = newunit(x, y, unit_type_ennemy_generator, newanimation(48,1,1))
	generator.gravityafected = false
	generator.ennemytype = ennemytype
	generator.ppositionx = 0
	generator.ppositiony = 0
	generator.spawntime = spawntime
	generator.ennemycount = ennemycount
	generator.visible = false

	-- machine state related attributes
	generator.time = 0
	generator.nextspawntime = spawntime
	generator.update = updateennemygenerator
	add(unitlist, generator)
	return generator
end

-- update particule generator
function updateennemygenerator(unit)
	unit.time += 1

	if (unit.time >= unit.nextspawntime) then
		local x, y, type = unit.positionx + unit.ppositionx, unit.positiony + unit.ppositiony, unit.ennemytype
		if (type == unit_type_ennemy_walker) then initializewalker(x, y)
		elseif (type == unit_type_ennemy_jumper) then initializejumper(x, y)
		elseif (type == unit_type_ennemy_flyer) then initializeflyer(x, y)
		end

		unit.ennemycount -= 1
		if (unit.ennemycount <= 0) then unit.state = unit_state_dead end
		unit.time, unit.nextspawntime = 0, unit.spawntime
	end
end

-- ************************************************************************ room system functions ************************************************************************

-- initialize room : place unit of correct type to correct position depending of the room structure
function initializeroom(room)
	-- initialize dead body list if not present
	if (not rooms[room].deadbodylist) then
		rooms[room].deadbodylist = {}
	end

	-- place dead body
	for pos in all(rooms[room].deadbodylist) do
		local body = newunit(pos.positionx, pos.positiony, unit_type_useless, newanimation(16,1,1))
		body.environementafected = false
		body.gravityafected = false
		add(unitlist, body)
	end

	-- instanciate all unit of room
	newunitlist = rooms[room][6]
	for i = 1, count(newunitlist) do
		local x, y, type = newunitlist[i][1]*8, newunitlist[i][2]*8, newunitlist[i][3]
		if (type == unit_type_generator_fire) then placefire(x, y)
		elseif (type == unit_type_generator_acid) then placeacid(x, y)
		elseif (type == unit_type_ennemy_walker) then initializewalker(x, y)
		elseif (type == unit_type_ennemy_jumper) then initializejumper(x, y)
		elseif (type == unit_type_ennemy_flyer) then initializeflyer(x, y)
		elseif (type == unit_type_scenario) then
			local item = scenario[newunitlist[i][4]]
			if (item and not item[2]) then
				placescenario(x, y, item[1], newunitlist[i][4])
			end
		end
	end

	-- special update for boss !!!!
	if(room == 16) then
		for bosswave in all(boss.wave) do
			for bossunit in all(bosswave.layer) do
				mset(bossunit[1], bossunit[2], bossunit[3])
			end
		end
	end
end

-- update current room depending on player position
function updateroom()
	local px, py, tmproom = player.positionx, player.positiony, rooms[currentroom]

	if (mid(px, tmproom[1], tmproom[1] + tmproom[3]) == px) and (mid(py, tmproom[2], tmproom[2] + tmproom[4]) == py) then
		return
	else 
		for i = 1, count(tmproom[5]) do
			local r = tmproom[5][i]
			if (mid(px, rooms[r][1], rooms[r][1] + rooms[r][3]) == px) and (mid(py, rooms[r][2], rooms[r][2] + rooms[r][4]) == py) then
	   			currentroom = r
	   			tmproom = rooms[currentroom]
	   			break
	   		end
		end

		tmpunitlist, unitlist = unitlist, tmpunitlist
		initializeroom(currentroom)
		gamestate = game_state_camtransition
		cam.targetx, cam.targety = mid(px - 64, tmproom[1], tmproom[1] + tmproom[3] - 128), mid(py - 64, tmproom[2], tmproom[2] + tmproom[4] - 128)
	end
end

-- boss behaviour
function updatebossroom()
	-- close door
	if (boss.state == 0) then
		if (player.positionx <= 880) then
			boss.state += 1
			mset(111, 46, 210)
			local transition = initializeparticule(888, 368, newanimation(210,2,5), 10)
			transition.gravityafected = false
		end
	
	-- init wave 1
	elseif (boss.state == 1) then
		-- remove all plateform
		for pos in all(bossroomplateform) do
			mset(pos[1], pos[2], 0)
		end

		-- get ennemy count to initialize depending on wave number
		local ennemycount
		if(boss.wave[boss.currentwave].ennemytype == unit_type_ennemy_walker) then ennemycount = killboard.walker - 1
		elseif(boss.wave[boss.currentwave].ennemytype == unit_type_ennemy_jumper) then ennemycount = killboard.jumper
		else ennemycount = killboard.flyer end

		-- instanciate ennemy spawner
		if (ennemycount > 0 and player.positionx >= 824 and player.positionx <= 840) then
			boss.state += 1
			initializeennemygenerator(784, 344, boss.wave[boss.currentwave].ennemytype, 20, ennemycount)
			initializeennemygenerator(872, 344, boss.wave[boss.currentwave].ennemytype, 20, ennemycount)
		elseif (ennemycount <= 0) then
			boss.state = 3
			boss.timer = 1
		end

	-- wave 1
	elseif (boss.state == 2) then
		local ennemyremaining = false
		for unit in all(unitlist) do
			if (unit.type == unit_type_ennemy_generator) then
				ennemyremaining = true
				break
			elseif (unit.type >= unit_type_ennemy_walker and unit.type <= unit_type_ennemy_flyer) then
				ennemyremaining = true
				break
			end
		end
		if (not ennemyremaining) then
			boss.state += 1
			boss.timer = 1
		end

	-- init wave 1b
	elseif (boss.state == 3) then
		if (boss.timer <= count(bossroomplateform)) then
			mset(bossroomplateform[boss.timer][1], bossroomplateform[boss.timer][2], 195)
			local transition = initializeparticule(8*bossroomplateform[boss.timer][1], 8*bossroomplateform[boss.timer][2], newanimation(195,2,5), 10)
			transition.gravityafected = false
		else
			boss.state += 1
		end

		-- replace layer by destructible sprites
		for bossunit in all(boss.wave[boss.currentwave].layer) do
			fset(bossunit[3], flag_destructible, true)
		end

		boss.timer += 1

	-- wave 1b
	elseif (boss.state == 4) then
		boss.timer += 1
		if (boss.timer > 20) then
			boss.timer = 0
			local bullet = initializeparticule(828, 304, newanimation(239, 1, 5), 50)
			bullet.speedx, bullet.speedy = player.positionx - bullet.positionx, player.positiony - bullet.positiony
			local d = sqrt(bullet.speedx*bullet.speedx + bullet.speedy*bullet.speedy)
			bullet.speedx, bullet.speedy = 2.5 * bullet.speedx / d, 2.5 * bullet.speedy / d

			bullet.type = unit_type_ennemy_particule
			bullet.sizey, bullet.damage = 0.7, 1
			bullet.gravityafected, bullet.traversable = false, true
		end

		for pos in all(boss.wave[boss.currentwave].layer) do
			if(mget(pos[1], pos[2]) == 0) then -- check if a layer is partialy destroyed
				for pos2 in all(boss.wave[boss.currentwave].layer) do
					destroy(8 * pos2[1], 8 * pos2[2])
				end

				-- increment wave or quit
				boss.currentwave += 1
				if(boss.currentwave > 3) then
					boss.state += 1
					boss.timer = 0
					destroy(824, 296)
					destroy(832, 296)

					local tmp = initializeparticule(824, 296, newanimation(8,1,10), 100)
						tmp.sizex, tmp.sizey, tmp.damage = 2, 2, 0.001
				else boss.state = 1 end
				break
			end
		end

	--	boss killed !!!!!!!!!!!!!!!!
	else
		boss.timer += 1
		if(boss.timer > 70) then
			destroy(888, 368)
			cam.popuptext = {"congratulations !","you won !", "press enter to quit"}
			gamestate = game_state_end
		end
	end
end


-- ************************************************************************ scenario functions ************************************************************************
-- place a scenario block (a chest with a sprite floating on top)
-- has to reference a index on scenario table to have acces to additionnal parameter
function placescenario(x, y, sprite, index)
	local block
	if(sprite != 1) then
		block = initializeparticulegenerator(x, y, newanimation(32,1,1), newanimation(sprite, 1, 1), 60)
		block.plife, block.pdirection, block.type = block.spawntime + 1, 0, unit_type_scenario
	else
		block = newunit(x, y, unit_type_scenario, newanimation(1,1,1))
		add(unitlist, block)
	end
	block.index, block.burnafterreading = index, true
end


-- ************************************************************************ physics functions ************************************************************************
-- move object to delta and check collision with environement
-- compactable si develloppement des variable local
function updatephysics(unit, step)
	local x, y, sx, sy = unit.positionx, unit.positiony, 8 * unit.sizex, 8 * unit.sizey
	local callback, notraversable = _colisionmatrix[type_environement][unit.type], not unit.traversable

	-- aply gravity if unit is not touching ground
	if (unit.gravityafected) then
		if (checkflag(x + 1, y + sy, flag_solid) or
			checkflag(x + sx - 2, y + sy, flag_solid) ) then
		elseif (notraversable and (checkflag(x + 1, y + sy, flag_traversable) or checkflag(x + 6, y + 8, flag_traversable) )) then
		else
			unit.speedy += step * 0.4   -- gravity = 0.4
		end
	end

	local dx, dy = step * unit.speedx, step * unit.speedy

	if (callback) then
		-- check left and right collision with environement
		if (dx > 0) then
			if (checkflag(x + sx - 1 + dx, y + 1, flag_solid) or checkflag(x + sx - 1 + dx, y + sy - 2, flag_solid) ) then
				callback(unit, flag_solid, "x")
			elseif (notraversable and (checkflag(x + sx - 1 + dx, y + 1, flag_traversable) or checkflag(x + sx - 1 + dx, y + sy - 2, flag_traversable) )) then
				callback(unit, flag_traversable, "x")
			else
				x += dx
			end
		elseif (dx < 0) then
			if (checkflag(x + dx, y + 1, flag_solid) or checkflag(x + dx, y + sy - 2, flag_solid) ) then
				callback(unit, flag_solid, "x")
			elseif (notraversable and (checkflag(x + dx, y + 1, flag_traversable) or checkflag(x + dx, y + sy - 2, flag_traversable) )) then
				callback(unit, flag_traversable, "x")
			else
				x += dx
			end
		end

		-- check up and down collision with environement
		if (dy > 0) then
			if (checkflag(x + 1, y + sy - 1 + dy, flag_solid) or checkflag(x + sx - 2, y + sy - 1 + dy, flag_solid) ) then
				callback(unit, flag_solid, "y")
			elseif (notraversable and (checkflag(x + 1, y + sy - 1 + dy, flag_traversable) or checkflag(x + sx - 2, y + sy - 1 + dy, flag_traversable) )) then
				callback(unit, flag_traversable, "y")
			else
				y += dy
			end
		elseif (dy < 0) then
			if (checkflag(x + 1, y + dy, flag_solid) or checkflag(x + sx - 2, y + dy, flag_solid) ) then
				callback(unit, flag_solid, "y")
			elseif (notraversable and (checkflag(x + 1, y + dy, flag_traversable) or checkflag(x + sx - 2, y + dy, flag_traversable) )) then
				callback(unit, flag_traversable, "y")
			else
				y += dy
			end

		-- speed null so repositionate unit in a good way to avoid overlap on y axis (repositionate on top of the nearest plateform)
		elseif (unit.type != unit_type_particule) then
			if (checkflag(x + 1, y + sy - 1, flag_solid) or checkflag(x + sx - 2, y + sy - 1, flag_solid) ) then
				y -= 1
			elseif (notraversable and (checkflag(x + 1, y + sy - 1, flag_traversable) or checkflag(x + sx - 2, y + sy - 1, flag_traversable) )) then
				y -= 1
			end
		end
	else
		x += dx
		y += dy
	end
	unit.positionx, unit.positiony = x, y
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
	if (unit.environementafected) then
		local x, y = unit.positionx, unit.positiony
		if (unit.damage >= 4) then
			if (unit.speedx > 0) then
				if (checkflag(x + 8, y + 3, flag_destructible) or checkflag(x + 8, y + 4, flag_destructible) ) then
					destroy(x + 8, y + 3)
				end
			elseif (unit.speedx < 0) then
				if (checkflag(x - 1, y + 3, flag_destructible) or checkflag(x - 1, y + 4, flag_destructible) ) then
					destroy(x - 1, y + 3)
				end
			end
			unit.damage -= 4

			if(unit.damage <= 0) then
				local dead = initializeparticule(x, y, newanimation(251, 5, 1), 5)
				dead.gravityafected, dead.direction = false, unit.direction				
				unit.speedx, unit.life, unit.visible = 0, 0, false
			end
		elseif (unit.damage > 0) then
			if(unit.sizex <= 1) then
				local dead = initializeparticule(x, y, newanimation(251, 5, 1), 5)
				dead.gravityafected = false
				dead.direction = unit.direction
			else -- boss eye explosion
				for i = 1, 10 do
					local dead
					if( i % 2 == 1) then dead = initializeparticule(x + 8, y + 8, newanimation(7, 1, 10), 100)
					else dead = initializeparticule(x + 8, y + 8, newanimation(205, 3, 10), 30) end
					dead.direction, dead.speedx, dead.speedy = unit.direction, (rnd(10) - 5.0) / 2.5, constant_jumpspeed + (rnd(10) - 5.0) / 2.5
				end
			end

			unit.speedx = 0
			unit.life = 0
			unit.visible = false
		else
			unit.speedx = 0
			unit.life = 0
			unit.visible = false			
		end
	else
		unit.speedy = 0
	end
end


-- ************************************************************************ unit collision functions ************************************************************************
-- initialize collision callbacks matrix
function initializecollision()
	_colisionmatrix = {}
	for i = 1, 14 do
		_colisionmatrix[i] = {}
		for j = 1, 14 do
			_colisionmatrix[i][j] = nil
		end
	end

	_colisionmatrix[type_environement][unit_type_player] = callbackphysicsenvironementunit						-- [1][2]
	_colisionmatrix[type_environement][unit_type_particule] = callbackphysicsenvironementparticule				-- [1][3]
	_colisionmatrix[type_environement][unit_type_particule_generator] = callbackphysicsenvironementunit			-- [1][4]
	_colisionmatrix[type_environement][unit_type_scenario] = callbackphysicsenvironementunit					-- [1][5]
	_colisionmatrix[type_environement][unit_type_generator_fire] = callbackphysicsenvironementunit				-- [1][6]
	_colisionmatrix[type_environement][unit_type_generator_acid] = callbackphysicsenvironementunit				-- [1][7]
	_colisionmatrix[type_environement][unit_type_ennemy_walker] = callbackphysicsenvironementunit				-- [1][8]
	_colisionmatrix[type_environement][unit_type_ennemy_jumper] = callbackphysicsenvironementunit				-- [1][9]
	_colisionmatrix[type_environement][unit_type_ennemy_flyer] = callbackphysicsenvironementunit				-- [1][10]
	_colisionmatrix[type_environement][unit_type_ennemy_particule] = callbackphysicsenvironementparticule		-- [1][11]

	_colisionmatrix[unit_type_player][unit_type_particule_generator] = callbackcollisionplayerennemy			-- [2][4]
	_colisionmatrix[unit_type_player][unit_type_generator_fire] = callbackcollisionplayerennemy					-- [2][6]
	_colisionmatrix[unit_type_player][unit_type_scenario] = callbackcollisionplayerscenario						-- [2][5]
	_colisionmatrix[unit_type_player][unit_type_generator_acid] = callbackcollisionplayerennemy					-- [2][7]
	_colisionmatrix[unit_type_player][unit_type_ennemy_walker] = callbackcollisionplayerennemy					-- [2][8]
	_colisionmatrix[unit_type_player][unit_type_ennemy_jumper] = callbackcollisionplayerennemy					-- [2][9]
	_colisionmatrix[unit_type_player][unit_type_ennemy_flyer] = callbackcollisionplayerennemy					-- [2][10]
	_colisionmatrix[unit_type_player][unit_type_ennemy_particule] = callbackcollisionplayerennemy				-- [2][11]

	_colisionmatrix[unit_type_particule][unit_type_ennemy_walker] = callbackcollisionparticuleunit				-- [3][8]
	_colisionmatrix[unit_type_particule][unit_type_ennemy_jumper] = callbackcollisionparticuleunit				-- [3][9]
	_colisionmatrix[unit_type_particule][unit_type_ennemy_flyer] = callbackcollisionparticuleunit				-- [3][10]

	-- symetrize matrix
	for i = 1, 13 do
		for j = i, 13 do
			_colisionmatrix[j][i] = _colisionmatrix[i][j]
		end
	end
end

-- check if two unit currently collide (overlap)
function collisioncheck(unit1, unit2)
	local sx1, sy1, sx2, sy2 = 4*unit1.sizex, 4*unit1.sizey, 4*unit2.sizex, 4*unit2.sizey
	if ( abs(unit1.positionx + sx1 - (unit2.positionx + sx2)) < sx1 + sx2 - 1 ) then
		if ( abs(unit1.positiony + sy1 - (unit2.positiony + sy2)) < sy1 + sy2 - 1 ) then
			return true
		end
	end
	return false
end

-- units collision callbacks
function callbackcollisionparticuleunit(unit1, unit2)
	-- begin
	local particule, unit
	if(unit1.type == unit_type_particule) then particule, unit = unit1, unit2
	else particule, unit = unit2, unit1 end

	-- collision interaction
	if (particule.life > 0 and particule.damage > 0) then
		local impact = initializeparticule(unit.positionx + unit.sizex*4 - 4 + 0.2*particule.speedx, unit.positiony + unit.sizey*4 - 4 + 0.2*particule.speedy, newanimation(205, 3, 3), 9)
			impact.pose = 3
			impact.environementafected, impact.gravityafected = false, false
			impact.speedx, impact.direction = particule.direction * 0.8, particule.direction

		local dammage = particule.damage
		particule.damage -= unit.healthpoint
		unit.healthpoint -= dammage

		if (particule.damage <= 0) then particule.life, particule.speedx, particule.speedy = 0, 0, 0 end
		if (unit.healthpoint <= 0) then
			unit.visible = false
			sfx(6)
			unit.state = unit_state_dead
			if (unit.type == unit_type_ennemy_walker) then killboard.walker += 1
			elseif (unit.type == unit_type_ennemy_jumper) then killboard.jumper += 1
			elseif (unit.type == unit_type_ennemy_flyer) then killboard.flyer += 1
			end
			
			unit = newunit(0, 15*8, unit_type_particule, newanimation(36, 1, 1))
			unit.life, unit.update = 30, updateparticle
			add(hudunit, unit)
		end
	end
end
function callbackcollisionplayerennemy(unit1, unit2)
	if(unit1.type == unit_type_player) then player.framedammage += unit2.damage
	else player.framedammage += unit1.damage end
end
function callbackcollisionplayerscenario(unit1, unit2)
	-- get scenario unit in unit variable
	local unit
	if(unit1.type == unit_type_player) then unit = unit2
	else unit = unit1 end
	local item = scenario[unit.index]

	-- mark scenario as read
	if (unit.burnafterreading) then unit.state = unit_state_dead end
	item[2] = true
	
	-- give power to player
	if (item[4] == "shoot") then
		player.shootenable = true
		player.healthpoint = 3
	elseif (item[4] == "djump") then
		player.djumpenable = true
		player.healthpoint = 3
	elseif (item[4] == "cshoot") then
		player.shootenable, player.chargeshootenable = true, true
		player.healthpoint = 3

		-- place destructible wall and start transition animation
		mset(79, 46, 94)
		unit = initializeparticule(632, 368, newanimation(210,2,5), 10)
		unit.gravityafected = false
	elseif (item[4] == "key") then
		player.healthpoint = 3

		-- open boss room
		destroy(896, 368)
		scenario[5][2] = true
	end

	-- add item sprite to temporary hud list
	if (item[1] != 1) then
		unit = newunit(0, 120, unit_type_particule, newanimation(item[1], 1, 1))
		unit.life, unit.update = 30, updateparticle
		add(hudunit, unit)
	end

	-- show popup
	if (count(item[3])) then
		cam.popuptext = item[3]
		gamestate = game_state_popup
	end
end

-- ************************************************************************ rendering functions ************************************************************************
function drawunit(unit)
	if (unit.visible) then
		spr(unit.animations[unit.state].start + unit.pose * unit.sizex, unit.positionx, unit.positiony, unit.sizex, unit.sizey, (unit.direction < 0))
	end
end

function drawhudunit(unit, offset)
	if (unit.visible) then
		rectfill(cam.x + unit.positionx + offset, cam.y + unit.positiony, cam.x + unit.positionx + offset + 8, cam.y + unit.positiony + 8, 0)
		spr(unit.animations[unit.state].start + unit.pose, cam.x + unit.positionx + offset, cam.y + unit.positiony)
	end
end

function drawpopup()
	local h = max(16, 5*count(cam.popuptext))
	rect(cam.x + 23, cam.y + 63 - h, cam.x + 105, cam.y + 65 + h, 12)
	rectfill(cam.x + 24, cam.y + 64 - h, cam.x + 104, cam.y + 64 + h, 0)
	for i = 1, count(cam.popuptext) do
		print(cam.popuptext[i], cam.x + 65 - 2.0 * #cam.popuptext[i], cam.y + 60 - h + 8*i, 7)
	end
	print("\151", cam.x + 97, cam.y + 59 + h, 7)
end

function updatecameraposition()
	if (gamestate == game_state_camtransition) then
		local dx, dy = cam.targetx - cam.x, cam.targety - cam.y
		local d = sqrt(dx*dx + dy*dy)
		if(d < cam.speed) then
			cam.x, cam.y = cam.targetx, cam.targety
		else
			cam.x += cam.speed * dx / d
			cam.y += cam.speed * dy / d
		end
	else
		local tmproom = rooms[currentroom]
		cam.x, cam.y = mid(player.positionx - 64, tmproom[1], tmproom[1] + tmproom[3] - 128), mid(player.positiony - 64, tmproom[2], tmproom[2] + tmproom[4] - 128)
	end
end


-- ************************************************************************ controller functions ************************************************************************
-- update all button state. parameter define the current frame
-- if a button changing state is detected this time will be refered as the changing state time for the button
function updatecontroller(time)
	for i = 1, 7 do
		_controllerbuttonmap[i].previous = _controllerbuttonmap[i].state
		_controllerbuttonmap[i].state = btn(i-1)
		if (_controllerbuttonmap[i].previous != _controllerbuttonmap[i].state) then
			_controllerbuttonmap[i].time = time
		end
	end
end

-- return boolean true if button state change from pressed to up this frame 
function controllerbuttonup(button) return (not _controllerbuttonmap[button].state and _controllerbuttonmap[button].previous) end

-- return boolean true if button state change from up to pressed this frame
function controllerbuttondown(button) return (_controllerbuttonmap[button].state and not _controllerbuttonmap[button].previous) end

-- return boolean true if button state is pressed
function controllerbuttonispressed(button) return _controllerbuttonmap[button].state end

-- return time (in frame) when button state change. reference (zero) is programme start.
function controllergetstatechangetime(button) return _controllerbuttonmap[button].time end

-- return last button event code
function controllergetlast()
	local last, lasttime = 1, 0
	for i = 1, 7 do
		if(_controllerbuttonmap[i].time > lasttime) then
			lasttime = _controllerbuttonmap[i].time
			last = i
		end
	end
	return last
end


-- ************************************************************************ utils functions ************************************************************************
function newanimation(start, frames, time)
	return {
		start = start,
		frames = frames,
		time = time
	}
end

function newunit(x, y, type, idleanimation, width, height)
	width, height = width or 1, height or 1

	local unit = {
		positionx = x,									-- unit position on x axis
		positiony = y, 									-- unit position on x axis
		speedx = 0,										-- unit speed on x axis (could be positif or negatif)
		speedy = 0,										-- unit speed on y axis (could be positif or negatif)
		sizex = width, 									-- unit size on y axis (scale is in tile (8 pixel))
		sizey = height, 								-- unit size on y axis (scale is in tile (8 pixel))

		direction = 1,									-- unit direction. default is 1. if you want to flip unit on x axis direction is equals to -1
		gravityafected = true,							-- define if unit is afected by gravity
		traversable = false,							-- define if unit can cross traversable plateform
		state = unit_state_idle, 						-- unit state
		statetime = 0,									-- state time elapsed since the unit change its state
		damage = 0,										-- unit dammage

		animations = {},								-- animations list
		pose = 0,										-- used for animation state
		visible = true,									-- unit is visible (or not!)
		update = nil,									-- unit update function (machine state)
		controller = nil 								-- unit behaviour (ia)
	}

	unit.type = type 									-- unit type (see at file beginig to see full type list)
	unit.animations[unit_state_idle] = idleanimation	-- define idle animation
	unit.animations[unit_state_dead] = idleanimation	-- define dead animation. can be changed if you want (but define in "construcor" since it could cause a crash)
	return unit
end

function checkflag(x, y, flag) return fget(mget(flr(x/8),flr(y/8)), flag) end

function destroy(x, y)
	local particle = initializeparticule(8*flr(x/8), 8*flr(y/8), newanimation(205,2,5), 10)
	particle.gravityafected = false

	if(checkflag(x, y, flag_transmission)) then
		mset(flr(x/8), flr(y/8), 0)
		if(checkflag(x+8, y, flag_destructible)) then destroy(x+8,y) end
		if(checkflag(x-8, y, flag_destructible)) then destroy(x-8,y) end
		if(checkflag(x, y+8, flag_destructible)) then destroy(x,y+8) end
		if(checkflag(x, y-8, flag_destructible)) then destroy(x,y-8) end
	else mset(flr(x/8), flr(y/8), 0) end
end

function inroom(x, y, room)
	local tmp = rooms[room]
	if (mid(x, tmp[1], tmp[1] + tmp[3]) == x) and (mid(y, tmp[2], tmp[2] + tmp[4]) == y) then return true
	else return false end
end

function distance(unit1, unit2)
	local x = unit1.positionx - unit2.positionx
	local y = unit1.positiony - unit2.positiony
	return sqrt(x*x + y*y)
end


-- ************************************************************************ cartrige data/assets ************************************************************************
__gfx__
800000000000000004141400000000000000a0050001c000001000000000000000000e0000200000000000000000000000000088888000000007788778000000
080000800000000000a2204000000000060a006000c0000000c40400000000000000e000e0020000000008888800000000077887778800000072827777800000
0080080000000000000220000000000000567600001c00004201c2040028e0000000000200020000007788777880000000072827778800000078887877800000
00081000000000000000220000000000a0777760001c100047041c1404f88f000000e00e002e0000007282777888000000078887888880000008888888880000
000180000000000000000200000000000a6776a0c0c01100227444790888e2000002777777ee200000788878888880000000888888888880000eeeee88880000
008008000000000000000d00000000000007650a000c0000227221c900fe200000067e77e7e76000000888888888888000000eeee88888880000eeeee8888000
08000080000000000000ed00000000000050a0600010c000922cc7990000000000777e777e7772000000eeee888888800000022eee888880000022eee8888800
80000008000000000006600000000000060a000000cc010012c12221000000000577e77727e776500000022eee8888880000020eee888080000020eee8880880
0000000009990000099900000999000009990000000000000dd1cd00500000000677777e777e77600000020eee88808000000202ee8880800000202ee8800008
00000000c444c000c444c000c444c000c444c0000000000007d1cd10600000000777777277e7777000000202ee88808000000202208880807222202208800880
00000000ccccc000ccd66dddccccc000ccd66ddd00000000071cdd1070770700077777e7777e7770000002022088808000002202208808800222022288878800
00000000ccd66dddccddd46dccd66dddccddd46d0000000007dcd1c090ee030a0677777777777760000022022088088000002202208808800720022088008700
88800000ccddd46dcc4cdc00ccddd46dcc4cd00000008000017dcc7040880b010077777337777700000022022088088000007200200808070000002008800000
484c1cc0cc4cdc000cccd000cc4cdc000c00d0000008c80000dcc71020220c0d0067773bb3777600000072002008080700000070200807000000000200080000
ccccdc1c0c0cd0000c0c00000c0cd0000c00c000008c0c80011cd10000000000000677b00b766000000000702208870000000000200800000000000020008000
ccddd86d0c0c00000c0c0000c000c000c00c000008c000c8071cdd10000000000000663bb3600000000000000200800000000000200800000000000000000000
000000000d33ddd000cc4400000000000007aa00888828100188888201999928929994100108ee8282ee80002229222200000000000000000000770000770000
000000000ddd66d000cc04000c665c00007aaaa0288889212128888822499889229999402001ee22828e11002229999200000070000000000007887887887000
00000000d00d000000cc44000c666c0000aaaa90188881120229888202888928822e882100028228828e8012c17cc41900000777000777000087888787887000
00000000000d0000009900000ccccc00000a9900288118110188898288929929888892801021e228888e220077c1474c00007887787887700088788888887000
0000000000000000000000000c111c000008880028982920212228810442882882ee44800101282288eee00041c4249400087888887887000088888888878000
05c55c5000000000000000000c111c000008880088898212092882820149ee289222994200018e22e8e20e01404c440400088788888888000088887788888800
0cccccc0000000000000000000000000000808008828811002288898014992898228848000028e828e88800240c1400000888877888888000088877878888280
05c55c5000000000000000000000000000000000288818220121188802289228228948200222e28282282020000c000400888778788882200088878878880280
00000000700070000007070000000000090020001888822021188882219889288829ee282272772722772772000cc00080888788788800280008887888882080
00777770070700000070700007007700009002002882881099928881044ee22982298881277272772727727200c0000080088878888828280080888888800280
07777777070700070707007070070000077927902898811221288982024988288228e4220727772777277772001c000000808888888008208080208028800288
075575570706007007060070706007700792997288881291118188820188899888922e800677777777727760001c100000802080288002008080208020880028
0755755706e8e60006e8e6006e8e6000977299921289988228888221224ee228929ee9100077777777277720c0c0110000822880208800200008208020080020
007757706e8880066e888006e8880066207929901128888118882211014e2929222e11000067773bb3777602000c000000020800200880000000208002800200
00077700088888e0088888e088888e000299220011122888882221110012299112920000000677b00b7660000010c00000020880020080000002008020800000
0006760008222888082228888222888800222000000021222221000000001411191000000000667bb760000000cc010000000080000000000000080020080000
02222222222222222222222002222220000000000005000000222222222222222229222222222200505000000e10000000000000000d000d5555556600000555
24424242242424422424244224242442000500000055500002222229299999222229999292222220550000000110000000d00000000010015555566600005055
224944422444942424449422244494220000000005550050224299999999229924044449999922225050000001d10e1000100d00000011d15555556600050555
24499924429999924299944222999442050000000555055022242999224424292940440499922222500000001111111de100010001d001115555666600000055
2292999999992999999929222449292205000500555550552494422099404444440420949222222250055000111e111000101100100011115555566600050555
29242499994244499942429224924292050050055555555549429240444404404044440499292292055000001111111011101000011011110555666600005055
22424244442424244424242224242422055555505555555022244094400400404040400049922222550000001111111111111100001111115555566600000555
02222222222222222222222002222220555555555555555522992900000000000000000449929922550000001111111111111111111111115555566600005005
55551115555500000000000055555555555555555055000029944240299499400499499200244992000515001111111100000000000000000088ee8282ee8800
55115511111550000000500505555555555555555500000029994400292444000044492904449992000150001111111100e00000666600000888ee22828e8880
551665515111500000500055555555555555555555005000229990409240400000040229444999225005100511111111011001006666600002828228828e8820
5511655155215500000505550555555555555555555550002994040099400400004004994444499255051051111111111100d010666666000028e228888e2200
55512661512155000505555505555555555555555555000029922240949004404040094904222992011515101111111111000010666666600008282288eee000
555522215221550000005555055555555555555555555000290044444404000400004044444449920051510011111111010001105555666608822e22e8e28e80
555552552215550005555555000550555555555555555500290409004000004000440004049449920005100011111111011001000555566602828e828e888820
55555255221555000005555500000555555555555555500029494040000000000000000004449492000050001111111100111100555556660222e22282282220
555552551215555000050055555555555555555555555550222444000000400000000000004442220000000007000000000000000000000022429c4200000000
55555255521550500000555555555555555555555555555022440099400040040004400499040422240200000777000000000000000000002499c92200000000
555555555d155000500005555555555555555555555555009294444044040000400040440440492904404002002767000000000000000000249cc44200000000
555555050dd05500000555555555555555555555555500009299090094900440404009490494992900200220000776600000000000000000224dd12200000000
5555550500d100000055555555555555555555555555000092922004994004000440049940442929000000000007766000000000000000002449d9d200000000
555555000d21000005555555555555555555555555500000999994429940400000040499240049994200000200272660000007777777000022497cd200dcc100
55555000dd1100000005555555555555555555500500050099244400929444000044492994440499002042040027662000077777777270002444cc420dcc7c10
5555500dd11111100005055555555555555550500000000092944494299499400499492242242929040240400022620000777772222670002227c4d20dccc7c0
00000000224299425555555505555555505550500000000022299940000000000000000004499222555555560000000007777772666627002219c12222222222
000000d0242994225555555500055555505500500000000029942224000404000404004040949922555595a100000000077777726666670024149442244a7442
70000000244994425555555550055505505000500000000092992949420402040024440444994929555556110000000027277726666662002477d92479d49424
000000002299242255555555000505000000055000000000299944994404444420424044994499295545a11100772220277772666666667042cc9a9a9cc99719
0d00000024499242555555550005000500000000000050002292299222444449229444092992299955561111077266660277726666626620999cc9c1c91979cc
00000d0022499422555555500055000000500050050050002999992222222999999922942299999295a1111177266626072726666626266099121179ca41cc99
00000007244299425005050000550050005000000505555029222929922922999222929292922292561111117762666207726666626262204a24222444741914
00000000222499420000000000500000005000005555555502922222222222222222222222222920a11111112762262007226662662222002222222222222222
00000000000000000000000000867787777787778777877787778777877787768677877787778777877787778777877787778777877787778777877787778776
0095000c1c2c0000000c2c00006777778777877787769600000000009c6776000086778777877787778777877787760095000c2c00650000b386877686778776
86878777877787778777877787979c8c9c009d8c9c009d8c9d009c009c8c9d65958c8c9d9c9d9d9c9d005744009d9d009d9d9d9c9d574457009d9c9d9d9d8c65
009600000000000000000000d42f3f3f3f4f9dad8c66960034000000007d660086978c9d00725292a26282009d8c677696ac00000066000086979c8c349dad66
95d4b4b4c400000000000000000000000000000000000000000000000000c5669600005444574457445445455444445455444400254545455544575455000067
87970000000000004454000064847484943e4f000065957e00000000007d6500957e000000725292a262820000007d659500009e7d6500869717ac008c007d65
96b5b5b5b5c49e5c9e9e000000000000000000000000000000009ed4b4d4b5659500f4454545454545454545454545454545454545454545454545455600009e
9e9e0000000000253636570065a6a6a6955c3e4f3266967e00003c00000066009600000000725292a2628200005c9e6696000c2c0065b396ad347e5400007d66
95b54d4db504246474847484945c00000000000000000000009e6474942eb5669600f4454545454545454527454735454545454545454545454556379e5c6474
7484940000005436363636006777877685141414141497003c000000005c65009500000000735392a263830000041465957e00007d676097009d008d55255465
96b55f5fb52f4f677787777685949e0000000000000000009e6475a6953e2e65950000454527454527455600370000c6d6003747003705150037009e64747500
0000959e00003636373636009d9c8c65a695000000000000000000000c1c66009644570000440093a3000000000000669600000000177d347e00005d6d264566
95342eb5b5b52f4f00009d677685949e7c5c5c5c5c5c5c9e647500a696023e669600004537000515003700009e5c7cc7d75c5c9e000006169e5c7c6475000000
0000859400f4365600473655000000658697445400000000042400000000650095355600254555544425a4000044006595ac0c2c00347e9d0000005e6e008d65
963e3f2eb5b5b52f4f00009d677797747484748474847484750000008574847595000045009e0616000064748474847484748474847484748474847500000000
0000869700f4365500573636550000669525455500000000000000007c00660096000025454545563736442545560066967e000000000000005ca66494003766
8574943e2eb5b5b52f4f0000ad8c67877787768777767787778777877787760096000045000c1c2c000067778777877777877787778777877787877600000000
0000959d3c002736443636365600006596454556000000000000006474747500950000f44545560000474545a400006585847484847484748474847596442065
0000857484740d942e2f4f00000034009dad179d9d17ad9d8c9d179d9d0067769500004700000000000000008c9d473745559d8c8c8c000000009c6500000000
0086970000000035363636470000006695464700006474747474747500000000965757443545555700573546445757660000000000000000000000a6951c1c66
00000000a6000085944e2f4f0000000000003400003400000000340000008c66960000000000c6d6000000000000002545560000000000009e00006600000000
00958c00003c0000473627000000d465963700000465008677877787760000009637354556373636443636353546566500000000000000000000a68697000065
00868777877600a6955c4e2f4f00000000000000000000000000000000000066959e5c00009ec7d7000000000000f445470057545757000034007d6500000000
00960000009e9e0000370000c5d4647596003c00006776969c8c9dad67760000950000000000354645464700000000665000000000000000008677979d009e66
0095009d8c671d768584944e2f4f00000000000000000034000000000000d4659514142400041424009e000000572545572545454545550017007d6600000000
0095009e006424000000d4b4641414769500000000006797ac0000007d66000095000000000000474545a40000000065500000000000867777979d0000006475
0096000000000065000085944e2f4f0000340000000000170000340000d4b5679700000000008c9d003c7e002645454545454545450515001700006500000000
0096003400349d0000d4b5b5179d9c679700003c0000e5f50000c6d600650000959e0000000000003745550000000067608777877787979c9d0000009e5c6600
0095325c9e9e9e660000a685944e2f4f00170000340000170000170034b5b52f3f4f0000009e9e9e9e9e9e254545454545454556340616a61700326600000000
00959e5c5c5c5c9ed4b5b53417025700000000000000e5f5b657c7d79e66000085945c9e00b70000003726545744545c61000000000000009e5c648474847500
0085748474847475000000a685748474747574847584747574847484748474847484748474847484748474847484848474847484748474847484747500000000
00857484748474847484747585748474847484748474847474847484747500000085748474847484748474847484748474847484748474847484750000000000
02222222222222222222222002222220055555500f0000000000000000000000d2202d200200022200d000000008990000008090008000000000000000000000
224244222242442222424422224244225515115500d000000000000000000000020220d0026002d0220200000009800000009890000000000000008000000000
224242424242424242424242224242425515151500d00f0000777700077700000d00d0d006a60dd00000d0000098000000008900000000000088080000000000
2d42244d2d42244d2d4224422d422442511551150020d00007cc2c60077270000d0020d00060dd00a00000000088980000898800000000080008802000008000
22dd2dddd2dd2dddd2d42dd222dd2dd25511511500d0d00f07722660072627000d0d000d000df00000000000008aa980089aa800208000000008800000082800
0200200d0000200d0000200d020020d005005055d020d0d022cc222007266220d000d000000faf002d0d000008aaaa908aaa8980000002000088080200028000
d0000d0000020000000d000000d00e00051555500d2020d02266622227226292000000000000f0000020a00009a98a98aaa89990000000080000000000000000
00000000000000000000000000000000500005002222202022262222222726990000000000000000d0000000988aa999aaaaa889080200000080000000000000
2222222200000000088ee822011771660222222055552225555500000000000055555555a0200020022000200000000000000000000000000000000000000000
2999992200040400888ee22e111776672242442255229922222550000000002005555555000d00d00d0d00d00000000000000000000000000000000000000000
99992299420402042828228e6161661722424242552999925222500000000d02055555550000020002000d200000000003000000000000000ccc0c1000000000
2244242944044444028e2288061766112d422442552299925542550000000000055555550000000000d002000000300000000b000000000000ccc100000c1000
9940444422444449008282280016166122dd2dd255524992524255000000000000555555000000000000a000000000300000bab000c01001011cc000000ccc00
44440440222229998822e22211667666121020d05555444254425500000000020055555500000000000000000000000000000b0000c00c0000cc0c0000010000
40040040922922992828e8226161716601d10e0105555455442555000000000205555555000000000000000000000b000ba00000cc100c0000c0100000000000
0000000022222222222e222e66676667101010100555545544255500000000d0555555550000000000000000000300033bb30000000000000000000000000000
3333333333333333011111110101010101111111005554552425555000d000001111111100000000000000000000000000a77a0000077000000aa00000000000
3bb333333bb333b310111111001010100011111100555455542550502d00000011111110000000000000000009000090090000900a7007a009a77a9000000000
3b33bb3333b333b301011111000101010001111100555555542550000000000011111101000000000000700800000000a000000a070000700a7777a0000aa000
bb333bb33bb3bb33101011110000101000001111050555050440550000000000111110100000000000000790000000007000000770000007a777777a00aa7a00
3bb333b333b3b3330101011100000101000001115500550500420000200000001111010100000000000007a7000000007000000770000007a777777a00a7aa00
3b33bbb333b3bbb310101011000000100000001100000500044200000d00000011101010000f00000000007000000000a000000a070000700a7777a0000aa000
bbb3bbb33bb333b3010101010000000100000001000050004422000000000000110101010e0020000000070009000090090000900a7007a009a77a9000000000
3bbbbbbb3bbbbbbb10101010000000000000000000005004422222200000000010101010020200f0000007000000000000a77a0000077000000aa00000000000
000000000000000001010101010101010000000001010101555545a60101010100000001000000000000000000000000000003b0000000300000000000000000
0000000000000000101010101010101010000000101010105554596a10101011000000100003b330000000000000000000000000000030000000000000000000
000000000000000011010101010101010100000011010101555545a6010101110000010103bbba730003bbb3000000000000000b000000b00000030000000000
0000600000000600111010101010101010100000111010105554696a1010111100001010bbb7aaaabbbaaaaa000030000000000000000bb000000bbb000000bb
000000000000000011110101010101010101000011111111555546a6010111110001010103bbba730003bbb30000003000000003000bbb0b0003bbbb000000bb
0000050005000000111110101010101010101000111111110554696a10111111001010100003b3300000000000000000000003b000000bb00000300000000000
000000000000000011111101010101010101010011111111555546a60111111101010101000000000000000000000b0000000000000000b30000000000000000
0000000000000000111111101010101010101010111111115554596a1111111110101010000000000000000000030003000b3030000003000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400004994992
00000000000440040004040004040040000404000404004000040400040400400004040004040040000404000404004000040400040400404000400400444929
00000000400040444204020400244404420402040024440442040204002444044204020400244404420402040024440442040204002444044404000000040229
00000000404009494404444420424044440444442042404444044444204240444404444420424044440444442042404444044444204240449490044000400499
00000000044004992244444922944409224444492294440922444449229444092244444922944409224444492294440922444449229444099940040040400949
00000000000404992222299999992294222229999999229422222999999922942222299999992294222229999999229422222999999922949940400000004044
00000000004449299229229992229292922922999222929292292299922292929229229992229292922922999222929292292299922292929294440000440004
00000000049949222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222994994000000000
0000000004499222d2202d20a020002000000000088ee822000000000000000000000000000000000000000002000222a0200020d2202d202229994400004000
0004400440949922020220d0000d00d000000000888ee22e0000000000000000000000000000000000000000026002d0000d00d0020220d02994222440004004
40004044449949290d00d0d000000200000000002828228e000000000000000000000000000000000000000006a60dd0000002000d00d0d09299294944040000
40400949994499290d0020d00000000000000000028e228800000000000000000000000000000000000000000060dd00000000000d0020d02999449994900440
04400499299229990d0d000d0000000000000000008282280000000000000000000000000000000000000000000df000000000000d0d000d2292299299400400
0004049922999992d000d00000000000000000008822e2220000000000000000000000000000000000000000000faf0000000000d000d0002999992299404000
00444929929222920000000000000000000000002828e82200000000000000000000000000000000000000000000f00000000000000000002922292992944400
0499492222222920000000000000000000000000222e222e00000000000000000000000000000000000000000000000000000000000000000292222229949940
0024499200d00000000000000000000000000000088ee8220000667711111c1c11111c1c76000000000000000000000000000000000000000000000029944240
044499922d000000000000000000000000000000888ee22e00067777cccccccccccccccc77660000000000000000000000000000000000000000002029994400
44499922000000000000000000000000000000002828228e00677777cccccccccccccccc777760200000000000000000000000000000000000000d0222999040
4444499200000000000000000000000000000000028e2288007777777cccccc77cccccc772777200000000000000000000000000000000000000000029940400
04222992200000000000000000000000000000000082822806777777777777777777777727777600000000000000000000000000000000000000000029922240
444449920d0000000000000000000000000000008822e22207277727777777277777772772777720000000000000000000000000000000000000000229004444
04944992000000000000000000000000000000002828e82227727277772777727727777272772722000000000000000000000000000000000000000229040900
0444949200000000000000000000000000000000222e222e2272772772772727727727272772772200000000000000000000000000000000000000d029494040
0044422200000000000000000000000000000000088ee822242422224442244444422444222242255555000000000000000000000f0000000000000022244400
9904042200000000000000000000000000000000888ee22e5242222244444244444442442422225555000000000000000000000000d000000000000022440099
04404929000000000000000000000000000000002828228e5224424494449444944494444424422255005000000000000000000000d00f000000000092944440
0494992900000000000000000000000000000000028e2288224244444444444444444444424424255555500000000000000000000020d0000000000092990900
4044292900000000000000000000000000000000008282282244424444444424444444244444242255550000000000000000000000d0d00f0000000092922004
24004999000000000000000000000000000000008822e22222244444444442944444429444424422555550000000000000000000d020d0d0000f000099999442
94440499000000000000000000000000000000002828e822224444442449444424494444424242225555550000000000000000000d2020d00e00200099244400
4224292900000000000000000000000000000000222e222e2244442444444444444444444424444255555000000000000000000022222020020200f092944494
00244992000000000000000000000000000505502424222244477794497999999777774449444444222242255555000000000000022222222222222229944240
04449992000000000000000000000000505550555242222249799999797777799999997444944294242222555500000000000000244242422424244229994400
44499922000000000000000000000000055255055224424442799949999999999499992299777794442442225500500000000000224944422444942422999040
4444499200000000000000000000000055552552224244444424999999999992994999229777cc72424424255555500000000000244999244299999229940400
0422299200000000000000000000000050552525224442444429499994299999499992429766cc62444424225555000000000000229299999999299929922240
44444992000000000000000000000000555525522224444444422229422222222929222427966762444244225555500000000000292424999942444929004444
04944992000000000000000000000000552522252244444444424222424242242992244442992224424242225555550000000000224242444424242429040900
04449492000000000000000000000000522552222244442444224244224224242222444442222444442444425555500000000000022222222222222229494040
00444222000000000000000000050000242422224442244444422444444224444944244444222424494424442222422555550000000000000000000022244400
99040422000500000000000000555000524222224444424444444244444442444494424442942444449442442422225555000000000000000000000022440099
04404929000000000000000005550050522442449444944494449444944494444779279442442444477927944424422255005000000000000000000092944440
04949929050000000000000005550555224244444444444444444444444444444792997244442244479299724244242555555000000000000000000092990900
40442929050005000000500055555055224442444444442444444424444444249772999242944424977299924444242255550000000000000000000092922004
24004999050050050500500055555555222444444444429444444294444442942479299442422494247929944442442255555000000000000000000099999442
94440499055555500505555055555555224444442449444424494444244944444299224444444444429922444242422255555500000000000000000099244400
42242929555555555555555555555555224444244444444444444444444444444422244444429444442224444424444255555000000000000000000092944494
00244992022222200222222055555555224444444944244449444444444224444442244449444444444444224444442255555550000000000000000029944240
04449992224244222242442255555555222444444494424444944294444442444444424444944294444242224442242255555550000500000000000029994400
44499922224242422242424255555555224224244779279499777794944494449444944499777794444444224244242255555500000000000000000022999040
444449922d4224422d4224425555555522224444479299729777cc7244444444444444449777cc72444444224244424255550000050000000000000029940400
0422299222dd2dd222dd2dd25555555522444444977299929766cc6244444424444444249766cc62444224224424225255550000050005000000000029922240
44444992020020d0020020d055555555224444442479299427966762444442944444429427966762442442222442422555500000050050050000000029004444
0494499200d00e0000d00e0055555555224424444299224442992224244944442449444442992224444442222222422505000500055555500000000029040900
04449492000000000000000055555555222244444422244442222444444444444444444442222444444444222222525500000000555555550000000029494040
00444222000000000000000055555555224444244442244444222424444777949777774444222424444444225222522502222220022222200000000022244400
99040422000000000000000005555555524442424444424442942444497999999999997442942444444242225522225522424422224244220000000022440099
04404929000000000000000055555555242242449444944442442444427999499499992242442444444444225225525522424242224242420000000092944440
0494992900000000000000000555555522242444444444444444224444249999994999224444224444444422552555552d4224422d4224420000000092990900
40442929000000000000000005555555252422244444442442944424442949994999924242944424444224225552552522dd2dd222dd2dd20000000092922004
240049990000000000000000055555555242524244444294424224944442222929292224424224944424422255225555020020d0020020d00000000099999442
94440499000000000000000000055055252422222449444444444444444242222992244444444444444442225525555500d00e0000d00e000000000099244400
42242929000000000000000000000555552252524444444444429444442242442222444444429444444444225555555500000000000000000000000092944494
00244992000000000000000000000000555555552244442444422444442224244944444444422444444444225555555500000000000000000000000029944240
04449992000000000000000000000000555555555244424244444244429424444494429444444244444224225555555500000000000000000000000029994400
44499922000000000000000000000000555555552422424494449444424424449977779494449444424424225555555500000000000000000000000022999040
44444992000000000000000000000000555555552224244444444444444422449777cc7244444444424442425555555500000000000000000000000029940400
04222992000000000000000000000000555555552524222444444424429444249766cc6244444424442422525555555500000000000000000000000029922240
44444992000000000000000000000000555555555242524244444294424224942796676244444294244242255555555500000000000000000000000029004444
04944992000000000000000000000000555555552524222224494444444444444299222424494444222242255555555500000000000000000000000029040900
04449492000000000000000000000000555555555522525244444444444294444222244444444444222252555555555500000000000000000000000029494040
00444222000000000000000000000000555555555555555522444424244444224422242444444422522252255555555500000000000000000000000022244400
99040422000000000000000000050000055555555555555552444242244442424294244444422422552222555555555500050000000000000000000022440099
04404929000000000000000000000000555555555555555524224244244444424244244442442422522552555555555500000000000000000000000092944440
04949929000000000000000005000000055555555555555522242444244444424444224442444242552555555555555505000000000000000000000092990900
40442929000050000000500005000500055555555555555525242224224444224294442444242252555255255555555505000500000050000000500092922004
24004999050050000500500005005005055555555555555552425242522442254242249424424225552255555555555505005005050050000500500099999442
94440499050555500505555005555550000550555555555525242222252222524444444422224225552555555555555005555550050555500505555099244400
42242929555555555555555555555555000005555555555555225252552225254442944422225255555555555555505055555555555555555555555592944494
00444222022222200222222002222220022222200555555552225225222252522444442222225252555555550222222002222220022222200222222029944240
99040422224244222242442222424422224244220005555555222255225222252444424222522225555555552242442222424422224244222242442229994400
04404929224242422242424222424242224242425005550552255255522252522444444252225252555555552242424222424242224242422242424222999040
049499292d4224422d4224422d4224422d4224420005050055255555522522552444444252252255555555552d4224422d4224422d4224422d42244229940400
4044292922dd2dd222dd2dd222dd2dd222dd2dd200050005555255255255525522444422525552555555555522dd2dd222dd2dd222dd2dd222dd2dd229922240
24004999020020d0020020d0020020d0020020d0005500005522555552255555522442255225555555555555020020d0020020d0020020d0020020d029004444
9444049900d00e0000d00e0000d00e0000d00e0000550050552555555525555525222252552555555555555500d00e0000d00e0000d00e0000d00e0029040900
42242929000000000000000000000000000000000050000055555555555555555522252555555555555555550000000000000000000000000000000029494040
00244992000000000000000000000000000000000000000055555555555555555222522555555555505550500000000000000000000000000000000022244400
04449992000000000000000000000000000000000000000005555555555555555522225555555555505500500000000000000000000000000000000022440099
44499922000000000000000000000000000000000000000055555555555555555225525555555555505000500000000000000000000000000000000092944440
44444992000000000000000000000000000000000000000005555555555555555525555555555555000005500000000000000000000000000000000092990900
04222992000000000000000000000000000000000000000005555555555555555552552555555555000000000000000000000000000000000000000092922004
44444992000000000000000000000000000000000000000005555555555555555522555555555555005000500000000000000000000000000000000099999442
04944992000000000000000000000000000000000000000000055055555555505525555555555550005000000000000000000000000000000000000099244400
04449492000000000000000000000000000000000000000000000555555550505555555555555050005000000000000000000000000000000000000092944494
00244992000000000000000000000000000000000000000000000000505550505555555555555555555500000000000000000000000000000000000029944240
04449992000000000000000000000000000000000000000000000000505500505555555555555555550000000000000000000000000000000000000029994400
44499922000000000000000000000000000000000000000000000000505000505555555555555555550050000000000000000000000000000000000022999040
44444992000000000000000000000000000000000000000000000000000005505555555555555555555550000000000000000000000000000000000029940400
042229920000000000000000000000000000000000000000000000000000000055555555555555555555000000000000000000000000000000000000cc92cc40
4444499200000000000000000000000000000000000000000000000000500050555555555555555555555000000000000000000000000000000000002c004c44
0494499200000000000000000000000000000000000000000000000000500000555555555555555555555500000000000000000000000000000000002c040c00
0444949200000000000000000000000000000000000000000000000000500000555555555555555555555000000000000000000000000000000000002c494c40
002449920000000000000000000000000000000000000000000000000000000005555555555555555055505000000000000000000000000000000000ccc9ccc4
04449992000000000000000000000000000000000000000000000000000000000005555555555555505500500000000000000000000000000000000029942224
444999220000000000000000000000000000000000000000000000000000000050055505555555555050005000000000000000000000000000000000c2c9c949
444449920000000000000000000000000000000000000000000000000000000000050500555555550000055000000000000000000000000000000000c9c9c499
042229920000000000000000000000000000000000000000000000000000000000050005555555550000000000000000000000000000000000000000ccc2ccc2
44444992000000000000000000000000000000000000000000000000000000000055000055555555005000500000000000000000000000000000000029c9c9c2
04944992000000000000000000000000000000000000000000000000000000000055005055555555005000000000000000000000000000000000000029c2ccc9
04449492000000000000000000000000000000000000000000000000000000000050000055555555005000000000000000000000000000000000000002922222
0499499222222200000000000000000000000000000000000000000000000000000000000555555500000000000000000000000000000000000000000ccc0000
004449299222222000000000000000000000000000000000000000000000000000000000000555550005000000000000000000000000000000000000c444c000
000402299999222200000000000000000000000000000000000000000000000000000000500555050000000000000000000000000000000000000000cccccf00
004004999992222200000000000000000000000000772220000000000000000000000000000505000500000000000000000000000000000000000000ccd66ddd
404009499222222200000000000000000000000007726666000000000000000000000000000500050500050000000000000000000000000000000000ccddd46d
0000404499292292000f00000000000000000000772666260000000000000000000000000055000005005005000000000000000000000000000f0000cc4cdcd0
00440004499222220e00200000000000000000007762666200000000000000000000000000550050055555500000000000000000000000000e0020000c2cd0d0
0000000049929922020200f00000000000000000276226200000000000000000000000000050000055555555000000000000000000000000020200f02c2c2020
00000000049949922222222222292222222222222229222222222222222922222222222222292222222222222229222222222222222922222222222222292222
00000000004449292999992222299992299999222229999229999922222999922999992222299992299999222229999229999922222999922999992222299992
00000000000402299999229924044449999922992404444999992299240444499999229924044449999922992404444999992299240444499999229924044449
00000000004004992244242929404404224424292940440422442429294044042244242929404404224424292940440422442429294044042244242929404404
00000000404009499940444444042094994044444404209499404444440420949940444444042094994044444404209499404444440420949940444444042094
00000000000040444444044040444404444404404044440444440440404444044444044040444404444404404044440444440440404444044444044040444404
00000000004400044004004040404000400400404040400040040040404040004004004040404000400400404040400040040040404040004004004040404000
00000000000000000000000000000004000000000000000400000000000000040000000000000004000000000000000400000000000000040000000000000004

__gff__
0000001a001a020200080000000000000000000000000202000000000000000000000000001212121212120200000000000000001e1212121202021a000000000202020200000202020200000000020000000000000002020202000000021a1a0000000000000202020200000000020000020000000002020202020000000202
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004040404000000000000001010000000040402000400000000000000000000001010000000000000000000000000000000000000000002000000000000000000
__map__
00700000000000000000000000000056687778777877787778777877787778676878777877787778777877787778670068777877787778777877787778777867006877787778777877787778777878676877787778777877787778777877787778777877787778777877787778776777676878687867000000005849f3767767
00000000000000f000000000007000565923000000c8004400c800c9c8c800565900c9c800c9c8c800c900c9c8c8666a69e7000000c800c800c80000c800c9560059e7d902c9c800d9000000c8d9d9565900c8d9c9c800d9c900c8d900d771d9d743d771d90043d971dad943dac971c87679d943d976776700000069e3f4da56
0000525455f1000000000045000000665849000000005263454444455500006669e70045440000000000000000d7566a59e76c6d0062454444454444000000660069ca000400000000000000c5234d5669e700000000000000000000000043e700000043e70000d7430000d900004300d94300c900d9c87667000069cae3f466
000054000000005255004563000000566841414200626363636363636500d75659e762636500000000c5000000d7660069e77c7d00007365536365740000d7560059e7000000e94d4b00004d4041427679006f000000000000000000000000000000000000000000da0000000000d90000430000004544c976670059e700e356
0000540062550062540063730000f1665900000000005363637263650000d76669006372d7404141414142e74c4d767779404142000000c5007400000000d766006900000000d4e25b4b4d5bf2f3f3f3f3f46e000000000000000000430000000000000000000000000000000000000000c800006263650000560069e700d766
75005363636500536500536300000056690000c700626350510073000000007679e773000000c5c5c5c5004d5b5bf2f3f3f3f3f3f4464749e700d7c0c200d75668790000004df2f3e25b5b5b5bf2404149e36e004300000000000000000043000000000043000000000000004300000000000062637200000076777900000056
4f5d0045550070007500007444000066584748474849536061000000006b0000000000d746484747484748495b5b5bf2f3f3f3f3f3566a59e70000000000d76659d900e94d5b5bf5f55b5b5b5b5bf26669e76e0071004300000043000000000000430000710000004300000071004300000000007300000000005e5fe9000066
004e00534400450063004500635455566a00006a6a6a4748490000c0c2464748474847485700000000000058474747474847484748576a59000000e90000005669000043e25b5b5b5b5b5b5b5b5b5b5669417e7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f2b4748414142000056
004e0000540054546300540054736566687877787778777879e70000d756000068777877787778777877787778777867687778777877787900c0c1c2e700005659000071f35b5b5b5b5b5b5b5b5b5b66592375000000e9000000e9e9000000d900da46474879c8d900000000000000e9e900d944d9c86605006879dad9000066
004e5d6265f1740063005400547400566900dac9c8c9dad9d9c3000000766700590000c8440000c90044000000c800566900d9c9d9dac8d90000000000c5006669e9c571f35b5b5b5b5b5b5b5b5b5b56694141424440420043d74042e74300000000766759e700230000e9e9004d4b464900525051d756056879d9005c4d4b56
00724e00f0000000634a74007300006659e70052454575750000000000e9566a690000626345754445634575000000665900004445754555754544d7c0c2d7566841414141425b5b5b5b5b5b5b5b5b665963636363545455747574e900d9e9000000c9565849c54649c546494d5bd4665952546061c5660059d9004d5b5b4366
0052f6000000f100730000000000005669e7526363636363550000d740417667590052636363636363636363550000566900526363636363727265000000d76659d9da71f3f3e25b5b5b5b5b5b43e25669414141414141414141414141414200000000660058475758485769c2e2f2566953404141416668794b4d5b5be8f366
004ff6000000000000000000004d4b7679e762636363636365007b000000c556690062636363636363657365000000665900626363657473000000e9000000566900d743f3f3f3e25b5b5b5b5b71f37679dad9dad9d9d9d9d9c8d9da0000000000000076777877787778777900e3e2665952545454555659f75b5b5be8f3f356
4f4ff600000000000000005c4d5b5bf2f3f473635051737400404141414141417900007372727372730000000000005669005272d5d60000c0c1c1c2e700006659c500f8f3f3f3f3e25b5b5b5b71f3f400000000007500000000000000000000c0c20000c943d900c843e700d743e35669414141426566695b5b5be8f3f3f366
4f4ff6000000000000004d5b5b5b5b5bf2f3f473606175000000000000000000000000c500c5007b00c5c500c520006659005a00e5e6c50000e9e9e9e9c7e9565847484749f343f343e243e24647484749c50000526345457544750000c50000000000000000004300000043e9e9c5665900734a7400795849e8c3f3f3f3f356
4f4f4e46474747484748474847484748484748474847484748474847484748474748474847484748474847484748475769c0c1c24647484748474847484748570000687879e3f4e3f4e3f3f3767777675847484748474847474847484748474847484748474847484748474847484757474900404141660069f3f4e3f3f3f366
4f4f4e57006877787778777877787778777877787778777877787778777877787778777877786700000000000000006a5900000056000000000000000000000068787900c900e3c0c2f4e3f3f4dac95668777877787778777877787778777877787778777877787778777877787778670059000000da766759f3f3c0c2e3f356
4f4f4e676a59f3f3f3f3f3f400c8c9c9d9c9d9d9d97500c9d9c9d9d9d9d9c9d9d900d900d9da7677787778777867000069e7c3d77677787778777877787778675900c8000000000000e3f4e3f3f4d7665923d9dad9dad9dac8d9000075757500da00d9dad9c8da00c9c8d9d900c80056005849000000da6669f3f3f40000e356
004f4e767779f3f3f3f3f3f3f40000e9c5c5e900526345457544756b00e90000000000000000c8c9c875d9c9c876676a597b000000d90000d9dac9c8dad9d75669000000000000000000c0c1c2e3f4565849000000000045524575525454545500000000000000000000000000004b660000584900c300565943e3f3f4d74066
00527a5b5b5bf2f3f3f3f3f3f3f4464847484748474847484748474847484748474849006c6d62555263454400c87667584748494b4c0000000000000000d7665900000000000000c50000000000e36668796c6d000062545454545454545051000000000000000000000000004d5b56687778790000006669d900e3f3f4da56
527a5b5b5b5b5bf2f3f3f34647485700687778777877787778777877787778676a6a69007c7d0053636363635500c95668777841414142e900004d4b4cc54d56690000000000c0c1c1c200000000005659e97c7dc55254545454545454656061c5c500000000000000005c6b4d5b5b6659e7dad900c3005659000000c3e3f466
495b5b5b5b5b5b5b464748570000006a69c8c900c90000d9d9d9d9c8d9c9d7566a6a584847484900745363d5d600d77679e7dac8d74041414141425b5b43e26659000000000000000000000000004d6658414141414141414141414141414141414200004041414141414141414141676900000000004d6669ca00000000e356
595b5b5b46474847570000000000000059e7000000000000e90000454400d76668787778676a59c5c50074e5e6c5000000000000f8f3f3f3f3f3f75b5bf2f3565849000000000000000000c30040416759c8c9d9d9d9da00d9d9000000c9dac800000000d9c9d90000d900c9c8d9da56590000004041415759e7c3000000e966
5841425b5600000000000000000000006900000000000000430052545455d7566923005e666a584748474847484748474847484748474847484748474847485768794200000000000000000000d9c86659e900000000005c4d4b4ce9e90000006b000000000000c50000e900000000666900c300d9dac9566900000000d74066
59f3f75b66000000000000000000000059000000d74042e9715263545465d7666841425e7678777877787778777877676878777877777877787778777877786759c8c90000000000c0c20000000000565849e9004d4b4d5b5b5b5b464748474849404141414141414141414142e7e9565900000000000056590000000000d756
69f7e84076777877787877787778670069e7c0c20000c846584953635455d75659c8005e5f000000c9c8c80000c9c85659d9c9d9c8c8c9c8c8c9d9c9c8c8d95669e7000000000000c9d900450000d7660058494d5b5b5b5b43e25b766700000059c8d9dad9d900d9d9000000000046576900d743e700006669e70000e9000056
59e8f3f4c8d9c8c9c8c8d9c9d9d7560059000000e90000560059e773546500666900d7c0c2000000000000000000006669e7000000000000000000000000d7665900000000d7c0c2e70062635500d756006a595b5b5b5b5bf2f3e25b56000000690000000000000000000000e9c56600590000000000e95659ca00c0c200e966
69f3c0c2000000000000000000d7666a690000c0c200d7660069e7007400d75659e700000000c0c1c2e700e90000005659e7000000000000000000000000d75669e7000000000000005263636500006668774248474849e25bf2f3e25600000059004041490000464141484847485700690000000000436669e7004400004356
59f3f400d7c0c2e700e9000000d77677790000000000465700584900000000666900000000000000000000430000006669e7000000000000000000000000d7665900d7c0c1c2e700004f63635500d75659007677786769e3c0c1c2e3560000006900dad976414179c976777877787778790000000000d97679e752545500d966
69f3f3f4000000d7c0c1c2e7000000000000c0c200455600000059000000007679e700000000000000e94649004d4b7679000000000000006c6d00000000007679e70000000000e90000536365000076790000000056590000000000560000005900000000000000000000000000000000000000000000dac800737465007b56
59f3f3f3f40000c5c5c5c50044457b44c5c5c5c562636600000069c5c5c700000000e9c500c5e9e9004657694d5b5bf2f3f4e9c5c5c5c7c57c7dc5c5c56be9e9000000000000c0c1c2e7007300e9c7e9e9e9c5c6e966690000000000560000005848474847484748474847484749c5e90000000000000000000000e9c5464857
584748474847484748474847484748474847484748475700000058474847484747484748474847484757005847484748474847484748474847484748474847484749000000e90000000000000046474847484748475759e70043430076670000000000000000000000000000005847484900e900004647482b48474847570000
__sfx__
000400000f5500a550105500f5500c550075500355001550025500155000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000f00000f0201002013030160401a0601e06023070130501f0001e0002000012000140001600014000147001270013700100001200014000190001d000280000000000000000000000000000000000000000000
00140008015003f5303f5503f5703f5503f5300150001500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000200002845024450214501c45016450124500e45009650066500364001640026000160000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
0001000001150011500315004150071500b1500f15013150001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
0002000015650090501565008050070500405004050020500370002000347000a7000770000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00080000286501f650116500b6400a6300260002600016000260002600081000810009100091000810006100061000610006100071000b3000000000000000000000000000000000000000000000000000000000
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

