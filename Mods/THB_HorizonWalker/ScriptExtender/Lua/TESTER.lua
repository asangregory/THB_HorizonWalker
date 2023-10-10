-- Table to store distant strikers to prevent issues with more than one horizon walker using distant strike at once.
distantStrikers = {}
-- Character information for the individual distant strikers.
distantStriker = { preCastX = nil, preCastY = nil, preCastZ = nil, currentTarget = nil, targetList = {}, dStrikeExtraCharges = 0 }

function distantStriker:new(char)
    char = char or {}
    setmetatable(char, self)
    self.__index = self
    return char
end


guid1 = "Player_Elf-123456"
guid2 = "Player_Elf-132546"
guid3 = "123_Player_Elf_456"

function distantStrikerInfo(GUID)
    local guid = tostring(GUID)
    local info = nil
    for k, v in pairs(distantStrikers) do
        if string.find(k, guid) then
            info = distantStrikers[k]
            break
        end
    end
    if (info == nil) then
        distantStrikers[guid] = distantStriker:new()
        info = distantStrikers[guid]
    end
    return info
end

subGUID = "123456"

distantStrikerInfo(guid1)
distantStrikerInfo(guid2)
distantStrikerInfo(guid3)

_1_1_Table = {"Knife"}
_1_2_Table = {"Gun"}
_1_Table = {_1_1_Table, _1_2_Table}

_2_1_Table = {"Tomato"}
_2_2_Table = {"Apple"}
_2_3_Table = {"Orange"}
_2_Table = {_2_1_Table, _2_2_Table, _2_3_Table}

mainTable = {_1_Table, _2_Table}

function displayTieredTables (o)
    if type(o) == 'table' or type(o) == 'userdata' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end