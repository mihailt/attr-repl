# create canvas
canvas = document.createElement 'canvas'
ctx = canvas.getContext("2d")

# setting canvas width/heigth
canvas.width = document.body.clientWidth
canvas.height = document.body.clientHeight


# adding canvas to the document
document.body.appendChild canvas

#filling width black color
ctx.fillStyle = '#000';
ctx.fillRect(0, 0, canvas.width, canvas.height)

#mouse object
mouse =
    pX: 0,
    pY: 0,
    x: 0,
    y: 0,
    down: false

#mouse events
canvas.addEventListener('mousemove', (event)->
    mouse.pX = mouse.x || event.clientX
    mouse.pY = mouse.y || event.clientY
    mouse.x = event.clientX;
    mouse.y = event.clientY;
)

canvas.addEventListener('mousedown', (event)->
    mouse.down = true
)

canvas.addEventListener('mouseup', (event)->
    mouse.down = false
)

# config object
config =
    attractorFactor: 0.08,
    repulsionRadius: 100,
    saveAsImage: ()->
        Canvas2Image.saveAsPNG(canvas)

# config gui
gui = new dat.GUI()
gui.add(config, 'attractorFactor', 0, 1)
gui.add(config, 'repulsionRadius', 10, 500)
gui.add(config, 'saveAsImage')


# app loop
lastUpdate = Date.now()
fps = 60

run = ()->
    now = Date.now()
    dt = now - lastUpdate
    if dt >= (1000 / fps)
        lastUpdate = now - dt % (1000 / fps)
        render()
    requestAnimationFrame(run)

#utils
rgba = (r, g, b, a)->
    "rgba(#{r}, #{g}, #{b}, #{a})"
randomInteger = (min, max=0) ->
    Math.floor(Math.random() * (max + 1 - min)) + min
random = (min=0, max=1)->
    Math.random() * (max-min) + min;
dist = (x1, y1, x2, y2)->
    x2-=x1
    y2-=y1
    Math.sqrt((x2 * x2) + (y2 * y2))

#app
class ParticleSystem
    constructor: ()->
        @particles = []
    update: ()->
        for p in @particles
            p.update()
    draw: ()->
        for p in @particles
            for p2 in @particles
                distance = dist(p.position.x, p.position.y, p2.position.x, p2.position.y)
                alpha = 1 - (distance / 100)
                vx = p2.position.x - p.position.x
                vy = p2.position.y - p.position.y
                nx = vx * (1 / Math.sqrt(vx * vx + vy * vy))
                ny = vy * (1 / Math.sqrt(vx * vx + vy * vy))
                ctx.beginPath()
                ctx.moveTo(p.position.x, p.position.y)
                ctx.lineTo(p2.position.x, p2.position.y)
                ctx.strokeStyle = rgba(255, 255, 255, alpha)
                ctx.stroke()
                ctx.closePath()
            p.draw()
    addParticle:( particle )->
        @particles.push( particle )
    removeParticle: ( particle )->
        @particles.splice(index, 1) for index, value of @particles when value is particle

class Particle
    constructor:(@position, @radius, @mass, @drag)->
        @position = { x:x, y:y }
        @forces = { x:0, y: 0 }
        @prevPosition = { x:0, y: 0 }
    update:()->
        temp = { x:@position.x, y:@position.y }
        vx = (@position.x - @prevPosition?.x) * @drag
        vy = (@position.y - @prevPosition?.y) * @drag

        fx = @forces.x / @mass
        fy = @forces.y / @mass

        @position.x += vx + fx
        @position.y += vy + fy

        @prevPosition = temp
        @forces = { x:0, y: 0 }
    draw:()->
        ctx.beginPath();
        ctx.arc(@position.x, @position.y, @radius * 1.2, 0, 2 * Math.PI, false)
        ctx.strokeStyle = rgba(255, 255, 255, 1)
        ctx.stroke()
        ctx.closePath()

        ctx.beginPath();
        ctx.arc(@position.x, @position.y, @radius, 0, 2 * Math.PI, false)
        ctx.fillStyle = rgba(255, 255, 255, 1)
        ctx.fill()
        ctx.closePath()


#setup
@particleSystem = new ParticleSystem
for i in [0..100]
    x = random(0, canvas.width)
    y = random(0, canvas.height)
    radius = random(2, 15)
    mass = radius * 2
    drag = 0.1
    particle = new Particle( {x:x, y:y}, radius, mass, drag )
    particleSystem.addParticle( particle )

attrPosition = { x: canvas.width / 2, y: canvas.height / 2 }
repulsion = false

#this function will be called in the loop
render = ()->
    ctx.clearRect(0,0, canvas.width, canvas.height)
    repulsion = mouse.down

    if repulsion
        for p in particleSystem.particles
            rx = (p.position.x - attrPosition.x)
            ry = (p.position.y - attrPosition.y)

            nx = rx * (1 / Math.sqrt(rx * rx + ry * ry))
            ny = ry * (1 / Math.sqrt(rx * rx + ry * ry))
            p.forces.x += nx * Math.max(0, config.repulsionRadius - Math.sqrt(rx * rx + ry * ry))
            p.forces.y += ny * Math.max(0, config.repulsionRadius - Math.sqrt(rx * rx + ry * ry))

    attrPosition = { x: mouse.x or canvas.width / 2, y: mouse.y or canvas.height / 2 }

    for p in particleSystem.particles
        ax = (attrPosition.x - p.position.x) * config.attractorFactor
        ay = (attrPosition.y - p.position.y) * config.attractorFactor
        p.forces.x += ax
        p.forces.y += ay

    particleSystem.update()
    particleSystem.draw()

do run
