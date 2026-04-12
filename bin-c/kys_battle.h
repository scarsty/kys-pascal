// kys_battle.h - 战斗系统
// 对应 kys_battle.pas

#pragma once
#include "kys_type.h"
#include <string>

// 战斗主流程
bool Battle(int battlenum, int getexp);
bool InitialBField();
void InitialBRole(int i, int rnum, int team, int x, int y);
int SelectTeamMembers();
void BattleMainControl();

// 战斗辅助
void CalMoveAbility();
void ReArrangeBRole();
int BattleStatus();
int BattleMenu(int bnum);
void MoveRole(int bnum);
bool MoveAmination(int bnum);
bool SelectAim(int bnum, int step, int AreaType = 0, int AreaRange = 0);
bool SelectDirector(int bnum, int step);
void SeekPath2(int x, int y, int step, int myteam, int mode);
void CalCanSelect(int bnum, int mode, int step);

// 攻击系统
void Attack(int bnum);
void AttackAction(int bnum, int i, int mnum, int level);
void AttackAction(int bnum, int mnum, int level);
void AttackActionAll(int bnum, int mnum, int level);
void ShowMagicName(int mnum, int mode = 0);
int SelectMagic(int rnum);
void SetAminationPosition(int mode, int step, int range = 0);
void SetAminationPosition2(int bx1, int by1, int ax1, int ay1, int mode, int step, int range = 0);
void PlayMagicAmination(int bnum, int enumv, int ForTeam = 0, int mode = 0);

// 伤害计算
void CalHurtRole(int bnum, int mnum, int level);
int CalHurtValue(int bnum1, int bnum2, int mnum, int level);
int CalHurtValue2(int bnum1, int bnum2, int mnum, int level);
void ShowHurtValue(int mode);
void SelectModeColor(int mode, uint32_t& color1, uint32_t& color2, std::string& str, int trans = 0);
void CalPoiHurtLife();
void ClearDeadRolePic();

// 战斗状态管理
void Wait(int bnum);
void RestoreRoleStatus();
void AddExp();
void CheckLevelUp();
void LevelUp(int bnum);
void CheckBook();
int CalRNum(int team);

// 战斗物品/武功使用
void BattleMenuItem(int bnum);
void UsePoison(int bnum);
void PlayActionAmination(int bnum, int mode, int mnum = -1);
void Medcine(int bnum);
void MedPoison(int bnum);
void UseHiddenWeapon(int bnum, int inum);
void Rest(int bnum);
bool TeamModeMenu(int bnum);

// AI 系统
void AutoBattle(int bnum);
void AutoUseItem(int bnum, int list);
void TryMoveAttack(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int bnum, int mnum, int level);
void calline(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int curX, int curY, int bnum, int mnum, int level);
void CalArea(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int curX, int curY, int bnum, int mnum, int level);
void CalPoint(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int curX, int curY, int bnum, int mnum, int level);
void calcross(int& Mx1, int& My1, int& Ax1, int& Ay1, int& tempmaxhurt, int curX, int curY, int bnum, int mnum, int level);
void NearestMove(int& Mx1, int& My1, int bnum);
void NearestMoveByPro(int& Mx1, int& My1, int& Ax1, int& Ay1, int bnum, int TeamMate, int KeepDis, int Prolist, int MaxMinPro, int mode);
