Advanced_trajectory = {}
local ATY = Advanced_trajectory
Advanced_trajectory.table={}
Advanced_trajectory.boomtable={}
Advanced_trajectory.aimcursor=nil
Advanced_trajectory.aimcursorsq = nil
Advanced_trajectory.panel = {}
Advanced_trajectory.panel.instance = nil
Advanced_trajectory.aimnum = 100

Advanced_trajectory.aimtexwtable ={} 
Advanced_trajectory.aimtexdistance = 0 --包含准星的武器

Advanced_trajectory.Advanced_trajectory = {}




function Advanced_trajectory.itemremove(worlditem)
    if worlditem==nil then return end
    -- worlditem:getWorldItem():getSquare():transmitRemoveItemFromSquare(worlditem:getWorldItem())
    worlditem:getWorldItem():removeFromSquare()
end

function Advanced_trajectory.mathfloor(number)
    return number-math.floor(number)
end

function Advanced_trajectory.additemsfx(square,itemname,x,y,z)
    -- if square:getZ()>7 then return end
    -- local iteminv = InventoryItemFactory.CreateItem(itemname)
    -- local itemin = IsoWorldInventoryObject.new(iteminv,square,Advanced_trajectory.mathfloor(x),Advanced_trajectory.mathfloor(y),Advanced_trajectory.mathfloor(z));
    -- iteminv:setWorldItem(itemin)
    -- square:getWorldObjects():add(itemin)
    -- square:getObjects():add(itemin)
    -- local chunk = square:getChunk()
    
    -- if chunk then
    --     square:getChunk():recalcHashCodeObjects()
    -- else return end
    -- -- iteminv:setAutoAge();
    -- -- itemin:setKeyId(iteminv:getKeyId());
    -- -- itemin:setName(iteminv:getName());
    return nil
end

function Advanced_trajectory.twotable(table2)
    local table1={}

    for i,k in pairs(table2) do
        table1[i]=table2[i]
    end
    -- print(table1)
    return table1
end

-- print(Advanced_trajectory.additemsfx(getPlayer():getCurrentSquare(),"Base.Apple",getPlayer():getCurrentSquare():getX(),getPlayer():getCurrentSquare():getY(),0):getWorldItem())

function Advanced_trajectory.getShootzombie(postable,damage,isshotplayer)

    local zbtable = {}
    local prtable = {}

    for kz = -1,1 do
        for vz = -1,1 do
            local sq = getCell():getGridSquare(postable[1]+kz*0.5,postable[2]+vz*0.5,postable[3])
            if sq then

                local movingObjects = sq:getMovingObjects()
                -- print(movingObjects)

                for zz=1,movingObjects:size() do
                    local zombiez = movingObjects:get(zz-1)
                    -- print(zombiez)
                    if instanceof(zombiez,"IsoZombie") or instanceof(zombiez,"IsoAnimal")  then
                        -- print("addzombie")
                        zbtable[zombiez] = 1
                    elseif isshotplayer and  instanceof(zombiez,"IsoPlayer") then
                        prtable[zombiez] = 1
                    end
                end
            end
        end
    end

    local mindistance = 0
    local minzb = {false,1}
    local minpr = {false,1}


    for sz,bz in pairs(zbtable) do
        mindistance = (postable[1] - sz:getX())^2 + (postable[2] - sz:getY())^2
        -- print(mindistance)
        if  mindistance<=0.42*damage then
            if mindistance < minzb[2] then
                minzb = {sz,mindistance}
            end
        end
    end

    for sz,bz in pairs(prtable) do
        mindistance = (postable[1] - sz:getX())^2 + (postable[2] - sz:getY())^2

        if  mindistance<=0.4*damage then
            if mindistance < minpr[2] then
                minpr = {sz,mindistance}
            end
        end
    end


    -- if minpr[1] and minpr[1]   then
    --     minpr[1]:getBodyDamage():ReduceGeneralHealth(30*damage)
    -- end

    return minzb[1],minpr[1]


end


function Advanced_trajectory.checkiswallordoor(square,angle,postion,postion2,nosfx)
    local objects = square:getObjects()
    if objects then
        for i=1,objects:size() do

            local locobject = objects:get(i-1)
            local sprite = locobject:getSprite()
            if sprite  then
                local Properties = sprite:getProperties()
                if Properties then
                    if instanceof(locobject,"IsoWindow") and not locobject:isSmashed() then

                        if nosfx then return true end
                        locobject:setSmashed(true)
                        getSoundManager():PlayWorldSoundWav("SmashWindow",square, 0.5, 2, 0.5, true);
                        return true
                    end





                    local intdel = 0.25
                    if Properties:Is(IsoFlagType.WallNW)then
                        if postion[2]  < square:getY() + intdel  and postion[1]  < square:getX() + intdel  then
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end
                    elseif Properties:Is(IsoFlagType.WallN) or (Properties:Is(IsoFlagType.doorN) and not locobject:IsOpen() )then
                        if postion[2]  < square:getY() + intdel then
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end

                    elseif Properties:Is(IsoFlagType.WallW) or (Properties:Is(IsoFlagType.doorW) and  not locobject:IsOpen()) then
                        if postion[1]  < square:getX() + intdel then
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end
                    end





                end
            end
        end
    end

    local player = getPlayer()
    local playervehicle 
    if player then
        playervehicle = player:getVehicle()
    end

    local squarecar = playervehicle or square:getVehicleContainer()
    -- local squarecar2
    -- local player = getPlayer()
    -- if player then
    --     local vehsq = player:getCurrentSquare()
    --     if vehsq then
    --         squarecar2 = vehsq:getVehicleContainer()
    --     end
    -- end
    
    if squarecar and ((squarecar:getX() -postion2[1] )^2  + (squarecar:getY() -postion2[2])^2)  >8 then


        if nosfx then return true end


        if ((squarecar:getX() -postion[1] )^2  + (squarecar:getY() -postion[2])^2) < 2.8  then

            if getSandboxOptions():getOptionByName("AT_VehicleDamageenable"):getValue() then

                
                squarecar:HitByVehicle(squarecar, 0.3)
                
            end
            return true
            
        end 
        
        
    end

    
end

function Advanced_trajectory.boomontick()

    local tablenow = Advanced_trajectory.boomtable
    for kt,vt in pairs(tablenow) do

        for kz,vz in pairs(vt[12]) do
            Advanced_trajectory.itemremove(vt[12][vt[3] - vt[13]])
        end

        if vt[3] > vt[2] + vt[13] then
            tablenow[kt] = nil
            break
        end

        if vt[3]== 1 and  vt[7]==0 then 


            local itemornone = Advanced_trajectory.additemsfx(vt[5],vt[1]..tostring(vt[3]),vt[4][1],vt[4][2],vt[4][3])
            table.insert(vt[12],itemornone)
            vt[3]=vt[3]+1
        elseif vt[7] > vt[6] and vt[3] <= vt[2] then
            vt[7] = 0

            local itemornone = Advanced_trajectory.additemsfx(vt[5],vt[1]..tostring(vt[3]),vt[4][1],vt[4][2],vt[4][3])
            table.insert(vt[12],itemornone)
            vt[3]=vt[3]+1
        elseif vt[7] > vt[6] then
            vt[7] = 0 
            vt[3]=vt[3]+1
        end
            
        vt[7] = vt[7] + getGameTime():getMultiplier()

    end


end

function Advanced_trajectory.boomsfx(sq,sfxName,sfxNum,ticktime)
    -- print(sq)
    local sfxname = sfxName or"Base.theMH_MkII_SFX"
    local sfxnum = sfxNum or 12
    local nowsfxnum =1
    local sfxcount = 0
    local pos = {sq:getX(), sq:getY() ,sq:getZ()}
    local square = sq
    local ticktime = ticktime or 2
    local func = function() return end
    local varz1,varz2,varz3
    local item = {}
    local offset = 3

    local tablesfx = {

        sfxname,         ---1
        sfxnum,          ---2
        nowsfxnum,       ---3
        pos,             ---4
        square,          ---5
        ticktime,        ---6
        sfxcount,        ---7
        func,            ---8
        varz1,           ---9
        varz2,           ---10
        varz3,           ---11
        item,            ---12
        offset           ---13滞后
    }

    table.insert(Advanced_trajectory.boomtable,tablesfx)
end


function Advanced_trajectory.OnPlayerUpdate()

    

    local player = getPlayer() 
    if not player then return end
    local weaitem = player:getPrimaryHandItem()

    -- local isspwaepon = 



    if  player:isAiming()  and instanceof(weaitem,"HandWeapon") and (((weaitem:isRanged() and getSandboxOptions():getOptionByName("Advanced_trajectory.Enablerange"):getValue()) or (weaitem:getSwingAnim() =="Throw" and getSandboxOptions():getOptionByName("Advanced_trajectory.Enablethrow"):getValue())) or Advanced_trajectory.Advanced_trajectory[weaitem:getFullType()]) and (((string.contains(weaitem:getAmmoType() or "","Shotgun") or string.contains(weaitem:getAmmoType() or "","shotgun")) and  getSandboxOptions():getOptionByName("Advanced_trajectory.Enableshotgun"):getValue()) or not (string.contains(weaitem:getAmmoType() or "","Shotgun") or string.contains(weaitem:getAmmoType() or "","shotgun")))      then
        weaitem:setMaxHitCount(0)
        Mouse.setCursorVisible(false)
        

        -- print(getPlayer():getCoopPVP())

        
        

        local level = 11-player:getPerkLevel(Perks.Aiming)

        local gametimemul = getGameTime():getMultiplier() * 16/(level+10)
        local maxaimnum = weaitem:getAimingTime() + level*7 + getSandboxOptions():getOptionByName("Advanced_trajectory.maxaimnum"):getValue() 

        if Advanced_trajectory.aimnum > maxaimnum then
            Advanced_trajectory.aimnum = maxaimnum
        end

        
        
        if player:getVariableBoolean("isMoving") then
            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum +gametimemul*getSandboxOptions():getOptionByName("Advanced_trajectory.moveeffect"):getValue() 
        end
        

        if player:getVariableBoolean("isTurning") then
            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum +gametimemul*getSandboxOptions():getOptionByName("Advanced_trajectory.turningeffect"):getValue() 
        end

        if Advanced_trajectory.aimnum > 0  then
            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum -gametimemul*getSandboxOptions():getOptionByName("Advanced_trajectory.reducespeed"):getValue() 
            -- print(gametimemul)
        end

        if Advanced_trajectory.aimnum < 0  then
            Advanced_trajectory.aimnum = 0
        end

        -- print(Advanced_trajectory.aimnum)

        

        if not Advanced_trajectory.panel.instance and  getSandboxOptions():getOptionByName("Advanced_trajectory.aimpoint"):getValue()  then
            Advanced_trajectory.panel.instance = Advanced_trajectory.panel:new(0,0,200,200)
            Advanced_trajectory.panel.instance:initialise()
            Advanced_trajectory.panel.instance:addToUIManager() 
        end

        local isspwaepon = Advanced_trajectory.Advanced_trajectory[weaitem:getFullType()]

        if weaitem:getSwingAnim() =="Throw"  or (isspwaepon and isspwaepon["islightsq"]) then

            weaitem:setPhysicsObject(nil)  
            weaitem:setMaxHitCount(0)

            --getPlayer():getPrimaryHandItem():getSmokeRange()

            if not Advanced_trajectory.aimcursor then
                -- Advanced_trajectory.thorwerinfo = {
                --     weaitem:getSmokeRange(),
                --     weaitem:getExplosionPower(),
                --     weaitem:getExplosionRange(),
                --     weaitem:getFirePower(),
                --     weaitem:getFireRange()
                -- }
                Advanced_trajectory.aimcursor = ISThorowitemToCursor:new("", "", player,weaitem)
                getCell():setDrag(Advanced_trajectory.aimcursor, 0)
            end
        end 


        local dx = getMouseXScaled();
        local dy = getMouseYScaled();
        local playerZ = math.floor(player:getZ())


        local isaimobject =false

        for Z=0,7 do

            -- print(dx,"---",x)
            local deldis = Z - playerZ


            local wx, wy = ISCoordConversion.ToWorld(dx-3*deldis, dy-3*deldis, Z);
            wx = math.floor(wx);
            wy = math.floor(wy);
        
            
        
            local cell = getWorld():getCell();
            


            for yz=-1,1 do




                for lz = -1 ,1 do


                    local sq = cell:getGridSquare(wx+2.2 + yz, wy+2.2 + lz, Z);
                    if sq then

                        local movingObjects = sq:getMovingObjects()
                        -- print(movingObjects)
        
                        for zz=1,movingObjects:size() do
                            local zombiez = movingObjects:get(zz-1)
                            -- print(zombiez)
                            if instanceof(zombiez,"IsoZombie") then
        
        
                                -- player:Say("get"..tostring(Z))
        
                                Advanced_trajectory.aimlevels = Z
        
                                isaimobject = true
        
                                return 
        
        
        
                            
                            elseif instanceof(zombiez,"IsoPlayer") then
        
                                -- player:Say("get"..tostring(Z))
        
                                Advanced_trajectory.aimlevels = Z
                                isaimobject = true
                                return
                                
        
        
        
                            end
                        end
                    end
                

                end
            

            end

            

            

            if not isaimobject then
                Advanced_trajectory.aimlevels = nil
                
            end

        

        end

        -- print(Advanced_trajectory.aimlevels)
        





      

        
        
    else 
        if Advanced_trajectory.aimcursor then
            getCell():setDrag(nil, 0);
            Advanced_trajectory.aimcursor=nil
            Advanced_trajectory.thorwerinfo={}
        end
        if Advanced_trajectory.panel.instance then
            Advanced_trajectory.panel.instance:removeFromUIManager()
            Advanced_trajectory.panel.instance=nil
        end
        Advanced_trajectory.aimnum = 100
        

    end
end

Advanced_trajectory.damagedisplayer = {}

function Advanced_trajectory.checkontick()

    Advanced_trajectory.boomontick()
    Advanced_trajectory.OnPlayerUpdate()


    local timemultiplier = getGameTime():getMultiplier()

    for la,lb in pairs(Advanced_trajectory.damagedisplayer) do

        lb[1] = lb[1] - timemultiplier
        if lb[1] < 0 then
            lb = nil
        else

            lb[3] = lb[3] + timemultiplier
            lb[4] = lb[4] - timemultiplier
            lb[2]:AddBatchedDraw(lb[3], lb[4], true)

            -- print(Advanced_trajectory.damagedisplayer[3] - Advanced_trajectory.damagedisplayer[5])
            
        end
    
    
    end


    -- if  then

    --     -- Advanced_trajectory.damagedisplayer = {1,damagea,sx,sy,1,1}



    --     Advanced_trajectory.damagedisplayer[1] = Advanced_trajectory.damagedisplayer[1] 


    --     if Advanced_trajectory.damagedisplayer[1] < 0 then
    --         Advanced_trajectory.damagedisplayer = nil
    --     else

    --         Advanced_trajectory.damagedisplayer[3] = Advanced_trajectory.damagedisplayer[3] + timemultiplier
    --         Advanced_trajectory.damagedisplayer[4] = Advanced_trajectory.damagedisplayer[4] - timemultiplier

    --         -- if (Advanced_trajectory.damagedisplayer[3] - Advanced_trajectory.damagedisplayer[5])<15 then
                
                
    --         -- end
            
    
    --         Advanced_trajectory.damagedisplayer[2]:AddBatchedDraw(Advanced_trajectory.damagedisplayer[3], Advanced_trajectory.damagedisplayer[4], true)

    --         -- print(Advanced_trajectory.damagedisplayer[3] - Advanced_trajectory.damagedisplayer[5])
            
    --     end

        
        
    -- end


    


    local tablenow = Advanced_trajectory.table
    -- print(#tablenow)
    -- print(getGameTime():getMultiplier())
    for kt,vt in pairs(tablenow) do

        



        Advanced_trajectory.itemremove(vt[1])
        

        local tablenowz12_ = vt[12]*0.35


        
        -- local avenfps = getAverageFPS()
        -- if avenfps >=60 then
        --     avenfps=60   
        -- end
        -- tablenowz12_ = vt[12]*60/avenfps
        
        vt[2]=getWorld():getCell():getOrCreateGridSquare(vt[4][1],vt[4][2],vt[4][3])
        vt[22]["pos"] = {Advanced_trajectory.mathfloor(vt[4][1]),Advanced_trajectory.mathfloor(vt[4][2])}
        if vt[2] then
            if Advanced_trajectory.checkiswallordoor(vt[2],vt[5],vt[4],vt[20],vt["nonsfx"]) and not vt[15] then

                -- print(vt["wallcarmouse"])
                if  vt[9] =="Grenade" or vt["wallcarmouse"] or vt["wallcarzombie"]then

                    if vt[22][2] > 0 then
                        Advanced_trajectory.boomsfx(vt[2],vt["boomsfx"][1],vt["boomsfx"][2],vt["boomsfx"][3])
                    end
                    if not vt["nonsfx"]  then
                        -- print("Boom")
                        Advanced_trajectory.Boom(vt[2],vt[22])
                    end
                    
                end
                Advanced_trajectory.itemremove(vt[1]) 
                tablenow[kt]=nil
                break
            end

            local mathfloor = Advanced_trajectory.mathfloor


            vt[1] = Advanced_trajectory.additemsfx(vt[2],vt[14]..tostring(vt[8]),mathfloor(vt[4][1]),mathfloor(vt[4][2]),mathfloor(vt[4][3]))
            local spnumber = (vt[3][1]^2 + vt[3][2]^2)^0.5*tablenowz12_
            vt[7]=vt[7]-spnumber
            vt[17] = vt[17]+ spnumber

            if vt[9] == "flamethrower" then

                -- print(vt[17])
                if vt[17] >3 then
                    vt[17] = 0
                    vt[21]=vt[21]+1
                    vt[4] = Advanced_trajectory.twotable(vt[20])
                end
                -- print(vt[21])
                if vt[21] >4 then
                    Advanced_trajectory.itemremove(vt[1]) 
                    tablenow[kt]=nil
                    break
                end
            
            elseif vt[7]<0 and vt[9] ~= "Grenade"  then

                -- if (vt[22][2]or 0 )> 0 then 
                --     Advanced_trajectory.boomsfx(vt[2])
                -- end


                if vt["wallcarmouse"] or vt["wallcarzombie"]then

                    if vt[22][2] > 0 then
                        Advanced_trajectory.boomsfx(vt[2],vt["boomsfx"][1],vt["boomsfx"][2],vt["boomsfx"][3])
                    end
                    if not vt["nonsfx"]  then
                        Advanced_trajectory.Boom(vt[2],vt[22])
                    end
                end



                Advanced_trajectory.itemremove(vt[1])
                tablenow[kt]=nil
                break
            end

            vt[5] = vt[5]+vt[10]
            if vt[1] then
                vt[1]:setWorldZRotation(vt[5])
            -- elseif vt[9] ~= "Grenade" then
            --     -- Advanced_trajectory.itemremove(vt[1]) 
            --     tablenow[kt]=nil
            --     break
            end

            vt[4][1] = vt[4][1]+tablenowz12_*vt[3][1]
            vt[4][2] = vt[4][2]+tablenowz12_*vt[3][2]

            -- print(kt,"a-----a",vt[4])
            -- print(kt,"a-----a",vt[3][1])

            -- print(kt,"-=--",tablenowz12_*vt[3][2])
            -- vt[21]= vt[21]+tablenowz12_*vt[3][2]
            -- print(kt,"-=--",vt[21])
            -- -- vt[21] = vt[21]+1


            if  vt["isparabola"]  then

                vt[4][3] = 0.5-vt["isparabola"]*vt[17]*(vt[17]-vt[18])
                
                if vt[4][3]<=0.3  then
                    if not vt["nonsfx"]  then
                        Advanced_trajectory.Boom(vt[2],vt[22])
                    end
                    
                    if vt[22][2] > 0 then
                        Advanced_trajectory.boomsfx(vt[2],vt["boomsfx"][1],vt["boomsfx"][2],vt["boomsfx"][3])
                    end
                    Advanced_trajectory.itemremove(vt[1])
                    tablenow[kt]=nil
                    break
                end

            -- elseif  vt[9] =="GrenadeLauncher" then
            --     vt[4][3] = 0.5-0.02*vt[17]*(vt[17]-vt[18])
            --     if vt[4][3] <=0.5  then
            --         Advanced_trajectory.boomsfx(vt[2])
            --         Advanced_trajectory.itemremove(vt[1])
            --         tablenow[kt]=nil
            --         break
            --     end
            end

            if  (vt[9] ~= "Grenade" or (vt[22][8]or 0) > 0 or vt["wallcarzombie"]) and  not vt["wallcarmouse"]then
                local saywhat = "IGUI_Headshot"
                local isshotplayer = getSandboxOptions():getOptionByName("Advanced_trajectory.playerdamage"):getValue()


                local angleammo = vt[5]

                local angelammooff = 0

                if angleammo >=135 and angleammo<=180 then
                    angelammooff = angleammo - 135
                elseif angleammo >=-180 and angleammo<=-135 then
                    angelammooff = angleammo+180 +45
                elseif angleammo >=-135 and angleammo<=-45 then
                    angelammooff = -angleammo - 45 
                end

                angelammooff = angelammooff/30

                -- print(angelammooff)
               

                local admindel = vt["animlevels"] - math.floor(vt[4][3])
                local shootlevel =  vt[4][3] + admindel

                if  vt["isparabola"] then
                    
                    shootlevel  = vt[4][3]
                end
                    


                local Playershot
                local Zombie,Playershot =  Advanced_trajectory.getShootzombie({vt[4][1] + admindel*3,vt[4][2]  + admindel*3,shootlevel},1 +angelammooff ,isshotplayer)
                
                local damagezb = 12* vt[6]*0.1
                local damagepr = 20


                if not Zombie and not Playershot  then
                    Zombie,Playershot = Advanced_trajectory.getShootzombie({vt[4][1]-0.9 +angelammooff*0.45+admindel*3,vt[4][2]-0.9+angelammooff*0.45+admindel*3,shootlevel},2,isshotplayer)
                    damagezb = 4*vt[6]*0.1
                    saywhat = "IGUI_Bodyshot"
                    damagepr = 2
                end
                if not Zombie and not Playershot then
                    Zombie,Playershot = Advanced_trajectory.getShootzombie({vt[4][1]-1.8+0.9*angelammooff+admindel*3,vt[4][2]-1.8+0.9*angelammooff+admindel*3,shootlevel},3,isshotplayer)
                    damagezb = 1*vt[6]*0.1
                    saywhat = "IGUI_Footshot"
                    damagepr = 1
                end


                -- if not Zombie and not Playershot and vt[2]:getObjects():size() <2 and vt[20][3]>0 then
                --     Zombie,Playershot =  Advanced_trajectory.getShootzombie({vt[4][1]-3,vt[4][2]-3,vt[4][3]-1},4,isshotplayer)
                --     damagezb = 10 * vt[6]*0.1
                --     damagepr = 20
                -- end

                -- print(Playershot)

                if not vt["nonsfx"] and Playershot and vt[19] and Playershot ~= vt[19] and (Faction.getPlayerFaction(Playershot)~=Faction.getPlayerFaction(vt[19]) or not Faction.getPlayerFaction(Playershot))     then
                    
                    Playershot:setX(Playershot:getX()+0.15*vt[3][1])
                    Playershot:setY(Playershot:getY()+0.15*vt[3][2])
                    Playershot:addBlood(100)



                    if isClient() then
                        sendClientCommand("ATY_shotplayer","true",{damagepr,vt[6],Playershot:getOnlineID()})
                    else


                        local headpart = {
                            BodyPartType.Neck,
                            BodyPartType.Head
                        }
                        local midpart = {
                            BodyPartType.Torso_Upper,
                            BodyPartType.Torso_Lower,
                            BodyPartType.ForeArm_L,
                            BodyPartType.ForeArm_R,
                            BodyPartType.UpperArm_L,
                            BodyPartType.UpperArm_R,
                            BodyPartType.Groin,
                            BodyPartType.Back
                        }
                        local lowpart = {
                            BodyPartType.UpperLeg_L,
                            BodyPartType.UpperLeg_R,
                            BodyPartType.LowerLeg_L,
                            BodyPartType.LowerLeg_R,
                            BodyPartType.Foot_L,
                            BodyPartType.Foot_R
                        }

                        local shotpart = BodyPartType.Foot_R

                        if damagepr == 20 then
                            shotpart = headpart[ZombRand(#headpart)+1]
                        elseif damagepr == 2 then
                            shotpart = midpart[ZombRand(#midpart)+1]
                        elseif damagepr ==1 then
                            shotpart = lowpart[ZombRand(#lowpart)+1]
                        end

                        local bodypart = Playershot:getBodyDamage():getBodyPart(shotpart)

                        if bodypart:haveBullet() then
                            local deepWound = bodypart:isDeepWounded()
                            local deepWoundTime = bodypart:getDeepWoundTime()
                            local bleedTime = bodypart:getBleedingTime()
                            bodypart:setHaveBullet(false, 0)
                            bodypart:setDeepWoundTime(deepWoundTime)
                            bodypart:setDeepWounded(deepWound)
                            bodypart:setBleedingTime(bleedTime)
                        else
                            bodypart:setHaveBullet(true, 0)
                        end

                        vt[19]:Say("PlayerDmg:"..tostring(math.floor(vt[6]*damagepr)) .."CH:"..tostring(math.floor(Playershot:getBodyDamage():getHealth())))
                        Playershot:getBodyDamage():ReduceGeneralHealth(vt[6]*damagepr)
                    end

                    Advanced_trajectory.itemremove(vt[1])
                    tablenow[kt]=nil
                    break
                end

                if Zombie and Zombie:isAlive() then
                    if vt[19] and getSandboxOptions():getOptionByName("Advanced_trajectory.callshot"):getValue() then
                        vt[19]:Say(getText(saywhat))
                    end

                    if vt["wallcarzombie"] or vt[9] == "Grenade"then

                        vt[22]["zombie"] = Zombie
                        if vt[22][2]> 0 then
                            Advanced_trajectory.boomsfx(vt[2])
                        end
                        if not vt["nonsfx"] then
                            Advanced_trajectory.Boom(vt[2],vt[22])
                        end
                        
                        Advanced_trajectory.itemremove(vt[1])
                        tablenow[kt]=nil
                        break
                    


                    elseif not vt["nonsfx"]  then
                        if vt[9] == "flamethrower" then
                            Zombie:setOnFire(true)
    
                        -- elseif vt[9] == "GrenadeLauncher" then
                            -- tanksuperboom(vt[2])
                        end

                        if isClient() then

                            sendClientCommand("ATY_cshotzombie","true",{Zombie:getOnlineID(),vt[19]:getOnlineID()})
                            -- Zombie:Kill(vt[19])
                            
                        end


                        -- if not string.find(tostring(Zombie:getCurrentState()), "Climb") and not string.find(tostring(Zombie:getCurrentState()), "Craw") then
                       
                        --     Zombie:changeState(ZombieIdleState.instance())
                        -- end

                        triggerEvent("OnWeaponHitCharacter", vt[19], Zombie, vt[19]:getPrimaryHandItem(), damagezb) -- OnWeaponHitXp From "KillCount",used(wielder,victim,weapon,damage)






                        if getSandboxOptions():getOptionByName("ATY_damagedisplay"):getValue() then
                            local damagea = TextDrawObject.new()
                            damagea:setDefaultColors(1,1,0.1,0.7)
                            damagea:setOutlineColors(0,0,0,1)
                            damagea:ReadString(UIFont.Middle, "-" ..tostring(math.floor(damagezb*100)), -1)
                            local sx = IsoUtils.XToScreen(Zombie:getX(), Zombie:getY(), Zombie:getZ(), 0);
                            local sy = IsoUtils.YToScreen(Zombie:getX(), Zombie:getY(), Zombie:getZ(), 0);
                            sx = sx - IsoCamera.getOffX() - Zombie:getOffsetX();
                            sy = sy - IsoCamera.getOffY() - Zombie:getOffsetY();
                            sy = sy - 64
                            sx = sx / getCore():getZoom(0)
                            sy = sy / getCore():getZoom(0)
                            sy = sy - damagea:getHeight()
    
    
                            table.insert(Advanced_trajectory.damagedisplayer,{60,damagea,sx,sy,sx,sy})
                            
                        end
                        
                        -- damagea:AddBatchedDraw(sx, sy, true)
                        -- Advanced_trajectory.damagedisplayer = 
                        -- print("-" ..tostring(math.floor(damagezb*100)))


                        Zombie:setHealth(Zombie:getHealth()-damagezb)
                        -- Zombie:setHitReaction("HitReaction")

                        -- Zombie:setHitTime(99)
                        -- Zombie:setHitDirEnum("FRONT")

                        -- Zombie:setHitForce(999);
                        -- Zombie:setStaggerBack(true);
                        

                        -- Zombie:setHitAngle(Vector2f.new())


                        -- Zombie:setHitReaction("");
                        Zombie:pathToCharacter(vt[19])
                        -- Zombie:DoZombieStats();
                        Zombie:setHitReaction("ShotChest");
                        -- Zombie:setPlayerAttackPosition("BEHIND");
                        

                        
                        Zombie:addBlood(getSandboxOptions():getOptionByName("AT_Blood"):getValue())
                        
    
    
    
                        if Zombie:getHealth()<=0.1 then 
                                
                            if vt[19] then

                                if isClient() then

                                    sendClientCommand("ATY_killzombie","true",{Zombie:getOnlineID()})
                                    -- Zombie:Kill(vt[19])
                                end
                                Zombie:Kill(vt[19])

                                
                                    


                            

                                
                                
                                vt[19]:setZombieKills(vt[19]:getZombieKills()+1)
                                vt[19]:setLastHitCount(1)
                                vt[19]:getXp():AddXP(Perks.Aiming, 1);



                                -- triggerEvent("OnWeaponHitXp",vt[19], vt[19]:getPrimaryHandItem(), Zombie, damagezb) -- OnWeaponHitXp From "KillCount",used(wielder,weapon,victim,damage)
                            end
                                
                        end
    
    
                        -- Zombie:setHealth(Zombie:getHealth()-damagezb)
                        -- Zombie:setX(Zombie:getX()+0.15*vt[3][1])
                        -- Zombie:setY(Zombie:getY()+0.15*vt[3][2])
                        -- Zombie:addBlood(100)
                        -- -- print(Zombie:isAlive())
                        -- if Zombie:getHealth()<=0.1 then 
                            
                        --     if vt[19] then
                        --         Zombie:Kill(vt[19])
                        --         vt[19]:setZombieKills(vt[19]:getZombieKills()+1)
                        --         vt[19]:getXp():AddXP(Perks.Aiming, 1);
    
                        --     end
                            
                        --     -- local playerz = getPlayer()
                            
                        -- end
                        
                    end
                    

                    Advanced_trajectory.itemremove(vt[1])

                    if not vt["ThroNumber"] then vt["ThroNumber"] = 1 end
                    vt["ThroNumber"] = vt["ThroNumber"]-1
                    vt[6] = 0.36*vt[6]

                    if not vt[11] and (vt["ThroNumber"] <= 0  )then
                        tablenow[kt]=nil
                        break
                        
                    end  
                end

                
                
            end  
        end

    end

    -- print(Advanced_trajectory.table == tablenow)

    -- Advanced_trajectory.table =  tablenow

    


end

Events.OnTick.Add(Advanced_trajectory.checkontick)

function Advanced_trajectory.OnWeaponSwing(character, handWeapon)

    -- print(character)
    local item
    local winddir=1
    local weaponname = ""
    local rollspeed = 0
    local iscanthrough = false
    local ballisticspeed = 0.15  
    local ballisticdistance = handWeapon:getMaxRange(character)*1.5
    local itemtypename = ""
    local iscanbigger = 0
    local sfxname = ""
    local isthroughwall =true
    local distancez = 0

    local player=character

    local offx = character:getX()
    local offy = character:getY()
    local offz = character:getZ()

    local deltX
    local deltY
    local ProjectileCount = 1

    local throwinfo ={}
    local ispass =false


    local square
    local _damage

    local dirc = player:getForwardDirection():getDirection()

    local aimrate = Advanced_trajectory.aimnum * math.pi / 250

    

    dirc =   dirc + ZombRandFloat(-aimrate,aimrate)
    deltX=math.cos(dirc)
    deltY=math.sin(dirc)

    



    local tablez = 
    {
        item,                                      --1物品obj
        square,                                    --2方格obj
        {deltX,deltY},                             --3向量
        {offx, offy, offz},                        --4偏移量
        dirc,                                      --5方向
        _damage,                                   --6伤害
        ballisticdistance,                         --7距离
        winddir,                                   --8弹道小类别
        weaponname,                                --9种类
        rollspeed,                                 --10旋转速度
        iscanthrough,                              --11是否能够穿透
        ballisticspeed,                            --12弹道速度
        iscanbigger,                               --13是否可以变大
        sfxname,                                   --14弹道名称
        isthroughwall,                             --15是否能穿墙
        1,                                         --16尺寸
        0,                                         --17当前距离
        distancez,                                 --18距离常数
        player,                                    --19玩家
        {offx, offy, offz},                        --20原始偏移量
        0,                                         --21计数 
        throwinfo                                  --22投掷物属性                                                          
    }

    tablez["boomsfx"] = {}
    tablez["animlevels"] = Advanced_trajectory.aimlevels or math.floor(tablez[4][3])

    -- if Advanced_trajectory.thorwerinfo then
    --     tablez[22] = Advanced_trajectory.twotable(Advanced_trajectory.thorwerinfo)
    -- end
    -- Advanced_trajectory.thorwerinfo = {
        
    -- }

    tablez[22] = {
        handWeapon:getSmokeRange(),
        handWeapon:getExplosionPower(),
        handWeapon:getExplosionRange(),
        handWeapon:getFirePower(),
        handWeapon:getFireRange()
    }




    tablez[22][7] = handWeapon:getExplosionSound()

    tablez["ThroNumber"] = 1


    local isspweapon = Advanced_trajectory.Advanced_trajectory[handWeapon:getFullType()] 
    if isspweapon then
        for lk,pk in pairs(isspweapon) do
            if lk == 4 then
                tablez[4][1] = tablez[4][1]+pk[1]*tablez[3][1]
                tablez[4][2] = tablez[4][2]+pk[2]*tablez[3][2]
                tablez[4][3] = tablez[4][3]+pk[3]
            else 
                tablez[lk] = pk
            end
            
        end
        ispass = true
    end

    if Advanced_trajectory.aimcursorsq then
        tablez[18] = ((Advanced_trajectory.aimcursorsq:getX()+0.5-offx)^2+(Advanced_trajectory.aimcursorsq:getY()+0.5-offy)^2)^0.5
    else
        tablez[18] =handWeapon:getMaxRange(character)
    end

    if not ispass then  
        if getSandboxOptions():getOptionByName("Advanced_trajectory.Enablethrow"):getValue() and handWeapon:getSwingAnim() =="Throw" then  --投掷物

            
    
            
            
            if tablez[22][1] ==0 and tablez[22][2] ==0 and tablez[22][4]==0 then
                tablez[22][6] = 0.016
                
            else
                tablez[22][6] = 0.04--弧度
            end
    
            
            tablez[22][9] = handWeapon:canBeReused()
    
    
            tablez[7] = tablez[18]
            tablez[9]="Grenade"
            tablez[14] = handWeapon:getFullType()
            tablez[8] = ""
            tablez[11] = false
            tablez[15] = false

            tablez[4][1] = tablez[4][1]+0.3*tablez[3][1]
            tablez[4][2] = tablez[4][2]+0.3*tablez[3][2]

            tablez[10] = 6
            tablez[12] = 0.3
    
            tablez[22][10] = tablez[14]
            tablez["isparabola"] = tablez[22][6]
    

        elseif getSandboxOptions():getOptionByName("Advanced_trajectory.Enablerange"):getValue() and handWeapon:getSubCategory() =="Firearm" then ----枪


            if  (string.contains(handWeapon:getAmmoType() or "","Shotgun") or string.contains(handWeapon:getAmmoType() or "","shotgun"))   then
                if getSandboxOptions():getOptionByName("Advanced_trajectory.Enableshotgun"):getValue() then
                    tablez[9]="Shotgun"
                    tablez[14] = "Base.aty_Shotguna"
                    tablez[12] = 1.6  
                    tablez[7] = tablez[7]*0.46
                    tablez[15] = false
                    tablez[4][1] = tablez[4][1]+0.6*tablez[3][1]
                    tablez[4][2] = tablez[4][2]+0.6*tablez[3][2]
                    tablez[4][3] = tablez[4][3]+0.5
                    
                else
                    return
                    
                end
                

            else
                tablez[9]="revolver"
                tablez[14] = "Base.aty_revolversfx"
                tablez[12] = 1.8
                tablez[15]  = false
            
                tablez[4][1] = tablez[4][1]+0.6*tablez[3][1]
                tablez[4][2] = tablez[4][2]+0.6*tablez[3][2]
                tablez[4][3] = tablez[4][3]+0.57

                tablez["ThroNumber"] = ScriptManager.instance:getItem(handWeapon:getFullType()):getMaxHitCount()
            end
        else
            return
            
        end
        

    end

    tablez[2] = tablez[2] or getWorld():getCell():getGridSquare(offx,offy,offz)
    if tablez[2] == nil then return end

    local playerlevel = character:getPerkLevel(Perks.Aiming)
    tablez[6] = tablez[6] or (handWeapon:getMinDamage() + ZombRandFloat(0.1,1.3)*(0.5+handWeapon:getMaxDamage()-handWeapon:getMinDamage()))
    if ZombRand(100)+1 <= handWeapon:getCriticalChance() then
        tablez[6]=tablez[6]*2
    end
    -- throwinfo[8] = tablez[6]
    tablez[22][8] = handWeapon:getMinDamage()
    local dirc1 = tablez[5]
    tablez[5] = tablez[5]*360/(2*math.pi)
    tablez[12] = tablez[12]*getSandboxOptions():getOptionByName("Advanced_trajectory.bulletspeed"):getValue() 
    tablez[7] = tablez[7]*getSandboxOptions():getOptionByName("Advanced_trajectory.bulletdistance"):getValue() 


    local bulletnumber = getSandboxOptions():getOptionByName("Advanced_trajectory.shotgunnum"):getValue() 


    local damagemutiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.ATY_damage"):getValue()  or 1

    -- print(damagemutiplier)
    -- _damage = tablez[6]/4 * damagemutiplier
    -- tablez[6] = 
    tablez[6] = tablez[6]*damagemutiplier

    local damageer = tablez[6]

    -- print(tablez[5])
    if tablez[9]== "Shotgun" then

        -- tablez[12] = tablez[12]*1.5
        --    if getPlayer():getPerkLevel(Perks.Aiming)


        local aimtable = {}
        
        -- aimtable[0] = bulletnumber
        -- aimtable[1] = bulletnumber
        -- aimtable[2] = bulletnumber+1
        -- aimtable[3] = bulletnumber+1
        -- aimtable[4] = bulletnumber+1
        -- aimtable[5] = bulletnumber+1
        -- aimtable[6] = bulletnumber+1
        -- aimtable[7] = bulletnumber+1
        -- aimtable[8] = bulletnumber+1
        -- aimtable[9] = bulletnumber+1
        -- aimtable[10] = bulletnumber+1

        for shot =1,bulletnumber do
            local adirc
            local numpi = getSandboxOptions():getOptionByName("Advanced_trajectory.shotgundivision"):getValue() *0.7
            adirc = dirc1 +ZombRandFloat(-math.pi * numpi,math.pi*numpi)

            tablez[3] = {math.cos(adirc),math.sin(adirc)}
            tablez[4] = {tablez[4][1], tablez[4][2], tablez[4][3]}
            tablez[5] = adirc*360/(2*math.pi)
            tablez[20] = {tablez[4][1], tablez[4][2], tablez[4][3]}

            tablez[6] = damageer
            

            if isClient() then
                tablez["nonsfx"] = 1
                sendClientCommand("ATY_shotsfx","true",{tablez,character:getOnlineID()})
            end
            tablez["nonsfx"] = nil
            table.insert(Advanced_trajectory.table,Advanced_trajectory.twotable(tablez))
        end
    else

        -- print(tablez[9])
        if tablez["wallcarmouse"] then
            tablez[7] = Advanced_trajectory.aimtexdistance - 1
        end
        tablez[20] = {offx, offy, tablez[4][3]}
        table.insert(Advanced_trajectory.table,Advanced_trajectory.twotable(tablez))
        if isClient() then
            tablez["nonsfx"] = 1
            sendClientCommand("ATY_shotsfx","true",{tablez,character:getOnlineID()})
        end

        -- print(Advanced_trajectory.aimtexdistance)
        
    end

    Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + ((14 - 0.8*playerlevel)*1.8 + handWeapon:getAimingTime()*0.3) * getSandboxOptions():getOptionByName("Advanced_trajectory.fireoffset"):getValue()

    
end

Events.OnWeaponSwingHitPoint.Add(Advanced_trajectory.OnWeaponSwing)

