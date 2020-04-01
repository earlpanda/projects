
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
    
    -- more retro-looking font object
    smallFont = love.graphics.newFont('font.ttf', 8)
    scoreFont = love.graphics.newFont('font.ttf', 32)

    -- initialize virtual resolution, which will be rendered within our actual window no matter its dimensions
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = false
    })

    -- initialize score variables, used for rendering on the screen and keeping track of winner
    player1Score = 0
    player2Score = 0

    paddle1 = Paddle(5, 20, 5, 20)
    paddle2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 5, 5)
    gameState = 'start'

end

function love.update(dt)

    paddle1:update(dt)
    paddle2:update(dt)

    -- player 1 movement
    if love.keyboard.isDown('w') then
        paddle1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        paddle1.dy = PADDLE_SPEED
    else
        paddle1.dy = 0
    end

    -- player 2 movement
    if love.keyboard.isDown('up') then
        paddle2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        paddle2.dy = PADDLE_SPEED
    else
        paddle2.dy = 0
    end

    -- track for gamestate
    if gameState == 'play' then
        ball:update(dt)
    end
end

-- keyboard handling, passes in the key we pressed so we can access
function love.keypressed(key)

    if key == 'escape' then
        love.event.quit()
    
    elseif key == 'enter' or key == 'return' then
        
        if gameState == 'start' then
            gameState = 'play'
        
        elseif gameState == 'play' then
            gameState = 'start'
            ball:reset()
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
    if gameState == 'start' then
        love.graphics.printf('Hello Start State!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        love.graphics.printf('Hello Play State!', 0, 20, VIRTUAL_WIDTH, 'center')
    end

    -- set score font
    love.graphics.setFont(scoreFont)
    love.graphics.print(player1Score, VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
    love.graphics.print(player2Score, VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)
  
    -- draw 2 paddles
    paddle1:render()
    paddle2:render()

    ball:render()
  
    -- end rendering at virtual resolution
    push:apply('end')
end