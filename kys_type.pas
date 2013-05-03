unit kys_type;

{$mode delphi}

interface
type

  //以下所有类型均有两种引用方式: 按照别名引用, 按照短整数数组引用
  //在该文件中定义不同MOD中的数据类型, main文件中指定
  TCallType = (Element, Address);

  TRole = record
    case TCallType of
      Element: (ListNum, HeadNum, IncLife, UnUse: smallint;
        Name, Nick: array[0..9] of char;
        Sexual, Level: smallint;
        Exp: word;
        CurrentHP, MaxHP, Hurt, Poison, PhyPower: smallint;
        ExpForItem: word;
        Equip: array[0..1] of smallint;
        AmiFrameNum, AmiDelay, SoundDealy: array[0..4] of smallint;
        MPType, CurrentMP, MaxMP: smallint;
        Attack, Speed, Defence, Medcine, UsePoi, MedPoi, DefPoi, Fist, Sword, Knife, Unusual, HidWeapon: smallint;
        Knowledge, Ethics, AttPoi, AttTwice, Repute, Aptitude, PracticeBook: smallint;
        ExpForBook: word;
        Magic, MagLevel: array[0..9] of smallint;
        TakingItem, TakingItemAmount: array[0..3] of smallint);
      Address: (Data: array[0..90] of smallint);
  end;

  TItem = record
    case TCallType of
      Element: (ListNum: smallint;
        Name, Name1: array[0..19] of char;
        Introduction: array[0..29] of char;
        Magic, AmiNum, User, EquipType, ShowIntro, ItemType, UnKnow5, UnKnow6, UnKnow7: smallint;
        AddCurrentHP, AddMaxHP, AddPoi, AddPhyPower, ChangeMPType, AddCurrentMP, AddMaxMP: smallint;
        AddAttack, AddSpeed, AddDefence, AddMedcine, AddUsePoi, AddMedPoi, AddDefPoi: smallint;
        AddFist, AddSword, AddKnife, AddUnusual, AddHidWeapon, AddKnowledge, AddEthics,
        AddAttTwice, AddAttPoi: smallint;
        OnlyPracRole, NeedMPType, NeedMP, NeedAttack, NeedSpeed, NeedUsePoi, NeedMedcine, NeedMedPoi: smallint;
        NeedFist, NeedSword, NeedKnife, NeedUnusual, NeedHidWeapon, NeedAptitude: smallint;
        NeedExp, NeedExpForItem, NeedMaterial: smallint;
        GetItem, NeedMatAmount: array[0..4] of smallint);
      Address: (Data: array[0..94] of smallint);
  end;

  TScence = record
    case TCallType of
      Element: (ListNum: smallint;
        Name: array[0..9] of char;
        ExitMusic, EntranceMusic: smallint;
        JumpScence, EnCondition: smallint;
        MainEntranceY1, MainEntranceX1, MainEntranceY2, MainEntranceX2: smallint;
        EntranceY, EntranceX: smallint;
        ExitY, ExitX: array[0..2] of smallint;
        JumpY1, JumpX1, JumpY2, JumpX2: smallint);
      Address: (Data: array[0..25] of smallint);
  end;

  TMagic = record
    case TCallType of
      Element: (ListNum: smallint;
        Name: array[0..9] of char;
        UnKnow: array[0..4] of smallint;
        SoundNum, MagicType, AmiNum, HurtType, AttAreaType, NeedMP, Poison: smallint;
        Attack, MoveDistance, AttDistance, AddMP, HurtMP: array[0..9] of smallint);
      Address: (Data: array[0..67] of smallint);
  end;

  TShop = record
    case TCallType of
      Element: (Item, Amount, Price: array[0..4] of smallint);
      Address: (Data: array[0..14] of smallint);
  end;

  TBattleRole = record
    case TCallType of
      Element: (rnum, Team, Y, X, Face, Dead, Step, Acted: smallint;
        Pic, ShowNumber, UnUse1, UnUse2, UnUse3, ExpGot, Auto: smallint;
        RealSpeed, RealProgress, BHead, AutoMode: smallint);
      Address: (Data: array[0..18] of smallint);
  end;

  TCol = record
    r, g, b: byte;
  end;

  TCloud = record
    Picnum: integer;
    Shadow: integer;
    Alpha: integer;
    MixColor: Uint32;
    MixAlpha: integer;
    Positionx, Positiony, Speedx, Speedy: integer;
  end;

  TWarData = record
    case TCallType of
      Element: (Warnum: smallint;
        Name: array[0..9] of char;
        BFieldNum, ExpGot, MusicNum: smallint;
        TeamMate, AutoTeamMate, TeamY, TeamX: array [0..5] of smallint;
        Enemy, EnemyY, EnemyX: array [0..19] of smallint);
      Address: (Data: array[0..$5C] of smallint);
  end;

  TRoleRedFace = record
    case TCallType of
      Element: (ListNum, HeadNum, IncLife, UnUse: smallint;
        Name, Nick: array[0..9] of char;
        Sexual, Level: smallint;
        Exp: word;
        CurrentHP, MaxHP, Hurt, Poison, PhyPower: smallint;
        ExpForItem: word;
        Equip: array[0..1] of smallint;
        AmiFrameNum, AmiDelay, SoundDealy: array[0..4] of smallint;
        MPType, CurrentMP, MaxMP: smallint;
        Attack, Speed, Defence, Medcine, UsePoi, MedPoi, DefPoi, Fist, Sword, Knife, Unusual, HidWeapon: smallint;
        Knowledge, Ethics, AttPoi, AttTwice, Repute, Aptitude, PracticeBook: smallint;
        ExpForBook: word;
        //Magic, MagLevel: array[0..9] of smallint;
        Magic, MagLevel: array[0..39] of smallint;
        TakingItem, TakingItemAmount: array[0..3] of smallint;
        UnKnow: array[0..9] of smallint);
      Address: (Data: array[0..160] of smallint);
  end;

  TItemRedFace = record
    case TCallType of
      Element: (//ListNum: smallint;
        Name: array[0..19] of char;
        Introduction: array[0..29] of char;
        Magic, AmiNum, User, EquipType, ShowIntro, ItemType, UnKnow5, UnKnow6, UnKnow7: smallint;
        AddCurrentHP, AddMaxHP, AddPoi, AddPhyPower, ChangeMPType, AddCurrentMP, AddMaxMP: smallint;
        AddAttack, AddSpeed, AddDefence, AddMedcine, AddUsePoi, AddMedPoi, AddDefPoi: smallint;
        AddFist, AddSword, AddKnife, AddUnusual, AddHidWeapon, AddKnowledge, AddEthics,
        AddAttTwice, AddAttPoi: smallint;
        OnlyPracRole, NeedMPType, NeedMP, NeedAttack, NeedSpeed, NeedUsePoi, NeedMedcine, NeedMedPoi: smallint;
        NeedFist, NeedSword, NeedKnife, NeedUnusual, NeedHidWeapon, NeedAptitude: smallint;
        NeedExp, NeedExpForItem, NeedMaterial: smallint;
        GetItem, NeedMatAmount: array[0..4] of smallint;
        Unkown: array[0..10] of smallint);
      Address: (Data: array[11..105] of smallint);
  end;

  TMagicRedFace = record
    case TCallType of
      Element: (//ListNum: smallint;
        Name: array[0..9] of char;
        UnKnow: array[0..4] of smallint;
        SoundNum, MagicType, AmiNum, HurtType, AttAreaType, NeedMP, Poison: smallint;
        Attack, MoveDistance, AttDistance, AddMP, HurtMP: array[0..9] of smallint;
        UnKnow1: array[0..20] of smallint);
      Address: (Data: array[0..67] of smallint);
  end;

  TWarDataRedFace = record
    case TCallType of
      Element: (Warnum: smallint;
        Name: array[0..9] of char;
        BFieldNum, ExpGot, MusicNum: smallint;
        //TeamMate, TeamY, TeamX: array [0..11] of smallint;
        //AutoTeamMate, AutoTeamY, AutoTeamX: array [0..29] of smallint;
        AutoTeamMate, AutoTeamY, AutoTeamX: array [0..11] of smallint;
        TeamMate, TeamY, TeamX: array [0..29] of smallint;
        Enemy, EnemyY, EnemyX: array [0..99] of smallint);
      Address: (Data: array[0..$5D] of smallint);
  end;

implementation

end.

