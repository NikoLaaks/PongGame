-- Todo --
-- goalPause needs to be handled somehow
-- maybe gameloop with loads and updates in function
-- then flag for goalPause and if its true -> run the gameloop function 

PLAYER_SPEED = 200
BALL_SPEED = 100
ENEMY_MAXSPEED = 250
PLAYER_POINTS = 0
ENEMY_POINTS = 0

-- Menu
local gameState = "menu"
local button = {}
button.x = love.graphics.getWidth() / 2 - 75  -- Center button horizontally
button.y = love.graphics.getHeight() / 2 - 25  -- Center button vertically
button.width = 150
button.height = 50

-- gamestate == "menu"
function drawMainMenu()
    love.graphics.setColor(1, 1, 1)  -- White color for text and button
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)  -- Draw button
    love.graphics.setFont(love.graphics.newFont(15))
    love.graphics.setColor(0, 0, 0)  -- Black text color
    love.graphics.printf("Start Game", button.x, button.y + 15, button.width, "center")  -- Center the text
end

function love.mousepressed(x, y, mouseButton, istouch, presses)
    if gameState == "menu" then
        -- Check if the click is within the button's bounds
        if x >= button.x and x <= button.x + button.width and y >= button.y and y <= button.y + button.height then
            -- Change game state to "game"
            gameState = "game"
        end
    end
end

-- gamestate == "game"
function drawGame()
    love.graphics.draw(background,0,0)

    -- Draw Player
    love.graphics.rectangle("fill", player.x - player.width / 2, player.y - player.height / 2, player.width, player.height)

    -- Draw Enemy
    love.graphics.rectangle("fill", enemy.x - enemy.width / 2, enemy.y - enemy.height / 2, enemy.width, enemy.height)

    -- Draw Ball
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)

    -- Display Ball Speed
    love.graphics.setFont(love.graphics.newFont(15))
    love.graphics.setColor(1, 1, 1)  -- Set text color to white
    love.graphics.print("Ball Speed: " .. string.format("%.2f", ball.speed), 10, 10)  -- Display speed at top-left corner
    love.graphics.print("Player: " .. (PLAYER_POINTS), 10, 30)
    love.graphics.print("Enemy: " .. (ENEMY_POINTS), 10, 50)
end

function loadPlayer()
    player = {}
    player.x = love.graphics.getWidth() / 2
    player.y = love.graphics.getHeight() - 40
    player.speed = PLAYER_SPEED
    player.width = 80
    player.height = 20

end

function loadEnemy()
    enemy = {}
    enemy.x = love.graphics.getWidth() / 2
    enemy.y = 40
    enemy.width = 80
    enemy.height = 20
end

function loadBall()
    ball = {}
    ball.x = love.graphics.getWidth() / 2
    ball.y = love.graphics.getHeight() / 2
    ball.speed = BALL_SPEED
    ball.radius = 20

    -- Set the minimum and maximum angles for vertical motion
    local min_angle = math.pi / 6    -- 30 degrees (not too shallow)
    local max_angle = 5 * math.pi / 6  -- 150 degrees (not too steep)

    -- Generate a random angle within the specified range
    math.randomseed(os.time())
    angle = math.random() * (max_angle - min_angle) + min_angle

    -- Set ball velocity based on the new angle
    ball.vx = math.cos(angle) * ball.speed
    ball.vy = math.sin(angle) * ball.speed
end

function updatePlayer(dt)
    if player.x < love.graphics.getWidth() then
        if love.keyboard.isDown("d") then
            if love.keyboard.isDown("lshift") then -- Shift doubles speed
                player.x = player.x + player.speed * 2 * dt
            else
                player.x = player.x + player.speed * dt
            end
        end
    end
    if player.x > 0 then
        if love.keyboard.isDown("a") then
            if love.keyboard.isDown("lshift") then -- Shift doubles speed
                player.x = player.x - player.speed * 2 * dt
            else
                player.x = player.x - player.speed * dt
            end
        end
    end
end

-- Enemy
local enemyMaxSpeed = ENEMY_MAXSPEED

function updateEnemy(dt)
    -- Calculate the difference between the ball and enemy position
    local diff = ball.x - enemy.x

    -- Adjust the speed to follow the ball, but limit it to maxSpeed
    if math.abs(diff) > 5 then  -- Add a threshold to prevent jittering when close to the ball
        -- Normalize the difference to move with the enemyMaxSpeed
        local direction = math.sign(diff)  -- Get the direction to move in (1 or -1)

        -- Move the enemy based on the direction, clamped by enemyMaxSpeed
        enemy.x = enemy.x + direction * enemyMaxSpeed * dt

        -- Make sure the enemy stays within the screen bounds
        if enemy.x < 0 then
            enemy.x = 0
        elseif enemy.x > love.graphics.getWidth() - enemy.width then
            enemy.x = love.graphics.getWidth() - enemy.width
        end
    end
end

-- Utility function for the direction of movement
function math.sign(x)
    if x > 0 then return 1 end
    if x < 0 then return -1 end
    return 0
end

function updateBall(dt)
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Ball bounces from sides
    if ball.x < 0 + ball.radius or ball.x > 800 - ball.radius then
        ball.vx = -ball.vx
    end
end

function checkCollision(ball, paddle)
    return ball.x - ball.radius < paddle.x + paddle.width / 2 and
           ball.x + ball.radius > paddle.x - paddle.width / 2 and
           ball.y - ball.radius < paddle.y + paddle.height / 2 and
           ball.y + ball.radius > paddle.y - paddle.height / 2
end

function increaseBallSpeed()
    -- Calculate the offset between the ball and the center of the paddle
    local offset = (ball.x - player.x) / (player.width / 2)
    
    -- Clamp the offset to the range [-1, 1] in case the ball is out of bounds
    offset = math.max(-1, math.min(1, offset))
    
    -- Speed increase factor based on how far the ball is from the center
    local speedIncrease = 1 + (math.abs(offset) * 0.5)  -- Max speed increase will be 1.5
    
    -- Apply the speed increase to the ball's speed
    ball.speed = ball.speed * speedIncrease
    
    -- Update ball's vx and vy based on the new speed (keeping the same direction)
    local angle = math.atan2(ball.vy, ball.vx)
    ball.vx = math.cos(angle) * ball.speed
    ball.vy = math.sin(angle) * ball.speed
end

function adjustBallAngle(ball, paddle)
    -- Calculate the distance between the ball and the center of the paddle
    local offset = (ball.x - paddle.x) / (paddle.width / 2)
    
    -- Clamp the offset to the range [-1, 1]
    offset = math.max(-1, math.min(1, offset))

    -- Slightly adjust the angle based on where the ball hit the paddle
    -- The further from the center the hit is, the more the angle changes
    local angle = math.atan2(ball.vy, ball.vx) + offset * math.pi / 6  -- Adjust the angle by a small factor
    ball.vx = math.cos(angle) * ball.speed
    ball.vy = math.sin(angle) * ball.speed
end

-- Pause
function drawPauseScreen()
    -- Set background color or darken the screen for the pause effect
    love.graphics.setColor(0, 0, 0, 0.5)  -- Semi-transparent black background
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())  -- Draw rectangle to cover the screen

    -- Draw the pause message
    love.graphics.setColor(1, 1, 1)  -- Set text color to white
    love.graphics.setFont(love.graphics.newFont(30))  -- Set font size for the pause message
    love.graphics.printf("Game Paused", 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), "center")

    -- Draw resume instructions
    love.graphics.setFont(love.graphics.newFont(20))  -- Set font size for instructions
    love.graphics.printf("Press 'P' to Resume", 0, love.graphics.getHeight() / 2 + 20, love.graphics.getWidth(), "center")
end

function checkGoal()
    if ball.y > love.graphics.getHeight() then
        gameState = "pause"
        PLAYER_POINTS = PLAYER_POINTS + 1
    elseif ball.y < 0 then
        gameState = "pause"
        ENEMY_POINTS = ENEMY_POINTS + 1
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "p" then
        -- Toggle between "pause" and "game" when "p" is pressed
        if gameState == "pause" then
            gameState = "game"  -- Resume the game
        else
            gameState = "pause"  -- Pause the game
        end
    end
end

----------------------GAME LOOP------------------------
function love.load()
    loadPlayer()
    loadEnemy()
    loadBall()

    background = love.graphics.newImage('sprites/Wood051_2K_Color.png')
end


function love.update(dt)
    if gameState == "pause" then
        love.keypressed()
    end
    if gameState == "game" then
        updatePlayer(dt)
        updateEnemy(dt)
        updateBall(dt)

        if checkCollision(ball, player) then
            ball.vy = -math.abs(ball.vy)  -- Always bounce upward
            ball.y = player.y - player.height / 2 - ball.radius  -- Move ball above paddle
            if ball.speed < 400 then
                increaseBallSpeed()
            end
            adjustBallAngle(ball, player)
        end

        if checkCollision(ball, enemy) then
            ball.vy = math.abs(ball.vy)  -- Always bounce downward
            ball.y = enemy.y + enemy.height / 2 + ball.radius  -- Move ball below paddle
            if ball.speed < 400 then
                increaseBallSpeed()
            end
            adjustBallAngle(ball, enemy)
        end
    end
    checkGoal()
end


function love.draw()
    if gameState == "menu" then
        drawMainMenu()
    elseif gameState == "game" then
        drawGame()
    elseif gameState == "pause" then
        drawPauseScreen()
    end
end