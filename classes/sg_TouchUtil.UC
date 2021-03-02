//=============================================================================
// sg_TouchUtil.
//=============================================================================
class sg_TouchUtil expands Object;

static final function ClearTouchList( actor A)
{
	A.Touching[0] = none;
	A.Touching[1] = none;
	A.Touching[2] = none;
	A.Touching[3] = none;
}

static final function NoTouch( actor A, actor B)
{
	local int i;
	For ( i=0 ; i<4 ; i++ )
	{
		if ( A.Touching[i] == B )
			A.Touching[i] = none;
		if ( B.Touching[i] == A )
			B.Touching[i] = none;
	}
}

static final function SetTouch( actor A, actor B)
{
	local int i;
	while ( i<4 )
		if ( A.Touching[i++] == B )
			return;
	while ( i-->0 )
		if ( A.Touching[i] == none )
		{
			A.Touching[i] = B;
			return;
		}
}

defaultproperties
{
}
