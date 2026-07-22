// trackball_25mm_receiver_v6.scad
//
// Description:
// Custom 25mm trackball receiver for PMW3610 breakout sensor board.
//
// Bounding box requirements:
// - Pedestal width (X): 36.5 mm
// - Pedestal depth (Y): 30.0 mm
// - Pedestal corner fillets: 0.5 mm
// - Sensor board cavity: fits 32.5 mm (W) x 23.8 mm (D) PCB
// - Optical distance (reference plane to ball surface): 2.4 mm
// - Wire exit: > 14.6 mm width, flat base (no bottom lip)
// - Supports: 1.5 mm diameter zirconia/ceramic balls
// - No small recesses in the sensor cavity ceiling (completely flat)

$fn = 100;

// Dimensions of the pedestal
pedestal_w = 36.5; // X width
pedestal_d = 30.0; // Y depth
pedestal_fillet_r = 0.5;
pedestal_h = 6.7;  // matching PCB-to-lens-top height

// Bounding box total height
total_h = 14.0;

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
cavity_h = pedestal_h; // 6.7mm

// Lens reference plane (flange) to ball surface
optical_dist = 2.4; 

// Ball center Z coordinate
// Lens top reference is at Z = cavity_h = 6.7
// Ball bottom surface must be at Z = cavity_h + optical_dist = 6.7 + 2.4 = 9.1
// Ball center Z is at Z_ball_center = 9.1 + ball_r = 21.6
ball_center_z = cavity_h + optical_dist + ball_r; // 6.7 + 2.4 + 12.5 = 21.6

// Optical window (center hole)
optical_window_d = 8.5;

// Jumper wire exit opening
wire_exit_w = 16.5; // slightly wider than 14.6mm
wire_exit_d = 10.0; // cutting from cavity out to Y = -15

// Support balls (1.5mm zirconia/ceramic balls, 3-point support)
support_d = 1.5;
support_r = support_d / 2.0;
support_pocket_r = support_r + 0.1; // 0.1mm clearance for loose fit
contact_angle = 40; // 40 degrees from vertical

// Distance from ball center to support ball centers
support_dist_to_center = ball_r + support_r; // 12.5 + 0.75 = 13.25
support_xy_r = support_dist_to_center * sin(contact_angle);
support_z = ball_center_z - support_dist_to_center * cos(contact_angle);

module rounded_box(w, d, h, r) {
    w2 = w / 2;
    d2 = d / 2;
    hull() {
        translate([-w2 + r, -d2 + r, 0]) cylinder(r = r, h = h, $fn = 32);
        translate([ w2 - r, -d2 + r, 0]) cylinder(r = r, h = h, $fn = 32);
        translate([-w2 + r,  d2 - r, 0]) cylinder(r = r, h = h, $fn = 32);
        translate([ w2 - r,  d2 - r, 0]) cylinder(r = r, h = h, $fn = 32);
    }
}

difference() {
    // 1. Base Pedestal and Cup body
    union() {
        // Pedestal base
        rounded_box(pedestal_w, pedestal_d, pedestal_h, pedestal_fillet_r);
        
        // Cup cylinder
        // Outer diameter 30mm (radius 15mm) fits Y depth perfectly
        translate([0, 0, pedestal_h])
            cylinder(h = total_h - pedestal_h, r = pedestal_d / 2);
    }

    // 2. Sensor board cavity (from bottom)
    // Flat ceiling at Z = cavity_h, no recesses
    translate([-cavity_w / 2, -cavity_d / 2, -0.1])
        cube([cavity_w, cavity_d, cavity_h + 0.1]);

    // 3. Jumper wire exit (flat base, no bottom lip)
    translate([0, -pedestal_d / 2 + wire_exit_d / 2 - 0.1, cavity_h / 2])
        cube([wire_exit_w, wire_exit_d + 0.2, cavity_h + 0.2], center = true);

    // 4. Trackball cup bowl (inner sphere)
    translate([0, 0, ball_center_z])
        sphere(r = bowl_r);

    // 5. Optical window (center hole through ceiling)
    translate([0, 0, -0.5])
        cylinder(h = total_h + 1.0, r = optical_window_d / 2);

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
