import random
import times

type
  Color* = enum red, green, blue
  RGB* = array[Color, byte]

  Vector*[T] = object
    x*, y*: T

  Ball* = object
    pos*: Vector[float]
    vel*: Vector[float]
    col*: RGB
    radius*: float

var
  rseq = initRand(getTime().toUnix)

proc randomVec*[T](xs, ys: HSlice[T, T]): Vector[T] =
  result = Vector[T](x: rand(rseq, xs), y: rand(rseq, ys))

proc randomRGB*(): RGB =
  for col in Color:
    result[col] = byte(rand(rseq, 0..255))
  

proc moveBall*(ball: var Ball; left, top, right, bottom: int16) =
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
  ball.vel.x *= resistance
  ball.vel.y *= resistance
