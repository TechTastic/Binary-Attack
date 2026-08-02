pancake =  require "pancake"


local score = 0
local current_binary = 0
local on
local off
local active = false
local game_over = false

local spawn_interval = 5
local spawn_timer = 0

local numbers = {}

local function addBitButton(x, y, position)
	return pancake.addButton({ name = tostring(position), x = pancake.window.x + x * pancake.window.pixelSize, y = y * pancake.window.pixelSize, image = off, imageClicked = on, width = 4, height = 4, scale = pancake.window.pixelSize, func = function() toggleBit(position) end })
end

local function drawCurrentBinary(x, y)
	pancake.print(tostring(current_binary), pancake.window.x + x * pancake.window.pixelSize, y * pancake.window.pixelSize, pancake.window.pixelSize)
end

local function spawnNumber()
	local number = love.math.random(255, 0)
	local width = pancake.getStringWidth(tostring(number))
	local spawn_x = love.math.random(pancake.window.x + (3 + width) * pancake.window.pixelSize, pancake.window.x + (60 - width) * pancake.window.pixelSize)
	local spawn_y = pancake.window.height + 3 * pancake.window.pixelSize

	local spawn = pancake.addObject({ x = spawn_x, y = spawn_y, width = width, height = 5, colliding = true, name = tostring(number) })
	numbers[#numbers + 1] = spawn
	pancake.applyPhysics(spawn)
end

function toggleBit(position)
	current_binary = bit.bxor(current_binary, bit.lshift(1, position))
end

function love.load()
	pancake.init({ window = { pixelSize = love.graphics.getHeight()/64 }, physics = { gravityY = 10 } }) --Initiating pancake and setting pixelSize, so that the pancake display will be the height of the window! pixelSize is how many pixels every pancake pixel should take
	
	pancake.addImage("screen", "images")
	on = pancake.addImage("on", "images")
	off = pancake.addImage("off", "images")
	pancake.addObject({ x = 0, y = 0, width = 64, height = 64, image = "screen", colliding = false })
	pancake.addObject({ x = pancake.window.height, y = pancake.window.height + 64 * pancake.window.pixelSize, width = 64, height = 12, name = "hitbox", colliding = false })
end

function pancake.onCollision() --This function will be called whenever a physic object collides with a colliding object!
	--Insert your amazing code here!
end

function pancake.onLoad() -- This function will be called when pancake start up is done (after the animation)
	active = true

	addBitButton(5, 56, 7)
	addBitButton(12, 56, 6)
	addBitButton(19, 56, 5)
	addBitButton(26, 56, 4)

	addBitButton(34, 56, 3)
	addBitButton(41, 56, 2)
	addBitButton(48.01, 56, 1) -- weirdly needed
	addBitButton(55, 56, 0)
end

function pancake.onOverlap(object1, object2, dt) -- This function will be called every time object "collides" with a non colliding object! Parameters: object1, object2 - objects of collision, dt - time of collision
	--Insert your amazing code here!

	if (object1.name == "hitbox" and tonumber(object2.name)) or (object2.name == "hitbox" and tonumber(object1.name)) then
		game_over = true
	end
end

function love.draw()
	pancake.draw() --Sets the canvas right! If pancake.autoDraw is set to true (which is its default state) the canvas will be automatically drawn on the window x and y

	pancake.print("Score: " .. tostring(score))
	pancake.print("Number of Numbers: " .. tostring(#numbers), 0, 10)
	pancake.print("Active: " .. tostring(active), 0, 20)
	pancake.print("Game Over: " .. tostring(game_over), 0, 30)
	pancake.print("Spawn Interval: " .. tostring(spawn_interval), 0, 40)
	pancake.print("Gravity: " .. tostring(pancake.physics.gravityY), 0, 50)

	if not active then return end

	if not game_over then
		if current_binary / 100 > 1 then
			drawCurrentBinary(25, 47)
		elseif current_binary / 10 > 1 then
			drawCurrentBinary(28, 47)
		else
			drawCurrentBinary(30, 47)
		end

		for _, number in pairs(numbers) do
			pancake.print(number.name, number.x, number.y, pancake.window.pixelSize)
		end
	else
		local score_str = "Score: " .. tostring(score)
		local width = pancake.getStringWidth(score_str)
		pancake.print("Game Over!", pancake.window.x + (32 - (pancake.getStringWidth("Game Over!") / 2)) * pancake.window.pixelSize, pancake.window.y + 20 * pancake.window.pixelSize, pancake.window.pixelSize)
		pancake.print(score_str, pancake.window.x + (32 - (width / 2)) * pancake.window.pixelSize, pancake.window.y + 30 * pancake.window.pixelSize, pancake.window.pixelSize)
	end
end

function love.update(dt)
	if game_over then return end
	pancake.update(dt) --Passing time between frames to pancake!

	if not active then return end

	spawn_timer = spawn_timer + dt
	if spawn_timer >= spawn_interval then
		spawn_timer = 0
		spawnNumber()
	end

	for _, number in pairs(numbers) do
		if number.name == tostring(current_binary) then
			pancake.trash(pancake.objects, number.ID, "ID")
			pancake.trash(numbers, number.ID, "ID")
			score = score + 1
			spawn_interval = math.max(0.4, 5 - score * 0.02)
			pancake.physics.gravityY = math.max(12 * pancake.meter, pancake.physics.gravityY + score * 0.02)
		elseif number.y >= pancake.window.y + 48 * pancake.window.pixelSize then
			game_over = true
		end
	end
end

function love.mousepressed(x,y,button)
	pancake.mousepressed(x,y,button) -- Passing your presses to pancake!
	x_clicked = x
end