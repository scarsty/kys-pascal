
procedure DrawMMap;
var
  i1, i2, i, sum, x, y, k, ik, new, c, widthregion, sumregion, num, h, b, p, p1: integer;
  temp: array[0..479, 0..479] of smallint;
  Width, Height, xoffset, yoffset: smallint;
  pos: TPosition;
  BuildArray: array[0..2000] of TBuildInfo;
  tempb: TBuildInfo;
  tempscr, tempscr1: PSDL_Surface;
  dest: TSDL_Rect;
  inlist: boolean;
  drawed: array[0..2000] of integer;
begin
  {if BIG_PNG_TILE = 1 then
  begin
    SDL_FillRect(screen, nil, 0);
    dest.x := (-Mx * 18 + My * 18 + 8640 - CENTER_X) div 2;
    dest.y := (Mx * 9 + My * 9 + 18 - CENTER_Y) div 2;
    //dest.x := 8640 div 2;
    //dest.y := 4320 div 2;
    dest.w := CENTER_X;
    dest.h := CENTER_Y;
    tempscr := SDL_CreateRGBSurface(screen.flags, CENTER_X, CENTER_Y, 32, 0, 0, 0, 0);
    SDL_BlitSurface(MMapSurface, @dest, tempscr, nil);
    tempscr1 := sdl_gfx.zoomSurface(tempscr, 2, 2, 0);
    SDL_BlitSurface(tempscr1, nil, screen, nil);
    SDL_FreeSurface(tempscr);
    SDL_FreeSurface(tempscr1);
  end;}
  //由上到下绘制, 先绘制地面和表面, 同时计算出现的建筑数
  k := 0;
  h := High(BuildArray);
  widthregion := CENTER_X div 36 + 3;
  sumregion := CENTER_Y div 9 + 2;
  for sum := -sumregion to sumregion + 15 do
    for i := -Widthregion to Widthregion do
    begin
      i1 := Mx + i + (sum div 2);
      i2 := My - i + (sum - sum div 2);
      Pos := GetPositionOnScreen(i1, i2, Mx, My);
      if (i1 >= 0) and (i1 < 480) and (i2 >= 0) and (i2 < 480) then
      begin
        if (BIG_PNG_TILE = 0) then
        begin
          DrawMPic(earth[i1, i2] div 2, pos.x, pos.y);
          if surface[i1, i2] > 0 then
            DrawMPic(surface[i1, i2] div 2, pos.x, pos.y);
        end;
      end
      else
        DrawMPic(0, pos.x, pos.y);
    end;

  //从左向右扫描建筑
  //从游戏地图格式来看, 该方法准确, 且速度应该最快
  for i := Widthregion downto -Widthregion do
  begin
    p := 0;
    for sum := -sumregion to sumregion + 15 do
    begin
      if k >= h then
        break;
      i1 := Mx + i + (sum div 2);
      i2 := My - i + (sum - sum div 2);
      if (i1 >= 0) and (i1 < 480) and (i2 >= 0) and (i2 < 480) then
      begin
        //发现一个建筑引用, 则在序列中查找并定位, 如果有新建筑出现, 则插入此定位
        if (Buildy[i1, i2] > 0) or ((i1 = Mx) and (i2 = My)) then
        begin
          x := Buildx[i1, i2];
          y := Buildy[i1, i2];
          b := building[x, y] div 2;
          if (i1 = Mx) and (i2 = My) then
          begin
            x := i1;
            y := i2;
            if (InShip = 0) then
              if still = 0 then
                b := 2501 + MFace * 7 + MStep
              else
                b := 2528 + Mface * 6 + MStep
            else
              b := 3715 + MFace * 4 + (MStep + 1) div 2;
          end;
          if PNG_TILE > 0 then
          begin
            Width := MPNGIndex[b].CurPointer^.w;
            Height := MPNGIndex[b].CurPointer^.h;
            xoffset := MPNGIndex[b].x;
            yoffset := MPNGIndex[b].y;
          end
          else
          begin
            Width := SmallInt(Mpic[MIdx[b - 1]]);
            Height := SmallInt(Mpic[MIdx[b - 1] + 2]);
            xoffset := SmallInt(Mpic[MIdx[b - 1] + 4]);
            yoffset := SmallInt(Mpic[MIdx[b - 1] + 6]);
          end;
          c := (i1 + i2) - (Width + 35) div 16 - (yoffset - Height + 1) div 9;
          if b <= 0 then
            continue;
          //旧建筑, 定位其序列中的位置
          //在每一列之中, p默认的位置是最后面
          //因存在主角, 从已有图查找应多向前找一个, 有可能只主角的前一个图多查找一个即可
          inlist := False;
          for ik := max(0, p - 2) to k - 1 do
          begin
            if (x = BuildArray[ik].x) and (y = BuildArray[ik].y) then
            begin
              p := ik + 1;
              inlist := True;
            end;
          end;
          //新建筑的绘画顺序必定在前面定位到的旧建筑之后, 在后面应用中点判据
          if inlist = False then
          begin
            {for ik := p +1 to k - 1 do
              if (c > BuildArray[ik].c) then
              begin
                p := ik + 1;
              end;}
            for ik := k - 1 downto p do
              BuildArray[ik + 1] := BuildArray[ik];
            BuildArray[p].x := x;
            BuildArray[p].y := y;
            BuildArray[p].b := b;
            BuildArray[p].c := c;
            {Pos := GetPositionOnScreen(x, y, Mx, My);
            DrawMPic(b, pos.x, pos.y);
            updateallscreen;
            for ik := 0 to k-1do write(BuildArray[ik].b, ',',BuildArray[ik].c ,' ');
            writeln();
            waitanykey; }

            p := p + 1;
            k := k + 1;
          end;
        end;
      end;
    end;
  end;

  for i := 0 to k - 1 do
  begin
    Pos := GetPositionOnScreen(BuildArray[i].x, BuildArray[i].y, Mx, My);
    DrawMPic(BuildArray[i].b, pos.x, pos.y);
  end;
  DrawClouds;

end; 