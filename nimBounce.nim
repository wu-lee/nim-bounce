import sdl2
import sdl2.gfx
import random
import times

type SDLException = object of Exception

const
  gravity = 1
  numBalls = 30
  
type
  Input {.pure.} = enum none, left, right, fire, click, quit

  Vector*[T] = object
    x*, y*: T

  Ball = object
    pos*: Vector[float]
    vel*: Vector[float]

  Game = ref object
    inputs: array[Input, bool]
    renderer: RendererPtr
    ball: array[numBalls, Ball]

var
  rseq = initRand(getTime().toUnix)
    
const
  topLeft = Vector[int16](x:0,y:0)
  botRight = Vector[int16](x:1000,y:500)
  maxInitialVel = Vector[float](x:20,y:20)

proc randomVec[T](xs, ys: HSlice[T, T]): Vector[T] =
  result = Vector[T](x: rand(rseq, xs), y: rand(rseq, ys))
  
proc newGame(renderer: RendererPtr): Game =
  new result
  result.renderer = renderer
  for ix in low(result.ball)..high(result.ball):
    result.ball[ix].vel = randomVec(-maxInitialVel.x..maxInitialVel.x, -maxInitialVel.y..maxInitialVel.y)
  
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

proc moveBall(ball: var Ball; left, top, right, bottom: int16) =
  ball.pos.x += ball.vel.x
  ball.pos.y += ball.vel.y
  if ball.pos.x < float(left):
    ball.pos.x = float(left)
    ball.vel.x = -ball.vel.x
  elif ball.pos.x > float(right):
    ball.pos.x = float(right)
    ball.vel.x = -ball.vel.x
  if ball.pos.y < float(top):
    ball.pos.y = float(top)
    ball.vel.y = -ball.vel.y
  elif ball.pos.y > float(bottom):
    ball.pos.y = float(bottom)
    ball.vel.y = -ball.vel.y
  ball.vel.y += gravity
    
      
proc render(game: Game) =
  # Set the default color to use for drawing
  game.renderer.setDrawColor(r = 110, g = 132, b = 174)
  # Draw over all drawings of the last frame with the default color
  game.renderer.clear()

  for ix in low(game.ball)..high(game.ball):
    moveBall(game.ball[ix], topLeft.x, topLeft.y, botRight.x, botRight.y)
    game.renderer.aaCircleRGBA(int16(game.ball[ix].pos.x), int16(game.ball[ix].pos.y), 10, r = 1, g = 2, b = 3, a= 255)

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

main()
