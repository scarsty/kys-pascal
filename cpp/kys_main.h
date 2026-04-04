#pragma once
// kys_main.h - 游戏主流程：启动、行走、菜单、存读档、事件系统
// 对应 kys_main.pas

#include "kys_type.h"
#include <string>
#include <functional>

// 程序入口
void Run();
void Quit();
void SetMODVersion();
void ReadFiles();

// 游戏流程
void Start();
void StartAmi();
bool InitialRole();
void LoadR(int num);
void SaveR(int num);
int WaitAnyKey();

// 行走
void Walk();
bool CanWalk(int x, int y);
bool CheckEntrance();
bool CheckCanEnter(int snum);
uint32_t UpdateSceneAmi(void* param, SDL_TimerID timerid, uint32_t interval);
int WalkInScene(int Open);
void FindWay(int x1, int y1);
void Moveman(int x1, int y1, int x2, int y2);
void ShowSceneName(int snum);
bool CanWalkInScene(int x, int y);
bool CanWalkInScene(int x1, int y1, int x, int y);
bool CheckEvent1();
void CheckEvent3();

// 菜单
int CommonMenu(int x, int y, int w, int max, const std::string menuString[], int count = 0);
int CommonMenu(int x, int y, int w, int max, int default_, const std::string menuString[], int count = 0);
int CommonMenu(int x, int y, int w, int max, int default_, const std::string menuString[], TPInt1 fn, int count = 0);
int CommonScrollMenu(int x, int y, int w, int max, int maxshow, const std::string menuString[]);
int CommonGridMenu(int x, int y, int cols, int cellW, int maxShowRows, int maxItem, const std::string menuString[]);
int CommonMenu2(int x, int y, int w, const std::string menuString[]);
int SelectOneTeamMember(int x, int y, const std::string& str, int list1, int list2);
bool EnterString(std::string& str, int x, int y, int w, int h);

void MenuEsc();
void ShowMenu(int menu);
void MenuMedcine();
void MenuMedPoison();
bool MenuItem();
int ReadItemList(int ItemType);
void DrawItemFrame(int x, int y);
void UseItem(int inum);
bool CanEquip(int rnum, int inum);
void MenuStatus();
void ShowStatusByTeam(int tnum);
void ShowStatus(int rnum);
void ShowStatus(int rnum, int x, int y);
void ShowSimpleStatus(int rnum, int x, int y);
void MenuLeave();
int MenuSystem();
void MenuLoad();
int MenuLoadAtBeginning();
void MenuSave();
void MenuQuit();

// 效果
int EffectMedcine(int role1, int role2);
int EffectMedPoison(int role1, int role2);
int EatOneItem(int rnum, int inum, int times = 1, int display = 1);

// 事件
void CallEvent(int num);

// 云
void CloudCreate(int num);
void CloudCreateOnSide(int num);
bool IsCave(int snum);

int teleport();
int TeleportByList();
