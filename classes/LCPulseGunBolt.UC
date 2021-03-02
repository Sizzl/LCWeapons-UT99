//=============================================================================
// LCPulseGunBolt.
//=============================================================================
class LCPulseGunBolt extends PBolt;

//-----------------------------------------------------------------------------
// Properties.
//-----------------------------------------------------------------------------
var() bool bNoLockdown;
var float nextboltTime;

//-----------------------------------------------------------------------------
// Global Functions.
//-----------------------------------------------------------------------------

simulated function CheckBeam( vector X, float DeltaTime )
{
	local Actor HitActor;
	local vector HitLocation, HitNormal, HitCorrected;

	HitActor = Trace( HitLocation, HitNormal, Location+BeamSize*X, Instigator.Location, true );

	if ( HitActor!=None && HitActor!=Instigator && (HitActor.bProjTarget || HitActor==Level || HitActor.bBlockActors && HitActor.bBlockPlayers) && (Pawn(HitActor)==None || Pawn(HitActor).AdjustHitLocation(HitLocation,Velocity)) )
	{
		if ( Level.NetMode!=NM_Client )
		{
			HitCorrected = X;
			if ( (Pawn(HitActor) != None) && Pawn(HitActor).bIsPlayer && bNoLockdown)
				HitCorrected = vect(0,0,0); //Lockdown prevention on players - CB style

			if ( DamagedActor==None )
			{
				AccumulatedDamage = FMin( 0.5*(Level.TimeSeconds-LastHitTime), 0.1 );
				HitActor.TakeDamage( int(Damage*AccumulatedDamage), Instigator, HitLocation, float(MomentumTransfer)*HitCorrected*AccumulatedDamage, MyDamageType );
				AccumulatedDamage = 0.0;
			}
			else if ( DamagedActor!=HitActor )
			{
				DamagedActor.TakeDamage( int(Damage*AccumulatedDamage), Instigator, HitLocation, float(MomentumTransfer)*HitCorrected*AccumulatedDamage, MyDamageType );
				AccumulatedDamage = 0.0;
			}
			LastHitTime = Level.TimeSeconds;
			DamagedActor = HitActor;
			AccumulatedDamage += DeltaTime;
			if ( AccumulatedDamage>0.22 )
			{
				if ( DamagedActor.IsA('Carcass') && FRand()<0.09 )
				{
					AccumulatedDamage = 35.0/Damage;
				}
				DamagedActor.TakeDamage( int(Damage*AccumulatedDamage), Instigator, HitLocation, float(MomentumTransfer)*HitCorrected*AccumulatedDamage, MyDamageType );
				AccumulatedDamage = 0.0;
			}
		}
		if ( HitActor.bIsPawn && Pawn(HitActor).bIsPlayer )
		{
			if ( WallEffect!=None )
			{
				WallEffect.Destroy();
			}
		}
		else if ( WallEffect==None || WallEffect.bDeleteMe )
		{
			WallEffect = Spawn( Class'PlasmaHit', , , HitLocation-float(5)*X );
		}
		else if ( !WallEffect.IsA('PlasmaHit') )
		{
			WallEffect.Destroy();
			WallEffect = Spawn( Class'PlasmaHit', , , HitLocation-float(5)*X );
		}
		else
		{
			WallEffect.SetLocation( HitLocation-float(5)*X );
		}
		if ( WallEffect!=None && Level.NetMode!=NM_DedicatedServer )
		{
			Spawn( ExplosionDecal, , , HitLocation, Rotator(HitNormal) );
		}
		if ( PlasmaBeam!=None )
		{
			AccumulatedDamage += PlasmaBeam.AccumulatedDamage;
			PlasmaBeam.Destroy();
			PlasmaBeam = None;
		}
		return;
	}
	else if ( Level.NetMode!=NM_Client && DamagedActor!=None )
	{
		HitCorrected = X;
		if ( (Pawn(HitActor) != None) && Pawn(HitActor).bIsPlayer && bNoLockdown)
			HitCorrected = vect(0,0,0); //Lockdown prevention on players - CB style
		DamagedActor.TakeDamage( int(Damage*AccumulatedDamage), Instigator, DamagedActor.Location-HitCorrected*1.2*DamagedActor.CollisionRadius, float(MomentumTransfer)*X*AccumulatedDamage, MyDamageType );
		AccumulatedDamage = 0.0;
		DamagedActor = None;
	}
	nextboltTime += DeltaTime;
	if ( Position>=9 || nextboltTime<0.05 && PlasmaBeam==None )
	{
		if ( WallEffect==None || WallEffect.bDeleteMe )
		{
			WallEffect = Spawn( Class'PlasmaCap', , , Location+(BeamSize-float(4))*X );
		}
		else if ( WallEffect.IsA('PlasmaHit') )
		{
			WallEffect.Destroy();
			WallEffect = Spawn( Class'PlasmaCap', , , Location+(BeamSize-float(4))*X );
		}
		else
		{
			WallEffect.SetLocation( Location+(BeamSize-float(4))*X );
		}
	}
	else
	{
		if ( WallEffect!=None )
		{
			WallEffect.Destroy();
			WallEffect = None;
		}
		if ( PlasmaBeam==None )
		{
			PlasmaBeam = Spawn( Class'LCPulseGunBolt', , , Location+BeamSize*X );
			PlasmaBeam.Position = Position+1;
			LCPulseGunBolt(PlasmaBeam).nextboltTime = nextboltTime-0.05;
		}
		else
		{
			PlasmaBeam.UpdateBeam( Self, X, DeltaTime );
		}
	}
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

defaultproperties
{
      bNoLockdown=False
      nextboltTime=0.000000
}
