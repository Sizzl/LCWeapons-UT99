class LCImpactAffector expands Info;

var int CmpX, CmpY;

replication
{
	reliable if ( ROLE == ROLE_Authority )
		CmpX, CmpY;
}



function Setup( Pawn Shooter, vector X, vector Y)
{
	if ( Shooter == None )
		return;
	SetOwner( Shooter);
	SetLocation( Shooter.Location);
	CmpX = class'LCStatics'.static.CompressRotator( rotator(X) );
	CmpY = class'LCStatics'.static.CompressRotator( rotator(Y) );
}

simulated event PostNetBeginPlay()
{
	local vector X, Y;
	local Projectile P;
	local XC_CompensatorChannel LCChan;
	local vector OldLocation, Delta;
	
	X = vector( class'LCStatics'.static.DecompressRotator( CmpX));
	Y = vector( class'LCStatics'.static.DecompressRotator( CmpY));

	//Get local compensator
	ForEach AllActors( class'XC_CompensatorChannel', LCChan)
		if ( LCChan.LocalPlayer != None )
			break;
	if ( LCChan == None )
		return;
	
	//This is the client's own affector
	if ( Owner == LCChan.LocalPlayer )
	{
	}
	
	//Get projectiles (only straight liners for now)
	ForEach RadiusActors( class'Projectile', P, 500.0 + 1000.0 * LCChan.cAdv )
		if ( (P.Physics == PHYS_Projectile) || (P.Physics == PHYS_Falling) )
		{
			OldLocation = P.Location - P.Velocity * LCChan.cAdv;
			Delta = OldLocation - Location;
			if ( (VSize(Delta) <= 550) && (Normal(Delta) Dot X > 0.9) && FastTrace(OldLocation) )
			{
				P.Velocity *= -1;
				P.AutonomousPhysics( LCChan.cAdv);
				P.Velocity *= -1;
				if ( P.Velocity Dot Y > 0 )
					P.Velocity = P.Speed * Normal( P.Velocity + (750 - VSize(Delta)) * Y);
				else	
					P.Velocity = P.Speed * Normal( P.Velocity - (750 - VSize(Delta)) * Y);
				P.AutonomousPhysics( LCChan.cAdv);
			}
		}
		
}

defaultproperties
{
      CmpX=0
      CmpY=0
      bHidden=False
      bNetTemporary=True
      LifeSpan=0.800000
      DrawType=DT_None
      CollisionRadius=100.000000
      CollisionHeight=100.000000
      NetPriority=2.000000
      NetUpdateFrequency=40.000000
}
