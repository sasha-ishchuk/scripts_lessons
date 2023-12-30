local json = require("libs/dkjson")
local backgroundImage = love.graphics.newImage('assets/images/background.jpg')

local wantToSave = false

function love.load()

    -- set animation image
    local image = love.graphics.newImage("assets/images/exp2.jpg")
    animation = newAnimation(image, 30, 30, 1)
    animation.isStopped = true -- Set to true initially

    -- set window title
    love.window.setTitle("TETRIS")

    -- set background sound
    love.audio.stop()
    sound = love.audio.newSource("assets/sounds/background.mp3", "static")
    volume = 0.1
    sound:setVolume(volume)
    love.audio.play(sound)

    -- define types of blocks
    tetrisBlocks = {
        -- line blocks
        {
            {
                {' ', 'l', ' ', ' '},
                {' ', 'l', ' ', ' '},
                {' ', 'l', ' ', ' '},
                {' ', 'l', ' ', ' '},
            }, 
            {
                {' ', ' ', ' ', ' '},
                {'l', 'l', 'l', 'l'},
                {' ', ' ', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
        },
        -- Г-type blocks v1
        {
            {
                {' ', 'x', ' ', ' '},
                {' ', 'x', ' ', ' '},
                {' ', 'x', 'x', ' '},
                {' ', ' ', ' ', ' '},
            }, 
            {
                {' ', ' ', 'x', ' '},
                {'x', 'x', 'x', ' '},
                {' ', ' ', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
            {
                {'x', 'x', ' ', ' '},
                {' ', 'x', ' ', ' '},
                {' ', 'x', ' ', ' '},
                {' ', ' ', ' ', ' '},
            }, 
            {
                {' ', ' ', ' ', ' '},
                {'x', 'x', 'x', ' '},
                {'x', ' ', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
        },
         -- Г-type blocks v2
        {
            {
                {' ', 'g', ' ', ' '},
                {' ', 'g', ' ', ' '},
                {'g', 'g', ' ', ' '},
                {' ', ' ', ' ', ' '},
            }, 
            {
                {' ', ' ', ' ', ' '},
                {'g', 'g', 'g', ' '},
                {' ', ' ', 'g', ' '},
                {' ', ' ', ' ', ' '},
            },
            {
                {' ', 'g', 'g', ' '},
                {' ', 'g', ' ', ' '},
                {' ', 'g', ' ', ' '},
                {' ', ' ', ' ', ' '},
            }, 
            {
                {' ', ' ', ' ', ' '},
                {'g', 'g', 'g', ' '},
                {' ', ' ', 'g', ' '},
                {' ', ' ', ' ', ' '},
            },
        },
        -- square block
        {
            {
                {' ', ' ', ' ', ' '},
                {' ', 's', 's', ' '},
                {' ', 's', 's', ' '},
                {' ', ' ', ' ', ' '},
            }, 
        },
         -- T-type blocks
         {
            {
                {' ', 't', ' ', ' '},
                {'t', 't', 't', ' '},
                {' ', ' ', ' ', ' '},
                {' ', ' ', ' ', ' '},
            }, 
            {
                {' ', 't', ' ', ' '},
                {' ', 't', 't', ' '},
                {' ', 't', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
            {
                {' ', ' ', ' ', ' '},
                {'t', 't', 't', ' '},
                {' ', 't', ' ', ' '},
                {' ', ' ', ' ', ' '},
            }, 
            {
                {' ', 't', ' ', ' '},
                {'t', 't', ' ', ' '},
                {' ', 't', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
        },
         -- zig-zag blocks v1
        {
            {
                {'z', ' ', ' ', ' '},
                {'z', 'z', ' ', ' '},
                {' ', 'z', ' ', ' '},
                {' ', ' ', ' ', ' '},
            }, 
            {
                {' ', ' ', ' ', ' '},
                {' ', 'z', 'z', ' '},
                {'z', 'z', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
        },
        -- zig-zag blocks v2
        {
            {
                {' ', 'q', ' ', ' '},
                {'q', 'q', ' ', ' '},
                {'q', ' ', ' ', ' '},
                {' ', ' ', ' ', ' '},
            }, 
            {
                {' ', ' ', ' ', ' '},
                {'q', 'q', ' ', ' '},
                {' ', 'q', 'q', ' '},
                {' ', ' ', ' ', ' '},
            },
        },
    }

    -- set game board size
    boardWidth = 10
    boardHeight = 18
    
    -- create block
    function createBlock()
        x = boardWidth/2 -1
        y = 0
        rot = 1
        type = table.remove(game)
        if #game == 0 then
            newGame()
        end
    end

    function canRotate(x1, y1, rot1)
        for i = 1, 4 do
            for j = 1, 4 do
                local blockX = x1 + i
                local blockY = y1 + j
                if tetrisBlocks[type][rot1][i][j] ~= ' ' and (
                blockX < 1 
                or blockX > boardWidth 
                or blockY > boardHeight 
                or board[blockY][blockX] ~= ' '
                ) then
                    return false
                end
            end 
        end
        return true
    end

    function newGame()
        game = {}
        for typeId = 1, #tetrisBlocks do
            local pos = love.math.random(#game + 1)
            table.insert(game, pos, typeId)
        end
    end

    points = 0
    timeLimit = 1
    scoreLimit = 0
    
    -- clear board
    board = {}
    for y = 1, boardHeight do
        board[y] = {}
        for x = 1, boardWidth do
            board[y][x] = ' '
        end
    end
    
    newGame()
    createBlock()
    
    timer = 0

    loadGameState()
end


function love.update(dt)

    if not animation.isStopped then
        animation.currentTime = animation.currentTime + dt
        if animation.currentTime >= animation.duration then
            animation.currentTime = animation.duration
            animation.isStopped = true
        end
    end

    timer = timer + dt
    if scoreLimit > 500 then
        timeLimit = timeLimit - 10 * dt
        scoreLimit = 0
    end

    if timeLimit < 0.1 then
        timeLimit = 0.1
    end
    
    if timer >= timeLimit then
        timer = 0

        local y1 = y + 1
        if canRotate(x, y1, rot) then
            y = y1
        else
            for i = 1, 4 do
                for j = 1, 4 do
                    local block = tetrisBlocks[type][rot][i][j]
                    if block ~= ' ' then
                        board[y + j][x + i] = block
                    end
                end
            end

            for i = 1, boardHeight do
                local complete = true
                for j = 1, boardWidth do
                    if board[i][j] == ' ' then
                        complete = false
                        break
                    end
                end
        
                if complete then

                    -- run the animation
                    animation.isStopped = false
                    animation.currentTime = 0

                    -- play sound of completed row
                    sound_row_finished = love.audio.newSource("assets/sounds/row.wav", "static")
                    volume_row = 1
                    sound_row_finished:setVolume(volume_row)
                    love.audio.play(sound_row_finished)

                    points = points + 100
                    scoreLimit = scoreLimit + 100
                    
                    for removeY = i, 2, -1 do
                        for removeX = 1, boardWidth do
                            board[removeY][removeX] = board[removeY - 1][removeX]
                        end
                    end

                    for removeX = 1, boardWidth do
                        board[1][removeX] = ' '
                    end

                end

            end

            createBlock()

            if not canRotate(x, y, rot) then
                love.load()
            end
        end
    end
end


function love.draw()
    love.graphics.draw(backgroundImage, -100, -100)

    if not animation.isStopped then
        local spriteNum = math.floor(animation.currentTime / animation.duration * #animation.quads) + 1
        if spriteNum <= #animation.quads and spriteNum > 0 then
            love.graphics.draw(animation.spriteSheet, animation.quads[spriteNum], 0, 0, 0, 28)
        end
    end

    local function drawBlock(block, i, j)

        -- set coloros
        local WHITE = {1.0, 1.0, 1.0}
        local GRAY = {0.7, 0.7, 0.7}
        local RED = {0.99, 0.0, 0.0}
        local GREEN = {0.0, 0.99, 0.0}
        local BLUE = {0.0, 0.0, 0.99}
        local YELLOW = {0.99, 0.99, 0.0}
        local PINK = {0.87, 0.12, 0.49}
        local PURPLE = {0.59, 0.06, 0.8}
        local OCEAN = {0.02, 0.7, 0.7}
        local LIGHT_PINK = {1, 0.7, 0.9}
        local LIGHT_RED = {1, 0.569, 0.494}
        local GRAY_2 = {0.251, 0.204, 0.196}
        
        local colors = {
            [' '] = GRAY_2, 
            l = RED, x = GREEN,
            g = BLUE, s = YELLOW,
            t = PINK, z = PURPLE,
            q = OCEAN, next = LIGHT_RED
        }

        local color = colors[block]
        
        love.graphics.setColor(color)
        
        local blockSize = 28
        local blockDrawSize = blockSize - 2

        love.graphics.rectangle(
            'fill',
            (j - 1) * blockSize,
            (i - 1) * blockSize,
            blockDrawSize,
            blockDrawSize
        )
    end

    local marginWidth = 2
    local marginHeight = 10

    for i = 1, boardHeight do
        for j = 1, boardWidth do
            drawBlock(board[i][j], i + marginWidth, j + marginHeight)
        end
    end

    for i = 1, 4 do
        for j = 1, 4 do
            local block = tetrisBlocks[type][rot][i][j]
            if block ~= ' ' then
                drawBlock(block, j + y + marginWidth, i + x + marginHeight)
            end
        end
    end

    for y = 1, 4 do
        for x = 1, 4 do
            local block = tetrisBlocks[game[#game]][1][y][x]
            if block ~= ' ' then
                drawBlock('next', x + 8, y + 4)
            end
        end
    end

    font = love.graphics.newFont('/assets/fonts/FutureTimeSplitters.ttf', 20)
    love.graphics.setFont(font)
    -- love.graphics.set(0.1, 0, 0)
    love.graphics.print("POINTS: "..points, 30, 60)
    love.graphics.print("UP - ROTATE", 30, 110)
    love.graphics.print("C - DROP DOWN", 30, 140)
    love.graphics.print("NEXT -> ", 30, 253)
end

-- create simple animation
function newAnimation(image, width, height, duration)
    local animation = {}
    animation.spriteSheet = image;
    animation.quads = {};
    for y = 0, image:getHeight() - height, height do
        for x = 0, image:getWidth() - width, width do
            table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end
    animation.duration = duration or 1
    animation.currentTime = 0
    animation.isStopped = false
    return animation
end

-- save game
function saveGameState()
    local data = {
        board = board,
        points = points,
        timeLimit = timeLimit,
        scoreLimit = scoreLimit,
        game = game,
        x = x,
        y = y,
        rot = rot
    }
    local serializedData = json.encode(data)
    -- savw file into location C:\Users\user-name\AppData\Roaming\LOVE\tetris-love2d
    love.filesystem.write("savegame.json", serializedData)
end

-- load saved game
function loadGameState()
    if love.filesystem.getInfo("savegame.json") then
        local serializedData = love.filesystem.read("savegame.json")
        local loadedData = json.decode(serializedData)
        board = loadedData.board or board
        points = loadedData.points or points
        timeLimit = loadedData.timeLimit or timeLimit
        scoreLimit = loadedData.scoreLimit or scoreLimit
        game = loadedData.game or game
        x = loadedData.x or x
        y = loadedData.y or y
        rot = loadedData.rot or rot
    end
end

-- keyboard 
function love.keypressed(key)
    if key == 'up' then
        local rot1 = rot + 1
        if rot1 > #tetrisBlocks[type] then
            rot1 = 1
        end
        if canRotate(x, y, rot1) then
            rot = rot1
        end
    elseif key == 'left' then
        if canRotate(x - 1, y, rot) then
            x = x - 1
        end
    elseif key == 'right' then
        if canRotate(x + 1, y, rot) then
            x = x + 1
        end
    elseif key == 'c' then
        while canRotate(x, y + 1, rot) do
            y = y + 1
            timer = timeLimit
        end
    elseif key == 'down' then
        if canRotate(x, y + 1, rot) then
            y = y + 1
        end
    end
end

-- touch controls
function love.touchpressed(id, x, y, dx, dy, pressure)
    local halfScreenWidth = love.graphics.getWidth() / 2
    local quarterScreenWidth = halfScreenWidth / 2

    if x < quarterScreenWidth then
        if canRotate(x, y, rot) then
            rot = rot + 1
            if rot > #tetrisBlocks[type] then
                rot = 1
            end
        end
    elseif x > quarterScreenWidth and x < halfScreenWidth + quarterScreenWidth then
        if dx > 0 then
            if canRotate(x + 1, y, rot) then
                x = x + 1
            end
        elseif dx < 0 then
            if canRotate(x - 1, y, rot) then
                x = x - 1
            end
        end
    else
        if canRotate(x, y + 1, rot) then
            y = y + 1
        end
    end
end

-- save game and ask when quit
function love.quit()
    local message = "Do you want to save the game before quitting? (Y/N)"
    local buttons = {"Yes", "No"}
    local choice = love.window.showMessageBox("Quit Game", message, buttons, "info")

    if choice == 1 then
        wantToSave = true
    else
        wantToSave = false
    end

    if wantToSave then
        saveGameState()
        wantToSave = false
    end

    return wantToSave
end
