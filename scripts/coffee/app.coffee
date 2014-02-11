FLAP_VELOCITY = -300
GRAVITY = 1200
GROUND_HEIGHT = 32
WIDTH = 800
HEIGHT = 600
KILL_HEIGHT = HEIGHT - GROUND_HEIGHT
START_POSITION = 100
SPACE_KEY_CODE = 32
SCROLL_RATE = 30
UP_KEY_CODE = 38
READY_KEY = Phaser.Keyboard.SPACEBAR
FLAP_KEY = Phaser.Keyboard.UP
MENU_TEXT = "< SPACE > PUSH IT BRO, PUSH IT!"
PREFLIGHT_TEXT = "GET READY TO FLAP FO YO LIVES!"
INSTRUCTION_TEXT = "PUSH 'UP ARROW' TO FLAP"


handleCollision = ->
  @_deathSound.play()
  @game.state.start "inmenu"

handleCollision = ->
  @_deathSound.play()
  @game._safeZoneCounter = 0
  @game._safeZoneIDs = []
  @game._player.kill()
  @game._score = 0
  @game._scoreText.destroy()
  @game.time.events.remove(@game._timer)
  @game._pipes.removeAll()
  @game._safeZones.removeAll()
  @game.state.start "preflight", false
  
toggleFlap = -> @_shouldFlap = true

toggleReady = -> @_ready = true

updateGround = (ground, rate) ->
  ground.tilePosition = x: ground.tilePosition.x + rate, y: ground.tilePosition.y

game = new Phaser.Game WIDTH, HEIGHT

preflight = new Phaser.State

preflight.create = ->
  player = @game.add.sprite(100, @game.world.height - 400, "dude")
  player.body.collideWorldBounds = true
  player.animations.add "flying", [5,6,7,8], 4, true
  player.animations.play "flying"
  player.anchor = new Phaser.Point .5, .5

  ground = game.add.tileSprite(0, HEIGHT - 32, WIDTH, 32, "ground")
  
  readyKey = @game.input.keyboard.addKey FLAP_KEY
  readyKey.onDown.add toggleFlap, @
 
  @game._safeZoneCounter = 0
  @game._safeZoneIDs = []
  @game._score = 0
  @_readyText = @game.add.text(100, 100, PREFLIGHT_TEXT, font: '32px arial', fill: '#000')
  @_instructionText = @game.add.text(120, 200, INSTRUCTION_TEXT, font: '24px arial', fill: '#000')
  @game._scoreText = @game.add.text(16, 16, "#{@game._score}", font: '32px arial', fill: '#000')
  @game._player = player
  @game._ground = ground
  @_readyKey = readyKey
  @_shouldFlap = false

preflight.update = ->
  @game._player.body.rotation = 0
  ground = @game._ground
  updateGround ground, SCROLL_RATE
  if @_shouldFlap
    @_readyText.destroy()
    @_instructionText.destroy()
    @game.state.start "ingame", false

ingame = new Phaser.State

ingame.create = ->
  @game._player.body.gravity.y = GRAVITY
  @game._player.body.collideWorldBounds = true
  @game._timer = @game.time.events.loop(3000, ingame.createPipe, @)
  
  @game._pipes = @game.add.group()
  @game._safeZones = @game.add.group()
  
  flapKey = @game.input.keyboard.addKey FLAP_KEY
  flapKey.onDown.add toggleFlap, @

  @_flapSound = game.add.audio "flap"
  @_deathSound = game.add.audio "death"
  @_flapKey = flapKey
  @_shouldFlap = false

ingame.update = ->
  game = @game
  player = game._player
  ground = game._ground

  if player.y > KILL_HEIGHT then handleCollision.call @

  updateGround ground, SCROLL_RATE

  player.body.rotation = if player.body.velocity.y > 0
    player.body.rotation + 5
  else
    0

  player = @game._player
  ground = @game._ground
  pipes = @game._pipes
  safeZone = @game._safeZones
  
  @game.physics.collide(player, ground, handleCollision, null, @)
  @game.physics.overlap(player, ground, handleCollision, null, @)
  
  @game.physics.overlap(player,pipes,handleCollision, null, @) 
  
  @game.physics.overlap(player,safeZone,addPoint, null, @)
  
  player.body.rotation = if player.body.velocity.y < 0 then -40 else 60
  if @_shouldFlap
    @_flapSound.play()
    player.body.velocity.y = FLAP_VELOCITY
    @_shouldFlap = false
  
  @game._scoreText.content = "#{@game._score}"

  
ingame.createPipe = ->
  player = @game._player
  #determine the safe zone of each pipe column
  safeZoneLocation = Math.floor(Math.random() * (400 - 150 + 1)) + 150
  pipes = @game._pipes
  safeZones = @game._safeZones
  
  #top and bottom of pipe Group
  pipeTop = @game.add.sprite(700, (safeZoneLocation - 100 - 525 ), "pipe_top")
  pipeBottom = @game.add.sprite(700, safeZoneLocation + 125, "pipe_bottom")
 
  safeZone = @game.add.sprite(700, safeZoneLocation, "safe_zone")
  
  newId = @game._safeZoneCounter + 1
  @game._safeZoneCounter = newId
  @game._safeZoneIDs.push(newId)
  
  safeZone.body.velocity.x = -200
  pipeTop.body.velocity.x = -200
  pipeBottom.body.velocity.x = -200
  
  pipes.add(pipeTop)
  pipes.add(pipeBottom)
  safeZones.add(safeZone)
 
addPoint = (player, zone)->
  @game._score += 1
  zone.destroy()
  
inmenu = new Phaser.State

inmenu.preload = ->
  @game.input.keyboard.addKeyCapture [SPACE_KEY_CODE, UP_KEY_CODE]
  @game.load.image('sky', '/assets/images/sky.png')
  @game.load.image('ground', '/assets/images/grass_32x32.png')
  @game.load.spritesheet('dude', '/assets/images/dude.png', 32, 48)
  @game.load.audio('flap', '/resources/sounds/Flap.ogg')
  @game.load.audio("death", '/resources/sounds/Death.ogg')
  #@game.load.audio("menu_select", "/resources/sounds/Menu_Select.ogg")
  @game.load.audio("point", "/resources/sounds/Point.ogg")

  @game.load.image('pipe_top', '/assets/images/pipe_top.png', 100, 600)
  @game.load.image('pipe_bottom', '/assets/images/pipe_bottom.png', 100, 600)
  @game.load.image('safe_zone', '/assets/images/safe_zone.png', 100, 100)

inmenu.create = ->
  @game.add.sprite(0, 0, 'sky')
  @game.add.audio("flap")
  @game.add.audio("death")

  readyKey = @game.input.keyboard.addKey READY_KEY
  readyKey.onDown.add toggleReady, @

  @_readyKey = readyKey
  @_ready = false
  @_menuText = @game.add.text(100, 100, MENU_TEXT, font: '32px arial', fill: '#000')

inmenu.update = ->
  if @_ready
    @game.state.start "preflight", false
    @_menuText.destroy()

game.state.add "ingame", ingame, false
game.state.add "preflight", preflight, false
game.state.add "inmenu", inmenu, true
