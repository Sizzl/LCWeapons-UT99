//************************
// Change a reference here
//************************
class LCSpawnNotify expands SpawnNotify;

var LCMutator Mutator;

auto state InitialDelay
{
Begin:
	Sleep(0.0);
	Mutator.bApplySNReplace = true;
}

event Actor SpawnNotification( actor A)
{
	if ( (Mutator.ReplaceThis == A) && (Mutator.ReplaceThisWith != none) )
	{
		A.Destroy();
		A = Mutator.ReplaceThisWith;
		Mutator.SetReplace(none,none);
	}
	return A;
}

defaultproperties
{
      Mutator=None
      ActorClass=Class'LCWeapons_0025test.LCDummyWeapon'
      RemoteRole=ROLE_None
}
