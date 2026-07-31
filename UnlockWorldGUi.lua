-- Script Daftar Semua World + Pilih Teleport
local function listAndTeleport()
    local rs = game:GetService("ReplicatedStorage")
    local CfgFind = require(rs.Tool.CfgFind)
    local worldConf = CfgFind.GetCfgByName("worldConf")
    local player = game.Players.LocalPlayer
    local GetData = require(rs.Tool.GetData)
    local currentWorld = GetData.GetCurWorld(player)
    
    if not worldConf then
        print("❌ worldConf tidak ditemukan!")
        return
    end
    
    print("=" .. string.rep("=", 70))
    print("🌍 DAFTAR WORLD")
    print("=" .. string.rep("=", 70))
    print("📍 World saat ini: " .. currentWorld)
    print("\n📋 Pilih world untuk teleport:")
    
    local worldList = {}
    for id, data in pairs(worldConf) do
        table.insert(worldList, {id = id, name = data.ZhName})
    end
    
    -- Urutkan berdasarkan ID
    table.sort(worldList, function(a, b) return a.id < b.id end)
    
    for i, world in pairs(worldList) do
        local isCurrent = (world.id == currentWorld) and "📍" or "  "
        print("  " .. isCurrent .. " [" .. i .. "] World " .. world.id .. ": " .. world.name)
    end
    
    print("\n" .. "=" .. string.rep("=", 70))
    print("💡 Gunakan: teleportToWorld(nomor)")
    print("   Contoh: teleportToWorld(1) untuk World 1")
    
    -- Simpan fungsi global
    _G.teleportToWorld = function(index)
        local selected = worldList[index]
        if not selected then
            print("❌ World index " .. index .. " tidak ditemukan!")
            return
        end
        
        local remoteEvent = rs.Msg:FindFirstChild("RemoteEvent")
        if remoteEvent then
            pcall(function()
                remoteEvent:FireServer("TeleportToTargetWorld", selected.id)
                print("✅ Teleport ke World " .. selected.id .. " (" .. selected.name .. ") dikirim!")
            end)
        else
            print("❌ RemoteEvent tidak ditemukan!")
        end
    end
    
    print("\n✅ Fungsi _G.teleportToWorld() tersedia!")
end

listAndTeleport()

-- Contoh setelah script dijalankan:
-- _G.teleportToWorld(1)  -- Teleport ke World 1
-- _G.teleportToWorld(15) -- Teleport ke World 15 (Shanghai)
