# GPS Braking Aid 


**Author:** Dave Franchino
**Email:** dave.franchino@gmail.com
**Contact:** 608.334.5788


## Overview
The GPS Braking Aid is designed to help drivers find the optimal braking points during a race.  


The program records the GPS location where the driver hits the brakes during each lap. The program then uses a Shift3X to “count down” to the location where the driver pressed the brakes on their fastest lap. The brake point locations are updated every time the driver turns their fastest lap of the session.  This aids the driver in understanding when to brake during a race. 


## Version History
- **V10.0** (10/5/2023): Reduced marker warning from 9-0 to 4-0.
- **V12** (10/9): Clamped the track marker between 4 and 0 to prevent briefly displaying a 5 at corners.
- **V15**: Implemented revised brake based on testing at Kallsen.
- **V16**: Preparation for Road America. V15 fixed an issue with garbage collection.


## Code Features
- Refresh rate is set at 10Hz.
- Configuration is set for ShiftX3 with normal orientation, 100% brightness, and CAN 2.
- Virtual channels have been set up for tracking corner distances and brake pressures.
- Various variables are initialized for tracking lap details, distances, braking points, and more.
- Flags for indicating the state of the vehicle in relation to corners and braking zones.
- Arrays to store GPS coordinates for the corner, the current lap's brake points, and the brake points for the fastest lap.
- Functions to determine the proximity to corners, update braking points, and handle the LED display based on the distance to the brake point for the upcoming corner.
- Lower LED states indicate the distance to the upcoming corner.
- Function to calculate distance between two GPS points using the Haversine formula.
- Function to check if brakes have been pressed.
- Function to monitor if the start line has been passed and subsequently check for the fastest lap.


## Note
The code provides simulated GPS coordinates for testing purposes around the author's house. It also contains actual GPS coordinates for Road America but they are commented out. Adjustments can be made to switch between simulated and actual race track conditions.


## Usage
To use this script, integrate it into the software platform compatible with your racing hardware. Ensure that the necessary hardware and configurations are in place for effective tracking and display on the Shift3X unit.