print "starting"
require "sprite"
require "physics"

physics.start()
physics.setGravity(0, 0)
display.setStatusBar( display.HiddenStatusBar )

function distance(a, b)
  return math.sqrt((b.x - a.x)^2 + (b.y - a.y)^2)
end

function duration(a, b, velocity)
  return distance(a, b) / velocity
end

local w, h = display.contentWidth, display.contentHeight

local background = display.newRect(0, 0, w, h)
background:setFillColor(255, 255, 255)

-- A sprite sheet with a cat
local alex_sheet = sprite.newSpriteSheet( "alex.png", 32, 32 )
local alex_set = sprite.newSpriteSet(alex_sheet, 1, 6)
sprite.add( alex_set, "standing", 1, 1, 300, 0 ) 
sprite.add( alex_set, "walking", 2, 2, 300, 0 ) 
sprite.add( alex_set, "punching", 4, 3, 200, 0 ) 

local magus_sheet = sprite.newSpriteSheet("magus.png", 64, 64)
local magus_set = sprite.newSpriteSet(magus_sheet, 1, 8)
sprite.add(magus_set, "standing", 1, 1, 300, 0)
sprite.add(magus_set, "hurt", 2, 1, 500, 0)
sprite.add(magus_set, "walking", 3, 6, 600, 0)

local zombie_sheet = sprite.newSpriteSheet("zombie.png", 30, 50)
local zombie_set = sprite.newSpriteSet(zombie_sheet, 1, 4)
sprite.add(zombie_set, "walking", 1, 4, 800, 0)

local player = {
  name = "player",
  velocity = .15,
  attacking = false,
  sprite = sprite.newSprite( alex_set ),
  duration = function(self, target)
    return duration(self.sprite, target, self.velocity)
  end,
  idle = function(self)
    self.sprite:prepare("standing")
  end,
  punch = function(self)
    self.sprite:prepare("punching")
    local function finished(event)
      if event.phase == "loop" then
        print "finished punching"
        self.attacking:attacked()
        self.sprite:removeEventListener("sprite", finished)
        self.sprite:prepare("standing")
        self.attacking = nil
      end
    end
    self.sprite:addEventListener("sprite", finished)
    self.sprite:play()
  end,
  move = function(self, event)
    print "moving"
    local dest
    local padding = 20
    
    if event.x < self.sprite.x then
      self.sprite.xScale = -1
      dest = {
        x = event.x + padding,
        y = event.y
      }
    else
      self.sprite.xScale = 1
      dest = {
        x = event.x - padding,
        y = event.y
      }
    end
  
    if self.velocity > 0 then
      if self.sprite.sequence ~= "walking" then
        self.sprite:prepare("walking")
        self.sprite:play()
      end
      transition.to(self.sprite, {
        time=self:duration(event),
        x=dest.x,
        y=dest.y,
        onComplete=function(sprite)
          if self.attacking then
            self:punch(sprite)
          else
            self:idle(sprite)
          end
        end
      })
    end
  end,
  attack = function(self, event, target)
    print("attacking " .. target.name)
    self.attacking = target
  end
}

player.sprite.x = 100
player.sprite.y = 200
player.sprite.xScale = 1
player.sprite.yScale = 1
player.sprite:prepare("standing")
player.sprite:play()
physics.addBody(player.sprite, {
  density = 1.0, 
  friction = 0.3,
  bounce = 0.2,
})
player.sprite.isFixedRotation = true

local magus = {
  name = "Magus",
  sprite = sprite.newSprite(magus_set),
  attacked = function(self) 
    print(self.name .. " was attacked")
    self.sprite:prepare("hurt")
    local function finished(event)
      if event.phase == "loop" then
        print "finished being hurt"
        self.sprite:removeEventListener("sprite", finished)
        self.sprite:prepare("standing")
        self.sprite:play()
      end
    end
    self.sprite:addEventListener("sprite", finished)
    self.sprite:play()    
  end
}

magus.sprite.x = 400
magus.sprite.y = 200
magus.sprite.xScale = -.75
magus.sprite.yScale = .75
magus.sprite:prepare("standing")
magus.sprite:play()

local zombie = {
  name = "zombie",
  sprite = sprite.newSprite(zombie_set),
  velocity = .05,
  duration = function(self, target)
    return duration(self.sprite, target, self.velocity)
  end,
  pace = function(self)
    local function pace(sprite)
      local target = {
        x = 100,
        y = 200
      }
      sprite.xScale = -1
      transition.to(sprite, {
        time=self:duration(target),
        x=target.x,
        y=target.y,
        onComplete=function(sprite)
          local target = {
            x = 300,
            y = 200
          }
          sprite.xScale = 1
          transition.to(sprite, {
            time=self:duration(target),
            x=target.x,
            y=target.y,
            onComplete=pace
          })
        end
      })
    end
    pace(self.sprite)
  end
}

zombie.sprite.x = 300
zombie.sprite.y = 200
zombie.sprite.xScale = -1
zombie.sprite.yScale = 1
zombie.sprite:prepare("walking")
zombie.sprite:play()
physics.addBody(zombie.sprite, {
  density = 10.0, 
  friction = 0.3,
  bounce = 10.0,
})
zombie.sprite.isFixedRotation = true

magus.sprite:addEventListener("tap", function(event)
  player:attack(event, magus)
end)

background:addEventListener("tap", function(event) 
  player:move(event)
end)

zombie:pace()

