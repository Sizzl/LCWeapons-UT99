//==================================================================================
// LCPulseGun; secondary alterations only
//==================================================================================
class LCPulseGun extends PulseGun;

var XC_CompensatorChannel LCChan;
var int LCMode;

var() bool bBulletNow;
var() bool bTIW;
var() bool bDebug;

var() float SlowSleep; // Uses this if !bTIW
var() float FastSleep; // Uses this if !bTIW
var() float SlowTIW; //Copies value to SlowSleep if bTIW
var() float FastTIW; //Copies value to FastSleep if bTIW
var() float PowerFactorPri; // Adjusted in Mutator
var() float PowerFactorSec; // Adjusted in Mutator
var() float SlowAccuracy;
var() float FastAccuracy;
var() float TIWCounter;

var() int BaseDamage;
var() int RandomDamage;

var vector LastStartTrace;


replication
{
	reliable if ( bNetOwner && Role == ROLE_Authority )
		SlowSleep, FastSleep;
}


////////////////////////////////
//All of the unlagged code here
simulated event KillCredit( actor Other)
{
	if ( XC_CompensatorChannel(Other) != none )
		LCChan = XC_CompensatorChannel(Other);
	if ( LCMutator(Other) != none )
	{
		bDebug = LCMutator(Other).bDebug;
		bTIW = LCMutator(Other).bTIWFire;
		class'LCPulseGunBolt'.Default.bNoLockdown = LCMutator(Other).bNoLockdownAll || LCMutator(Other).bNoLockdownPulseGun;
		class'LCPulseGunStarterBolt'.Default.bNoLockdown = LCMutator(Other).bNoLockdownAll || LCMutator(Other).bNoLockdownPulseGun;
		PowerFactorPri = LCMutator(Other).PowerAdjustPulseGunPri;
		PowerFactorSec = LCMutator(Other).PowerAdjustPulseGunSec;
		if (bTIW)
		{
			if (bDebug)
				log("[LC] Adjusting TIW power value by a factor of, Pri:"@PowerFactorPri$", ["$SlowTIW$"->"$string(SlowTIW * PowerFactorPri)$"] Sec:"@PowerFactorSec$", ["$FastTIW$"->"$string(FastTIW * PowerFactorSec)$"]",'LCWeapons');
			SlowTIW = SlowTIW * PowerFactorPri;
			FastTIW = FastTIW * PowerFactorSec;
		}
		else
		{
			if (bDebug)
				log("[LC] Adjusting non-TIW power value by a factor of, Pri:"@PowerFactorPri$", ["$SlowSleep$"->"$string(SlowSleep * PowerFactorPri)$"] Sec:"@PowerFactorSec$", ["$FastSleep$"->"$string(FastSleep * PowerFactorSec)$"]",'LCWeapons');
			SlowSleep = SlowSleep * PowerFactorPri;
			FastSleep = FastSleep * PowerFactorSec;			

		}
	}
}
simulated function PlayPostSelect()
{
	if ( Level.NetMode == NM_Client )
		bCanClientFire = True;
	Super.PlayPostSelect();
}

state AltFiring
{
	ignores AnimEnd;

	function Tick( float DeltaTime )
	{
		local Pawn P;

		P = Pawn(Owner);
		if ( P==None )
		{
			GotoState( 'Pickup' );
			return;
		}
		if ( int(P.bAltFire)==0 || P.IsA('Bot') && (P.Enemy==None || Level.TimeSeconds-Bot(P).LastSeenTime>float(5)) )
		{
			P.bAltFire = 0;
			Finish();
			return;
		}
		Count += DeltaTime;
		if ( Count>0.24 )
		{
			if ( Affector!=None )
			{
				Affector.FireEffect();
			}
			Count -= 0.24;
			if ( !AmmoType.UseAmmo(1) )
			{
				Finish();
			}
		}
	}
}



//***********************************************************************
// LCWeapons common interfaces
//***********************************************************************
function Inventory SpawnCopy( Pawn Other )
{
	return Class'LCStatics'.static.SpawnCopy( Other, self);
}
function GiveTo( Pawn Other )
{
	Class'LCStatics'.static.GiveTo(Other,self);
}
function SetSwitchPriority( Pawn Other)
{
	Class'LCStatics'.static.SetSwitchPriority( Other, self, 'minigun2');
}
simulated function float GetRange( out int ExtraFlags)
{
	return 10000;
}
simulated function vector GetStartTrace( out int ExtraFlags, vector X, vector Y, vector Z)
{
	LastStartTrace = Owner.Location + CalcDrawOffset() + FireOffset.Y * Y + FireOffset.Z * Z;
	return LastStartTrace;
}
simulated function bool IsLC()
{
	return (LCChan != none) && LCChan.bUseLC && (LCChan.Owner == Owner);
}
simulated function float GetAimError()
{
	return 0;
}
simulated function bool HandleLCFire( bool bFire, bool bAltFire)
{
	return true; //Don't let LCChan hitscan fire
}

defaultproperties
{
      LCChan=None
      LCMode=0
      bBulletNow=False
      bTIW=False
      bDebug=False
      SlowSleep=0.130000
      FastSleep=0.080000
      SlowTIW=0.150000
      FastTIW=0.100000
      PowerFactorPri=1.000000
      PowerFactorSec=1.000000
      SlowAccuracy=0.200000
      FastAccuracy=0.750000
      TIWCounter=0.000000
      BaseDamage=9
      RandomDamage=6
      LastStartTrace=(X=0.000000,Y=0.000000,Z=0.000000)
      AltProjectileClass=Class'LCWeapons_0025test.LCPulseGunStarterBolt'
}
