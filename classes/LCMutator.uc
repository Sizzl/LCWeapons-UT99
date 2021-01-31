//Keep all basic weapon replacement and standalone implementations here
class LCMutator expands XC_LagCompensation;

var Weapon ReplaceThis, ReplaceThisWith;
var LCSpawnNotify ReplaceSN;
var() bool bApplySNReplace;
var() bool bTeamShock;
var() string LoadedClasses;
var() config bool bUseRifleHeadshotAdjustment;
var() config bool bDebug;
var() config float PowerAdjustMiniPri; // Power (frequency) adjustment, lower value = more frequent
var() config float PowerAdjustMiniSec; 

var() config bool bNoLockdownAll; // All overrides individual values if True (TO-DO - further weapon lockdown removal)
var() config bool bNoLockdownMini;

// Individual weapon replacement toggles
var() config bool bReplaceImpactHammer;
var() config bool bReplaceEnforcer;
var() config bool bReplaceShockRifle;
var() config bool bReplaceMinigun;
var() config bool bReplaceSniperRifle;
var() config bool bReplaceInsta;
var() config bool bReplaceSiegePulseRifle;

//Find known custom arenas, replace with LC arenas
event PreBeginPlay()
{
	local Mutator M, old;

	Super.PreBeginPlay(); //XC_LagCompensation will hook the monsters

	//New arena is hooked right before this LCMutator
	if ( FoundArena( Level.Game.BaseMutator) )
	{
		M = Level.Game.BaseMutator;
		Level.Game.BaseMutator = M.nextMutator;
		M.Destroy();
	}
	old = Level.Game.BaseMutator;
	For ( M=old.NextMutator ; M!=none ; M=M.nextMutator )
	{
		if ( FoundArena( M) )
		{
			old.NextMutator = M.NextMutator;
			M.Destroy();
		}
		else
			old = M;
	}
	Level.Game.RegisterMessageMutator(self);
}

function AddMutator(Mutator M)
{
	//Do not add this arena if it can be replaced
	if ( FoundArena(M) || M==self )
	{
		return;
	}

	if ( LCArenaMutator(M) != None )
	{
		LCArenaMutator(M).LCMutator = self;
		ChainMutatorBeforeThis(M);
		return;
	}
	
	if ( FV_ColoredShock(M) != none )
	{
		bTeamShock = true;
		M.Destroy();
		return;
	}

	if ( NextMutator == None )
		NextMutator = M;
	else
		NextMutator.AddMutator(M);
}

event PostBeginPlay()
{
	ReplaceSN = Spawn(class'LCSpawnNotify');
	ReplaceSN.Mutator = self;
}

function Class<Weapon> MyDefaultWeapon()
{
	if ( Level.Game.DefaultWeapon == class'ImpactHammer' && bReplaceImpactHammer )
		return class'LCImpactHammer';
	return Level.Game.DefaultWeapon;
}

function bool IsRelevant( Actor Other, out byte bSuperRelevant)
{
	local int Result;

	if ( ScriptedPawn(Other) != None )
	{
		SetupPosList( Other );
		return true;
	}

	Result = LCReplacement(Other); //0 = replace, 1 = no replace, 2 = delayed replace
	if ( Result == 1 && (NextMutator != None) ) //Do not let mutators alter delayed replacements
		Result = int(NextMutator.IsRelevant(Other, bSuperRelevant));

	return (Result > 0);
}

function int LCReplacement( Actor Other)
{
	local Weapon W;
	
	W = Weapon(Other);
	if ( W == none )
		return 1;

	if ( W.GetPropertyText("LCChan") != "" )
	{
		W.KillCredit(self);
		return 1;
	}
		
	if ( W.Class == class'ImpactHammer' && bReplaceImpactHammer)
		return DoReplace(W,class'LCImpactHammer');
	else if ( ClassIsChildOf( W.Class, class'Enforcer') && bReplaceEnforcer)
	{
		if ( W.Class == class'Enforcer' )		return DoReplace(W,class'LCEnforcer');
		else if ( W.IsA('sgEnforcer') )			return DoReplace(W,class'LCEnforcer',,,true);
	}
	else if ( ClassIsChildOf( W.Class, class'ShockRifle') && bReplaceShockRifle)
	{
		if ( W.Class == class'ShockRifle' )			return DoReplace(W,class'LCShockRifle');
		if ( W.Class == class'SuperShockRifle' )	return DoReplace(W,class'LCSuperShockRifle',class'LCShockRifleLoader');
		if ( W.IsA('AdvancedShockRifle') )			return DoReplace(W,class'LCAdvancedShockRifle',class'LCShockRifleLoader');
		if ( W.IsA('BP_ShockRifle') )				return DoReplace(W,class'LCBP_ShockRifle',class'LCShockRifleLoader');
		if ( W.IsA('RainbowShockRifle') )			return DoReplace(W,class'LCRainbowShockRifle',class'LCShockRifleLoader');
	}
	else if ( W.default.Mesh == LodMesh'Botpack.RiflePick' && bReplaceSniperRifle )	//This is a sniper rifle!
	{
		if ( ClassIsChildOf( W.Class, class'SniperRifle') )
		{
			if ( W.Class == class'SniperRifle' )	return DoReplace(W,class'LCSniperRifle');
			else if ( W.IsA('SniperRifle2x') ) 		return DoReplace(W,class'LCSniperRifle',,,true); //AWM_Beta1 rifle
			else if ( W.IsA('BP_SniperRifle') )		return DoReplace(W,class'LCBP_SniperRifle',class'LCSniperRifleLoader');
		}
		else if ( W.IsA('MH2Rifle') )
		{
			class'LCMH2Rifle'.default.RifleDamage = int(W.GetPropertyText("RifleDamage"));
			if ( class'LCMH2Rifle'.default.RifleDamage == 0 )
				class'LCMH2Rifle'.default.RifleDamage = 50;
			return DoReplace(W,class'LCMH2Rifle',class'LCSniperRifleLoader');
		}
		else if ( W.IsA('NYACovertSniper') )		return DoReplace(W,class'LCNYACovertSniper',class'LCSniperRifleLoader');
		else if ( W.IsA('ChamV2SniperRifle') )		return DoReplace(W,class'LCChamRifle',class'LCSniperRifleLoader');
		else if ( string(W.class) ~= "h4xRiflev3.h4x_Rifle" )	return DoReplace(W,class'LC_v3_h4xRifle',class'LCSniperRifleLoader');
		else if ( W.IsA('AlienAssaultRifle') )					return DoReplace(W,class'LC_AARV17',class'LCSniperRifleLoader');
	}
	else if ( ClassIsChildOf( W.Class, class'minigun2') && bReplaceMinigun)
	{
		if ( W.Class == class'minigun2' )			return DoReplace(W,class'LCMinigun2');
		else if ( W.IsA('Minigun_2x') )				return DoReplace(W,class'LCMinigun2',,,true);
		else if ( W.IsA('BP_Minigun') )				return DoReplace(W,class'LCBP_Minigun',class'LCClassLoader');
		else if ( W.IsA('sgMinigun') )				return SiegeMini(W);
	}
	else if ( W.default.Mesh == LodMesh'UnrealI.minipick' && bReplaceMinigun )	//This is an old minigun!
	{
		if ( (W.Class == Class'UnrealI.Minigun') || W.IsA('OLMinigun') )
			return DoReplace( W, class'LCMinigun');
		else if ( W.IsA('LMinigun') ) //Liandri minigun
		{
			Class'LCLiandriMinigun'.default.OrgClass = class<TournamentWeapon>(W.Class);
			return DoReplace( W, class'LCLiandriMinigun');
		}
	}
	else if ( W.IsA('AsmdPulseRifle') && bReplaceSiegePulseRifle ) //SiegeXtreme
	{
		Class'LCAsmdPulseRifle'.default.OrgClass = class<TournamentWeapon>(W.Class);
		return DoReplace( W, class'LCAsmdPulseRifle');
	}
	else if ( W.IsA('SiegeInstagibRifle') && bReplaceInsta ) //SiegeUltimate
	{
		Class'LCSiegeInstagibRifle'.default.OrgClass = class<TournamentWeapon>(W.Class);
		return DoReplace( W, class'LCSiegeInstagibRifle');
	}


	return 1;
}

function int SiegeMini( Weapon Other)
{
	local Weapon W;

	W = Other.Spawn(class'LCMinigun2', Other.Owner, Other.Tag);
	if ( W != none )
	{
		LCMinigun2(W).SlowSleep = 0.14;
		LCMinigun2(W).FastSleep = 0.09;
		W.SetCollisionSize( Other.CollisionRadius, Other.CollisionHeight);
		W.Tag = Other.Tag;
		W.Event = Other.Event;
		if ( W.MyMarker != none )
		{
			W.MyMarker = Other.MyMarker;
			W.MyMarker.markedItem = W;
		}
		W.bHeldItem = Other.bHeldItem;
		W.RespawnTime = Other.RespawnTime;
		W.PickupAmmoCount = Other.PickupAmmoCount;
		W.AmmoName = Other.AmmoName;
		W.bRotatingPickup = Other.bRotatingPickup;
		SetReplace( Other, W);
		return int(bApplySNReplace) * 2;
	}
	return 1;
}

function int DoReplace
(
	Weapon Other,
	class<Weapon> NewWeapClass,
	optional class<LCClassLoader> LoaderClass,
	optional bool bFullAmmo,
	optional bool bCopyAmmo
)
{
	local Weapon W;
	local bool bAllowItemRotation, bForceItemRotation;

	if ( LoaderClass != None )
		SetupLoader( Other.Class, NewWeapClass, LoaderClass);
	
	W = Other.Spawn(NewWeapClass, Other.Owner, Other.Tag, Other.Location);
	if ( W != none )
	{
		W.SetCollisionSize( Other.CollisionRadius, Other.CollisionHeight);
		W.Tag = Other.Tag;
		W.Event = Other.Event;
		if ( Other.MyMarker != none )
		{
			W.MyMarker = Other.MyMarker;
			W.MyMarker.markedItem = W;
		}
		W.bHeldItem = Other.bHeldItem;
		W.RespawnTime = Other.RespawnTime;
		W.PickupAmmoCount = Other.PickupAmmoCount;
		if ( bCopyAmmo )
			W.AmmoName = Other.AmmoName;
		if ( bFullAmmo )
			W.PickupAmmoCount = W.AmmoName.default.MaxAmmo;
		if ( (!Other.bRotatingPickup || Other.RotationRate == rot(0,0,0))
				&& (Other.Rotation.Pitch != 0 || Other.Rotation.Roll != 0) )
			bAllowItemRotation = False;
		else
			bAllowItemRotation = (Other.RotationRate != rot(0,0,0) && Other.bRotatingPickup) || !Other.default.bRotatingPickup || Other.default.RotationRate == rot(0,0,0);
		bForceItemRotation = Other.RotationRate != rot(0,0,0) && Other.bRotatingPickup && (!Other.default.bRotatingPickup || Other.default.RotationRate == rot(0,0,0));
 
		W.bRotatingPickup = bAllowItemRotation && (W.bRotatingPickup || bForceItemRotation);;
		W.bFixedRotationDir=Other.bFixedRotationDir;
		W.SetPhysics(Other.Physics);
		SetReplace( Other, W);
		return int(bApplySNReplace) * 2;
	}
	return 1;
}

function SetReplace( Weapon Other, Weapon With)
{
	ReplaceThis = Other;
	ReplaceThisWith = With;
	if ( (ReplaceThis != none) && (ReplaceThisWith != none) )
		ReplaceSN.ActorClass = ReplaceThis.class;
	else
		ReplaceSN.ActorClass = class'LCDummyWeapon';
}

function SetupLoader( class<Weapon> OrgW, class<Weapon> NewW, class<LCClassLoader> LoaderClass)
{
	if ( (LoaderClass != None) && (InStr(LoadedClasses, ";" $ NewW.Name $ ";") == -1) )
	{
		LoadedClasses = LoadedClasses $ NewW.Name $ ";";
		Spawn( LoaderClass).Setup( OrgW, NewW);
	}
}

//***************************************************
//This function is massive, deal with each known case
//***************************************************
function bool FoundArena( Mutator M)
{
	local LCArenaMutator LCArena;

	if ( M == none )
		return false;

	if ( Arena(M) != none )
	{
		if ( M.IsA('SniperArena') )
		{
			LCArena = Spawn( class'LCArenaMutator');
			LCArena.SetupWeaponReplace( class'SniperRifle', class'LCSniperRifle');
			LCArena.AddPropertyWeapon( "bCanThrow", "0");
		}
		else if ( M.IsA('ShockArena') )
		{
			LCArena = Spawn( class'LCArenaMutator');
			LCArena.SetupWeaponReplace( class'ShockRifle', class'LCShockRifle');
			LCArena.AddPropertyWeapon( "bCanThrow", "0");
		}
		else if ( M.IsA('impactarena') )
		{
			LCArena = Spawn( class'LCArenaMutator');
			LCArena.SetupWeaponReplace( class'ImpactHammer', class'LCImpactHammer');
		}
		else if ( M.IsA('InstaGibDM') && bReplaceInsta)
		{
			LCArena = Spawn( class'LCArenaMutator');
			LCArena.SetupWeaponReplace( class'SuperShockRifle', class'LCSuperShockRifle');
			if ( !ChainMutatorBeforeThis(LCArena) )
				return false;
			LCArena.LCMutator = self;
			LCArena.SetupWeaponRespawn( true, true, true, true, true, true);
			LCArena.SetupPickups( true, true, false, true);
			LCArena.AddPropertyWeapon( "bNoAmmoDeplete", "1");
			LCArena.AddPropertyWeapon( "bCanThrow", "0");
			SetupLoader( LCArena.OldWeapClass, LCArena.MainWeapClass, class'LCShockRifleLoader');
			return true;
		}

		if ( LCArena != none )
		{
			if ( !ChainMutatorBeforeThis(LCArena) )
				return false;
			LCArena.LCMutator = self;
			LCArena.SetupWeaponRespawn( true, true, true, true);
			LCArena.SetupPickups( false, false, false, true);
			return true;
		}
	}
	else if ( M.IsA('NYACovertSniper_RIFLEMutator') )
	{
		LCArena = Spawn( class'LCArenaMutator');
		LCArena.SetupWeaponReplace( class<Weapon>(DynamicLoadObject("NYACovertSniper.NYACovertSniper",class'class')), class'LCNYACovertSniper');
		if ( !ChainMutatorBeforeThis(LCArena) )
			return false;
		LCArena.LCMutator = self;
		LCArena.SetupWeaponRespawn( true, true, true, true);
		LCArena.SetupPickups( false, false, false, true);
		LCArena.AddPropertyWeapon( "bCanThrow", "0");
		SetServerPackage( "NYACovertSniper");
		SetupLoader( LCArena.OldWeapClass, LCArena.MainWeapClass, class'LCSniperRifleLoader');
		return true;
	}
	else if ( string(M.Class) ~= "ChamRifle_v2.Rifle_HeadshotMut" )
	{
		LCArena = Spawn( class'LCArenaMutator');
		LCArena.SetupWeaponReplace( class<Weapon>(DynamicLoadObject("ChamRifle_v2.ChamV2SniperRifle",class'class')), class'LCChamRifle');
		if ( !ChainMutatorBeforeThis(LCArena) )
			return false;
		LCArena.LCMutator = self;
		LCArena.SetupWeaponRespawn( true, true, true, true);
		LCArena.SetupPickups( false, false, false, true);
		LCArena.AddPropertyWeapon( "bCanThrow", "0");
		SetServerPackage( "ChamRifle_v2");
		SetupLoader( LCArena.OldWeapClass, LCArena.MainWeapClass, class'LCSniperRifleLoader');
		return true;
	}
	else if ( string(M.Class) ~= "h4xRiflev3.h4x_HeadshotMut" )
	{
		LCArena = Spawn( class'LCArenaMutator');
		LCArena.SetupWeaponReplace( class<Weapon>(DynamicLoadObject("h4xRiflev3.h4x_Rifle",class'class')), class'LC_v3_h4xRifle');
		if ( !ChainMutatorBeforeThis(LCArena) )
			return false;
		LCArena.LCMutator = self;
		LCArena.SetupWeaponRespawn( true, true, true, true);
		LCArena.SetupPickups( true, false, false, false);
		LCArena.SetupCustomXLoc( class<Translocator>(DynamicLoadObject("h4xRiflev3.h4x_Xloc",class'class')), true);
		LCArena.AddPropertyWeapon( "bCanThrow", "0");
		SetServerPackage( "h4xRiflev3");
		SetupLoader( LCArena.OldWeapClass, LCArena.MainWeapClass, class'LCSniperRifleLoader');
		return true;
	}
	else if ( string(M.Class) ~= "AARV17.AlienRifleMutator" )
	{
		LCArena = Spawn( class'LCArenaMutator');
		LCArena.SetupWeaponReplace( class<Weapon>(DynamicLoadObject("AARV17.AlienAssaultRifle",class'class')), class'LC_AARV17');
		if ( !ChainMutatorBeforeThis(LCArena) )
			return false;
		LCArena.LCMutator = self;
		LCArena.SetupWeaponRespawn( true, true, true, true, true);
//		LCArena.SetupPickups( false, false, false, false);
		LCArena.AddPropertyWeapon( "bCanThrow", "0");
		SetServerPackage( "AARV17");
		SetupLoader( LCArena.OldWeapClass, LCArena.MainWeapClass, class'LCSniperRifleLoader');
		return true;
	}

	
}

function bool ChainMutatorBeforeThis( Mutator M)
{
	local Mutator MU;
	M.NextMutator = self;
	if ( Level.Game.BaseMutator == self )
	{
		Level.Game.BaseMutator = M;
		return true;
	}

	For ( MU=Level.Game.BaseMutator ; MU.NextMutator != none ; MU=MU.NextMutator )
	{
		if ( MU.NextMutator == self )
		{
			MU.NextMutator = M;
			return true;
		}
	}

	Level.Game.BaseMutator.AddMutator( M);
	return true;
}


//*******************************
//******************* MUTATE

//Mimicking ZP because ppl gets used to stuff
function Mutate (string MutateString, PlayerPawn Sender)
{
	local string item;
	if ( !bNoBinds && Left(MutateString, 10) ~= "getweapon " )
	{
		if ( (MutateString ~= "getweapon zp_SniperRifle") || (MutateString ~= "getweapon zp_sn") )
			Class'LCStatics'.static.FindBasedWeapon( Sender, class'LCSniperRifle');
		else if ( (MutateString ~= "getweapon zp_ShockRifle") || (MutateString ~= "getweapon zp_sh") )
			Class'LCStatics'.static.FindBasedWeapon( Sender, class'LCShockRifle');
		else if ( (MutateString ~= "getweapon zp_Enforcer") || (MutateString ~= "getweapon zp_e") )
			Class'LCStatics'.static.FindBasedWeapon( Sender, class'LCEnforcer');
		else if ( (MutateString ~= "getweapon lc_apr") )
			Class'LCStatics'.static.FindBasedWeapon( Sender, class'LCAsmdPulseRifle');
		else if ( (MutateString ~= "getweapon lc_sir") )
			Class'LCStatics'.static.FindBasedWeapon( Sender, class'LCSiegeInstagibRifle');
		else if ( (MutateString ~= "getweapon lc_m") )
			Class'LCStatics'.static.FindBasedWeapon( Sender, class'LCMinigun2');
		else if ( (MutateString ~= "getweapon lc_ih") )
			Class'LCStatics'.static.FindBasedWeapon( Sender, class'LCImpactHammer');
	}
	else if ( MutateString ~= "lc" || MutateString ~= "lcweapons" || MutateString ~= "replacements" )
	{
		Sender.ClientMessage("LCWeapons replacement mutator. Weapons/variants being replaced:");
		Sender.ClientMessage("---");
		Sender.ClientMessage("Impact Hammer:"@string(bReplaceImpactHammer));
		// Sender.ClientMessage("Enforcer:"@string(bReplaceEnforcer)$", Lockdown enabled:"@(bNoLockdownAll || bNoLockdownEnforcer));
		Sender.ClientMessage("Enforcer:"@string(bReplaceEnforcer));
		Sender.ClientMessage("Shock Rifle:"@string(bReplaceShockRifle));
		Sender.ClientMessage("Minigun:"@string(bReplaceMinigun)$", Lockdown enabled:"@(bNoLockdownAll || bNoLockdownMini));
		//Sender.ClientMessage("Sniper Rifle:"@string(bReplaceSniperRifle)$", Lockdown enabled:"@(bNoLockdownAll || bNoLockdownSniper));
		Sender.ClientMessage("Sniper Rifle:"@string(bReplaceSniperRifle));
		Sender.ClientMessage("Super Shock Rifle (InstaGib):"@string(bReplaceInsta));
		Sender.ClientMessage("Rocket Projectiles:"@string(bReplaceRockets));
	}
	else if (Left(MutateString,6) ~= "lc set")
	{
		item = Mid(MutateString,7);
		if (Left(item,8) ~= "mini pri")
		{
			Sender.ClientMessage("Altering Minigun primary power adjustment from:"@PowerAdjustMiniPri$", to:"@string(float(Mid(item,9))));
			PowerAdjustMiniPri = float(Mid(item,9));
		}
		else if (Left(item,8) ~= "mini sec")
		{
			Sender.ClientMessage("Altering Minigun secondary power adjustment from:"@PowerAdjustMiniSec$", to:"@string(float(Mid(item,9))));
			PowerAdjustMiniSec = float(Mid(item,9));
		}
		SaveConfig();
	}
	else if ( Left(MutateString,9) ~= "lc toggle")
	{
		if (Sender.bAdmin)
		{
			item = Mid(MutateString,10);
				
			if (item ~= "ImpactHammer" || item ~= "Hammer")
			{
				bReplaceImpactHammer = !bReplaceImpactHammer;
				Sender.ClientMessage("Impact Hammer replacement, now set to:"@string(bReplaceImpactHammer));
			}
			else if (item ~= "Enforcer")
			{
				bReplaceEnforcer = !bReplaceEnforcer;
				Sender.ClientMessage("Enforcer replacement, now set to:"@string(bReplaceEnforcer));
			}
			else if (Left(item,5) ~= "Shock")
			{
				bReplaceShockRifle = !bReplaceShockRifle;
				Sender.ClientMessage("Shock Rifle replacement, now set to:"@string(bReplaceShockRifle));
			}
			else if (Left(item,4) ~= "Mini")
			{
				bReplaceMinigun = !bReplaceMinigun;
				Sender.ClientMessage("Minigun, now set to:"@string(bReplaceMinigun));
			}
			else if (Left(item,6) ~= "Sniper")
			{
				bReplaceSniperRifle = !bReplaceSniperRifle;
				Sender.ClientMessage("Sniper Rifle, now set to:"@string(bReplaceSniperRifle));
			}
			else if (Left(item,6) ~= "rocket")
			{
				bReplaceRockets = !bReplaceRockets;
				Sender.ClientMessage("Rocket replacement, now set to:"@string(bReplaceRockets));
			}
			else if (Left(item,2) ~= "hs")
			{
				bUseRifleHeadshotAdjustment = !bUseRifleHeadshotAdjustment;
				Sender.ClientMessage("Sniper Rifle headshot height adjustment, now set to:"@string(bUseRifleHeadshotAdjustment));
			}
			else if (Left(item,5) ~= "debug")
			{
				bDebug = !bDebug;
				Sender.ClientMessage("Enhanced logging, now set to:"@string(bDebug));
			}
			SaveConfig();
		}
		else
		{
			Sender.ClientMessage("Administrative rights required to make these changes.");
		}
	}
	else if ( MutateString ~= "zp_Off" )
	{
		Sender.ClientMessage("Zeroping disabled.");
		Sender.ClientMessage("Type 'mutate zp_on' to restore.");
		ffFindCompFor(Sender).CompChannel.ClientChangeLC(false);
	}
	else if ( MutateString ~= "zp_On" )
	{
		Sender.ClientMessage("Zeroping enabled.");
		Sender.ClientMessage("Type 'mutate zp_off' to disable.");
		ffFindCompFor(Sender).CompChannel.ClientChangeLC(true);
	}
	else if ( MutateString ~= "state" )
		Sender.ClientMessage("Weapon State:" @ string(Sender.Weapon.GetStateName()));
	Super.Mutate(MutateString,Sender);
}

function bool MutatorBroadcastLocalizedMessage(Actor Sender, Pawn Receiver, out class<LocalMessage> Message, out optional int Switch, out optional PlayerReplicationInfo RelatedPRI_1, out optional PlayerReplicationInfo RelatedPRI_2, out optional Object OptionalObject)
{
	// Let other message handlers know the default Item name of replaced weapons, helps with old HUD replacement and chat mutators
    if (OptionalObject!=None && Class<Weapon>(OptionalObject)!=None)
    {
    	switch (Caps(Class<Weapon>(OptionalObject).default.ItemName))
    	{
    		case "SNIPER RIFLE":
    			OptionalObject = class'Botpack.SniperRifle';
    			break;
    		case "SHOCK RIFLE":
    			OptionalObject = class'Botpack.ShockRifle';
    			break;
    		case "MINIGUN":
    			OptionalObject = class'Botpack.minigun2';
    			break;
    		case "PULSE GUN":
    			OptionalObject = class'Botpack.pulsegun';
    			break;
    		case "PULSE GUN":
    			OptionalObject = class'Botpack.pulsegun';
    			break;
    		case "IMPACT HAMMER":
    			OptionalObject = class'Botpack.ImpactHammer';
    			break;
    		case "ENFORCER":
    			OptionalObject = class'Botpack.Enforcer';
    			break;
    		case "ENHANCED SHOCK RIFLE":
    			OptionalObject = class'Botpack.SuperShockRifle';
    			break;
    		default:

    	}
    }
    return Super.MutatorBroadcastLocalizedMessage( Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
}  



//******************************************
//****************** DYNAMIC PACKAGE LOADING
//*** Platform friendly function, change this code for Unreal 227

final function SetServerPackage( string Pkg)
{
	if ( LCS.default.XCGE_Version >= 11 )
		AddToPackageMap( Pkg);
}


defaultproperties
{
     LoadedClasses=";"
     bDebug=false
     bUseRifleHeadshotAdjustment=true
     PowerAdjustMiniPri=1.00
     PowerAdjustMiniSec=1.00
     bReplaceImpactHammer=true
     bReplaceEnforcer=true
     bReplaceSiegePulseRifle=true
     bReplaceShockRifle=true
     bReplaceMinigun=true
     bReplaceSniperRifle=true
     bReplaceInsta=true
     bNoLockdownAll=true
     bNoLockdownMini=true
}

