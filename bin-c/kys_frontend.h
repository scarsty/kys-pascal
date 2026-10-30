#pragma once

#include <string>
#include <vector>

// Null selects the existing SDL frontend. The headless frontend owns input and
// presentation only; scripts, inventory, gates and combat calculations are shared.
struct GameFrontend
{
    virtual ~GameFrontend() = default;
    virtual void text(const std::string& value, int head = -1) = 0;

    virtual void context(const std::string&) { }

    virtual int choose(const std::string& title, const std::vector<std::string>& options, bool cancel = true) = 0;
    virtual int number(int minimum, int maximum, int initial) = 0;
    virtual bool battle(int number, int getexp) = 0;
    virtual bool aim(int actor, int step, int area, int range) = 0;
    virtual void instruction(int script, int pc, int opcode) = 0;
};

inline GameFrontend* Frontend = nullptr;

inline bool Headless() { return Frontend != nullptr; }

inline unsigned HeadlessRandomState = 1;
inline int HeadlessJumpGuardX = -1, HeadlessJumpGuardY = -1;
int GameRandom();

// Size is a presentation property. A headless session never creates an SDL surface.
int ScreenWidth();
int ScreenHeight();
