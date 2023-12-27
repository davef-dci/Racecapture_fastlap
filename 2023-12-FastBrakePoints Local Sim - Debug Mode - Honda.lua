-- GPS Braking Aid
-- Dave Franchino - dave.franchino@gmail.com - 608.334.5788
-- Designed to count down the distance to the point at which the driver pressed the brakes on their fastest previous lap to aid in braking 
-- This is displayed on a Shift3X unit
-- V10.0 10/5/2023 - modified to reduce marker warning from 9-0 to 4-0 
-- V12 10/9 - modified to clamp the track marker between 4 and 0 to prevent briefly displaying a 5 at corners.
-- V15 implemented revised brake based on testing at Kallsen 
-- V16 Prep for Road America - V15 fixed issue with garbage collection 

setTickRate(10) -- set the refresh rate at 10hz.
sxSetConfig(0,0,1)  -- ShiftX3 Config - normal orientation, 100% brightness, CAN 2

--Setup up virtual channels 
d_corner = addChannel("CORNER_DIST",10) -- this channel outputs distance as virtual channel - not used by program but monitored in race capture 
addChannel("BRAKES",10) -- channel for brake pressure 

-- Initialzing Variables
new_lap = 0 -- variable that keeps track of the lap number. increments when we pass start/finish 
current_lap = 0 -- Self Explaintory really now isn't it
delta = 0 -- variable used to hold the distance between the current position and the corner lat/lon
target_corner = 1    -- what is our next corner we are driving for
best_lap_time = 600 -- need to figure out what to set this to?  decimal minutes/seconds?
distance_to_target_corner = 2000 -- variable to hold the distance we are from the upcoming target corner (not the braking point)
distance_to_fastest_brake_point = 2000 -- a variable to hold how far we are from the brake point on our fastest lap
num_corners = 3 -- how many corners we are going to have for this track
track_marker = 4 -- variable uses to store the track marker number to be displayed on the ShiftX3.  Will step from 3 to 1 depending on how far away you are
track_marker_quarters = 0  -- a variable used to control the discrete LED displaces. The display indicated "quarter" markers (four indications every marker) 
prev_distances = {} -- stores previous 5 distances from GPS to compensate for GPS jitters 
for i = 1, 3 do
    table.insert(prev_distances, 0) -- initialize 
end

-- Initializing flags
at_corner = false --  flag variable - self explainitory
brake_zone_distance = 300 -- The distance from the corner where we will be looking for braking. 
in_brake_zone = false -- used to determine if we are in the braking zone.
brake_detected = false -- used to determine if the brakes have been pushed.
passed_brake_point = false

-- set up arrays to hold the GPS coordinates for the corner, the current lap's brake points (lat and lon) and the brake points for fastest lap
corner_lat = {}
corner_lon = {}

brake_point_current_lap_lat={}
brake_point_current_lap_lon={}

brake_point_fastest_lap_lat={}
brake_point_fastest_lap_lon={}

brake_recorded = {} -- used to determine if the lat and lon have been recorded.

for i = 1, num_corners , 1  do
   brake_recorded[i]= false-- used to determine if the lat and lon have been recorded.
   brake_point_fastest_lap_lat[i]=0
   brake_point_fastest_lap_lon[i]=0
   brake_point_current_lap_lat[i]=0
   brake_point_current_lap_lon[i]=0
end

-- These are GPS Coords for software "simulated" track used only for debug.  These are around my house.

corner_lat[1]= 43.046943
corner_lon[1]=-89.447696

corner_lat[2]= 43.042599
corner_lon[2]=-89.447685

corner_lat[3]=  43.044876
corner_lon[3]=-89.444664

--[[
--  GPS Coordinates for the apexs at Road America

-- GPS Coordinates for road america 
--1 - Corner 1
corner_lat[1] = 43.792079	
corner_lon[1] = -87.989737

--Corner 3
--corner_lat[2] =  43.791517
--corner_lon[2] = -87.995286

--3 - Corner 5
corner_lat[2] = 43.80177	
corner_lon[2] = -87.992557


--Corner 6
--corner_lat[4] = 43.801674	
--corner_lon[4] = -87.9961

--Corner 8
--corner_lat[5] = 43.797134	
--corner_lon[5] = -88.000014

--Corner 11
--corner_lat[6] =  43.797037	
--corner_lon[6] = -88.002548

--6 Corner12
corner_lat[3] = 43.80494
corner_lon[3] =-87.997522

--7 Corner 14
--corner_lat[8] = 43.804053
--corner_lon[8] =-87.990036
--]]

function check_if_at_corner()--determines what corner we are driving towards
   for i = 1, num_corners, 1 do 
      delta = distance(corner_lat[i], corner_lon[i], current_lat, current_lon)  -- how far are we from the corner?  
      --if delta < at_corner_tolerance and not at_corner then  (commented out to save memory and replaced with a number)  
      if delta < 60 and not at_corner then  -- within tolerance and at_corner flag is not set 
         target_corner = i + 1 -- increment to the next corner 
         at_corner = true  -- set the flag 
         passed_brake_point = false  -- reset the passed brake point flag so we're ready for the next corner 
         break
      end
      if i == target_corner then  -- if at "target corner" then set the distance to target corner.    
         distance_to_target_corner = delta
         setChannel(d_corner, delta)
      end
      --if delta >= at_corner_tolerance then (commented out to save memory and replace with a number)
      if delta >= 60 then -- if our current distance is greater than 60 feet then we are not at a corner yet.  
         at_corner = false
      end
   end
   -- Check and wrap target_corner after the loop
   if target_corner > num_corners then
      target_corner = 1
   end
end

function update_brake_point() --updates braking points if conditions are met 
    in_brake_zone = distance_to_target_corner <= brake_zone_distance 
      --in_brake_zone = distance_to_target_corner <= 1000
      
    if in_brake_zone then
    sxSetLed(8,1,0,255,0,0)
  else
    sxSetLed(8,1,0,0,0,0)
  end
    
    End

   if in_brake_zone and brake_detected and not brake_recorded[target_corner] then
      brake_point_current_lap_lat[target_corner] = current_lat
      brake_point_current_lap_lon[target_corner] = current_lon
      brake_recorded[target_corner] = true -- set flag so we don't record multiple brake points - only the first one within the zone 
   end
end

function update_display() -- initiates the ShiftX display based on distance to brake point for the upcoming corner for the fastest lap
  local brake_warn = 300  -- this is how far away from tbe brake point we'll begin counting down.  Set to smaller number for local testing around my house 
   -- compute the distance between our current location and the location where the brakes were pressed on the fastest lap (for the current corner) 
   distance_to_fastest_brake_point = distance(brake_point_fastest_lap_lat[target_corner], brake_point_fastest_lap_lon[target_corner], current_lat, current_lon)

   table.insert(prev_distances, distance_to_fastest_brake_point) -- save the last points - add new value to the end
   table.remove(prev_distances, 1) -- remove the oldest value from the start

   passed_brake_point = false  -- initialize the flag variable that tracks if we've passed the brake point
   
   if distance_to_fastest_brake_point >= prev_distances[1] then   --Further away than the previous distance - moving AWAY from the fastest brake point 
      passed_brake_point = true
   end

  if distance_to_fastest_brake_point > brake_warn then
    track_marker = 0
    led_off() -- is this working correctly?  Need to verify. Not sure how I want the LEDs to behave  
  end
  
-- set the distance to the brake point... 
   if not passed_brake_point and distance_to_fastest_brake_point < brake_warn then
      track_marker = math.ceil(distance_to_fastest_brake_point/brake_warn*4)  -- determine which track marker number to display. 
      track_marker_quarters = (distance_to_fastest_brake_point / brake_warn *4) - (track_marker - 1) -- determing which "quarter" to display - Lower LEDs
    else
        track_marker = 0  -- if we have passed the brake point or we are too far away then... 
        led_all_blue()
    end
   
     if track_marker > 0 and track_marker < 4 then -- count down from 3 to 1  
        sxSetDisplay(0, track_marker)
        -- turn on the lower LEDs  
        if track_marker_quarters < .25 then
            led_state4()
        elseif track_marker_quarters <= .5 then 
            led_state3()
        elseif track_marker_quarters <= .75 then 
            led_state2()
        else 
            led_state1()
        end
      else 
          sxSetDisplay(0, "")
      end
end

-- Lower LED states
--* = on
--o = off
function led_state1()  -- *********** (all on)  
 local r, g, b = getColorBasedOnTrackMarker(track_marker)
 sxSetLed(0,7,r,g,b,0)
end

function led_state2() -- o****o
  local r, g, b = getColorBasedOnTrackMarker(track_marker)
  sxSetLed(0,1,0,0,0,0)
  sxSetLed(1,5,r,g,b,0)
  sxSetLed(6,1,0,0,0,0)
end

function led_state3() --oo***oo
  local r, g, b = getColorBasedOnTrackMarker(track_marker)
  sxSetLed(0,2,0,0,0,0)
  sxSetLed(2,3,r,g,b,0)
  sxSetLed(5,2,0,0,0,0)
end

function led_state4() --ooo*ooo
  local r, g, b = getColorBasedOnTrackMarker(track_marker)
  sxSetLed(0,3,0,0,0,0)
  sxSetLed(3,1,r,g,b,0)
  sxSetLed(4,3,0,0,0,0)
end

function led_off()
  sxSetLed(0,7,0,0,0,0)
end

function led_all_blue()
  sxSetLed(0,7,0,0,255,0)
  end




function getColorBasedOnTrackMarker(marker)  -- the lower LEDs change color between green and yellow depending on how close we are
    if marker == 1 then
        return 255, 255, 0  -- Yellow for track_marker 1
    elseif marker >= 2 and marker <= 4 then
        return 0, 255, 0  -- Green for track_marker 2 to 4
    else
        return 0, 0, 0  -- Turn off LEDs for any other value
    end
end


function distance(lat1,lon1,lat2,lon2) -- math funtion determines the distances between two GPS points using the Haversine formula - not perfect but close enough.
   result = (math.sqrt(((math.rad(lon2)-math.rad(lon1))*math.cos((math.rad(lat1)+math.rad(lat2))/2))^2 + (math.rad(lat2) - math.rad(lat1))^2))*6371e3*3.28084  -- note the 3.28 converst from meters to feet.
   return result
end

function check_brakes() -- this function determines if the brakes have currently been pressed.
 
 -- Use this section for the "simulation" (push button switch into GPIO that simulates brakes)  
 
 brakepressure = getGpio(0) or 0  -- look for a button press (simulates pressing the brake)  
  brake_detected = brakepressure >= 1  -- Simulated value after button press
  if brake_detected then
    sxSetLed(7,1,255,0,0,0)
  else
    sxSetLed(7,1,0,0,0,0)
  end

--[[
  -- Use this section for racing at the track  
  brake_pressure = getChannel("BRAKES") -- comment out for simulation
  brake_detected = brake_pressure > 1100  -- measured value of actual brake pressure during testing  
--]]

end

function check_if_passed_start() -- monitor the lap count to see if we passed start. If so, check for fastest lap and update if so
    new_lap = getLapCount()
    if new_lap > current_lap then 
        -- Reset the brake recorded flags for each corner
        for i = 1, num_corners, 1 do
            brake_recorded[i] = false
        end
        -- Check if the current lap time is our fastest lap
        if getLapTime() < best_lap_time then
            best_lap_time = getLapTime()
            -- Copy brake points from current lap to fastest lap
            for i = 1, num_corners, 1 do
                brake_point_fastest_lap_lat[i] = brake_point_current_lap_lat[i]
                brake_point_fastest_lap_lon[i] = brake_point_current_lap_lon[i]
                --println('fl = '..tostring(new_lap)..' # '.. tostring(i)..' Lat '..tostring(brake_point_fastest_lap_lat[i])..' Lon '..tostring(brake_point_fastest_lap_lon[i]))
            end
        end
        current_lap = new_lap -- Update the current lap count

        -- Re-zero lat and lon brake points for the current lap
        for i = 1, num_corners, 1 do
            brake_point_current_lap_lat[i] = 0
            brake_point_current_lap_lon[i] = 0
        end
    end
end

function onTick() -- main loop 
  current_lat, current_lon = getGpsPos() -- get the current GPS positon in terms of Lat and Lon
  check_if_passed_start() -- Determines if we are at the start/finish line, check for fastest lap and update brake points if so.  
  check_if_at_corner() -- Determines if we have passed a corner which sets the next target corner
  check_brakes() -- Checks to see the the brakes have been pressed
  update_brake_point() -- If the proper conditions are met this routine will record when brakes are pushed 
  update_display() -- update_display
  collectgarbage() -- Collect garbage to mimize LUA overhead and open up memory space

--debugging printlns.  can be commented out to save space for operation and provide space for more points 
  println(" ")
  println("Current Lap #"..tostring(current_lap).."  Corner= " ..target_corner.. " Brakes " .. tostring(brake_detected).." In Zone? " ..tostring(in_brake_zone) .. " BP Dist =  "..tostring(distance_to_fastest_brake_point))
  println("CURRENT lap brake point lats and lons ...")
  for j = 1, num_corners , 1  do
    println("brake point current Lap corner lat = " .. brake_point_current_lap_lat[j] .. ", brake point current Lap  corner lon = " .. brake_point_current_lap_lon[j])
  end
  println("Fastest lap brake point lats and lons ...")
  for m = 1, num_corners , 1  do
   println("bp fast Lap corner lat / lon = " .. brake_point_fastest_lap_lat[m] .."  ".. brake_point_fastest_lap_lon[m])
  end

  --[[
  if getGpsSpeed() > 10 then
    startLogging()
  else
    stopLogging()
  end
  --]]
end
