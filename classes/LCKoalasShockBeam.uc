class LCKoalasShockBeam extends supershockbeam;

simulated function Timer()
{
	local SuperShockBeam r;
	
	if (NumPuffs>0)
	{
		r = Spawn(class'LCKoalasShockBeam',,,Location+MoveAmount);
		r.RemoteRole = ROLE_None;
		r.NumPuffs = NumPuffs -1;
		r.MoveAmount = MoveAmount;
	}
}

defaultproperties
{
      Texture=Texture'Botpack.GoopEx.ge1_a00'
      Mesh=LodMesh'Botpack.PBolt'
}
