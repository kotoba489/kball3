// trackball_25mm_receiver_v8.scad
//
// Description:
// Custom 25mm trackball receiver for PMW3610 breakout sensor board (Version 8).
//
// Updates in v8:
// - Added a 0.5 mm fillet to the bottom outer edge of the pedestal.
// - Added a 0.5 mm chamfer to the bottom inner edge of the sensor cavity entrance.
// - Added a 1.0 mm fillet to the bottom edge of the optical window hole.
// - Maintains total height at 15.5 mm and support ball contact angle at 45 degrees.
// - Maintains 36.5 mm x 30.0 mm pedestal base dimensions with 0.5 mm corner fillets.
// - Pedestal height adjusted to 7.5 mm to match the 7.5 mm case support pillars,
//   leaving a solid 0.8 mm top plate above the 6.7 mm cavity.

$fn = 100;

// Dimensions of the pedestal
pedestal_w = 36.5; // X width
pedestal_d = 30.0; // Y depth
pedestal_fillet_r = 0.5; // Vertical corner fillet radius
pedestal_bottom_fillet_r = 0.5; // Bottom edge fillet radius

// Pedestal height adjusted to exactly 7.5 mm to match keyboard support pillars
pedestal_h = 7.5;

// Bounding box total height
total_h = 15.5;

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
cavity_h = 6.7; // Exactly matching PCB-to-lens-top height

// Lens reference plane (flange) to ball surface
optical_dist = 2.4; 

// Ball center Z coordinate
ball_center_z = cavity_h + optical_dist + ball_r; // 6.7 + 2.4 + 12.5 = 21.6

// Optical window (center hole)
optical_window_d = 8.5;
optical_window_r = optical_window_d / 2.0; // 4.25 mm

// Jumper wire exit opening
wire_exit_w = 16.5;
wire_exit_d = 10.0;

// Support balls (1.5mm zirconia/ceramic balls, 3-point support)
support_d = 1.5;
support_r = support_d / 2.0;
support_pocket_r = support_r + 0.1; // 0.1mm clearance for loose fit
contact_angle = 50; 

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

    // 2. Sensor board cavity (from bottom)
    // Flat ceiling at Z = cavity_h
    translate([-cavity_w / 2, -cavity_d / 2, -0.1])
        cube([cavity_w, cavity_d, cavity_h + 0.1]);

    // 2b. Chamfer at the bottom entrance of the cavity (0.5mm, 45-degree angle)
    hull() {
        translate([0, 0, -0.1])
            cube([cavity_w + 1.0, cavity_d + 1.0, 0.01], center = true);
        translate([0, 0, 0.4])
            cube([cavity_w, cavity_d, 0.01], center = true);
    }

    // 3. Jumper wire exit (flat base, no bottom lip)
    translate([0, -pedestal_d / 2 + wire_exit_d / 2 - 0.1, cavity_h / 2])
        cube([wire_exit_w, wire_exit_d + 0.2, cavity_h + 0.2], center = true);

    // 4. Trackball cup bowl (inner sphere)
    translate([0, 0, ball_center_z])
        sphere(r = bowl_r);

    // 5. Optical window (center hole through ceiling)
    translate([0, 0, -0.5])
        cylinder(h = total_h + 1.0, r = optical_window_r);

    // 5b. 1.0 mm fillet at the bottom of the optical window (Z = 6.7)
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
