#pragma once

#include "kys_rules.h"
#include <span>

// DOS-compatible metadata in existing role words; no runtime state or save footer.
namespace rules::growth
{
bool HasSeed(const TRole& hero);
uint32_t ReadSeed(const TRole& hero);
void WriteSeed(TRole& hero, uint32_t seed);
void PrepareLoadedRoles(std::span<TRole> roles);
void StartCampaign(std::span<TRole> roles, uint32_t seed);
bool HasHalf(const TRole& role);
void StoreHalf(TRole& role, bool half);
int FixedDraw(uint32_t seed, int roleIndex, int targetLevel, int group, int bound);
void CheckPersonalItemWrite(int roleIndex);
}
