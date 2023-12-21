local crashFonts = {big=love.graphics.newFont(32),small=love.graphics.newFont(14),medium=love.graphics.newFont(24)}

local utf8 = require("utf8")

local yCameraTween = 800

local shaderTimer=0

function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errorhandler(msg)
  local crashAudio = love.audio.newSource('crash.mp3','stream')
  crashAudio:setLooping(false)
  crashAudio:play()
	msg = tostring(msg)
  
  local newTimer=0
  local textTable = {'C','O','G','R','A','T','U','L','A','T','I','O','N','S'}

	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then
			love.mouse.setCursor()
		end
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	--if love.audio then love.audio.stop() end
  if bgm then bgm:stop() end

	love.graphics.reset()
	local font = love.graphics.setNewFont(14)

	love.graphics.setColor(1, 1, 1)

	local trace = debug.traceback()

	love.graphics.origin()

	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	local err = {}

	table.insert(err, sanitizedmsg)

	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end

	table.insert(err, "\n")

	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")

	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")
  
  love.window.setTitle('LEVEL SELECT')

	local function draw()
    local dt = love.timer.step()
    shaderTimer=shaderTimer+(dt)
    newTimer=newTimer+dt
    customShader:send('timer',shaderTimer)
    yCameraTween=yCameraTween-(((yCameraTween)/0.5)*dt)
		if not love.graphics.isActive() then return end
		local pos = 70
		love.graphics.setColor(0.5, 0.5, 0.5)
    customShader:send('background',backgroundImage3)
    love.graphics.setShader(customShader)
    love.graphics.rectangle('fill',0,0,love.graphics.getWidth(),love.graphics.getHeight())
    love.graphics.setShader()
    love.graphics.setFont(crashFonts.big)
    --congrats
    for i,v in pairs(textTable) do
      local x = 400+((i-8)*35)
      local y = 35-yCameraTween+(math.sin((i*20)+(newTimer*10))*10)
      love.graphics.setColor(0.5,0.5,0.5,0.5)
      love.graphics.printf(v,x+3,y+3,35,'center')
      love.graphics.setColor(1,1,1,1)
      love.graphics.printf(v,x,y,35,'center')
    end
    love.graphics.setColor(0.5,0.5,0.5,0.5) --backdrop
    love.graphics.printf('YOU HAVE FOUND THE SECRET LEVEL SELECT\nSCREEN',3,103-yCameraTween,800,'center')
    love.graphics.setFont(crashFonts.medium)
    love.graphics.printf('(The program crashed)',3,183-yCameraTween,800,'center')
    love.graphics.setColor(1,1,1,1) --main text
    love.graphics.setFont(crashFonts.big)
    love.graphics.printf('YOU HAVE FOUND THE SECRET LEVEL SELECT\nSCREEN',0,100-yCameraTween,800,'center')
    love.graphics.setFont(crashFonts.medium)
    love.graphics.printf('(The program crashed)',0,180-yCameraTween,800,'center')
    love.graphics.setFont(crashFonts.small)
		love.graphics.printf(p, pos, (pos+160)+yCameraTween, love.graphics.getWidth() - pos)
    
    love.graphics.setShader(customShader)
    love.graphics.rectangle('fill',0,love.graphics.getHeight()-60,love.graphics.getWidth(),60)
    love.graphics.setShader()
    love.graphics.line(0,love.graphics.getHeight()-60,love.graphics.getWidth(),love.graphics.getHeight()-60)
    
    love.graphics.setFont(crashFonts.medium)
    love.graphics.printf('Please send this error with a screenshot to the developer',yCameraTween,(love.graphics.getHeight()-55),800+(yCameraTween*10),'center')
    love.graphics.setFont(crashFonts.small)
    love.graphics.printf('(Press tab to open the bug report discord server)',yCameraTween*3,(love.graphics.getHeight()-25),800,'center')
    
    if not fadeTimer then
      fadeTimer = 0
    end
    
    love.graphics.setColor(0,0,0,math.sin((fadeTimer/60)*math.pi))
    love.graphics.rectangle('fill',0,0,800,600)
    love.graphics.setColor(1,1,1,1)
    
		love.graphics.present()
	end

	local fullErrorText = p
	local function copyToClipboard()
		if not love.system then return end
		love.system.setClipboardText(fullErrorText)
		p = p .. "\nCopied to clipboard!"
	end

	if love.system then
		p = p .. "\n\nPress Ctrl+C or tap to copy this error"
	end

	return function()
    fadeTimer = math.max(fadeTimer-1,0)
		love.event.pump()
    if not crashAudio.Playing then
      crashAudio:play()
    end
    
		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return 1
			elseif e == "keypressed" and a == "escape" then
				return 1
			elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
				copyToClipboard()
      elseif e == "keypressed" and a == "tab" then
        love.system.openURL('https://discord.gg/tE3phJdxH3')
			elseif e == "touchpressed" then
				local name = love.window.getTitle()
				if #name == 0 or name == "Untitled" then name = "Game" end
				local buttons = {"OK", "Cancel"}
				if love.system then
					buttons[3] = "Copy to clipboard"
				end
				local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
				if pressed == 1 then
					return 1
				elseif pressed == 3 then
					copyToClipboard()
				end
			end
		end

		draw()

		if love.timer then
      --love.timer.sleep(0.1)
		end
	end

end