class XC_CProjSN expands SpawnNotify;

var XC_CompensatorChannel Channel;
var XC_ElementAdvancer Advancer;
var Projectile Stored[256];
var float RemainingAdv[256];
var int iStored, iStoredNew;

var XC_ProjSimulator SimulatorList;


function Setup( XC_CompensatorChannel COwner, XC_ElementAdvancer EAdv)
{
	Channel = COwner;
	Advancer = EAdv;
}

event Actor SpawnNotification( Actor A)
{
	local XC_ProjSimulator Sim;
//	if ( A.Role == ROLE_Authority && A.RemoteRole == ROLE_None ) //Spawned by client with authoritary control (not for simulation purposes)
//		return A;

	if ( (Channel.ProjAdv > 0) && (Projectile(A).default.Damage != 0) )
	{
		Sim = XC_ProjSimulator(A);
		if ( Sim != none )
		{
			Sim.Notify = self;
			Sim.NextSimulator = SimulatorList;
			SimulatorList = Sim;
			Sim.ssCounter = Channel.cAdv; //Temporary, requires bWeaponAnim
			Sim.ssPredict = Channel.ProjAdv;
		}
		else if ( A.default.bNetTemporary || A.default.RemoteRole == ROLE_SimulatedProxy )
		{
			if ( iStoredNew < ArrayCount(Stored) )
			{
				RemainingAdv[iStoredNew] = Channel.ProjAdv;
				Stored[iStoredNew++] = Projectile(A);
			}
		}
		else //Guided warheads?
			Advancer.RegisterAdvance( A);
	}
	return A;
}

event Tick( float DeltaTime)
{
	local int i;
	local PlayerPawn Client;
	local bool bVisible;
	local vector ClientView;

	Client = Channel.LocalPlayer;
	if ( Client == None || DeltaTime == 0.0 || iStoredNew == 0 )
		return;
	
	ClientView = Client.Location;
	ClientView.Z += Client.EyeHeight;
	
	// Remove deleted and pre-processed entries:
	// - Assimilated projectiles are advanced according to assimilator
	// - Advanced (owned) projectiles are given to the element advancer
	// - Non-visible projectiles are advanced in full
	// Note: RemainingAdv is identical in all entries
	for ( i=iStoredNew-1 ; i>=iStored ; i-- )
	{
		if ( Stored[i] == None || Stored[i].bDeleteMe )
		{
			REMOVE_NEW:
			Stored[i] = Stored[--iStoredNew];
			Stored[iStoredNew] = None;
		}
		else
		{
			bVisible = Stored[i].FastTrace( ClientView);
			if ( Stored[i].Instigator == Client )
			{
				if ( AssimilateProjectile( Stored[i]) )
					Goto REMOVE_NEW;
				if ( bVisible )
				{
					Advancer.RegisterAdvance( Stored[i]); //Immediately register
					Goto REMOVE_NEW;
				}
			}

			if ( !bVisible )
			{
				AdvanceProjectile( Stored[i], RemainingAdv[i]);
				Goto REMOVE_NEW;
			}
		}
	}
	
	//Compact and update list
	DeltaTime *= 1.25;
	for ( i=iStoredNew-1 ; i>=0 ; i-- )
	{
		if ( Stored[i] == None || Stored[i].bDeleteMe || (Stored[i].Physics == PHYS_None) )
		{
			REMOVE_OLD:
			Stored[i] = Stored[--iStoredNew];
			RemainingAdv[i] = RemainingAdv[iStoredNew];
			Stored[iStoredNew] = None;
		}
		else
		{
			AdvanceProjectile( Stored[i], FMin( RemainingAdv[i], DeltaTime));
			if ( (RemainingAdv[i] -= DeltaTime) <= 0 )
				Goto REMOVE_OLD;
		}
	}
	iStored = iStoredNew;

}

function bool AssimilateProjectile( Projectile P)
{
	local XC_ProjSimulator Sim, BestSim;

	// Try matching a good simulator
	for ( Sim=SimulatorList ; Sim!=None ; Sim=Sim.NextSimulator )
		Sim.AssessProjectile( P, BestSim);
		
	// Try matching last simulator
	if ( BestSim == None )
		for ( Sim=SimulatorList ; Sim!=None ; Sim=Sim.NextSimulator )
			Sim.AssessProjectileNoCheck( P, BestSim);
		
	// Assimilate
	if ( BestSim != None )
	{
		BestSim.Assimilate( P);
		return true;
	}
	return false;
}

function AdvanceProjectile( Projectile P, float AdvanceAmount)
{
	P.AutonomousPhysics( AdvanceAmount);
	if ( P.bNetTemporary ) //This is a projectile i have simulated control over
	{
		if ( P.LifeSpan > FMax( AdvanceAmount, 1) )
			P.LifeSpan -= AdvanceAmount;
		if ( (P.TimerRate > 0) && (P.bTimerLoop || (P.TimerRate - P.TimerCounter > FMax(AdvanceAmount, 1))) )
			class'LCStatics'.static.SetTimerCounter( P, P.TimerCounter + AdvanceAmount);
	}
}

defaultproperties
{
      Channel=None
      Advancer=None
      Stored(0)=None
      Stored(1)=None
      Stored(2)=None
      Stored(3)=None
      Stored(4)=None
      Stored(5)=None
      Stored(6)=None
      Stored(7)=None
      Stored(8)=None
      Stored(9)=None
      Stored(10)=None
      Stored(11)=None
      Stored(12)=None
      Stored(13)=None
      Stored(14)=None
      Stored(15)=None
      Stored(16)=None
      Stored(17)=None
      Stored(18)=None
      Stored(19)=None
      Stored(20)=None
      Stored(21)=None
      Stored(22)=None
      Stored(23)=None
      Stored(24)=None
      Stored(25)=None
      Stored(26)=None
      Stored(27)=None
      Stored(28)=None
      Stored(29)=None
      Stored(30)=None
      Stored(31)=None
      Stored(32)=None
      Stored(33)=None
      Stored(34)=None
      Stored(35)=None
      Stored(36)=None
      Stored(37)=None
      Stored(38)=None
      Stored(39)=None
      Stored(40)=None
      Stored(41)=None
      Stored(42)=None
      Stored(43)=None
      Stored(44)=None
      Stored(45)=None
      Stored(46)=None
      Stored(47)=None
      Stored(48)=None
      Stored(49)=None
      Stored(50)=None
      Stored(51)=None
      Stored(52)=None
      Stored(53)=None
      Stored(54)=None
      Stored(55)=None
      Stored(56)=None
      Stored(57)=None
      Stored(58)=None
      Stored(59)=None
      Stored(60)=None
      Stored(61)=None
      Stored(62)=None
      Stored(63)=None
      Stored(64)=None
      Stored(65)=None
      Stored(66)=None
      Stored(67)=None
      Stored(68)=None
      Stored(69)=None
      Stored(70)=None
      Stored(71)=None
      Stored(72)=None
      Stored(73)=None
      Stored(74)=None
      Stored(75)=None
      Stored(76)=None
      Stored(77)=None
      Stored(78)=None
      Stored(79)=None
      Stored(80)=None
      Stored(81)=None
      Stored(82)=None
      Stored(83)=None
      Stored(84)=None
      Stored(85)=None
      Stored(86)=None
      Stored(87)=None
      Stored(88)=None
      Stored(89)=None
      Stored(90)=None
      Stored(91)=None
      Stored(92)=None
      Stored(93)=None
      Stored(94)=None
      Stored(95)=None
      Stored(96)=None
      Stored(97)=None
      Stored(98)=None
      Stored(99)=None
      Stored(100)=None
      Stored(101)=None
      Stored(102)=None
      Stored(103)=None
      Stored(104)=None
      Stored(105)=None
      Stored(106)=None
      Stored(107)=None
      Stored(108)=None
      Stored(109)=None
      Stored(110)=None
      Stored(111)=None
      Stored(112)=None
      Stored(113)=None
      Stored(114)=None
      Stored(115)=None
      Stored(116)=None
      Stored(117)=None
      Stored(118)=None
      Stored(119)=None
      Stored(120)=None
      Stored(121)=None
      Stored(122)=None
      Stored(123)=None
      Stored(124)=None
      Stored(125)=None
      Stored(126)=None
      Stored(127)=None
      Stored(128)=None
      Stored(129)=None
      Stored(130)=None
      Stored(131)=None
      Stored(132)=None
      Stored(133)=None
      Stored(134)=None
      Stored(135)=None
      Stored(136)=None
      Stored(137)=None
      Stored(138)=None
      Stored(139)=None
      Stored(140)=None
      Stored(141)=None
      Stored(142)=None
      Stored(143)=None
      Stored(144)=None
      Stored(145)=None
      Stored(146)=None
      Stored(147)=None
      Stored(148)=None
      Stored(149)=None
      Stored(150)=None
      Stored(151)=None
      Stored(152)=None
      Stored(153)=None
      Stored(154)=None
      Stored(155)=None
      Stored(156)=None
      Stored(157)=None
      Stored(158)=None
      Stored(159)=None
      Stored(160)=None
      Stored(161)=None
      Stored(162)=None
      Stored(163)=None
      Stored(164)=None
      Stored(165)=None
      Stored(166)=None
      Stored(167)=None
      Stored(168)=None
      Stored(169)=None
      Stored(170)=None
      Stored(171)=None
      Stored(172)=None
      Stored(173)=None
      Stored(174)=None
      Stored(175)=None
      Stored(176)=None
      Stored(177)=None
      Stored(178)=None
      Stored(179)=None
      Stored(180)=None
      Stored(181)=None
      Stored(182)=None
      Stored(183)=None
      Stored(184)=None
      Stored(185)=None
      Stored(186)=None
      Stored(187)=None
      Stored(188)=None
      Stored(189)=None
      Stored(190)=None
      Stored(191)=None
      Stored(192)=None
      Stored(193)=None
      Stored(194)=None
      Stored(195)=None
      Stored(196)=None
      Stored(197)=None
      Stored(198)=None
      Stored(199)=None
      Stored(200)=None
      Stored(201)=None
      Stored(202)=None
      Stored(203)=None
      Stored(204)=None
      Stored(205)=None
      Stored(206)=None
      Stored(207)=None
      Stored(208)=None
      Stored(209)=None
      Stored(210)=None
      Stored(211)=None
      Stored(212)=None
      Stored(213)=None
      Stored(214)=None
      Stored(215)=None
      Stored(216)=None
      Stored(217)=None
      Stored(218)=None
      Stored(219)=None
      Stored(220)=None
      Stored(221)=None
      Stored(222)=None
      Stored(223)=None
      Stored(224)=None
      Stored(225)=None
      Stored(226)=None
      Stored(227)=None
      Stored(228)=None
      Stored(229)=None
      Stored(230)=None
      Stored(231)=None
      Stored(232)=None
      Stored(233)=None
      Stored(234)=None
      Stored(235)=None
      Stored(236)=None
      Stored(237)=None
      Stored(238)=None
      Stored(239)=None
      Stored(240)=None
      Stored(241)=None
      Stored(242)=None
      Stored(243)=None
      Stored(244)=None
      Stored(245)=None
      Stored(246)=None
      Stored(247)=None
      Stored(248)=None
      Stored(249)=None
      Stored(250)=None
      Stored(251)=None
      Stored(252)=None
      Stored(253)=None
      Stored(254)=None
      Stored(255)=None
      RemainingAdv(0)=0.000000
      RemainingAdv(1)=0.000000
      RemainingAdv(2)=0.000000
      RemainingAdv(3)=0.000000
      RemainingAdv(4)=0.000000
      RemainingAdv(5)=0.000000
      RemainingAdv(6)=0.000000
      RemainingAdv(7)=0.000000
      RemainingAdv(8)=0.000000
      RemainingAdv(9)=0.000000
      RemainingAdv(10)=0.000000
      RemainingAdv(11)=0.000000
      RemainingAdv(12)=0.000000
      RemainingAdv(13)=0.000000
      RemainingAdv(14)=0.000000
      RemainingAdv(15)=0.000000
      RemainingAdv(16)=0.000000
      RemainingAdv(17)=0.000000
      RemainingAdv(18)=0.000000
      RemainingAdv(19)=0.000000
      RemainingAdv(20)=0.000000
      RemainingAdv(21)=0.000000
      RemainingAdv(22)=0.000000
      RemainingAdv(23)=0.000000
      RemainingAdv(24)=0.000000
      RemainingAdv(25)=0.000000
      RemainingAdv(26)=0.000000
      RemainingAdv(27)=0.000000
      RemainingAdv(28)=0.000000
      RemainingAdv(29)=0.000000
      RemainingAdv(30)=0.000000
      RemainingAdv(31)=0.000000
      RemainingAdv(32)=0.000000
      RemainingAdv(33)=0.000000
      RemainingAdv(34)=0.000000
      RemainingAdv(35)=0.000000
      RemainingAdv(36)=0.000000
      RemainingAdv(37)=0.000000
      RemainingAdv(38)=0.000000
      RemainingAdv(39)=0.000000
      RemainingAdv(40)=0.000000
      RemainingAdv(41)=0.000000
      RemainingAdv(42)=0.000000
      RemainingAdv(43)=0.000000
      RemainingAdv(44)=0.000000
      RemainingAdv(45)=0.000000
      RemainingAdv(46)=0.000000
      RemainingAdv(47)=0.000000
      RemainingAdv(48)=0.000000
      RemainingAdv(49)=0.000000
      RemainingAdv(50)=0.000000
      RemainingAdv(51)=0.000000
      RemainingAdv(52)=0.000000
      RemainingAdv(53)=0.000000
      RemainingAdv(54)=0.000000
      RemainingAdv(55)=0.000000
      RemainingAdv(56)=0.000000
      RemainingAdv(57)=0.000000
      RemainingAdv(58)=0.000000
      RemainingAdv(59)=0.000000
      RemainingAdv(60)=0.000000
      RemainingAdv(61)=0.000000
      RemainingAdv(62)=0.000000
      RemainingAdv(63)=0.000000
      RemainingAdv(64)=0.000000
      RemainingAdv(65)=0.000000
      RemainingAdv(66)=0.000000
      RemainingAdv(67)=0.000000
      RemainingAdv(68)=0.000000
      RemainingAdv(69)=0.000000
      RemainingAdv(70)=0.000000
      RemainingAdv(71)=0.000000
      RemainingAdv(72)=0.000000
      RemainingAdv(73)=0.000000
      RemainingAdv(74)=0.000000
      RemainingAdv(75)=0.000000
      RemainingAdv(76)=0.000000
      RemainingAdv(77)=0.000000
      RemainingAdv(78)=0.000000
      RemainingAdv(79)=0.000000
      RemainingAdv(80)=0.000000
      RemainingAdv(81)=0.000000
      RemainingAdv(82)=0.000000
      RemainingAdv(83)=0.000000
      RemainingAdv(84)=0.000000
      RemainingAdv(85)=0.000000
      RemainingAdv(86)=0.000000
      RemainingAdv(87)=0.000000
      RemainingAdv(88)=0.000000
      RemainingAdv(89)=0.000000
      RemainingAdv(90)=0.000000
      RemainingAdv(91)=0.000000
      RemainingAdv(92)=0.000000
      RemainingAdv(93)=0.000000
      RemainingAdv(94)=0.000000
      RemainingAdv(95)=0.000000
      RemainingAdv(96)=0.000000
      RemainingAdv(97)=0.000000
      RemainingAdv(98)=0.000000
      RemainingAdv(99)=0.000000
      RemainingAdv(100)=0.000000
      RemainingAdv(101)=0.000000
      RemainingAdv(102)=0.000000
      RemainingAdv(103)=0.000000
      RemainingAdv(104)=0.000000
      RemainingAdv(105)=0.000000
      RemainingAdv(106)=0.000000
      RemainingAdv(107)=0.000000
      RemainingAdv(108)=0.000000
      RemainingAdv(109)=0.000000
      RemainingAdv(110)=0.000000
      RemainingAdv(111)=0.000000
      RemainingAdv(112)=0.000000
      RemainingAdv(113)=0.000000
      RemainingAdv(114)=0.000000
      RemainingAdv(115)=0.000000
      RemainingAdv(116)=0.000000
      RemainingAdv(117)=0.000000
      RemainingAdv(118)=0.000000
      RemainingAdv(119)=0.000000
      RemainingAdv(120)=0.000000
      RemainingAdv(121)=0.000000
      RemainingAdv(122)=0.000000
      RemainingAdv(123)=0.000000
      RemainingAdv(124)=0.000000
      RemainingAdv(125)=0.000000
      RemainingAdv(126)=0.000000
      RemainingAdv(127)=0.000000
      RemainingAdv(128)=0.000000
      RemainingAdv(129)=0.000000
      RemainingAdv(130)=0.000000
      RemainingAdv(131)=0.000000
      RemainingAdv(132)=0.000000
      RemainingAdv(133)=0.000000
      RemainingAdv(134)=0.000000
      RemainingAdv(135)=0.000000
      RemainingAdv(136)=0.000000
      RemainingAdv(137)=0.000000
      RemainingAdv(138)=0.000000
      RemainingAdv(139)=0.000000
      RemainingAdv(140)=0.000000
      RemainingAdv(141)=0.000000
      RemainingAdv(142)=0.000000
      RemainingAdv(143)=0.000000
      RemainingAdv(144)=0.000000
      RemainingAdv(145)=0.000000
      RemainingAdv(146)=0.000000
      RemainingAdv(147)=0.000000
      RemainingAdv(148)=0.000000
      RemainingAdv(149)=0.000000
      RemainingAdv(150)=0.000000
      RemainingAdv(151)=0.000000
      RemainingAdv(152)=0.000000
      RemainingAdv(153)=0.000000
      RemainingAdv(154)=0.000000
      RemainingAdv(155)=0.000000
      RemainingAdv(156)=0.000000
      RemainingAdv(157)=0.000000
      RemainingAdv(158)=0.000000
      RemainingAdv(159)=0.000000
      RemainingAdv(160)=0.000000
      RemainingAdv(161)=0.000000
      RemainingAdv(162)=0.000000
      RemainingAdv(163)=0.000000
      RemainingAdv(164)=0.000000
      RemainingAdv(165)=0.000000
      RemainingAdv(166)=0.000000
      RemainingAdv(167)=0.000000
      RemainingAdv(168)=0.000000
      RemainingAdv(169)=0.000000
      RemainingAdv(170)=0.000000
      RemainingAdv(171)=0.000000
      RemainingAdv(172)=0.000000
      RemainingAdv(173)=0.000000
      RemainingAdv(174)=0.000000
      RemainingAdv(175)=0.000000
      RemainingAdv(176)=0.000000
      RemainingAdv(177)=0.000000
      RemainingAdv(178)=0.000000
      RemainingAdv(179)=0.000000
      RemainingAdv(180)=0.000000
      RemainingAdv(181)=0.000000
      RemainingAdv(182)=0.000000
      RemainingAdv(183)=0.000000
      RemainingAdv(184)=0.000000
      RemainingAdv(185)=0.000000
      RemainingAdv(186)=0.000000
      RemainingAdv(187)=0.000000
      RemainingAdv(188)=0.000000
      RemainingAdv(189)=0.000000
      RemainingAdv(190)=0.000000
      RemainingAdv(191)=0.000000
      RemainingAdv(192)=0.000000
      RemainingAdv(193)=0.000000
      RemainingAdv(194)=0.000000
      RemainingAdv(195)=0.000000
      RemainingAdv(196)=0.000000
      RemainingAdv(197)=0.000000
      RemainingAdv(198)=0.000000
      RemainingAdv(199)=0.000000
      RemainingAdv(200)=0.000000
      RemainingAdv(201)=0.000000
      RemainingAdv(202)=0.000000
      RemainingAdv(203)=0.000000
      RemainingAdv(204)=0.000000
      RemainingAdv(205)=0.000000
      RemainingAdv(206)=0.000000
      RemainingAdv(207)=0.000000
      RemainingAdv(208)=0.000000
      RemainingAdv(209)=0.000000
      RemainingAdv(210)=0.000000
      RemainingAdv(211)=0.000000
      RemainingAdv(212)=0.000000
      RemainingAdv(213)=0.000000
      RemainingAdv(214)=0.000000
      RemainingAdv(215)=0.000000
      RemainingAdv(216)=0.000000
      RemainingAdv(217)=0.000000
      RemainingAdv(218)=0.000000
      RemainingAdv(219)=0.000000
      RemainingAdv(220)=0.000000
      RemainingAdv(221)=0.000000
      RemainingAdv(222)=0.000000
      RemainingAdv(223)=0.000000
      RemainingAdv(224)=0.000000
      RemainingAdv(225)=0.000000
      RemainingAdv(226)=0.000000
      RemainingAdv(227)=0.000000
      RemainingAdv(228)=0.000000
      RemainingAdv(229)=0.000000
      RemainingAdv(230)=0.000000
      RemainingAdv(231)=0.000000
      RemainingAdv(232)=0.000000
      RemainingAdv(233)=0.000000
      RemainingAdv(234)=0.000000
      RemainingAdv(235)=0.000000
      RemainingAdv(236)=0.000000
      RemainingAdv(237)=0.000000
      RemainingAdv(238)=0.000000
      RemainingAdv(239)=0.000000
      RemainingAdv(240)=0.000000
      RemainingAdv(241)=0.000000
      RemainingAdv(242)=0.000000
      RemainingAdv(243)=0.000000
      RemainingAdv(244)=0.000000
      RemainingAdv(245)=0.000000
      RemainingAdv(246)=0.000000
      RemainingAdv(247)=0.000000
      RemainingAdv(248)=0.000000
      RemainingAdv(249)=0.000000
      RemainingAdv(250)=0.000000
      RemainingAdv(251)=0.000000
      RemainingAdv(252)=0.000000
      RemainingAdv(253)=0.000000
      RemainingAdv(254)=0.000000
      RemainingAdv(255)=0.000000
      iStored=0
      iStoredNew=0
      SimulatorList=None
      ActorClass=Class'Engine.Projectile'
      RemoteRole=ROLE_None
}
