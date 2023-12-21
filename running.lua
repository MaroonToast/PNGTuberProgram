--final prep
local fileName = currentItem.fileName

for i,v in pairs(pngData.body) do
  for ii,vv in pairs(v.image) do
    v.image[ii]=love.graphics.newImage(fileName..'/'..vv)
  end
end

for i,v in pairs(pngData.eyes) do
  for ii,vv in pairs(v.image) do
    v.image[ii]=love.graphics.newImage(fileName..'/'..vv)
  end
end

for i,v in pairs(pngData.mouths) do
  for ii,vv in pairs(v.image) do
    v.image[ii]=love.graphics.newImage(fileName..'/'..vv)
  end
end

if pngData.props then
  for i,v in pairs(pngData.props) do
    for ii,vv in pairs(v.image) do
      v.image[ii]=love.graphics.newImage(fileName..'/'..vv)
    end
  end
else
  pngData.props={}
end


local eyesOpen = true
local mouthOpen = false

local talking=false

local blinkTimer = 200
local talkTimer = 0
local animateTimer = 0

local bounceTimer=0
local bounceOffset = 0
local bouncing = false

local sinMultiplier = (1/20)*math.pi

local microphoneSensitivity = 0.95

local debugVisible=0
local microphones = nil

local currentMicrophone = nil
local microphoneName = ''
local currentMicrophoneIndex = 1

local microphoneVolume = 0

local focused = false

local barHoveringPosition = 0

local silenceAllowance=0

microphones=love.audio.getRecordingDevices()

if love.filesystem.getInfo('settings') then
  local data = love.filesystem.newFile('settings','r')
  local rawData = data:read()
  data:close()
  local index = 0
  
  local sensitivity = 0.95
  local micIndex = 1
  for token in string.gmatch(rawData,'[^%s]+') do
    index=index+1
    if index == 1 then
      sensitivity = tonumber(token)/100
    elseif index == 2 then
      micIndex = math.floor(tonumber(token)+0.5)
    end
  end
  microphoneSensitivity=sensitivity
  currentMicrophoneIndex=math.min(#microphones,math.max(0,micIndex))
end

function updateMicrophone()
  if currentMicrophone then
    currentMicrophone:stop()
  end
  currentMicrophone=microphones[currentMicrophoneIndex]
  microphoneName=currentMicrophone:getName()
  debugVisible=200
  currentMicrophone:start()
end

eyesOpenSprite = pngData.eyes.open
mouthOpenSprite = pngData.mouths.open
updateMicrophone()
love.window.setTitle('Maroon\'s Custom PNGTuber Software - '..pngData.name)

function love.keypressed(key)
  if key == 'rshift' then
    currentMicrophoneIndex=currentMicrophoneIndex+1
    if currentMicrophoneIndex > #microphones then
      currentMicrophoneIndex=1
    end
    updateMicrophone()
  elseif key =='lshift' then
    currentMicrophoneIndex=currentMicrophoneIndex-1
    if currentMicrophoneIndex < 1 then
      currentMicrophoneIndex=#microphones
    end
    updateMicrophone()
  end
  
  local number = tonumber(key) or tonumber(string.sub(key,-1,-1))
  if number and number > 0 and number < 10 and pngData.props[number] and pngData.props[number].toggle then
    pngData.props[number].enabled = not pngData.props[number].enabled
  end
end

function incrimentFrame()
  pngData.body.neutral.spriteIndex=pngData.body.neutral.spriteIndex+1
  if pngData.body.neutral.spriteIndex > #pngData.body.neutral.image then
    pngData.body.neutral.spriteIndex=1
  end
  for i,v in pairs(pngData.eyes) do
    v.spriteIndex=v.spriteIndex+1
    if v.spriteIndex > #v.image then
      v.spriteIndex=1
    end
  end
  for i,v in pairs(pngData.mouths) do
    v.spriteIndex=v.spriteIndex+1
    if v.spriteIndex > #v.image then
      v.spriteIndex=1
    end
  end
  for i,v in pairs(pngData.props) do
    v.spriteIndex=v.spriteIndex+1
    if v.spriteIndex > #v.image then
      v.spriteIndex=1
    end
  end
end

function love.quit()
  --the data
  local fileData = tostring(math.floor((microphoneSensitivity*100)+0.5))..' '..tostring(currentMicrophoneIndex)
  local file = love.filesystem.newFile('settings','w')
  file:write(fileData)
  file:close()
  return false
end

function love.update(dt)
  fadeTimer = math.max(fadeTimer-1,0)
  next_time = next_time + min_dt
  animateTimer = animateTimer-1
  
  if bgm then
    bgm:setVolume(bgm:getVolume()-0.01)
    if bgm:getVolume() <= 0.001 then
      bgm:release()
      bgm = nil
    end
  end
  
  silenceAllowance = math.max(0,silenceAllowance-1)
  if animateTimer <= 0 then
    animateTimer = pngData.animationSpeed
    incrimentFrame()
  end
  
  focused = love.mouse.isDown(1) or love.mouse.isDown(2)
  
  for i,v in pairs(pngData.props) do
    if not v.toggle and i <= 9 then
      v.enabled = love.keyboard.isDown('kp'..tostring(i))
    end
  end
  
  if focused then
    debugVisible=500
  end
  
  if not love.window.hasFocus() then
    debugVisible=0
  end
  
  bounceTimer = math.max(0,bounceTimer-1)
  debugVisible = math.max(0,debugVisible-1)
  
  barHoveringPosition = math.min(math.max(love.mouse.getY()-120,0),360)
  if love.mouse.isDown(1) then
    microphoneSensitivity = (barHoveringPosition/360)
  end
  
  local microphoneData = currentMicrophone:getData()
  
  if microphoneData then
    local loudestVolume = 0
    for pos = 1,microphoneData:getSampleCount()-1 do
      local volume = microphoneData:getSample(pos)
      loudestVolume = math.max(volume,loudestVolume)
    end
    microphoneVolume=math.min(loudestVolume*2,1)
  else
    microphoneVolume=0
  end
  
  talking = (microphoneVolume > 1-microphoneSensitivity) or love.keyboard.isDown('space')
  
  if talking then
    silenceAllowance = pngData.silenceAllowance
  end
  
  if talking or silenceAllowance > 0 then
    if not bouncing then
      bouncing=true
      if talkTimer < pngData.talkDelay then
        bounceTimer=20
      end
    end
    talkTimer=100
  else
    bouncing=false
    talkTimer=math.max(talkTimer-1,0)
  end
  
  mouthOpen = talkTimer > pngData.talkDelay
  
  bounceOffset = math.sin(bounceTimer*sinMultiplier)*pngData.bounceIntensity
  
  blinkTimer=blinkTimer-1
  if blinkTimer < 0 then
    blinkTimer=math.random(pngData.blinkRange[1],pngData.blinkRange[2])+pngData.blinkLength
  end
  
  eyesOpen = (blinkTimer > pngData.blinkLength)
end

function love.draw()
  love.graphics.setFont(fonts.small)
  love.graphics.setColor(1,1,1)
  love.graphics.push()
  love.graphics.translate(pngData.globalOffset[1],pngData.globalOffset[2]-bounceOffset)
  
  --background
  love.graphics.setBackgroundColor(pngData.backgroundColor.R,pngData.backgroundColor.G,pngData.backgroundColor.B)
  
  --backprops
  for i,v in pairs(pngData.props) do
    if v.enabled and v.behind then
      love.graphics.draw(v.image[currentFrame],v.offset[1],v.offset[2]+(bounceOffset*(1-v.multiplier)))
    end
  end
  
  --body
  love.graphics.draw(pngData.body.neutral.image[pngData.body.neutral.spriteIndex],pngData.body.neutral.offset[1],pngData.body.neutral.offset[2])
  
  --eyes
  if eyesOpen then
    love.graphics.draw(pngData.eyes.open.image[pngData.eyes.open.spriteIndex],eyesOpenSprite.offset[1],eyesOpenSprite.offset[2])
  else
    love.graphics.draw(pngData.eyes.closed.image[pngData.eyes.closed.spriteIndex],pngData.eyes.closed.offset[1],pngData.eyes.closed.offset[2])
  end
  
  --mouth
  if mouthOpen then
    love.graphics.draw(pngData.mouths.open.image[pngData.mouths.open.spriteIndex],mouthOpenSprite.offset[1],mouthOpenSprite.offset[2])
  else
    love.graphics.draw(pngData.mouths.closed.image[pngData.mouths.closed.spriteIndex],pngData.mouths.closed.offset[1],pngData.mouths.closed.offset[2])
  end
  
  --props
  for i,v in pairs(pngData.props) do
    if v.enabled and not v.behind then
      love.graphics.draw(v.image[v.spriteIndex],v.offset[1],v.offset[2]+(bounceOffset*(1-v.multiplier)))
    end
  end
  
  love.graphics.pop()
  
  --debug
  love.graphics.setLineWidth(2)
  if debugVisible > 0 then
    local barOffset = 360-(microphoneVolume*360)
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle('fill',0,10,800,50)
    love.graphics.setColor(1,1,1,1)
    love.graphics.print('Current Microphone: '..microphoneName,20,20)
    love.graphics.print('Left/Right Shift to select microphone',20,40)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle('fill',700,120+barOffset,20,360-barOffset)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle('line',700,120,20,360)
    love.graphics.setColor(1,0,0)
    love.graphics.rectangle('fill',690,120+(microphoneSensitivity*360),40,2)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle('fill',690,120+barHoveringPosition,40,2)
  end
  
  love.graphics.setColor(0,0,0,math.sin((fadeTimer/60)*math.pi))
  love.graphics.rectangle('fill',0,0,800,600)
  
  local cur_time = love.timer.getTime()
  if next_time <= cur_time then
    next_time = cur_time
    return
  end
  love.timer.sleep(next_time - cur_time)
end