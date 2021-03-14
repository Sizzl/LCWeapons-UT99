//=============================================================================
// XC_LagCompensation.
// 128 player markers, 32 generic ones
// Made by Higor
//=============================================================================
class XC_LagCompensation expands Mutator
	config(LCWeapons);

const PositionStep = 0.05f;
const LCS = class'LCStatics';


struct PositionMarker
{
	var() int Index;
	var() int IndexNext;
	var() float Alpha;
};

var XC_LagCompensator ffCompList;
var int iCombo; //Combo tracker count
var float ffMaxLatency;
var string Pkg;
var int ffCurId;
var float LastTimeSeconds;

var GameEngine XCGE;

var bool bNoBinds;
var bool bNeedsHiddenEffects;

var(Debug) float PingMult, PingAdd;
var Pawn LinkedPawn;
var() config bool bDebug;
var() config bool bKickers; //Requires restart
var() config bool bSWJumpPads;
var() config bool bWeaponAnim;
var() config bool bSimulateAmmo;
var() config bool bUsePrediction;
var() config bool bEnableMHhack;

var() config bool bReplaceRockets;
var() config bool bReplaceImpactHammer;
var() config bool bReplaceEnforcer;
var() config bool bReplacePulseGun;
var() config bool bReplaceShockRifle;
var() config bool bReplaceMinigun;
var() config bool bReplaceSniperRifle;
var() config bool bReplaceInsta;
var() config bool bReplaceSiegePulseRifle;

var() config bool bTIWFire;
var() config float MaxPredictNonLC;
var() config int PredictMode;
var Teleporter swPads[63];

// Time Stamp counter for positions
var(Debug) int PositionIndex;
var(Debug) bool bAddPosition;
var(Debug) float PositionTimeStamp[32]; //Real Seconds!!
var(Debug) float PositionTimer;
var PositionMarker Marker[2]; //Set during ffUnlagPositions


//XC_GameEngine interface
native(1718) final function bool AddToPackageMap( optional string PkgName);

event PreBeginPlay()
{
	local ScriptedPawn Monster;
	local Kicker K;
	local Teleporter T; 
	local int i;

	if ( LCS.static.DetectXCGE( self) )
		SetPropertyText("XCGE", XLevel.GetPropertyText("Engine"));
	Spawn(class'LCProjSN').Mutator = self;
	bNoBinds = LCS.default.bXCGE; //This Game Engine is about to correct GetWeapon!!!
	if ( LCS.default.XCGE_Version >= 11 )
		AddToPackageMap();
	if ( Level.Game.IsA('Monsterhunt') && bEnableMHhack )
	{
		Spawn(class'LCMonsterSN').Mutator = self;
		ForEach AllActors (class'ScriptedPawn', Monster)
			SetupPosList( Monster );
	}

	if ( bKickers )
		ForEach AllActors (class'Kicker', K)
		{
			if ( K.GetPropertyText("NoLC") != "" )
				continue;
			if ( (K.KickedClasses == 'Actor') || (K.KickedClasses == 'Pawn') || (K.KickedClasses == 'PlayerPawn') || (K.KickedClasses == 'Projectile') )
				Spawn(class'LCKicker').ServerSetup( K);
		}
	if ( bSWJumpPads )
		ForEach AllActors (class'Teleporter', T)
		{
			if ( T.IsA('swJumpPad') )
			{
				swPads[i++] = T;
				if ( i >= (ArrayCount(swPads)-1) ) //Last slot always free for speed reasons and code simplicity
					break;
			}
		}
}

/*-----------------------------------------------------------------------
	Mutator Interface.
-----------------------------------------------------------------------*/

function ModifyPlayer( Pawn Other)
{
	local XC_LagCompensator Comp;
	
	Super.ModifyPlayer(Other);

	Comp = ffFindCompFor(Other);
	if ( Comp == none )
		ffInsertNewPlayer( Other);
	else
		Comp.CheckPosList();
}


//Mimicking ZP because ppl gets used to stuff
function Mutate (string MutateString, PlayerPawn Sender)
{
	local int PPredict;
	local XC_LagCompensator LCComp;
	local string Param;
	
	if ( Sender != none )
	{
		if ( MutateString ~= "GetPrediction")
		{
			PPredict = -1;
			Sender.ClientMessage("The server is using a"@int(MaxPredictNonLC)@"ms prediction cap, mode:"@LCComp.Mode$", debugging enabled:"@LCComp.bDebug);
			LCComp = ffFindCompFor(Sender);
			if ( LCComp != none && LCComp.CompChannel != none )
				PPredict = LCComp.CompChannel.ClientPredictCap;
			if ( PPredict == 0 )
				Sender.ClientMessage( "Your client is overriding prediction: 0 = DISABLED");
			else if ( PPredict > 0 )
				Sender.ClientMessage( "Your client is overriding prediction cap: "$PPredict$"ms");
		}
		else if ( Left(MutateString, 11) ~= "Prediction " )
		{
			LCComp = ffFindCompFor(Sender);
			Param = Mid( MutateString, 11);
			if ( LCComp != none && LCComp.CompChannel != none )
			{
				if ( Param ~= "default" || Param ~= "enable" )
					LCComp.CompChannel.ChangePCap( -1);
				else if ( Param ~= "disable" )
					LCComp.CompChannel.ChangePCap( 0);
				else
					LCComp.CompChannel.ChangePCap( int(Param) );
				Sender.ClientMessage( "New Prediction cap value: "$LCComp.CompChannel.ClientPredictCap$", mode:"@LCComp.Mode$", debugging enabled:"@LCComp.bDebug );
			}	
		}
		else if ( Sender.bAdmin && Left(MutateString, 6) ~= "pmode " )
		{
			Param = Mid( MutateString, 6);
			LCComp = ffFindCompFor(Sender);
			PredictMode = int(Param);
			if (PredictMode==1)
				Sender.ClientMessage( "Global prediction mode is now set to less frequent sampling.");
			else if (PredictMode==2)
				Sender.ClientMessage( "Global prediction mode is now set to less frequent and next-neighbour sampling.");
			else if (PredictMode==3)
				Sender.ClientMessage( "Global prediction mode is now set to smoothed averaging.");
			else
			{
				PredictMode = 0;
				Sender.ClientMessage( "Global prediction mode is now set to smoothed averaging.");
			}


			SaveConfig();
			if ( LCComp != none && LCComp.CompChannel != none )
			{
				LCComp.Mode = PredictMode;
			}

		}
		else if ( Left(MutateString, 10) ~= "Prediction" )
		{
			Sender.ClientMessage( "Use MUTATE PREDICTION VALUE to control the prediction cap");
			Sender.ClientMessage( "> Add a numeric value (in ms), 0 disables prediction");
			Sender.ClientMessage( "> Add DEFAULT value to let server control prediction cap");
		}
	}
	Super.Mutate(MutateString,Sender);
}


/*-----------------------------------------------------------------------
	Other code.
-----------------------------------------------------------------------*/


event Tick( float DeltaTime)
{
	local int i;
	local XC_LagCompensator LCComp;

	bNeedsHiddenEffects = (LCS.default.XCGE_Version < 17) || (XCGE == none) || !bool(XCGE.GetPropertyText("bUseNewRelevancy"));

	//Frame took over 0.25 second!!! (game was paused/server frame drop)
	if ( Level.TimeSeconds - LastTimeSeconds > 0.25 * Level.TimeDilation ) 
	{
		For ( LCComp=ffCompList ; LCComp!=None ; LCComp=LCComp.ffCompNext )
			LCComp.ResetTimeStamp();
	}
	
	//Advance all timestamps
	DeltaTime /= Level.TimeDilation;
	for ( i=0 ; i<32 ; i++ )
		PositionTimeStamp[i] += DeltaTime;
	PositionTimer += DeltaTime;
		
	bAddPosition = PositionTimer >= PositionStep;
	if ( bAddPosition )
	{
		PositionTimer = fMin( PositionStep, PositionTimer - PositionStep);
		PositionIndex = (PositionIndex + 1) & 31;
		PositionTimeStamp[PositionIndex] = 0;
	}
	
	LastTimeSeconds = Level.TimeSeconds;
}


function ffCollidePlayers( private bool ffEnable)
{
	local private XC_LagCompensator ffTmp;
	
	if ( !ffEnable )
	{	For ( ffTmp=ffCompList ; ffTmp!=none ; ffTmp=ffTmp.ffCompNext )
		{
			ffTmp.ffGetCollision();
			ffTmp.ffNoCollision();
		}
	}
	else
		For ( ffTmp=ffCompList ; ffTmp!=none ; ffTmp=ffTmp.ffCompNext )
			ffTmp.ffSetCollision();
}

function bool ffInsertNewPlayer( Pawn NewPlayer)
{
	local private XC_LagCompensator ffTmp;
	
	if ( NewPlayer == none )
		return false;
	ffTmp = Spawn( class'XC_LagCompensator', NewPlayer);
	ffTmp.bDebug = bDebug;
	ffTmp.Mode = PredictMode;
	ffTmp.ffOwner = NewPlayer;
	ffTmp.ffCompNext = ffCompList;
	ffCompList = ffTmp;
	ffTmp.Mutator = self;
	ffTmp.PosList = SetupPosList( NewPlayer );

	//Register individual ZP controller channel on this playerpawn
	if ( (PlayerPawn(NewPlayer) != none) && (NetConnection(PlayerPawn(NewPlayer).Player) != none) )
	{
		ffTmp.CompChannel = Spawn(class'XC_CompensatorChannel');
		ffTmp.CompChannel.bNoBinds = bNoBinds;
		ffTmp.CompChannel.bSimAmmo = bSimulateAmmo;
		
		ffTmp.CompChannel.bDebug = bDebug;

		ffTmp.CompChannel.bReplaceImpactHammer = bReplaceImpactHammer;
		ffTmp.CompChannel.bReplaceEnforcer = bReplaceEnforcer;
		ffTmp.CompChannel.bReplacePulseGun = bReplacePulseGun;
		ffTmp.CompChannel.bReplaceShockRifle = bReplaceShockRifle;
		ffTmp.CompChannel.bReplaceMinigun = bReplaceMinigun;
		ffTmp.CompChannel.bReplaceSniperRifle = bReplaceSniperRifle;
		ffTmp.CompChannel.bReplaceInsta = bReplaceInsta;
		ffTmp.CompChannel.bReplaceSiegePulseRifle = bReplaceSiegePulseRifle;

		ffTmp.CompChannel.AddPlayer( PlayerPawn(NewPlayer), self);
	}
}

final function XC_LagCompensator ffFindCompFor( private pawn ffOther)
{
	local private XC_LagCompensator ffTmp;
	
	For ( ffTmp=ffCompList ; ffTmp!=none ; ffTmp=ffTmp.ffCompNext )
		if ( ffTmp.ffOwner == ffOther )
			return ffTmp;
	return none;
}

final function XC_LagCompensator ffFindCompForId( private int Id)
{
	local private XC_LagCompensator ffTmp;
	
	For ( ffTmp=ffCompList ; ffTmp!=none ; ffTmp=ffTmp.ffCompNext )
		if ( ffTmp.ffOwner.PlayerReplicationInfo.PlayerId == Id )
			return ffTmp;
	return none;
}

function PositionMarker GetOldPositionIndex( float Latency)
{
	local int i, Pos;
	local PositionMarker NewMarker;
	
	//Optimization: starting point
	Pos = int(Latency / PositionStep);
	while ( Pos < ArrayCount(PositionTimeStamp) )
	{
		i = (PositionIndex - Pos) & 31;
		if ( PositionTimeStamp[i] >= Latency )
		{
			NewMarker.Index = i;
			if ( i == PositionIndex ) //Alpha with current actor position instead
			{
				NewMarker.IndexNext = -1;
				NewMarker.Alpha = 1.0 - Latency / PositionTimeStamp[i];
			}
			else
			{
				NewMarker.IndexNext = (i+1) & 31;
				NewMarker.Alpha = 1.0 - (Latency - PositionTimeStamp[NewMarker.IndexNext]) / (PositionTimeStamp[i] - PositionTimeStamp[NewMarker.IndexNext]);
			}
			NewMarker.Alpha = fClamp( NewMarker.Alpha, 0, 1);
			return NewMarker;
		}
		Pos++;
	}
	NewMarker.Index = (PositionIndex + 1) & 31;
	NewMarker.IndexNext = (PositionIndex + 2) & 31;
	NewMarker.Alpha = 0;
	return NewMarker;
}

function ffUnlagPositions( XC_LagCompensator Compensator, vector ShootStart, rotator ShootDir)
{
	local float Latency, ShotTimeStamp;
	local vector Pos, X, Y, Z;
	local XC_PosList PosList;
	
	if ( Compensator == None )
		return;
		
	//Find the position slot
	Latency = Compensator.GetLatency() * PingMult + PingAdd; //PingMult and PingAdd kept for debugging purposes
	Marker[0] = GetOldPositionIndex( Latency);
	if ( Compensator.CompChannel != None ) //Almost always true
		Marker[1] = GetOldPositionIndex( Latency - Compensator.CompChannel.ProjAdv);
	else
		Marker[1] = Marker[0];

	ShotTimeStamp = Level.TimeSeconds - Latency * Level.TimeDilation;
	GetAxes( ShootDir,X,Y,Z);
	ForEach AllActors( class'XC_PosList', PosList) //XC: Use DynamicActors
		if ( PosList != Compensator.PosList )
			PosList.SetupCollision( ShotTimeStamp, ShootStart, X, Y, Z);
}

function ffRevertPositions()
{
	local XC_PosList PosList;
	ForEach AllActors( class'XC_PosList', PosList, 'CollidingPosList') //XC: Use DynamicActors
		PosList.DisableCollision();
}

function ffRevertPositions_XC()
{
	ffRevertPositions();

	// Requires XC_Core script compile functions

	//local XC_PosList PosList;
	//ForEach DynamicActors( class'XC_PosList', PosList, 'CollidingPosList')
	//	PosList.DisableCollision();
}


function float ffMaxLag()
{
	return ffMaxLatency * 0.001 * Level.TimeDilation; //Scale up if game is faster, we'll be operating using just ffDelta on other calculation phases
}


function vector WeaponStartTrace( Weapon W)
{
	local vector X,Y,Z;
	GetAxes( Pawn(W.Owner).ViewRotation, X, Y, Z);
	return W.Owner.Location + W.CalcDrawOffset() + W.FireOffset.Y * Y + W.FireOffset.Z * Z; 
}

function ScoreKill( Pawn Killer, Pawn Other)
{
	local XC_LagCompensator LCComp;
	
	if ( Other.PlayerReplicationInfo != None )
	{
		LCComp = ffFindCompFor( Other);
		if ( LCComp != None && LCComp.PosList != None )
			LCComp.PosList.StartingTimeSeconds = Level.TimeSeconds + 0.1;
	}
	
	if ( NextMutator != None )
		NextMutator.ScoreKill(Killer, Other);
}

function bool IsRelevant( Actor Other, out byte bSuperRelevant)
{
	local bool bResult;

	//bIsPawn is done for speed reasons
	if ( Other.bIsPawn && Other.IsA('ScriptedPawn') )
	{
		SetupPosList( Other);
		return true;
	}

	// allow mutators to remove actors
	if ( bResult && (NextMutator != None) )
		bResult = NextMutator.IsRelevant(Other, bSuperRelevant);

	return bResult;
}

function bool HandleEndGame()
{
	SaveConfig();
	if ( NextMutator != None )
		return NextMutator.HandleEndGame();
	return false;
}

function XC_PosList SetupPosList( Actor Other)
{
	local XC_PosList NewPosList;
	
	NewPosList = Spawn( class'XC_PosList', Other);
	NewPosList.Mutator = self;
	NewPosList.UpdateNow();

	return NewPosList;
}

defaultproperties
{
	  PredictMode=3
      ffCompList=None
      iCombo=0
      ffMaxLatency=650.000000
      pkg=""
      ffCurId=0
      LastTimeSeconds=0.000000
      XCGE=None
      bNoBinds=False
      bNeedsHiddenEffects=False
      PingMult=1.000000
      PingAdd=0.000000
      LinkedPawn=None
      bKickers=True
      bSWJumpPads=True
      bWeaponAnim=True
      bSimulateAmmo=True
      bUsePrediction=True
      bEnableMHhack=True
      bReplaceRockets=True
      bTIWFire=True
      MaxPredictNonLC=150.000000
      swPads(0)=None
      swPads(1)=None
      swPads(2)=None
      swPads(3)=None
      swPads(4)=None
      swPads(5)=None
      swPads(6)=None
      swPads(7)=None
      swPads(8)=None
      swPads(9)=None
      swPads(10)=None
      swPads(11)=None
      swPads(12)=None
      swPads(13)=None
      swPads(14)=None
      swPads(15)=None
      swPads(16)=None
      swPads(17)=None
      swPads(18)=None
      swPads(19)=None
      swPads(20)=None
      swPads(21)=None
      swPads(22)=None
      swPads(23)=None
      swPads(24)=None
      swPads(25)=None
      swPads(26)=None
      swPads(27)=None
      swPads(28)=None
      swPads(29)=None
      swPads(30)=None
      swPads(31)=None
      swPads(32)=None
      swPads(33)=None
      swPads(34)=None
      swPads(35)=None
      swPads(36)=None
      swPads(37)=None
      swPads(38)=None
      swPads(39)=None
      swPads(40)=None
      swPads(41)=None
      swPads(42)=None
      swPads(43)=None
      swPads(44)=None
      swPads(45)=None
      swPads(46)=None
      swPads(47)=None
      swPads(48)=None
      swPads(49)=None
      swPads(50)=None
      swPads(51)=None
      swPads(52)=None
      swPads(53)=None
      swPads(54)=None
      swPads(55)=None
      swPads(56)=None
      swPads(57)=None
      swPads(58)=None
      swPads(59)=None
      swPads(60)=None
      swPads(61)=None
      swPads(62)=None
      PositionIndex=0
      bAddPosition=False
      PositionTimeStamp(0)=0.000000
      PositionTimeStamp(1)=0.000000
      PositionTimeStamp(2)=0.000000
      PositionTimeStamp(3)=0.000000
      PositionTimeStamp(4)=0.000000
      PositionTimeStamp(5)=0.000000
      PositionTimeStamp(6)=0.000000
      PositionTimeStamp(7)=0.000000
      PositionTimeStamp(8)=0.000000
      PositionTimeStamp(9)=0.000000
      PositionTimeStamp(10)=0.000000
      PositionTimeStamp(11)=0.000000
      PositionTimeStamp(12)=0.000000
      PositionTimeStamp(13)=0.000000
      PositionTimeStamp(14)=0.000000
      PositionTimeStamp(15)=0.000000
      PositionTimeStamp(16)=0.000000
      PositionTimeStamp(17)=0.000000
      PositionTimeStamp(18)=0.000000
      PositionTimeStamp(19)=0.000000
      PositionTimeStamp(20)=0.000000
      PositionTimeStamp(21)=0.000000
      PositionTimeStamp(22)=0.000000
      PositionTimeStamp(23)=0.000000
      PositionTimeStamp(24)=0.000000
      PositionTimeStamp(25)=0.000000
      PositionTimeStamp(26)=0.000000
      PositionTimeStamp(27)=0.000000
      PositionTimeStamp(28)=0.000000
      PositionTimeStamp(29)=0.000000
      PositionTimeStamp(30)=0.000000
      PositionTimeStamp(31)=0.000000
      PositionTimer=0.000000
      Marker(0)=(Index=0,IndexNext=0,Alpha=0.000000)
      Marker(1)=(Index=0,IndexNext=0,Alpha=0.000000)
      RemoteRole=ROLE_None
      bGameRelevant=True
}
