class LCKoalasSuperRing extends ut_superring2;

simulated function SpawnExtraEffects()
{
	bExtraEffectsSpawned = true;
	Spawn(class'EnergyImpact');
	Spawn(class'SuperShockExplo').RemoteRole = ROLE_None;
}

defaultproperties
{
      LODBias=1000.000000
      Style=STY_Translucent
      Texture=Texture'Botpack.Skins.MuzzyPulse'
      DrawScale=4.000000
      ScaleGlow=3.000000
      bParticles=True
}
