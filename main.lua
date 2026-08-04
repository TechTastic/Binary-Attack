pancake =  require "pancake"

local screen
local on
local off

local highscore = 0
local score = 0
local current_binary = 0
local active = false
local game_over = false
local before_spawn = true

local base_spawn_interval = 10
local base_speed = 20

local speed = base_speed
local spawn_interval = base_spawn_interval
local spawn_timer = 0

local numbers = {}
local buttons = {}

local function addBitButton(x, y, position, key)
	local button = pancake.addButton({ name = tostring(position), x = pancake.window.x + x * pancake.window.pixelSize, y = y * pancake.window.pixelSize, image = off, imageClicked = on, width = 4, height = 4, scale = pancake.window.pixelSize, key = tostring(key) })
	button.toggled = false
	button.func = function()
		toggleBit(position)
		button.toggled = not button.toggled
	end
	buttons[position] = button
	return button
end

local function randomColor()
	return { r = love.math.random(255, 127) / 255, g = love.math.random(255, 127) / 255, b = love.math.random(255, 127) / 255, a = 1 }
end

local function percentile()
	return love.math.random(100, 1) / 100
end

local function drawText(text, x, y)
	pancake.print(text, pancake.window.x + x * pancake.window.pixelSize, y * pancake.window.pixelSize, pancake.window.pixelSize)
end

local function spawnNumber()
	local number = love.math.random(math.min(255, 15 + math.pow(2, score)), 0)
	local num_str = tostring(number)
	if score >= 20 then
		num_str = string.format("0x%02X", number)
	end

	local width = pancake.getStringWidth(num_str)
	local spawn_x = pancake.window.x + love.math.random(4, 61 - width) * pancake.window.pixelSize
	local spawn_y = pancake.window.height + -10 * pancake.window.pixelSize

	local spawn = pancake.addObject({ x = spawn_x, y = spawn_y, width = width, height = 5, colliding = true, name = num_str })
	spawn.num_type = num_type
	spawn.color = randomColor()
	spawn.number = number
	numbers[#numbers + 1] = spawn
end

local function drawLegend(x, y)
	local scale = pancake.window.pixelSize / 8
	pancake.print("Keybinds:", pancake.window.x + x * pancake.window.pixelSize, pancake.window.y + y * pancake.window.pixelSize, scale)
	pancake.print("Press \"Escape\" to quit the game", pancake.window.x + x * pancake.window.pixelSize, pancake.window.y + (y + 1.1) * pancake.window.pixelSize, scale)
	pancake.print("Press \"1\" to \"8\" to set bits, left to right", pancake.window.x + x * pancake.window.pixelSize, pancake.window.y + (y + 2.2) * pancake.window.pixelSize, scale)
	pancake.print("The Red Bit Boxes are also clickable buttons!", pancake.window.x + x * pancake.window.pixelSize, pancake.window.y + (y + 3.2) * pancake.window.pixelSize, scale)
end

local function drawBit(x, y, position)
	local b = bit.band(bit.rshift(current_binary, position), 1)
	if b == 1 then
		drawText(tostring(b), x + .5, y)
	else
		drawText(tostring(b), x, y)
	end
	drawText("!", x + 1.5, y + 6)
end

function toggleBit(position)
	current_binary = bit.bxor(current_binary, bit.lshift(1, position))
end

function love.load()
	pancake.init({ window = { pixelSize = love.graphics.getHeight()/64 }, background = { r = 0, g = 0, b = 0, a = 1 } })
	
	screen = pancake.addImage("screen", "images")
	on = pancake.addImage("on", "images")
	off = pancake.addImage("off", "images")

	if love.filesystem.getInfo("highscore.sav") then
        highscore = pancake.load("highscore.sav", "table").value
    end
end

function pancake.onLoad()
	active = true

	addBitButton(5, 49, 7, 1)
	addBitButton(12, 49, 6, 2)
	addBitButton(19, 49, 5, 3)
	addBitButton(26, 49, 4, 4)

	addBitButton(34, 49, 3, 5)
	addBitButton(41, 49, 2, 6)
	addBitButton(48.01, 49, 1, 7) -- weirdly needed
	addBitButton(55, 49, 0, 8)
end

function love.draw()
	pancake.draw()

	if not active then return end

	drawLegend(64.25, 28)

	if before_spawn then
		drawText("Match Binary", 32 - pancake.getStringWidth("Match Binary") / 2, 14)
		drawText("to Numbers", 32 - pancake.getStringWidth("to Numbers") / 2, 20)
		drawText("to Score!", 32 - pancake.getStringWidth("to Score!") / 2, 26)

		drawBit(5, 39, 7)
		drawBit(12, 39, 6)
		drawBit(19, 39, 5)
		drawBit(26, 39, 4)

		drawBit(34, 39, 3)
		drawBit(41, 39, 2)
		drawBit(48, 39, 1)
		drawBit(55, 39, 0)
	end

	if not game_over then
		local binary_str = tostring(current_binary)
		if score >= 20 then
			binary_str = string.format("0x%02X", current_binary)
		end
		drawText(binary_str, 6, 56)

		drawText(tostring(score), 59 - pancake.getStringWidth(tostring(score)), 56)

		for _, number in pairs(numbers) do
			love.graphics.setColor(number.color.r, number.color.g, number.color.b, number.color.a)
			pancake.print(number.name, number.x, number.y, pancake.window.pixelSize)
			love.graphics.setColor(1, 1, 1, 1)
		end

		love.graphics.draw(screen, pancake.window.x, pancake.window.y, 0, pancake.window.pixelSize)

		for _, button in pairs(buttons) do
			local img = button.image
			if button.toggled then
				img = button.imageClicked
			end
			love.graphics.draw(img, button.x, button.y, 0, button.scale)
		end
	else
		if score > highscore then
			highscore = score
			pancake.save({value = highscore}, "highscore.sav")
		end

		local score_str = "Score: " .. tostring(score)
		local highscore_str = "Highscore: " .. tostring(highscore)
		drawText("Game Over!", 32 - pancake.getStringWidth("Game Over!") / 2, 10)
		drawText(highscore_str, 32 - pancake.getStringWidth(highscore_str) / 2, 20)
		drawText(score_str, 32 - pancake.getStringWidth(score_str) / 2, 30)
	end
end

function love.update(dt)
	if game_over then return end
	pancake.update(dt)

	if not active then return end

	spawn_timer = spawn_timer + dt
	if spawn_timer >= spawn_interval then
		spawn_timer = 0
		if before_spawn then
			before_spawn = false
		end
		spawnNumber()
	end

	for _, number in pairs(numbers) do
		number.y = number.y + (speed * dt)
		if number.number == current_binary then
			pancake.trash(pancake.objects, number.ID, "ID")
			pancake.trash(numbers, number.ID, "ID")
			score = score + 1
			spawn_interval = math.max(4, base_spawn_interval - (score * 0.2))
			speed = base_speed + (score * 0.1)
		elseif number.y >= pancake.window.y + 45 * pancake.window.pixelSize then
			game_over = true
		end
	end
end

function love.mousepressed(x,y,button)
	pancake.mousepressed(x,y,button)
	x_clicked = x
end

function love.keypressed(key)
	if key == "escape" then
        love.event.quit()
        return
    end
   	pancake.keypressed(key)
end