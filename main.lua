-- Todo
-- Max ball speed

PLAYER_SPEED = 200
BALL_SPEED = 100

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

function updateEnemy(dt)
    enemy.x = ball.x
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



----------------------GAME LOOP STARTS------------------------
function love.load()
    loadPlayer()
    loadEnemy()
    loadBall()

    background = love.graphics.newImage('sprites/Wood051_2K_Color.png')
end


function love.update(dt)
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


function love.draw()
    love.graphics.draw(background,0,0)

    -- Draw Player
    love.graphics.rectangle("fill", player.x - player.width / 2, player.y - player.height / 2, player.width, player.height)

    -- Draw Enemy
    love.graphics.rectangle("fill", enemy.x - enemy.width / 2, enemy.y - enemy.height / 2, enemy.width, enemy.height)

    -- Draw Ball
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)

    -- Display Ball Speed
    love.graphics.setFont(love.graphics.newFont(20))  -- Set font size to 20
    love.graphics.setColor(1, 1, 1)  -- Set text color to white (default)
    love.graphics.print("Ball Speed: " .. string.format("%.2f", ball.speed), 10, 10)  -- Display speed at top-left corner
    --love.graphics.print("vx: " .. string.format("%.2f", ball.vx), 10, 30)
    --love.graphics.print("vx: " .. string.format("%.2f", ball.vy), 10, 50)
    
end