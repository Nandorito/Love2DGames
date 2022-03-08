--include libraries here
local push = require 'push'
Class = require 'class'

--include our classes so we can instantiate them and make our code a little cleaner
require 'Paddle'
require 'Ball'

--set some global variables
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243
VIRTUAL_RATIO = WINDOW_HEIGHT/VIRTUAL_HEIGHT

PADDLE_SPEED = 200

RECT_WIDTH = 5
RECT_HEIGHT = 20
BALL_DIMENSIONS = 4

WINNING_SCORE = 5

SPEED_MULTIPLIER = 1.05

--this load function initializes variables, sets fonts, sets random seed, sets the gameState,
--gets sounds, and instantiates an object* (not really an object, but acts as such)
function love.load()

    love.graphics.setDefaultFilter('nearest', 'nearest')

    smallFont = love.graphics.newFont('NEONLEDLight.otf', 24)
    fpsFont = love.graphics.newFont('impact.ttf', 12)
    scoreFont = love.graphics.newFont('NEONLEDLight.otf', 40)

    love.graphics.setFont(smallFont)

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    love.window.setTitle('Pong')

    math.randomseed(os.time())

    sounds = {
        ['paddle_hit'] = love.audio.newSource('Sounds/Paddle_Hit.wav', 'static'),
        ['score'] = love.audio.newSource('Sounds/Score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('Sounds/Wall.wav', 'static')
    }

    player1Score = 0
    player2Score = 0

    mouseY = 0

    player1 = Paddle(10, 30, RECT_WIDTH, RECT_HEIGHT)
    player2 = Paddle(VIRTUAL_WIDTH - 10,VIRTUAL_HEIGHT - 30, RECT_WIDTH, RECT_HEIGHT)

    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, BALL_DIMENSIONS, BALL_DIMENSIONS)

    gameState = 'start'

end

--put the y coordinates of the mouses movement within the window into a variable
--dont need the other mouse variables
function love.mousemoved(x,y,dx,dy,istouch)
    mouseY = y
end

--allows us to reshape the window
--we have to make sure virtual ration gets updated
function love.resize(w,h)
    push:resize(w,h)
    VIRTUAL_RATIO = h/VIRTUAL_HEIGHT
end

function love.update(dt)
    if gameState == 'play' then

        --here we decided what to do with the ball has collided with anything that can be collided with
        --we are checking to see if each edge of any collidable object
        --is matching the edge of the ball
        --after which we changed the balls direction, increase its speed, and randomly
        --change the direction of its Y direction
        if ball:collides(player1) then
            ball.dx = -ball.dx * SPEED_MULTIPLIER
            ball.x = player1.x + player1.width
            sounds['paddle_hit']:play()

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * SPEED_MULTIPLIER
            ball.x = player2.x - ball.width
            sounds['paddle_hit']:play()

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end



        --here we are checking to make sure that the ball stays within the bounds
        --of the top of the window and the bottom of the window
        --this does not check the left and right sides of the window. that is a score condition
        --that we'll cover further into the code
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        if ball.y >= (VIRTUAL_HEIGHT - ball.height) then
            ball.y = VIRTUAL_HEIGHT - ball.height
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end


        --here we call the update function so that we can simulate the ball moving across the screen
        --this function is within the ball class
        --right now it has a perfect AI setting (within 60 frames at least)
        --will change that soon
        ball:update(dt)
        player2.y = ball.y - (player2.height/2)
        player2:update(dt)

        --this is where we cover scoring
        --once someone scores, the other player gets to serve
        --meaning the ball will head towards the person who recently score <- this will get implemented
        --further into the code
        --this also covers the win condition which is set to 5 and it changes the gameState
        if ball.x >= VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()
            if player1Score == WINNING_SCORE then
                winningPlayer = 1
                gameState = 'done'
            else
                ball:reset()    
                gameState = 'serve'
            end
        elseif ball.x <= 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()
            if player2Score == WINNING_SCORE then
                winningPlayer = 2
                gameState = 'done'
            else
                ball:reset()    
                gameState = 'serve'
            end
        end
    end
    
end

--pressing escape will end the game
function love.keypressed(key)

    if key == 'escape' then
        love.event.quit()
    end
end

--use mouse click to perform various task
--ranging from starting the game, taking turns, and ending the game
function love.mousepressed(x, y, button, istouch)
    if button == 1 then
        if gameState == 'start' then
            gameState = 'play'
        elseif gameState == 'serve' then
            ball:reset()
            if servingPlayer == 1 then
                ball.dx = 200
            elseif servingPlayer == 2 then
                ball.dx = -200
            end
            gameState = 'play'
        elseif gameState == 'done' then
            player1Score = 0
            player2Score = 0
            gameState = 'start'
            ball:reset()
        else
            gameState = 'start'
            ball:reset()
        end
    end
end

function love.draw()
    push:apply('start')

    --displays some text depending on the game state
    love.graphics.setFont(smallFont)
    if gameState == 'play' then
        love.graphics.printf('Play', 0, 10, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. ' is serving', 0, 10, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'start' then
        love.graphics.printf('Start', 0, 10, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'done' then
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Click the mouse button to start again', 0, 45, VIRTUAL_WIDTH, 'center')
    end

    --this is where we determine the height of player 1's paddle
    --based on the location of the mouse
    --VIRTUAL_RATIO is the window height / virtual height. without this the paddle does not
    --move relative to the exact mouse location. it scales in speed as the mouseY position increases
    --we subtract 10 because that is half of the paddle
    --resulting in the center of the paddle being equivalent to the mouseY position
    if mouseY < (VIRTUAL_HEIGHT/2) then
        player1.y = math.max(0, (mouseY/VIRTUAL_RATIO - 10))
    end

    if mouseY >= (VIRTUAL_HEIGHT/2) then
        player1.y = math.min(VIRTUAL_HEIGHT - RECT_HEIGHT, (mouseY/VIRTUAL_RATIO - 10))
    end

    --here we display the score large and center for the player to see
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH/2 - 50, VIRTUAL_HEIGHT/2 - 16)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH/2 + 30, VIRTUAL_HEIGHT/2 - 16)

    --player bar graphics
    player1:render()
    player2:render()
    --ball graphics
    ball:render()

    displayFPS()

    push:apply('end')
end

function displayFPS()
    love.graphics.setFont(fpsFont)
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 20, 5)
end