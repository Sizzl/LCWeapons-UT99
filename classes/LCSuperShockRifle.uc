// Instagib version

class LCSuperShockRifle expands LCShockRifle;

/*
function AltFire( float Value )
{
	Fire(Value);
}
*/

defaultproperties
{
      bNoAmmoDeplete=True
      bCombo=False
      bInstantFlash=False
      ffRefireTimer=1.130000
      FireAnimRate=0.400000
      AltFireAnimRate=0.400000
      BeamPrototype=Class'Botpack.supershockbeam'
      ExplosionClass=Class'LCWeapons_0025uta.LCSuperRing2'
      hitdamage=1000
      InstFog=(X=800.000000,Z=0.000000)
      AmmoName=Class'Botpack.SuperShockCore'
      bAltInstantHit=True
      AltProjectileClass=None
      aimerror=650.000000
      DeathMessage="%k electrified %o with the %w."
      PickupMessage="You got the enhanced Shock Rifle."
      ItemName="Enhanced Shock Rifle"
      PlayerViewMesh=LodMesh'Botpack.sshockm'
      ThirdPersonMesh=LodMesh'Botpack.SASMD2hand'
}
