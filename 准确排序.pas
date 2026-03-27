
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

  //按照中点坐标排序建筑
  //根据游戏主地图定义, 该方法准确, 但速度应有优化空间
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
        //将主角位置也视作一个建筑进行排序, 以保证遮挡关系正确
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
              if MainMapStill = 0 then
                b := 2501 + MFace * 7 + MainMapStep
              else
                b := 2528 + Mface * 6 + MainMapStep
            else
              b := 3715 + MFace * 4 + (MainMapStep + 1) div 2;
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
          //已存在时, 定位到其在列表中的位置
          //每一列结束后, p 默认定位到上一列结果
          //这样可减少搜索范围, 新图元大概率在当前点附近插入
          inlist := False;
          for ik := max(0, p - 2) to k - 1 do
          begin
            if (x = BuildArray[ik].x) and (y = BuildArray[ik].y) then
            begin
              p := ik + 1;
              inlist := True;
            end;
          end;
          //新建筑绘制顺序放在当前判定位置之后, 并在后续继续校正
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