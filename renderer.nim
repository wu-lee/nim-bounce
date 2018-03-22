import sdl2
import sdl2.gfx
import random
import times

type
  Input {.pure.} = enum none, left, right, fire, click, quit

  Game = ref object
    inputs: array[Input, bool]
    renderer: RendererPtr
    ball: array[numBalls, Ball]
  SDLException = object of Exception

const
  topLeft = Vector[int16](x:0,y:0)
  botRight = Vector[int16](x:1000,y:500)
  maxInitialVel = Vector[float](x:20,y:20)
  
proc newGame(renderer: RendererPtr): Game =
  new result
  result.renderer = renderer
  for ix in low(result.ball)..high(result.ball):
    template ball(): untyped = result.ball[ix]
    ball.vel = randomVec(-maxInitialVel.x..maxInitialVel.x, -maxInitialVel.y..maxInitialVel.y)
    ball.col = randomRGB()
    ball.radius = radius
  
template sdlFailIf(cond: typed, reason: string) =
  if cond: raise SDLException.newException(
    reason & ", SDL error: " & $getError())

proc toInput(key: Scancode): Input =
  case key
  of SDL_SCANCODE_A: Input.left
  of SDL_SCANCODE_D: Input.right
  of SDL_SCANCODE_Q: Input.quit
  else: Input.none

proc handleInput(game: Game) =
  var event = defaultEvent
  while pollEvent(event):
    case event.kind
    of QuitEvent:
      game.inputs[Input.quit] = true
    of KeyDown:
      game.inputs[event.key.keysym.scancode.toInput] = true
    of KeyUp:
      game.inputs[event.key.keysym.scancode.toInput] = false
    else:
      discard

proc render(game: Game) =
  # Set the default color to use for drawing
  game.renderer.setDrawColor(r = 110, g = 132, b = 174)
  # Draw over all drawings of the last frame with the default color
  game.renderer.clear()

  for ix in low(game.ball)..high(game.ball):
    template ball(): untyped = game.ball[ix]
    moveBall(ball, topLeft.x, topLeft.y, botRight.x, botRight.y)
    game.renderer.filledCircleRGBA(int16(ball.pos.x), int16(ball.pos.y), ball.radius.int16, r = ball.col[red], g = ball.col[green], b = ball.col[blue], a = 255)

  # Show the result on screen
  game.renderer.present()

proc main =
  sdlFailIf(not sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)):
    "SDL2 initialization failed"

  # defer blocks get called at the end of the procedure, even if an
  # exception has been thrown
  defer: sdl2.quit()

  sdlFailIf(not setHint("SDL_RENDER_SCALE_QUALITY", "2")):
    "Linear texture filtering could not be enabled"

  let window = createWindow(
    title = "Our own 2D platformer",
    x = SDL_WINDOWPOS_CENTERED, y = SDL_WINDOWPOS_CENTERED,
    w = botRight.x - topLeft.x, h = botRight.y - topLeft.y,
    flags = SDL_WINDOW_SHOWN)
  sdlFailIf window.isNil: "Window could not be created"
  defer: window.destroy()

  let renderer = window.createRenderer(
    index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync)
  sdlFailIf renderer.isNil: "Renderer could not be created"
  defer: renderer.destroy()

  var game = newGame(renderer)
  
  # Game loop, draws each frame
  while not game.inputs[Input.quit]:
    game.handleInput()
    game.render()
