//
//  Base position holder actor, designed for lag compensation
/////////////////////////////////////////////////////////////
class XC_PosList expands Info;

var XC_LagCompensation Mutator;
var bool bClientAdvance;
var bool bPingHandicap;

var float StartingTimeSeconds; //Only consider shots originated at this time or later
var vector Position[32];
var vector Extent[32]; //X=radius, Z=height (VSize = Bounding Sphere)
var float EyeHeight[32];
var int Flags[32];
//1 - Ghost
//2 - Duck (deprecated)
//4 - Teleported


event PostBeginPlay()
{
	StartingTimeSeconds = Level.TimeSeconds;
}

event Tick( float DeltaTime)
{
	if ( Owner == None || Owner.bDeleteMe )
		Destroy();
	else if ( Mutator.bAddPosition )
		UpdateNow();
}

function UpdateNow() 
{
	local int OldIndex;
	local int NewFlags;
	
	Position[Mutator.PositionIndex] = Owner.Location;
	Extent[Mutator.PositionIndex].X = Owner.CollisionRadius + float(bPingHandicap);
	Extent[Mutator.PositionIndex].Z = Owner.CollisionHeight + float(bPingHandicap);
	if ( Pawn(Owner) != None )
		EyeHeight[Mutator.PositionIndex] = class'LCStatics'.static.GetEyeHeight( Pawn(Owner) );
	
	OldIndex = (Mutator.PositionIndex - 1) & 31;
	if ( !Owner.bCollideActors )
		NewFlags += 1;
	if ( VSize( Position[OldIndex] - Owner.Location) > 200 )
		NewFlags += 4;
	Flags[Mutator.PositionIndex] = NewFlags;
}


function vector GetExtent( int Index)
{
	return Extent[Index];
} 

function SetupCollision( float TraceTimeStamp, vector StartTrace, vector X, vector Y, vector Z)
{
	local int i, Index;
	local vector OldPosition, OldExtent;
	
	i = int(bClientAdvance);
	
	//Eliminate objects that cannot be hit.
	if ( (Flags[Mutator.Marker[i].Index] & 1) != 0 //Ghost = fail
	   || TraceTimeStamp < StartingTimeSeconds ) //Shooting before 'Start' = fail
	   return;
	
	OldPosition = GetOldPosition( Mutator.Marker[i].Index, Mutator.Marker[i].IndexNext, Mutator.Marker[i].Alpha );
	OldPosition -= StartTrace;
	
	//Eliminate OldPositions behind the trace
	if ( OldPosition dot X < 0 ) 
		return;

	//Eliminate anything too far from the line's orthogonal projection of said OldPosition.
	X.X = 0;
	X.Y = OldPosition dot Y;
	X.Z = OldPosition dot Z;
	OldExtent = Extent[Mutator.Marker[i].Index];
	if ( VSize(X) > VSize(OldExtent) ) 
		return;
		
	//Passed all checks
	OldPosition += StartTrace;
	SetCollisionSize( OldExtent.X, OldExtent.Z);
	SetLocation( OldPosition );
	SetCollision( true, false, false);
	bProjTarget = true;
	Tag = 'CollidingPosList';
}

function DisableCollision()
{
	Tag = '';
	SetCollision( false );
}


function vector GetOldPosition( int Index, int IndexNext, float Alpha)
{
	local bool bTeleported;
	local vector NextPosition;
	
	if ( IndexNext >= 0 )
	{
		bTeleported = (Flags[IndexNext] & 4) != 0;
		NextPosition = Position[IndexNext];
	}
	else
	{
		bTeleported = VSize( Position[Index] - Owner.Location ) > 200;
		NextPosition = Owner.Location;
	}

	if ( bTeleported )
	{
		if ( Alpha > 0.01 )
			Alpha = 1;
	}

	return class'LCStatics'.static.VLerp( Alpha, Position[Index], NextPosition);
}


//Additional distance to add to error checks
//In case of teleportation, treat as stationary
function vector GetVelocity( int Index, int IndexNext)
{
	local float Time;
	local bool bTeleported;
	local vector NextPosition;

	Time = Mutator.PositionTimeStamp[Index];
	if ( IndexNext >= 0 )
	{
		Time -= Mutator.PositionTimeStamp[IndexNext];
		bTeleported = (Flags[IndexNext] & 4) != 0;
		NextPosition = Position[IndexNext];
	}
	else
	{
		bTeleported = VSize( Position[Index] - Owner.Location ) > 200;
		NextPosition = Owner.Location;
	}
	if ( bTeleported )
		return vect(0,0,0);

	Time = fMax( Time, Mutator.PositionStep / 10.0);
	return (Position[Index] - NextPosition) / Time;
}

defaultproperties
{
      Mutator=None
      bClientAdvance=False
      bPingHandicap=False
      StartingTimeSeconds=0.000000
      Position(0)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(1)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(2)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(3)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(4)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(5)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(6)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(7)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(8)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(9)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(10)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(11)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(12)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(13)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(14)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(15)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(16)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(17)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(18)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(19)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(20)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(21)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(22)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(23)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(24)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(25)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(26)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(27)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(28)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(29)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(30)=(X=0.000000,Y=0.000000,Z=0.000000)
      Position(31)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(0)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(1)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(2)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(3)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(4)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(5)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(6)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(7)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(8)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(9)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(10)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(11)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(12)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(13)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(14)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(15)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(16)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(17)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(18)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(19)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(20)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(21)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(22)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(23)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(24)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(25)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(26)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(27)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(28)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(29)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(30)=(X=0.000000,Y=0.000000,Z=0.000000)
      Extent(31)=(X=0.000000,Y=0.000000,Z=0.000000)
      EyeHeight(0)=0.000000
      EyeHeight(1)=0.000000
      EyeHeight(2)=0.000000
      EyeHeight(3)=0.000000
      EyeHeight(4)=0.000000
      EyeHeight(5)=0.000000
      EyeHeight(6)=0.000000
      EyeHeight(7)=0.000000
      EyeHeight(8)=0.000000
      EyeHeight(9)=0.000000
      EyeHeight(10)=0.000000
      EyeHeight(11)=0.000000
      EyeHeight(12)=0.000000
      EyeHeight(13)=0.000000
      EyeHeight(14)=0.000000
      EyeHeight(15)=0.000000
      EyeHeight(16)=0.000000
      EyeHeight(17)=0.000000
      EyeHeight(18)=0.000000
      EyeHeight(19)=0.000000
      EyeHeight(20)=0.000000
      EyeHeight(21)=0.000000
      EyeHeight(22)=0.000000
      EyeHeight(23)=0.000000
      EyeHeight(24)=0.000000
      EyeHeight(25)=0.000000
      EyeHeight(26)=0.000000
      EyeHeight(27)=0.000000
      EyeHeight(28)=0.000000
      EyeHeight(29)=0.000000
      EyeHeight(30)=0.000000
      EyeHeight(31)=0.000000
      Flags(0)=0
      Flags(1)=0
      Flags(2)=0
      Flags(3)=0
      Flags(4)=0
      Flags(5)=0
      Flags(6)=0
      Flags(7)=0
      Flags(8)=0
      Flags(9)=0
      Flags(10)=0
      Flags(11)=0
      Flags(12)=0
      Flags(13)=0
      Flags(14)=0
      Flags(15)=0
      Flags(16)=0
      Flags(17)=0
      Flags(18)=0
      Flags(19)=0
      Flags(20)=0
      Flags(21)=0
      Flags(22)=0
      Flags(23)=0
      Flags(24)=0
      Flags(25)=0
      Flags(26)=0
      Flags(27)=0
      Flags(28)=0
      Flags(29)=0
      Flags(30)=0
      Flags(31)=0
      RemoteRole=ROLE_None
}
