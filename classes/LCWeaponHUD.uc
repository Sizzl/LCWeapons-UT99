//Render weapon stuff in PURE based games
class LCWeaponHUD extends Mutator;

var PlayerPawn LocalPlayer;

simulated event PostBeginPlay()
{
	SetTimer( 5, false); //Wait for PURE to replace stuff
}

simulated event Timer()
{
	local string HudClass;
	HudClass = string(LocalPlayer.myHud.Class);
	//Hud was replaced
	if ( InStr(Caps(HudClass),"PURE") >= 0 && Caps(Left(HudClass,12)) != "INSTAGIBPLUS" )
	{
		NextHUDMutator = LocalPlayer.myHud.HUDMutator;
		LocalPlayer.myHud.HUDMutator = self;
	}
	else
		Destroy();
}

simulated event PostRender (Canvas Canvas)
{
	if ( (LocalPlayer != None) && (LocalPlayer.Weapon != None) )
		LocalPlayer.Weapon.PostRender(Canvas);
}

defaultproperties
{
      LocalPlayer=None
}
