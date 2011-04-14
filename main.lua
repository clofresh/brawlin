print "starting"
require "sprite"
require "physics"

physics.start()
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

local ground = display.newRect(0, h - 100, w, 100)
ground:setFillColor(0, 0, 0)
physics.addBody(ground, "static", {
  density=1.6,
  friction=0.5,
  bounce=0.2
})

local l_wall = display.newRect(0, 0, 50, h)
l_wall:setFillColor(0, 0, 0)
physics.addBody(l_wall, "static", {
  density=1.6,
  friction=0.5,
  bounce=0.2
})

local r_wall = display.newRect(w - 50, 0, 50, h)
r_wall:setFillColor(0, 0, 0)
physics.addBody(r_wall, "static", {
  density=1.6,
  friction=0.5,
  bounce=0.2
})



-- A sprite sheet with a cat
local alex_sheet = sprite.newSpriteSheet( "alex.png", 32, 32 )
local alex_set = sprite.newSpriteSet(alex_sheet, 1, 6)
sprite.add( alex_set, "standing", 1, 1, 300, 0 ) 
sprite.add( alex_set, "walking", 2, 2, 300, 0 ) 
sprite.add( alex_set, "punching", 4, 3, 200, 0 ) 

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
    local diff = {
      x = event.x - self.sprite.x,
      y = event.y - self.sprite.y
    } 
    if diff.x > 0 then
      self.sprite.xScale = 1
    else
      self.sprite.xScale = -1
    end
    self.sprite:applyForce(diff.x * .25, 0, self.sprite.x, self.sprite.y)
    self.sprite:applyLinearImpulse(0, diff.y * .01, self.sprite.x, self.sprite.y)
  end,
  attack = function(self, event, target)
    print("attacking " .. target.name)
    self.attacking = target
  end
}

player.sprite.x = 75
player.sprite.y = h - 150
player.sprite.xScale = 1
player.sprite.yScale = 1
player.sprite:prepare("standing")
player.sprite:play()
physics.addBody(player.sprite, {
  density = 1.0, 
  friction = 0.3,
  bounce = .5,
})
player.sprite.isFixedRotation = true

local zombie = {
  name = "zombie",
  sprite = sprite.newSprite(zombie_set),
  pace = function(self)
    self.sprite:setLinearVelocity(-25, 0)
  end
}

zombie.sprite.x = w - 75
zombie.sprite.y = h - 150
zombie.sprite.xScale = -1
zombie.sprite.yScale = 1
zombie.sprite:prepare("walking")
zombie.sprite:play()
physics.addBody(zombie.sprite, {
  density = 1.0, 
  friction = 0,
  bounce = 0.2,
})
zombie.sprite.isFixedRotation = true

background:addEventListener("touch", function(event) 
  player:move(event)
end)

zombie:pace()

