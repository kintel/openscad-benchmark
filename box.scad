// Parametric divided storage box OpenSCAD source.
// Project Home: https://hackaday.io/project/164516/
// Author: https://hackaday.io/daren
//
// Creative Commons License exists for this work. You may copy and alter the content
// of this file for private use only, and distribute it only with the associated
// Parametric divided storage box content. This license must be included with
// the file and content.
// For a copy of the current license, please visit http://creativecommons.org/licenses/by/2.0/



cols=[7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2]; // col widths
rows=[8.5,8.5,8.5,8.5,8.5]; // row widths
pin_d=1; // hinge pin diameter
lid_h=6; // lid height
box_h=8.5; // box height
hinge_clearance=0.2; // clearance for hinge rotation
walls=[1.2,1.6,0.3,0.4]; // inner,outer,top,bottom
hinge_d=pin_d+2.4;

$fn=30;
extra=0.01;
w=array_sum(cols);
l=array_sum(rows);
total_w=w-walls[0]+walls[1]*2;
total_l=l-walls[0]+walls[1]*2;

//assembly(offset=4);
minkowski() {
box();
//lid();
sphere(1, $fn=100);
}

module assembly(offset=0) {
	box();
	translate([0,l+walls[1]*2-hinge_clearance+offset,box_h-lid_h]) lid();
}
	
module box() {
	difference() {
		union() {
			translate([0,0,box_h/2]) cube([total_w,total_l,box_h],center=true);
			translate([0,(total_l+hinge_d/4+hinge_clearance)/2,box_h]) hull() {
				rotate([0,90,0]) cylinder(r=hinge_d/2,h=total_w,center=true);
				translate([0,-hinge_d/4,-hinge_d*.85]) cube([total_w,extra,extra],center=true);
			}
			hull() for(i=[-1,1]) translate([i*w/6,-total_l/2,box_h/8]) scale([1,0.75,1])  sphere(r=box_h/8,center=true);
		}
		translate([-w/2,(total_l+hinge_d/4+hinge_clearance)/2,box_h]) build_box_hinge();
		translate([0,-(total_l+walls[1])/2,box_h]) for(i=[-1,1]) translate([i*w/6,1,-box_h/4-hinge_clearance]) scale([1,0.95,1.5])  sphere(r=box_h/8,center=true);
		translate([-w/2,-l/2,box_h/2+walls[3]]) build_rows(0,0,walls[0]*2);
		translate([0,(total_l+hinge_d/4+hinge_clearance)/2,box_h]) rotate([0,90,0]) cylinder(r=pin_d/2,h=total_w+extra,center=true);
	}
}

module lid() {
	difference() {
		union() {
			translate([0,0,(lid_h-hinge_clearance)/2]) cube([total_w,total_l,lid_h-hinge_clearance],center=true);
			translate([0,(total_l+walls[1]+hinge_clearance/2)/2,lid_h]) hull() {
				for(i=[-1,1]) translate([i*w/6,-walls[1]/4,box_h/4]) rotate([90,0,0]) cylinder(r=hinge_d/2,h=walls[1]/2,center=true);
				translate([0,-walls[1]/2-hinge_clearance/4,-lid_h]) cube([w/2+walls[1]+pin_d,extra,extra],center=true);
				translate([0,0,-lid_h/2]) cube([w/2+walls[1]+pin_d,walls[1],extra],center=true);
			} 
			hull() for(i=[-1,1]) translate([i*w/6,total_l/2+walls[1]*.75,lid_h]) {
				scale([1,0.75,1.5])  sphere(r=box_h/8,center=true);
				translate([0,-walls[1]/2,-hinge_clearance-box_h/8]) cube([box_h/4,walls[1]/2,box_h/4],center=true);
			}
			translate([0,(total_l+walls[1])/2,lid_h]) for(i=[-1,1]) translate([i*w/6,-box_h/15,box_h/4]) scale([1,0.75,1.25]) sphere(r=box_h/8,center=true);
			translate([0,-(total_l+hinge_d/4+hinge_clearance)/2,lid_h]) hull() {
				rotate([0,90,0]) cylinder(r=hinge_d/2,h=total_w,center=true);
				translate([0,hinge_d/4,-hinge_d*.85]) cube([total_w,extra,extra],center=true);
			}
		}
		difference() {
			translate([0,0,lid_h/2+walls[2]/2]) cube([total_w-walls[1]*2,total_l-walls[1]*2,lid_h-walls[2]],center=true);
			translate([0,-(total_l+hinge_d/4+hinge_clearance)/2,lid_h]) hull() {
				rotate([0,90,0]) cylinder(r=hinge_d/2,h=total_w,center=true);
				translate([0,hinge_d/4,-hinge_d*.85]) cube([total_w,extra,extra],center=true);
			}
		}
		translate([0,-(total_l+hinge_d/4+hinge_clearance)/2,lid_h]) {
			rotate([0,90,0]) cylinder(r=pin_d/2,h=total_w+extra,center=true);
			translate([-w/2,0,0]) build_lid_hinge();
			for(i=[-1,1]) translate([i*(total_w-walls[1])/2,0,0]) hull() {
				rotate([0,90,0]) cylinder(r=hinge_d/2+hinge_clearance/2,h=walls[1]+hinge_clearance,center=true);
				translate([0,hinge_clearance/2,-hinge_d*.85]) cube([walls[1]+hinge_clearance,extra,extra],center=true);
			}
		}
		translate([0,0,-box_h/2]) cube([total_w,total_l,box_h],center=true);
	}
}

module build_lid_hinge(col=0,offset=walls[0]) {
	if (col % 2 != 0) translate([cols[col]/2,0,0]) hull() {
		rotate([0,90,0]) cylinder(r=hinge_d/2+hinge_clearance/2,h=cols[col]+offset+hinge_clearance,center=true);
		translate([0,0,-hinge_d*.85]) cube([cols[col]+offset+hinge_clearance,extra,extra],center=true);
	}
	if (col<len(cols)-1) translate([cols[col],0,0]) build_lid_hinge(col+1);
}

module build_box_hinge(col=0,offset=walls[0]) {
	if (col % 2 == 0) translate([cols[col]/2,0,0]) hull() {
		rotate([0,90,0]) cylinder(r=hinge_d/2+hinge_clearance/2,h=cols[col]-offset,center=true);
		translate([0,0,-hinge_d*.85]) cube([cols[col]-offset,extra,extra],center=true);
	}
	if (col<len(cols)-1) translate([cols[col],0,0]) build_box_hinge(col+1);
}
	
module build_rows(col=0,row=0,offset=walls[0]) {
	translate([0,rows[row]/2,0]) {
		if (row<len(rows)-1) translate([0,rows[row]/2,0]) build_rows(col,row+1,offset);
		build_cols(col,row,offset);
	}
}

module build_cols(col,row,offset=walls[0]) {
	translate([cols[col]/2,0,0]) {
		cube([cols[col]-offset/2,rows[row]-offset/2,box_h],center=true);
		if (col<len(cols)-1) translate([cols[col]/2,0,0]) build_cols(col+1,row,offset);
	}
}

function array_sum(arr,c=0) = c < len(arr) - 1 ?  arr[c] + array_sum(arr, c + 1) : arr[c];

