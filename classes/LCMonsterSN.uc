//************************
// Monsterhunt fix
//************************
class LCMonsterSN expands SpawnNotify;

var XC_LagCompensation Mutator;

event Actor SpawnNotification( actor A)
{
	Mutator.SetupPosList( A);
	return A;
}

defaultproperties
{
      Mutator=None
      ActorClass=Class'UnrealShare.ScriptedPawn'
      RemoteRole=ROLE_None
}
