local rotations = {}
local r = math.pi/2
local d = math.pi
rotations.facedir = {
	[0] = vector.new(0, 0, 0),
	vector.new( 0, -r,  0),
	vector.new( 0,  d,  0),
	vector.new( 0,  r,  0),

	vector.new(-r,  0,  0),
	vector.new( 0, -r, -r),
	vector.new( r,  d,  0),
	vector.new( 0,  r,  r),

	vector.new( r,  0,  0),
	vector.new( 0, -r,  r),
	vector.new(-r,  d,  0),
	vector.new( 0,  r, -r),

	vector.new( 0,  0,  r),
	vector.new(-r,  0,  r),
	vector.new( d,  0,  r),
	vector.new( r,  0,  r),

	vector.new( 0,  0, -r),
	vector.new( r,  0, -r),
	vector.new( d,  0, -r),
	vector.new(-r,  0, -r),

	vector.new( 0,  0,  d),
	vector.new( 0,  r,  d),
	vector.new( 0,  d,  d),
	vector.new( 0, -r,  d),
}

return rotations
