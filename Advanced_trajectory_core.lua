-- local function OnZombieUpdate(zombie)
-- 	-- Your code here

--     -- print(zombie:getTargetAlpha())

--     -- print(getPlayer():CanSee(zombie))

--     -- print(getCell():getNearestVisibleZombie(0))

--     -- print(zombie:getZ())

--     zombie:setOutlineHighlight(true)
--     zombie:setOutlineHighlightCol(1.0, 1.0, 1.0, 1.0)

-- end

-- Events.OnZombieUpdate.Add(OnZombieUpdate)











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
Advanced_trajectory.aimtexdistance = 0 

Advanced_trajectory.Advanced_trajectory = {}
Advanced_trajectory.damagedisplayer = {}

local zombiecolor = {}








---------------

local function distanceSquared(x1, y1, x2, y2)
    return (x2 - x1)^2 + (y2 - y1)^2
end
local function normalizeVector(vx, vy)
    local length = math.sqrt(vx^2 + vy^2)
    return vx / length, vy / length
end
local function closestPointOnRay(O, d, length, P)
    local ox, oy = O[1], O[2]      -- 射线起点
    local px, py = P[1], P[2]      -- 空间物体点
    local dx, dy = d[1], d[2]      -- 射线方向向量

    -- 步骤 1：归一化射线方向向量，并扩展到指定长度
    local ndx, ndy = normalizeVector(dx, dy)
    local ex, ey = ox + ndx * length, oy + ndy * length  -- 射线终点

    -- 步骤 2：计算 t 参数
    local t = ((px - ox) * ndx + (py - oy) * ndy) / length

    -- 步骤 3：判断 t 的范围，并计算最近点
    if t < 0 then
        -- 最近点为射线起点
        return {ox, oy}, math.sqrt(distanceSquared(ox, oy, px, py))
    elseif t > 1 then
        -- 最近点为射线终点
        return {ex, ey}, math.sqrt(distanceSquared(ex, ey, px, py))
    else
        -- 最近点在线段上
        local closestX = ox + t * ndx * length
        local closestY = oy + t * ndy * length
        return {closestX, closestY}, math.sqrt(distanceSquared(closestX, closestY, px, py))
    end
end




-----------------

local function pointToSegmentDistance(px, py, x1, y1, x2, y2)
    -- 向量法计算
    local dx, dy = x2 - x1, y2 - y1 -- 线段的方向向量
    local lengthSquared = dx * dx + dy * dy -- 线段长度的平方

    if lengthSquared == 0 then
        -- 如果线段退化成一个点，直接计算点到该点的距离
        return math.sqrt((px - x1) ^ 2 + (py - y1) ^ 2)
    end

    -- 投影系数 t
    local t = ((px - x1) * dx + (py - y1) * dy) / lengthSquared

    if t < 0 or t > 1 then
        -- 如果 t 不在 [0,1] 范围内，说明垂足不在线段上
        return nil
    end

    -- 垂足在线段上，计算垂足坐标
    local projectionX = x1 + t * dx
    local projectionY = y1 + t * dy

    -- 计算点到垂足的距离
    local distance = math.sqrt((px - projectionX) ^ 2 + (py - projectionY) ^ 2)
    return distance
end

-----------------------------------



local function isshotgun(weapon) 
    return (string.contains(weapon:getAmmoType() or "","Shotgun") or string.contains(weapon:getAmmoType() or "","shotgun")) 
    
end

function Advanced_trajectory.getshotanimals(weapon,player)


    local dx = getMouseXScaled();
	local dy = getMouseYScaled();
	local z = player:getZ();


	local wx, wy = ISCoordConversion.ToWorld(dx, dy, z);
	wx = math.floor(wx);
	wy = math.floor(wy);

    local sqtable = {}

    for i=-1,1 do
        for k=-1,1 do
            local cell = getWorld():getCell();
	        local sq = cell:getGridSquare(wx+i, wy+k, z);
            if sq then
                table.insert(sqtable,sq) 
            end
        end
    end

    local animalstable = {}

    for i ,v in pairs(sqtable) do
        local anis = v:getAnimals()
        for h=1,anis:size() do
            animalstable[anis:get(h-1)]=true
            -- print(anis:get(h-1))
        end
    end

    return animalstable
end

function Advanced_trajectory.getshotzombies(weapon,player)

    local ballisticdistance = weapon:getMaxRange(player)

    if weapon:getSwingAnim() == "Handgun" then
        ballisticdistance = ballisticdistance*0.85
        
    end





    local isshotgun = isshotgun(weapon)
    if  isshotgun then
        ballisticdistance = ballisticdistance*0.65
    end

    local offx = player:getX()
    local offy = player:getY()
    local offz = player:getZ()

    local dirc = player:getForwardDirection():getDirection()

    local aimrate = Advanced_trajectory.aimnum * math.pi / 250

    dirc =   dirc + ZombRandFloat(-aimrate,aimrate)
    local deltX
    local deltY



    deltX=math.cos(dirc)
    deltY=math.sin(dirc)

    local offx = offx +deltX*0.55
    local offy = offy + deltY*0.55



    local endpoint = {offx+ballisticdistance*deltX,offy+ballisticdistance*deltY}

    local hitcount = ScriptManager.instance:getItem(weapon:getFullType()):getMaxHitCount()
    local bulletnumber = getSandboxOptions():getOptionByName("Advanced_trajectory.shotgunnum"):getValue() 

    local debugzombiecheck = 0





    local zombierank = {}

    

    if isshotgun then
        hitcount = math.floor(hitcount/2)+ bulletnumber
    end


    -- print(hitcount)
    -- if weapon:getFullType() =="Base.Pistol" then
    --     hitcount =1
    -- end

    if hitcount> 0 then

        local zombielist = getCell():getZombieList()

        
        

        for i=1,zombielist:size() do
            local zombiez = zombielist:get(i-1)
            if zombiez:getTargetAlpha() > 0 and zombiez:isAlive()  then



                local levelfix = -(zombiez:getZ() - player:getZ())


                local zombiepos

                if zombiez:isCrawling() then
                    zombiepos = {zombiez:getX()+levelfix*3+2,zombiez:getY()+levelfix*3+2}
                else
                    zombiepos = {zombiez:getX()+levelfix*3,zombiez:getY()+levelfix*3}
                end
                    


                
                -- local behind = isZombieBehindPlayer({offx,offy}, {deltX,deltY}, zombiePos)


                -- print(behind)
                


                local zombiedistance = distanceSquared(offx,offy,zombiepos[1],zombiepos[2])
                if not false then
                    local shortestDistance = pointToSegmentDistance(zombiepos[1], zombiepos[2], offx, offy, endpoint[1], endpoint[2])

                    -- print(shortestDistance)

                    if shortestDistance then
                        if not  isshotgun then

                            
                            if shortestDistance < 2 then
                                -- for k=1 , hitcount do
                                --     -- if zombierank[k] ==nil then
                                --     --     zombierank[k] = {zombiez,shortestDistance}
                                --     --     break
                                --     -- elseif shortestDistance < zombierank[k][2] then
                                --     --     zombierank[k] = {zombiez,shortestDistance}
                                --     --     break
                                --     -- end
                                --     if zombierank[k] ==nil then
                                --         zombierank[k] = {zombiez,zombiedistance,shortestDistance}
                                --         break
                                --     elseif zombiedistance < zombierank[k][2] then
                                --         zombierank[k] = {zombiez,zombiedistance,shortestDistance}
                                --         break
                                --     end
                                -- end


                                local index = 1

                                for ia=1 , #zombierank do

                                    if zombiedistance < zombierank[ia][2] then
                                        index = ia
                                        break
                                    end
                                    index = index + 1

                                end

                                table.insert(zombierank,index,{zombiez,zombiedistance,shortestDistance})







                                

                                
                                
                            end
                        else

                            

                            if shortestDistance < 4.6 then

                                -- debugzombiecheck = debugzombiecheck + 1
                                
                                -- print(zombiedistance)



                                local index = 1

                                for ia=1 , #zombierank do

                                    if zombiedistance < zombierank[ia][2] then
                                        index = ia
                                        break
                                    end
                                    index = index + 1

                                end

                                table.insert(zombierank,index,{zombiez,zombiedistance})

                                -- for o=1 , math.floor(hitcount/2)+ bulletnumber do



                                --     for ia=1 , #zombierank do

                                --         if zombiedistance < zombierank[ia][2] then
                                --             index = ia
                                --             break
                                --         end
                                --         index = index + 1
                                --     end

                
                                --     if zombierank[o] ==nil then
                                --         zombierank[o] = {zombiez,zombiedistance}
                                --         break
                                --     elseif zombiedistance < zombierank[o][2] then
                                --         zombierank[o] = {zombiez,zombiedistance}
                                --         break
                                --     end

                                -- end
                            end
                        end
                    end
                end
            end
            
        end


        
    end







    local ranklistcount = #zombierank


    if ranklistcount > hitcount then

        for i=1,ranklistcount - hitcount do
            table.remove(zombierank,ranklistcount-i+1)
        end
        


    end
    if not isshotgun then
        for jk,jl in pairs(zombierank) do
            zombiecolor[jl[1]] = 1-jl[3]/2
        end
        
    end
    

    -- print(debugzombiecheck)

    return zombierank;

    


end

local timervalue = 10
local timer = timervalue

local color = {1,1,1}

Advanced_trajectory.zombierank = nil

function Advanced_trajectory.OnPlayerUpdate(timemuti)

    local player = getPlayer() 
    if not player then return end
    local weaitem = player:getPrimaryHandItem()
    local sdoption = getSandboxOptions()


    



    if  player:isAiming()  and instanceof(weaitem,"HandWeapon") and weaitem:isRanged() and not (weaitem:getSwingAnim() =="Throw") then

        weaitem:setMaxHitCount(0)


        
        -- local timemuti = getGameTime():getMultiplier()
        timer = timer - timemuti 

        

        if timer <0 then
            Advanced_trajectory.zombierank = Advanced_trajectory.getshotzombies(weaitem,player)

            

            local animals = Advanced_trajectory.getshotanimals(weaitem,player)

            for i,v in pairs(animals) do

                table.insert(Advanced_trajectory.zombierank,{i,0})
            end

            timer = timervalue
        end
    
        if Advanced_trajectory.zombierank then
            for i,v in pairs(Advanced_trajectory.zombierank) do
                local zombie = v[1] 
                if instanceof(zombie,"IsoZombie") then
                    zombie:setOutlineHighlight(true)

                    local iszombiespcolor = zombiecolor[zombie]

                    -- print(iszombiespcolor)

                    

                    if iszombiespcolor then
                        zombie:setOutlineHighlightCol((1-iszombiespcolor)*0.5, iszombiespcolor, 0, 0.8)
                        
                    else
                        zombie:setOutlineHighlightCol(color[1], color[2], color[3], 0.8)
                    end
                    
                end
                
            end
        end
        


        

      
        local level = 11-player:getPerkLevel(Perks.Aiming)

        local gametimemul = getGameTime():getMultiplier() * 16/(level+10)
        local maxaimnum = weaitem:getAimingTime() + level*7 + sdoption:getOptionByName("Advanced_trajectory.maxaimnum"):getValue() 
   


        

        if Advanced_trajectory.aimnum > maxaimnum then
            Advanced_trajectory.aimnum = maxaimnum
        end

        
        
        if player:getVariableBoolean("isMoving") then
            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum +gametimemul*sdoption:getOptionByName("Advanced_trajectory.moveeffect"):getValue() 
        end
        

        if player:getVariableBoolean("isTurning") then
            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum +gametimemul*sdoption:getOptionByName("Advanced_trajectory.turningeffect"):getValue() 
        end

        if Advanced_trajectory.aimnum > 0  then
            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum -gametimemul*sdoption:getOptionByName("Advanced_trajectory.reducespeed"):getValue() 
            -- print(gametimemul)
        end

        if Advanced_trajectory.aimnum < 0  then
            Advanced_trajectory.aimnum = 0
        end

        Advanced_trajectory.accuracy =1-Advanced_trajectory.aimnum/maxaimnum
        local acc = Advanced_trajectory.accuracy
        color = {(1*(1-acc)),acc,0}

        if not Advanced_trajectory.panel.instance and  sdoption:getOptionByName("Advanced_trajectory.aimpoint"):getValue()  then

            
            Advanced_trajectory.panel.instance = Advanced_trajectory.panel:new(0,0,200,200)
            Advanced_trajectory.panel.instance:initialise()
            Advanced_trajectory.panel.instance:addToUIManager() 
        end

        if Advanced_trajectory.panel.instance then
            Advanced_trajectory.panel.instance:setVisible(true)
        end
        
    else 
    
        if Advanced_trajectory.panel.instance then
            Advanced_trajectory.panel.instance:setVisible(false)
            -- Advanced_trajectory.panel.instance=nil
        end
        Advanced_trajectory.aimnum = 100
        Advanced_trajectory.accuracy= 0
        timer = timervalue
        Advanced_trajectory.zombierank = nil
        color = {0.5,0,0.5}
        

    end
end



function Advanced_trajectory.checkontick()

    local timemultiplier = getGameTime():getMultiplier()
    Advanced_trajectory.OnPlayerUpdate(timemultiplier)


    for la,lb in pairs(Advanced_trajectory.damagedisplayer) do

        lb[1] = lb[1] - timemultiplier
        if lb[1] < 0 then
            lb = nil
        else

            lb[3] = lb[3] + timemultiplier
            lb[4] = lb[4] - timemultiplier
            lb[2]:AddBatchedDraw(lb[3], lb[4], true)
        end
    end

end


Events.OnTick.Add(Advanced_trajectory.checkontick)


function Advanced_trajectory.OnWeaponSwing(character, handWeapon)
    if instanceof(handWeapon,"HandWeapon") and handWeapon:isRanged() and not (handWeapon:getSwingAnim() =="Throw") and Advanced_trajectory.zombierank then

        local playerlevel = character:getPerkLevel(Perks.Aiming)

        for i,v in pairs(Advanced_trajectory.zombierank) do
            
            local zombie = v[1] 
            if (instanceof(zombie,"IsoZombie") and zombie:isAlive() ) or instanceof(zombie,"IsoAnimal") then

                -- print(zombie)



                local damage = handWeapon:getMinDamage() + ZombRandFloat(0.1,1.3)*(0.5+handWeapon:getMaxDamage()-handWeapon:getMinDamage())
                local acc = Advanced_trajectory.accuracy * 0.1

                -- print(v[2])

                
    
    
                if v[3]  then

                    
                    acc = acc* (1-v[3]/2)* 10
                end

                
    
                if isshotgun(handWeapon) then
                    -- acc = acc*8

                    local a = 50 - v[2]
                    if a< 0 then a = 0 end

                    acc = acc * (1 + a/50)*5


                    
                end

                -- print(v[2])
    
                
    
    
                damage = damage *acc*(getSandboxOptions():getOptionByName("Advanced_trajectory.ATY_damage"):getValue()  or 1)*(1+playerlevel*0.2)
                zombie:pathToCharacter(character)
                zombie:setHitReaction("ShotChest");
                zombie:addBlood(getSandboxOptions():getOptionByName("AT_Blood"):getValue())
                triggerEvent("OnWeaponHitCharacter", character, zombie,handWeapon, damage)
    
    
                if getSandboxOptions():getOptionByName("ATY_damagedisplay"):getValue() then
                    local damagea = TextDrawObject.new()
                    damagea:setDefaultColors(1,1,0.1,0.7)
                    damagea:setOutlineColors(0,0,0,1)
                    damagea:ReadString(UIFont.Middle, "-" ..tostring(math.floor(damage*100)), -1)
                    local sx = IsoUtils.XToScreen(zombie:getX(), zombie:getY(), zombie:getZ(), 0);
                    local sy = IsoUtils.YToScreen(zombie:getX(), zombie:getY(), zombie:getZ(), 0);
                    sx = sx - IsoCamera.getOffX() - zombie:getOffsetX();
                    sy = sy - IsoCamera.getOffY() - zombie:getOffsetY();
                    sy = sy - 64
                    sx = sx / getCore():getZoom(0)
                    sy = sy / getCore():getZoom(0)
                    sy = sy - damagea:getHeight()
    
    
                    table.insert(Advanced_trajectory.damagedisplayer,{60,damagea,sx,sy,sx,sy})
                    
                end
    
    
    
    
    
                zombie:setHealth(zombie:getHealth()-zombie:getHealth()*0.17)

                zombie:setHealth(zombie:getHealth()-damage)


                if zombie:getHealth()<=0.1 then 

                    zombie:Kill(character)
                    
                    character:setZombieKills(character:getZombieKills()+1)
                    character:setLastHitCount(1)
                    character:getXp():AddXP(Perks.Aiming, 1);
    
    
                end
                
            end
            
        end

        if isshotgun(handWeapon) then
            Advanced_trajectory.aimnum =Advanced_trajectory.aimnum + 12
            
        end

        Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + ((14 - 0.8*playerlevel)*1.8 + handWeapon:getAimingTime()*0.3) * getSandboxOptions():getOptionByName("Advanced_trajectory.fireoffset"):getValue()
        


    end




end

Events.OnWeaponSwingHitPoint.Add(Advanced_trajectory.OnWeaponSwing)