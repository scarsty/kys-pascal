#pragma once

#include "mod.h"

namespace mods
{
const Definition& Base();
const Definition& Xiaozhu();
const Definition& Dragon();
const Definition& TianshuQixia();
const Definition& BoluoSanguo();
const Definition& Xiaomeng();
const Definition& Zaizhan();
const Definition& Ptt();
const Definition& Weizheng();
const Definition& TianshuJie();
const Definition& ShakeWorld();
const Definition& Zhenlong();
const Definition& Wenqing();
const Definition& Other();
const Definition& Unspecified(int version);

// The base game and MODVersion=100 share these character setup bonuses.
bool ApplyBaseStartingStats(TRole& role, const std::string& name);
void ApplyBaseCharacterSetup(const std::string& name);
}    //namespace mods
