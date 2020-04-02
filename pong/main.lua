
-- push is a library that will allow us to draw our game at a virtual resolution,
-- instead of however large our window is; used to provide a more retro aesthetic
-- https://github.com/Ulydev/push

Class = require'class'
push = require 'push'

require 'Ball'
require 'Paddle'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200 -- equals to 200 pixels per second

--[[
    Runs when the game first starts up, only once; used to initialize the game.
]]
function love.load()
    math.randomseed(os.time())
    
    -- use nearest-neighbor filtering on upscaling and downscaling to prevent blurring of text and graphics
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setTitle('Pong')
    
    -- more retro-looking font object
    smallFont = love.graphics.newFont('font.ttf', 8)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    victoryFont = love.graphics.newFont('font.ttf', 32)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['point_scored'] = love.audio.newSource('sounds/point_scored.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    -- initialize virtual resolution, which will be rendered within our actual window no matter its dimensions
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = true
    })

    -- initialize score variables, used for rendering on the screen and keeping track of winner
    player1Score = 0
    player2Score = 0

    servingPlayer = math.random(2) == 1 and 1 or 2
    winningPlayer = 0

    -- initialize player paddles, make them global so that they can be detected by other funtions and modules
    paddle1 = Paddle(10, 30, 5, 20)
    paddle2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    -- place the ball in the middle of the screen
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)
    
    if servingPlayer == 1 then
        ball.dx = 100
    else
        ball.dx = -100
    end

    -- game state variable used to transition between different parts of the game
    -- use this to determine behavior during render and update
    gameState = 'start'

end

function love.resize(w, h)
    push:resize(w,h)
end

function love.update(dt)
    if gameState == 'play' then

        -- detect ball collision with paddles, reversing dx if true and
        -- slightly increasing it, then altering the dy based on the position of collision
        if ball:collides(paddle1) then
            -- deflect ball to the right
            ball.dx = -ball.dx * 1.03
            ball.x = paddle1.x + 5

            sounds['paddle_hit']:play()

            if ball.dx < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        if ball:collides(paddle2) then
            -- deflect ball to the left
            ball.dx = -ball.dx * 1.03
            ball.x = paddle2.x - 4

            sounds['paddle_hit']:play()

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end
        
        -- detect upper and lower screen boundary collision and reverse if collied
        if ball.y <= 0 then
            -- deflect the ball down
            ball.dy = -ball.dy
            ball.y = 0

            sounds['wall_hit']:play()
        end

        -- -4 to account for the ball's size
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            -- deflect the ball up
            ball.dy = -ball.dy
            ball.y = VIRTUAL_HEIGHT - 4

            sounds['wall_hit']:play()
        end
    end

    if ball.x <= 0 then
        player2Score = player2Score + 1
        servingPlayer = 1
        ball:reset()
        ball.dx = 100

        sounds['point_scored']:play()

        -- if we've reached a score of 10, the game is over;
        -- set the state to done so we can show the victory message
        if player2Score >= 10 then
            gameState = 'victory'
            winningPlayer = 2
        else
            gameState = 'serve'
        end
    end

    if ball.x >= VIRTUAL_WIDTH - 4 then
        player1Score = player1Score + 1
        servingPlayer = 2
        ball:reset()
        ball.dx = -100

        sounds['point_scored']:play()

        -- if we've reached a score of 10, the game is over;
        -- set the state to done so we can show the victory message
        if player1Score >= 10 then
            gameState = 'victory'
            winningPlayer = 1
        else
            gameState = 'serve'
        end
    end

    -- player 1 movement (AI)
    if gameState ~= 'play' then
        paddle1.dy = 0
    elseif ball.y > paddle1.y + paddle1.height / 2 then
        paddle1.dy = paddle1.dy + math.random(100, PADDLE_SPEED)
    elseif ball.y < paddle1.y + paddle1.height / 2 then
        paddle1.dy = paddle1.dy - math.random(100, PADDLE_SPEED)
    end

    -- player 2 movement
    if love.keyboard.isDown('up') then
        paddle2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        paddle2.dy = PADDLE_SPEED
    else
        paddle2.dy = 0
    end

    -- update the ball based on its DX and DY only if we're in play state
    if gameState == 'play' then
        ball:update(dt)
    end

    paddle1:update(dt)
    paddle2:update(dt)

end

-- keyboard handling, passes in the key we pressed so we can access
function love.keypressed(key)

    if key == 'escape' then
        love.event.quit()
    
    --if press enter during the start of the game, change to play mode
    elseif key == 'enter' or key == 'return' then    
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'victory' then
            gameState = 'start'
            player1Score = 0
            player2Score = 0
        elseif gameState == 'serve' then
            gameState = 'play'
        end
    end
end

--[[
    Called after update by LOVE, used to draw anything to the screen, updated or otherwise.
]]
function love.draw()
    
    -- begin rendering at virtual resolution
    push:apply('start')

    -- clear the screen with specific color
    love.graphics.clear(40 / 255, 45 / 255, 52 / 255, 255 / 255)

    -- draw welcome text toward the top screen
    love.graphics.setFont(smallFont)

    displayScore()

    if gameState == 'start' then
        love.graphics.setFont(smallFont)
        love.graphics.printf("Welcome to Pong!", 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to Play!", 0, 32, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf("Player " .. tostring(servingPlayer) .. " 's turn!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to Play!", 0, 32, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'victory' then
        -- draw victory statement
        love.graphics.setFont(victoryFont)
        love.graphics.printf("Player " .. tostring(winningPlayer) .. " wins!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf("Press Enter to Play!", 0, 42, VIRTUAL_WIDTH, 'center')
    end

    -- draw 2 paddles
    paddle1:render()
    paddle2:render()

    ball:render()

    displayFPS()
  
    -- end rendering at virtual resolution
    push:apply('end')
end

function displayFPS()
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.setFont(smallFont)
    -- the '..' is the string concatenation operator, means add 2 strings together
    love.graphics.print('FPS: '.. tostring(love.timer.getFPS()), 40, 20)
    love.graphics.setColor(1, 1, 1, 1)
end

function displayScore()
    -- set score font
    love.graphics.setFont(scoreFont)
    love.graphics.print(player1Score, VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
    love.graphics.print(player2Score, VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)
end   