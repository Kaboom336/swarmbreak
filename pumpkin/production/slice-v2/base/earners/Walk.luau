-- Pure two-frame pose. Distance comes from the replicated authority Part, never an intent.
return function(distance,moving,side)
	if not moving or not side then return 0,0 end
	local frame=math.floor(distance/0.65)%2
	local raised=(frame==0 and side<0) or (frame==1 and side>0)
	return raised and 0.25 or 0,raised and 0.25 or -0.25
end
