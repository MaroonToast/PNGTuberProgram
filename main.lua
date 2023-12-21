json = require "json"

fonts = {
  big = love.graphics.newFont(64),
  medium = love.graphics.newFont(24),
  small = love.graphics.newFont(16),
}

local backgroundImage = love.graphics.newImage('background1.png')
backgroundImage:setWrap('repeat','repeat')

fadeTimer = 60
local fading=false

local bWidth, bHeight = backgroundImage:getWidth(),backgroundImage:getHeight()

local hasMoved = false

local selected = 1

local hintFade = 1

customShader = love.graphics.newShader('scrolling.fs')
customShader:send('background',backgroundImage)
customShader:send('backgroundWidth',bWidth)
customShader:send('backgroundHeight',bHeight)

local shaderTimer=0

local backgroundImage2 = love.graphics.newImage('background2.png')
backgroundImage2:setWrap('repeat','repeat')
backgroundImage3 = love.graphics.newImage('background3.png')
backgroundImage3:setWrap('repeat','repeat')
local backgroundImage4 = love.graphics.newImage('background4.png')
backgroundImage4:setWrap('repeat','repeat')
local backgroundImage5 = love.graphics.newImage('background5.png')
backgroundImage5:setWrap('repeat','repeat')
local backgroundImage6 = love.graphics.newImage('background6.png')
backgroundImage6:setWrap('repeat','repeat')
local backgroundImage7 = love.graphics.newImage('background7.png')
backgroundImage7:setWrap('repeat','repeat')


bgm = love.audio.newSource('bgm.mp3','stream')
bgm:setLooping(true)
bgm:play()

local moveSound = love.audio.newSource('select.wav','static')
local selectSound = love.audio.newSource('selected.wav','static')

local validItems={}
currentItem = nil
local currentItemNumber = 1
local yCameraTween = (1*-50)+190
local yCamera = yCameraTween
local iconTween=0

function convertJSONtoCustom(fileDir)
  local fileName = fileDir..'/info.json'
  local loaded=true
  local output=nil
  
  if not love.filesystem.getInfo(fileName) then
    loaded=false
    output='File '..fileName..' not found!'
    return loaded,output
  end
  
  local file = love.filesystem.newFile(fileName,'r')
  local data = file:read()
  file:close()
  
  local decoded
  local success,err = pcall(function() return json:decode(data) end)
  if not success then
    loaded=false
    output=err
    return loaded,output
  else
    decoded=err
  end
  output = {}
  
  output.name = decoded.Name
  output.description=decoded.Description
  output.backgroundColor=decoded['Background Color']
  output.globalOffset={decoded.Position.X,decoded.Position.Y}
  output.talkDelay=decoded['Talk Delay']
  output.bounceIntensity=decoded['Bounce Intensity']
  output.blinkRange = {decoded['Blink Range'].Min,decoded['Blink Range'].Max}
  output.blinkLength = decoded['Blink Length']
  output.animationSpeed = decoded['Animation Speed']
  output.silenceAllowance = decoded['Silence Allowance']
  
  local body = {image={}}
  local eyes = {open={image={}},closed={image={}}}
  local mouths = {open={image={}},closed={image={}}}
  local props = {}
  
  for i,v in pairs(decoded.Sprites.Body['Sprite Names']) do --body
    body.image[i]=v
  end
  body.spriteIndex=1
  body.offset={decoded.Sprites.Body.Offset.X,decoded.Sprites.Body.Offset.Y}
  
  for i,v in pairs(decoded.Sprites.Eyes.Open['Sprite Names']) do --open eyes
    eyes.open.image[i]=v
  end
  eyes.open.spriteIndex=1
  eyes.open.offset={decoded.Sprites.Eyes.Open.Offset.X,decoded.Sprites.Eyes.Open.Offset.Y}
  
  for i,v in pairs(decoded.Sprites.Eyes.Closed['Sprite Names']) do --closed eyes
    eyes.closed.image[i]=v
  end
  eyes.closed.spriteIndex=1
  eyes.closed.offset={decoded.Sprites.Eyes.Closed.Offset.X,decoded.Sprites.Eyes.Closed.Offset.Y}
  
  for i,v in pairs(decoded.Sprites.Mouth.Open['Sprite Names']) do --open mouth
    mouths.open.image[i]=v
  end
  mouths.open.spriteIndex=1
  mouths.open.offset={decoded.Sprites.Mouth.Open.Offset.X,decoded.Sprites.Mouth.Open.Offset.Y}
  
  for i,v in pairs(decoded.Sprites.Mouth.Closed['Sprite Names']) do --closed mouth
    mouths.closed.image[i]=v
  end
  mouths.closed.spriteIndex=1
  mouths.closed.offset={decoded.Sprites.Mouth.Closed.Offset.X,decoded.Sprites.Mouth.Closed.Offset.Y}
  
  if decoded.Props then
    for i,v in pairs(decoded.Props) do
      local newTable = {
        spriteIndex=1,
        image={},
        offset={v.Offset.X,v.Offset.Y},
        multiplier=v.Paralax,
        enabled=v['Enabled by Default'],
        behind=v.behind,
        toggle=v.Toggleable,
      }
      for ii,vv in pairs(v['Sprite Names']) do
        newTable.image[ii]=vv
      end
      props[i] = newTable
    end
  end
  
  output.body = {neutral=body}
  output.eyes = eyes
  output.mouths = mouths
  output.props = props
  
  for i,v in pairs(output.body) do
    for ii,vv in pairs(v.image) do
      if not love.filesystem.getInfo(fileDir..'/'..vv) then
        loaded=false
        output='File "'..vv..'" not found!'
        return loaded,output
      end
    end
  end

  for i,v in pairs(output.eyes) do
    for ii,vv in pairs(v.image) do
      if not love.filesystem.getInfo(fileDir..'/'..vv) then
        loaded=false
        output='File "'..vv..'" not found!'
        return loaded,output
      end
    end
  end

  for i,v in pairs(output.mouths) do
    for ii,vv in pairs(v.image) do
      if not love.filesystem.getInfo(fileDir..'/'..vv) then
        loaded=false
        output='File "'..vv..'" not found!'
        return loaded,output
      end
    end
  end

  for i,v in pairs(output.props) do
    for ii,vv in pairs(v.image) do
      if not love.filesystem.getInfo(fileDir..'/'..vv) then
        loaded=false
        output='File "'..vv..'" not found!'
        return loaded,output
      end
    end
  end
  
  return loaded,output
end

function notepad(text)
  local tempFile = love.filesystem.newFile('crash.txt','w')
  tempFile:write(text)
  tempFile:close()
  love.system.openURL(love.filesystem.getSaveDirectory()..'/crash.txt')
end

function love.keypressed(key)
  local moved=false
  if key == 'up' then
    currentItemNumber = currentItemNumber - 1
    if currentItemNumber <= 0 then
      currentItemNumber = #validItems
    end
    moved=true
  elseif key == 'down' then
    currentItemNumber = currentItemNumber + 1
    if currentItemNumber > #validItems then
      currentItemNumber=1
    end
    moved=true
  elseif key == 'left' then
    currentItemNumber = currentItemNumber - 5
    if currentItemNumber <= 0 then
      currentItemNumber = 1
    end
    moved=true
  elseif key == 'right' then
    currentItemNumber = currentItemNumber + 5
    if currentItemNumber > #validItems then
      currentItemNumber=#validItems
    end
    moved=true
  elseif key == 'return' then
    if currentItem.loaded then
      function love.keypressed() end
      selectSound:stop()
      selectSound:play()
      fading=true
    else
      notepad(currentItem.crash)
    end
  end
  if moved then
    currentItem=validItems[currentItemNumber]
    yCamera = (currentItemNumber*-50)+190
    iconTween=0
    moveSound:stop()
    moveSound:play()
    hasMoved=true
  end
  if key == 'tab' then
    selectSound:stop()
    selectSound:play()
    love.system.openURL(love.filesystem.getSaveDirectory()..'/tubers')
  end
end

function love.load(arg)
  min_dt = 1/60
  next_time = love.timer.getTime()
  love.window.setTitle('Maroon\'s Custom PNGTuber Software')
  local items = love.filesystem.getDirectoryItems('tubers/')
  
  if arg[1] == '-console' then
    love._openConsole()
  end
  
  for i,v in pairs(items) do
    local workingDir = 'tubers/'..v..'/'
    local valid=true
    local info = love.filesystem.getInfo(workingDir)
    local luaData = nil
    local crashReason = ''
    local loaded=false
    if info.type ~= 'directory' then
      valid=false
    else
      if not love.filesystem.getInfo(workingDir..'info.json') then
        valid=false
      else
        --loaded,crashReason = pcall(function() luaData=require(workingDir..'/info')  end)
        loaded,crashReason = convertJSONtoCustom(workingDir)
        if loaded then
          luaData=crashReason
        end
      end
    end
    
    if valid then
      local icon = nil
      local width,height=0,0
      if love.filesystem.getInfo(workingDir..'/icon.png') then
        icon = love.graphics.newImage(workingDir..'/icon.png')
        width,height = icon:getWidth(),icon:getHeight()
      end
      local description = nil
      if luaData then
        description = luaData.description
      end
      table.insert(validItems,{name=v,icon=icon,iconWidth=width,iconHeight=height,fileName=workingDir,data=luaData,loaded=loaded,crash=crashReason,description=description})
    else
      
    end
  end
  currentItem=validItems[1]
end

function love.update(dt)
  if fading then
    fadeTimer=fadeTimer-1
  end
  if fadeTimer<=30 then
    pngData = currentItem.data
    require('running')
  end
  yCameraTween=yCameraTween-((yCameraTween-yCamera)/10)
  iconTween=iconTween-((iconTween-200)/10)
  if hasMoved then
    hintFade = math.max(0,hintFade-0.01)
  end
  
  next_time = next_time + min_dt
  shaderTimer=shaderTimer+(dt)
end

function love.draw()
  customShader:send('timer',shaderTimer)
  love.graphics.setShader(customShader)
  customShader:send('background',backgroundImage)
  customShader:send('xSpeed',0.2)
  customShader:send('ySpeed',0.1)
  love.graphics.rectangle('fill',0,0,800,600)
  
  love.graphics.push()
  love.graphics.translate(0,yCameraTween)
  
  love.graphics.setFont(fonts.medium)
  love.graphics.setLineWidth(2)
  
  for i,v in pairs(validItems) do
    love.graphics.setShader(customShader)
    if v.loaded then
      if i == currentItemNumber then
        customShader:send('background',backgroundImage2)
      else
        customShader:send('background',backgroundImage3)
      end
    else
      if i == currentItemNumber then
        customShader:send('background',backgroundImage4)
      else
        customShader:send('background',backgroundImage5)
      end
    end
    love.graphics.rectangle('fill',50,i*50,700,34,10)
    love.graphics.setShader()
    
    
    if not v.loaded then
      love.graphics.print('CRASHED - '..v.fileName,60,(i*50)+3)
      if currentItemNumber==i then
        
      end
    else
      local name = v.data.name or v.name
      love.graphics.print(name,60,(i*50)+3)
      if currentItemNumber==i then
        
      end
    end
    love.graphics.rectangle('line',50,i*50,700,34,10)
  end
  love.graphics.pop()
  love.graphics.setColor(1,1,1,hintFade)
  love.graphics.print('Use UP/DOWN to Move',10,10)
  love.graphics.print('Use LEFT/RIGHT to Move x5',10,45)
  love.graphics.print('Use ENTER to Select',10,80)
  love.graphics.print('Press TAB to Open Tuber Folder',10,115)
  love.graphics.setColor(1,1,1,1)
  
  if currentItem.icon and currentItem.loaded then
    local width = currentItem.iconWidth
    local height = currentItem.iconHeight
    love.graphics.setShader(customShader)
    customShader:send('background',backgroundImage7)
    local color = currentItem.data.backgroundColor or {0,1,0}
    
    love.graphics.setColor(color.R,color.G,color.B)
    love.graphics.rectangle('fill',550,600-iconTween,200,250,20)
    love.graphics.setColor(1,1,1)
    love.graphics.setShader()
    love.graphics.rectangle('line',550,600-iconTween,200,250,20)
    love.graphics.draw(currentItem.icon,550,600-iconTween,0,200/width,200/height)
  elseif currentItem.loaded then
    customShader:send('background',backgroundImage6)
    love.graphics.setShader(customShader)
    love.graphics.rectangle('fill',550,600-iconTween,200,250,20)
    love.graphics.setShader()
    love.graphics.rectangle('line',550,600-iconTween,200,250,20)
    love.graphics.printf('No Icon!',550,650-iconTween,200,'center')
  else
    customShader:send('background',backgroundImage4)
    love.graphics.setShader(customShader)
    love.graphics.rectangle('fill',550,600-iconTween,200,250,20)
    love.graphics.setShader()
    love.graphics.rectangle('line',550,600-iconTween,200,250,20)
    if currentItem.icon then
      local width = currentItem.iconWidth
      local height = currentItem.iconHeight
      love.graphics.setColor(0.25,0,0)
      love.graphics.draw(currentItem.icon,550,600-iconTween,0,200/width,200/height)
      love.graphics.setColor(1,1,1)
    end
    love.graphics.printf('CRASH!\nSelect for details!',550,650-iconTween,200,'center')
  end
  
  local desc = currentItem.description or 'No Description!'
  love.graphics.setShader(customShader)
  if currentItem.loaded then
    customShader:send('background',backgroundImage3)
  else
    customShader:send('background',backgroundImage5)
    desc = currentItem.crash
  end
  love.graphics.rectangle('fill',50,600-iconTween,450,250,20)
  love.graphics.setShader()
  love.graphics.rectangle('line',50,600-iconTween,450,250,20)
  love.graphics.printf(desc,60,610-iconTween,430,'left')
  
  love.graphics.setColor(0,0,0,math.sin((fadeTimer/60)*math.pi))
  love.graphics.rectangle('fill',0,0,800,600)
  love.graphics.setColor(1,1,1,1)
  
  local cur_time = love.timer.getTime()
  if next_time <= cur_time then
    next_time = cur_time
    return
  end
  love.timer.sleep(next_time - cur_time)
end

love.filesystem.createDirectory(love.filesystem.getSaveDirectory())

local urlToOpen = love.filesystem.getSaveDirectory()

if not love.filesystem.getInfo('tubers/') then
  love.filesystem.createDirectory('tubers/')
end

if not love.filesystem.getInfo('tubers/example/') then
  love.filesystem.createDirectory('tubers/example/')
  local fileList = love.filesystem.getDirectoryItems('internalExample/')
  
  for i,v in pairs(fileList) do
    local oldFile = love.filesystem.newFile('internalExample/'..v,'r')
    local fileContents = oldFile:read()
    oldFile:close()
    local newFile = love.filesystem.newFile('tubers/example/'..v,'w')
    newFile:write(fileContents)
    newFile:close()
  end
end

if not love.filesystem.getInfo('tubers/PLACE YOUR PNGTUBERS IN THIS FOLDER') then
  local file = love.filesystem.newFile('tubers/PLACE YOUR PNGTUBERS IN THIS FOLDER','w')
  file:close()
end

--love.system.openURL(urlToOpen)

require('errorHandler')