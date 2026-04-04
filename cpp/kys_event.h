// kys_event.h - 事件系统声明
// 对应 kys_event.pas

#pragma once
#include <string>
#include "kys_type.h"

// 事件指令
void instruct_0();
std::string ReadTalk(int talknum);
void talk_1(const std::string& talkstr, int headnum, int dismode);
void instruct_1(int talknum, int headnum, int dismode);
void instruct_2(int inum, int amount);
void ReArrangeItem(int sort = 0);
void instruct_3(int list[]);
int instruct_4(int inum, int jump1, int jump2);
int instruct_5(int jump1, int jump2);
int instruct_6(int battlenum, int jump1, int jump2, int getexp);
void instruct_8(int musicnum);
int instruct_9(int jump1, int jump2);
void instruct_10(int rnum);
int instruct_11(int jump1, int jump2);
void instruct_12();
void instruct_13();
void instruct_14();
void instruct_15();
int instruct_16(int rnum, int jump1, int jump2);
void instruct_17(int list[]);
int instruct_18(int inum, int jump1, int jump2);
void instruct_19(int x, int y);
int instruct_20(int jump1, int jump2);
void instruct_21(int rnum);
void instruct_22();
void instruct_23(int rnum, int Poison);
void instruct_24();
void instruct_25(int x1, int y1, int x2, int y2);
void instruct_26(int snum, int en, int add1, int add2, int add3);
void instruct_27(int en, int beginpic, int endpic);
int instruct_28(int rnum, int e1, int e2, int jump1, int jump2);
int instruct_29(int rnum, int r1, int r2, int jump1, int jump2);
void instruct_30(int x1, int y1, int x2, int y2);
int instruct_31(int moneynum, int jump1, int jump2);
void instruct_32(int inum, int amount);
void instruct_33(int rnum, int magicnum, int dismode);
void instruct_34(int rnum, int iq);
void instruct_35(int rnum, int magiclistnum, int magicnum, int exp);
int instruct_36(int sexual, int jump1, int jump2);
void instruct_37(int Ethics);
void instruct_38(int snum, int layernum, int oldpic, int newpic);
void instruct_39(int snum);
void instruct_40(int director);
void instruct_41(int rnum, int inum, int amount);
int instruct_42(int jump1, int jump2);
int instruct_43(int inum, int jump1, int jump2);
void instruct_44(int enum1, int beginpic1, int endpic1, int enum2, int beginpic2, int endpic2);
void instruct_44e(int enum1, int beginpic1, int endpic1, int enum2, int beginpic2, int enum3, int beginpic3);
void instruct_45(int rnum, int speed);
void instruct_46(int rnum, int mp);
void instruct_47(int rnum, int Attack);
void instruct_48(int rnum, int hp);
void instruct_49(int rnum, int MPpro);
int instruct_50(int list[]);
void instruct_51();
void instruct_52();
void instruct_53();
void instruct_54();
int instruct_55(int en, int Value, int jump1, int jump2);
void instruct_56(int Repute);
void instruct_57();
void instruct_58();
void instruct_59();
int instruct_60(int snum, int en, int pic, int jump1, int jump2);
int instruct_61(int jump1, int jump2);
void instruct_62(int enum1, int beginpic1, int endpic1, int enum2, int beginpic2, int endpic2);
void EndAmi();
void instruct_63(int rnum, int sexual);
void instruct_64();
void instruct_66(int musicnum);
void instruct_67(int Soundnum);
int e_GetValue(int bit, int t, int x);
int CutRegion(int x);
int instruct_50e(int code, int e1, int e2, int e3, int e4, int e5, int e6);
bool HaveMagic(int person, int mnum, int lv);
void StudyMagic(int rnum, int magicnum, int newmagicnum, int level, int dismode);
void DivideName(const std::string& fullname, std::string& surname, std::string& givenname);
std::string ReplaceStr(const std::string& S, const std::string& Srch, const std::string& Replace);
void NewTalk(int headnum, int talknum, int namenum, int place, int showhead, int color, int frame, const std::string& content = "", const std::string& disname = "");
int EnterNumber(int MinValue, int MaxValue, int x, int y, int Default = 0);
void SetAttribute(int rnum, int selecttype, int modlevel, int minlevel, int maxlevel);
