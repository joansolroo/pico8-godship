pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

-- ************************************************************************ global variables ************************************************************************
-- button inputs
button_left   = 0
button_right  = 1
button_up     = 2
button_down	  = 3
button_action = 4
button_jump   = 5
button_previous = {}

-- player constants
state_idle    = 0
state_walk    = 1
state_jump    = 2
state_djump   = 3
state_falling = 4

-- material flags
flag_none   	 = 0
flag_solid  	 = 1
flag_traversable = 2
flag_destructible= 3
flag_enemy		 = 4

-- physics variables
gravity = 0.3
max_body_speed = 4
jump_speed = - 11 * gravity
walk_speed = 1.80
friction = 1
colision_margin = 1
bullet_range = 30
charge_shoot_time = 20
charge_damage = 10
damage_timer = 60

-- type
type_thing = 0
type_body  = 1
type_unit  = 2
type_player= 3
type_bullet= 4
type_scenario = 5
type_monster = 6

-- monster type
type_walking = 0
type_flying = 1
type_jumping = 2

-- keep track of number of instance created from start
instance_counter = 0
particles_counter = 0

-- instance list to animate via physics, or for collision stuff
physics = {}

-- instance list to animate via ai or particle

ai = {}
particles = {}
monsters = {}

game_elements = {}

-- global time from start
global_time = 0

-- room format : {posx, posy, width, height, {neighbors room, ...}, {monster, ...}}
-- monster format : {posx, posy, type, looking direction}
-- rooms
rooms = {
	{0,0, 16*8, 16*8, {2,8}, {}},					--1
	{16*8, 0, 16*8, 16*8, {1,3}, {{28*8, 10*8, 0, 1}}},			--2
	{16*16, 0, 16*8, 16*8, {2,4}, {{39*8, 3*8, 0, 1}}},			--3
	{16*24, 0, 16*8, 16*8, {3,5}, {{59*8, 4*8, 0, 1},{59*8, 7*8, 0, 1},{57*8, 12*8, 0, 1}}},			--4
	{16*8*3, 16*8, 16*8, 16*8, {4,6,9}, {{54*8, 19*8, 0, 1},{57*8, 20*8, 0, 1},{50*8, 22*8, 0, 1},{58*8, 27*8, 2, 1}}},	--5
	{16*16, 16*8, 16*8, 16*8, {5,7}, {}},		--6
	{16*8, 16*8, 16*8, 16*8, {6,8}, {{22*8, 23*8, 0, 1}}},		--7
	{0, 16*8, 16*8, 16*8, {7, 1}, {}},				--8
	{16*8*4, 0, 16*8, 16*8*3, {5,10,12,15}, {}},--9
	{16*8*2, 16*8*2, 16*8*2, 16*8, {9,11}, {}}, --10
	{0, 16*8*2, 16*8*2, 16*8, {10}, {}},		--11
	{16*8*5, 0, 16*8*2, 16*8, {9,13}, {}},		--12
	{16*8*7, 0, 16*8, 16*8*3, {12,14,16}, {}},	--13
	{16*8*6, 16*8, 16*8, 16*8, {13,15}, {}},	--14
	{16*8*5, 16*8, 16*8, 16*8*2, {14,9}, {}},	--15
	{16*8*6, 16*8*2, 16*8, 16*8, {13}, {}}		--16
}
current_room = 1

-- scenarios and power up
game_elements = {}

-- game state
game_on_popup = true
popup_text_line1 = "let the game"
popup_text_line2 = "begin !!"

-- ************************************************************************ init functions ************************************************************************
-- init function entry of pico 8
function _init()
  music(5)
  init_player()
  init_scenario()
end

-- init player : machine state / physics / ...
function init_player()
	-- add player
	player = new_unit(7*8, 14*8, 1, 1)
	player.djump_available = true	-- used by machine state : you have to land after a djump before to reuse it
	player.type = type_player		-- unit type
	player.sprite = 17				-- unit default sprite. useless here since player have animation but who knows

	player.animations = {}
	player.animations[state_idle] = new_animation(17, 2, 30)
	player.animations[state_walk] = new_animation(19, 2, 2)
	player.animations[state_jump] = new_animation(21, 1, 5)
	player.animations[state_djump] = new_animation(21, 1, 5)
	player.animations[state_falling] = new_animation(21, 1, 5)

	-- collide event
	player.collide = function(self, body)
		if (body.type == type_monster) then
			self.collided = true
		end
	end

	-- take_damage function

	reset_player()
end

-- init monster
function init_monster(posx, posy, type, looking_direction)
	-- add monster
	size = 1
	if (type > 0) then
		size = 2
	end

	monster = new_unit(posx, posy, size, size)
	monster.direction = looking_direction
	monster.type = type_monster
	monster.monster_type = type
	monster.sprite = sprite_monster(type)
	monster.hp = hp_monster(type)
	monster.damage_taken = 0

	monster.animations = {}

	-- collide event
	monster.collide = function(self, body)
		if (body.type == type_bullet and not self.collided) then
			self.collided = true
			self.damage_taken = body.damage
		end
	end

	monsters[monster.id] = monster
end

function hp_monster(type)
	if (type == type_walking) then
		return 1
	elseif (type == type_flying) then
		return 2
	elseif (type == type_jumping) then
		return 3
	end
end

function sprite_monster(type)
	if (type == type_walking) then
		return 49
	elseif (type == type_flying) then
		return 40
	elseif (type == type_jumping) then
		return 12
	end
end

function reset_player()
	player.position_x = 7*8
	player.position_y = 14*8
	current_room = 1

	player.state = state_idle		-- state for player machine state
	player.direction = 1			-- player viewing direction
	player.charging_shoot_time = 0	-- used to know if shoot is charged
	player.damage_time = 0			-- invulnerability cooldown
	player.visible = true			-- used for damage animation
	player.hp = 3					-- obvious
	player.pose = 0					-- used to keep track of the current pose of animation
end

function init_scenario()
	-- clear scenario list 
	for element in all(game_elements) do del(game_elements, element) end

	-- insert new scenario element
	insert_scenario(9*8, 14*8, 1,1, "aie! : you hit", "the scenario!")
end


-- ************************************************************************ instanciation functions ************************************************************************
function new_unit(x,y,w,h)
	local unit = new_body(x,y,w,h)
	unit.state = state_idle
	unit.previous_state = state_idle
	unit.state_time = 0

	unit.type = type_unit

	unit.animations = {}
	return unit
end

function new_bullet(x,y)
	local unit = new_body(x,y,1,1)
	unit.type = type_bullet
	unit.gravity_factor = 0.0
	unit.lifespan = bullet_range
	unit.damage = 1

	particles[unit.id] = unit
	particles_counter += 1

	-- collide event
	unit.collide = function(self, body)
		if (body.type == type_monster) then
			self.collided = true
		end
	end

	unit.animations = {}
	return unit
end

function new_body(x,y,w,h)
	local body = new_thing()
	body.position_x = x
	body.position_y = y
	body.size_x = w
	body.size_y = h

	body.sprite = 34
	body.direction = 1

	body.speed_x = 0
	body.speed_y = 0
	body.gravity_factor = 1.0

	body.type = type_body

	-- collide method
	body.collided = false
	body.collide = function(self, body)
		--nothing
	end

	physics[body.id] = body
	return body
end

function new_thing()
	local thing = {}
	thing.id = instance_counter
	instance_counter += 1
	thing.type = type_thing
	return thing
end

function new_animation(start, frames, time)
	local a = {}
	a.start = start
	a.frames = frames
	a.time = time
	return a
end

function insert_scenario(x,y, w,h, text1,text2)
	local element = {}
	element.position_x = x
	element.position_y = y
	element.size_x = w
	element.size_y = h
	element.type = type_scenario

	element.text1 = text1
	element.text2 = text2

	add(game_elements, element)
end


-- ************************************************************************ updates functions ************************************************************************
function _update()
	global_time += 1

	if (player.hp <= 0) then
		game_on_popup = true
		popup_text_line1 = "game over !"
		popup_text_line2 = ""
	end

	if (game_on_popup) then
		if(btn_down(button_action)) then
			game_on_popup = false
			if(player.hp <=0 ) then
				reset_player()
				init_scenario()


				-- reload map
				reload(0x2000, 0x2000, 0x1000)
			end
		end
	else
		update_physics()
		update_particles()
		update_monsters()
		update_scenario()
		update_player()
		update_controller()
		update_room()
	end
end

function update_room()
	if (mid(player.position_x, rooms[current_room][1], rooms[current_room][1] + rooms[current_room][3]) == player.position_x) and
	   (mid(player.position_y, rooms[current_room][2], rooms[current_room][2] + rooms[current_room][4]) == player.position_y)
	   then
	   return
	else 
		for i = 1, count(rooms[current_room][5]) + 1 do
			local r = rooms[current_room][5][i]
			if (mid(player.position_x, rooms[r][1], rooms[r][1] + rooms[r][3]) == player.position_x) and
	   		   (mid(player.position_y, rooms[r][2], rooms[r][2] + rooms[r][4]) == player.position_y) then
	   		   	destroy_all_monsters()
	   			current_room = r
	   			create_all_monsters_in_room(current_room)

	   			break
	   		end
		end
	end
end

function destroy_all_monsters()
	for id,monster in pairs(monsters) do
		monsters[monster.id] = nil
		physics[monster.id] = nil
	end
end

function create_all_monsters_in_room(room)
	new_monsters = rooms[current_room][6]
	for i = 1, count(new_monsters) do
		init_monster(new_monsters[i][1],new_monsters[i][2],new_monsters[i][3],new_monsters[i][4])
	end
end

function update_physics()
	for id,body in pairs(physics) do
		body.speed_y += gravity * body.gravity_factor
		body.speed_y = min(body.speed_y, max_body_speed)
		
		--right
		if (body.speed_x > 0) then
			local actual_speed = 0
			while (not is_solid(body.position_x + 7 + actual_speed + 1 - 1, body.position_y + 2) and
				   not is_solid(body.position_x + 7 + actual_speed + 1 - 1, body.position_y + 7) and actual_speed < body.speed_x) do
				actual_speed += 0.1
			end
			
			-- test for bullet collition
			if (abs(body.speed_x - actual_speed) > 0.2 and body.type == type_bullet)then
				if (body.damage == charge_damage) then
					if (is_destructible(body.position_x + 7 + actual_speed, body.position_y + 2)) then
						destroy(body.position_x + 7 + actual_speed, body.position_y + 2)
					elseif (is_destructible(body.position_x + 7 + actual_speed, body.position_y + 7)) then
						destroy(body.position_x + 7 + actual_speed, body.position_y + 7)
					end
				end
				body.lifespan = 2
			end
			body.speed_x = actual_speed
		
		--left
		elseif (body.speed_x < 0) then
			local actual_speed = 0
			while (not is_solid(body.position_x + actual_speed - 1 + 1, body.position_y + 2) and
				   not is_solid(body.position_x + actual_speed - 1 + 1, body.position_y + 7) and actual_speed > body.speed_x) do
				actual_speed -= 0.1
			end

			-- test for bullet collision
			if (abs(body.speed_x - actual_speed) > 0.2 and body.type == type_bullet) then
				if (body.damage == charge_damage) then
					if (is_destructible(body.position_x + actual_speed, body.position_y + 2)) then
						destroy(body.position_x + actual_speed, body.position_y + 2)
					elseif (is_destructible(body.position_x + actual_speed, body.position_y + 7))then
						destroy(body.position_x + actual_speed, body.position_y + 7)
					end
				end
				body.lifespan = 2
			end
			body.speed_x = actual_speed
		end

		body.position_x += body.speed_x
		if (body.speed_x > 0) then
			body.speed_x -= friction * body.gravity_factor
			body.speed_x = max(0,body.speed_x)
		elseif (body.speed_x < 0) then
			body.speed_x += friction * body.gravity_factor
			body.speed_x = min(0, body.speed_x)
		end

		-- top
		if (body.speed_y < 0) then
			local actual_speed = 0
			while (not is_solid(body.position_x + 2, body.position_y + actual_speed - 1 + 1) and
				   not is_solid(body.position_x + 7 - 2, body.position_y + actual_speed - 1 + 1) and actual_speed > body.speed_y) do
				actual_speed -= 0.1
			end
			body.speed_y = actual_speed
		
		-- down
		elseif (body.speed_y > 0) then
			local actual_speed = 0
			while (not is_solid(body.position_x + 2, body.position_y + 7 + actual_speed + 1 ) and
				   not is_solid(body.position_x + 7 - 2, body.position_y + 7 + actual_speed + 1) and
				   not is_traversable(body.position_x + 2, body.position_y + 7 + actual_speed + 1) and
				   not is_traversable(body.position_x + 7 - 2, body.position_y + 7 + actual_speed + 1) and actual_speed < body.speed_y) do
				actual_speed += 0.1
			end
			body.speed_y = actual_speed
		end

		body.position_y += body.speed_y

		-- body interference
		--body.collide = false
		for id2,body2 in pairs(physics) do
			-- avoid some triky cases
			if (id2 == id) then break
			elseif (body2.type == type_player and body.type == type_bullet) then break
			end
		
			-- detect collision between two square
			if ( abs(body.position_x + 4*body.size_x - (body2.position_x + 4*body2.size_x)) < 4*(body.size_x + body2.size_x) ) then
				if ( abs(body.position_y + 4*body.size_y - (body2.position_y + 4*body2.size_y)) < 4*(body.size_y + body2.size_y) ) then
					body:collide(body2)
					body2:collide(body)
				end
			end
		end
	end
end

function update_scenario()
	for element in all(game_elements) do
		-- detect collision between two square
		if ( abs(element.position_x + 4*element.size_x - (player.position_x + 4*player.size_x)) < 4*(element.size_x + player.size_x) ) then
			if ( abs(element.position_y + 4*element.size_y - (player.position_y + 4*player.size_y)) < 4*(element.size_y + player.size_y) ) then
				if(element.type == type_scenario) then
					popup_text_line1 = element.text1
					popup_text_line2 = element.text2
					game_on_popup = true
					del(game_elements, element)
				end

			end
		end
	end
end

function update_particles()
	for id,part in pairs(particles) do
		part.lifespan -= 1
		if (part.lifespan <= 0 or part.collided) then
			particles[part.id] = nil
			physics[part.id] = nil
		end
	end
end

function update_monsters()
	for id,monster in pairs(monsters) do

		-- collision
		if (monster.collided) then
			monster.hp -= monster.damage_taken
			monster.damage_taken = 0
			monster.collided = false
		end

		-- if hp < 1, destroy it
		if (monster.hp < 1) then
			monsters[monster.id] = nil
			physics[monster.id] = nil
		end

	end
end

function is_grounded(body)
	for i = 2, 6 do
		local sprite_id = mget(flr((body.position_x+i)/8),flr((body.position_y+8)/8))
		if (fget(sprite_id, flag_solid)) or (fget(sprite_id, flag_traversable)) then return true end
	end
	return false
end

function is_solid(x,y)
	local sprite_id = mget(flr(x/8),flr(y/8))
	if (fget(sprite_id, flag_solid)) return true
	return false
end

function is_traversable(x,y)
	if (btn(button_down)) return false
	local sprite_id = mget(flr(x/8), flr(y/8))
	if (fget(sprite_id, flag_traversable)) and flr(y)%8 == 0 then return true end
	return false
end

function is_destructible(x,y)
	local sprite_id = mget(flr(x/8),flr(y/8))
	if (fget(sprite_id, flag_destructible)) return true
	return false
end

function destroy(x,y)
	mset(flr(x/8), flr(y/8), 0)
	if(is_destructible(x+8,y)) then destroy(x+8,y) end
	if(is_destructible(x-8,y)) then destroy(x-8,y) end
	if(is_destructible(x,y+8)) then destroy(x,y+8) end
	if(is_destructible(x,y-8)) then destroy(x,y-8) end
end

function update_player()
	-- players movement machine state
	player.state_time += 1

	-- idle state
	if(player.state == state_idle) then
		--player.speed_x = 0
		player.previous_state = state_idle
		player.djump_available = true

		if(btn(button_left) or btn(button_right)) then
			player.state = state_walk
			player.state_time = 0
		elseif(not is_grounded(player)) then
			player.state = state_falling
			player.state_time = 0
		elseif(btn_down(button_jump)) then
			player.state = state_jump
			player.state_time = 0
		end

	-- walk state
	elseif(player.state == state_walk) then
		player.previous_state = state_walk
		player.djump_available = true

		if(btn(button_left)) then
			player.speed_x = -walk_speed
			player.direction = -1
		elseif(btn(button_right)) then
			player.speed_x = walk_speed
			player.direction = 1
		end

		if(btn_down(button_jump)) then
			player.state = state_jump
			player.state_time = 0
		elseif(not is_grounded(player)) then
			player.state = state_falling
			player.state_time = 0
		elseif(not btn(button_left) and not btn(button_right)) then
			player.state = state_idle
			player.state_time = 0
		end

	-- jump state
	elseif(player.state == state_jump) then
		if(player.previous_state != state_jump) then
			player.speed_y = jump_speed
			sfx(4)
		end
		player.previous_state = state_jump

		if(btn(button_left)) then
			player.speed_x = -walk_speed
		elseif(btn(button_right)) then
			player.speed_x = walk_speed
		--else
		--	player.speed_x = 0
		end

		if(is_grounded(player)) then
			if(btn(button_left) or btn(button_right)) then
				player.state = state_walk
			else
				player.state = state_idle
			end
			player.state_time = 0
		--else
		--if(is_roofed(player)) then
		--	player.state = state_falling
		--	player.state_time = 0
		elseif(btn_down(button_jump) and player.djump_available) then
			player.state = state_djump
			player.state_time = 0
		elseif(player.speed_y > 0) then
			player.state = state_falling
			player.state_time = 0
		end

	-- double jump state
	elseif(player.state == state_djump) then
		if(player.previous_state != state_djump) then
			--if(player.speed_y > 0) then
				player.speed_y = jump_speed
			--else
			--	player.speed_y += jump_speed
			--end
		end
		player.previous_state = state_djump
		player.djump_available = false

		if(btn(button_left)) then
			player.speed_x = -walk_speed
		elseif(btn(button_right)) then
			player.speed_x = walk_speed
		--else
		--	player.speed_x = 0
		end

		--if(is_roofed(player)) then
		--	player.state = state_falling
		--	player.state_time = 0
		if(player.speed_y > 0) then
			player.state = state_falling
			player.state_time = 0
		elseif(is_grounded(player)) then
			if(btn(button_left) or btn(button_right)) then
				player.state = state_walk
			else
				player.state = state_idle
			end
			player.state_time = 0
		end

	-- falling state
	elseif(player.state == state_falling) then
		player.previous_state = state_falling

		if(btn(button_left)) then
			player.speed_x = -walk_speed
			player.direction = -1
		elseif(btn(button_right)) then
			player.speed_x = walk_speed
			player.direction = 1
		--else
		--	player.speed_x = 0
		end

		if(is_grounded(player)) then
			if(btn_down(button_jump)) then
				player.state = state_jump
			elseif(btn(button_left) or btn(button_right)) then
				player.state = state_walk
			else
				player.state = state_idle
			end
			player.state_time = 0
		elseif(btn_down(button_jump) and player.djump_available) then
			player.state = state_djump
			player.state_time = 0
		end
	end

	-- player animation
	player.pose = flr(player.state_time / player.animations[player.state].time) % player.animations[player.state].frames
	
	-- player damage animation
	if ((fget(mget(flr(player.position_x/8 +0.5),flr(player.position_y/8 +0.5)), flag_enemy) or player.collided) and player.damage_time == 0) then
		player.damage_time = damage_timer
		player.hp -= 1
	elseif (player.damage_time > 0) then
		player.damage_time -= 1
		player.visible = not player.visible
	else 
		player.visible = true
	end
	player.collided = false

	-- player action state machine
	if (btn_down(button_action)) then
		player.charging_shoot_time = 0
	elseif (btn_up(button_action)) then
		local bullet = new_bullet(player.position_x + player.direction * (8 * player.size_x - 2), player.position_y)
		bullet.speed_x = player.direction * 10
		bullet.direction = player.direction

		if(player.charging_shoot_time > charge_shoot_time) then 
			bullet.speed_x = player.direction * 5
			bullet.sprite = 225
			bullet.damage = charge_damage
		else
			bullet.speed_x = player.direction * 10
			bullet.sprite = 224
		end
		player.charging_shoot_time = 0

		if(player.state == state_idle) then
			player.pose = 1
			player.state_time = 0
		end

		sfx(3)

	elseif (btn(button_action)) then
		player.state_time = 0
		player.charging_shoot_time += 1
	end
end

-- ************************************************************************ draw functions ************************************************************************
function update_camera()
	camposx = mid(player.position_x - 64, rooms[current_room][1], rooms[current_room][1] + rooms[current_room][3] - 128)
	camposy = mid(player.position_y - 64, rooms[current_room][2], rooms[current_room][2] + rooms[current_room][4] - 128)
	camera(camposx, camposy)
	--camera(16*24, 0)
end

function _draw()
	cls()
	update_camera()
	map(0, 0, 0, 0, 128, 48)

	for id,body in pairs(physics) do
		draw_unit(body)
	end

	if (game_on_popup) then draw_popup(80,30) end


	--print(count(monsters), player.position_x, player.position_y - 16)
	--print(rooms[1][5][1], player.position_x, player.position_y - 8)
	--print(player.djump_available, player.position_x, player.position_y - 8)
	--print(player.collide, player.position_x, player.position_y - 8)
	--print(fget(mget(flr((player.position_x + (8 * player.size_x - 1) / 2) / 8), flr((player.position_y + 8) / 8))), player.position_x, player.position_y + 8)
	--print(fget(mget(flr((player.position_x + (8 * player.size_x - 1) / 2) / 8), flr((player.position_y - 1) / 8))), player.position_x, player.position_y - 8)
	--print(fget(mget(flr((player.position_x + (8 * player.size_x - 1) / 2) / 8), flr((player.position_y - 9) / 8))), player.position_x, player.position_y - 16)
	--print(is_solid_2top(player), player.position_x, player.position_y - 8)
end

function draw_unit(unit)
	if(unit.type == type_player) then
		if (unit.visible) then
			spr(unit.animations[unit.state].start + unit.pose, unit.position_x, unit.position_y, unit.size_x, unit.size_y, (unit.direction < 0))
			if (unit.charging_shoot_time > charge_shoot_time) then
				spr(253, unit.position_x + unit.direction*8*unit.size_x, unit.position_y, unit.size_x, unit.size_y, (unit.direction < 0))
			end
		end
		print(unit.hp, unit.position_x, unit.position_y - 8)
	else
		spr(unit.sprite, unit.position_x, unit.position_y, unit.size_x, unit.size_y, (unit.direction < 0))
	end
end

function draw_popup(w,h)
	rect(camposx + 63 - w/2, camposy + 63 - h/2, camposx + 65 + w/2, camposy + 65 + h/2, 12)
	rectfill(camposx + 64 - w/2, camposy + 64 - h/2, camposx + 64 + w/2, camposy + 64 + h/2, 0)
	print(popup_text_line1, camposx + 64 - 1.5 * #popup_text_line1, camposy + 60, 7)
	print(popup_text_line2, camposx + 64 - 1.5 * #popup_text_line2, camposy + 68, 7)

	rectfill(camposx + 63 + w/2, camposy + 63  + h/2, camposx + 67 + w/2, camposy + 69 + h/2, 12)
	print("c", camposx + 64 + w/2, camposy + 64 + h/2, 7)
end

-- ************************************************************************ utils functions ************************************************************************
function update_controller()
	for i = 1, 7 do
		button_previous[i] = btn(i-1)
	end
end

function btn_down(button)
	return not button_previous[button+1] and btn(button)
end

function btn_up(button)
	return button_previous[button+1] and not btn(button)
end

__gfx__
80000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088888000000007788778000000
08000080000000000000000000000000000000000000000000000000000000000000000000000000000008888800000000077887778800000072827777800000
00800800000000000000000000000000000000000000000000000000000000000000000000000000007788777880000000072827778800000078887877800000
00081000000000000000000000000000000000000000000000000000000000000000000000000000007282777888000000078887888880000008888888880000
0001800000000000000000000000000000000000000000000000000000000000000000000000000000788878888880000000888888888880000eeeee88880000
00800800000000000000000000000000000000000000000000000000000000000000000000000000000888888888888000000eeee88888880000eeeee8888000
080000800000000000000000000000000000000000000000000000000000000000000000000000000000eeee888888800000022eee888880000022eee8888800
800000080000000000000000000000000000000000000000000000000000000000000000000000000000022eee8888880000020eee888080000020eee8880880
500000000999000009990000099900000999000009990000000000000000000000000000000000000000020eee88808000000202ee8880800000202ee8800008
60000000c444c000c444c000c444c000c444c000c444c0000000000000000000000000000000000000000202ee88808000000202208880807222202208800880
70770700ccccc000ccd66dddccd66dddccccc000ccd66ddd00000000000000000000000000000000000002022088808000002202208808800222022288878800
90ee030accd66dddccddd46dccddd46dccd66dddccddd46d00000000000000000000000000000000000022022088088000002202208808800720022088008700
40880b01ccddd46dcc4cdc00cc4cdc00ccddd46dcc4cd00000000000000000000000000000000000000022022088088000007200200808070000002008800000
20220c0dcc4cdc000cccd0000cccd000cc4cdc000c00d00000000000000000000000000000000000000072002008080700000070200807000000000200080000
000000000c0cd0000c0c00000c0c00000c0cd0000c00c00000000000000000000000000000000000000000702208870000000000200800000000000020008000
000000000c0c00000c0c00000c0c0000c000c000c00c000000000000000000000000000000000000000000000200800000000000200800000000000000000000
000000000000ca008888888800000000000000000000000000000000000000000000770000770000000000000000000000000000000000000000000000000000
000000000000c0008888888805500660000000000000000000000070000000000007887887887000000000000000000002200022220000000000007000000000
0baaab0000acc0008088808805666660000000000000000000000777000777000087888787887000000000000000000028828828828000000000077700777700
0baaab00cccccacc8088808805565660000000000000000000007887787887700088788888887000000000000000000028828888228800000000788778788770
0bbbbb00000aaa008888888805656660000000000000000000087888887887000088888888878000000000000000000022888888888822200008788888788700
0b777b0000aaccc08888888805566660000000000000000000088788888888000088887788888800000000000000000082888886688828220008878888888800
0b777b000c00c00a888008880440444000000000000000000088887788888800008887787888828000000000000000008888e886ee8888220088887778888800
00000000c000c0008808808800000000000000000000000000888778788882200088878878880280000000000000000088887776777882800088877878888220
000060007000070000000000070000707000070000000000808887887888002800088878888820800000000000000000888e7e777c7e7e808088878878880028
00055600070070000700770000700700070070000000000080088878888828280080888888800280000000000000000088877c77cc7777e88008877888882828
005bbb6007070007700700000070700707070007000000000080888888800820808020802880028800000000000000008887cccecc6cc7e80080888888800820
055b555607060070706007700070600707060070000000000080208028800200808020802088002800000000000000000888cc208c2c67e80080208028800200
5555b55006e8e6006e8e6000606e8e6006e8e600000000000082288020880020000820802008002000000000000000002082882080226e880082288020880020
05bbb5006e888006e888006606e888006e8880060000000000020800200880000000208002800200000000000000000020822822802228800002080020088000
00555000088888e088888e000088888e088888e00000000000020880020080000002008020800000000000000000000002820802082022880002088002008000
00050000082228888222888808822288082228880000000000000080000000000000080020080000000000000000000022802882802022880000008000000000
0222222222222222222222200222222000000000000500000022222222222222222922222222222000ccc0000e100000000000000007000d5555556600000555
244242422424244224242442242424420005000000555000022222292999992222299992922222220cc7ac001110000000d00000000010015555566600005055
224944422444942424449422244494220000000005550050224299999999229924044449999992220c77acc011d10e1000100d00000011e15555556600050555
244999244299999242999442229994420500000005550555222429992244242929404404499222220a77aac01111111de100010001d001115555666600000055
229299999999299999992922244929220500050055555055249442209940444444042094922292920c77aac0111e111000101100100011115555566600050555
292424999942444999424292249242920500500555555555494292404444044040444404942422920c777ac01111110001101000011011110555666600005055
2242424444242424442424222424242205555550555555552224409440040040404040004992222200c77c001111111001111100001111115555566600000555
0222222222222222222222200222222055555555555555552299290000000000000000044492992200077c001111111111111110111111115555566600005005
5555111555550000000000005555555555555555555500002994424029949940049949920024499200c77c00111111110000000000000000088ee8222ee88000
5511551111155000000050050555555555555555550000002999440029244400004449290444999200ca700c1111111100e0000066660000888ee22e28e88800
5516655151115000005000555555555555555555550050002299904092404000000402294449992200ca7c001111111101100107666660002828228e28e28200
55116551552155000005055505555555555555555555500029940400994004000040049944444992000a7700111111111100d01066666600028e228888e82000
555126615121550005055555055555555555555555550000299222409490044040400949042229920c0aa7001111111111000010666666600082822882e80000
5555222152215500000055550555555555555555555550002900444444040004000040444444499200c0a7001111111101010110555566668822e222e8228800
05555255221555000555555500055055555555555555550029040900400000400044000404944992000aa0001111111101711100055556662828e822e8828200
05555255221555000005555500000555555555555555500029494040000000000000000004449492000a0000111111110111111055555666222e222e22822200
00555255121555500005005555555555555555555555555022244400000040000000000000444222000000000700000000000000000000009999999999446666
00555255521550500000555555555555555555555555555022440099400040040004400499040422000002400777000000000000000000009994499999446666
005555555d1550005000055555555555555555555555550092944440440400004000404404404929000020020027670000000000000000009999949999446666
050555050dd055000005555555555555555555555555000092990900949004404040094904949929000000000007766000000000000000009999449999944666
5500550500d100000055555555555555555555555555000092922004994004000440049940442929040000000007766000000000000000009999944999944466
000005000d2100000555555555555555555555555550000099999442994040000004049924004999402000020027266000000777777700009944444999999466
00005000dd1100000005555555555555555555500500050099244400929444000044492994440499002042040027662000077777777270009999444499999446
0000500dd11111100005055555555555555550500000000092944494299499400499492242242929040240400022620000777772222670009994444499999944
00000000224299425555555505555555505555000000000022299944000000000000000004499222555555560000000007777772666627009999424499229999
007000d0242994225555555500055555505505000000000029942224000404000404004040949922555555610000000007777772666667009999424492ffff99
700000002449944255555555500555055050005000000000929929494204020400244404449949295555561100000000272777266666620099fff2f44ffffff9
0007000d22992422555555550005050000000500000000002999449944044444204240449944992955556111007722202777726666666670ffffffffffffffff
0d000000244992425555555500050000000000000000500022922992224444492294440929922999555611110772666602777266666266207777777777777777
00000d00224994225555555000550000000000000500500029999922222229999999229422999992556111117726662607272666662626606666666666666666
00d00007244299425005050000550050000000000505555029222929922922999222929292922292561111117762666207726666626262209994666494949496
00007000222499420000000000500000000000005555555502922222222222222222222222222920611111112762262007226662662222009949444449494949
00000000000000000000000000867787777787778777877787778777877787768677877787778777877787778777877787778777877787778777877787778776
0095000c1c2c0000000c2c0000677777877787778776967e008cdd440000650000867787778777877787778777877685957e0c2c7d6500000086877787777666
86878777877787778777877787979c8c9cbd9d8c9c8c9dbd9d8cdd00dd8c9d65958c8c9d9c9d9d9c9d005744009d9d009d9d9d9c9d574457009d9c9d9d9d8c65
009600000000000000000000d42f3f3f3f3f3f3f3f66967e34002536557d660086978cdd0000000000000000dd8c6776967e00007d66000086979dbd34cd6766
95d4b4b4c400000000000000000000000000000000000000000000000000c5669600005444574457445445455444445455444400254545455544575455000067
87970000000000004454000064847484943e3f3f3f659500dd00008d5600650095000000000012121212000000000065957e009e7d6500869734000034009c65
96b5b5b5b5c45c9e9e9e000000000000000000000000000000009ed4b4d4b5659500f44545454545454545454545454545454545454545454545454556000000
00000000000000253636570065000000955c3e3f3f66960000003c8d5d7d6600960c1c2c00fdfdfdfdfdfd000c1c2c66967e0c2c7d6500969d34004454447d66
95b50424b564748474847484945c0000000000000000a0b0004d6474942eb566960000454545454545454527454735454545454545454545454556379e9e6474
7484940000005436363636006777877685141414141497003c0054554d9e650095000000fdfdfdfdfdfdfdfd00000065957e00007d67879700dd253636567d65
96b52f3f2e6777877787777685949e00000000000000a1b19e647500953e2e659500f4454527454527455600370000c6d6003747003705150037009e64747500
0000959e00003636373636009d9c8c650095cd8cbddddd009e4d8d550c1c660096000000fdfdfdfdfdfdfdfd00000066967e9e007d34bd340025360515007d66
95342e2f3f4f0000000000677685949e7c3d9e9e9e9e3d9e6475000096323e669600004537000515003700009e5c7cc7d75c5c9e000006169e5c7c6475000000
0000859400f4365600473655000000658697000000000000042437470000650095000000fdfdfdfdfdfdfdfd000c2c65957e0c2c7d3400000000370616000065
673e3f2e2f3f4f0000000000677797747484748474847484750000008574847595000045009e0616000064748474847484748474847484748474847500000000
0000869700f436550057363655000066959c000000d4b4c4ddcd00004d5c660096000000fdfdfdfdfdfdfdfd00000066965c00000000004d3d9e5c6494000066
8574943e2e2f3f4f00000000000017677787768777767787778777877787777696000045000c1c2c000067778777877777877787778777877787877600000000
0000959d3c00273644363636560000659600c4c5d4b5b5b5b4003d64747434009500000000fdfdfdfdfdfd000000006585748474847484748474849796004d65
000085748474849400000000000034009d9d179d9d179d9d9d9d179d9d0085659500004700000000000000008c9d473745559d8c8c8c000000009c6500000000
0086970000000035363636470000006695d4b5b5b5647474747474750000000096000c2c00fdfdfdfdfdfd0000000066867776008677760000000000951c1c66
0000000000000085940000000000000000003400003400000000340000000066969e5c9e0000c6d6000000000000002545560000000000000000006600000000
00958c00003c0000473627000000d46596b5b58e046500867787778776000000960000000000fdfdfdfd00000c1c2c6595dd858775dd65000000008696000065
008687778776000085940000000000000000000000000000000000000000006685748424009ec7d7000000000000f44547005754575700009e007d6500000000
00960000009e9e0000370000c5d46475968e3c3f4f6776968cddbd8c677600009500000000000000000000000000006696763d3d3d866600a686779700009e66
00959ccd00678776008594000000000000000000000000340000000000000065a686979c00041424009e000000002545572545454545550034007d6600000000
0095009e006424000000d4b464141476953f3f3f3f4f6797000000009c660000950c1c2c00000000000000000000006585848484847586777797000000006475
0096000000dd8c65000085940000000000341f1f001f1f17001f341f000000677797c50000008c9d003c7e002645454545454545450515003400006500000000
0096003400349d0000d4b5b5179d9c67973f0f3c3e3f4f347e000000006500009500000000000000000000000000006777877787778797000000004d3d5c6600
00955c3d9e3d5c66000000859400000000170d1d340d1d170d1d172d34008f3f3f7fb5b45c9e9e9e9e9e9e254545454545454556340616a63400026600000000
00959e5c5c5c5c9ed4b5b564170357008f0f9e5c9e3e3f4f9e3db65c3d66000085940000005c7c003d5c9e9e9e0000000000000000000000004d648474847500
00857484748474750000000085748474747574847584747574847484748474847484748474847484748474847484848474847484748474847484747500000000
00857484748474847484747585748474847484748474847474847484747500000085748474847484748474847484748474847484748474847484750000000000
02222222222222222222222002222220000ccc000f0000000000000000000000d2202d20020002220006d7000000000000000000008000000000000000000000
2242442222424422224244222242442200c77bc000d000000000000000000000020220d0026002d0000777000000000000000080000000000000000000000000
2242424242424242424242422242424200c77ba000d00f0000777700077700000d00d0d006a60dd000d70000000000000088080000000000ccc0ccc0ccc06660
2d42244d2d42244d2d4224422d42244200c7baa00020d00007cc2c60077270000d0020d00060dd0000770000000080000008802000000008ccc0ccc0ccc06060
22dd2dddd2dd2dddd2d42dd222dd2dd2000c770000d0d00f07722660072627000d0d000d0000700000760000000828000008800020800000ccc0ccc0ccc06060
0200200d0000200d0000200d020020d000077b00d020d0d022cc222007266220d000d00000075700007dd000000280000088080200000200ccc0ccc0ccc06660
d0000d0000020000000d000000d00e00c0077c000d2020d022666222272262920000000000007000000760000000000000000000000000080000000000000000
0000000000000000000000000000000000c77c002222202022262222222726990000000000000000000700000000000000800000080200000000000000000000
33333333333333333333333300000000000000005000000000000000000000005555555504d242400d6007009442244211020d11010010010000000000000000
3bb333333bb333b3b3b3333b00000000000000005000500000000000000000200555555592204d0000d670000222494007002e70000d00100000000000000000
3b3bbb3bb3b3bb33b3bb3b3b0000000000000000550000000000000000000d0205555555702d6760000d600002777792e00007700000000d5522888888888888
bb33bbb3bbb33bb3bbb33bbb000000d00000000050000000000000000000000005555555000d707000006d00027eee7000071d00000000005522888888888888
3bb33b7373b377333bb373330006000600000000505000000000000000000000005555550000676000006d00277e1e7000077000000000000552228888888888
3773bbb737bbbb3b7b37b3b70020002d0000005055500000000000000000000200555555000000000000d700077eee7000000000000000000055228888888888
bab3bab3babb3b3bbbb3bbab02d0604000d00d00500000003030303000000002055555550000000000dd67000077770000000000000000000000000000000000
37bba7bb73b37abb3b7ab37a226242241d1021120000000003030303000000d055555555000000000d6770000000000000000000000000000000000000000000
000000000000000001111111010101019aaaa89899aaaaa90000000000d0000011111111000000000006770000000000000aa0000007700000a77a0000000000
000000000003b3301011111100101010a98aa892988aa89a000000002d0000001111111000000000000d70000000000009a77a900a7007a00900009009000090
0003bbb303bbba730101111100010101aaa8982498a9aaaa0000000000000000111111010000000000677000000aa0000a7777a007000070a000000a00000000
bbbaaaaabbb7aaaa101011110000101098a89224a9aaaa890000000000000000111110100000000000d7000000aa7a00a777777a700000077000000700000000
0003bbb303bbba730101011100000101aa982242aaaaa9aa00000000200000001111010100000000006dd00000a7aa00a777777a700000077000000700000000
000000000003b3301010101100000010a8924404aaa8aaaa000000000d00000011101010000f000000077d00000aa0000a7777a007000070a000000a00000000
0000000000000000010101010000000188224000a8a9aaa80000000000000000110101010e0020000007d6000000000009a77a900a7007a00900009009000090
00000000000000001010101000000000924420409aaaaa9a000000000000000010101010020200f0007d600000000000000aa0000007700000a77a0000000000
01010101000000000101010101010101000000009aaaaa99555545a6010101010000000100089900000080900000000000000000030000000b30000000000000
1010101000b00a0a101010101010101010000000a98aa8895554596a101010110000001000098000000098900000000000000000000300000000000000000000
010101000bab0000110101010101010101000000aaaa9a89555545a60101011100000101009800000000890000000000003000000b000000b000000000000000
1010100000b00a0a11101010101010101010000098aaaa9a5554696a101011110000101000889800008988000000bb0000bbb0000bb000000000000000030000
0101000000000000111101010101010101010000aa9aaaaa555546a60101111100010101008aa980089aa8000000bb003bbbb000b0bbb0003000000003000000
1010000000000ba0111110101010101010101000aaaa8aaa0554696a101111110010101008aaaa908aaa898000000000030000000bb000000b30000000000000
010000000ba00bb01111110101010101010101008aaa9a8a555546a6011111110101010109a98a98aaa8999000000000000000003b0000000000000000b00000
100000003bb30000111111101010101010101010a9aaaaa95554596a1111111110101010988aa999aaaaa8890000000000000000003000000303b00030003000

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
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000001010101000000000000000000000000202020200000202020200000000020000000000000002020202000000000a0a0000000000000202020200000000000000020000000002020202020000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004040404000000000000000000000000000000000000000000000000000000000000000010000000000000000000000010000000001000000010100000000000
__map__
707070707070707070707070707070566877787778777877787778777877786768787778777877787778777877786700687778777877787778777877787778670068777877787778777877787778786768777877787778777877787778777877787778777877787778777877787778777877787778670000000000000068d767
707070707070707070707070707070565900000000db004400c800c9c8dc00565900c9db00c9dddc00c900c9dcdd666a69e7ddddddc8ddc8dddcddddc8ddc9560059ddc9d9ddc8ddc9ddddddd9dddd5659dddddbc8dcc9c8dcdbd9c8dddd4300c943d943c8db43c843c90043e7d943c84343c943dd767767000000687779e756
70cecf545500707000707045707070665849200000005263454444455500006669e70045440000000000000000d7566a59e76c6d00624544444544440000006600690000000000000000000000e9205669e7000000000075444575000000430000c8d7437544c80043e7004400004300d94300dc00ddc87667000059dcdd0066
707054000000705255704563007070566841414200626363636363636500d75659e762636500003100c5000000d7660069e77c7d00007365536365740000d756005900c3000000000000000040414177790030000000526354545455000000000075755254545544750052635500000000430000000000db76670059e7000056
707054006255006254706373707000665900000000005363637263650000d76669006372d7404141414142e74c4d7677794041420000e9c50074003100000066006900000000000000000000c8c900000000430000004f636465730043000000007354726553545472626365000000000000000000000000c9560069e7000066
75005363636500536570536300707056690000c700000050510073000000007679e77300d4e9c5c5c5e9d44d5b5bf2f3f3f3f3f3f4464749e700d7c0c20000566879000000000000000000000000d74649e743004300e97374000000dd00430000e9730043007374d40074004300000000000000006c6d0000767779004d4b56
4f5d7045557070007570007444000066584748474849006061000000d46be9000000e9d746484747484748495b5b5bf2f3f3f3f3f3566a59e7000000000000665900000000000000000000000000006669d343d243d243d2d0d143d0d1d2d0d1d243d0d143d0d1d243d2d1d043d043d3c5d400c74d7c7dd400dd5e5f4d5b5b66
004e70534400450063704570635455566a000000006a47484900004041484748474847485700000000000058474747474847484748576a5900000031000000566900004300000000000000000000d75669414141414141414141414141414141414147474741414141414141414141414141414141414141474847425b5b5b56
004e7000540054545470547054736566687877787778777859e700d77667000068777877787778777877787778777867687778777877787900c0c1c2e7000056590000710000000000005c4d4b5c4d6659dddddddcdddd000000000000dddddcc9d7766759dd00ddd9c8dcdd4d5b5b5b5b5b5b5b5b5b4657006879f75b5b5b66
004e006265007400727054005474705669dddddcdbc9dcdd4042d400006600005900dddd4400c8d9004400c9dbdd0056690000c900ddc8dd0000000000c500666900e971c7c5004d4b4d5b5b5b5b5b56694141420040420043004042004300000000c876592000000000004d5b5b5b4647414141425b56006879f75b5b5b5b56
00725d00da000070007074007370006659e700524545757500c0c2003156006a690000626345754445634575000000665900004445754555754544d7c0c2d7566841414141424d5b5b5b5b5b5b5b5b6659d400d40000000000d4d400000000000000d7565849d04649d046495b5bc06659f3f3f3f75b660059f75b5b5be84066
00524ecaeaca0070000000000000005669e7526363636363550000d740417767590052636363636363636363550000566900626363636363727265000000d76659f3f371f3f3e25b5b5b5b5b5b43e256694141414141414141414141414142000000d7660058475758475769c2e2f25669f3404141416600695b5b5be8f3f466
004ff6f9cadaca00000000000000007679e762637272636365007b00d4e9c556690062636363636363657365000000665900626363657473003100e90000005669f3f343f3f3f3e25b5b5b5b5b71f37679dddddddcc800dddddddcc8c9dddd0000e90076777877787778777900e3e26659f3f4d4e9005600595be8c3f3f3f356
4f4ff6e5f9eaea000000005c4d4b4df2430073746c6d73740040414141414141790000737272737273000000003000566900627250510000c0c1c1c2e700006659f3f3f3f3f3f3f3e25b5b5b5b71f3f4000000000000006c6d00000000000000c0c24d5b5b43f3f3f343dd000043e356694141414200660069e8f3f3f3f3f366
4f4ff6f5e5faf90001004d5b5b5b5b5bf2f400007c7d00000000000000000000000000c500c5007b00c5c500c5000066590073006061c50000e9e9e9e9c7e9565847484749f343f343e243e24647484749c5d300c6d3007c7dc50000d47bd300004d5b5b5bf2f343f3f4d443e9d4c66659c5000000d3790059f0c0c2f3f3f366
4f4ff6e5f5e447484748474847484748484748474847484748474847484748474748474847484748474847484748474869c0c1c24647484748474847484748570000687879e3f3f3f3f3f3f3767777675847484748474847474847484748474847484748474847484748474847484757474900404141666a69e700f8f3f3f356
4f4ff6f5e46877787778777877787778777877787778777877787778777877787778777877786700000000000000006a5900000056000000000000000000000068787900c900e3c0c2f3f3f3f400c95668777877787778777877787778777877787778777877787778777877787778670059e90000d776675900f8f0c3f3f366
4f4ff6e45759f3f3f3f3f3f3f4c8c9c9d9c9d9d9007500c900c900000000c900000000000000767778777877786700006900c3007677787778777877787778675900c8000000000000e3f3f3f3f400665921ddd9dcddddd9c9dddcdd447575ddd9dd4475000044750000dddddddcc856005849d40000c96669f8f00000e3f356
004f4e687879f3f3f3f3f3f3f3f400e9c5c5e900526345457544756b00e900d4d3e9e9000000c8c9c87500c9db76676a597b0000000000dddddddcc8dd00d75669000000000000000000c0c1c2e3f45658490000525500000000004563637255526363635552636345554445550000666879584900c3d7565942000000d74066
00527a5b5b5bf2f3f3f3f3f3f3f3464847484748474847484748474847484748474849006c6d62636363454400dc76675847484900003100000000000000d7665900000000000000c50000000000e366687900005365006c6d005272505100736365736365735372537374736500005659db76790000d76669d900000000dd56
527a5b5b5b5b5bf2f3f3f3464748570068777877787778777877787778777867006a69c57c7d0053636363635500c95668777841414149e9003100005cc54d56690000000000c0c1c1c200000000005659c7c5c5d3e9e97c7de974006061e9d374e952650000d47bd300d4e9e9d3c56659e7dc0000c3005659000000c3000066
495b5b5b5b5b5b5b464748570000006a69c8c900c900000000c8d9c8d9c9d7560000584847484900745363505100d77679e70000d7764141414141425b43e26659c50000000000000000000000004d6658414141414141414141414141414141414262d540414141414141414141416769e7000000e9c5666900000000000056
595b5b5b46474847570000000000000059e7000000000000e90000454400d76668787778670059c5e900746061c50000e90031004df2f3f3f3f3f3f3e2f2f3565849e90000000000000000c3004041675900dddddddcddc8ddddddc8dcc8dcdddd0073000000000000ddc9dbddc8dc565900000040414166590000c30000d466
5841425b5600000000000000000000006900000000003100430052545455d7566921005e6600584748474847484748474847484748474847484748474847485768794200000000000000000000d9c86659d3000000000000000000000000d4e9d4000000d4e9c5c7e9d40000000000666900c3000000dc5669d4000000004066
59f3f75b66000000000000000000000059000000d74042e943e962545465d7666841425e7678777877787778777877676878777877777877787778777877786759c8c90000000000c0c20000000000565849d40000000000e900d746474847484940414246484748494041414200d456590000d40000d756594300000000dd56
69f7e84041787778777877787778670069e7c0c200ddd946484900545455d75659c8005e5f000000c9dbc80000c9dd5659d9c9d9c8dbc9c8c8c9d9c9c8dbd95669e7000000000000c9d900450000d76600584900000000004300d7767878787879dddcdd7677787779dcc8dd0000465769e700430000006669c9000000000056
59e8f3f4c8d9c8c9c8c8d9c9d9d7560059000000e90000560059e77354650066690000c0c2000000000000000000006669e7000000000000000000000000d7665900000000d7c0c2e70062635500d756006a59c5d3d40000000000c971c8d9dd00000000000000000000000000c76600590000dd0000d456590000c0c2000066
69f3c0c2000000000000000000d7666a690000c0c200d7660069e7007400d756590000000000c0c1c20000e90000005659e700000000000000000c0d0000d75669e70000e90000000052636365000066687742484748490000d40000710000000000404149d44041424648484748570069e700750000436669e7000000004356
59f3f400d7c0c2e700e9000000d77677790000000000465700584900000000666900000000000000000000430000006669e700000000000000001c1d0000d7665900d7c0c1c2e700004f63635500d7565900767778676900c0c1c20071006c6d0000ddc8764179dcdd76777877787778790052725575d95659e700000000dd66
69f3f3f4000000d7c0c1c2e7000000000000c0c2004556000000590000000076790000000000000000004649004d4b7679000000000000006c6d00000000007679e70000000000d3e90053636500007679000000005659000000000071d37c7dc500000000d4e9e9e9e9d40000000000dd005345646500767900000000d4c556
59f3f3f3f40000c5c5c5c50044457b44d4d4c5d462636600000069c5c5c700000000e9000000e9e9004657694d5b5bf2f3f4e9c5c5c5c7c57c7dc5c5c56be9e9000000000000c0c1c2e7007300e9c7e9e9e9c5c6e96669000000d400764146484748474847484748474847484749c5d3e90073637400d4e9e9d4d3d4c5464866
58474847484748474847484748474847484748474847570000005847484748474748474847484748475700584748474847484748474847484748474847484748474900d400e9000000d4e90000464748474847484757590000404200ddc866000000000000000000000000000058474849e70073d74647484748474847576a56

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

