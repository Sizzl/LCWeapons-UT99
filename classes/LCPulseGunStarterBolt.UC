//=============================================================================
// LCPulseGunStarterBolt
//=============================================================================
class LCPulseGunStarterBolt extends LCPulseGunBolt;

//-----------------------------------------------------------------------------
// Properties.
//-----------------------------------------------------------------------------
var float OldError;
var float NewError;
var float StartError;
var float aimerror;
var rotator AimRotation;
var float AnimTime;

//-----------------------------------------------------------------------------
// Network replication.
//-----------------------------------------------------------------------------

replication
{
	reliable if ( Role==ROLE_Authority )
		NewError, aimerror, AimRotation;
}

//-----------------------------------------------------------------------------
// Global Functions.
//-----------------------------------------------------------------------------

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( Instigator==None )
	{
		return;
	}
	if ( Instigator.IsA('Bot') && Bot(Instigator).bNovice )
	{
		aimerror = 2200.0+(float(3)-Instigator.Skill)*float(300);
	}
	else
	{
		aimerror = 1000.0+(float(3)-Instigator.Skill)*float(400);
	}
	if ( FRand()<0.5 )
	{
		aimerror *= float(-1);
	}
}

simulated function Tick( float DeltaTime )
{
	local vector X, Y, Z, AimSpot, DrawOffset, AimStart;
	local int YawErr;
	local float dAdjust;
	local Bot MyBot;

	AnimTime += DeltaTime;
	if ( AnimTime>0.05 )
	{
		AnimTime -= 0.05;
		SpriteFrame++;
		if ( SpriteFrame==5 )
		{
			SpriteFrame = 0;
		}
		Skin = SpriteAnim[SpriteFrame];
	}
	if ( Instigator!=None )
	{
		if ( Level.NetMode==NM_Client && (!Instigator.IsA('PlayerPawn') || PlayerPawn(Instigator).Player==None) )
		{
			SetRotation( AimRotation );
			Instigator.ViewRotation = AimRotation;
			DrawOffset = 0.01*Class'PulseGun'.default.PlayerViewOffset >> Rotation;
			DrawOffset += Instigator.EyeHeight*vect(0.0,0.0,1.0);
		}
		else
		{
			MyBot = Bot(Instigator);
			if ( MyBot!=None )
			{
				if ( Instigator.Target==None )
				{
					Instigator.Target = Instigator.Enemy;
				}
				if ( Instigator.Target==Instigator.Enemy )
				{
					if ( MyBot.bNovice )
					{
						dAdjust = DeltaTime*(float(4)+Instigator.Skill)*0.075;
					}
					else
					{
						dAdjust = DeltaTime*(float(4)+Instigator.Skill)*0.12;
					}
					if ( OldError>NewError )
					{
						OldError = FMax( OldError-dAdjust, NewError );
					}
					else
					{
						OldError = FMin( OldError+dAdjust, NewError );
					}
					if ( OldError==NewError )
					{
						NewError = FRand()-0.5;
					}
					if ( StartError>float(0) )
					{
						StartError -= DeltaTime;
					}
					else if ( MyBot.bNovice && Level.TimeSeconds-MyBot.LastPainTime<0.2 )
					{
						StartError = MyBot.LastPainTime;
					}
					else
					{
						StartError = 0.0;
					}
					AimSpot = 1.25*Instigator.Target.Velocity+0.75*Instigator.Velocity;
					if ( Abs(AimSpot.Z)<float(120) )
					{
						AimSpot.Z *= 0.25;
					}
					else
					{
						AimSpot.Z *= 0.5;
					}
					if ( int(Instigator.Target.Physics)==int(EPhysics.PHYS_Falling) )
					{
						AimSpot = Instigator.Target.Location-0.0007*aimerror*OldError*AimSpot;
					}
					else
					{
						AimSpot = Instigator.Target.Location-0.0005*aimerror*OldError*AimSpot;
					}
					if ( int(Instigator.Physics)==int(EPhysics.PHYS_Falling) && Instigator.Velocity.Z>float(0) )
					{
						AimSpot = AimSpot-0.0003*aimerror*OldError*AimSpot;
					}
					AimStart = Instigator.Location+FireOffset.X*X+FireOffset.Y*Y+(1.2*FireOffset.Z-float(2))*Z;
					if ( FastTrace(AimSpot-vect(0.0,0.0,10.0),AimStart) )
					{
						AimSpot = AimSpot-vect(0.0,0.0,10.0);
					}
					GetAxes( Instigator.Rotation, X, Y, Z );
					AimRotation = Rotator(AimSpot-AimStart);
					AimRotation.Yaw = int(float(AimRotation.Yaw)+(OldError+StartError)*0.75*aimerror);
					YawErr = AimRotation.Yaw-(Instigator.Rotation.Yaw&65535)&65535;
					if ( YawErr>3000 && YawErr<62535 )
					{
						if ( YawErr<32768 )
						{
							AimRotation.Yaw = Instigator.Rotation.Yaw+3000;
						}
						else
						{
							AimRotation.Yaw = Instigator.Rotation.Yaw-3000;
						}
					}
				}
				else if ( Instigator.Target!=None )
				{
					AimRotation = Rotator(Instigator.Target.Location-Instigator.Location);
				}
				else
				{
					AimRotation = Instigator.ViewRotation;
				}
				Instigator.ViewRotation = AimRotation;
				SetRotation( AimRotation );
			}
			else
			{
				AimRotation = Instigator.ViewRotation;
				SetRotation( AimRotation );
			}
			DrawOffset = Instigator.Weapon.CalcDrawOffset();
		}
		GetAxes( Instigator.ViewRotation, X, Y, Z );
		if ( bCenter )
		{
			FireOffset.Z = default.FireOffset.Z*1.5;
			FireOffset.Y = 0.0;
		}
		else
		{
			FireOffset.Z = default.FireOffset.Z;
			if ( bRight )
			{
				FireOffset.Y = default.FireOffset.Y;
			}
			else
			{
				FireOffset.Y = -1.0*default.FireOffset.Y;
			}
		}
		SetLocation( Instigator.Location+DrawOffset+FireOffset.X*X+FireOffset.Y*Y+FireOffset.Z*Z );
	}
	else
	{
		GetAxes( Rotation, X, Y, Z );
	}
	CheckBeam( X, DeltaTime );
}

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

		DamagedActor.TakeDamage( int(Damage*AccumulatedDamage), Instigator, DamagedActor.Location-X*1.2*DamagedActor.CollisionRadius, float(MomentumTransfer)*HitCorrected*AccumulatedDamage, MyDamageType );
		AccumulatedDamage = 0.0;
		DamagedActor = None;
	}
	if ( Position>=9 )
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
			LCPulseGunBolt(PlasmaBeam).bNoLockdown = bNoLockdown;
			PlasmaBeam.Position = Position+1;
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
      OldError=0.000000
      NewError=0.000000
      StartError=0.500000
      aimerror=0.000000
      AimRotation=(Pitch=0,Yaw=0,Roll=0)
      AnimTime=0.000000
      SpriteAnim(0)=Texture'Botpack.Skins.sbolt0'
      SpriteAnim(1)=Texture'Botpack.Skins.sbolt1'
      SpriteAnim(2)=Texture'Botpack.Skins.sbolt2'
      SpriteAnim(3)=Texture'Botpack.Skins.sbolt3'
      SpriteAnim(4)=Texture'Botpack.Skins.sbolt4'
      RemoteRole=ROLE_SimulatedProxy
      LightType=LT_Steady
      LightEffect=LE_NonIncidence
      LightBrightness=255
      LightHue=83
      LightSaturation=50
      LightRadius=5
}
