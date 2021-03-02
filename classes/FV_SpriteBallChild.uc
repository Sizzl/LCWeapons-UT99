class FV_SpriteBallChild expands FV_SpriteBallExplosion;


function PostBeginPlay()
{
	Texture = SpriteAnim[Rand(5)];
	DrawScale = FRand()*0.5+0.9;
}

defaultproperties
{
      SpriteAnim(3)=Texture'Botpack.UT_Explosions.Exp5_a00'
      SpriteAnim(4)=Texture'Botpack.UT_Explosions.Exp4_a00'
      bHighDetail=True
      RemoteRole=ROLE_None
      DrawScale=1.200000
      LightType=LT_None
      LightEffect=LE_None
}
