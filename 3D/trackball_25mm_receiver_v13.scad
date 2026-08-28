// trackball_25mm_receiver_v13.scad
//
// Description:
// Custom 25mm trackball receiver for PMW3610 breakout sensor board (Version 13).
//
// Updates in v13:
// - Slide-in design: open at Y-minus front so the sensor board slides in and stops at the back Y-plus wall.
// - Left and right bottom edges feature 1.5mm wide, 1.0mm high shelves to support the PCB.
// - Raised cavity_h to 7.7mm and ball_center_z to 22.6mm to preserve the exact 2.4mm optical pitch distance.
// - Keeps the 0.5 mm bottom outer fillet, 1.0 mm lens hole fillet, and 55-degree support ball contact angle (Z=15.00 mm).

$fn = 100;

// Dimensions of the pedestal
pedestal_w = 36.5; // X width
pedestal_d = 30.0; // Y depth
pedestal_fillet_r = 0.5; // Vertical corner fillet radius
pedestal_bottom_fillet_r = 0.5; // Bottom edge fillet radius

// Pedestal height set to 8.8 mm (thicker upwards to reinforce the top plate while leaving 0.2 mm clearance)
pedestal_h = 8.8;

// Bounding box total height set to exactly 17.0 mm (same as v12)
total_h = 17.0;

// Ball and cup dimensions
ball_d = 25.0;
ball_r = ball_d / 2.0;
bowl_clearance = 0.35;
bowl_r = ball_r + bowl_clearance;

// Sensor PCB and lens dimensions
pcb_w = 32.5;
pcb_d = 23.8;
pcb_clearance = 0.3; // 0.3mm tolerance
cavity_w = pcb_w + pcb_clearance;
cavity_d = pcb_d + pcb_clearance;
cavity_h = 6.7; // Reverted to v12 ceiling height (sensor sits between Z=1.0 and Z=6.7)

// Lens reference plane (flange) to ball surface
optical_dist = 2.4; 

// Ball center Z coordinate (remains at Z=21.6 to keep the 2.4mm optical distance)
ball_center_z = cavity_h + optical_dist + ball_r; // 6.7 + 2.4 + 12.5 = 21.6

// Optical window (center hole)
optical_window_d = 8.5;
optical_window_r = optical_window_d / 2.0; // 4.25 mm

// Support balls (1.5mm zirconia/ceramic balls, 3-point support)
support_d = 1.5;
support_r = support_d / 2.0;
support_pocket_r = support_r + 0.1; // 0.1mm clearance for loose fit

// Contact angle increased to 55 degrees for physical limit of lateral stability
contact_angle = 55; 

// Distance from ball center to support ball centers
support_dist_to_center = ball_r + support_r; // 13.25
support_xy_r = support_dist_to_center * sin(contact_angle);
support_z = ball_center_z - support_dist_to_center * cos(contact_angle);

// Torus module for filleting
module torus(r_major, r_minor) {
    rotate_extrude($fn = 100)
    translate([r_major, 0, 0])
    circle(r = r_minor, $fn = 100);
}

// Rounded box with fillet on the bottom outer edge
module rounded_box_fillet_bottom(w, d, h, corner_r, bottom_r) {
    w2 = w / 2;
    d2 = d / 2;
    hull() {
        // Top part: vertical cylinders from Z = bottom_r to Z = h
        translate([-w2 + corner_r, -d2 + corner_r, bottom_r]) 
            cylinder(r = corner_r, h = h - bottom_r, $fn = 32);
        translate([ w2 - corner_r, -d2 + corner_r, bottom_r]) 
            cylinder(r = corner_r, h = h - bottom_r, $fn = 32);
        translate([-w2 + corner_r,  d2 - corner_r, bottom_r]) 
            cylinder(r = corner_r, h = h - bottom_r, $fn = 32);
        translate([ w2 - corner_r,  d2 - corner_r, bottom_r]) 
            cylinder(r = corner_r, h = h - bottom_r, $fn = 32);
            
        // Bottom part: spheres at Z = bottom_r
        translate([-w2 + corner_r, -d2 + corner_r, bottom_r]) 
            sphere(r = bottom_r, $fn = 32);
        translate([ w2 - corner_r, -d2 + corner_r, bottom_r]) 
            sphere(r = bottom_r, $fn = 32);
        translate([-w2 + corner_r,  d2 - corner_r, bottom_r]) 
            sphere(r = bottom_r, $fn = 32);
        translate([ w2 - corner_r,  d2 - corner_r, bottom_r]) 
            sphere(r = bottom_r, $fn = 32);
    }
}

difference() {
    // 1. Base Pedestal and Cup body
    union() {
        // Pedestal base with rounded bottom edge
        rounded_box_fillet_bottom(pedestal_w, pedestal_d, pedestal_h, pedestal_fillet_r, pedestal_bottom_fillet_r);
        
        // Cup cylinder
        translate([0, 0, pedestal_h])
            cylinder(h = total_h - pedestal_h, r = pedestal_d / 2);
    }

    // 2. Slide-in sensor board cavity (open at Y-minus front, with 1.5mm wide shelves at Z=0..1.0)
    // 2a. Center bottom channel (between shelves): width = cavity_w - 3.0, height = 1.0 (from Z=-0.1 to Z=1.0)
    translate([-(cavity_w - 3.0) / 2, -pedestal_d / 2 - 0.1, -0.1])
        cube([cavity_w - 3.0, pedestal_d / 2 + cavity_d / 2 + 0.1, 1.1]);

    // 2b. Main board slot and component cavity: width = cavity_w, height = cavity_h (from Z=1.0 to Z=cavity_h)
    translate([-cavity_w / 2, -pedestal_d / 2 - 0.1, 1.0])
        cube([cavity_w, pedestal_d / 2 + cavity_d / 2 + 0.1, cavity_h - 1.0 + 0.1]);

    // 4. Trackball cup bowl (inner sphere)
    translate([0, 0, ball_center_z])
        sphere(r = bowl_r);

    // 5. Optical window (center hole through ceiling)
    translate([0, 0, -0.5])
        cylinder(h = total_h + 1.0, r = optical_window_r);

    // 5b. 1.0 mm fillet at the bottom of the optical window (Z = 7.7)
    translate([0, 0, cavity_h]) {
        difference() {
            cylinder(h = 1.001, r = optical_window_r + 1.0, $fn = 100);
            translate([0, 0, 1.0])
                torus(optical_window_r + 1.0, 1.0);
            cylinder(h = 1.1, r = optical_window_r, $fn = 100);
        }
    }

    // 6. Three support ball pockets (loose fit)
    for (angle = [30, 150, 270]) {
        translate([
            support_xy_r * cos(angle),
            support_xy_r * sin(angle),
            support_z
        ])
            sphere(r = support_pocket_r);
    }
}
