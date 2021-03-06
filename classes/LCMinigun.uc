//=============================
// Unreal 1, here we go!
//=============================

class LCMinigun expands LCMinigun2;

function SetHand (float hand)
{
	Super.SetHand(hand);
	Mesh = Default.PlayerViewMesh;
}

simulated event RenderOverlays( canvas Canvas )
{
	Super(TournamentWeapon).RenderOverlays( Canvas);
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
	Super.ProcessTraceHit( Other, HitLocation, HitNormal, X, Y, Z);
}

simulated function PlayFiring()
{	
	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
	PlayAnim('Shoot1',0.8, 0.05);
	AmbientGlow = 250;
	AmbientSound = FireSound;
	bSteadyFlash3rd = true;
}

simulated function PlayAltFiring()
{
	PlayFiring();
}

state NormalFire
{
  function AnimEnd()
  {
    if (Pawn(Owner).Weapon != self) GotoState('');
    else if (Pawn(Owner).bFire!=0 && AmmoType.AmmoAmount>0)
    {
      if ( (PlayerPawn(Owner) != None) || (FRand() < ReFireRate) )
        Global.Fire(0);
      else 
      {
        Pawn(Owner).bFire = 0;
        GotoState('FinishFire');
      }
    }
    else if ( Pawn(Owner).bAltFire!=0 && AmmoType.AmmoAmount>0)
      Global.AltFire(0);
    else 
      GotoState('FinishFire');
  }
}

simulated state ClientAltFiring
{
	simulated function AnimEnd()
	{
		if ( (Pawn(Owner) == None) || (AmmoType.AmmoAmount <= 0) )
		{
			PlayUnwind();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner).bAltFire != 0 )
		{
			if ( (AnimSequence != 'Shoot2') || !bAnimLoop )
			{	
				AmbientSound = AltFireSound;
				SoundVolume = 255*Pawn(Owner).SoundDampening;
				LoopAnim('Shoot2',1.9);
			}
			else if ( AmbientSound == None )
				AmbientSound = FireSound;

			if ( Affector != None )
				Affector.FireEffect();
			if ( PlayerPawn(Owner) != None )
				PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
		}
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else
		{
			PlayUnwind();
			bSteadyFlash3rd = false;
			GotoState('ClientFinish');
		}
	}
}

state AltFiring
{
	function AnimEnd()
	{
		if ( (AnimSequence != 'Shoot2') || !bAnimLoop )
		{  
			AmbientSound = AltFireSound;
			SoundVolume = 255*Pawn(Owner).SoundDampening;
			LoopAnim('Shoot2',0.5);
		}
		else if ( AmbientSound == None )
			AmbientSound = FireSound;
		if ( Affector != None )
			Affector.FireEffect();
	}
}

state Idle
{


Begin:
  if (Pawn(Owner).bFire!=0 && AmmoType.AmmoAmount>0) Fire(0.0);
  if (Pawn(Owner).bAltFire!=0 && AmmoType.AmmoAmount>0) AltFire(0.0);  
  PlayAnim('Still');
  bPointing=False;
  if ( (AmmoType != None) && (AmmoType.AmmoAmount<=0) ) 
    Pawn(Owner).SwitchToBestWeapon();  //Goto Weapon that has Ammo
  Disable('AnimEnd');
  PlayIdleAnim();    
}

defaultproperties
{
      bSpawnTracers=False
      FastSleep=0.070000
      FastTIW=0.087000
      SlowAccuracy=0.100000
      FastAccuracy=0.800000
      AmmoName=Class'UnrealShare.ShellBox'
      AIRating=0.700000
      RefireRate=0.900000
      AltRefireRate=0.930000
      FireSound=Sound'UnrealI.Minigun.RegF1'
      AltFireSound=Sound'UnrealI.Minigun.AltF1'
      Misc1Sound=Sound'UnrealI.Minigun.WindD2'
      InventoryGroup=10
      PlayerViewOffset=(X=5.600000,Y=-1.500000,Z=-1.800000)
      PlayerViewMesh=LodMesh'UnrealI.minigunM'
      PickupViewMesh=LodMesh'UnrealI.minipick'
      ThirdPersonMesh=LodMesh'UnrealI.SMini3'
      Mesh=LodMesh'UnrealI.minipick'
      CollisionRadius=28.000000
      LightBrightness=250
}
